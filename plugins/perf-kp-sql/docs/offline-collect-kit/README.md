# GaussDB 离线采集 kit

把这个目录 scp 到 GaussDB 服务器,跑一份"指标 + 参数现值"采集,然后把结果带回本地反喂 perf-kp-sql skill 做诊断。**适用场景:** 内网/无 SSH 直连环境,perf-kp-sql skill 不能远程实时采集。

## 内容

```
offline-collect-kit/
├── README.md                    本文件
├── checklist.ndjson             290 个真采集 check (GaussDB 关联 · 已剔文档示例)
│
├── collect-precompiled.sh       ★ 预编译版 bash · auto 命令 inline · 完全自包含
├── collect-precompiled.py       ★ 预编译版 python · auto 命令 inline · 纯 stdlib
│
├── collect.sh                   现场解析版 bash · 读 ndjson · 依赖 jq
├── collect.py                   现场解析版 python · 读 ndjson · 纯 stdlib
│
├── extract-offline-checklist.mjs  ★ 源头 · 从 perf-kp-sql case 库筛 gaussdb + A3 剔文档示例 → ndjson
└── _build-precompiled.mjs         本地工具 · checklist.ndjson → precompiled.{sh,py} (本地跑 · 不部署)
```

### 完整再生链 (改了 case 库后重跑)

```bash
# 1. 从 perf-kp-sql case 库重新筛 GaussDB 采集清单 (写到 ../gaussdb-offline-checklist.ndjson)
node extract-offline-checklist.mjs
# 2. cp 到 kit + 重编译自包含脚本
cp ../gaussdb-offline-checklist.ndjson checklist.ndjson
node _build-precompiled.mjs
```

## 两种形态选哪个

| 形态 | 文件 | 依赖 (db 服务器) | 适合 |
|---|---|---|---|
| **预编译** ★ 推荐 | `collect-precompiled.{sh,py}` | bash / python3 自带 · **无外部** | 部署到 db 服务器 · 一份脚本拷过去就跑 · 内网/隔离环境 |
| 现场解析 | `collect.{sh,py}` + `checklist.ndjson` | sh 版要 jq · py 版纯 stdlib | 本地开发 / 频繁改 checklist 时 |

**预编译** = 216 个 ready-to-run 命令直接 inline 在脚本里 (heredoc / tuple list),不需要 db 服务器装 jq、不需要现场解析 ndjson。改 checklist 后本地跑一次 `node _build-precompiled.mjs` 重编译 precompiled.{sh,py} 即可。

### 依赖安装(db 服务器一次性)

```bash
# RHEL / CentOS / openEuler
yum install -y jq coreutils                 # sh 版
# Ubuntu / Debian
apt install -y jq coreutils                 # sh 版
# python3 各发行版基本都自带 (3.6+)         # py 版无需额外装
```

## 部署 + 运行 (预编译版 · 推荐)

```bash
# 1. 只拷一个文件 (要 bash 拷 .sh,要 python 拷 .py)
scp collect-precompiled.sh root@<gaussdb-host>:/tmp/

# 2. 登服务器 · source gsql env · 跑
ssh root@<gaussdb-host>
source ~/gauss_env_file
COLLECT_TIMEOUT=10 /tmp/collect-precompiled.sh ./out-$(hostname)-$(date +%Y%m%d)

# 3. 拷结果回本地
scp -r root@<gaussdb-host>:./out-* ./
```

## 部署 + 运行 (现场解析版)

```bash
# 整个目录都要拷 (checklist.ndjson + collect.sh + collect.py)
scp -r offline-collect-kit/ root@<gaussdb-host>:/tmp/
ssh root@<gaussdb-host>
cd /tmp/offline-collect-kit
source ~/gauss_env_file
./collect.sh checklist.ndjson ./out-$(hostname)-$(date +%Y%m%d)
# 或 python3 collect.py --checklist checklist.ndjson --out ./out-$(hostname)-$(date +%Y%m%d)
```

## 行为

对每个 check:

| method 判定 | 行为 | 状态码 |
|---|---|---|
| `NULL` / 空 | 跳过 | `skip-empty` |
| 含 ≥8 个汉字 OR 含描述词(查看 / 通常 / 建议 / 如果 / 排查 ...) | 跳过 + 列入 manual.md 给你人审 | `manual-descriptive` |
| 真命令(GUC SHOW / OS top / gsql) | `bash -c "<method>"` 跑 · 捕获 stdout/stderr · 默认 5s timeout | `auto-ok` / `auto-error-rcN` / `auto-timeout` |

## 部署形态过滤(topology)

collector 用 `gs_deployment()` 自识别部署形态写 `deploy.txt`,并据此跳过无关 check:

| deploy_form | 跳过 | 采集 |
|---|---|---|
| `centralized` / `single-node` | `distributed-only`(CN/DN/redistribute/DWS 等) | `common` + `centralized-only` |
| `distributed` | `centralized-only` | `common` + `distributed-only` |
| `unknown-*` | 不跳(全采) | 全部 + stderr 提示 `⚠️ topology-filter-disabled` |

被跳的 check 在 `report.tsv` 标 `status=skip-topology`(可审计 · 不悄悄消失)。
每条 check 的 topology 继承自其 linked case(在 `checklist.ndjson` 的 `topology` 字段;
gaussdb case 的 topology 由 `cases/gaussdb/{common,centralized,distributed}/` 子目录定)。

## 输出目录布局

```
out-<host>-<date>/
├── collect-report.ndjson    341 行 · 每行一 check 状态汇总 (主报告)
├── manual.md                需人审 method 集合 (描述性中文 → 你自己跑)
├── stdout/<check_id>.txt    auto-ok 的 stdout
├── stderr/<check_id>.txt    auto-error 的 stderr
├── cmd/<check_id>.sh        真正执行的命令 (头加 check_id/name/layer 注释 · 便于复跑)
└── parsed.tsv               ndjson → TSV 解析中间产物 (仅 bash 版有)
```

## 环境变量(bash 版)

```bash
COLLECT_TIMEOUT=10  ./collect.sh        # 默认 5s · 慢命令可放宽
COLLECT_DRYRUN=1    ./collect.sh        # 不真跑 · 只分类 manual/auto
```

## 数据来源

- checklist.ndjson 由本目录 `extract-offline-checklist.mjs`(2026-05-25 从 db-distill-engine
  仓收编 · 它属 perf-kp-sql 离线套件不属蒸馏引擎)从
  `plugins/perf-kp-sql/data/cases/indices/by-check-item/CASES.md` 过滤生成
- 过滤标准: check.linked_case_ids ∩ (`cases/gaussdb/` ∪ `cases/gaussdb-dws/`) ≠ ∅
- A3 剔除文档示例 SQL: 写操作 DDL/DML(CREATE/INSERT/...) + 只读查询 FROM 跟非 trusted
  系统视图(t1/customer/skew 等业务示例表)· 341 → 290 真采集

## 拿回结果之后

把 `out-*/`(含 `deploy.txt` + `stdout/`)整个目录拷回本地,跑反喂(按 `deploy.txt`
自动只撞相关 topology 的 check):

```bash
node match-collect-to-cases.mjs \
    --collect out-<host>-<date>/ \
    [--checklist checklist.ndjson]   # 默认用本目录 checklist.ndjson
    [--cases ../../data/cases]       # 默认相对本目录定位 · case 级 topology 二次过滤用
```

> 双重过滤:check 级(按 check.topology 跳无关 check)+ case 级(common check 可能 link
> 到 distributed case,集中式下按 case 自身 topology 再剔)· 确保候选不含本形态无关的 case。

产出 `out-*/match-candidates.{md,ndjson}` 两段:
- `自动命中候选` —— 有阈值且采集值越界(带"实测值 vs 阈值"证据)
- `待判候选` —— 阈值 NULL/不可机械比 · 附 stdout · 交后续 skill 的 LLM/人判

诊断报告仍由 perf-kp-sql skill 的 Phase 4/5 出(本工具只出候选 case_id)。

## 预估自动率

| 阶段 | 数 | 比例 |
|---|---:|---:|
| 总 check | 341 | 100% |
| 描述性中文 method (manual) | ~205 | ~60% |
| GUC 参数 (SHOW · auto-ok) | 54 | 16% |
| 真命令 (OS/db-shell/gsql 类 · auto) | ~80 | ~24% |
| NULL/空 (skip) | ~2 | ~1% |

跑完看 `collect-report.ndjson` 实际数。
