# archer-ui 真实接口探索笔记

> 探索时间：2026-05-18  
> 目标分支：worktrees/4a46  
> 目标目录：`archer-ui/views/gs_dsw/funcs/` + `archer-ui/views/gs_dignose_report/`

---

## TL;DR（3 句话）

1. **6 个 checker 中，5 个（instance/index/sql/sqlplan/bak/waitevent）是真正的诊断规则**，封装在 class 里、接收 `data_bundle: Dict`，可复用；`cluster_checker.py` 和 `wdr_comparison.py` 是**工具脚本**（SSH 日志采集 / WDR HTML 解析），不含可复用诊断规则。
2. **`gs_dignose_report/udf_funcs.py` 的 12 条规则是另一套完全独立的旧体系**（依赖 `parse_dict` module-global 状态 + `diagnose` C 扩展），不和 `gs_dsw` 的 ModelRunner 体系共享，直接拷贝需大量改造。
3. **15 个 model 全部是 `BaseModel` 子类，只负责采集（gsql 执行 SQL）和 parse（读文件→List[Dict]）**，是数据层，不含诊断逻辑；可以直接拷贝当数据适配层用。

---

## Q1 · 6 个 checker 的真实接口

### cluster_checker.py

- **签名**：顶层 `def run(args)`（第 645 行）；内部主类 `LogCollector` + `ClusterAnalyzer`
- **入参**：`args` 是 argparse.Namespace，包含 `--mode online/offline`、`-f 文件路径`、`--start-time`、`--end-time`、`--events` 等
- **做什么**：
  - online 模式：`cm_ctl query -Cvd` 发现集群拓扑 → 对每台主机 SSH 执行 shell 脚本（grep GS 日志 / CMA 日志 / CMS 日志）→ 写本地 log 文件
  - offline 模式：直接分析本地已有的 log 文件（`analyzer.analyze(log_file)`）
  - 输出：CLI 打印关键事件时间线表格（stdout 打印），**无返回值**
- **能离线诊断吗**：**否**。它是日志采集+关键词检索工具，不是诊断规则引擎。输出是 ASCII 表格打印，没有结构化 return。
- **改造路径**：**整段废掉 / 独立保留**。可以把 `GS_SINGLE_PATTERNS`、`CMA_PATTERNS`、`CMS_PATTERNS` 这些关键字 dict 拿来当 GaussDB 异常日志模式参考，但整个 cluster_checker 不适合作为诊断规则复用。

---

### instance_checker.py

- **签名**：顶层 `def run(args)`（第 176 行）；内部主类 `InstanceDiagnoser(data_context: Dict[str, Any])`
- **入参**：`InstanceDiagnoser.__init__` 接收 `data_context: Dict`，key 为 `'statement_history'`、`'gs_gsc_dbstat_info'`、`'top_wait_events'`
- **做什么**：纯计算诊断——聚合 TopSQL 的 Buffer 命中率、GSC 命中率；无 SSH、无文件读取
- **输出**：`execute_diagnosis()` 返回 `List[Dict]`，字段包含 `rule_name/status/result/reason/suggestion/detail/sql_id`
- **能离线诊断吗**：**是**。传入正确的 data_context dict 即可独立运行
- **改造路径**：**不动，直接包装**。只需要把 GaussDB 采集来的数据按相同 key 结构喂进去

---

### index_checker.py

- **签名**：顶层 `def run(args)`（第 612 行）；内部主类 `IndexCheckerDiagnoser(data_bundle: Dict)`
- **入参**：`data_bundle` dict，key 包含：`index_cols`（带 rowLoader）、`gpi_check`、`ndv`、`index_collation`、`col_type`、`type_cast`、`type_operator`、`table_column`、`pg_settings`、`statement_history`
- **做什么**：静态元数据诊断（GPI 全局分区索引、NDV 复合索引列顺序、字符集排规则），+ 动态计划诊断（最左匹配、索引跳跃、未使用索引、隐式类型转换、扫描选择率）
- **输出**：`check(args)` 返回 `List[Dict]`（`status/feature/sql_text/query_plan/sql_id/detail`）
- **能离线诊断吗**：**是**。接收 data_bundle dict，不依赖 SSH
- **改造路径**：**不动，直接包装**；部分 model（`index_cols` rowLoader、`ndv`、`index_collation`）需要确认 GaussDB 侧数据是否存在对应视图，需适配采集 SQL

---

### sql_checker.py

- **签名**：顶层 `def run(args)`（第 82 行）；内部主类 `StaticDiagnoser(data_context: Dict)`
- **入参**：`check(sql_record: Dict, args)` 接收单条 statement_history row（dict）
- **做什么**：调用 `util/sql.py` 的 `SQLDiagnosticEngine` 对 SQL 文本做静态正则检查（NOT IN、SELECT * 等反模式），无 SSH
- **输出**：返回 `List[Dict]`（`rule_name/status/result/suggestion`）
- **能离线诊断吗**：**是**
- **改造路径**：**不动**；`SQLDiagnosticEngine` 里的规则与 DB 类型无关（纯 SQL 语法），对 GaussDB 完全适用

---

### sqlplan_checker.py（即 plan_checker / PlanDiagnoser）

- **签名**：顶层 `def run(args)`（第 653 行）；内部主类 `PlanDiagnoser(data_context: Dict)`
- **入参**：`check(sql_record: Dict, args)` 接收单条 statement_history row
- **做什么**：硬解析检测（结合 summary_statement）、死元组 I/O 放大检测（pg_stat_all_tables）、数据倾斜检测（pg_stats）、纯执行计划诊断（util/sqlplan.py）
- **输出**：返回 `List[Dict]`（`rule_name/status/result/detail/suggestion`）
- **能离线诊断吗**：**是**
- **改造路径**：**不动**；GaussDB 的 `dbe_perf.statement_history` 字段与 openGauss 完全相同，执行计划格式一致

---

### wdr_comparison.py

- **签名**：`def main()`（第 3437 行），无 `run(args)` 入口；通过 `argparse` 解析命令行：`--files wdr1.html wdr2.html --output out.html`
- **入参**：argparse.Namespace，含 `--files` 列表（WDR HTML 报告路径）
- **做什么**：解析多个 WDR HTML 报告，按照 JSON 配置（`REPORT_CONFIG_JSON`，内嵌 3000+ 行）将数据融合成对比 HTML；涉及 `bs4` HTML 解析 + 数学公式计算
- **输出**：生成一个 WDR 对比 HTML 文件（写磁盘），无结构化 return
- **能离线诊断吗**：**否**。这是报告展示工具，不是诊断规则
- **改造路径**：**独立保留**，对 GaussDB WDR 报告对比有价值，但不属于"诊断规则"，不需要拷进 skill

---

## Q2 · 12 条 udf 规则真实调用方式

### 函数签名

`udf_funcs.py` 里能找到的规则函数签名（第 27–393 行）：

| 函数名 | 签名 |
|--------|------|
| `check_index_usage` | `(json_data, statement_his_tup)` |
| `check_tab_statistic` | `(json_data, statement_his_tup)` |
| `check_LockMgrLock` | `(json_data, statement_his_tup)` |
| `check_wal_sync` | `(json_data, statement_his_tup)` |
| `check_hard_parse_ratio` | `(json_data, statement_his_tup)` |
| `check_regular_lock_wait` | `(son_data, statement_his_tup)` |
| `check_rw_lock_wait` | `(son_data, statement_his_tup)` |

前 7 个可见，其余（⚠️ 未确认：文件后半部分未读，limit=393 行只覆盖到此处）。

### `statement_his_tup` 是什么

从源码（第 27–49 行）可以确认：
- `statement_his_tup` 是**单条 statement_history 的 dict row**（`row["n_returned_rows"]`、`row["unique_query_id"]` 等字段）
- **不是整个 DN 集合**；调用方在外部循环逐条传入

### 谁在循环调用

⚠️ **未找到调用方**。在整个 `archer-ui/views/` 中，`grep` 没有找到任何 Python 文件调用 `parse_common_dict_data` 或 `import udf_funcs`。`udf_funcs.py` 只做了 `from parse_dict import *`（第 10 行）。

`diagnose_report_v1.py`（第 51 行）调用的是 `health_report.run(args)`，而 `health_report.run` 实际调用的是 `slowsql.SlowSQLDiagnoser` + `memory.MemoryDiagnoser`，**完全不使用 `udf_funcs.py`**。

**结论**：`udf_funcs.py` 是一套历史遗留（旧体系）代码，当前 archer 主流程已切换到 `gs_dsw/funcs/` 新体系（ModelRunner + checker classes），`udf_funcs.py` 已经**不在任何活跃调用链中**。

### 依赖问题

`udf_funcs.py` 第 3 行 `import diagnose` —— 这是一个找不到源文件的 C 扩展或独立模块（在仓库中未找到 `diagnose.py`），`process_cluster_info` 函数调用了它。这个依赖无法直接移植。

---

## Q3 · 15 个 model 的接口

### 架构模式

所有 model 都继承 `BaseModel`（`models/base.py`），通过 `@ModelRunner.register("name")` 装饰器注册。

```
BaseModel
  ├── FILE_NAME = "xxx.txt"           # 离线模式文件名
  ├── collect(args, work_dir) -> str  # 执行 gsql 写文件，返回文件路径
  └── load() -> List[Dict] or Dict    # 读文件解析为结构化数据
```

**不是 ORM-like**，也不是纯 dataclass。是 **采集器 + 解析器** 二合一，职责：
1. `collect()` 负责在线模式执行 `gsql -A -f <sql_file>` 写结果到 txt 文件
2. `load()` 负责读 txt 文件，按 `|` 分割解析成 `List[Dict]` 或特定格式

### 三个典型 model 对比

| Model | SQL 目标视图 | load() 返回格式 |
|-------|-------------|----------------|
| `pg_class_model.py` | `pg_catalog.pg_class` JOIN `pg_namespace` | `Dict[(schema, table), reltuples_float]` |
| `pg_stats_model.py` | `pg_catalog.pg_stats` | `List[Dict]`（字段：schemaname/tablename/attname/most_common_vals/most_common_freqs） |
| `statement_history_model.py` | `dbe_perf.statement_history` | `[{"statement_history": {"rows": List[Dict], "cols": List}}]` （嵌套格式） |

### 与 SQL 模板 / parse_dict 的关系

- `gs_dsw` 的 model **完全不使用** `parse_dict.py`
- `parse_dict.py` 是旧体系（`gs_dignose_report/`）的模块级全局字典
- 新体系（`gs_dsw/`）通过 `ModelRunner.run_combination()` 统一调度，结果存在 `results: Dict[str, Any]`，传给 checker class

### 是 SQL 生成器还是数据解析器

**两者都是**：`collect()` 内嵌 SQL 字符串（SQL 生成器）+ 调用 gsql；`load()` 是数据解析器（给 checker 类使用）。

---

## Q4 · parse_dict ↔ udf_funcs 数据流真相

### parse_dict.py 的作用

`parse_dict.py`（`gs_dignose_report/parse_dict.py`）定义了一批 module-global dict：
- `pg_class_dict`、`pg_stat_all_tables_dict`、`summary_statement_dict`、`gs_asp_sampleid_dict` 等（第 4–21 行）
- `parse_common_dict_data(data)` 接收一个 list-of-dict 数据包，按 `first_key` 分发填充这些全局变量（第 25–53 行）

### 调用链

**完全找不到调用方**。在整个 `archer-ui` 代码库中，`parse_common_dict_data` 没有被任何 Python 文件调用。`udf_funcs.py` `from parse_dict import *` 导入了这些全局变量，但本身也没有调用 `parse_common_dict_data`。

这说明：**`parse_dict` + `udf_funcs` 这一套是独立运行的旧体系**，可能原来由 Go 后端直接调用（传入 JSON 数据 → `parse_common_dict_data` → 调用 udf 函数），但在当前 archer-ui 代码库中这个调用链已被废弃或移到仓库外。

### 新体系数据流（`gs_dsw`）

```
WebArgs(zip_path)
  → health_report.run(args)
    → ModelRunner.run_combination(all_models, offline_zip_path)
      → 解压 zip → 各 model.collect() 或 load()
      → data_bundle: Dict[model_name, data]
    → SlowSQLDiagnoser(data_bundle)
      → InstanceDiagnoser / WaitDiagnoser / PlanDiagnoser / StaticDiagnoser
      → check(sql_record, args) 逐条诊断
    → MemoryDiagnoser(data_bundle)
  → final_report_data: {"memory_diagnose_result": [], "sql_diagnose_result": []}
  → generate_report_v1.report_html(json_str, html_path)
```

---

## Q5 · archer 真正的诊断编排在哪

### `health_report.run(args)`（`gs_dsw/funcs/bak/health_report.py`）

这就是真正的诊断引擎入口（83 行，`diagnose_report_v1.py` 第 51 行调用它）：

```python
def run(args):
    runner = ModelRunner(args, task_uuid=task_uuid)
    # 合并 slowsql.REQUIRED_MODELS + memory.REQUIRED_MODELS
    data_bundle = runner.run_combination(all_models, offline_zip_path=offline_zip)
    # 模块1: 内存诊断
    mem_diag = memory.MemoryDiagnoser(data_bundle)
    mem_diag.execute_diagnosis_flow()
    # 模块2: 慢SQL诊断
    slow_diag = slowsql.SlowSQLDiagnoser(data_bundle)
    slow_diag.execute_diagnosis_flow(args)
    return final_report_data
```

### 形态

**多步骤 pipeline**（不是单 monolithic 函数）：
1. `ModelRunner` 统一采集/解压
2. `MemoryDiagnoser`（`bak/memory_checker.py`）—— 4 条内存规则
3. `SlowSQLDiagnoser`（`bak/slowsql.py`）—— 聚合 4 个子 checker

### SlowSQLDiagnoser 的编排

`bak/slowsql.py` 的 `SlowSQLDiagnoser` 将 4 个 checker 统一调度：

```python
DIAGNOSER_CLASSES = [
    InstanceDiagnoser,    # 缓冲区命中率、SysCache命中率
    WaitDiagnoser,        # 等待事件 (bak/waitevent_checker.py)
    PlanDiagnoser,        # 执行计划诊断 (sqlplan_checker.py)
    StaticDiagnoser       # 静态SQL诊断 (sql_checker.py)
]
```

对每条 statement_history row，逐个调用 `diagnoser.check(sql_record, args)` → 汇总结果。

**IndexCheckerDiagnoser 被注释掉了**（`#IndexDiagnoser`），实际没有接入全量诊断流。

---

## Q6 · 真实诊断规则分布

### `bak/` 目录完整文件清单

```
bak/
  ├── __init__.py
  ├── health_report.py      ← 诊断编排入口
  ├── slowsql.py            ← SlowSQL 聚合调度器
  ├── memory_checker.py     ← 内存诊断（4 条规则）
  ├── memory_model.py       ← 内存数据 model
  ├── waitevent_checker.py  ← 等待事件诊断（4 条规则）
  ├── topn_slowsql.py       ← TopN 慢SQL（⚠️ 未深读）
  ├── index_checker.py      ← ⚠️ 与外层 index_checker.py 不同的版本？
  ├── instance_checker.py   ← 同外层
  ├── gs_asp_model.py       ← gs_asp 采集 model
  ├── gsc_suggest_model.py  ← GSC 建议 model
  ├── index_meta_model.py   ← 索引元数据 model
  ├── invalid_index_model.py← 无效索引 model
  ├── json_builder.py       ← JSON 构建工具
  └── wait_events_model.py  ← 等待事件 model
```

### memory_checker.py 的规则（`bak/`）

4 条诊断规则：
1. `_check_shared_memory_high()`：全局动态内存占比 > 80% 提示
2. `_check_session_thread_ratio()`：Session/Thread 内存占比 > 80% 提示
3. `_check_peak_memory_usage()`：⚠️ 未深读
4. `_check_other_memory_leak()`：⚠️ 未深读

### waitevent_checker.py 的规则（`bak/`）

4 条：常规锁争抢 / 轻量级锁 / 主备同步 WAL sync / WAL flush

### 真正的诊断规则分布总结

| 文件 | 规则条数 | 规则类别 |
|------|---------|--------|
| `bak/memory_checker.py` | 4 | 内存 |
| `bak/waitevent_checker.py` | 4 | 等待事件/锁 |
| `instance_checker.py` | 2 | 缓冲区/SysCache 命中率 |
| `index_checker.py` | 5（静态3+动态5） | 索引质量 |
| `sql_checker.py`（via util/sql.py） | 多条 | 静态SQL反模式 |
| `sqlplan_checker.py` | 4+N | 执行计划质量 |
| `gs_dignose_report/udf_funcs.py` | 7~12 | **旧体系，已废弃** |

---

## Q7 · 整体架构图

```
【在线模式 (online)】
Web Request (Go)
  ↓
diagnose_report_v1.py  (Python adapter)
  ↓  WebArgs(zip_path=None, mode='online')
health_report.run(args)
  ↓
ModelRunner.run_combination()
  ├── [每个 model].collect(args, work_dir)
  │     ↓ gsql -A -h host -p port -U user -W pwd -f sql.sql
  │     → 写 txt 文件到 work_dir/
  └── [每个 model].load()
        → List[Dict] / Dict

【离线模式 (offline)】
Go 后端调用: python3 diagnose_report_v1.py <zip_path> <html_path>
  ↓
health_report.run(WebArgs(zip_path))
  ↓
ModelRunner._prepare_offline_data(zip_path)
  → 解压 zip 到 work_dir/offline_XXXX/
  → 各 model.load() 读解压出的 txt 文件

【离线模式 zip 内容格式】
zip/
  ├── statement_history.txt   (gsql -A 管道符分隔输出)
  ├── pg_class.txt
  ├── pg_stats.txt
  ├── pv_total_memory_detail.txt
  ├── ...（每个 model 一个文件，FILE_NAME 定义）

【诊断流水线】
data_bundle (Dict[model_name, data])
  ↓
SlowSQLDiagnoser
  ├── for each sql_record in statement_history.rows:
  │     ├── InstanceDiagnoser.check(sql_record, args)
  │     ├── WaitDiagnoser.check(sql_record, args)
  │     ├── PlanDiagnoser.check(sql_record, args)
  │     └── StaticDiagnoser.check(sql_record, args)
  └── _format_and_save() → results[]

MemoryDiagnoser.execute_diagnosis_flow()

final_report_data → generate_report_v1.report_html() → HTML 文件

【旧体系（已废弃，不在主流程中）】
gs_dignose_report/parse_dict.py  ← module-global dict
gs_dignose_report/udf_funcs.py   ← 12 条规则（无活跃调用方）
```

---

## Q8 · 最终结论与 plan 修改建议

### a. 6 个 checker 能不能拷进 skill 当诊断规则用？

**部分能**。

| Checker | 结论 | 原因 |
|---------|------|------|
| `cluster_checker.py` | ❌ 否 | SSH 日志采集+关键词检索工具，无诊断规则，无结构化 return |
| `wdr_comparison.py` | ❌ 否 | WDR 报告对比 HTML 工具，无诊断规则 |
| `instance_checker.py` | ✅ 是 | 纯计算，接收 dict，返回 List[Dict] |
| `index_checker.py` | ✅ 是 | 纯计算，接收 dict，返回 List[Dict] |
| `sql_checker.py` | ✅ 是 | 纯正则 SQL 文本检查，无外部依赖 |
| `sqlplan_checker.py` | ✅ 是 | 纯计算，接收 dict，返回 List[Dict] |

### b. 12 条 udf 规则能不能复用？

**否，或需要大量改造**。

- **依赖 `import diagnose`**（C 扩展/外部模块，仓库内找不到源码）
- **依赖 module-global 状态**（`parse_dict.py` 的全局 dict），无法直接函数调用
- **在当前 archer 主流程中已被废弃**，没有活跃调用方
- **规则逻辑价值**：7 条可见规则的逻辑本身（索引使用、统计信息过时、锁等待、WAL sync、硬解析率）已经在新体系 checker 中有更好的实现（`sqlplan_checker.py`、`waitevent_checker.py`）

**如果需要复用这些逻辑**：抽取纯诊断逻辑（阈值判断部分）重写为接受 dict 参数的纯函数，丢弃 `diagnose`、`parse_dict` 依赖。

### c. 15 个 model 能不能复用？

**是**。

所有 model 都是 `BaseModel` 子类，职责清晰（采集 + 解析），可以直接拷贝。注意：

- `collect()` 方法依赖 `gsql` 命令行，在 GaussDB 环境中同样可用
- `statement_history_model.py` 的 SQL 指向 `dbe_perf.statement_history`，GaussDB 与 openGauss 字段完全兼容
- 部分 model 的 SQL 可能需要核对 GaussDB 视图是否存在（如 `gs_gsc_dbstat_info`、`top_wait_events`、`gpi_check`）

### d. 真正诊断逻辑集中在哪些文件？

Plan 原来假设的位置（`cluster_checker.py`、`udf_funcs.py`）**不是**主要诊断规则位置。真正的诊断逻辑在：

```
gs_dsw/funcs/instance_checker.py          ← 2 条：缓冲区/SysCache 命中率
gs_dsw/funcs/index_checker.py             ← 8 条：索引质量（静态+动态）
gs_dsw/funcs/sql_checker.py + util/sql.py ← N 条：SQL 静态反模式
gs_dsw/funcs/sqlplan_checker.py           ← 4 条：执行计划质量
gs_dsw/funcs/bak/waitevent_checker.py     ← 4 条：等待事件
gs_dsw/funcs/bak/memory_checker.py        ← 4 条：内存诊断
```

### e. plan 假设是否成立？修改清单

**Plan 假设部分错误**：
- `cluster_checker.py` 不是诊断规则，是采集工具
- `udf_funcs.py` 不在活跃调用链中，且有不可移植的依赖
- 真正的诊断规则比 plan 估计的更多（`bak/` 目录里还有 memory + waitevent）

| Plan 任务 | 原假设 | 实际 | 修改建议 |
|----------|-------|------|---------|
| spec §6.2 cluster_checker 复用 | 诊断规则，可复用 | SSH 日志采集工具，无诊断规则 | 删除 cluster_checker 复用条目；改为"日志异常关键字模式参考" |
| spec §6.2 udf_funcs 12 条复用 | 核心诊断规则 | 旧体系已废弃，有不可移植依赖 | 删除 udf_funcs 复用；改为"参考 sqlplan/instance checker 新实现" |
| spec §6.2 wdr_comparison 复用 | 诊断规则 | WDR 报告对比 HTML 工具 | 删除该条目或标记为"可选 WDR 展示工具，非诊断规则" |
| M1.diag 数据采集 | 靠 cluster_checker 采集 | 靠 ModelRunner + model 各自 collect() | M1.diag 采集层改为：拷贝 models/ 下需要的 model 文件，按 BaseModel 模式适配 GaussDB 视图 |
| M1.diag 诊断规则 | 拷贝 udf_funcs + cluster_checker | 拷贝 instance/index/sql/sqlplan/waitevent/memory checker | 修改复用清单，见下表 |

**修改后复用清单（拷贝路径表）**

| 组件 | 拷贝来源路径 | 拷贝到 skill 的用途 |
|------|------------|-------------------|
| ModelRunner + BaseModel | `gs_dsw/funcs/models/base.py` | 数据采集框架 |
| StatementHistoryModel | `gs_dsw/funcs/models/statement_history_model.py` | TopSQL 采集 |
| PgClassModel | `gs_dsw/funcs/models/pg_class_model.py` | 表行数查询 |
| PgStatsModel | `gs_dsw/funcs/models/pg_stats_model.py` | 列统计信息 |
| 其他需要的 model | `gs_dsw/funcs/models/*.py` | 按 checker 的 REQUIRED_MODELS 按需拷 |
| InstanceDiagnoser | `gs_dsw/funcs/instance_checker.py` | 缓冲区/SysCache 诊断规则 |
| IndexCheckerDiagnoser | `gs_dsw/funcs/index_checker.py` | 索引质量诊断 |
| StaticDiagnoser | `gs_dsw/funcs/sql_checker.py` | SQL 静态反模式 |
| PlanDiagnoser | `gs_dsw/funcs/sqlplan_checker.py` | 执行计划质量 |
| WaitDiagnoser | `gs_dsw/funcs/bak/waitevent_checker.py` | 等待事件诊断 |
| MemoryDiagnoser | `gs_dsw/funcs/bak/memory_checker.py` | 内存诊断 |
| SlowSQLDiagnoser (编排) | `gs_dsw/funcs/bak/slowsql.py` | 诊断编排 pipeline |
| health_report.run() | `gs_dsw/funcs/bak/health_report.py` | 顶层入口 |
| SQLDiagnosticEngine | `gs_dsw/funcs/util/sql.py` | SQL 正则规则库 |
| SQLPlanDiagnoser | `gs_dsw/funcs/util/sqlplan.py` | 执行计划规则库 |
| ~~cluster_checker~~ | ~~不复用~~ | 日志采集工具，用于参考日志关键字模式 |
| ~~udf_funcs~~ | ~~不复用~~ | 旧体系，依赖不可移植 |
| ~~wdr_comparison~~ | ~~不复用~~ | WDR 展示工具，非诊断规则 |
