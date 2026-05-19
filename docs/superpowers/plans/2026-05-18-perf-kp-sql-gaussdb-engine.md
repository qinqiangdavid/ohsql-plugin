# perf-kp-sql GaussDB engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** v0.2(2026-05-18 重写 · 应用 Sonnet review + archer-interface-notes 校准)

**Goal:** 给现有 perf-kp-sql skill 加 `engine=gaussdb` 支持 · 把 archer-ui 新体系 `gs_dsw/funcs/` 已有的 GaussDB 离线诊断能力(6 个 Diagnoser · 22+ 条规则 + 15 个 BaseModel + `ModelRunner` + `SlowSQLDiagnoser` 编排 + `health_report.run()` 顶层入口)抽进 skill 内部 · 实现 collected zip → markdown 报告的端到端。

**Architecture:** 现有 7-phase LLM 编排流水线保留 · Phase 0 / Phase 3 子步替换(SSH 远程 → zip 解包 + `run.py` 包装 archer `health_report.run(WebArgs)`)· case 库 engine 平级隔离(`data/cases/{mongo,gaussdb}/`)· mongo 现有 case 文件也要挪进子目录。

**重要 v0.2 改动**:
- ❌ 不复用 `udf_funcs.py`(旧体系已废弃,依赖找不到的 C 扩展 `import diagnose`)
- ❌ 不复用 `cluster_checker.py`(SSH 日志采集脚本,不是诊断规则)
- ❌ 不复用 `wdr_comparison.py`(WDR HTML 对比工具,不是诊断规则)
- ✅ 复用 `gs_dsw/funcs/` 新体系:`ModelRunner / BaseModel / 4 个活跃 Diagnoser / 2 个 bak/ Diagnoser / SlowSQLDiagnoser / health_report.run`
- ✅ 22+ 条规则(不是原假设的 12 条 udf)

**Tech Stack:** Python 3 (archer 诊断逻辑 + run.py CLI) · Bash (dbcollect.sh / dn-helper.sh 采集脚本) · GaussDB gsql + EXECUTE DIRECT (跨 DN 采集) · NotebookLM (openGauss 公开文档权威源) · pytest (archer testcases 移植)

**Spec reference:** `docs/superpowers/specs/2026-05-18-perf-kp-sql-gaussdb-engine-design.md`

**仓库现状关键差异(spec §3.1 路径需修正)**:case 数据在 `plugins/perf-kp-sql/data/`(plugin 根)而**不是** `skills/perf-kp-sql/data/`(skill 子目录)。所有新增 `data/cases/gaussdb/` 和 `data/engines/gaussdb/` 都放在 plugin 根的 `data/` 下。

---

## 路径规范(全局)

- **plugin 根**:`plugins/perf-kp-sql/`
- **skill 主目录**:`plugins/perf-kp-sql/skills/perf-kp-sql/`(只有 SKILL.md + scripts/ ?)
- **数据目录**:`plugins/perf-kp-sql/data/`(case + engines 都在这)
- **本仓库根**:`/Users/david/code/ohsql-plugin-dev/`

后续所有"data/" 开头的相对路径都相对**plugin 根** `plugins/perf-kp-sql/`。

---

## 文件结构总览

```
plugins/perf-kp-sql/
├── data/
│   ├── cases/
│   │   ├── mongo/                                     新建 · M3.0 挪现有文件
│   │   │   ├── INDEX.md                               (从 data/cases/ 移)
│   │   │   ├── CASES.md                               (从 data/cases/ 移)
│   │   │   └── indices/
│   │   │       ├── by-source-url.json                 (从 data/cases/indices/ 移)
│   │   │       └── by-check-item/
│   │   │           ├── INDEX.md                       (从 data/cases/indices/by-check-item/ 移)
│   │   │           └── CASES.md                       (从 data/cases/indices/by-check-item/ 移)
│   │   └── gaussdb/                                   新建 · M1.case 写
│   │       ├── INDEX.md                               12 条 case 路由
│   │       ├── CASES.md                               12 条 case 详情(沿用 mongo H2 格式)
│   │       └── indices/
│   │           ├── by-source-url.json                 NLM 喂料 URL 列表
│   │           └── by-check-item/
│   │               ├── INDEX.md                       check-item 路由(从 cases 派生)
│   │               └── CASES.md                       check-item 详情
│   └── engines/
│       └── gaussdb/                                   新建 · M1.collect + M1.diag
│           ├── collect/
│           │   ├── dbcollect.sh                       CN 主脚本 · M1.collect.5
│           │   ├── dn-helper.sh                       DN 助手 · M1.collect.7
│           │   ├── README.md                          采集脚本使用说明
│           │   └── sql/                               19 个 SQL 模板 · M1.collect.1
│           │       ├── pg_settings.sql
│           │       ├── pg_stats.sql
│           │       ├── pg_class.sql
│           │       ├── pg_stat_all_tables.sql
│           │       ├── pg_total_autovac_tuples.sql
│           │       ├── statement_history.sql
│           │       ├── summary_statement.sql
│           │       ├── ddl_table_def.sql
│           │       ├── col_type.sql
│           │       ├── table_column.sql
│           │       ├── index_cols.sql
│           │       ├── index_collation.sql
│           │       ├── gpi_check.sql
│           │       ├── ndv.sql
│           │       ├── type_cast.sql
│           │       ├── type_operator.sql
│           │       ├── gs_gsc_dbstat_info.sql
│           │       ├── pgxc_thread_wait_status.sql
│           │       └── pgxc_get_senders_catchup_time.sql
│           └── diag/
│               ├── __init__.py
│               ├── run.py                             CLI 入口 · M1.diag.6 · 包装 health_report.run
│               ├── transform.py                       archer final_report_data → hits.json · M1.diag.6
│               ├── models/                            archer 15 BaseModel + ModelRunner · M1.diag.1
│               │   ├── __init__.py
│               │   ├── base.py                        BaseModel 抽象 + ModelRunner 调度器
│               │   ├── statement_history_model.py
│               │   ├── pg_class_model.py
│               │   ├── pg_stats_model.py
│               │   ├── pg_setting_model.py
│               │   ├── pg_stat_all_tables_model.py
│               │   ├── pg_total_autovac_tuples_model.py
│               │   ├── summary_statement_model.py
│               │   ├── index_cols_model.py
│               │   ├── index_collation_model.py
│               │   ├── table_column_model.py
│               │   ├── col_type_model.py
│               │   ├── ndv_model.py
│               │   ├── type_operator_model.py
│               │   ├── type_cast_model.py
│               │   ├── gpi_check_model.py
│               │   ├── gs_gsc_dbstat_info_model.py
│               │   └── pgxc_*_model.py                新建 · 分布式视图(M1.diag.5)
│               ├── diagnosers/                        6 个 Diagnoser class · M1.diag.2-3
│               │   ├── __init__.py
│               │   ├── instance_checker.py            InstanceDiagnoser(2 规则)
│               │   ├── index_checker.py               IndexCheckerDiagnoser(8 规则)
│               │   ├── sql_checker.py                 StaticDiagnoser(N SQL 反模式)
│               │   ├── sqlplan_checker.py             PlanDiagnoser(4 规则)
│               │   ├── waitevent_checker.py           WaitDiagnoser(4 规则)从 bak/ 提
│               │   └── memory_checker.py              MemoryDiagnoser(4 规则)从 bak/ 提
│               ├── pipeline/                          编排 · M1.diag.4
│               │   ├── __init__.py
│               │   ├── slowsql.py                     SlowSQLDiagnoser(从 bak/ 提)
│               │   └── health_report.py               run(WebArgs)顶层入口(从 bak/ 提)
│               ├── util/                              archer util · M1.diag.4
│               │   ├── __init__.py
│               │   ├── sql.py                         SQLDiagnosticEngine
│               │   ├── sqlplan.py                     执行计划规则库
│               │   ├── deadlock.py
│               │   └── print.py
│               ├── requirements.txt                   Python 依赖
│               └── tests/                             M1.diag.7
│                   ├── __init__.py
│                   ├── conftest.py
│                   ├── fixtures/
│                   │   ├── bad_sql.sql
│                   │   ├── bad_plan.sql
│                   │   └── sample-collected.zip      合成 fixture · 端到端用
│                   ├── test_cluster_checker.py
│                   ├── test_instance_checker.py
│                   ├── test_index_checker.py
│                   ├── test_sql_checker.py
│                   ├── test_sqlplan_checker.py
│                   ├── test_memory_checker.py
│                   └── test_run_py.py                端到端 · M1.diag.9
├── skills/
│   ├── perf-kp-sql/SKILL.md                          M3.skill 改造
│   └── perf-kp-sql-setup/                            M3.setup 扩 NLM
│       └── SKILL.md
└── docs/superpowers/
    ├── specs/2026-05-18-perf-kp-sql-gaussdb-engine-design.md
    └── plans/2026-05-18-perf-kp-sql-gaussdb-engine.md (本文件)
```

---

## Phase 0 · 准备工作(独立 worktree + 探索现状)

### Task 0.1: 起 worktree

**Files:**
- Create: `/Users/david/code/perf-kp-sql-gaussdb-wt/`(git worktree 隔离副本)

- [ ] **Step 1: 检查仓库 main 干净度**

```bash
cd /Users/david/code/ohsql-plugin-dev
git status -sb
```
Expected: `## main...origin/main`(无未提交改动)

- [ ] **Step 2: 用 superpowers:using-git-worktrees skill 起 worktree**

skill 会自动建 `/Users/david/code/perf-kp-sql-gaussdb-wt/` worktree 指向新分支 `feat/gaussdb-engine`(或类似命名)。

- [ ] **Step 3: 后续所有操作 cd 进 worktree**

```bash
cd /Users/david/code/perf-kp-sql-gaussdb-wt
git status -sb
```
Expected: `## feat/gaussdb-engine`

### Task 0.2: 探索 archer 实际函数签名(读 udf_funcs / parse_dict / generate_report_v1 全文)

读 archer 关键文件全文,记笔记到 worktree 临时 markdown(`/tmp/archer-notes.md` 或 worktree 内 `notes/`):

**Files:**
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dignose_report/udf_funcs.py`(全 393 行)
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dignose_report/parse_dict.py`(全 101 行)
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dignose_report/generate_report_v1.py`(全 96 行)
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dignose_report/diagnose_report_v1.py`(全 69 行 — 已部分读过)
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/cluster_checker.py` 全文
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/instance_checker.py` 全文
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/index_checker.py` 全文
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/sql_checker.py` 全文
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/sqlplan_checker.py` 全文
- Read: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/wdr_comparison.py` 全文

- [ ] **Step 1: Read 上面所有文件,写一份接口笔记**

笔记内容:
1. `UdfRet` 完整字段定义(class 体)
2. 每个 udf 函数的入参签名 + 返回值
3. 每个 checker 的入口函数签名(可能不叫 `run`)
4. `parse_dict.parse_common_dict_data(data)` 接受的 data 形态是什么(spec 里说是 list,实际是?)
5. `generate_report_v1.report_html(json_str, html_path)` 消费 dict 的字段名
6. 验证 spec §13 风险 1(UdfRet 是否够细)

输出位置:`notes/archer-interface-notes.md`(worktree 内,不入正式 commit · 或入 commit 作为开发文档,看个人偏好)

- [ ] **Step 2: 记录跟 spec 不一致的地方**

如果发现 archer 实际接口跟 spec §6.1 / §6.2 描述不符,在笔记里标 `⚠️ 偏差 N:...`,后续 Task 修正。

### Task 0.3: 探索 perf-kp-sql 现状代码(mongo case 格式 + SKILL.md 路径引用)

**Files:**
- Read: `plugins/perf-kp-sql/data/cases/INDEX.md`(全 108 行)
- Read: `plugins/perf-kp-sql/data/cases/CASES.md`(首 200 行看 H2 格式 + 至少 3 个完整 case)
- Read: `plugins/perf-kp-sql/data/cases/indices/by-check-item/INDEX.md` 头 50 行
- Read: `plugins/perf-kp-sql/data/cases/indices/by-source-url.json`(全)
- Read: `plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md`(全 1814 行 — 已部分读过,补全)
- Read: `plugins/perf-kp-sql/skills/perf-kp-sql-setup/SKILL.md`(全)
- Read: `plugins/perf-kp-sql/scripts/notebooklm.mjs`(看 NLM 注册逻辑)
- Read: `plugins/perf-kp-sql/scripts/ssh.mjs`(看 SSH wrapper · 不修改,但要理解)
- Read: `plugins/perf-kp-sql/tests/cases/golden-validity.test.ts`(看 case 库测试模式)
- Read: `plugins/perf-kp-sql/tests/cases/field-integrity.test.ts`
- Read: `plugins/perf-kp-sql/tests/cases/index-integrity.test.ts`

- [ ] **Step 1: 记录 mongo CASES.md 的 H2 case 完整字段清单**

把所有 `- **field**: value` 字段列出 + `### symptom_description` / `### diagnostic_steps` / `### likely_causes` 子段格式(含 code block 内部 `[step N] / metric_name: / collection_method_quote: / abnormal_pattern_quote: / abnormal_pattern_threshold: / metric_unit: / prerequisite_steps:`)。

输出位置:`notes/mongo-case-format.md`

- [ ] **Step 2: 列 SKILL.md 里所有需要改的 `data/cases/` 路径引用**

grep + 人工 review,输出清单到 `notes/skillmd-path-refs.md`,每条标:
- 行号
- 当前内容
- 改后目标(`data/cases/INDEX.md` → `data/cases/<engine>/INDEX.md`,`<engine>` 是 LLM 运行时变量)

第一轮 grep 已显示 14 处。

- [ ] **Step 3: 列 `tests/cases/*.ts` 里需要适配的测试模式**

mongo case 库现有 3 个 TypeScript 测试(golden-validity / field-integrity / index-integrity)。看它们怎么验证 mongo case,gaussdb case 是否需要同样的测试 + 文件路径要不要参数化 engine。

输出位置:`notes/case-tests-pattern.md`

### Task 0.4: 创建目录骨架

**Files:**
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/` 空目录
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/sql/` 空目录
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/diag/` 空目录(含 `__init__.py`)
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/diag/checkers/` 空目录(含 `__init__.py`)
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/diag/models/` 空目录(含 `__init__.py`)
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/diag/rules/` 空目录(含 `__init__.py`)
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/diag/util/` 空目录(含 `__init__.py`)
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/diag/tests/` 空目录(含 `__init__.py`)
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/diag/tests/fixtures/` 空目录
- Create: `plugins/perf-kp-sql/data/cases/gaussdb/` 空目录
- Create: `plugins/perf-kp-sql/data/cases/gaussdb/indices/by-check-item/` 空目录

- [ ] **Step 1: 一次性 mkdir**

```bash
cd /Users/david/code/perf-kp-sql-gaussdb-wt/plugins/perf-kp-sql/data
mkdir -p engines/gaussdb/collect/sql \
         engines/gaussdb/diag/{checkers,models,rules,util,tests/fixtures} \
         cases/gaussdb/indices/by-check-item
```

- [ ] **Step 2: 建 `__init__.py` 空文件**

```bash
cd engines/gaussdb/diag
touch __init__.py checkers/__init__.py models/__init__.py rules/__init__.py util/__init__.py tests/__init__.py
```

- [ ] **Step 3: 提交骨架**

```bash
git add -A
git commit -m "build(perf-kp-sql): scaffold data/engines/gaussdb 和 data/cases/gaussdb 目录骨架"
```

---

## Phase M1.diag · 诊断侧(拷 archer 新体系 + 写 run.py + 测试)

> **依赖关系**:M1.diag.1-5(代码移植)按顺序串行(import 链)· M1.diag.6(run.py)依赖 1-5 全部完成 · M1.diag.7-8(测试)依赖 6。
> 
> **并发可行性**:M1.diag 跟 M1.collect 可**并行**(两个 agent / 两个 session)— 采集脚本和诊断模块解耦,只在端到端测试时汇合。
> 
> **粗估时长**:~14-18 小时(2 工作日 · 比 v0.1 多 2-4h,因为要逐个 Diagnoser 读源码确认 rule_name)。

> **关键 v0.2 改动**(对比 v0.1):
> - 不拷 `funcs/checkers/` 6 个文件,只拷 4 个**活跃 Diagnoser**(instance/index/sql/sqlplan)
> - 不拷 `udf_funcs.py` / `parse_dict.py`(旧体系废弃)
> - **额外拷** `bak/waitevent_checker.py` / `bak/memory_checker.py` / `bak/slowsql.py` / `bak/health_report.py`(这些不是"过期备份",是当前主流程实际用的代码,见 `archer-interface-notes.md` Q5)
> - run.py 不自己拼 udf 循环,改成包装 `health_report.run(WebArgs)`
> - 加 `transform.py` 把 archer 返回的 `final_report_data` 转 hits.json schema

### Task M1.diag.1: 拷贝 archer 15 个 model + base.py + ModelRunner

**Files:**
- Copy: `/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/models/*.py`(15 个 model + base.py + __init__.py)
- Target: `plugins/perf-kp-sql/data/engines/gaussdb/diag/models/`

- [ ] **Step 1: 列源目录全部文件确认**

```bash
ls /Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/models/*.py | wc -l
```
Expected:17(15 model + base.py + __init__.py)

- [ ] **Step 2: 拷过去**

```bash
cd /Users/david/code/perf-kp-sql-gaussdb-wt
SRC=/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/models
DST=plugins/perf-kp-sql/data/engines/gaussdb/diag/models
cp $SRC/*.py $DST/
```

- [ ] **Step 3: 确认目标**

```bash
ls $DST/*.py | wc -l
```
Expected:17 个

- [ ] **Step 4: Read base.py 全文确认 ModelRunner 接口签名**

读 `$DST/base.py`(预估 200-400 行),把以下接口写入 `notes/model-runner-api.md`:
- `BaseModel` 类签名(`collect()` / `load()` / `FILE_NAME`)
- `ModelRunner.__init__(args, task_uuid)` 入参
- `ModelRunner.run_combination(models, offline_zip_path=None)` 返回值类型
- `ModelRunner._prepare_offline_data(zip_path)` 是否真的支持 zip 直接传入

这些是后续 M1.diag.6 写 run.py 时的关键契约。

- [ ] **Step 5: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/models/
git commit -m "feat(perf-kp-sql/gaussdb): 拷 archer 15 个 model + base.py + ModelRunner"
```

### Task M1.diag.2: 拷贝 4 个活跃 Diagnoser

**Files:**
- Copy: `{instance,index,sql,sqlplan}_checker.py` 4 个
- Target: `plugins/perf-kp-sql/data/engines/gaussdb/diag/diagnosers/`

注:archer 把这 4 个叫 `*_checker.py` 但实际类名是 `*Diagnoser`。文件名沿用 archer 命名(改 import 时统一)。

- [ ] **Step 1: 拷贝**

```bash
cd /Users/david/code/perf-kp-sql-gaussdb-wt
SRC=/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs
DST=plugins/perf-kp-sql/data/engines/gaussdb/diag/diagnosers
cp $SRC/instance_checker.py $DST/
cp $SRC/index_checker.py $DST/
cp $SRC/sql_checker.py $DST/
cp $SRC/sqlplan_checker.py $DST/
```

**注意:不拷 `cluster_checker.py` 和 `wdr_comparison.py`**(它们不是诊断规则,见 spec §1.2)。

- [ ] **Step 2: 确认**

```bash
ls $DST/*.py | wc -l
```
Expected:4 个 .py

- [ ] **Step 3: 逐个 Diagnoser 读全文 + 摘要内部规则名 → `notes/diagnoser-rules.md`**

逐个读这 4 个 Diagnoser 文件,**找内部规则常量 / 函数名 / 返回 dict 的 rule_name 字段**,写到 `notes/diagnoser-rules.md`:

```markdown
## InstanceDiagnoser(instance_checker.py)
- rule_name: buffer_hit_ratio_low · 阈值:hit_ratio < 0.95
- rule_name: syscache_hit_ratio_low · 阈值:gs_gsc_dbstat_info 计算

## IndexCheckerDiagnoser(index_checker.py)
- rule_name: gpi_present
- rule_name: ndv_order_wrong
- ... (8 条)

## StaticDiagnoser(sql_checker.py)
- 通过 util/sql.py SQLDiagnosticEngine 跑 N 条规则
- rule_name 见 util/sql.py 内部 RULE_DEFINITIONS

## PlanDiagnoser(sqlplan_checker.py)
- rule_name: hard_parse_high
- rule_name: dead_tuple_io_amp
- rule_name: data_skew
- rule_name: plan_quality
```

这份笔记是 M1.case 写 case 库的依据。**第一版 case 库 22+ 条规则数量根据此笔记最终确定**。

- [ ] **Step 4: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/diagnosers/ notes/diagnoser-rules.md
git commit -m "feat(perf-kp-sql/gaussdb): 拷 4 个活跃 Diagnoser + 内部规则名笔记"
```

### Task M1.diag.3: 拷贝 bak/ 的 2 个 Diagnoser(waitevent + memory)

**Files:**
- Copy: `bak/waitevent_checker.py` + `bak/memory_checker.py` + `bak/memory_model.py` + `bak/wait_events_model.py`
- Target: `diag/diagnosers/`(checker)+ `diag/models/`(对应 model)

**注**:archer 把这些放 `bak/` 命名误导,但实际**还在用**(`bak/slowsql.py` 的 `DIAGNOSER_CLASSES` 引用 WaitDiagnoser)。

- [ ] **Step 1: 拷贝 Diagnoser**

```bash
SRC=/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/bak
DST=plugins/perf-kp-sql/data/engines/gaussdb/diag/diagnosers
cp $SRC/waitevent_checker.py $DST/
cp $SRC/memory_checker.py $DST/
```

- [ ] **Step 2: 拷贝对应 model**(这两 Diagnoser 依赖的 model 可能在 bak/ 里)

```bash
cp $SRC/memory_model.py plugins/perf-kp-sql/data/engines/gaussdb/diag/models/ 2>/dev/null || echo "no memory_model"
cp $SRC/wait_events_model.py plugins/perf-kp-sql/data/engines/gaussdb/diag/models/ 2>/dev/null || echo "no wait_events_model"
```

如果某个 model 不在 bak/ 下,先 grep 找位置:

```bash
grep -rn "class.*MemoryModel\|class.*WaitEventModel" /Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/
```

- [ ] **Step 3: 逐个 Diagnoser 读全文 → 补 `notes/diagnoser-rules.md`**

```markdown
## WaitDiagnoser(waitevent_checker.py · 从 bak/ 提)
- rule_name: regular_lock_wait
- rule_name: lightweight_lock_wait  
- rule_name: wal_sync_slow
- rule_name: wal_flush_slow

## MemoryDiagnoser(memory_checker.py · 从 bak/ 提)
- rule_name: shared_memory_high · 阈值 > 80%
- rule_name: session_thread_high · 阈值 > 80%
- rule_name: peak_memory_usage
- rule_name: memory_leak
```

- [ ] **Step 4: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/diagnosers/{waitevent,memory}_checker.py
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/models/*memory* plugins/perf-kp-sql/data/engines/gaussdb/diag/models/*wait* 2>/dev/null
git commit -m "feat(perf-kp-sql/gaussdb): 拷 WaitDiagnoser + MemoryDiagnoser(从 archer bak/ 提)"
```

### Task M1.diag.4: 拷贝 pipeline 编排 + util 规则库

**Files:**
- Copy: `bak/slowsql.py` + `bak/health_report.py` → `diag/pipeline/`
- Copy: `funcs/util/{sql,sqlplan,deadlock,print}.py` → `diag/util/`

- [ ] **Step 1: 拷贝 pipeline**

```bash
mkdir -p plugins/perf-kp-sql/data/engines/gaussdb/diag/pipeline
touch plugins/perf-kp-sql/data/engines/gaussdb/diag/pipeline/__init__.py
SRC=/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/bak
DST=plugins/perf-kp-sql/data/engines/gaussdb/diag/pipeline
cp $SRC/slowsql.py $DST/
cp $SRC/health_report.py $DST/
```

- [ ] **Step 2: 拷贝 util**

```bash
SRC=/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/funcs/util
DST=plugins/perf-kp-sql/data/engines/gaussdb/diag/util
cp $SRC/sql.py $DST/
cp $SRC/sqlplan.py $DST/
cp $SRC/deadlock.py $DST/
cp $SRC/print.py $DST/
```

- [ ] **Step 3: 读 `slowsql.py` 全文确认 `SlowSQLDiagnoser.DIAGNOSER_CLASSES` 列表**

预期 archer 写的是:
```python
DIAGNOSER_CLASSES = [
    InstanceDiagnoser,
    WaitDiagnoser,
    PlanDiagnoser,
    StaticDiagnoser,
    # IndexCheckerDiagnoser,  ← archer 注释了
]
```

**本期要把 `IndexCheckerDiagnoser` 取消注释加进去**(spec §6.2 已声明)— 在改 import 那一步顺便做。

- [ ] **Step 4: 读 `health_report.py` 全文确认 `run(args)` 接口 + `WebArgs` 结构**

写入 `notes/health-report-api.md`:
- `WebArgs.__init__(action, mode, file)` 字段名
- `health_report.run(args)` 返回值结构(`final_report_data` 字段名)
- `mode='offline'` vs `mode='online'` 在 run() 内部如何分流

- [ ] **Step 5: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/{pipeline,util}/
git commit -m "feat(perf-kp-sql/gaussdb): 拷 pipeline(slowsql+health_report) + util(sql/sqlplan/deadlock/print)"
```

### Task M1.diag.5: 写 pgxc_* 分布式视图 model + 修全部 import

archer 没有 `pgxc_thread_wait_status` / `pgxc_get_senders_catchup_time` 等分布式视图的 model — 这两个是 GaussDB 分布式 only 用到的,要按 BaseModel pattern 新建。

**Files:**
- Create: `diag/models/pgxc_thread_wait_status_model.py`
- Create: `diag/models/pgxc_senders_catchup_time_model.py`
- Modify: 所有 diag/ 下 .py 的 import 路径

- [ ] **Step 1: 新建 2 个 pgxc model(模仿 archer 现有 model 模式)**

读 `diag/models/pg_class_model.py` 看 BaseModel 实现模式,照样写两个 pgxc 版:

```python
# diag/models/pgxc_thread_wait_status_model.py
from .base import BaseModel, ModelRunner

@ModelRunner.register("pgxc_thread_wait_status")
class PgxcThreadWaitStatusModel(BaseModel):
    FILE_NAME = "pgxc_thread_wait_status.txt"
    SQL = """
        SELECT node_name, wait_status, wait_event, query_id, count(*) AS cnt
        FROM pgxc_thread_wait_status
        WHERE wait_status <> 'none' AND query_id > 0
        GROUP BY 1, 2, 3, 4
        ORDER BY 5 DESC
        LIMIT 1000;
    """
    
    def collect(self, args, work_dir):
        # 参考 pg_class_model.collect() 写法
        ...
    
    def load(self):
        # 参考 pg_class_model.load() 写法
        ...
```

第二个 `pgxc_senders_catchup_time_model.py` 同样模式 · SQL 来自 archer dist.sh L48:`select * from pgxc_get_senders_catchup_time()`。

- [ ] **Step 2: 找全部需要改 import 的位置**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/diag
grep -rn "from gs_dsw\|import gs_dsw\|from views\." . --include="*.py"
```

预估 20-50 处需改。常见模式:

| 原 import | 新 import |
|---|---|
| `from gs_dsw.funcs.models.pg_class_model import ...` | `from ..models.pg_class_model import ...` |
| `from gs_dsw.funcs.util.sql import ...` | `from ..util.sql import ...` |
| `from gs_dsw.funcs.bak.waitevent_checker import WaitDiagnoser` | `from .waitevent_checker import WaitDiagnoser`(因为 bak/ 提到正式目录) |
| `from gs_dsw.funcs.instance_checker import InstanceDiagnoser` | `from .instance_checker import InstanceDiagnoser` |

- [ ] **Step 3: 批量改**

按文件 Edit。**注意 `bak/health_report.py` 里 import 也要改**:`from .slowsql import ...` 之类。

- [ ] **Step 4: 改 SlowSQLDiagnoser 激活 IndexCheckerDiagnoser**

`pipeline/slowsql.py`:

```python
# 取消注释 IndexCheckerDiagnoser
DIAGNOSER_CLASSES = [
    InstanceDiagnoser,
    WaitDiagnoser,
    PlanDiagnoser,
    StaticDiagnoser,
    IndexCheckerDiagnoser,   # archer 注释,本期激活
]
```

- [ ] **Step 5: 验证 import 跑通**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb
python3 -c "
from diag.models import base
from diag.diagnosers import instance_checker, index_checker, sql_checker, sqlplan_checker, waitevent_checker, memory_checker
from diag.pipeline import slowsql, health_report
from diag.util import sql, sqlplan
print('OK')
"
```
Expected:`OK`

- [ ] **Step 6: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/
git commit -m "feat(perf-kp-sql/gaussdb): 加 pgxc_* 分布式 model + 全部 import 改成相对路径 + 激活 IndexDiagnoser"
```

### Task M1.diag.6: 写 run.py + transform.py(包装 health_report.run)

**Files:**
- Create: `diag/run.py`
- Create: `diag/transform.py`
- Test: `diag/tests/test_run_py.py`(单元测试 + 集成测试拆开)

- [ ] **Step 1: 先写 transform.py 单元测试(failing)**

```python
# diag/tests/test_transform.py
"""测试 archer final_report_data → hits.json schema 转换"""
import pytest
from ..transform import transform_to_hits


def test_transform_memory_diag():
    """archer MemoryDiagnoser 返回展开成 hits"""
    archer_result = {
        "memory_diagnose_result": [
            {
                "rule_name": "shared_memory_high",
                "status": "critical",
                "result": "动态内存占比 85%",
                "reason": "...",
                "suggestion": "...",
                "detail": {"ratio": 0.85}
            }
        ],
        "sql_diagnose_result": []
    }
    
    hits = transform_to_hits(archer_result)
    
    assert len(hits) == 1
    assert hits[0]["rule_name"] == "shared_memory_high"
    assert hits[0]["diagnoser"] == "MemoryDiagnoser"
    assert hits[0]["status"] == "critical"
    assert hits[0]["category"] == "param"   # MemoryDiagnoser → param
    assert hits[0]["severity"] == "P0"      # shared_memory_high → P0


def test_transform_sql_diag_with_sql_id():
    """SlowSQL 诊断结果按 sql_id 聚合"""
    archer_result = {
        "memory_diagnose_result": [],
        "sql_diagnose_result": [
            {
                "sql_id": "31697554",
                "diagnoser": "InstanceDiagnoser",  # 假设 archer 这么标
                "rule_name": "buffer_hit_ratio_low",
                "status": "warning",
                "result": "buffer hit 87%",
                "reason": "...",
                "suggestion": "..."
            }
        ]
    }
    
    hits = transform_to_hits(archer_result)
    
    assert len(hits) == 1
    assert hits[0]["category"] == "param"
    assert hits[0]["detail"]["sql_id"] == "31697554"


def test_transform_empty():
    assert transform_to_hits({}) == []
    assert transform_to_hits({"memory_diagnose_result": [], "sql_diagnose_result": []}) == []
```

- [ ] **Step 2: 跑测试验证失败**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/diag
python3 -m pytest tests/test_transform.py -v
```
Expected:`ImportError: cannot import 'transform_to_hits'`(transform.py 不存在)

- [ ] **Step 3: 写 transform.py**

```python
"""archer final_report_data → hits.json schema 转换"""
from typing import List, Dict, Any


# (Diagnoser, rule_name) → (category, severity) 映射
# 注:具体 rule_name 来自 M1.diag.2-3 的 notes/diagnoser-rules.md
_RULE_META: Dict[tuple, tuple] = {
    # MemoryDiagnoser
    ("MemoryDiagnoser", "shared_memory_high"):   ("param", "P0"),
    ("MemoryDiagnoser", "session_thread_high"):  ("param", "P1"),
    ("MemoryDiagnoser", "peak_memory_usage"):    ("param", "P1"),
    ("MemoryDiagnoser", "memory_leak"):          ("param", "P0"),
    # InstanceDiagnoser
    ("InstanceDiagnoser", "buffer_hit_ratio_low"):    ("param", "P1"),
    ("InstanceDiagnoser", "syscache_hit_ratio_low"):  ("param", "P1"),
    # WaitDiagnoser
    ("WaitDiagnoser", "regular_lock_wait"):    ("slow_sql", "P1"),
    ("WaitDiagnoser", "lightweight_lock_wait"): ("slow_sql", "P1"),
    ("WaitDiagnoser", "wal_sync_slow"):        ("param", "P0"),
    ("WaitDiagnoser", "wal_flush_slow"):       ("param", "P0"),
    # PlanDiagnoser
    ("PlanDiagnoser", "hard_parse_high"):    ("param", "P1"),
    ("PlanDiagnoser", "dead_tuple_io_amp"):  ("table_def", "P1"),
    ("PlanDiagnoser", "data_skew"):          ("slow_sql", "P1"),
    ("PlanDiagnoser", "plan_quality"):       ("slow_sql", "P1"),
    # IndexCheckerDiagnoser(8 条 — 读 diagnoser-rules.md 补全)
    ("IndexCheckerDiagnoser", "gpi_present"):       ("table_def", "P2"),
    ("IndexCheckerDiagnoser", "ndv_order_wrong"):   ("table_def", "P1"),
    ("IndexCheckerDiagnoser", "collation_mismatch"): ("table_def", "P1"),
    ("IndexCheckerDiagnoser", "leftmost_violation"): ("table_def", "P1"),
    ("IndexCheckerDiagnoser", "index_skip"):        ("table_def", "P1"),
    ("IndexCheckerDiagnoser", "index_not_used"):    ("table_def", "P1"),
    ("IndexCheckerDiagnoser", "implicit_type_cast"): ("table_def", "P1"),
    ("IndexCheckerDiagnoser", "scan_selectivity_low"): ("table_def", "P2"),
    # StaticDiagnoser(N 条 SQL 反模式 — 读 util/sql.py RULE_DEFINITIONS)
    # ...
}


def _classify(diagnoser: str, rule_name: str) -> tuple:
    """(category, severity)"""
    return _RULE_META.get((diagnoser, rule_name), ("unknown", "P2"))


def transform_to_hits(archer_result: Dict[str, Any]) -> List[Dict[str, Any]]:
    """archer final_report_data → hits.json hits[] list"""
    hits: List[Dict[str, Any]] = []
    
    # 内存诊断
    for entry in archer_result.get("memory_diagnose_result", []):
        rule_name = entry.get("rule_name", "")
        diagnoser = entry.get("diagnoser", "MemoryDiagnoser")
        category, severity = _classify(diagnoser, rule_name)
        hits.append({
            "rule_name": rule_name,
            "diagnoser": diagnoser,
            "severity": severity,
            "category": category,
            "status": entry.get("status", "info"),
            "result": entry.get("result", ""),
            "reason": entry.get("reason", ""),
            "suggestion": entry.get("suggestion", ""),
            "detail": entry.get("detail", {}),
        })
    
    # SQL 诊断
    for entry in archer_result.get("sql_diagnose_result", []):
        rule_name = entry.get("rule_name", "")
        diagnoser = entry.get("diagnoser", "")
        category, severity = _classify(diagnoser, rule_name)
        detail = dict(entry.get("detail", {}))
        if "sql_id" in entry:
            detail["sql_id"] = entry["sql_id"]
        hits.append({
            "rule_name": rule_name,
            "diagnoser": diagnoser,
            "severity": severity,
            "category": category,
            "status": entry.get("status", "info"),
            "result": entry.get("result", ""),
            "reason": entry.get("reason", ""),
            "suggestion": entry.get("suggestion", ""),
            "detail": detail,
        })
    
    return hits
```

- [ ] **Step 4: 跑测试验证 PASS**

```bash
python3 -m pytest tests/test_transform.py -v
```
Expected:全 PASS。如果 archer 实际字段名不是 `rule_name / diagnoser` 那一套,**改 transform.py 适配真实字段名 + 改测试**。

- [ ] **Step 5: 写 run.py**

```python
#!/usr/bin/env python3
"""
GaussDB 离线诊断 CLI 入口 · 包装 archer health_report.run(WebArgs)

用法:
    python3 run.py --input <collected.zip> --output-json -
"""

import argparse
import json
import sys
import time
import tempfile
import zipfile
from pathlib import Path

from .pipeline import health_report
from .transform import transform_to_hits


SCHEMA_VERSION = "0.1.0"


class WebArgs:
    """模拟 archer Go 后端调用形态(沿用 diagnose_report_v1.py:26 的 WebArgs class)"""
    def __init__(self, zip_path: str):
        self.action = 'health_report'
        self.mode = 'offline'
        self.file = zip_path


def parse_args():
    p = argparse.ArgumentParser(description="GaussDB 离线诊断 · 包装 archer health_report.run")
    p.add_argument("--input", required=True, help="collected zip 路径")
    p.add_argument("--output-json", required=True, help="hits.json 输出(- 表示 stdout)")
    p.add_argument("--verbose", action="store_true")
    return p.parse_args()


def read_meta(zip_path: Path) -> dict:
    """从 zip 读 meta.json(dbcollect 写的)"""
    with zipfile.ZipFile(zip_path) as z:
        with z.open("meta.json") as f:
            return json.load(f)


def aggregate(hits: list, meta: dict, zip_path: Path, duration: float) -> dict:
    by_severity = {"P0": 0, "P1": 0, "P2": 0}
    by_category = {}
    for h in hits:
        sev = h.get("severity", "P2")
        by_severity[sev] = by_severity.get(sev, 0) + 1
        cat = h.get("category", "unknown")
        by_category[cat] = by_category.get(cat, 0) + 1
    
    return {
        "schema_version": SCHEMA_VERSION,
        "input_zip": zip_path.name,
        "deploy_mode": meta.get("deploy_mode", "unknown"),
        "summary": {
            "total_hits": len(hits),
            "by_severity": by_severity,
            "by_category": by_category,
        },
        "hits": hits,
        "meta": {
            "duration_seconds": round(duration, 2),
            "collected_at": meta.get("collected_at"),
            "window": meta.get("window"),
        },
    }


def main():
    args = parse_args()
    input_path = Path(args.input).resolve()
    
    if not input_path.exists():
        print(f"error: input not found: {input_path}", file=sys.stderr)
        sys.exit(2)
    
    started = time.time()
    
    # 1. 读 meta(校验 + 给 aggregate 用)
    try:
        meta = read_meta(input_path)
    except (zipfile.BadZipFile, KeyError) as e:
        print(f"error: meta.json 读取失败: {e}", file=sys.stderr)
        sys.exit(3)
    
    # 2. 构造 WebArgs + 调 archer health_report.run
    web_args = WebArgs(zip_path=str(input_path))
    try:
        archer_result = health_report.run(web_args)
    except Exception as e:
        print(f"error: archer health_report.run 失败: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc(file=sys.stderr)
        sys.exit(4)
    
    if archer_result is None:
        print("error: archer 返回空", file=sys.stderr)
        sys.exit(4)
    
    # 3. 转 hits
    hits = transform_to_hits(archer_result)
    
    # 4. 聚合 + 输出
    duration = time.time() - started
    output = aggregate(hits, meta, input_path, duration)
    
    output_str = json.dumps(output, ensure_ascii=False, indent=2)
    if args.output_json == "-":
        print(output_str)
    else:
        Path(args.output_json).write_text(output_str)
    
    sys.exit(0)


if __name__ == "__main__":
    main()
```

- [ ] **Step 6: 写 run.py 集成测试(独立于单元测试)**

`tests/test_run_py.py`:

```python
"""run.py 端到端集成测试"""
import json
import subprocess
import zipfile
from pathlib import Path
import pytest


@pytest.fixture
def minimal_zip(tmp_path):
    """构造一个最小 collected zip(只含 meta.json + 一份空 statement_history)"""
    workdir = tmp_path / "wd"
    workdir.mkdir()
    
    (workdir / "meta.json").write_text(json.dumps({
        "collected_at": "2026-05-18T10:00:00",
        "window": {"start": "...", "end": "..."},
        "deploy_mode": "centralized",
        "cn": {"hostname": "test", "node_name": "main"},
        "dn_total": 0,
        "dn_collected": [],
        "dn_failed": [],
        "wdr_unavailable": True,
        "version": {"gaussdb": "5.0.0", "dbcollect": "0.1.0"}
    }))
    
    cn_dump = workdir / "dump" / "cn"
    cn_dump.mkdir(parents=True)
    # archer model 期待的文件名(各 model FILE_NAME 来自 base.py)
    (cn_dump / "statement_history.txt").write_text("")
    (cn_dump / "pg_class.txt").write_text("")
    
    zip_path = tmp_path / "collected.zip"
    with zipfile.ZipFile(zip_path, 'w') as z:
        for f in workdir.rglob("*"):
            if f.is_file():
                z.write(f, f.relative_to(workdir))
    return zip_path


def test_run_py_minimal_zip(minimal_zip):
    """空数据 zip 跑通 · 返回合法 JSON · hits 数组(可能为空)"""
    run_py = Path(__file__).parent.parent / "run.py"
    result = subprocess.run(
        ["python3", "-m", "diag.run", "--input", str(minimal_zip), "--output-json", "-"],
        capture_output=True, text=True, timeout=30,
        cwd=Path(__file__).parent.parent.parent  # cwd 到 gaussdb/ 以便 -m diag.run
    )
    
    assert result.returncode == 0, f"stderr: {result.stderr}"
    output = json.loads(result.stdout)
    
    assert output["schema_version"] == "0.1.0"
    assert output["deploy_mode"] == "centralized"
    assert isinstance(output["hits"], list)
    assert "summary" in output


def test_run_py_invalid_zip(tmp_path):
    """坏 zip → exit 3"""
    bad_zip = tmp_path / "bad.zip"
    bad_zip.write_bytes(b"not a zip")
    
    result = subprocess.run(
        ["python3", "-m", "diag.run", "--input", str(bad_zip), "--output-json", "-"],
        capture_output=True, text=True, timeout=10,
        cwd=Path(__file__).parent.parent.parent
    )
    assert result.returncode == 3


def test_run_py_missing_input():
    """input 不存在 → exit 2"""
    result = subprocess.run(
        ["python3", "-m", "diag.run", "--input", "/tmp/nonexistent.zip", "--output-json", "-"],
        capture_output=True, text=True, timeout=10
    )
    assert result.returncode == 2
```

- [ ] **Step 7: 跑测试**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb
python3 -m pytest diag/tests/test_run_py.py -v
```
Expected:**3 个测试都 PASS**。如果 archer health_report.run 在空数据时抛异常,把空数据 fixture 加些必要 model 文件凑齐。

- [ ] **Step 8: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/run.py \
        plugins/perf-kp-sql/data/engines/gaussdb/diag/transform.py \
        plugins/perf-kp-sql/data/engines/gaussdb/diag/tests/test_transform.py \
        plugins/perf-kp-sql/data/engines/gaussdb/diag/tests/test_run_py.py
git commit -m "feat(perf-kp-sql/gaussdb): run.py 包装 health_report.run + transform.py 输出 hits.json + 测试"
```

### Task M1.diag.7: 移植 archer testcases + 写 sample.zip 端到端

**Files:**
- Copy: `archer testcases/test_*.py` 6 个 → `diag/tests/`
- Copy: `bad_sql.sql` / `bad_plan.sql` → `diag/tests/fixtures/`
- Create: `diag/tests/fixtures/build_sample_zip.py`

- [ ] **Step 1: 拷 archer 测试**

```bash
SRC=/Users/david/.codex/worktrees/4a46/archer-ui/views/gs_dsw/testcases
DST=plugins/perf-kp-sql/data/engines/gaussdb/diag/tests
cp $SRC/test_*.py $DST/ 2>/dev/null
mkdir -p $DST/fixtures
cp $SRC/bad_sql.sql $DST/fixtures/
cp $SRC/bad_plan.sql $DST/fixtures/
```

- [ ] **Step 2: 改测试 import 路径**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/diag/tests
grep -l "from gs_dsw\|import gs_dsw\|from views" *.py
```
Edit 每个文件,把 `from gs_dsw.funcs.X import Y` 改成 `from ..diagnosers.X import Y` 或 `from ..util.X import Y`。

- [ ] **Step 3: 跑现有测试**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb
python3 -m pytest diag/tests/ -v
```
失败的记录到 `notes/test-portability-failures.md` 作为后续待修。

- [ ] **Step 4: 写 build_sample_zip.py**

(沿用 v0.1 plan 里那段 build_sample_zip.py 代码,但 fixture 数据要造**至少 1 条触发 hit 的数据**——比如 `pg_stat_all_tables` 写一条 `last_analyze` 距今 78 天的表,触发 PlanDiagnoser.dead_tuple_io_amp 或类似规则)

- [ ] **Step 5: 跑 sample.zip 端到端**

```bash
python3 -m diag.tests.fixtures.build_sample_zip
python3 -m diag.run --input diag/tests/fixtures/sample-collected.zip --output-json - --verbose
```

Expected:
- exit 0
- stdout 合法 JSON
- `output.summary.total_hits >= 1`
- 至少一条 hit 的 `rule_name` 跟 diagnoser-rules.md 里某条对得上

- [ ] **Step 6: 把 sample 加入回归测试**

修改 `test_run_py.py` 加 `test_run_py_sample_zip_known_hits`:

```python
def test_run_py_sample_zip_known_hits():
    fixture = Path(__file__).parent / "fixtures" / "sample-collected.zip"
    result = subprocess.run(
        ["python3", "-m", "diag.run", "--input", str(fixture), "--output-json", "-"],
        capture_output=True, text=True, timeout=60,
        cwd=Path(__file__).parent.parent.parent
    )
    assert result.returncode == 0
    output = json.loads(result.stdout)
    assert output["summary"]["total_hits"] >= 1, f"sample.zip 应触发 hit,实际:{output}"
```

- [ ] **Step 7: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/tests/
git commit -m "test(perf-kp-sql/gaussdb): 移植 archer testcases + sample.zip 端到端"
```

### Task M1.diag.8: requirements.txt + 跑全部测试回归

**Files:**
- Create: `diag/requirements.txt`(估计无第三方依赖,看 archer 实际 import)
- Create: `diag/requirements-dev.txt`(pytest)

- [ ] **Step 1: 列 Python 依赖**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/diag
grep -rh "^import \|^from " . --include="*.py" | sort -u | grep -vE "^(from \.|^import \.)" | head -40
```

archer 实际可能用了 `sqlglot`(udf_funcs.py 用 sqlglot,但我们不复用 udf;sqlplan_checker 可能也用)、`dateutil`、`bs4`(wdr_comparison 用,我们不复用)。把**实际 import 但非 stdlib** 的列出来。

- [ ] **Step 2: 写 requirements.txt**

示例(具体看 grep 结果):

```
# 见 grep 实际结果填
sqlglot>=10.0
python-dateutil>=2.8
```

- [ ] **Step 3: requirements-dev.txt**

```
pytest>=7.0
```

- [ ] **Step 4: 全量回归**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/diag
pip install -r requirements.txt
pip install -r requirements-dev.txt
python3 -m pytest tests/ -v
```
Expected:全 PASS(若有 FAIL,记录在 `notes/test-portability-failures.md`)

- [ ] **Step 5: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/diag/requirements*.txt
git commit -m "build(perf-kp-sql/gaussdb): diag Python 依赖清单"
```




## Phase M1.collect · 采集侧(SQL 模板 + dbcollect.sh + dn-helper.sh)

> **依赖关系**:M1.collect.1(SQL 模板)和 M1.collect.7(dn-helper)可并行 · M1.collect.2-6(dbcollect.sh 主脚本)按步骤串行。
> 
> **并发可行性**:M1.collect 跟 M1.diag 完全独立,可两个 session 并行。
> 
> **粗估时长**:~10-14 小时(1.5 工作日)。
> 
> **测试方法**:M1.collect 因依赖实际 GaussDB 环境,**无法在本机跑通**。本地只能做 shellcheck + 语法验证 + 假数据 dry-run。真实环境冒烟在 M3 端到端阶段联调。

### Task M1.collect.1: 写 Python 入口包装 ModelRunner(代替 SQL 模板拆分)

**v0.2 改动**:不再外部拆 SQL 模板(spec §5.3 已决定)。改成写一个 Python 入口让 archer model 自己跑 `collect()` 写文件。

**Files:**
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/run_models.py`(`dbcollect.sh` 调用入口)
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/pgxc_extra_collect.sh`(分布式视图采集 · pgxc_thread_wait_status / pgxc_get_senders_catchup_time)

注:**`collect/sql/` 目录不建**(spec §5.3)。

- [ ] **Step 1: 写 `run_models.py`(dbcollect.sh 第 8 步调它)**

```python
#!/usr/bin/env python3
"""
collect/run_models.py — dbcollect.sh 的 CN 全局 DB 采集入口

调用 archer ModelRunner 让 15 个 model 各自跑 collect() 写 dump/cn/<model>.txt。
不外部维护 SQL 模板 — model 自带 SQL。
"""

import argparse
import sys
from pathlib import Path

# 加入 diag 模块路径
script_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(script_dir.parent / "diag"))

from models import base, ModelRunner
# 通过 ModelRunner 自动注册的 model 列表跑全套
ALL_MODELS = ModelRunner.ALL_MODELS  # 装饰器自动注册的列表


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--work-dir", required=True, help="输出 dump/cn/ 目录路径")
    p.add_argument("--host", required=True)
    p.add_argument("--port", required=True)
    p.add_argument("--user", required=True)
    p.add_argument("--database", default="postgres")
    p.add_argument("--start", required=True, help="时间窗口起点 'YYYY-MM-DD HH:MM:SS'")
    p.add_argument("--end", required=True)
    p.add_argument("--top-n", type=int, default=100)
    p.add_argument("--deploy-mode", choices=["distributed", "centralized"], required=True)
    args = p.parse_args()
    
    # 构造 ModelRunner args(模拟 archer Go 后端调用形态)
    class CollectArgs:
        host = args.host
        port = args.port
        user = args.user
        database = args.database
        start_time = args.start
        end_time = args.end
        top_n = args.top_n
        # 密码走 $PGPASSWORD 环境变量(不传命令行)
    
    work_dir = Path(args.work_dir)
    work_dir.mkdir(parents=True, exist_ok=True)
    
    # 集中式模式跳过 pgxc_* model
    models_to_run = [m for m in ALL_MODELS 
                     if args.deploy_mode == "distributed" or not m.__name__.startswith("Pgxc")]
    
    runner = ModelRunner(CollectArgs(), task_uuid="dbcollect-run")
    
    for model_cls in models_to_run:
        try:
            model_cls().collect(CollectArgs(), str(work_dir))
            print(f"  OK   {model_cls.__name__} → {work_dir / model_cls.FILE_NAME}")
        except Exception as e:
            print(f"  FAIL {model_cls.__name__}: {e}", file=sys.stderr)
    
    sys.exit(0)


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: 写最小可用单元测试 `tests/test_run_models.py`**(集成测试在 M1.collect.6 端到端阶段做):

```python
"""test_run_models · 验证 ModelRunner 入口能 import + parse args(无需真实 gsql)"""
import subprocess
from pathlib import Path


def test_help_works():
    script = Path(__file__).parent.parent / "run_models.py"
    r = subprocess.run(["python3", str(script), "--help"], capture_output=True, text=True, timeout=10)
    assert r.returncode == 0
    assert "--work-dir" in r.stdout


def test_required_args_check():
    """缺必填参数 → exit 2"""
    script = Path(__file__).parent.parent / "run_models.py"
    r = subprocess.run(["python3", str(script)], capture_output=True, text=True, timeout=10)
    assert r.returncode == 2   # argparse 缺必填默认 exit 2
```

- [ ] **Step 3: 跑测试验证**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/collect
python3 -m pytest tests/test_run_models.py -v
```
Expected:PASS

- [ ] **Step 4: 写 `pgxc_extra_collect.sh`(分布式特有视图,model 没覆盖的)**

archer model 体系覆盖 15 个视图,但分布式 `pgxc_thread_wait_status` / `pgxc_get_senders_catchup_time` 已经在 M1.diag.5 加进 model(`pgxc_thread_wait_status_model.py` / `pgxc_senders_catchup_time_model.py`)。M1.collect 沿用 M1.diag.5 创建的 model,**不需要单独的 .sh**。

⚠️ **修正:取消 `pgxc_extra_collect.sh`,前面笔记说错了**。pgxc model 已经在 M1.diag.5 创建,M1.collect.1 的 `run_models.py` 通过 `ALL_MODELS` 自动包含它们。

- [ ] **Step 5: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/collect/run_models.py \
        plugins/perf-kp-sql/data/engines/gaussdb/collect/tests/test_run_models.py
git commit -m "feat(perf-kp-sql/gaussdb): collect/run_models.py 入口 · 调 ModelRunner 跑全套 model(不外部拆 SQL)"
```

---

⚠️ **避坑**(本期 dbcollect.sh 绝不能犯的 cent.sh bug):

archer `cent.sh` 第 6-7 行有 bug:`schemaname=$5; hostip=$5` — **同一位置参数被两次赋值**,导致 `schemaname` 实际拿到的是 `$5` 但 `hostip` 也是 `$5`,后续位置参数 `start_time=$6 / end_time=$7 / top_n=$8` 全部错位。

本期 dbcollect.sh **必须用 long-opt 参数解析**(`--start` / `--end` / `--top-n` 等),**绝不允许位置参数**。M1.collect.2 step 1 的 dbcollect.sh 主框架已经按 long-opt 写,Reviewer 必须确认没有位置参数依赖。

---

### Task M1.collect.2: dbcollect.sh 主框架(参数解析 + 部署形态检测)

**Files:**
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh`

- [ ] **Step 1: 先写 shellcheck 友好的最小可执行版本**

```bash
#!/usr/bin/env bash
#
# dbcollect.sh — GaussDB 离线诊断采集脚本
# 调用方式见 README.md
#
# 退出码:
#   0  成功
#   2  参数错误 / 输入不合法
#   3  环境检测失败(gsql 不在 PATH / 不在 CN / 等)
#   4  采集中关键步骤失败(WDR 失败 / DN 全部不通 等)

set -euo pipefail

# ============================================================
# 1. 默认值 + 参数解析
# ============================================================
START=""
END=""
OUTPUT=""
TOP_N=100
NO_WDR=false
SSH_USER="omm"
SSH_KEY=""
CN_PORT=""
DB="postgres"
DEBUG=false

usage() {
    cat <<EOF
用法: bash dbcollect.sh --start "YYYY-MM-DD HH:MM:SS" --end "..." --output collected-<ts>.zip [选项]

必填:
  --start "TIME"        采集时间窗口起点
  --end   "TIME"        采集时间窗口终点
  --output PATH         输出 zip 路径

可选:
  --top-n N             慢 SQL TopN · 默认 100
  --no-wdr              跳过 WDR 报告生成(体量过大或权限不足时)
  --ssh-user USER       SSH 跨节点用户 · 默认 omm
  --ssh-key PATH        SSH key 路径 · 默认走互信
  --port PORT           CN gsql 端口 · 默认从 postgresql.conf 推断
  --db DB               数据库名 · 默认 postgres
  --debug               输出 debug 日志到 stderr
  -h, --help            显示帮助
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --start)        START="$2"; shift 2 ;;
        --end)          END="$2"; shift 2 ;;
        --output)       OUTPUT="$2"; shift 2 ;;
        --top-n)        TOP_N="$2"; shift 2 ;;
        --no-wdr)       NO_WDR=true; shift ;;
        --ssh-user)     SSH_USER="$2"; shift 2 ;;
        --ssh-key)      SSH_KEY="$2"; shift 2 ;;
        --port)         CN_PORT="$2"; shift 2 ;;
        --db)           DB="$2"; shift 2 ;;
        --debug)        DEBUG=true; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              echo "未知参数: $1" >&2; usage; exit 2 ;;
    esac
done

[[ -z "$START" || -z "$END" || -z "$OUTPUT" ]] && { echo "缺必填参数" >&2; usage; exit 2; }

log() { [[ "$DEBUG" == "true" ]] && echo "[dbcollect] $*" >&2; }

# ============================================================
# 2. 环境检测
# ============================================================
check_env() {
    command -v gsql >/dev/null || { echo "gsql 不在 PATH" >&2; exit 3; }
    [[ -n "${PGDATA:-}" ]] || { echo "PGDATA 未设" >&2; exit 3; }
    [[ -f "$PGDATA/postgresql.conf" ]] || { echo "$PGDATA/postgresql.conf 不存在" >&2; exit 3; }
}

# 推断 CN 端口
detect_cn_port() {
    if [[ -z "$CN_PORT" ]]; then
        CN_PORT=$(grep -E "^port\s*=" "$PGDATA/postgresql.conf" | head -1 | awk -F'=' '{print $2}' | awk '{print $1}')
        [[ -z "$CN_PORT" ]] && CN_PORT=25000  # GaussDB 默认
    fi
    log "CN_PORT=$CN_PORT"
}

# 检测部署形态:分布式 / 集中式
detect_deploy_mode() {
    if gsql -d "$DB" -p "$CN_PORT" -tA -c \
        "SELECT count(*) FROM pgxc_node WHERE node_type='C'" 2>/dev/null | grep -qE "^[1-9]"; then
        echo "distributed"
    else
        echo "centralized"
    fi
}

check_env
detect_cn_port
DEPLOY_MODE=$(detect_deploy_mode)
log "DEPLOY_MODE=$DEPLOY_MODE"

echo "OK: 环境检测通过 · 部署形态=$DEPLOY_MODE · CN_PORT=$CN_PORT"
exit 0  # 临时 · 后续 task 加完采集步骤再去掉
```

- [ ] **Step 2: shellcheck**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/collect
shellcheck dbcollect.sh
```
Expected:无 warning / error

- [ ] **Step 3: 给 dbcollect.sh 加执行权限**

```bash
chmod +x dbcollect.sh
```

- [ ] **Step 4: 跑 --help 验证参数解析**

```bash
bash dbcollect.sh --help
```
Expected:输出 help 文本

- [ ] **Step 5: 跑参数缺失验证退出码**

```bash
bash dbcollect.sh --start "2026-05-18 10:00" 
echo "exit=$?"
```
Expected:`缺必填参数` + `exit=2`

- [ ] **Step 6: commit**

```bash
git add plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh
git commit -m "feat(perf-kp-sql/gaussdb): dbcollect.sh 主框架(参数解析 + 环境检测 + 部署形态)"
```

### Task M1.collect.3: dbcollect.sh OS 画像采集(9 项)

**Files:**
- Modify: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh`

- [ ] **Step 1: 在 dbcollect.sh `exit 0` 前加 OS 画像采集函数**

去掉 step 1 末尾的 `exit 0`,加:

```bash
# ============================================================
# 3. 准备工作目录
# ============================================================
TS=$(date '+%Y%m%dT%H%M%S')
TMP=$(mktemp -d -t "dbcollect-$TS-XXXXXX")
log "TMP=$TMP"
trap "rm -rf '$TMP'" EXIT

mkdir -p "$TMP"/{env,conf,logs,deploy,wdr,dump/cn}
[[ "$DEPLOY_MODE" == "distributed" ]] && mkdir -p "$TMP/dump/dn"

# ============================================================
# 4. CN 本机 OS 画像(9 项)
# ============================================================
collect_cn_env() {
    log "采 CN OS 画像..."
    uname -a > "$TMP/env/uname.txt"
    lscpu > "$TMP/env/lscpu.txt" 2>/dev/null || echo "lscpu unavailable" > "$TMP/env/lscpu.txt"
    head -50 /proc/cpuinfo > "$TMP/env/cpuinfo.txt" 2>/dev/null
    free -h > "$TMP/env/free.txt"
    cat /proc/meminfo > "$TMP/env/meminfo.txt"
    sysctl -a 2>/dev/null | grep -E '^(vm|kernel|net)\.' > "$TMP/env/sysctl.txt" || true
    df -h > "$TMP/env/df.txt"
    lsblk > "$TMP/env/lsblk.txt" 2>/dev/null || true
    ulimit -a > "$TMP/env/ulimit.txt"
    ip -br a > "$TMP/env/ip.txt" 2>/dev/null || ifconfig > "$TMP/env/ip.txt" 2>/dev/null || true
    ss -s > "$TMP/env/ss.txt" 2>/dev/null || true
    ps auxf | grep -E 'gauss|postgres' | head -50 > "$TMP/env/ps.txt" || true
    
    # 尝试 iostat(可能没 sysstat)
    if command -v iostat >/dev/null; then
        iostat -xz 1 3 > "$TMP/env/iostat.txt"
    else
        echo "sysstat (iostat) not installed" > "$TMP/env/iostat.txt"
    fi
    
    cp "$PGDATA/postgresql.conf" "$TMP/conf/" || log "postgresql.conf 拷贝失败"
}

collect_cn_env
echo "OK: CN OS 画像采集完成"
exit 0  # 临时
```

- [ ] **Step 2: shellcheck**

```bash
shellcheck dbcollect.sh
```

- [ ] **Step 3: dry-run(本机不能真跑,但能看是否语法对)**

```bash
bash -n dbcollect.sh
```
Expected:无输出(语法 OK)

- [ ] **Step 4: commit**

```bash
git add dbcollect.sh
git commit -m "feat(perf-kp-sql/gaussdb): dbcollect.sh CN OS 画像采集 9 项"
```

### Task M1.collect.4: dbcollect.sh pg_log 裁剪 + 部署识别

**Files:**
- Modify: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh`

- [ ] **Step 1: 在 OS 画像后加 pg_log 裁剪 + 部署识别**

```bash
# ============================================================
# 5. pg_log 时间窗口裁剪
# ============================================================
collect_cn_log() {
    log "采 CN pg_log(窗口 $START → $END)..."
    if [[ -d "$PGDATA/pg_log" ]]; then
        find "$PGDATA/pg_log" -type f \
            -newermt "$START" \! -newermt "$END" \
            -exec cp {} "$TMP/logs/" \; 2>/dev/null || true
    fi
    if [[ -z "$(ls -A "$TMP/logs/" 2>/dev/null)" ]]; then
        echo "(no pg_log in window)" > "$TMP/logs/EMPTY"
    fi
}

# ============================================================
# 6. 部署形态识别 · 集群拓扑
# ============================================================
collect_deploy() {
    log "采部署形态信息..."
    if [[ "$DEPLOY_MODE" == "distributed" ]]; then
        gsql -d "$DB" -p "$CN_PORT" -tA -c "SELECT * FROM pgxc_node" > "$TMP/deploy/pgxc_node.txt" 2>&1 || true
        gsql -d "$DB" -p "$CN_PORT" -tA -c "SELECT * FROM pgxc_group" > "$TMP/deploy/pgxc_group.txt" 2>&1 || true
        gs_om -t status --detail > "$TMP/deploy/cluster_status.txt" 2>&1 || \
            echo "(gs_om unavailable)" > "$TMP/deploy/cluster_status.txt"
    else
        gs_ctl status -D "$PGDATA" > "$TMP/deploy/status.txt" 2>&1 || true
    fi
    {
        gs_om --version 2>/dev/null || true
        gs_ctl --version 2>/dev/null || true
        gsql -d "$DB" -p "$CN_PORT" -tA -c "SELECT version()" 2>&1
    } > "$TMP/deploy/version.txt"
}

collect_cn_log
collect_deploy
echo "OK: pg_log + 部署识别完成"
exit 0  # 临时
```

- [ ] **Step 2: shellcheck + bash -n**

```bash
shellcheck dbcollect.sh && bash -n dbcollect.sh && echo OK
```

- [ ] **Step 3: commit**

```bash
git add dbcollect.sh
git commit -m "feat(perf-kp-sql/gaussdb): dbcollect.sh pg_log 裁剪 + 部署形态识别"
```

### Task M1.collect.5: dbcollect.sh WDR 生成 + 降级

**Files:**
- Modify: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh`

- [ ] **Step 1: 加 WDR 生成函数**

```bash
# ============================================================
# 7. WDR 报告生成 · 失败降级
# ============================================================
WDR_UNAVAILABLE=false

collect_wdr() {
    if [[ "$NO_WDR" == "true" ]]; then
        log "--no-wdr 指定,跳过 WDR"
        WDR_UNAVAILABLE=true
        return
    fi
    
    log "尝试生成 WDR 报告..."
    # 找窗口内的两个 snap_id
    local snap_pair
    snap_pair=$(gsql -d "$DB" -p "$CN_PORT" -tA -c "
        SELECT min(snapshot_id), max(snapshot_id)
        FROM dbe_perf.snapshot
        WHERE start_ts BETWEEN '$START' AND '$END'
    " 2>/dev/null || echo "|")
    
    local snap1 snap2
    snap1=$(echo "$snap_pair" | awk -F'|' '{print $1}')
    snap2=$(echo "$snap_pair" | awk -F'|' '{print $2}')
    
    if [[ -z "$snap1" || -z "$snap2" || "$snap1" == "$snap2" ]]; then
        log "WDR 窗口内无两个 snapshot · 尝试触发"
        gsql -d "$DB" -p "$CN_PORT" -tA -c "SELECT dbe_perf.create_wdr_snapshot()" 2>/dev/null || {
            log "create_wdr_snapshot 失败 · 标 unavailable"
            WDR_UNAVAILABLE=true
            return
        }
        sleep 5
        gsql -d "$DB" -p "$CN_PORT" -tA -c "SELECT dbe_perf.create_wdr_snapshot()" 2>/dev/null || true
        sleep 2
        snap_pair=$(gsql -d "$DB" -p "$CN_PORT" -tA -c "
            SELECT max(snapshot_id) - 1, max(snapshot_id) FROM dbe_perf.snapshot
        " 2>/dev/null || echo "|")
        snap1=$(echo "$snap_pair" | awk -F'|' '{print $1}')
        snap2=$(echo "$snap_pair" | awk -F'|' '{print $2}')
    fi
    
    if [[ -n "$snap1" && -n "$snap2" && "$snap1" != "$snap2" ]]; then
        gsql -d "$DB" -p "$CN_PORT" -tA -c "
            SELECT dbe_perf.generate_wdr_report($snap1, $snap2, 1, 'detail', 'cluster')
        " > "$TMP/wdr/wdr_${snap1}_${snap2}.html" 2>/dev/null || {
            WDR_UNAVAILABLE=true
            rm -f "$TMP/wdr/wdr_${snap1}_${snap2}.html"
        }
    else
        WDR_UNAVAILABLE=true
    fi
    
    [[ "$WDR_UNAVAILABLE" == "true" ]] && log "WDR 不可用 · meta 将标记"
}

collect_wdr
echo "OK: WDR 步骤完成(unavailable=$WDR_UNAVAILABLE)"
exit 0  # 临时
```

- [ ] **Step 2: shellcheck + 语法检查**

```bash
shellcheck dbcollect.sh && bash -n dbcollect.sh && echo OK
```

- [ ] **Step 3: commit**

```bash
git add dbcollect.sh
git commit -m "feat(perf-kp-sql/gaussdb): dbcollect.sh WDR 生成 + 失败降级"
```

### Task M1.collect.6: dbcollect.sh CN 全局 DB 采集 + EXECUTE DIRECT 跨 DN

**Files:**
- Modify: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh`

- [ ] **Step 1: 加 CN DB 采集 + EXECUTE DIRECT**

```bash
# ============================================================
# 8. CN 全局 DB 数据采集 · 调 run_models.py 让 archer model 自跑
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

collect_cn_db() {
    log "采 CN 全局 DB 数据 · ModelRunner 入口"
    # 密码走 PGPASSWORD env(不传命令行 · 避免 history 泄漏)
    export PGPASSWORD="${PGPASSWORD:-}"
    python3 "$SCRIPT_DIR/run_models.py" \
        --work-dir "$TMP/dump/cn" \
        --host localhost --port "$CN_PORT" --user "${PGUSER:-omm}" \
        --database "$DB" \
        --start "$START" --end "$END" --top-n "$TOP_N" \
        --deploy-mode "$DEPLOY_MODE" \
        2>&1 | tee -a "$TMP/dump/cn/_runner.log" || log "  ModelRunner 部分失败 · 看 _runner.log"
}

# ============================================================
# 9. per-DN DB 数据(分布式 only) · EXECUTE DIRECT ON
# ============================================================
DN_FAILED_EXEC=()

collect_dn_db_via_exec_direct() {
    [[ "$DEPLOY_MODE" != "distributed" ]] && return
    log "采 per-DN DB 数据 · EXECUTE DIRECT ON · 用临时 SQL 文件传"
    
    local dns
    dns=$(gsql -d "$DB" -p "$CN_PORT" -tA -c \
        "SELECT node_name FROM pgxc_node WHERE node_type='D'" 2>/dev/null)
    
    # ⚠️ 重要(v0.2 修正):不能用 `gsql -c "EXECUTE DIRECT ON ($dn) \$\$ ... \$\$"`
    # 因为 bash 双引号内 `\$\$` 会展开成 `$$`(当前进程 PID),GaussDB 收到的
    # 是损坏的 SQL。改用临时 SQL 文件 + `gsql -f`,把 EXECUTE DIRECT 包裹放在
    # 文件里(单引号也行,但要小心 SQL 模板里如果有单引号需要双倍转义)。
    
    while IFS= read -r dn; do
        [[ -z "$dn" ]] && continue
        log "  DN: $dn"
        mkdir -p "$TMP/dump/dn/$dn/dump"
        
        for sql_name in statement_history pg_stat_all_tables pg_locks; do
            # 拿原 SQL 模板(去掉末尾分号 · 准备塞 EXECUTE DIRECT 内部)
            local sqlfile="$SQL_DIR/${sql_name}.sql"
            local inner_sql=""
            if [[ -f "$sqlfile" ]]; then
                inner_sql=$(tr -d '\r' < "$sqlfile" | sed 's/;[[:space:]]*$//')
            elif [[ "$sql_name" == "pg_locks" ]]; then
                inner_sql="SELECT * FROM pg_locks"
            else
                continue
            fi
            
            # 替换 statement_history 的变量(在 inner_sql 字符串里)
            if [[ "$sql_name" == "statement_history" ]]; then
                inner_sql=${inner_sql//:start_time/\'$START\'}
                inner_sql=${inner_sql//:end_time/\'$END\'}
                inner_sql=${inner_sql//:top_n/$TOP_N}
            fi
            
            # 写临时 SQL 文件 · 用 heredoc 防 bash 解释 $$ / $var
            # 注:heredoc 用 'EOF' 引号阻止变量展开,然后我们已经在 inner_sql 里
            # 手动替换好了所有需要的值
            local tmp_sql="$TMP/_exec_direct_${dn}_${sql_name}.sql"
            cat > "$tmp_sql" <<EOF_OUTER
EXECUTE DIRECT ON ($dn) \$EXECDIRECT\$
$inner_sql
\$EXECDIRECT\$;
EOF_OUTER
            
            # ⚠️ 用 \$EXECDIRECT\$ 而不是 \$\$ 作为 GaussDB dollar-quote 边界:
            # 1. \$\$ 在 heredoc 里也可能跟其他 shell 实现冲突
            # 2. 自定义边界 EXECDIRECT 字面不会出现在 inner_sql 里,绝对安全
            # GaussDB EXECUTE DIRECT 支持任意 dollar-quote 边界(`$tag$`)
            
            gsql -A -d "$DB" -p "$CN_PORT" -f "$tmp_sql" \
                > "$TMP/dump/dn/$dn/dump/${sql_name}.txt" 2>&1 || {
                log "    $sql_name 失败"
                DN_FAILED_EXEC+=("$dn:$sql_name")
            }
            
            rm -f "$tmp_sql"
        done
    done <<< "$dns"
}

collect_cn_db
collect_dn_db_via_exec_direct
echo "OK: CN 全局 + per-DN DB 采集完成"
exit 0  # 临时
```

- [ ] **Step 2: shellcheck + bash -n**

```bash
shellcheck dbcollect.sh 2>&1 | tee /tmp/shellcheck.out
bash -n dbcollect.sh
```
review shellcheck output,SC2155 / SC2034 warning 看是否要修。

- [ ] **Step 3: commit**

```bash
git add dbcollect.sh
git commit -m "feat(perf-kp-sql/gaussdb): dbcollect.sh CN DB 采集 + EXECUTE DIRECT 跨 DN"
```

### Task M1.collect.7: 写 dn-helper.sh(DN 文件级采集)

**Files:**
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dn-helper.sh`

- [ ] **Step 1: 写 dn-helper.sh**

```bash
#!/usr/bin/env bash
#
# dn-helper.sh — 在每个 DN 节点上跑,纯文件级采集
# 由 dbcollect.sh 通过 scp + ssh 调度,不直接给用户跑

set -euo pipefail

START="${1:?start time}"
END="${2:?end time}"
OUT="${3:?output zip path}"

TMP=$(mktemp -d -t "dn-helper-XXXXXX")
trap "rm -rf '$TMP'" EXIT

mkdir -p "$TMP"/{env,conf,logs}

# OS 画像 9 项
uname -a > "$TMP/env/uname.txt"
lscpu > "$TMP/env/lscpu.txt" 2>/dev/null || true
head -50 /proc/cpuinfo > "$TMP/env/cpuinfo.txt"
free -h > "$TMP/env/free.txt"
cat /proc/meminfo > "$TMP/env/meminfo.txt"
sysctl -a 2>/dev/null | grep -E '^(vm|kernel|net)\.' > "$TMP/env/sysctl.txt" || true
df -h > "$TMP/env/df.txt"
lsblk > "$TMP/env/lsblk.txt" 2>/dev/null || true
ulimit -a > "$TMP/env/ulimit.txt"
ps auxf | grep -E 'gauss|postgres' | head -50 > "$TMP/env/ps.txt" || true

# postgresql.conf
if [[ -n "${PGDATA:-}" && -f "$PGDATA/postgresql.conf" ]]; then
    cp "$PGDATA/postgresql.conf" "$TMP/conf/"
fi

# pg_log 按窗口裁剪
if [[ -n "${PGDATA:-}" && -d "$PGDATA/pg_log" ]]; then
    find "$PGDATA/pg_log" -type f \
        -newermt "$START" \! -newermt "$END" \
        -exec cp {} "$TMP/logs/" \; 2>/dev/null || true
fi

# 打包
cd "$TMP" && zip -rq "$OUT" .
echo "OK: $OUT"
```

- [ ] **Step 2: shellcheck**

```bash
shellcheck dn-helper.sh
chmod +x dn-helper.sh
```

- [ ] **Step 3: commit**

```bash
git add dn-helper.sh
git commit -m "feat(perf-kp-sql/gaussdb): dn-helper.sh DN 文件级采集"
```

### Task M1.collect.8: dbcollect.sh SSH 跨节点拉 DN 日志 + 降级

**Files:**
- Modify: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh`

- [ ] **Step 1: 加 SSH 跨节点采集函数**

```bash
# ============================================================
# 10. SSH 跨节点拉 DN 本机文件 · 失败降级
# ============================================================
DN_FAILED_SSH=()

collect_dn_files_via_ssh() {
    [[ "$DEPLOY_MODE" != "distributed" ]] && return
    log "SSH 跨节点拉 DN 文件..."
    
    local hosts
    hosts=$(gsql -d "$DB" -p "$CN_PORT" -tA -c \
        "SELECT node_name, node_host FROM pgxc_node WHERE node_type='D'" 2>/dev/null)
    
    local helper="$(cd "$(dirname "$0")" && pwd)/dn-helper.sh"
    local dn_tmp="$TMP/dn-zips"
    mkdir -p "$dn_tmp"
    
    local ssh_opts=("-o" "BatchMode=yes" "-o" "ConnectTimeout=30" "-o" "StrictHostKeyChecking=no")
    [[ -n "$SSH_KEY" ]] && ssh_opts+=("-i" "$SSH_KEY")
    
    while IFS='|' read -r dn_name dn_host; do
        [[ -z "$dn_name" || -z "$dn_host" ]] && continue
        log "  → $dn_name ($dn_host)"
        
        local remote_helper="/tmp/dn-helper-${dn_name}.sh"
        local remote_zip="/tmp/dn-${dn_name}.zip"
        
        if ! scp "${ssh_opts[@]}" "$helper" "${SSH_USER}@${dn_host}:${remote_helper}" 2>/dev/null; then
            log "    scp helper 失败"
            DN_FAILED_SSH+=("${dn_name}:scp_helper")
            continue
        fi
        
        if ! ssh "${ssh_opts[@]}" "${SSH_USER}@${dn_host}" \
            "bash '$remote_helper' '$START' '$END' '$remote_zip'" 2>/dev/null; then
            log "    dn-helper 执行失败"
            DN_FAILED_SSH+=("${dn_name}:exec_helper")
            ssh "${ssh_opts[@]}" "${SSH_USER}@${dn_host}" "rm -f '$remote_helper'" 2>/dev/null || true
            continue
        fi
        
        if ! scp "${ssh_opts[@]}" "${SSH_USER}@${dn_host}:${remote_zip}" "$dn_tmp/${dn_name}.zip" 2>/dev/null; then
            log "    回收 zip 失败"
            DN_FAILED_SSH+=("${dn_name}:scp_back")
            continue
        fi
        
        ssh "${ssh_opts[@]}" "${SSH_USER}@${dn_host}" "rm -f '$remote_helper' '$remote_zip'" 2>/dev/null || true
        
        # 解压到 dump/dn/<dn>/
        mkdir -p "$TMP/dump/dn/$dn_name"
        unzip -q "$dn_tmp/${dn_name}.zip" -d "$TMP/dump/dn/$dn_name/"
    done <<< "$hosts"
    
    rm -rf "$dn_tmp"
}

collect_dn_files_via_ssh
echo "OK: SSH 跨节点采集完成(failed=${#DN_FAILED_SSH[@]})"
exit 0  # 临时
```

- [ ] **Step 2: shellcheck + bash -n**

```bash
shellcheck dbcollect.sh && bash -n dbcollect.sh && echo OK
```

- [ ] **Step 3: commit**

```bash
git add dbcollect.sh
git commit -m "feat(perf-kp-sql/gaussdb): dbcollect.sh SSH 跨节点拉 DN 文件 + 降级"
```

### Task M1.collect.9: dbcollect.sh meta.json + checksums + 打包

**Files:**
- Modify: `plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh`

- [ ] **Step 1: 加 meta.json 生成 + sha256 + zip 打包**

去掉之前的 `exit 0`,加最终阶段:

```bash
# ============================================================
# 11. meta.json
# ============================================================
write_meta() {
    log "写 meta.json..."
    local dn_collected_json="[]"
    local dn_failed_json="[]"
    local dn_total=0
    
    if [[ "$DEPLOY_MODE" == "distributed" ]]; then
        # 列实际成功的 DN(SSH 没失败 + EXEC 没失败)
        local all_dns
        all_dns=$(gsql -d "$DB" -p "$CN_PORT" -tA -c \
            "SELECT node_name FROM pgxc_node WHERE node_type='D'" 2>/dev/null)
        dn_total=$(echo "$all_dns" | grep -c .)
        
        # 构造 JSON 数组
        local failed_set=""
        for f in "${DN_FAILED_SSH[@]}" "${DN_FAILED_EXEC[@]}"; do
            local name; name=${f%%:*}
            local reason; reason=${f#*:}
            failed_set+="${name}|${reason}\n"
        done
        
        # 把 failed 列表 dedup 后构造 JSON
        if [[ -n "$failed_set" ]]; then
            dn_failed_json=$(echo -e "$failed_set" | sort -u | grep -v "^$" | \
                awk -F'|' '{printf "{\"name\":\"%s\",\"reason\":\"%s\"},", $1, $2}' | \
                sed 's/,$//; s/^/[/; s/$/]/')
        fi
        
        # collected = all - failed_names
        local failed_names; failed_names=$(echo -e "$failed_set" | awk -F'|' '{print $1}' | sort -u)
        dn_collected_json=$(echo "$all_dns" | grep -vFf <(echo "$failed_names") | \
            awk 'NF{printf "\"%s\",", $1}' | sed 's/,$//; s/^/[/; s/$/]/' || echo "[]")
    fi
    
    local cn_hostname; cn_hostname=$(hostname)
    local cn_node_name=""
    [[ "$DEPLOY_MODE" == "distributed" ]] && cn_node_name=$(gsql -d "$DB" -p "$CN_PORT" -tA -c \
        "SELECT node_name FROM pgxc_node WHERE node_type='C' AND node_host = '$cn_hostname' LIMIT 1" 2>/dev/null)
    
    cat > "$TMP/meta.json" <<EOF
{
  "schema_version": "0.1.0",
  "collected_at": "$(date -Iseconds)",
  "window": {"start": "$START", "end": "$END"},
  "deploy_mode": "$DEPLOY_MODE",
  "cn": {"hostname": "$cn_hostname", "node_name": "$cn_node_name"},
  "dn_total": $dn_total,
  "dn_collected": $dn_collected_json,
  "dn_failed": $dn_failed_json,
  "wdr_unavailable": $WDR_UNAVAILABLE,
  "version": {
    "gaussdb": "$(gsql -d "$DB" -p "$CN_PORT" -tA -c 'SELECT version()' 2>/dev/null | head -1)",
    "dbcollect": "0.1.0"
  }
}
EOF
}

# ============================================================
# 12. checksums.txt
# ============================================================
write_checksums() {
    log "计算 sha256..."
    (cd "$TMP" && find . -type f \! -name "checksums.txt" -exec sha256sum {} \;) > "$TMP/checksums.txt"
}

# ============================================================
# 13. 打包 zip
# ============================================================
build_zip() {
    log "打包 → $OUTPUT"
    (cd "$TMP" && zip -rq "$OUTPUT" .)
    echo "✅ 采集完成 → $OUTPUT"
    echo "   部署形态: $DEPLOY_MODE"
    echo "   时间窗口: $START → $END"
    echo "   zip 大小: $(du -h "$OUTPUT" | awk '{print $1}')"
}

write_meta
write_checksums
build_zip
```

- [ ] **Step 2: shellcheck + bash -n**

```bash
shellcheck dbcollect.sh
bash -n dbcollect.sh
```

- [ ] **Step 3: commit**

```bash
git add dbcollect.sh
git commit -m "feat(perf-kp-sql/gaussdb): dbcollect.sh meta.json + checksums + zip 打包"
```

### Task M1.collect.10: 写采集 README + bats 测试占位

**Files:**
- Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/README.md`
- (可选)Create: `plugins/perf-kp-sql/data/engines/gaussdb/collect/test_dbcollect.bats`

- [ ] **Step 1: 写 README.md**

```markdown
# GaussDB 离线诊断 · 采集脚本

## 用途

部署到 GaussDB CN 节点跑,产出 collected zip · 用于 perf-kp-sql skill 的 `engine=gaussdb` 离线诊断。

## 部署 + 调用

```bash
# 1. SCP 脚本到 CN
scp dbcollect.sh dn-helper.sh sql/*.sql omm@<cn-host>:~/dbcollect/

# 2. 在 CN 上以 omm 用户跑
ssh omm@<cn-host>
cd ~/dbcollect
bash dbcollect.sh \
    --start "2026-05-18 10:00:00" \
    --end   "2026-05-18 11:00:00" \
    --output ~/collected-20260518T103000.zip

# 3. 回收 zip
scp omm@<cn-host>:~/collected-20260518T103000.zip ./

# 4. 离线诊断
/perf-kp-sql engine=gaussdb input=./collected-20260518T103000.zip
```

## 假设

- 以 GaussDB OS 用户(默认 omm)运行
- 节点间 SSH 互信(GaussDB 部署默认条件)
- `$PGDATA` 正确,`gsql` / `gs_om` 在 PATH

## 输出 zip 内目录

(spec §5.4 链接)

## 已知限制

- 分布式版**仅在 CN 节点跑**;DN 文件级数据通过 SSH 跨节点拉
- WDR 生成需 sysadmin 权限,失败标 `wdr_unavailable=true` 不阻断
- 单 DN SSH 不通时进入 `meta.dn_failed[]`,诊断侧标灰

## 配套

- 诊断侧入口:`../diag/run.py`
- skill 入口:`/perf-kp-sql engine=gaussdb input=...`
```

- [ ] **Step 2: commit**

```bash
git add README.md
git commit -m "docs(perf-kp-sql/gaussdb): collect/README.md 采集脚本使用说明"
```

---

## Phase M1.case · case 库写作(22+ 条 · 派生于 archer Diagnoser 内部规则)

> **依赖关系**:M1.case 强依赖 M1.diag.2-3 的 `notes/diagnoser-rules.md`(逐个 Diagnoser 实读源码摘的真实 rule_name 清单)。**不能跳过 M1.diag.2-3 自己编**,否则 case_id 跟 hits.json 对不上。
> 
> **粗估时长**:~11-18 小时(每条 case 30-60 分钟,22-30 条)。
> 
> **case 库格式**:沿用 mongo CASES.md 的 H2 + bullet list + H3 子段格式。**简化字段**:gaussdb case 不需要 `collection_method_quote`(诊断已在 run.py 完成)。

### Task M1.case.1: 写第一批 6 条 case · Memory + Instance Diagnoser

**Files:** Create `plugins/perf-kp-sql/data/cases/gaussdb/CASES.md`

- [ ] **Step 1:** 读 `notes/diagnoser-rules.md` 确认前 6 条规则真实 rule_name + 阈值(来自 M1.diag.2-3)

- [ ] **Step 2:** 写 CASES.md 头注释 + 6 条 case(2 InstanceDiagnoser + 4 MemoryDiagnoser),每条完整 5 子段(symptom_description / diagnostic_signals / likely_causes / fix_template / nlm_keywords),格式见 spec §6.3 模板

- [ ] **Step 3:** commit:`docs(perf-kp-sql/gaussdb): case 库 6 条(Memory + Instance Diagnoser)`

### Task M1.case.2: 第二批 8 条 · IndexCheckerDiagnoser 全部

`GPI_PRESENT / IDX_NDV_ORDER / IDX_COLLATION / IDX_LEFTMOST / IDX_SKIP / IDX_NOT_USED / IDX_IMPLICIT_CAST / IDX_SCAN_LOW_SEL`,每条完整 5 子段。commit message:`docs(perf-kp-sql/gaussdb): case 库 8 条(IndexCheckerDiagnoser 全部)`

### Task M1.case.3: 第三批 4 条 · WaitDiagnoser 全部

`LOCK_WAIT_REGULAR / LOCK_WAIT_LW / WAL_SYNC_SLOW / WAL_FLUSH_SLOW`。commit:`docs(perf-kp-sql/gaussdb): case 库 4 条(WaitDiagnoser 全部)`

### Task M1.case.4: 第四批 4 条 · PlanDiagnoser 全部

`HARD_PARSE_HIGH / TAB_VACUUM_NEEDED / DATA_SKEW / PLAN_QUALITY`。commit:`docs(perf-kp-sql/gaussdb): case 库 4 条(PlanDiagnoser 全部)`

### Task M1.case.5: 第五批 N 条 · StaticDiagnoser SQL 反模式

按 `notes/diagnoser-rules.md` StaticDiagnoser 节(读 `util/sql.py` `SQLDiagnosticEngine.RULE_DEFINITIONS` 得到具体规则),写 N 条 case(估计 5-10)。case_id 用 `SQL_<规则名>`(如 `SQL_NOT_IN` / `SQL_SELECT_STAR` / `SQL_CARTESIAN_JOIN`)。commit:`docs(perf-kp-sql/gaussdb): case 库 N 条(StaticDiagnoser SQL 反模式)`

### Task M1.case.6: 写 INDEX.md 路由表

**Files:** Create `plugins/perf-kp-sql/data/cases/gaussdb/INDEX.md`

按 mongo INDEX.md 格式,**按 Diagnoser 维度 + category 维度双索引** 22+ 条 case。

- [ ] **Step 1:** 写头 + 路由表(InstanceDiagnoser 2 / IndexCheckerDiagnoser 8 / WaitDiagnoser 4 / PlanDiagnoser 4 / MemoryDiagnoser 4 / StaticDiagnoser N · 各一节)+ 按 category 横切(slow_sql / table_def / param)

- [ ] **Step 2:** 计算 line offset:`grep -n "^## case_id:" CASES.md` 填表

- [ ] **Step 3:** commit:`docs(perf-kp-sql/gaussdb): INDEX.md 路由表(22+ cases · Diagnoser + category 双维)`

### Task M1.case.7: 写 by-source-url.json + by-check-item

⚠️ **重要 v0.2 修正**:`by-source-url.json` 的 schema 必须**对齐 notebooklm.mjs 期望的真实 schema**(M3.8 探索确认):

```json
{
  "domains": [
    {
      "domain": "gaussdb",
      "notebook_name": "perf-kp-sql · GaussDB Engine",
      "urls": [
        {"url": "...", "title": "..."},
        ...
      ]
    }
  ]
}
```

**不是** v0.1 plan 里编的 `{sources, case_urls}` schema!

- [ ] **Step 1:** 写 by-source-url.json(列 7-10 个 openGauss + 华为云 GaussDB 公开 URL)

- [ ] **Step 2:** **验证所有 URL 可达**(spec §P4 硬约束,不许编 URL):

```bash
cd plugins/perf-kp-sql/data/cases/gaussdb/indices
python3 -c "
import json
from urllib.request import urlopen
from urllib.error import URLError, HTTPError
data = json.load(open('by-source-url.json'))
for d in data['domains']:
    for entry in d['urls']:
        url = entry['url']
        try:
            r = urlopen(url, timeout=10)
            print(f'  {r.getcode()}  {url}')
        except HTTPError as e:
            print(f'  {e.code} ❌  {url}')
        except (URLError, Exception) as e:
            print(f'  ERR ❌  {url}: {e}')
"
```
任何 status >= 400 的 URL 必须删除或换。urllib 默认 follow redirect(2xx / 3xx 都接受)。

- [ ] **Step 3:** 写 `by-check-item/INDEX.md` + `CASES.md`(按 mongo 格式,per-Diagnoser 的指标 / 参数反查 + 阈值详情)

- [ ] **Step 4:** commit:`docs(perf-kp-sql/gaussdb): by-source-url.json(对齐 notebooklm schema · URL 已验证) + by-check-item INDEX/CASES`

### Task M1.case.8: case 库一致性测试

**Files:** Modify(可能) `plugins/perf-kp-sql/tests/cases/*.test.ts`(3 个现有测试)

- [ ] **Step 1:** 读现有 3 个 ts 测试(`golden-validity / field-integrity / index-integrity`)看模式

- [ ] **Step 2:** 决定 fork 还是参数化:**若硬编码 `data/cases/INDEX.md` 路径 → 优先参数化 engine,跑 mongo + gaussdb 两组 fixture(改动 < 10 行)。否则 fork 一份 `gaussdb-*.test.ts`**

- [ ] **Step 3:** 实现 ts 测试 · 验证:
  - gaussdb INDEX.md 列的 case_id 在 CASES.md 都有
  - CASES.md 每条 case 都在 INDEX 里有表项
  - 必填字段齐(`diagnoser / rule_name / title / severity / category / source_url`)
  - `by-source-url.json` 结构跟 mongo 版对齐(都 `{domains:[...]}`)

- [ ] **Step 4:** `npm test -- tests/cases` 验证 PASS

- [ ] **Step 5:** commit:`test(perf-kp-sql/gaussdb): case 库一致性测试覆盖 gaussdb engine`

---

## Phase M3 · skill 改造 + 集成

> **依赖关系**:**所有 M3 任务都依赖 M1 全部完成**(M1.diag.7 sample.zip 端到端跑通 + M1.case.6 INDEX.md 写好)。M3 内部 3.1 mongo case 挪动是 prerequisite,其他可串行。
> 
> **重要 v0.2 修正:M3.8 blockedBy M3.1**(否则 notebooklm.mjs URLS_PATH L38 硬编码路径会断,mongo NLM 功能坏)。
> 
> **粗估时长**:~10-14 小时(1.5 工作日)。

### Task M3.1: 挪 mongo case 到 data/cases/mongo/ 子目录

**Files:**
- Move: `plugins/perf-kp-sql/data/cases/{INDEX,CASES}.md` → `plugins/perf-kp-sql/data/cases/mongo/{INDEX,CASES}.md`
- Move: `plugins/perf-kp-sql/data/cases/indices/` → `plugins/perf-kp-sql/data/cases/mongo/indices/`

- [ ] **Step 1: git mv 而非 cp + rm(保留历史)**

```bash
cd /Users/david/code/perf-kp-sql-gaussdb-wt
mkdir -p plugins/perf-kp-sql/data/cases/mongo
git mv plugins/perf-kp-sql/data/cases/INDEX.md plugins/perf-kp-sql/data/cases/mongo/INDEX.md
git mv plugins/perf-kp-sql/data/cases/CASES.md plugins/perf-kp-sql/data/cases/mongo/CASES.md
git mv plugins/perf-kp-sql/data/cases/indices plugins/perf-kp-sql/data/cases/mongo/indices
```

- [ ] **Step 2: 验证结构**

```bash
find plugins/perf-kp-sql/data/cases -maxdepth 4 -type f
```
Expected:
```
plugins/perf-kp-sql/data/cases/mongo/INDEX.md
plugins/perf-kp-sql/data/cases/mongo/CASES.md
plugins/perf-kp-sql/data/cases/mongo/indices/by-source-url.json
plugins/perf-kp-sql/data/cases/mongo/indices/by-check-item/INDEX.md
plugins/perf-kp-sql/data/cases/mongo/indices/by-check-item/CASES.md
plugins/perf-kp-sql/data/cases/gaussdb/INDEX.md
plugins/perf-kp-sql/data/cases/gaussdb/CASES.md
plugins/perf-kp-sql/data/cases/gaussdb/indices/by-source-url.json
plugins/perf-kp-sql/data/cases/gaussdb/indices/by-check-item/INDEX.md
plugins/perf-kp-sql/data/cases/gaussdb/indices/by-check-item/CASES.md
```

- [ ] **Step 3: 跑 case 库测试看现有 mongo 测试是否还能找到**

```bash
cd plugins/perf-kp-sql
npm test -- tests/cases 2>&1 | tail -20
```
预期会有失败(测试硬编码了旧路径),记录失败的测试名。

- [ ] **Step 4: 修 case 库测试中硬编码的 mongo 路径**

```bash
grep -rln "data/cases/INDEX\|data/cases/CASES\|data/cases/indices" plugins/perf-kp-sql/tests/
```
对每个命中文件,Edit 把 `data/cases/INDEX.md` 改成 `data/cases/mongo/INDEX.md`,以此类推。

- [ ] **Step 5: 再跑测试**

```bash
npm test -- tests/cases
```
Expected:全 PASS

- [ ] **Step 6: commit**

```bash
git commit -m "refactor(perf-kp-sql): mongo case 挪进 data/cases/mongo/ + 修测试路径(对位 gaussdb)"
```

### Task M3.2: SKILL.md 批改 16 处 case 路径

**Files:**
- Modify: `plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md`

Task 0.3 step 2 已经列了 16 处需改的位置(notes/skillmd-path-refs.md)— 数字以本仓库实际 grep 为准:

```bash
grep -nE "data/cases/" plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md | wc -l
```

- [ ] **Step 1: 用 Edit 工具批改**

逐处 Edit:
- `data/cases/INDEX.md` → `data/cases/<engine>/INDEX.md`(`<engine>` 是 Phase 0 注入的运行时变量)
- `data/cases/CASES.md` → `data/cases/<engine>/CASES.md`
- `data/cases/indices/by-check-item/INDEX.md` → `data/cases/<engine>/indices/by-check-item/INDEX.md`
- `data/cases/indices/by-check-item/CASES.md` → `data/cases/<engine>/indices/by-check-item/CASES.md`
- `data/cases/indices/by-source-url.json` → `data/cases/<engine>/indices/by-source-url.json`

注意 SKILL.md 第 181 行的 `<候选路径>/data/cases/INDEX.md` 是 pre-flight 检测命令,要改成 `<候选路径>/data/cases/mongo/INDEX.md`(或 gaussdb,任一个都能验证)。

- [ ] **Step 2: 验证 grep 干净**

```bash
grep -n "data/cases/INDEX\|data/cases/CASES" plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md
```
Expected:无命中(全改成 `data/cases/<engine>/...` 或 `data/cases/mongo/...`)

- [ ] **Step 3: commit**

```bash
git add plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md
git commit -m "refactor(perf-kp-sql): SKILL.md 批改 14 处 case 路径加 <engine> 分流"
```

### Task M3.3: SKILL.md argument-hint + frontmatter trigger 改造

**Files:**
- Modify: `plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md`(开头 frontmatter)

- [ ] **Step 1: 改 argument-hint**

定位 `argument-hint:` 行,改成:

```yaml
argument-hint: |
  engine=mongo:   host=<ip> user=<user> (privateKeyPath=<path>|password=<pw>) [port=<ssh_port>]
  engine=gaussdb: input=<collected_zip_path>
```

- [ ] **Step 2: 改 description 加 GaussDB 支持**

定位 frontmatter `description:` 字段,扩成(沿用现有 mongo 描述,加 gaussdb 一段):

```yaml
description: |
  Kunpeng ARM64 + MongoDB joint performance diagnosis (engine=mongo) and GaussDB
  offline performance diagnosis (engine=gaussdb).
  
  mongo:  SSH-based remote collection + 7-phase LLM-orchestrated pipeline + 99 case
  library + NotebookLM authoritative source.
  
  gaussdb: 离线模式 · 输入用户从 GaussDB CN 节点跑 dbcollect.sh 产出的 collected zip,
  自家 archer 派生的 12 条 udf 规则 + 6 个 checker + 15 个 model 全量预筛输出 hits.json,
  LLM 综合写 markdown 报告。NLM 喂 openGauss 公开文档 + 华为云 GaussDB 文档作权威源。
  
  Use when users report MongoDB / GaussDB slowness, CPU spikes, latency jitter, slow SQL,
  unreasonable table definitions, parameter audit, distributed CN bottleneck, DN data skew.
  
  Triggers: '数据库慢' / 'CPU 高' / '抖动' / 'mongo perf' / 'Kunpeng 性能' /
  'gaussdb 慢' / 'GaussDB 性能' / 'openGauss 慢' / '分布式数据库' / 'CN 瓶颈' /
  'DN 倾斜' / '数据倾斜' / 'pgxc_*' / 'WDR 分析' / 'Stream Broadcast' /
  '分布列选错' / '参数调优' / '不合理表定义' / 'GTM'.
  
  First-time:run `/perf-kp-sql-setup` to verify runtime + register NotebookLM (mongo + gaussdb 两个 notebook 可选).
```

- [ ] **Step 3: 改 compatibility 字段加 gaussdb engine**

定位 `compatibility:` 段,加一段说明 gaussdb engine 走离线模式,不依赖 SSH wrapper,只需要 Python 3 + zip + 标准 unix 工具。

- [ ] **Step 4: commit**

```bash
git commit -am "feat(perf-kp-sql): SKILL.md frontmatter argument-hint + description 加 gaussdb engine"
```

### Task M3.4: SKILL.md Phase 0 改造(zip 解包 + 采集说明书)

**Files:**
- Modify: `plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md`(Phase 0 段)

- [ ] **Step 1: 在 Phase 0 章节加 engine=gaussdb 分流子段**

定位 `## Phase 0 · 环境信息采集(凭据 + 连通性探测 + 环境画像)` 段(SKILL.md L429 附近),加一段:

```markdown
### Phase 0 · engine=gaussdb 分流(离线 zip 模式)

> 仅当用户传 `engine=gaussdb` 触发本段流程 · mongo 流程保持原样

#### 0.1G 接收 input

凭据采集换成:从 `argument-hint` 拿 `input=<path>` · path 必填。如果 `input` 为空:
跳到 **Phase 0.6G**(输出采集说明书,终止当前会话,等用户带 zip 重新调用)。

#### 0.2G zip 解包 + meta 校验

```
Bash(command="""
WORKDIR=$(mktemp -d -t perf-kp-sql-gaussdb-XXXXXX)
unzip -q '<input path>' -d "$WORKDIR" || { echo 'ZIP_CORRUPT'; exit 1; }
[ -f "$WORKDIR/meta.json" ] || { echo 'META_MISSING'; exit 2; }
[ -f "$WORKDIR/checksums.txt" ] || { echo 'CHECKSUMS_MISSING'; exit 2; }
(cd "$WORKDIR" && sha256sum -c checksums.txt --quiet) || { echo 'CHECKSUM_MISMATCH'; exit 3; }
cat "$WORKDIR/meta.json"
echo "WORKDIR=$WORKDIR"
""")
```

stdout 校验通过 → 继续。失败任一项 → Phase 0.4G 阻断。

#### 0.3G 环境画像构建

Read 以下文件,组合成 `[环境上下文]`:
- `<WORKDIR>/meta.json` · deploy_mode + cn + dn_total + dn_collected + dn_failed + window
- `<WORKDIR>/env/uname.txt` + `lscpu.txt` + `free.txt` · OS / CPU / 内存
- `<WORKDIR>/deploy/cluster_status.txt` 或 `status.txt` · 部署状态

输出格式:

```
[环境上下文]
  部署形态: distributed (CN:1, DN:4 collected, 1 failed)
  GaussDB:  openGauss-X.X.X / GaussDB Kernel xxx
  OS:       Kunpeng 920 / 256GB / 16 core
  采集窗口:  2026-05-18 10:00 → 11:00
  WDR:      可用 / 不可用
  DN 缺失:   datanode3 (reason: ssh timeout 30s)
```

#### 0.4G 阻断判定

如果 0.2G 任一 exit code ≠ 0 → 阻断,不进 Phase 1。给用户报错 + 建议(zip 损坏让重采;meta 缺失让确认 dbcollect 版本)。

#### 0.5G 输出 [环境上下文]

把 0.3G 的结构化文本作为后续 phase 的上下文锚点。

#### 0.6G `input` 为空时:输出采集说明书

如果 0.1G 检测 `input` 参数没传:

```
打屏给用户:

═════════════════════════════════════════════════════
GaussDB 离线诊断 · 现场采集说明书
═════════════════════════════════════════════════════

[步骤 1] 把以下 3 个脚本 SCP 到 GaussDB CN 节点的 omm 用户家目录:

  本地路径:
    <PLUGIN_ROOT>/data/engines/gaussdb/collect/dbcollect.sh
    <PLUGIN_ROOT>/data/engines/gaussdb/collect/dn-helper.sh
    <PLUGIN_ROOT>/data/engines/gaussdb/collect/sql/        (整个目录)

  示例命令(替换 <cn-host>):
    scp dbcollect.sh dn-helper.sh omm@<cn-host>:~/dbcollect/
    scp -r sql/ omm@<cn-host>:~/dbcollect/

[步骤 2] 在 CN 节点上以 omm 用户跑:

  ssh omm@<cn-host>
  cd ~/dbcollect
  bash dbcollect.sh \
      --start "2026-05-18 10:00:00" \
      --end   "2026-05-18 11:00:00" \
      --output ~/collected-$(date +%Y%m%dT%H%M%S).zip

[步骤 3] 等脚本跑完(预计 5-15 分钟),拉 zip 回本地:

  scp omm@<cn-host>:~/collected-*.zip ./

[步骤 4] 回来重新调用:

  /perf-kp-sql engine=gaussdb input=./collected-<TS>.zip
═════════════════════════════════════════════════════

→ 终止当前会话,等用户带 zip 回来。
```

终止后**不进 Phase 1**。
```

- [ ] **Step 2: 验证 phase 编号子步骤可读**

人工 review 一遍这段 — 子步号 0.1G-0.6G 是否清晰,跟原 mongo 0.1-0.5 不冲突。

- [ ] **Step 3: commit**

```bash
git commit -am "feat(perf-kp-sql): SKILL.md Phase 0 gaussdb 分流(zip 解包 + 采集说明书)"
```

### Task M3.5: SKILL.md Phase 3 改造(调 run.py)

**Files:**
- Modify: `plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md`(Phase 3 段)

- [ ] **Step 1: Phase 3 段加 engine=gaussdb 分流**

定位 `## Phase 3 · 诊断指标采集` 段(SKILL.md L947 附近),加 gaussdb 子段:

```markdown
### Phase 3 · engine=gaussdb 分流(调 run.py)

> 仅当 engine=gaussdb · mongo 流程保持原样

#### 3.1G Bash 调 run.py

```
Bash(command="""
python3 <PLUGIN_ROOT>/data/engines/gaussdb/diag/run.py \
    --input '<input zip path>' \
    --output-json -
""")
```

`<input zip path>` 来自 Phase 0.1G。
`<PLUGIN_ROOT>` 来自 SKILL.md L171 的 PLUGIN_ROOT 探测。

#### 3.2G 检查 stdout / exit code

- exit ≠ 0 → 阻断 · 写报错 + 进 Phase 6 让用户排查 zip 完整性
- stdout 为空 → 同上
- exit = 0 + stdout 是合法 JSON → 进 3.3G

#### 3.3G 解析 hits.json + schema_version 校验

- `output.schema_version` 必须等于 `0.1.0`(将来升级再扩 compat 矩阵)
- `output.hits[]` 含命中 case 列表
- `output.summary` 含 total_hits / by_severity / by_category

把 `output` 作为 Phase 4 的输入 · 跳过 mongo 的 "Phase 3.A.3 火焰图采集" 等子段(gaussdb 不适用)。
```

- [ ] **Step 2: commit**

```bash
git commit -am "feat(perf-kp-sql): SKILL.md Phase 3 gaussdb 分流(调 run.py + hits.json)"
```

### Task M3.6: SKILL.md Phase 5 报告章节模板(gaussdb 版)

**Files:**
- Modify: `plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md`(Phase 5 / 综合描述 / 诊断结果 / 辅助信息 段)

- [ ] **Step 1: 在 Phase 5 章节加 engine=gaussdb 分流的报告模板**

定位 Phase 5 现有的 mongo 模板段(L1292+),加 gaussdb 模板:

```markdown
### Phase 5 · engine=gaussdb 报告章节模板

> 仅当 engine=gaussdb · mongo 模板保持原样

按 spec §9 的章节生成:

```markdown
# GaussDB 性能诊断报告 · <采集时间窗口>

## 环境上下文
- 部署形态: <distributed / centralized>
- GaussDB 版本: <version>
- OS / 硬件: <Kunpeng 920 / 256GB / 16 core>
- 集群拓扑: (ASCII 图)
- 采集时间窗口: <start> → <end>
- 数据缺失: <dn_failed / wdr_unavailable / nlm 缺失>

## 综合描述
<1-3 句话定性 + 主要发现 + 影响面 + 紧急度>

## 诊断结果(按严重度排序)
| # | 严重度 | 类别 | 现象 | 根因 | 修复建议 | 参考 |
|---|--------|------|------|------|----------|------|

## 详细分析
### 慢 SQL · TopN(从 hits 的 slow_sql 类聚合 + dump/cn/statement_history)
### 表定义问题(从 hits 的 table_def 类聚合)
### 参数审计(从 hits 的 param 类聚合 + dump/cn/pg_settings 全量审查)
### 倾斜证据(从 dump/dn/*/dump/pg_stat_all_tables 横向对比)

## 辅助信息
### 现场观测(无案例引用)
### 数据缺失
### 采集元信息

## 参考
[参考N] 来自 cases/gaussdb/CASES.md 的 source_url 字段 · verbatim
```
```

- [ ] **Step 2: commit**

```bash
git commit -am "feat(perf-kp-sql): SKILL.md Phase 5 gaussdb 报告章节模板"
```

### Task M3.7: SKILL.md trigger / pre-flight Python 检测

**Files:**
- Modify: `plugins/perf-kp-sql/skills/perf-kp-sql/SKILL.md`

- [ ] **Step 1: 找 pre-flight 段(L171 附近 PLUGIN_ROOT 解析)加 Python 检测**

加一段 gaussdb 专属 pre-flight:

```markdown
### engine=gaussdb pre-flight(skill 启动一次)

如果 `engine=gaussdb`:

```
Bash(command="""
python3 --version 2>&1 | grep -E 'Python 3\.([89]|1[0-9])' || \
    { echo 'PYTHON_TOO_OLD: 需 Python 3.8+'; exit 1; }

ls <PLUGIN_ROOT>/data/engines/gaussdb/diag/run.py \
   <PLUGIN_ROOT>/data/engines/gaussdb/diag/parse_dict.py \
   <PLUGIN_ROOT>/data/engines/gaussdb/diag/rules/udf_funcs.py \
   <PLUGIN_ROOT>/data/cases/gaussdb/INDEX.md \
   <PLUGIN_ROOT>/data/cases/gaussdb/CASES.md \
   >/dev/null 2>&1 || { echo 'INSTALL_INCOMPLETE: 文件缺失'; exit 2; }

echo 'gaussdb pre-flight OK'
""")
```

stderr 任一项失败 → 阻断,提示用户重装 ohsql-plugin 或 `pip install -r diag/requirements.txt`。
```

- [ ] **Step 2: commit**

```bash
git commit -am "feat(perf-kp-sql): SKILL.md gaussdb pre-flight Python 3 检测"
```

### Task M3.8: 修 notebooklm.mjs 路径 + 加 gaussdb domain entry

> ⚠️ **依赖**:**`blockedBy M3.1`**(M3.1 挪 mongo case 后,notebooklm.mjs L38 `URLS_PATH` 硬编码会断;必须紧跟着 M3.1 改路径,否则 mongo NLM 坏)

**Files:**
- Modify: `plugins/perf-kp-sql/scripts/notebooklm.mjs`(只改 1 处路径)
- Modify: `plugins/perf-kp-sql/skills/perf-kp-sql-setup/SKILL.md`(扩 gaussdb 引导)

**重要 v0.2 简化**(对比 v0.1):**不需要重写 notebooklm.mjs**。Sonnet review 已验证:

- notebooklm.mjs **已经支持多 domain**(`KEYWORD_ROUTES.os / mongo / kunpeng`,见 L784-788)
- `by-source-url.json` schema 是 `{domains:[{domain,notebook_name,urls}]}`(L647 `for (const domainDef of urlsData.domains)`)
- 不需要加 `--engine` 参数,不需要 config migrate,不需要新测试

实际改动只 3 件事:

- [ ] **Step 1: 修 notebooklm.mjs L38 `URLS_PATH` 路径**

mongo case 挪进子目录后,原路径 `data/cases/indices/by-source-url.json` 不存在了。改成动态拼:

```js
// 原(L38):
const URLS_PATH = join(PLUGIN_ROOT, "data", "cases", "indices", "by-source-url.json");

// 改成:接 --urls-file 参数(原本就支持) · 默认值改成所有 engine 合并
// 简化方案:默认指向 mongo 的(保持现有 mongo 路径默认,gaussdb 通过 --urls-file 传)
const URLS_PATH = join(PLUGIN_ROOT, "data", "cases", "mongo", "indices", "by-source-url.json");
```

或者更彻底(推荐):去掉这个 module-level 常量,让 `loadUrlsJson()` 必须由调用方显式传 `urlsFile`,默认走 mongo:

```js
function loadUrlsJson(urlsFile) {
  const p = urlsFile ?? join(PLUGIN_ROOT, "data", "cases", "mongo", "indices", "by-source-url.json");
  if (!existsSync(p)) fatal(`by-source-url.json not found: ${p}`);
  return JSON.parse(readFileSync(p, "utf8"));
}
```

- [ ] **Step 2: 把 gaussdb 加进 KEYWORD_ROUTES(notebooklm.mjs L784-788)**

```js
const KEYWORD_ROUTES = {
  os: [/vm\.\w+/i, /dirty_ratio/i, /hugepage/i, /\bTHP\b/i, /sysctl/i, ...],
  mongo: [/wiredTiger/i, /mongod/i, /oplog/i, /shard/i, ...],
  kunpeng: [/鲲鹏/i, /kunpeng/i, /\bARM\b/i, /aarch64/i, ...],
  gaussdb: [   // ← 新增
    /gaussdb/i, /opengauss/i, /pgxc_/i, /\b分布列\b/, /\bCN\b/i, /\bDN\b/i,
    /coordinator/i, /datanode/i, /数据倾斜/i, /WDR/i, /\bdbe_perf\b/i,
    /shared_buffers/i, /work_mem/i, /\bwal\b/i, /vacuum/i, /analyze/i, /硬解析/i,
  ],
};
```

- [ ] **Step 3: setup skill 扩 gaussdb 引导**

在 `plugins/perf-kp-sql/skills/perf-kp-sql-setup/SKILL.md` 的 NLM 注册段加:

```markdown
### NLM Notebook 注册 · gaussdb engine(可选)

如果用户打算用 `engine=gaussdb`,**额外**建一个 NLM notebook(已有 mongo notebook 不动):

跑:
```bash
node <PLUGIN_ROOT>/scripts/notebooklm.mjs --op add-domain \
    --domain gaussdb \
    --urls-file <PLUGIN_ROOT>/data/cases/gaussdb/indices/by-source-url.json
```

`add-domain` op(notebooklm.mjs 现有功能,无需改 .mjs 代码)会:
- 在 NotebookLM Web 上建一个 `perf-kp-sql · GaussDB Engine` notebook
- 加 by-source-url.json 列出的 URL 作 source
- 配置写到 `~/.perf-kp-sql/notebooklm.json` 的 `notebooks.gaussdb` entry
```

- [ ] **Step 4: shellcheck / npm test 验证 mongo 兼容**

```bash
cd plugins/perf-kp-sql
npm test
# mongo notebooklm 流程不破
```
Expected:全 PASS,mongo 测试无影响。

- [ ] **Step 5: commit**

```bash
git add plugins/perf-kp-sql/scripts/notebooklm.mjs \
        plugins/perf-kp-sql/skills/perf-kp-sql-setup/SKILL.md
git commit -m "fix(perf-kp-sql): notebooklm URLS_PATH 配 mongo 子目录 + 加 gaussdb KEYWORD_ROUTES + setup 加 gaussdb 引导"
```

### Task M3.9: 端到端 · skill 内调通 sample.zip → markdown 报告

**Files:**
- 不修改任何源码 · 跑 skill 端到端

- [ ] **Step 1: 把 perf-kp-sql skill local-install 到 plugin cache**

```bash
cd /Users/david/code/perf-kp-sql-gaussdb-wt
# 假设有个 build 命令
npm run build  # 或 ./scripts/_build.mjs · 看 plugin.json 怎么 build
```

或者直接把 worktree 路径加到 Claude Code 的 `extra_plugin_paths`(如果有这种机制)。

- [ ] **Step 2: 跑端到端**

启动一个新 Claude Code session,运行:

```
/perf-kp-sql engine=gaussdb input=/Users/david/code/perf-kp-sql-gaussdb-wt/plugins/perf-kp-sql/data/engines/gaussdb/diag/tests/fixtures/sample-collected.zip
```

观察 LLM 走完 7 phase + 出 markdown 报告。

- [ ] **Step 3: 人工 review 报告内容**

确认:
- 环境上下文段拓扑正确(centralized? distributed?)
- 诊断主表至少有 1 条 hit(TAB_NOT_ANALYZE)
- 每条主表行的"参考"列 URL **verbatim 来自 cases/gaussdb/CASES.md**(对比一下)
- 没有捏造的 URL / 字段

如果发现问题,记录在 `notes/e2e-issues.md` 回头修。

- [ ] **Step 4: 跑空 input 流程**

```
/perf-kp-sql engine=gaussdb
```
Expected:输出采集说明书,**不进 Phase 1**。

- [ ] **Step 5: 跑 mongo 兼容性验证**

```
/perf-kp-sql engine=mongo host=test-host user=test ...
```
Expected:mongo 流程**不受影响** · 仍走原 SSH 流程。

- [ ] **Step 6: commit 端到端验证记录**

```bash
echo "端到端验证记录 · 2026-05-XX" > notes/e2e-validation.md
echo "  - gaussdb sample.zip 跑通:✅" >> notes/e2e-validation.md
echo "  - 空 input 采集说明书:✅" >> notes/e2e-validation.md
echo "  - mongo 兼容:✅" >> notes/e2e-validation.md
git add notes/
git commit -m "test(perf-kp-sql): 端到端验证记录(gaussdb engine 三个场景)"
```

---

## 完成阶段 · code review + 合并

### Task FIN.1: 全量回归测试

**Files:** 不修改源码 · 跑全测试套件

- [ ] **Step 1: Python 测试**

```bash
cd plugins/perf-kp-sql/data/engines/gaussdb/diag
python3 -m pytest tests/ -v
```
Expected:全 PASS

- [ ] **Step 2: TypeScript 测试**

```bash
cd plugins/perf-kp-sql
npm test
```
Expected:全 PASS · 注意 mongo case 测试改路径后是否仍 PASS

- [ ] **Step 3: shellcheck**

```bash
shellcheck plugins/perf-kp-sql/data/engines/gaussdb/collect/dbcollect.sh
shellcheck plugins/perf-kp-sql/data/engines/gaussdb/collect/dn-helper.sh
```
Expected:无 error(warning 看情况处理)

- [ ] **Step 4: 记录回归通过**

记录在 commit message 里(下一步)。

### Task FIN.2: Code Review(必须不同模型评审者)

**重要**:用户 CLAUDE.md 强制要求:
> 代码开发完成后必须经过 code review 才算交付,不许"写完即合"。
> 评审者模型必须不同于作者模型——同一模型自审等于没审,会保留同型偏盲点。
> - Opus 写的代码 → Sonnet (或 Haiku)评审为佳
> - Sonnet 写的代码 → Opus (或另一家模型)评审为佳
> 评审走"团队"模式而非单评审者:至少一个语义/架构评审 + 一个安全/边界评审,可并行。
> 推荐用 superpowers:code-reviewer 子代理 + Codex codex:rescue 双路交叉。

**如果本 plan 由 Opus 4.7 执行**:

- [ ] **Step 1: 派 superpowers:code-reviewer 子代理(让它跑 Sonnet 4.6 或 Haiku 4.5)做语义 / 架构评审**

```
关注点:
- M1.diag 抽 archer 代码后 import 路径正确性 + 逻辑没退化
- run.py 的 hits.json schema 跟 spec §6.1 一致
- dbcollect.sh 失败降级路径全(每个 exit 码都对)
- SKILL.md engine 分流子段号(0.1G/3.1G 等)不跟 mongo 段冲突
- case 库 12 条字段齐全 + URL 可达
```

- [ ] **Step 2: 同时派 codex:rescue 做安全 / 边界评审**

```
关注点:
- dbcollect.sh 引号转义安全(EXECUTE DIRECT \$\$ ... \$\$ 没有 shell 注入)
- run.py 解 zip 的路径穿越漏洞(zipfile 默认不防 ../)
- SSH 凭据是否走 ssh-agent / key,不在命令行
- meta.json 写入是否有 race(并发 dn-helper 重写覆盖)
- Python 依赖 lock 是否够紧
```

- [ ] **Step 3: 收集 review 意见 → 列改 list**

每条评审意见决定:接受 / 拒绝 / 需要更多上下文 · 列在 `notes/review-decisions.md`。

不接受的项 → 用 superpowers:receiving-code-review skill 严格走"技术质问 + 验证"流程,不许 performative agreement。

- [ ] **Step 4: 实施接受的改动**

每条改动一个独立 commit · message 前缀 `review(perf-kp-sql/gaussdb):`。

- [ ] **Step 5: 重新跑评审验证修完**

让同一对评审者再过一次,确认无新发现。

### Task FIN.3: PR + 合并准备

**Files:**
- (可能)Modify: PR description / changelog

- [ ] **Step 1: 切回到主 worktree push 远程**

```bash
cd /Users/david/code/perf-kp-sql-gaussdb-wt
git log --oneline origin/main..HEAD
git push -u origin feat/gaussdb-engine
```

- [ ] **Step 2: 创建 PR**

```bash
gh pr create --title "feat(perf-kp-sql): 加 GaussDB engine 离线诊断支持" \
  --body "$(cat <<'EOF'
## Summary

- 给 perf-kp-sql 加 `engine=gaussdb input=<path>` 入口,实现 GaussDB 离线诊断
- 从 archer-ui 抽 12 条 udf 规则 + 6 个 checker + 15 个 model + 采集脚本到 skill 内部
- case 库 `data/cases/{mongo,gaussdb}/` engine 平级(mongo 也挪进子目录,**不破坏 mongo 现有流程**)
- NLM 接 openGauss / 华为云 GaussDB 公开文档作权威源

## Test plan

- [x] Python 测试 · `pytest plugins/perf-kp-sql/data/engines/gaussdb/diag/tests/`
- [x] TypeScript 测试 · `npm test`(case 库一致性 / mongo 兼容)
- [x] shellcheck · dbcollect.sh + dn-helper.sh
- [x] 端到端 · sample.zip 跑通 + 空 input 采集说明书 + mongo 兼容
- [x] Code review · superpowers:code-reviewer(Sonnet/Haiku) + codex:rescue 双路

## 已对齐设计判断(见 spec)

参见 `docs/superpowers/specs/2026-05-18-perf-kp-sql-gaussdb-engine-design.md` §4 决策表 + §13 风险。

## 已知不做

- M2 archer-ui 切到调 dbdiag CLI(跳过 · archer-ui 继续用旧 import 路径)
- 在线 SSH 模式诊断 GaussDB(下一期)
- 给 archer-ui 之外的第三方 agent 复用(本期内部自用)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: 让用户决定合并策略**

PR 链接给用户 · 等用户最终 review + merge。merge 后用 superpowers:finishing-a-development-branch skill 处理 worktree 清理 + 分支删除。

---

## Plan 总结

| Phase | Tasks | 估时 | 并发性 |
|-------|-------|------|--------|
| **0 · 准备** | 0.1-0.4 (4 task) | 1.5-2 h | 串行 |
| **M1.diag · 诊断侧** | 1-8 (8 task) | 14-18 h | 跟 M1.collect 可并行 |
| **M1.collect · 采集侧** | 1-10 (10 task) | 10-14 h | 跟 M1.diag 可并行 |
| **M1.case · case 库** | 1-8 (8 task) | 11-18 h | **强依赖 M1.diag.2-3 的 diagnoser-rules.md** |
| **M3 · skill 改造** | 1-9 (9 task) | 10-14 h | 依赖 M1 全部完成 · **M3.8 blockedBy M3.1** |
| **FIN · 完成** | 1-3 (3 task) | 4-6 h | 串行 · 评审强制不同模型 |

**总计**:42 task · ~50-72 小时 · 约 **2-2.5 工作周**(单人 · 不算 review 等待)。

---

## v0.2 改动总览(应用 Sonnet review)

| 改动 | 影响 task | 状态 |
|---|---|---|
| 不复用 udf_funcs / cluster_checker / wdr_comparison(spec §1.2 + §6.2) | M1.diag.1-8 整段重写 | ✅ |
| 复用 archer 新体系 `gs_dsw/funcs/` 6 个 Diagnoser + ModelRunner + health_report | M1.diag.1-8 | ✅ |
| run.py 改成包装 `health_report.run(WebArgs)` | M1.diag.6 | ✅ |
| 加 transform.py 把 archer final_report_data → hits.json | M1.diag.6 | ✅ |
| case 库 12 → 22+ 条 | M1.case.1-8 整段重写 | ✅ |
| case_id 命名改成基于 Diagnoser 内部规则 | M1.case.1-5 | ✅ |
| EXECUTE DIRECT bash 转义改 heredoc + dollar-quote 自定义边界 | M1.collect.6 | ✅ |
| notebooklm.mjs 不重写,只改 URLS_PATH + 加 gaussdb KEYWORD_ROUTES | M3.8 整段精简 | ✅ |
| M3.8 加 `blockedBy M3.1`(避免 mongo NLM 坏) | M3.8 header | ✅ |
| SKILL.md 16 处路径(不是 14 处) | M3.2 数字 | ✅ |
| by-source-url.json schema 改 `{domains:[{domain,notebook_name,urls}]}` | M1.case.7 + M3.8 | ✅ |
| URL 验证 follow redirect(urllib 默认) | M1.case.7 step 2 | ✅ |
| collect/sql/ 整段废 — model 自带 SQL | M1.collect.1 整段重写 + M1.collect.6 dbcollect.sh 第 8 步改调 run_models.py | ✅ |
| dbcollect.sh 必须用 long-opt 参数 · 避免 cent.sh `schemaname=$5; hostip=$5` 位置参数覆盖 bug | M1.collect.1 末尾"避坑" + M1.collect.2 已用 long-opt | ✅ |
| TDD 拆 unit + integration(transform.py 先单元,run.py 后集成) | M1.diag.6 | ✅ |
| run.py exit 码语义(2/3/4 各对应业务错误) | M1.diag.6 | ✅ |

---

**End of plan v0.2**
