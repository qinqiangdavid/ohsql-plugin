# perf-kp-sql 加 GaussDB engine · 离线诊断设计

- 状态:draft v0.2(2026-05-18 应用 Sonnet review 修订:整段重写 §1.2 + §6 诊断侧 + §12 M1 清单;archer 真实复用范围按 `archer-interface-notes.md` 校准)
- 起草:2026-05-18
- 作者:david
- 仓库:ohsql-plugin-dev(本仓库,private)

---

## 1. 背景与目标

### 1.1 现状

`perf-kp-sql` 目前是 ohsql-plugin 体系下的一个 LLM 编排诊断 skill,**只支持 MongoDB · 在线模式**(SSH 远程采集 + 案例驱动指标拉取 + LLM 综合 + markdown 报告)。架构成熟:7-phase 线性流水线 + 99 DF case 库 + NotebookLM 权威源 + URL 强制溯源约束。

但内部还有一类高频诊断需求 skill 现在覆盖不了:**GaussDB(分布式 / 集中式) · 离线模式**。场景:

- 现场环境与本地工作机隔离(内网 / 客户机房),无法 SSH
- 客户允许"采集脚本部署到目标节点 + 采集结果取回本地",但不允许我们的 agent 直连
- 需要分析的对象明确:**所有慢 SQL · 不合理的表定义 · 不合理的参数**(用户 2026-05-18 明确口径)

### 1.2 现有资产

archer-ui 仓库(`/Users/davidqin/Documents/repo/archer-ui`,本机有 codex worktree 副本 `/Users/david/.codex/worktrees/{4a46,b426}/archer-ui/views/`)的 `gs_dsw` + `gs_dignose_report` 模块**已经是一个可工作的 GaussDB 离线诊断工具**。经 2026-05-18 Sonnet review(见 `archer-interface-notes.md`),真实可复用范围是:

**可复用诊断架构**(`gs_dsw/funcs/` 新体系 · ModelRunner + Diagnoser pipeline):
- `funcs/models/*.py` 15 个 `BaseModel` 子类(`collect()` + `load()` 二合一)
- `funcs/models/base.py` `BaseModel` 抽象 + `ModelRunner` 调度器
- 4 个活跃 Diagnoser:`InstanceDiagnoser`(2 规则)/ `IndexCheckerDiagnoser`(8 规则)/ `StaticDiagnoser`(N 条 SQL 反模式)/ `PlanDiagnoser`(4 规则)
- 2 个 bak 但仍在用的 Diagnoser:`WaitDiagnoser`(4 规则)/ `MemoryDiagnoser`(4 规则)
- 编排:`bak/slowsql.py` `SlowSQLDiagnoser`(对每条 statement_history row 循环跑 4 个 sub-Diagnoser)
- 顶层入口:`bak/health_report.py` `run(WebArgs)`(支持 `mode='offline'` zip 输入)
- 规则库:`util/sql.py` `SQLDiagnosticEngine` + `util/sqlplan.py` 执行计划规则库
- 测试用例:`testcases/bad_sql.sql` / `bad_plan.sql` + `test_*.py`

**不复用的**(查证后排除):
- ❌ `funcs/cluster_checker.py` — SSH 日志采集+关键词检索工具,**不是诊断规则**(`run(args)` 接 argparse.Namespace,内部 SSH 拉日志后 stdout 打印表格)
- ❌ `funcs/wdr_comparison.py` — WDR HTML 报告对比工具,**不是诊断规则**(产 HTML 文件,无结构化 return)
- ❌ `gs_dignose_report/udf_funcs.py` 12 条规则 — **旧体系已废弃**:在 archer 主流程里**无活跃调用方**,且依赖一个仓库内找不到的 C 扩展 `import diagnose`(`udf_funcs.py:3`),**直接拷贝无法运行**。这套规则的诊断价值已被新体系 `sqlplan_checker / waitevent_checker / instance_checker` 替代
- ❌ `gs_dignose_report/parse_dict.py` — 旧体系 module-global 状态机,跟 udf_funcs 一起废弃

**合计规则数**:`2 + 8 + N + 4 + 4 + 4 = 22+ 条规则`(新体系)· 比旧 udf_funcs 体系覆盖更全更准。

但 archer-ui 是 Go web 后端 + Python 内嵌 + HTML 渲染,**不能直接给 perf-kp-sql 用**;且 archer 旧体系(`gs_dignose_report/`)有不可移植依赖,**必须用新体系**(`gs_dsw/funcs/`)。

### 1.3 目标

让 `perf-kp-sql` 通过加 `engine=gaussdb` 参数,支持 GaussDB 离线诊断,**完整端到端**:输入 collected zip → 输出 markdown 诊断报告。架构上跟 `engine=mongo` 完全对称。

### 1.4 非目标

- ❌ 在线 SSH 模式诊断 GaussDB(本期不做,需要时下一期再加)
- ❌ archer-ui 本身的改造(M2 跳过,见 §11)
- ❌ 把 GaussDB 诊断能力发布成独立 Python 包(`dbdiag` 包不做)
- ❌ 给非 ohsql 体系的第三方 agent / 工具复用(本期内部自用)
- ❌ 覆盖所有 GaussDB 诊断场景(第一版只覆盖 archer 新体系 6 个 Diagnoser ~22 条规则,实战补;特别地,慢 SQL TopN 的范畴外的诊断如 backup / DDL 锁 / 分布列倾斜补救等暂不覆盖)
- ❌ 实时监控(`dist.sh` 那种 daemon 循环模式不做)

---

## 2. 设计原则

### P1 · 跟 mongo engine 完全对称

新 engine 的目录结构 / phase 编号 / case 库格式 / 报告章节 / NLM 注册流程,都跟 mongo engine 对位摆放。LLM 编排端只需在 phase 内部做"engine 分流",不引入额外路由层。

### P2 · 复用 archer 已写对的代码,不重新发明

archer 新体系 `gs_dsw/funcs/` 的 6 个 Diagnoser(22+ 条规则)+ 15 个 BaseModel(数据采集 + 解析)+ `ModelRunner` 编排 + `SlowSQLDiagnoser` pipeline 是确定性 Python 代码,过过生产 + 有 testcases。skill 直接调,**不让 LLM 用 shell / jq 重新实现一遍判断逻辑**。LLM 只做"看 hits.json + 看 case 元信息 + 写报告"这种综合工作。

archer 旧体系(`gs_dignose_report/udf_funcs.py` + `parse_dict.py`)**已废弃,不复用**(详见 §1.2)。

### P3 · 一切融进 skill,无外部 Python 包

archer 抽出来的代码物理上拷进 `data/engines/gaussdb/diag/`,不发布成独立包。用户装 ohsql-plugin → 直接可用,**不要让用户 pip install dbdiag**。代价:archer-ui 那边继续用自己的内嵌副本(M2 跳过),短期内代码有两份;长期看可以再统一,本期不阻塞。

### P4 · URL 强制溯源不破

报告里 `[参考N]` URL 必须 verbatim 来自 `data/cases/gaussdb/CASES.md` 的 `source_url` 字段或 NLM `references[].source_id`。不许凭训练数据知识联想 / 推断官方文档 URL。案例 / NLM 都没引用的根因 → 移到 "辅助信息 · 现场观测" 子段,**不许编 URL 凑数**。

### P5 · 离线场景下"现场"是 zip

`engine=mongo+online` 的 Phase 3 是 SSH 拉远程指标;`engine=gaussdb+offline` 的 Phase 3 是**在 zip 内调 `run.py` 跑全套 archer 规则**。Phase 0 的"环境画像"也从"SSH env probe"换成"读 zip 内 `meta.json` + `env/`"。

### P6 · 量化数据没有时占位,不编造

`xx ms` / `xx %` / 表名 `xx` 占位。公开数据(openGauss 文档版本号 / archer 函数名 / pg view 名)可直接引用。

---

## 3. 整体架构

### 3.1 仓库布局

```
ohsql-plugin-dev/                                   (private repo · main 分支)
├── docs/
│   └── superpowers/specs/
│       └── 2026-05-18-perf-kp-sql-gaussdb-engine-design.md  (本文档)
└── plugins/perf-kp-sql/
    └── skills/perf-kp-sql/                         (主 skill)
        ├── SKILL.md                                改:加 engine=gaussdb 分流
        ├── scripts/                                现有(SSH wrapper)
        └── data/
            ├── cases/
            │   ├── mongo/                          挪进子目录(从 data/cases/ 根下)
            │   │   ├── INDEX.md
            │   │   ├── CASES.md
            │   │   └── indices/
            │   │       ├── by-check-item/{INDEX,CASES}.md
            │   │       └── by-source-url.json
            │   └── gaussdb/                        新增
            │       ├── INDEX.md                    12 条 case 路由表
            │       ├── CASES.md                    case 详情
            │       └── indices/
            │           ├── by-check-item/{INDEX,CASES}.md
            │           └── by-source-url.json
            └── engines/
                └── gaussdb/                        新增
                    ├── collect/
                    │   ├── dbcollect.sh            主脚本 · CN 上跑 · 调 Python ModelRunner 采集
                    │   ├── dn-helper.sh            DN 助手 · SCP 推过去 · 纯文件采集
                    │   └── README.md               采集脚本说明 · 部署 + 调用流程
                    │   # 注:SQL 模板由 archer model.collect() 内嵌(不再外部 sql/ 目录)
                    └── diag/
                        ├── run.py                  入口 CLI · 接 zip · 输出 hits.json · 包装 health_report.run()
                        ├── models/                 archer 15 个 BaseModel 子类
                        │   ├── base.py             BaseModel + ModelRunner 调度器
                        │   ├── statement_history_model.py
                        │   ├── pg_class_model.py
                        │   ├── pg_stats_model.py
                        │   ├── pg_setting_model.py
                        │   ├── pg_stat_all_tables_model.py
                        │   ├── pg_total_autovac_tuples_model.py
                        │   ├── summary_statement_model.py
                        │   ├── index_cols_model.py
                        │   ├── index_collation_model.py
                        │   ├── table_column_model.py
                        │   ├── col_type_model.py
                        │   ├── ndv_model.py
                        │   ├── type_operator_model.py
                        │   ├── type_cast_model.py
                        │   ├── gpi_check_model.py
                        │   └── gs_gsc_dbstat_info_model.py
                        ├── diagnosers/             6 个 Diagnoser class
                        │   ├── instance_checker.py   InstanceDiagnoser(2 规则)
                        │   ├── index_checker.py      IndexCheckerDiagnoser(8 规则)
                        │   ├── sql_checker.py        StaticDiagnoser
                        │   ├── sqlplan_checker.py    PlanDiagnoser(4 规则)
                        │   ├── waitevent_checker.py  WaitDiagnoser(4 规则 · 从 bak/ 拷)
                        │   └── memory_checker.py     MemoryDiagnoser(4 规则 · 从 bak/ 拷)
                        ├── pipeline/               诊断编排
                        │   ├── slowsql.py            SlowSQLDiagnoser(从 bak/ 拷)
                        │   ├── memory.py             顶层内存诊断流(从 bak/memory_checker 抽)
                        │   └── health_report.py      run(WebArgs)(从 bak/ 拷 · 顶层入口)
                        └── util/
                            ├── sql.py                SQLDiagnosticEngine(SQL 正则规则库)
                            ├── sqlplan.py            执行计划规则库
                            ├── deadlock.py
                            └── print.py
```

### 3.2 数据流

```
[目标内网 · CN 节点]                              [本地工作机]

用户从 skill 拿到采集说明书 →
   ↓
SCP dbcollect.sh + dn-helper.sh 到 CN omm 用户家目录
   ↓
bash dbcollect.sh \
    --start "..." --end "..." \
    --output collected.zip \
    --top-n 100
   ├─ 采 CN 本机 OS / pg_log / postgresql.conf
   ├─ gsql -p $CN_PORT 一会话内:
   │    ├─ 全局视图 (pgxc_node / pgxc_thread_wait_status / ...)
   │    ├─ 参数 (pg_settings)
   │    ├─ 元信息 (DDL / pg_stats / pg_class)
   │    ├─ WDR 报告(create_wdr_snapshot + generate_wdr_report)
   │    └─ CN 视角慢 SQL (dbe_perf.statement_history)
   ├─ for dn in pgxc_node where node_type='D':
   │    gsql -c "EXECUTE DIRECT ON ($dn) $$ ... $$" 拉 per-DN DB 数据
   ├─ for dn_host in pgxc_node where node_type='D':
   │    scp dn-helper.sh omm@$dn_host:/tmp/
   │    ssh omm@$dn_host "bash dn-helper.sh '$start' '$end' /tmp/dn.zip"
   │    scp omm@$dn_host:/tmp/dn.zip ./dn-tmp/
   ├─ 合并 cn / dn 数据 → collected-<ts>.zip
   └─ 用户 scp collected.zip 回本地工作机
                                                          ↓
                              /perf-kp-sql engine=gaussdb input=./collected.zip
                                                          ↓
                              Phase 0  解 zip + meta.json 校验 + 环境上下文
                                                          ↓
                              Phase 1  问问题现象
                                                          ↓
                              Phase 2  Read data/cases/gaussdb/INDEX.md 路由
                                                          ↓
                              Phase 3  python3 data/engines/gaussdb/diag/run.py \
                                            --input <zip> --output-json -
                                       → hits.json (列出 rule 命中 + 命中对象 + 关键值)
                                                          ↓
                              Phase 4  LLM 综合:hits.json + Read 命中 case 详情 + NLM
                                                          ↓
                              Phase 5  按章节模板生成 markdown 报告
                                                          ↓
                              Phase 6  深入对话(可选)
```

---

## 4. 关键决策记录(7 题)

| # | 决策 | 选择 | 理由 |
|---|------|------|------|
| Q1 | engine 分流入口 | `engine=gaussdb input=<path>` · input 为空 → Phase 0 输出采集说明书 | 单一参数 · 跟 mongo 入口形态对称 · 避免 SSH 凭据混入离线场景 |
| Q2a | Phase 0 改造 | 子步替换:凭据 → input 路径;env probe → zip 解包 + meta 校验 | Phase 结构不变,只换数据源 |
| Q2b | Phase 3 改造 | 路径 2 简化版:`Bash(python3 run.py)` 一步出 hits.json,内部包装 archer `health_report.run(WebArgs)` 调起完整 `ModelRunner + 6 Diagnoser` 流水线 | archer 已写对规则不重做;hits.json 含命中规则 + 现场细节 → 写报告够用;有需要再单条 case 加 zip_extractor 增量演进 |
| Q3 | case 库放哪 | `data/cases/{mongo,gaussdb}/` engine 平级 · gaussdb case 直接写 skill 内部 | mongo 也挪进子目录 · 平级对称 · 内部自维护无外部同步 |
| Q4 | trigger / 入口命令 | `/perf-kp-sql` 单一命令 · trigger 关键词加 gaussdb / openGauss / CN 瓶颈 / DN 倾斜 等 | 不加 alias slash · skill 名字不改(`perf-kp-sql` 保留 kp 字面) |
| Q5 | NotebookLM | 接 · 只喂 openGauss 公开文档 + 华为云 GaussDB 文档 | 跟 mongo 对称 · URL 强制溯源不破 · 公开源无合规问题 |
| Q6 | 报告章节 | 环境上下文 → 综合描述 → 诊断主表(按严重度排序) → 详细分析(4 子节:慢 SQL / 表定义 / 参数 / 倾斜) → 辅助信息 | 分布式拓扑信息密度大,前置;详细分析对位用户三个目标 + 倾斜 |
| Q7a | 工程基础设施 | 一切融进 skill · 无 dbdiag 独立包 · spec 落本仓库 docs/ · M2 跳过 | 内部自用 · skill 自包含 · archer-ui 继续用旧内嵌路径不阻塞 |

---

## 5. 采集组件 · `data/engines/gaussdb/collect/`

### 5.1 `dbcollect.sh`(CN 主脚本)

**调用形态**:

```bash
bash dbcollect.sh \
    --start "2026-05-18 10:00:00" \
    --end   "2026-05-18 11:00:00" \
    --output ./collected-20260518T103000.zip \
    --top-n 100                           # 慢 SQL TopN · 默认 100
    [--no-wdr]                            # 跳过 WDR 报告(体量过大时)
    [--ssh-user omm]                      # SSH 跨节点用户 · 默认 omm
    [--ssh-key ~/.ssh/id_rsa]             # SSH key · 默认走 om 用户互信
    [--port $CN_PORT]                     # 显式指定 · 默认从 postgresql.conf 推断
    [--db postgres]                       # 默认 postgres
```

**运行假设**:

- 脚本以 GaussDB OS 用户(通常 `omm`)身份运行
- 节点间 SSH 互信已配(GaussDB 部署默认条件)
- `$PGDATA` 环境变量正确,`gs_om` / `gsql` 在 PATH

**步骤**:

```
1. 解析参数 + 必填项校验 + 检测部署形态
   ├─ gsql -c "select count(*) from pgxc_node where node_type='C'" → >0 = 分布式
   └─ 单点 / 主备 = 集中式
2. 建工作目录 $TMP/collect/{env,conf,logs,deploy,wdr,dump/{cn,dn}}
3. 采 CN 本机 OS 画像 → $TMP/env/
   ├─ uname -a
   ├─ lscpu + cat /proc/cpuinfo (头 50 行)
   ├─ free -h + cat /proc/meminfo
   ├─ lsblk + df -h + mount | grep -E 'gauss|pgdata'
   ├─ iostat -xz 1 3 (若有 sysstat)
   ├─ sysctl -a | grep -E '^(vm|kernel|net)\.'
   ├─ ulimit -a + cat /etc/security/limits.conf
   ├─ ip -br a + ss -s
   └─ ps auxf | grep -E 'gauss|postgres' | head -50
4. cp $PGDATA/postgresql.conf → $TMP/conf/
5. 采 CN 本机 pg_log 按时间窗口裁剪 → $TMP/logs/
   └─ find $PGDATA/pg_log -newermt "$start" \! -newermt "$end" -exec cp {} $TMP/logs/ \;
6. 部署形态识别 → $TMP/deploy/
   ├─ gsql -c "select * from pgxc_node" > pgxc_node.txt        (分布式)
   ├─ gsql -c "select * from pgxc_group" > pgxc_group.txt      (分布式)
   ├─ gs_om -t status --detail > cluster_status.txt            (分布式)
   ├─ gs_ctl status -D $PGDATA > status.txt                    (集中式)
   └─ gs_om --version / gs_ctl --version → version.txt
7. WDR 报告生成 → $TMP/wdr/         (除非 --no-wdr)
   ├─ 找 dbe_perf.snapshot 表中时间最接近 start / end 的两个 snap_id
   ├─ 若不存在 → 触发 dbe_perf.create_wdr_snapshot() 两次(间隔 5 min)
   ├─ select dbe_perf.generate_wdr_report(snap1, snap2, 1, 'detail', 'cluster') → wdr_<sid1>_<sid2>.html
   └─ 若全部失败 → meta.wdr_unavailable=true · 继续
8. 采 CN 全局 DB 数据 → $TMP/dump/cn/
   for sql_template in sql/*.sql:
       gsql -A -d $db -p $CN_PORT -f $sql_template > $TMP/dump/cn/${sql_template%.sql}.txt
   含:pg_settings / pg_stats / pgxc_thread_wait_status / pgxc_get_senders_catchup_time
       / pg_class / pg_stat_all_tables / pg_total_autovac_tuples / index_* / col_type 
       / ndv / type_cast / type_operator / table_def / statement_history(CN 视角)
       / summary_statement / gs_gsc_dbstat_info
9. 采 per-DN DB 数据 (分布式 only) → $TMP/dump/dn/<dn_name>/
   for dn in $(gsql -tA -c "select node_name from pgxc_node where node_type='D'"):
       mkdir -p $TMP/dump/dn/$dn
       for sql in statement_history / pg_stat_all_tables / pg_locks:
           gsql -c "EXECUTE DIRECT ON ($dn) \$\$ $(cat sql/$sql.sql) \$\$" \
               > $TMP/dump/dn/$dn/$sql.txt
10. 跨节点 SSH 拉 DN 本机文件 (分布式 only) → $TMP/dump/dn/<dn_name>/{env,conf,logs}/
    可并发(`xargs -P` 或 `&` + `wait`)
    for dn_host in $(gsql -tA -c "select node_host from pgxc_node where node_type='D'"):
        scp dn-helper.sh omm@$dn_host:/tmp/
        ssh omm@$dn_host "bash /tmp/dn-helper.sh '$start' '$end' /tmp/dn-$(hostname).zip"
        scp omm@$dn_host:/tmp/dn-*.zip ./dn-tmp/
        ssh omm@$dn_host "rm /tmp/dn-helper.sh /tmp/dn-*.zip"
        SSH 失败 → meta.dn_failed[]: { name, reason } · 继续不阻断
11. 解 dn-tmp/dn-*.zip → $TMP/dump/dn/<dn_name>/{env,conf,logs}/
12. 写 meta.json:
    {
      "collected_at": "<iso8601>",
      "window": {"start": "...", "end": "..."},
      "deploy_mode": "distributed" | "centralized",
      "cn": {"hostname": "...", "node_name": "coordinator1"},
      "dn_total": <N>,
      "dn_collected": ["datanode1", "datanode2", ...],
      "dn_failed": [{"name": "datanode3", "reason": "ssh timeout 30s"}],
      "wdr_unavailable": false,
      "version": {"gaussdb": "...", "dbcollect": "0.1.0"},
      "files": [{"path": "...", "sha256": "...", "size_bytes": ...}, ...]
    }
13. checksums.txt(全文件 sha256)
14. zip -r $output $TMP/* → 用户取回
```

### 5.2 `dn-helper.sh`(DN 上跑)

**纯文件采集 · 不碰 gsql · 不依赖 DB 内部协议**

```bash
START=$1; END=$2; OUT=$3
TMP=$(mktemp -d)

# OS 画像 9 项(同 CN 主脚本第 3 步,简化版)
uname -a > $TMP/uname.txt
lscpu > $TMP/lscpu.txt
cat /proc/cpuinfo | head -50 > $TMP/cpuinfo.txt
free -h > $TMP/free.txt
sysctl -a | grep -E '^(vm|kernel|net)\.' > $TMP/sysctl.txt
df -h > $TMP/df.txt
lsblk > $TMP/lsblk.txt
ulimit -a > $TMP/ulimit.txt
ps auxf | grep -E 'gauss|postgres' | head -50 > $TMP/ps.txt

# postgresql.conf
cp $PGDATA/postgresql.conf $TMP/

# pg_log 按时间窗口裁剪
mkdir $TMP/logs
find $PGDATA/pg_log -newermt "$START" \! -newermt "$END" -exec cp {} $TMP/logs/ \;

cd $TMP && zip -r $OUT . && echo "OK"
```

### 5.3 SQL 模板 · 由 archer model `collect()` 内嵌(不外部拆)

**重要调整**(对比 plan v0.1):archer 新体系 `BaseModel.collect()` **已内嵌 SQL** + 调 gsql 写文件,跟"外部 SQL 模板"是同一份逻辑。本期采集架构**不再外部拆 SQL 模板**,直接复用 model 的 `collect()`。

`collect/sql/` 目录**不建** — dbcollect.sh 中"采全局 DB 数据"步骤改成调 Python `from models import ModelRunner; runner.run_combination(models, ...)`,让每个 model 自己跑自己的 SQL 写自己的 txt 文件。

涉及的 SQL 视图(15 个 model 各自 cover):
- `dbe_perf.statement_history`(`statement_history_model`)
- `pg_catalog.pg_class`(`pg_class_model`)
- `pg_catalog.pg_stats`(`pg_stats_model`)
- `pg_settings`(`pg_setting_model`)
- `pg_stat_all_tables`(`pg_stat_all_tables_model`)
- `pg_total_autovac_tuples`(`pg_total_autovac_tuples_model`)
- `dbe_perf.summary_statement`(`summary_statement_model`)
- 索引相关 4 个 model(index_cols / index_collation / gpi_check / table_column)
- 类型相关 3 个 model(col_type / type_cast / type_operator)
- `ndv_model`(基数估计)
- `gs_gsc_dbstat_info_model`(GSC dbstat)

**分布式专属视图**(`pgxc_thread_wait_status` / `pgxc_get_senders_catchup_time`)— archer 没现成 model,需要新建 2 个 model class(继承 `BaseModel`,跟其他 model 同 pattern)。

**dbcollect 跟 model.collect 的协同**:`dbcollect.sh` 主流程跑到第 8 步(CN DB 采集)时,改成:

```bash
# 第 8 步(新版)· 让 archer model 自己采
python3 -c "
from data.engines.gaussdb.diag.models import ModelRunner
runner = ModelRunner(work_dir='$TMP/dump/cn', conn_params=...)
runner.run_combination(ALL_MODELS, online=True)
"
```

`-W` 命令行传密码风险用 `$PGPASSFILE` 或 `$PGPASSWORD` 环境变量替代(archer model 内部已经这样做,沿用)。

### 5.4 collected zip 内目录

```
collected-<ts>.zip
├── meta.json                                  采集元信息(见 §5.1 第 12 步)
├── checksums.txt                              sha256 全文件清单
├── env/                                       CN 本机 OS 9 项
│   ├── uname.txt
│   ├── lscpu.txt
│   ├── meminfo.txt
│   ├── sysctl.txt
│   ├── df.txt
│   ├── iostat.txt
│   ├── ulimit.txt
│   ├── network.txt
│   └── ps.txt
├── conf/postgresql.conf                       CN 配置副本
├── logs/                                      CN pg_log 按时间窗口裁剪
│   └── pg_log_*.txt
├── deploy/                                    部署形态识别
│   ├── pgxc_node.txt
│   ├── pgxc_group.txt
│   ├── cluster_status.txt
│   └── version.txt
├── wdr/                                       WDR 报告
│   └── wdr_<sid1>_<sid2>.html
└── dump/
    ├── cn/                                    CN 全局视角数据(17+ 文件)
    │   ├── pg_settings.txt
    │   ├── pg_stats.txt
    │   ├── pg_class.txt
    │   ├── statement_history.txt
    │   ├── ddl_table_def.txt
    │   ├── ... 
    │   └── pgxc_thread_wait_status.txt
    └── dn/                                    per-DN(分布式 only)
        ├── datanode1/
        │   ├── env/                           SSH 拉(DN 本机 OS)
        │   ├── conf/postgresql.conf           SSH 拉
        │   ├── logs/pg_log_*.txt              SSH 拉
        │   └── dump/                          EXECUTE DIRECT 拉
        │       ├── statement_history.txt
        │       ├── pg_stat_all_tables.txt
        │       └── pg_locks.txt
        ├── datanode2/...
        └── datanodeN/...
```

---

## 6. 诊断组件 · `data/engines/gaussdb/diag/`

### 6.1 `run.py`(入口 CLI)

```bash
python3 data/engines/gaussdb/diag/run.py \
    --input ./collected.zip \
    --output-json -                   # 或 --output-json hits.json
    [--verbose]
```

**返回 JSON 结构**(stdout):

```json
{
  "schema_version": "0.1.0",
  "input_zip": "collected-20260518T103000.zip",
  "deploy_mode": "distributed",
  "summary": {
    "total_hits": 14,
    "by_severity": {"P0": 2, "P1": 5, "P2": 7},
    "by_category": {"slow_sql": 8, "memory": 2, "index": 3, "wait_event": 1}
  },
  "hits": [
    {
      "rule_name": "buffer_hit_ratio_low",
      "diagnoser": "InstanceDiagnoser",
      "severity": "P1",
      "category": "slow_sql",
      "status": "warning",
      "result": "缓冲区命中率 87% < 95% 阈值",
      "reason": "shared_buffers 配置过小,频繁磁盘读",
      "suggestion": "把 shared_buffers 调到物理内存的 25%",
      "detail": {
        "sql_id": "31697554",
        "hit_ratio": 0.87,
        "threshold": 0.95
      }
    },
    ...
  ],
  "meta": {
    "diagnosers_run": ["MemoryDiagnoser", "InstanceDiagnoser",
                       "WaitDiagnoser", "PlanDiagnoser", "StaticDiagnoser",
                       "IndexCheckerDiagnoser"],
    "models_loaded": ["statement_history", "pg_class", "pg_stats",
                      "pg_settings", "pg_stat_all_tables", ...],
    "duration_seconds": 12.4,
    "collected_at": "2026-05-18T10:30:00",
    "window": {"start": "...", "end": "..."}
  }
}
```

`hits[].status` 字段取自 archer Diagnoser 返回值,值域:`critical / warning / info / pass`。
`hits[].rule_name` 用 archer Diagnoser 内部的规则命名(具体取值 M1.diag 移植时**逐个 Diagnoser 读源码定**,见 §6.3)。

**`run.py` 内部流程**(架构关键):

```python
def main():
    args = parse_args()
    
    # 1. 构造 archer WebArgs(模拟 archer Go 后端调用形态)
    web_args = WebArgs(
        action='health_report',
        mode='offline',
        file=str(Path(args.input).resolve())
    )
    
    # 2. 调用 archer 顶层入口 health_report.run(args)
    #    内部会:
    #      ① ModelRunner 解压 zip + 各 model.load() → data_bundle
    #      ② MemoryDiagnoser(data_bundle).execute_diagnosis_flow()
    #      ③ SlowSQLDiagnoser(data_bundle).execute_diagnosis_flow(args)
    #         对每条 statement_history row 跑 4 个 sub-Diagnoser:
    #         InstanceDiagnoser / WaitDiagnoser / PlanDiagnoser / StaticDiagnoser
    #      ④ 可选:IndexCheckerDiagnoser(在 archer 中被注释,本期重新激活)
    from pipeline import health_report
    report_data = health_report.run(web_args)
    
    # 3. 把 archer 内部格式转 hits.json schema
    hits = transform_to_hits(report_data)
    
    # 4. 读 meta.json(dbcollect 写的) · 拼最终 output
    meta = json.load(open(args.input).workdir / "meta.json")
    output = aggregate(hits, meta, args.input, duration)
    
    print(json.dumps(output, ensure_ascii=False, indent=2))
```

`transform_to_hits` 把 archer 内部 `final_report_data`(`{"memory_diagnose_result": [], "sql_diagnose_result": []}`)展开成 hits.json schema 的 list,每条 hit 含 `rule_name / diagnoser / status / result / reason / suggestion / detail`。

### 6.2 复用 archer 代码 + 必要适配

| archer 原路径 | 移入 skill 路径 | 适配工作 |
|---|---|---|
| `funcs/models/*.py`(15 个) | `diag/models/` | 改 import 路径;每个 model `collect()` 内嵌 SQL,可能需要按 GaussDB(vs openGauss)做少量字段适配(`gs_gsc_dbstat_info` / `top_wait_events` / `gpi_check` 等视图存在性核对) |
| `funcs/models/base.py` | `diag/models/base.py` | `BaseModel` 抽象 + `ModelRunner` 调度器 · 改 import · 不动逻辑 |
| `funcs/instance_checker.py` `InstanceDiagnoser` | `diag/diagnosers/instance_checker.py` | 改 import · **不动逻辑** |
| `funcs/index_checker.py` `IndexCheckerDiagnoser` | `diag/diagnosers/index_checker.py` | 同上 · 注:archer 主流程把它注释掉了(`#IndexDiagnoser`),本期**重新激活**接入 SlowSQLDiagnoser |
| `funcs/sql_checker.py` `StaticDiagnoser` | `diag/diagnosers/sql_checker.py` | 同上 |
| `funcs/sqlplan_checker.py` `PlanDiagnoser` | `diag/diagnosers/sqlplan_checker.py` | 同上 |
| `funcs/bak/waitevent_checker.py` `WaitDiagnoser` | `diag/diagnosers/waitevent_checker.py` | 从 bak/ 拷过来挪到正式目录 |
| `funcs/bak/memory_checker.py` `MemoryDiagnoser` | `diag/diagnosers/memory_checker.py` | 同上 |
| `funcs/bak/slowsql.py` `SlowSQLDiagnoser` | `diag/pipeline/slowsql.py` | 编排器 · 改 import · `DIAGNOSER_CLASSES` 加 `IndexCheckerDiagnoser`(archer 注释掉了,本期激活) |
| `funcs/bak/health_report.py` `run(args)` | `diag/pipeline/health_report.py` | 顶层入口 · 改 import |
| `funcs/util/sql.py` `SQLDiagnosticEngine` | `diag/util/sql.py` | SQL 正则规则库 · 不动 |
| `funcs/util/sqlplan.py` | `diag/util/sqlplan.py` | 执行计划规则库 · 不动 |
| `funcs/util/deadlock.py` / `print.py` | `diag/util/` | 同上 |
| `views/gs_dignose_report/diagnose_report_v1.py` | **不要** | web 后端粘合层,被 `run.py` 替代 |
| `views/gs_dignose_report/generate_report_v1.py` | **不要** | HTML 渲染,被 LLM 生成 markdown 替代 |
| `views/gs_dignose_report/udf_funcs.py` | **不要** | 旧体系已废弃 · 依赖 C 扩展 `diagnose` |
| `views/gs_dignose_report/parse_dict.py` | **不要** | 旧体系已废弃 · module global 状态机 |
| `funcs/cluster_checker.py` | **不要** | 日志采集脚本,不是诊断规则 |
| `funcs/wdr_comparison.py` | **不要** | WDR HTML 对比工具,不是诊断规则 |
| `testcases/test_*.py`(6 个) | `diag/tests/` | 改 import · pytest 适配 |
| `testcases/bad_sql.sql` / `bad_plan.sql` | `diag/tests/fixtures/` | 作为回归 fixture |

### 6.3 22+ 条 Diagnoser 规则 → case 库映射

archer 6 个 Diagnoser 各自内部有多条规则。**具体规则名 + 阈值 / 提示文案要在 M1.diag 移植时逐个 Diagnoser 读源码定**(本表给已知近似映射,精确版以 M1.diag.2-3 实读源码为准)。

| Diagnoser | 内部规则名(近似) | case_id | severity | category |
|---|---|---|---|---|
| `InstanceDiagnoser` | buffer_hit_ratio_low | BUFFER_HIT_LOW | P1 | param |
| `InstanceDiagnoser` | syscache_hit_ratio_low | SYSCACHE_HIT_LOW | P1 | param |
| `IndexCheckerDiagnoser` | gpi_present | GPI_PRESENT | P2 | table_def |
| `IndexCheckerDiagnoser` | ndv_order_wrong | IDX_NDV_ORDER | P1 | table_def |
| `IndexCheckerDiagnoser` | collation_mismatch | IDX_COLLATION | P1 | table_def |
| `IndexCheckerDiagnoser` | leftmost_violation | IDX_LEFTMOST | P1 | table_def |
| `IndexCheckerDiagnoser` | index_skip | IDX_SKIP | P1 | table_def |
| `IndexCheckerDiagnoser` | index_not_used | IDX_NOT_USED | P1 | table_def |
| `IndexCheckerDiagnoser` | implicit_type_cast | IDX_IMPLICIT_CAST | P1 | table_def |
| `IndexCheckerDiagnoser` | scan_selectivity_low | IDX_SCAN_LOW_SEL | P2 | table_def |
| `StaticDiagnoser` | not_in_antipattern | SQL_NOT_IN | P1 | slow_sql |
| `StaticDiagnoser` | select_star | SQL_SELECT_STAR | P2 | slow_sql |
| `StaticDiagnoser` | (其他 N 条 · M1 实读)| ... | ... | slow_sql |
| `PlanDiagnoser` | hard_parse_high | HARD_PARSE_HIGH | P1 | param |
| `PlanDiagnoser` | dead_tuple_io_amp | TAB_VACUUM_NEEDED | P1 | table_def |
| `PlanDiagnoser` | data_skew | DATA_SKEW | P1 | slow_sql |
| `PlanDiagnoser` | plan_quality | PLAN_QUALITY | P1 | slow_sql |
| `WaitDiagnoser` | regular_lock_wait | LOCK_WAIT_REGULAR | P1 | slow_sql |
| `WaitDiagnoser` | lightweight_lock_wait | LOCK_WAIT_LW | P1 | slow_sql |
| `WaitDiagnoser` | wal_sync_slow | WAL_SYNC_SLOW | P0 | param |
| `WaitDiagnoser` | wal_flush_slow | WAL_FLUSH_SLOW | P0 | param |
| `MemoryDiagnoser` | shared_memory_high | MEM_SHARED_HIGH | P0 | param |
| `MemoryDiagnoser` | session_thread_high | MEM_SESSION_HIGH | P1 | param |
| `MemoryDiagnoser` | peak_memory | MEM_PEAK_USAGE | P1 | param |
| `MemoryDiagnoser` | memory_leak | MEM_LEAK | P0 | param |

**合计 ~22 条 case**(StaticDiagnoser 的 SQL 反模式条数待实读,可能再加 5-10 条)。

每条 case 在 `CASES.md` 里的字段(对位 mongo CASES.md 模板):

```yaml
case_id: TAB_VACUUM_NEEDED
title: 表死元组过多 · IO 放大
severity: P1
category: table_def
diagnoser: PlanDiagnoser
rule_name: dead_tuple_io_amp
phenomenon: |
  pg_stat_all_tables 显示 n_dead_tup / n_live_tup > 20%,SQL 扫表时
  IO 被死元组放大,执行计划估算偏差。
impact: |
  慢 SQL 增多 · 单点 query 耗时 2x-10x · vacuum 不及时累积
fix_template: |
  -- 立即 vacuum
  VACUUM ANALYZE <schemaname>.<relname>;
  
  -- 调小 autovacuum_vacuum_scale_factor
  ALTER TABLE <schemaname>.<relname> SET (autovacuum_vacuum_scale_factor = 0.05);
source_url: 
  - https://docs.opengauss.org/zh/docs/latest/docs/SQLReference/VACUUM.html
nlm_keywords:
  - "vacuum"
  - "dead tuple"
  - "autovacuum"
```

### 6.4 case 库工程量估算

**~22 条 Diagnoser 规则 → ~22 条 case**(StaticDiagnoser SQL 反模式可能再加 5-10 条,合计 27-32 条)。

每条 case 写 markdown 元信息(title / phenomenon / impact / fix_template / source_url / nlm_keywords)+ 读对应 Diagnoser 源码确认规则名 / 阈值估算 **每条 30-60 分钟** · 总计 **11-32 小时**。

**第一版完成 22 条核心 case**(StaticDiagnoser 子规则作为第二轮)。


---

## 7. case 库 · `data/cases/gaussdb/`

### 7.1 与 mongo 完全对称的结构

```
data/cases/
├── mongo/                           现有 · 挪进子目录(从 data/cases/ 根下)
│   ├── INDEX.md
│   ├── CASES.md
│   └── indices/
│       ├── by-check-item/
│       │   ├── INDEX.md
│       │   └── CASES.md
│       └── by-source-url.json
└── gaussdb/                         新增
    ├── INDEX.md                     case 路由表(对位 mongo 的 DF case 路由)
    ├── CASES.md                     case 详情(15-19 条)
    └── indices/
        ├── by-check-item/           指标集合路由(从 cases 派生)
        │   ├── INDEX.md
        │   └── CASES.md
        └── by-source-url.json       NLM 喂料 URL 列表
```

### 7.2 mongo 现有 case 库挪动的工作

`SKILL.md` 里所有 case 路径引用要批改(预估 5-10 处):

```
data/cases/INDEX.md → data/cases/mongo/INDEX.md
data/cases/CASES.md → data/cases/mongo/CASES.md
data/cases/indices/by-check-item/INDEX.md → data/cases/mongo/indices/by-check-item/INDEX.md
data/cases/indices/by-source-url.json → data/cases/mongo/indices/by-source-url.json
```

Phase 2.1 / Phase 2.3 / Phase 3 加载逻辑都加 `<engine>` 分流:

```
Phase 2.1 启动加载:  Read data/cases/<engine>/INDEX.md
Phase 2.3 拿单 case: Read data/cases/<engine>/CASES.md offset+limit
```

NLM 注册的 `by-source-url.json` 路径变更要同步改 `perf-kp-sql-setup` skill 的注册逻辑。

### 7.3 NLM notebook(gaussdb 版)

建一个跟 mongo 平行的 NLM notebook,**只喂公开文档**:

源 URL 列表(`by-source-url.json` 初版,可后续扩):

```json
{
  "schema_version": "0.1.0",
  "engine": "gaussdb",
  "sources": [
    {
      "title": "openGauss 官方文档(docs.opengauss.org)",
      "base_url": "https://docs.opengauss.org/zh/docs/",
      "scope": ["SQLReference", "AdministratorGuide", "PerformanceTuning"]
    },
    {
      "title": "华为云 GaussDB 文档",
      "base_url": "https://support.huaweicloud.com/gaussdb/",
      "scope": ["devg", "perftuning", "trouble"]
    }
  ],
  "excluded": [
    {
      "reason": "内部不公开 / GaussDB Kernel 商用增强版细节",
      "patterns": ["internal-wiki/*", "kernel-internal/*"]
    }
  ]
}
```

`perf-kp-sql-setup` skill 扩展逻辑:

- 检测用户当前 engine 选择(若指定 `engine=gaussdb`)
- 引导用户在 NotebookLM Web 上建 notebook · 标题 `perf-kp-sql · GaussDB Engine`
- 把上面 base_url 复制给用户作为 Notebook Sources
- 注册成功后 `~/.perf-kp-sql/nlm-notebooks.json` 加 `{engine: gaussdb, notebook_id: ...}` entry

---

## 8. Phase 流水线(gaussdb engine 版)

跟 mongo 的 7-phase 编号对齐 · 子步内容替换:

### Phase 0 · 环境信息采集(zip 模式)

| 子步 | mongo+online | gaussdb+offline |
|---|---|---|
| 0.1 | SSH 凭据 | `input` 路径 |
| 0.2 连通性 | SSH env probe | zip 解包 + meta.json 必填字段校验 + checksums.txt 校验 |
| 0.3 环境画像 | SSH 拉远程 OS/DB 版本 | Read zip 内 `env/` + `deploy/` + `meta.json` |
| 0.4 阻断 | SSH 不通 / 凭据错 | zip 损坏 / meta 缺失 / 时间窗口外异常 |
| 0.5 输出 [环境上下文] | OS / DB / 部署形态 | 同 + 集群拓扑 + 采集时间窗口 + dn_failed 列表 |
| **0.6**(新增) | — | `input` 为空 → 输出**采集说明书**(`dbcollect.sh` 副本路径 + SCP + 跑命令 + 取回流程) · 流程在此终止,等用户带 zip 重新调用 |

### Phase 1 · 对话引导

沿用 mongo 模式,在 [环境上下文] 基础上问问题现象。如:

> 现在看到的环境是分布式 GaussDB(3 CN + 4 DN),采集窗口 2026-05-18 10:00-11:00,dn3 SSH 失败。你想分析的现象主要是?
> 
> A. 慢 SQL 暴增
> B. CPU 高 / 抖动  
> C. 巡检(无具体现象 · 看是否有不合理的表定义 / 参数 / 倾斜)
> D. 其他

### Phase 2 · 案例匹配

```
2.1 Read data/cases/gaussdb/INDEX.md(路由表)
2.2 LLM 按问题现象 + 环境上下文路由到 N 条候选 case
2.3 Read data/cases/gaussdb/CASES.md offset+limit 拿候选 case 详情
```

### Phase 3 · 诊断指标采集(zip 内调 run.py · 一步)

**简化版**:不再"按 case 跑 SSH 命令",也不"按 case 跑 zip extractor",而是一次性跑全套:

```
3.1 Bash 调:
    python3 plugins/perf-kp-sql/skills/perf-kp-sql/data/engines/gaussdb/diag/run.py \
        --input <input zip path> --output-json -
3.2 → hits.json(每 hit 含 rule_id / category / severity / details / advise)
3.3 LLM 读 hits.json + 看 Phase 2.3 拿到的 case 元信息 · 进 Phase 4
```

**Phase 3 子步号** 在 SKILL.md 里要明确:

- 3.1 调 run.py
- 3.2 检查 stdout / exit code(失败阻断)
- 3.3 解析 hits.json + 校验 schema_version

**失败处理**:

- run.py exit ≠ 0 → 写报错 + 进 Phase 6(让用户排查 zip 完整性)
- hits.json schema 不匹配 → 同上
- 用 `dry-run` 模式让 LLM 看 run.py 准备跑哪些 checker,不真跑(可选 debug)

### Phase 4 · 多源综合诊断

跟 mongo 流程对齐 · 案例 + NLM 双源 · 单源是降级:

```
4.1 hits.json + Phase 2.3 case 详情 → 主表候选根因
4.2 NLM 巡检(可选):对 hits 列出的命中 case · 查 NLM 拿权威 URL 引用
4.3 案例 / NLM 都无引用的现象 → 进 "辅助信息 · 现场观测" 子段
4.4 按严重度 P0/P1/P2 排序最终结论
```

### Phase 5 · 报告生成

见 §9 章节模板。

### Phase 6 · 深入对话

沿用 mongo · 用户拿到报告后追问 · 由 LLM 复用 Phase 2-4 的上下文响应。

---

## 9. 报告章节模板(gaussdb 版)

> ⚠️ 以下是一份**示例报告模板**,内部的 H1/H2/H3 标题是最终生成报告的章节,不是本 spec 的章节。

```markdown
# GaussDB 性能诊断报告 · <采集时间窗口>

## 环境上下文

- 部署形态:分布式(3 CN + 4 DN) / 集中式(主备)
- GaussDB 版本:<version>
- OS / 硬件:<Kunpeng 920 / 256GB / 16 core>
- 集群拓扑:
  ```
  ┌─ coordinator1 ─ coordinator2 ─ coordinator3 ─┐
  └─ datanode1 ── datanode2 ── datanode3 ── datanode4 ┘
  ```
- 采集时间窗口:2026-05-18 10:00:00 → 11:00:00
- 数据缺失:dn3 SSH 失败(timeout 30s)/ WDR 报告生成失败

## 综合描述

<1-3 句话定性 + 主要发现 + 影响面 + 紧急度>

## 诊断结果(按严重度排序)

| # | 严重度 | 类别 | 现象 | 根因 | 修复建议 | 参考 |
|---|--------|------|------|------|----------|------|
| 1 | P0 | 慢 SQL | unique_query_id 31697554 平均 6135ms · 大表 nested loop | DN1 上 large_tbl 缺索引 · plan 选 NL | 加 idx_<col_name> + analyze | [参考1] |
| 2 | P0 | 参数 | shared_buffers=128MB(内存 256GB) | 配置过小 · buffer hit rate 87% | 调到 25% 物理内存 | [参考2] |
| 3 | P1 | 表定义 | order_tbl 分布列 = id(单调递增) | 写入热点全压到 DN1 | 改 hash distributed by user_id | [参考3] |
| 4 | P1 | 倾斜 | log_tbl: dn1=1B / dn2-4 各 200M | 5 倍倾斜 | 同 #3 修复后 redistribute | — |

## 详细分析

### 慢 SQL · TopN

| query_id | 模式 | 平均耗时 | 调用次数 | CN 时间 | DN1 | DN2 | DN3 | DN4 |
|----------|------|----------|----------|---------|-----|-----|-----|-----|
| 31697554 | SELECT ... FROM lancamento_debito ... | 6135ms | 33,642 | 200ms | 5400ms | 80ms | 75ms | 80ms |

### 表定义问题

- `apassist.order_tbl`:分布列 = `id`(单调递增)· 推荐改 `user_id`
- `apassist.session_log`:无主键 + 无索引 · 写入即慢扫
- `apassist.events_2026`:大表无分区(1.2B 行) · 推荐按 `event_time` 范围分区

### 参数审计

| 参数名 | 当前值 | 推荐值 | 类别 | 原因 |
|--------|--------|--------|------|------|
| shared_buffers | 128MB | 64GB(25% mem) | memory | hit rate 仅 87% · 离 95% 阈值差 8% |
| work_mem | 4MB | 64MB | memory | TopN 慢 SQL 多次 spill to disk |
| max_connections | 5000 | 2000 | session | 连接数高但活跃低 · 每连接 work_mem 浪费 |

### 倾斜证据

- `log_tbl`: dn1=1B, dn2=200M, dn3=200M, dn4=200M(倾斜系数 5.0)
- `order_tbl`: dn1=300M, dn2=295M, dn3=298M, dn4=302M(均衡)

## 辅助信息

### 现场观测(无案例引用)

<案例 / NLM 都没覆盖但客观存在的现象 · 不进主表>

### 数据缺失

- dn3 SSH 失败(timeout 30s) · OS 画像 / pg_log 缺
- WDR 报告生成失败(dbe_perf.create_wdr_snapshot 权限不足)
- NLM 未注册 · Phase 4B 退化到仅案例(报告里 [参考] 来自 CASES.md source_url)

### 采集元信息

- collected_at: 2026-05-18T10:30:00
- dbcollect 版本: 0.1.0
- 采集耗时: 12.4s
- zip 大小: 45MB
- 数据校验: sha256 全部通过

---

## 参考

[参考1] [openGauss · 创建索引](https://docs.opengauss.org/zh/docs/<version>/...)
[参考2] [华为云 · GaussDB 性能调优指南 · 内存参数](https://support.huaweicloud.com/perftuning/...)
[参考3] [openGauss · 分布列选择最佳实践](https://docs.opengauss.org/zh/docs/<version>/...)
```

---

## 10. 错误处理与降级

| 失败场景 | 阻断 / 降级 | 行为 |
|---|---|---|
| `input` 路径无效 | 阻断 Phase 0 | 报错 + 输出采集说明书 |
| zip 损坏 / checksums 不匹配 | 阻断 Phase 0 | 让用户重采 |
| `meta.json` 缺必填字段 | 阻断 Phase 0 | 同上 |
| `run.py` exit ≠ 0 | 阻断 Phase 3 | 报错 + 让用户排查 / 进 Phase 6 |
| `hits.json` schema 不匹配 | 阻断 Phase 3 | 同上 |
| 单 DN SSH 不通(采集时) | 降级 | `meta.dn_failed[]` 标 · 报告标"DN 数据缺" |
| 单 DN EXECUTE DIRECT 失败 | 降级 | 同上 |
| WDR 报告生成失败 | 降级 | `meta.wdr_unavailable=true` · 报告标 WDR 缺失 |
| NLM 不可用 | 降级 | Phase 4B 退化到"仅案例" · 报告标 NLM 缺失 |
| 案例 + NLM 都无 URL 引用的根因 | 降级 | 移到"辅助信息 · 现场观测",不许编 URL |
| Python 依赖缺失(pre-flight) | 阻断 | 提示用户 `pip install -r diag/requirements.txt` |

---

## 11. 测试与验证

### 11.1 单元测试(`diag/tests/`)

- 移植 archer `testcases/test_*_checker.py` 6 个,改 import 路径 + pytest 化
- 用 `bad_sql.sql` / `bad_plan.sql` + 一份合成 collected.zip 作 fixture

### 11.2 端到端测试

构造一份小尺寸 sample collected zip:
- 1 CN + 1 DN 假数据
- 包含 5-10 张表 · 故意造几个 hit(陈旧统计 / 缺索引 / 倾斜)
- 跑 `python3 run.py --input sample.zip` 验证 hits.json 输出
- 跑 `/perf-kp-sql engine=gaussdb input=sample.zip` 验证 markdown 报告

### 11.3 报告人工 review

第一版 case 库 22+ 条 · 必须每条至少跑过一次,人工 review:
- hit 关键值是否正确
- fix_template 是否可直接执行
- source_url 是否真实存在(不许编)
- NLM 引用是否权威

---

## 12. 落地里程碑

### M1 · 抽 archer 内核进 skill(本期核心)

- [ ] 拷 `views/gs_dsw/funcs/models/*.py`(15 个 + `base.py`)到 `data/engines/gaussdb/diag/models/`
- [ ] 拷 4 个活跃 Diagnoser(`instance_checker / index_checker / sql_checker / sqlplan_checker`)到 `diag/diagnosers/`
- [ ] 拷 `bak/waitevent_checker.py` + `bak/memory_checker.py` 到 `diag/diagnosers/`(从 bak/ 提升)
- [ ] 拷 `bak/slowsql.py` + `bak/health_report.py` 到 `diag/pipeline/`(加 `IndexCheckerDiagnoser` 到 `DIAGNOSER_CLASSES`)
- [ ] 拷 `funcs/util/{sql,sqlplan,deadlock,print}.py` 到 `diag/util/`
- [ ] 改全部 import 路径(`gs_dsw.funcs.*` → `.*`)
- [ ] 写 `run.py` CLI 入口 · 内部调 `health_report.run(WebArgs)` · 输出 hits.json
- [ ] 写 `transform_to_hits()` · archer `final_report_data` → hits.json schema
- [ ] 写 `dbcollect.sh` 主脚本 · 加时间窗口 / 9 项环境画像 / WDR / EXECUTE DIRECT 跨 DN
- [ ] 写 `dn-helper.sh` · 纯文件采集
- [ ] dbcollect 跟 archer model 的 `collect()` 协同 — model 自带 SQL,dbcollect 不必再拆 SQL 模板(原 collect/sql/ 整段废)
- [ ] 写 22+ 条 case 到 `data/cases/gaussdb/CASES.md`(读 6 个 Diagnoser 源码确认 rule_name)
- [ ] 写 `data/cases/gaussdb/INDEX.md` 路由表
- [ ] 建 NLM notebook + 写 `by-source-url.json`(schema 跟 mongo 版的 `{domains:[{domain,notebook_name,urls}]}` 对齐)
- [ ] 移植 archer testcases/ 测试到 `diag/tests/`
- [ ] 端到端用 sample.zip 跑通

### M2 · 跳过

archer-ui 继续用自己仓库的旧 Python 内嵌路径 · 不切到调本 skill 的 `run.py`。原因:archer-ui 是 Go web 后端,subprocess 调 skill 内部脚本不合适;且 archer-ui 跟 perf-kp-sql 没必要绑死。

### M3 · skill 改造 + 集成

- [ ] mongo case 挪到 `data/cases/mongo/` 子目录 + SKILL.md 路径引用批改(5-10 处)
- [ ] SKILL.md 加 `engine=gaussdb` 分流逻辑 + Phase 0/3 改造
- [ ] SKILL.md trigger phrase 扩(gaussdb / openGauss / CN 瓶颈 / DN 倾斜 等)
- [ ] argument-hint 改成 `engine=mongo: ... | engine=gaussdb: input=<path>`
- [ ] 报告章节模板按 §9 落
- [ ] pre-flight 加 Python 3.x + 必要 lib 检测
- [ ] `perf-kp-sql-setup` skill 扩 NLM gaussdb notebook 注册引导

### 时间估算

- M1:~7-9 工作日(代码移植 + dbcollect 重写 + 22+ 条 case 库写 + Diagnoser 源码逐个读)
- M3:~2-3 工作日(SKILL.md 改 + 测试)
- 合计:**2-2.5 周**

---

## 13. 风险

1. **Diagnoser 返回值字段实际形态** — 已知 archer Diagnoser `check()` 返回 `List[Dict]`,字段含 `rule_name / status / result / reason / suggestion / detail`,但**每个 Diagnoser 的 rule_name 命名空间需要 M1.diag 移植时逐个读源码确认**(spec §6.3 是近似映射);若实战发现 hits.json 写报告时缺现场细节,**单条 case 增量加 zip_extractor 字段**(LLM 跑一次 grep 补充)
2. **WDR 生成权限** — `dbe_perf.create_wdr_snapshot()` 需 sysadmin · 失败时降级取已有 snapshot · 全部失败标 `wdr_unavailable=true`
3. **EXECUTE DIRECT 引号转义** — Sonnet review 指出 `\$\$` 在 bash 双引号内会展开成 `$$`(当前 PID),**不能直接套 dist.sh L80 写法**;采集脚本中 EXECUTE DIRECT 必须用 heredoc 或临时 SQL 文件 + `-f` 传入,避免 shell 替换
4. **DN SSH 互信** — 前提条件 · 若环境特殊导致 omm 跨节点不通 · 用 `--ssh-user` / `--ssh-key` 覆盖 · 不通的 DN 走降级
5. **WDR 报告体量** — 单份 HTML 5-10MB · 总 zip 可能超 100MB · `--no-wdr` 开关 fallback
6. **case 库 22+ 条够不够** — archer 现有规则覆盖核心场景(缓冲区命中 / 索引质量 / SQL 反模式 / 执行计划 / 等待事件 / 内存)· 但**未覆盖**:无主键 / 大表无分区 / 主备追赶 / 分布列倾斜补救 / 内存配置不当等 — 第一版按 22+ 条上线 · 用户实战补
7. **GaussDB Kernel 内部规则不能进 NLM** — 公开 case 用 openGauss / 华为云文档 · 内部规则的 case 在 source_url 标 "internal,无公开 URL" · Phase 4B 不查 NLM
8. **archer-ui 双重维护** — M2 跳过 · skill 和 archer-ui 各持一份 archer 代码 · 短期接受 · 后续若 archer 团队改规则需手动 sync 回 skill(或反之)
9. **archer 新体系 `bak/` 目录命名误导** — `gs_dsw/funcs/bak/` 里有 `health_report` / `slowsql` / `waitevent_checker` / `memory_checker` 等,**这些不是"过期备份"**,是当前主流程实际用的代码(`diagnose_report_v1.py:51` 实际调 `bak.health_report.run`)。M1.diag 移植要把这些从 bak/ 挪到正式目录

---

## 14. 待定 / 未决

- [ ] `dbcollect.sh` 的 `--no-wdr` 默认值(开 vs 关)
- [ ] WDR 报告除了 `cluster` 维度,要不要也生成 `node` / `instance` 维度 · 体量翻倍但定位更准
- [ ] case 库写法是 markdown frontmatter(YAML)还是 H2 标题分段(对位 mongo CASES.md 现有格式)· 看 mongo CASES.md 实际 format 后定
- [ ] `parse_dict.py` 适配新 zip 布局的工作量(archer 原版基于 `process_dn_*` 命名 + 单文件 JSON,新版基于多个独立 .txt) · 可能要重写而不是改
- [ ] NLM notebook 注册的具体步骤是否需要在 setup skill 里加交互引导,还是仅文档化

---

## 15. 引用

- archer-ui worktree(本机副本):`/Users/david/.codex/worktrees/4a46/archer-ui/views/`
- perf-kp-sql 主 skill(plugin cache 最新版):
  `/Users/david/.claude-max/plugins/cache/ohsql-plugin/perf-kp-sql/0.54.0/skills/perf-kp-sql/SKILL.md`
- 本仓库 perf-kp-sql 源码:
  `/Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql/skills/perf-kp-sql/`
- gaussdb-diag 工作目录(诊断侧工具拆分):`/Users/david/code/gaussdb-diag/`
- archer 真实接口探索笔记(2026-05-18 Sonnet review 产出):
  `/Users/david/code/ohsql-plugin-dev/docs/superpowers/specs/archer-interface-notes.md`
- HANDOFF · 之前 datadog 设计:`/Users/david/observation/datadog/HANDOFF.md`(无关本期 · 仅记录上次 context reset 时的工作位置)

---

**End of design v0.2**
