# offline-collect-kit · HANDOFF

接手前必读。本目录是 perf-kp-sql skill 的**离线采集工具包** — 拷到 db 服务器,跑一份"指标 + 参数现值"采集,回喂诊断。

最后更新: 2026-05-23 · 当前版本: v5 (ok 率 99.4%)

---

## 1. 这套 kit 是干什么的

perf-kp-sql skill 默认走 SSH 实时采集。**内网/无 SSH 直连**场景(GaussDB 客户多内网部署)skill 不能远程探,需要一份"自包含、零依赖"脚本部署到 db 机上,拿运行结果回喂。

蒸馏阶段已经从 perf-kp-sql 案例库的 `by-check-item` 反向索引过滤出 GaussDB 关联 **341 个 check**(`gaussdb` + `gaussdb-dws` 桶),每 check 含 method (`gsql -c "SHOW xxx"` / SQL / OS 命令)+ abnormal_pattern。

---

## 2. 当前进展 (v5)

```
集中式   gauss_new (Ruby:37000)        : 179 ok · 1 rc127 (iostat 未装)
分布式   gauss_dist (dist_505:25000)   : 179 ok · 1 rc127
分布式   gauss_dist_new (dist_505_new:35000) : 179 ok · 1 rc127

总 341 check = 180 auto + 153 manual + 8 skip-empty
auto ok 率 = 179/180 = 99.4% (唯一 error: iostat sysstat 包未装)

3 集群 status 完全一致 · 0 个部署形态特异性差异
(GaussDB 507 集中式也保留 pgxc_node 等 catalog 表 · SELECT 不报错)
```

---

## 3. 文件清单

```
offline-collect-kit/
├── README.md                    用法 + 部署说明
├── HANDOFF.md                   本文件
├── checklist.ndjson             341 个 check 的机器可读源数据 (150 KB)
│
├── collect-precompiled.sh   ★ 推荐 · 92.6 KB · 216 命令 inline heredoc · 不依赖 ndjson
├── collect-precompiled.py   ★ 推荐 · 59.8 KB · CHECKS list inline · 纯 stdlib
│
│
├── manual-audit.md              ★ 153 manual 人审清单 · 每条带 matched_rule + 派生命令 (98.7% 有派生)
├── view-overlap-analysis.md     ★ 视图查询重叠分析 · 42 视图 / 134 → 42 round-trip · 可省 68.7%
│
├── _build-precompiled.mjs       本地工具 · 重生成 precompiled.{sh,py} + manual-audit.md
└── _analyze-view-overlap.mjs    本地工具 · 重生成 view-overlap-analysis.md
```

**precompiled.{sh,py} 是 user-facing**,部署一个文件就跑。  
**collect.{sh,py} 现场解析版**是开发期保留 (改 ndjson 不用重 build)。

---

## 4. cheat sheet · 怎么跑

```bash
# 本地: 拷一个文件
scp collect-precompiled.sh root@<db-host>:/tmp/

# db 服务器: source env + 跑
ssh root@<db-host>
su - <db-user>                                    # GaussDB 通常用专属 OS 用户
source ~/gauss_env_file                           # GaussDB env file (路径因 user 而异)
export PGPORT=<db-port>                           # 集中式 37000 · 分布式 25000/35000
cp /tmp/collect-precompiled.sh ~/
./collect-precompiled.sh ./out-$(hostname)-$(date +%Y%m%d)

# 拿结果回本地
scp -r root@<db-host>:~/<db-user>/out-* ./
```

### 输出布局

```
out-<host>-<ts>/
├── deploy.txt          ★ 部署形态自识别 (centralized / distributed / single-node / unknown-*)
├── report.tsv          ★ 主报告 · 头 4 行元数据 + 每行一 check 状态
├── manual.md           需人审 method 全列表 (描述性中文 / distill 字段残留 / 拼错 SQL 等)
├── skip.md             NULL/空 method 列表
├── stdout/<cid>.txt    auto 类 stdout
├── stderr/<cid>.txt    auto 类 stderr  
└── cmd/<cid>.sh        auto 类真跑的命令 (头注释 + method · 便于单条复跑)
```

### report.tsv 头部元数据示例

```
# deploy_form  centralized
# detected_at  2026-05-22T23:44:12-04:00
# host         rhel8.10-1
# user         Ruby
check_id  exit_code  status
chk-autovacuum  0  ok
...
```

---

## 5. 关键设计原理

### 5.1 部署形态自识别 (3 态)

```sql
SELECT pg_catalog.gs_deployment();
-- BusinessCentralized   → centralized
-- Distribute            → distributed
-- SingleNode / single_node → single-node
```

`gs_deployment()` 是 GaussDB 内置 C immutable 函数,跨内核版本稳。**不用** `pg_catalog.pgxc_node` 表存在性 — GaussDB 507 集中式也保留这个 catalog (空表) 不可靠。

实测 192.168.1.5 三集群正确识别 (`centralized` / `distributed` / `distributed`)。

### 5.2 method normalize (build 时)

`_build-precompiled.mjs` 在 inline 进 .sh/.py 前对每条 method 做这些清洗:

1. **strip 包裹**: backtick / quote / ` ``` ` 代码 fence
2. **unicode dash → ASCII**: `–` (en-dash) `—` (em-dash) `−` (minus) → `-` (distill 蒸 HTML 时 typographic 替换 · 工具不识别非 ASCII dash)
3. **strip gsql prompt 残留**: `gaussdb=# ` / `yshen=# ` / `[a-z_]+=[#>]` 行内 / 行首 都去
4. **砍 ` -- ` 行内注释**: distill 在 method 后塞 `或 SELECT ...` 中文注释,bash 看到 `--` 当下一行 cmd
5. **strip leading prompt**: `$ ` / `# `
6. **`top` 单跑 → `top -b -n 1`**: 非交互 tty 必须 batch mode
7. **`sar` 单跑 → `sar -u 1 1`**: 同理

### 5.3 isManual heuristic (build 时切走"不可执行" check)

`_build-precompiled.mjs` 把这些判 manual(不进 auto 跑):

- 含 ≥4 汉字 (短中文描述)
- 含描述关键词 (`查看` / `判断是否` / `通常` / `建议` / `日志中` / `如果发现` 等 20+ 词)
- distill 字段残留 (`- **<word>**:` 开头)
- 纯中文 metric (含汉字 + ASCII alphanumeric < 5)
- 单 token 视图名 (`[a-z_][a-z0-9_.]+` · 长度 > 6 · 不在 OS 命令白名单)
- 含中文占位符 (`进程号` / `实例号` / `xxx` / `<var>`)
- 起始中文动词 (`查询` / `查看` / `检测` / `分析` / `定位` / `确认` / `计算` / `获取` / `读取` / `检查` / `执行`)
- shell 工具 + PID 占位 (`gstack 14104` / `strace -p 12345` 等)
- GaussDB 集群工具 (`gs_ssh` / `gs_om` / `cm_ctl` / `gs_check` / `gs_collector` / `gs_dump`) — 集中式无效
- 日志关键词 (`WARNING:` / `ERROR:` / `FATAL:` 开头)

### 5.4 SQL/shell 自动 dispatch (collector 跑时)

`collect-precompiled.{sh,py}` 跑每条 method 前看第一个 token,决定 `gsql -f` 还是 `bash`:

```
SELECT | EXPLAIN | SHOW | WITH | SET | VACUUM | ANALYZE
| CREATE | ALTER | DROP | TRUNCATE | UPDATE | INSERT | DELETE
| COPY | REINDEX | CHECKPOINT | GRANT | REVOKE | RESET
| BEGIN | COMMIT | ROLLBACK | CALL | VALUES
```

起始词在这个列表 → `gsql -d postgres -f /tmp/<cid>.sql` 跑 (集中式分布式都用 `gsql`)。否则 → `bash` 跑。

---

## 6. 已知问题 / TODO

### 6.1 iostat rc127 (环境问题 · 非脚本问题)

192.168.1.5 上 sysstat 包没装 (iostat/sar/pidstat/vmstat 都不在 PATH)。`yum install -y sysstat` 失败 — 系统的 yum repo 指向 `file:///mnt/cdrom/` 但 cdrom 没挂载,VM 也没光驱。

**修法选项**:
- (a) 给 VM 挂 RHEL 8.10 ISO 到 `/mnt/cdrom`,然后 `yum install -y sysstat`
- (b) 配 EPEL / RHEL CDN 网络 repo
- (c) 直接 `scp sysstat-12.x.rpm` 上去 `rpm -i`

### 6.2 ghost-ok 防漏

`gsql -f` 默认 batch mode,SQL 报错 exit 0,collector 会标 ok。v5 通过 isManual 大部分过滤了(切了 8 个),但可能仍有漏过的。

**修法**:collector 加 stderr 探:
```bash
if [ "$rc" = "0" ] && grep -qE '^(gsql:.+:\s*)?(ERROR|FATAL|PANIC):' "$OUTDIR/stderr/$cid.txt"; then
  s="ghost-ok-sql-error"
fi
```

### 6.3 ~~真做 deploy form 分桶~~ ✅ 已落地 (2026-05-29 · case 级 topology 分桶)

不再靠"跑完对比 stdout",改为 **case 级 topology 字段** 驱动:
- distill 给每个 case 标 `topology` (common/centralized-only/distributed-only) · gaussdb 按此拆
  `cases/gaussdb/{common,centralized,distributed}/`;
- `extract-offline-checklist.mjs` 把 topology 继承到每个 check (写进 `checklist.ndjson`);
- collector 用 `gs_deployment()` 写 `deploy.txt`,**采集时**就跳过冲突 topology 的 check
  (标 `report.tsv` 的 `skip-topology`);
- `match-collect-to-cases.mjs` 反喂时按 `deploy.txt` 只撞相关 topology 的 check,出两段候选。

设计/计划: `docs/superpowers/specs/2026-05-28-gaussdb-offline-topology-routing-design.md`
+ `docs/superpowers/plans/2026-05-29-gaussdb-topology-plan{1,2}-*.md`。

### 6.4 ~~reasons.tsv 没记 manual 决策依据~~ ✅ 已做 (2026-05-23)

build 时落 `manual-audit.md` (本地工程文件 · 不在 outdir),每条 manual 带:
- `matched_rule` (r0 ~ r10,对应 isManual 的 10 条规则)
- 派生命令 `derived_commands` — 启发式从描述里挖出 0..N 个"看起来能跑"的命令作为人审起点(已知视图 → `SELECT * LIMIT 50`、GUC → `SHOW`、OS 命令直引、RDS metric → 标准采集、中文兜底)
- 蒸馏原文

153 manual 项里 **151 有派生命令** (覆盖率 98.7%),剩 2 条是纯主观建议(尝试在低峰时跑 / 重复执行同一 SQL)无标准命令。

重新生成:`node _build-precompiled.mjs`。

### 6.5 chk-iostat / chk-vecnestloopruntime 等真 OS 命令应该保留 auto

`iostat` / `gstack <pid>` 都是真 OS 工具,只是当前环境没装/含真 PID 占位被 isManual 切走。可考虑这些**保留 auto + 给 hint** "需要装 sysstat" 类提示,而非进 manual。

### 6.6 视图重叠 → 合并采集 (新)

`view-overlap-analysis.md` 显示 17 个 hot view 被反复查 134 次,合并后只需 42 次 (省 68.7%)。
特别是 `pg_stat_user_tables` (12 次)、`pg_stat_activity` (10 次)、`statement_history` (10 次)、
`gs_wlm_session_history` (9 次) 等,适合"环境查一次 + 本地 filter/agg"。

**修法 (TODO 没做)**: 写 `collect-merged.{sh,py}` 跟 precompiled 并列:
- 服务器端: 每 hot view 只 `SELECT * FROM v` 一次,落 \`raw/<view>.tsv\`
- 本地: \`post-process.{mjs,py}\` 读 raw/ · 按 check_id 的 filter/agg recipe 派生结果
- 适用: 现场 round-trip 慢 / 想要跨 check 快照一致 / 本地做 ad-hoc 二次分析
- 不适用: 大表 (\`statement_history\` 全表可能 GB 级,仍需 LIMIT/WHERE)

完整版 (precompiled) 不动,两套并存,README 加决策矩阵。

---

## 7. 测试环境 (192.168.1.5 同物理机 3 个 GaussDB 实例)

| 实例 | OS user | env file | PGPORT | gs_deployment() | 用途 |
|---|---|---|---:|---|---|
| `gauss_new` | Ruby | `~/gauss_env_file` | 37000 | `BusinessCentralized` | 集中式 507 |
| `gauss_dist` | dist_505 | `~/gauss_env_dist` | 25000 | `Distribute` | 分布式 505.2.1 (3 节点) |
| `gauss_dist_new` | dist_505_new | `~/gauss_env_dist_new` | 35000 | `Distribute` | 分布式 505_new (3 CN) |

SSH 入口: `root@192.168.1.5:2201` (memory 凭据 — 不入仓)

集中式连接信息(perf-kp-sql 端到端 e2e 用):
- SSH: `192.168.1.5:2201` · user root
- DB port: 37000
- DB user: `Ruby` (trust auth · 走 Unix socket `/data/gauss_new/tmp`)
- 默认库: `postgres`
- env: VM 内 `~/gauss_env_file` (source 后再 gsql)

---

## 8. 怎么重新生成 precompiled

改 checklist.ndjson 或 `_build-precompiled.mjs` 里 normalize / isManual 后:

```bash
cd plugins/perf-kp-sql/docs/offline-collect-kit
node _build-precompiled.mjs
# 输出: collect-precompiled.sh + collect-precompiled.py 重新落地

# verify 跑
COLLECT_DRYRUN=1 ./collect-precompiled.sh /tmp/dryrun-test
# 看 report.tsv status 分布
```

ndjson 重新生成 (改了 perf-kp-sql case 库后):
```bash
cd <db-distill-engine-dev>/runs/gaussdb-tuning-kunpeng/scripts
node extract-offline-checklist.mjs
# 输出: plugins/perf-kp-sql/docs/gaussdb-offline-checklist.{md,ndjson}
# kit 目录里再 cp 一份 checklist.ndjson
```

---

## 9. 关键 commit history

```
e3d9535  fix(offline-kit): method normalize + isManual 加强 · ok 率 86.6% → 99.4%
2cc04a1  refactor(offline-kit): detect_deploy_form 改用 GaussDB 内置 gs_deployment()
089e9ab  feat(offline-kit): collect-precompiled 自识别集中式 vs 分布式 (旧 GUC 法)
ee01eb5  chore: 清理 git add 误带的测试 stdout 文件
8ebd61f  feat(offline-kit): 加预编译版 collect-precompiled.{sh,py}
ece8932  fix(offline-kit): collect.sh 改成纯 bash+jq · 不依赖 python3
9a59128  docs: GaussDB 离线采集 kit + 端到端复现清单 (kit 初版)
```

---

## 10. 跟其他 skill 的关系

- **db-distill-engine** (`db-distill-engine-dev` 仓): 上游 distill 数据源 · 蒸馏 GaussDB 文档产 case 库 · 改了上游后要重跑 `extract-offline-checklist.mjs` 出新 ndjson
- **perf-kp-sql** (`ohsql-plugin-dev` 仓本目录的父 skill): 在线诊断模式 · 这套 kit 是它的离线版补充
- **cpu-flamegraph** (姐妹 skill): perf-kp-sql 火焰图采集委托 · 跟离线 kit 平行 · 火焰图采集需要 SSH 不能离线
