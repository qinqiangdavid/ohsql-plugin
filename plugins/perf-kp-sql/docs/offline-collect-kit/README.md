# GaussDB 离线采集 kit

把这个目录 scp 到 GaussDB 服务器,跑一份"指标 + 参数现值"采集,然后把结果带回本地反喂 perf-kp-sql skill 做诊断。**适用场景:** 内网/无 SSH 直连环境,perf-kp-sql skill 不能远程实时采集。

## 内容

```
offline-collect-kit/
├── README.md                    本文件
├── checklist.ndjson             399 个 check (GaussDB 关联 · 165 auto 可盲跑 / 220 manual / 14 空)
│
├── collect-precompiled.sh       ★ 现场采集器 bash · auto 命令 inline · 完全自包含(拷一个文件就跑)
├── collect-precompiled.py         同款 python 版 · 纯 stdlib(主机只有 python 没 bash 时用)
│
├── extract-offline-checklist.mjs  ★ 源头 · 从 perf-kp-sql case 库筛 gaussdb + A3 剔文档示例 → ndjson
└── _build-precompiled.mjs         本地工具 · checklist.ndjson → collect-precompiled.{sh,py} (本地跑 · 不部署)
```

> 现场只需 **collect-precompiled.sh 一个文件**:自包含、不要 jq、不要 checklist.ndjson、不要现场解析。
> 早先的"现场解析版"`collect.{sh,py}`(读 ndjson + 依赖 jq + 无 gsql 派发/topology 跳过)已移除。

### 完整再生链 (改了 case 库后重跑)

```bash
# 1. 从 perf-kp-sql case 库重新筛 GaussDB 采集清单 (写到 ../gaussdb-offline-checklist.ndjson)
node extract-offline-checklist.mjs
# 2. cp 到 kit + 重编译自包含脚本
cp ../gaussdb-offline-checklist.ndjson checklist.ndjson
node _build-precompiled.mjs
```

## 采集器 = collect-precompiled.sh(自包含 · 无外部依赖)

165 个 ready-to-run 命令直接 inline 在脚本里 (heredoc),**db 服务器不需要装 jq、不需要 checklist.ndjson、不需要现场解析**。bash 各发行版自带、`timeout`(coreutils)一般也有。改 checklist 后本地跑一次 `node _build-precompiled.mjs` 重编译即可。

> 主机只有 python 没合适 bash 时,用同款 `collect-precompiled.py`(纯 stdlib,用法相同)。

## 部署 + 运行(只拷一个文件)

```bash
# 1. 拷一个文件到服务器
scp collect-precompiled.sh root@<gaussdb-host>:/tmp/

# 2. 登服务器 · 跑(端口作为第 2 入参 · 不传则用 PGPORT 环境变量)
ssh root@<gaussdb-host>
source ~/gauss_env_file                                     # 若 env 已设 PGPORT 可省下方端口入参
/tmp/collect-precompiled.sh ./out-$(hostname)-$(date +%Y%m%d) 37000

# 3. 拷结果回本地
scp -r root@<gaussdb-host>:./out-* ./
```

入参:`collect-precompiled.sh [outdir] [port]` · 环境变量 `COLLECT_TIMEOUT`(单命令超时秒,默认 5)。

## 行为

对每个 check:

脚本只 inline **能盲跑的 auto 命令**(构建时 `_build-precompiled.mjs` 的 r0–r12 规则已筛掉:空/描述性中文/distill 残留/单标识/`<占位符>`/explain 需目标 SQL/非"无参只读"命令等 → 进 `manual-audit.md`,不 inline)。运行时对每个 inline 的 auto 命令:

| 命令类型 | 行为 | 状态码 |
|---|---|---|
| 首词是 SQL 关键字(SELECT/SHOW/WITH...) | `gsql -f` 跑(自动派发)· 默认 5s timeout | `auto-ok` / `error-rcN` / `timeout` |
| 完整 `gsql -c "..."` / OS 只读(cat/iostat/top...) | `bash` 跑 | 同上 |
| rc=0 但 SQL 报错(gsql batch 特性) | 标记 | `ghost-ok-sql-error` |
| 集中式跑分布式专用视图(单节点不支持) | 标记(非真错) | `unsupported-deploy-form` |

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
├── report.tsv             异常清单 · 只记非 ok(skip-topology/error/timeout/ghost/unsupported)· 全 ok 则仅表头
├── deploy.txt             gs_deployment() 探到的部署形态
├── <check_id>.txt         每条 check 一个数据文件 (文件名=check_id=抓的是什么 · 纯 stdout)
└── errors.log            所有报错汇总 (按 check_id 标记 · 不再每条一个 stderr 文件)
```

> 一条 check 一个数据文件(不再 stdout/ stderr/ cmd/ 三个子目录);报错全进 `errors.log`。

## 环境变量

```bash
COLLECT_TIMEOUT=10  ./collect-precompiled.sh ./out 37000   # 单命令超时 · 默认 5s
PGPORT=37000        ./collect-precompiled.sh ./out         # 端口也可走环境变量(命令行第2入参优先)
```

## 数据来源

- checklist.ndjson 由本目录 `extract-offline-checklist.mjs`(2026-05-25 从 db-distill-engine
  仓收编 · 它属 perf-kp-sql 离线套件不属蒸馏引擎)从
  `plugins/perf-kp-sql/data/cases/indices/by-check-item/CASES.md` 过滤生成
- 过滤标准: check.linked_case_ids ∩ (`cases/gaussdb/` ∪ `cases/gaussdb-dws/`) ≠ ∅
- A3 剔除文档示例 SQL: 写操作 DDL/DML(CREATE/INSERT/...) + 只读查询 FROM 跟非 trusted
  系统视图(t1/customer/skew 等业务示例表)· 399 check · 其中 165 auto 可盲跑

## 拿回结果之后

把 `out-*/`(含 deploy.txt + 各 <check_id>.txt)整个目录拷回本地,跑反喂(按 `deploy.txt`
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

## 自动率(当前 checklist)

| 类别 | 数 | 比例 |
|---|---:|---:|
| 总 check | 399 | 100% |
| **auto(可盲跑 · inline 进脚本)** | **165** | **41%** |
| manual(描述性/explain/占位/需入参 → manual-audit.md) | 220 | 55% |
| 空 (skip) | 14 | 4% |

165 auto 里:85 SQL 视图查询 + 67 完整 gsql 命令 + 6 SHOW 参数 + 7 OS 只读。跑完看 `report.tsv` 实际状态分布(集中式下约一半 auto 会因 distributed-only 标 `skip-topology`)。
