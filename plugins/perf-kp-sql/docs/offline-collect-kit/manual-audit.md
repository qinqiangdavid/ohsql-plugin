# Manual 人审清单 + 派生命令 (manual-audit.md)

> 本地工程文件 (跟 collect-precompiled.sh 一样属 offline-collect-kit 目录),build 时由 `_build-precompiled.mjs` 自动生成。
> 跟 collector 部署到 db 服务器后生成的 `outdir/manual.md` 不同:
> - `outdir/manual.md` 给运维当场看 · 只有蒸馏原文
> - `manual-audit.md` 给离线人审 · 多了:**matched_rule**(为什么被切人审) + **derived_commands**(从描述挖出的候选可执行命令)
>
> 派生命令是启发式抓的"看起来能跑"的命令 · **不保证语义正确** · 是人审起点 · 不是 ground truth.

## 总览

- 总 manual 数: **199**
- 有派生命令的: **176** / 199 (88.4%)
- 完全靠人脑解读的: **23**

### 切人审规则分布

| 规则 | 数量 | 含义 |
|---|---:|---|
| `r1-cjk-ge-4` | 152 | 含 ≥4 个汉字 · 描述性中文 · 不是命令 |
| `r6-cjk-placeholder` | 13 | 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值 |
| `r12-not-blind-runnable` | 9 | 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑 |
| `r11-explain-needs-target` | 7 | explain 类 · 需诊断时目标 SQL · 不能盲跑 |
| `r3-distill-leak` | 4 | distill 字段残留 (- **field**: ...) · 不是命令 |
| `r5-single-ident` | 4 | 单 token 视图 / 表名 · 没 SELECT FROM · 不能直跑 |
| `r10-cluster-tool` | 2 | GaussDB 集群工具 (gs_ssh / gs_om / cm_ctl ...) · 需集群拓扑 |
| `r13-placeholder-objname` | 2 | 占位对象名字面量(tablename/table_name 等)· 需填具体表名才能跑 |
| `r8-cjk-verb-start` | 2 | 起始中文动词 (查询 / 查看 / 检测 ...) · 非 ready-to-run |
| `r4-cjk-only` | 2 | 纯中文 metric 名 · ASCII alphanumeric 太少 |
| `r14-hadr-deploy-only` | 1 | 异地容灾(HADR)专用视图 gs_hadr_* · 没配容灾的部署上不存在 · 不盲采 |
| `r9-pid-literal` | 1 | 含真 PID/OID 数字占位 · 需替换实际 PID 才能跑 |

### 派生命令类型分布

| 类型 | 命中条数 |
|---|---:|
| `sql` | 96 |
| `sql-stub` | 55 |
| `view` | 53 |
| `os` | 44 |
| `guc` | 12 |

派生命令 kind 含义:

- `view` — 已知 GaussDB 视图/表 · 派生 `SELECT * FROM view LIMIT 50`
- `guc` — 已知 GUC 参数 · 派生 `SHOW guc_name`
- `os` — 描述里直接出现的 OS 命令 (top -Hp / sar / vmstat / iostat ...)
- `sql-stub` — 描述提到 EXPLAIN / ANALYZE · 派生模板需人填实际 SQL

---

## chk-gaussdb · GaussDB内置火焰图 · 时区加载线程占比
- layer: `flamegraph` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  GaussDB在内核505版本中内置了火焰图工具，默认每5分钟会自动采集一次，保存在$GAUSSLOG/gs_flamegraph/{datanode}路径下，详细信息可参考GaussDB产品文档《内置perf工具》章节。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `ls -la $GAUSSLOG/gs_flamegraph/`  — 按"GaussDB 内置火焰图"派生

## chk-buffer-wdr · buffer命中率 (WDR报告或管控平台)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  可以借助GaussDB的管控平台或者WDR报告。通常情况下，TP数据库的buffer命中率应该在99%以上。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT datname, blks_hit::numeric/NULLIF(blks_hit+blks_read,0) AS hit_ratio FROM pg_stat_database WHERE blks_hit+blks_read > 0 ORDER BY hit_ratio LIMIT 10;`  — 按"buffer 命中率"派生
  - `[sql]` `SELECT generate_wdr_report(<begin_snap_id>, <end_snap_id>, 1, 'all', 'all');`  — 按"WDR 报告生成 (需 snap id)"派生

## chk-explain-analyze-2 · EXPLAIN ANALYZE 算子落盘标志
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  为了优化性能，可以查看SQL的执行计划，如果算子存在落盘的情况，可适当调整work_mem参数值。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW work_mem;`
  - `[sql]` `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`  — 按"算子落盘"派生

## chk-dbe-perf-statement-cpu-time-cpu · dbe_perf.statement.cpu_time (持续CPU高)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  dbe_perf.statement`：可查询分布式本CN发起的历史语句信息。`dbe_perf.summary_statement`：可查询分布式所有CN发起的历史语句信息。（对cpu_time字段进行逆序排序即可识别）
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.statement LIMIT 50;`
  - `[view]` `SELECT * FROM dbe_perf.summary_statement LIMIT 50;`

## chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu · pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查询pg_stat_activity 获取正在运行的SQL的query_id。使用上一步的query_id，查询pg_thread_wait_status 获取正在运行的SQL的lwtid。使用操作系统命令top -Hp <gaussdb进程号>，查看相应lwtid(PID)的CPU使用率。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_stat_activity LIMIT 50;`
  - `[view]` `SELECT * FROM pg_thread_wait_status LIMIT 50;`
  - `[os]` `top -Hp`
  - `[os]` `top -b -n 1 | head -20`  — 按"CPU 使用率"派生
  - `[os]` `top -b -n 1 -p $(pgrep -f gaussdb | head -1) -H`  — 按"gaussdb 进程线程级 top"派生

## chk-statement-history-cpu-time-vs-db-time · statement_history.cpu_time vs db_time
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  登录至各CN/DN节点查询相应时间段的statement_history 表。使用全局接口dbe_perf.get_global_full_sql_by_timestamp('开始时间','结束时间')。注意：需要切换至postgres库。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.get_global_full_sql_by_timestamp LIMIT 50;`
  - `[view]` `SELECT * FROM statement_history LIMIT 50;`

## chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io · dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  如果持续IO高，可查询dbe_perf.statement/dbe_perf.summary_statement内n_blocks_fetched/n_blocks_hit字段，通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.statement LIMIT 50;`
  - `[view]` `SELECT * FROM dbe_perf.summary_statement LIMIT 50;`

## chk-pg-thread-wait-status-wait-status-wait-event-io · pg_thread_wait_status.wait_status / wait_event (当前IO高)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  如果当前IO高，可查询pg_thread_wait_status视图，查询wait_status/wait_event字段，通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_thread_wait_status LIMIT 50;`

## chk-statement-history-data-io-time-sql-io · statement_history.data_io_time (慢SQL IO分析)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查询statement_history表，慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM statement_history LIMIT 50;`
  - `[sql]` `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`  — 按"慢查询"派生
  - `[sql]` `SELECT query_id, n_blocks_fetched, n_blocks_hit, data_io_time FROM statement_history WHERE data_io_time > 0 ORDER BY data_io_time DESC LIMIT 20;`  — 按"SQL 级 IO"派生

## chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam · dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查询dbe_perf.memory_node_detail视图，明确内存占用点。•max_dynamic_memory：最大可使用动态内存 •dynamic_used_memory：已使用动态内存
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.memory_node_detail LIMIT 50;`
  - `[guc]` `SHOW max_dynamic_memory;`
  - `[sql]` `SELECT * FROM dbe_perf.memory_node_detail;`  — 按"内存使用"派生
  - `[sql]` `SHOW max_dynamic_memory; SELECT * FROM dbe_perf.memory_node_detail;`  — 按"动态内存"派生

## chk-dbe-perf-session-memory-detail-dynamic-used-shrctx · dbe_perf.session_memory_detail (dynamic_used_shrctx较小时)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  dynamic_used_shrctx较小，查询dbe_perf.session_memory_detail可获取到不同Session的内存消耗，通常来讲：用户会话数和用户每个session上内存占用都会导致动态内存异常问题。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.session_memory_detail LIMIT 50;`
  - `[sql]` `SELECT * FROM dbe_perf.memory_node_detail;`  — 按"内存使用"派生
  - `[sql]` `SHOW max_dynamic_memory; SELECT * FROM dbe_perf.memory_node_detail;`  — 按"动态内存"派生
  - `[sql]` `SELECT state, count(*) FROM pg_stat_activity GROUP BY state;`  — 按"会话状态分布"派生
  - `[sql]` `SELECT * FROM dbe_perf.session_memory_detail ORDER BY total_size DESC LIMIT 20;`  — 按"session 级内存"派生

## chk-dbe-perf-shared-memory-detail-dynamic-used-shrctx · dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  dynamic_used_shrctx较大，查询dbe_perf.shared_memory_detail可获取到异常内存消耗的context，通常此处有过多的异常消耗，多数情况下为用户session上的内存异常消耗。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.shared_memory_detail LIMIT 50;`
  - `[sql]` `SELECT * FROM dbe_perf.shared_memory_detail ORDER BY total_size DESC LIMIT 20;`  — 按"共享内存"派生

## chk-dbe-perf-local-active-session · dbe_perf.local_active_session (秒级抖动)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  对于短时间秒级性能抖动，分析相应时间点的dbe_perf.local_active_session，可排查点如下：•异常等待事件，当时SQL的异常等待事件，可参考整体性能慢-等待事件分析。•异常SQL，分析某些SQL出现的频率变化，以及执行速度，如多次采样均被采集到，即可反向分析到SQL执行时间。•异常连接数变化，比如业务突然连接增加。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.local_active_session LIMIT 50;`
  - `[sql]` `SELECT count(*) FROM pg_stat_activity; SHOW max_connections;`  — 按"连接数"派生
  - `[sql]` `SELECT * FROM dbe_perf.local_active_session ORDER BY sample_time DESC LIMIT 50;`  — 按"active session"派生
  - `[sql]` `SELECT wait_status, wait_event, count(*) FROM pg_thread_wait_status GROUP BY 1,2 ORDER BY 3 DESC;`  — 按"等待事件聚合"派生

## chk-gs-asp · gs_asp (两天内秒级抖动)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  对于两天内秒级性能抖动，分析相应时间点的gs_asp表
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM gs_asp LIMIT 50;`

## chk-costs · 执行计划costs
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  explain (analyze, verbose, buffers) <目标SQL>;
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-explain-performance · explain performance结果
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  explain performance <目标SQL>;
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-print-redo-wal-count-info-print-redo-wal-time-info · print_redo_wal_count_info/print_redo_wal_time_info
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在备机的gs_log检索“print_redo_wal”关键字
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-redo-unlink-ddl · redo_unlink_ddl
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在gs_log中检索“redo_unlink_ddl”关键字
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-buffer-hit-rate-wait-read-data · buffer_hit_rate / WAIT_READ_DATA
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在gs_log中检索“buffer_hit_rate”、“WAIT_READ_DATA”关键字
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-q-use-q-max-use-rec-cnt · q_use / q_max_use / rec_cnt
- layer: `db-shell` · type: `metric`
- matched_rule: `r10-cluster-tool` · GaussDB 集群工具 (gs_ssh / gs_om / cm_ctl ...) · 需集群拓扑
- 蒸馏原文:
  ```
  cm_ctl query -rv或者select * from local_redo_stat();
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-queue-usage · queue usage
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在日志中搜索queue statistic
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk--3 · 索引页面元组分布
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  使用gs_parse_page_bypath函数解析索引表页面，分析表页面使用情况。
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-last-analyze-time · last_analyze_time
- layer: `db-system-view` · type: `metric`
- matched_rule: `r13-placeholder-objname` · 占位对象名字面量(tablename/table_name 等)· 需填具体表名才能跑
- 蒸馏原文:
  ```
  select * from PG_STAT_ALL_TABLES where relname='tablename';
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-autoanalyze-threshold · autoanalyze_threshold
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r13-placeholder-objname` · 占位对象名字面量(tablename/table_name 等)· 需填具体表名才能跑
- 蒸馏原文:
  ```
  select * from pg_stat_get_tuples_changed('table_name'::REGCLASS); select pg_autovac_status('table_name'::REGCLASS);
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-pg-index-indisusable · pg_index_indisusable
- layer: `db-system-view` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  SELECT indexrelid，indisusable FROM pg_index WHERE indrelid = '<table>'::regclass;
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_index LIMIT 50;`

## chk-cpu-io · CPU、IO、内存使用率
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过htop查看CPU、IO、内存使用情况
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM dbe_perf.memory_node_detail;`  — 按"内存使用"派生

## chk-offcpu · offcpu火焰图
- layer: `flamegraph` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  /usr/share/bcc/tools/offcputime -df -p <pid> 30 > off.stacks && flamegraph.pl off.stacks > offcpu.svg
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `ls -la $GAUSSLOG/gs_flamegraph/`  — 按"GaussDB 内置火焰图"派生
  - `[os]` `perf top -p $(pgrep -f gaussdb | head -1) || gstack $(pgrep -f gaussdb | head -1)`  — 按"perf top / gstack"派生

## chk-n-tuples-fetched-n-tuples-returned · n_tuples_fetched / n_tuples_returned
- layer: `db-system-view` · type: `metric`
- matched_rule: `r8-cjk-verb-start` · 起始中文动词 (查询 / 查看 / 检测 ...) · 非 ready-to-run
- 蒸馏原文:
  ```
  查询dbe_perf.statement_history
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.statement_history LIMIT 50;`
  - `[view]` `SELECT * FROM statement_history LIMIT 50;`

## chk-subtransactions-log · subtransactions log
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  日志中可以尝试搜索关键字Transaction %lu has reached %d subtransactions!
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk--5 · 索引列过滤性
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  select attname, n_distinct, most_common_vals from pg_stats where tablename='<表>';
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk--6 · 活跃会话数
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查看gs_asp视图查看活跃会话数在冲高时间点
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM gs_asp LIMIT 50;`
  - `[sql]` `SELECT count(*) FROM pg_stat_activity WHERE state='active';`  — 按"活跃会话数"派生
  - `[sql]` `SELECT state, count(*) FROM pg_stat_activity GROUP BY state;`  — 按"会话状态分布"派生

## chk-provolatile-proshippable · 函数属性(provolatile/proshippable)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  select proname, provolatile, proshippable from pg_proc where proname='<函数名>';
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_proc LIMIT 50;`

## chk--11 · 备机日志刷盘影响
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  将GUC参数synchronous_commit设置为local进行长稳测试。
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk--14 · 语句执行情况与执行计划
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过gs_asp查看对应时间段的语句执行情况
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM gs_asp LIMIT 50;`

## chk--15 · 代价估算与页面数
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  识别上面的代价估算较低，仅为18，证明pg_class中记录的页面数较少。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_class LIMIT 50;`

## chk-vacuum · vacuum执行记录
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过pg_log,发现在某时刻开始，针对<库名> 中的分区sys_p22进行了vacuum。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $GAUSSLOG/pg_log -name '*.log' -mtime -1 | xargs grep -E '<keyword>'`  — 把 <keyword> 换成实际想抓的字符串
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生

## chk-sql-4 · 慢SQL与计划跳变排查
- layer: `db-system-view` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  select unique_query_id, count(*) from dbe_perf.statement_history where start_time > 'XXX' and start_time < 'XXX' group by 1 order by 2 desc; <br> select unique_query_id, query, query_plan from dbe_perf.statement_history where unique_query_id in (XXX,XXX); <br> select unique_query_id, count(*) from dbe_perf.local_active_session where sample_time > 'XXX' and sample_time < 'XXX' group by 1 order by 2 desc; <br> select unique_sql_id, query from dbe_perf.summary_statement where unique_sql_id in ('XXX', 'XXX');
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM dbe_perf.statement_history LIMIT 50;`
  - `[view]` `SELECT * FROM dbe_perf.local_active_session LIMIT 50;`
  - `[view]` `SELECT * FROM dbe_perf.summary_statement LIMIT 50;`
  - `[view]` `SELECT * FROM statement_history LIMIT 50;`
  - `[sql]` `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`  — 按"慢查询"派生
  - `[sql]` `SELECT * FROM dbe_perf.local_active_session ORDER BY sample_time DESC LIMIT 50;`  — 按"active session"派生

## chk-last-vacuum · last_vacuum
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查看相关表的日志，以及pg_stat_all_tables视图，通过其中的last_vacuum字段
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生

## chk-n-tup-hot-upd-n-tup-upd-n-dead-tup-n-live-tup · n_tup_hot_upd / n_tup_upd / n_dead_tup / n_live_tup
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在pg_stat_all_tables中表现如下
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-rpo · 容灾RPO
- layer: `db-system-view` · type: `metric`
- matched_rule: `r14-hadr-deploy-only` · 异地容灾(HADR)专用视图 gs_hadr_* · 没配容灾的部署上不存在 · 不盲采
- 蒸馏原文:
  ```
  select* from gs_hadr_remote_rto_and_rpo_stat();
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-cpu-4 · 线程CPU占用率
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  top分析线程CPU占用
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-wal · WAL日志产生量
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过计算日志里的LSN节点可知
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT pg_current_wal_lsn(), pg_size_pretty(sum(size)) FROM pg_ls_waldir() GROUP BY ();`  — 按"WAL 日志"派生

## chk-wal-2 · WAL日志类型占比
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  对WAL日志分析可知
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT pg_current_wal_lsn(), pg_size_pretty(sum(size)) FROM pg_ls_waldir() GROUP BY ();`  — 按"WAL 日志"派生

## chk-freeze-page · Freeze Page操作有效性
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  对产生的Freeze Page 类型WAL日志分析
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT pg_current_wal_lsn(), pg_size_pretty(sum(size)) FROM pg_ls_waldir() GROUP BY ();`  — 按"WAL 日志"派生

## chk--22 · 磁盘读写线程
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  识别磁盘读异常SQL(根据异常IO线程号查询pg_stat_activity + pg_thread_wait_status)
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_stat_activity LIMIT 50;`
  - `[view]` `SELECT * FROM pg_thread_wait_status LIMIT 50;`

## chk-gs-log · gs_log日志清理时长
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  检查gs_log日志
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-wal-3 · WAL日志清理模式
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  检查WAL日志
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT pg_current_wal_lsn(), pg_size_pretty(sum(size)) FROM pg_ls_waldir() GROUP BY ();`  — 按"WAL 日志"派生

## chk--24 · 事务日志内容
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  使用gs_xlogdump_xid()系统函数获取被查杀事务对应的日志
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-poll-interrupt · poll_interrupt接口耗时/线程唤醒耗时
- layer: `log-grep / flamegraph` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  从日志中我们发现，CN在调用poll_interrupt接口等待DN回复消息时存在偶现时延增大到4ms的情况。 / 我们抓取了火焰图
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `ls -la $GAUSSLOG/gs_flamegraph/`  — 按"GaussDB 内置火焰图"派生

## chk-rx-dropped-call-stack · rx_dropped call stack
- layer: `os` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  perf record -o perf_lo_drop.data -a -g -e mem:0xffff920fc37b31c8:w
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `perf record`

## chk--26 · 死元组数/表占用空间
- layer: `db-system-view` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  select relname, n_dead_tup, pg_relation_size(relid) sz from pg_stat_all_tables where relname='<表>';
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-toast · toast表空间占用
- layer: `db-system-view` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  select pg_relation_size(reltoastrelid) from pg_class where relname='<表>';
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_class LIMIT 50;`

## chk-palm-hang-detect-main · palm_hang_detect_main等待锁日志
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  gaussdb-<日期>_180856.log.gz:<日期> 某时刻.054 dn_6007_6008_6009 [unkown] [unknown] localhost 281279935201968 0[0:0#0] 0 dn_6007 0 [BACKEND] WARNING: palm_hang_detect_main Cur time is 785847582052464, need_wait_time is 785847577052464, oldest_time is 785847564558141; wait_lock_type(4).
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-lwlock-event-procarraylock · LWLOCK_EVENT ProcArrayLock等待事件
- layer: `db-system-view` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  Wait Events Area: ‘1’ LWLOCK_EVENT ProcArrayLock 11700 (us)
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT wait_status, wait_event, count(*) FROM pg_thread_wait_status GROUP BY 1,2 ORDER BY 3 DESC;`  — 按"等待事件聚合"派生

## chk-unlink-half-dead-page · unlink_half_dead_page索引日志
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  <日期> 某时刻.143 dn_6001_6002_6003 mecs mecs <IP> 281222782959760 375685[11206835某时刻7457#30802] 213523483 cn_5001 73183494132910882 [UBTREE] LOG: [unlink_half_dead_page:1386] IndexRnode:{16某时刻7某时刻227:-1} Xid:{213523483}. valid left sibling for deletion target could not be located: left sibling postmaster pool start, fd nums:4
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-cpu-io-2 · CPU、内存、IO使用率
- layer: `os` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  top -Hp <pid>
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `top -Hp`
  - `[sql]` `SELECT * FROM dbe_perf.memory_node_detail;`  — 按"内存使用"派生

## chk--28 · 轻量级锁排他锁等待时间日志
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  登录客户生产环境进行查询，确实找到了对应的日志打印
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM pg_locks WHERE NOT granted;`  — 按"锁等待"派生

## chk-data-node-scan · 执行计划下推标识（Data Node Scan）
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  将GUC参数enable_fast_query_shipping设置为off，使查询优化器使用分布式框架策略。查看执行计划。如果执行计划中有Data Node Scan节点，那么此执行计划是发送语句的分布式执行计划，为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW enable_fast_query_shipping;`

## chk-pg-proc-provolatile-proshippable · pg_proc.provolatile / proshippable
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE。另外，在pg_proc中的proshippable字段，取值范围为t/f/NULL，这个字段与provolatile字段一起用于描述函数是否下推。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_proc LIMIT 50;`

## chk-explain-verbose-remotequery · explain verbose · RemoteQuery 计划
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  set rewrite_rule='none'; SET explain (verbose on, costs off)  select two_sum(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-explain-verbose-subplan · explain verbose · SubPlan 执行方式
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  set rewrite_rule='none'; SET explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-pg-proc-provolatile · pg_proc.provolatile
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_proc LIMIT 50;`

## chk-explain-verbose-warning · explain verbose WARNING · 统计信息缺失提示
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, ...) are not collected. HINT:Do analyze for them in order to generate optimized plan.
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生
  - `[sql]` `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`  — 按"统计信息缺失检测"派生

## chk-explain-nest-loop-join · EXPLAIN 执行计划 · Nest Loop Join 耗时
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-enable-hashjoin · enable_hashjoin 关闭后执行计划
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  SET enable_hashjoin = off;
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW enable_hashjoin;`

## chk-explain-verbose-warning-2 · EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan.
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生
  - `[sql]` `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`  — 按"统计信息缺失检测"派生

## chk-pg-log-statistics-not-collected · pg_log 日志 · Statistics not collected 日志行
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  可以通过在pg_log目录下的日志文件中查找以下信息来确认当前执行的query是否由于没有收集统计信息导致查询性能变差。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $GAUSSLOG/pg_log -name '*.log' -mtime -1 | xargs grep -E '<keyword>'`  — 把 <keyword> 换成实际想抓的字符串
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生

## chk-explain-verbose-streaming-vs-data-node-scan · EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  set rewrite_rule='none'; SET explain (verbose on, costs off)  select group_concat(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-explain-verbose-subplan-2 · EXPLAIN VERBOSE · SubPlan 算子出现在目标列
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  set rewrite_rule='none'; SET explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-savepoint · 存储过程中 SAVEPOINT 的创建/释放配对
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在使用完SAVEPOINT后，应及时使用RELEASE SAVEPOINT来释放资源。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `grep -E 'SAVEPOINT|RELEASE' $GAUSSLOG/pg_log/*.log | tail -50`  — 按"保存点 (走 pg_log grep)"派生
  - `[os]` `grep -E 'SAVEPOINT|RELEASE|EXCEPTION' $GAUSSLOG/pg_log/*.log | tail -100`  — 按"SAVEPOINT / EXCEPTION 日志"派生

## chk-commit-rollback-i-o · COMMIT/ROLLBACK 频率与 I/O 开销
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  事务的COMMIT和ROLLBACK操作需要同步数据库的元数据和日志，频繁执行可能增加I/O开销，从而影响性能。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT datname, xact_commit, xact_rollback FROM pg_stat_database;`  — 按"COMMIT/ROLLBACK 频率"派生

## chk-b-tree-explain-analyze · 创建 B-tree 索引后再次 EXPLAIN ANALYZE
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  添加索引后，通过与无索引时执行计划的对比，查询时间从原来的382.624ms缩短到0.293 ms。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-explain-verbose-warning-3 · EXPLAIN VERBOSE 执行计划 Warning
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r11-explain-needs-target` · explain 类 · 需诊断时目标 SQL · 不能盲跑
- 蒸馏原文:
  ```
  explain verbose
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-rds001-cpu-util · rds001_cpu_util
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r4-cjk-only` · 纯中文 metric 名 · ASCII alphanumeric 太少
- 蒸馏原文:
  ```
  CPU使用率
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `top -b -n 1 | head -20`  — RDS metric: CPU 使用率

## chk-rds002-mem-util · rds002_mem_util
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  内存使用率
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SHOW max_dynamic_memory; SELECT * FROM dbe_perf.memory_node_detail;`  — RDS metric: 内存使用率 (GUC + 动态内存视图)
  - `[sql]` `SELECT * FROM dbe_perf.memory_node_detail;`  — 按"内存使用"派生

## chk-io-bandwidth-usage · io_bandwidth_usage
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  磁盘io带宽占用率
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `iostat -x 1 1`  — RDS metric: IO 带宽

## chk-iops-usage · iops_usage
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r4-cjk-only` · 纯中文 metric 名 · ASCII alphanumeric 太少
- 蒸馏原文:
  ```
  IOPS使用率
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `iostat -x 1 1`  — RDS metric: IOPS

## chk-rds007-instance-disk-usage · rds007_instance_disk_usage
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  实例数据磁盘已使用百分比
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `df -h $PGDATA $GAUSSDATA 2>/dev/null`  — RDS metric: 实例磁盘使用率

## chk-rds020-avg-disk-ms-per-write · rds020_avg_disk_ms_per_write
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  数据磁盘单次写入花费的时间
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `iostat -x 1 1`  — RDS metric: 平均写延迟

## chk-rds021-avg-disk-ms-per-read · rds021_avg_disk_ms_per_read
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  数据磁盘单次读取花费的时间
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `iostat -x 1 1`  — RDS metric: 平均读延迟

## chk-rds036-deadlocks · rds036_deadlocks
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  死锁次数
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT datname, deadlocks FROM pg_stat_database ORDER BY deadlocks DESC LIMIT 10;`  — RDS metric: 死锁数

## chk-rds048-p80 · rds048_P80
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  80% SQL的响应时间
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT percentile_cont(0.8) WITHIN GROUP (ORDER BY duration) AS p80 FROM statement_history WHERE start_time > now() - interval '5 min';`  — RDS metric: P80 响应时间

## chk-rds049-p95 · rds049_P95
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  95% SQL的响应时间
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY duration) AS p95 FROM statement_history WHERE start_time > now() - interval '5 min';`  — RDS metric: P95 响应时间

## chk-rds060-long-running-transaction-exectime · rds060_long_running_transaction_exectime
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  数据库最长事务的执行时长
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT pid, usename, state, xact_start, query FROM pg_stat_activity WHERE state='active' AND xact_start < now() - interval '5 min' ORDER BY xact_start;`  — RDS metric: 长事务
  - `[sql]` `SELECT pid, usename, state, xact_start, query FROM pg_stat_activity WHERE state='active' AND xact_start < now() - interval '5 min';`  — 按"长事务"派生

## chk-rds063-slowquery-user · rds063_slowquery_user
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  用户库慢SQL数量
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SHOW log_min_duration_statement; SELECT user_name, count(*) FROM statement_history WHERE duration > 1000 GROUP BY user_name ORDER BY count DESC LIMIT 20;`  — RDS metric: 慢查询用户分布
  - `[sql]` `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`  — 按"慢查询"派生

## chk-rds065-dynamic-used-memory-usage · rds065_dynamic_used_memory_usage
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  动态内存使用率
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM dbe_perf.memory_node_detail;`  — RDS metric: 动态已用内存
  - `[sql]` `SHOW max_dynamic_memory; SELECT * FROM dbe_perf.memory_node_detail;`  — 按"动态内存"派生

## chk-rds066-replication-slot-wal-log-size · rds066_replication_slot_wal_log_size
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  复制槽保留的WAL日志大小
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT slot_name, restart_lsn, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS lag FROM pg_replication_slots;`  — RDS metric: 复制槽 WAL 滞后
  - `[sql]` `SELECT * FROM pg_replication_slots;`  — 按"复制槽"派生
  - `[sql]` `SELECT pg_current_wal_lsn(), pg_size_pretty(sum(size)) FROM pg_ls_waldir() GROUP BY ();`  — 按"WAL 日志"派生

## chk-rds070-thread-pool · rds070_thread_pool
- layer: `db-internal-counter` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  线程池使用率
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SHOW enable_thread_pool; SHOW thread_pool_attr;`  — 按"线程池配置"派生

## chk-copy · COPY 导入是否存在约束冲突类容错需求
- layer: `db-shell` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  SET a_format_load_with_constraints_violation = 's2';
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT n_tup_ins, n_tup_upd, n_tup_del, last_vacuum FROM pg_stat_user_tables ORDER BY n_tup_ins DESC LIMIT 20;`  — 按"写入操作分布"派生

## chk-explain-verbose-hashjoin · EXPLAIN VERBOSE hashjoin 行数估算
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r11-explain-needs-target` · explain 类 · 需诊断时目标 SQL · 不能盲跑
- 蒸馏原文:
  ```
  set cost_param=2; explain verbose
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-top-gsql-cpu · top · gsql 进程 CPU 占用
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  top 命令显示 gsql 进程占用率高
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `top -b -n 1 -p $(pgrep -f gaussdb | head -1) -H`  — 按"gaussdb 进程线程级 top"派生

## chk-pg-stat-statements-total-time-calls · pg_stat_statements · total_time + calls (慢查询统计)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r3-distill-leak` · distill 字段残留 (- **field**: ...) · 不是命令
- 蒸馏原文:
  ```
  - **abnormal_patterns**: ["total_time > 1000 AND calls > 10"]
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`  — 按"慢查询"派生

## chk-explain-groupagg-sort · EXPLAIN · 算子(GroupAgg+Sort)
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  计划中包含GroupAgg+Sort算子
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 HashAgg / GroupAgg 算子`  — 按"Agg 算子"派生

## chk-explain-analyze-hashjoin-dn · EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r11-explain-needs-target` · explain 类 · 需诊断时目标 SQL · 不能盲跑
- 蒸馏原文:
  ```
  EXPLAIN ANALYZE
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-memory-information-dn · Memory Information 各 DN 内存消耗分布
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r11-explain-needs-target` · explain 类 · 需诊断时目标 SQL · 不能盲跑
- 蒸馏原文:
  ```
  EXPLAIN ANALYZE` (Memory Information 段)
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-explain-analyze-4 · EXPLAIN ANALYZE 顺序扫描耗时
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r5-single-ident` · 单 token 视图 / 表名 · 没 SELECT FROM · 不能直跑
- 蒸馏原文:
  ```
  EXPLAIN
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-explain-seqscan-vs-indexscan · EXPLAIN · 算子(seqscan vs indexscan)
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在优化前，没有创建places.place_id和states.state_id索引，执行计划如下
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-pidstat-iotop-i-o · pidstat / iotop 显示线程 I/O 消耗
- layer: `os` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  pidstat -dt -p gaussdb进程号
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `pidstat -dt -p $(pgrep -f gaussdb | head -1) 1 1`  — 按"进程 IO (按 PID)"派生
  - `[os]` `top -b -n 1 -p $(pgrep -f gaussdb | head -1) -H`  — 按"gaussdb 进程线程级 top"派生

## chk-pg-thread-wait-status-pg-stat-activity-i-o-sql · pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过查询pg_thread_wait_status视图的lwtid为上一步内的TID，获取对应的tid和sessionid。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_thread_wait_status LIMIT 50;`
  - `[view]` `SELECT * FROM pg_stat_activity LIMIT 50;`  — 从 name 提取视图 pg_stat_activity

## chk-wdr-top-sql-order-by-cpu-time · WDR 报告 Top SQL order by CPU Time
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT generate_wdr_report(<begin_snap_id>, <end_snap_id>, 1, 'all', 'all');`  — 按"WDR 报告生成 (需 snap id)"派生

## chk--35 · 内核代码热点函数火焰图
- layer: `flamegraph` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `ls -la $GAUSSLOG/gs_flamegraph/`  — 按"GaussDB 内置火焰图"派生

## chk-guc-shared-buffers-work-mem-thread-pool-attr · GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  常见的可能情况有：1. shared_buffers配置过小，导致buffer淘汰频繁。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW shared_buffers;`
  - `[guc]` `SHOW work_mem;`  — 从 name 提取 GUC work_mem
  - `[guc]` `SHOW thread_pool_attr;`  — 从 name 提取 GUC thread_pool_attr

## chk-session-package · SESSION 中 PACKAGE 变量数量与内存占用
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  PACKAGE变量是在PACKAGE内定义的全局变量，其生命周期覆盖整个数据库会话（SESSION）。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM dbe_perf.memory_node_detail;`  — 按"内存使用"派生

## chk-pg-proc-volatility · pg_proc 函数 volatility 类型查询
- layer: `db-system-view` · type: `metric`
- matched_rule: `r8-cjk-verb-start` · 起始中文动词 (查询 / 查看 / 检测 ...) · 非 ready-to-run
- 蒸馏原文:
  ```
  查询pg_proc
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_proc LIMIT 50;`

## chk-exception · 存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `grep -E 'SAVEPOINT|RELEASE|EXCEPTION' $GAUSSLOG/pg_log/*.log | tail -100`  — 按"SAVEPOINT / EXCEPTION 日志"派生
  - `[os]` `grep -E 'EXCEPTION|SQLERRM' $GAUSSLOG/pg_log/*.log | tail -50`  — 按"EXCEPTION 块日志"派生

## chk--36 · 存储过程默认权限模式
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  存储过程默认具有SECURITYINVOKER权限。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT proname, prosecdef FROM pg_proc WHERE prosecdef=true LIMIT 50;`  — 按"存储过程权限模式"派生

## chk-explain-remotequery-data-node-scan · EXPLAIN · 是否含 RemoteQuery / Data Node Scan
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r3-distill-leak` · distill 字段残留 (- **field**: ...) · 不是命令
- 蒸馏原文:
  ```
  - **abnormal_patterns**: ["`Data Node Scan on t1 \"_REMOTE_TABLE_QUERY_\"`"]
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-explain-performance-2 · EXPLAIN PERFORMANCE 算子耗时
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r11-explain-needs-target` · explain 类 · 需诊断时目标 SQL · 不能盲跑
- 蒸馏原文:
  ```
  EXPLAIN PERFORMANCE
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看每个算子 A-time 列`  — 按"算子耗时"派生

## chk-group-by-groupagg-sort · GROUP BY 查询计划中是否包含 GroupAgg+Sort
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 HashAgg / GroupAgg 算子`  — 按"Agg 算子"派生

## chk-explain-2 · EXPLAIN · 计划与实际行数比对
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  导致执行计划选择不优
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-explain-data-node-scan-on · EXPLAIN 输出中 "Data Node Scan on" 是否在第一行
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通常而言explain语句后没有显示具体的执行计划算子，执行计划中关键字\"Data Node Scan on\"出现在第一行（不包含计划格式）则说明语句已下推给DN去执行。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-dn-cpu · 备DN CPU使用率 · 回放线程资源
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  极致RTO采用了多个page redo线程并行加速回放进度。当备DN回放追平主DN，空载的情况下，单个page redo线程的CPU消耗大约在15%左右（实际值与具体硬件和参数配置相关），备DN回放的总CPU消耗值 = 单个page redo线程的CPU消耗值 x page redo线程数。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `top -b -n 1 | head -20`  — 按"CPU 使用率"派生

## chk-explain-verbose · EXPLAIN VERBOSE 统计信息警告
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan.
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生

## chk-pg-log · pg_log 统计信息缺失日志
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $GAUSSLOG/pg_log -name '*.log' -mtime -1 | xargs grep -E '<keyword>'`  — 把 <keyword> 换成实际想抓的字符串
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生
  - `[sql]` `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`  — 按"统计信息缺失检测"派生

## chk-explain-analyze-stream · EXPLAIN ANALYZE · Stream算子类型
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  GaussDB计划中常见的主要Stream算子包括Redistribute、Broadcast和Gather。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-explain-analyze-startup-vs-total · EXPLAIN ANALYZE · 路径代价 (Startup vs Total)
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  把explain_perf_mode设置为normal，查看原Nest Loop的启动代价
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-nestloop-2 · 语句执行时间 / 执行计划中 NestLoop 算子
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  该问题发生在实时场景下，语句执行时间因为达到了 3600s而自动终止运行
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 Nested Loop 算子`  — 按"嵌套循环排查"派生

## chk-pgxc-wlm-session-history-block-time-duration · pgxc_wlm_session_history · block_time / duration
- layer: `db-system-view` · type: `metric`
- matched_rule: `r5-single-ident` · 单 token 视图 / 表名 · 没 SELECT FROM · 不能直跑
- 蒸馏原文:
  ```
  pgxc_wlm_session_history
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`

## chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ · GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write
- layer: `db-system-view` · type: `metric`
- matched_rule: `r5-single-ident` · 单 token 视图 / 表名 · 没 SELECT FROM · 不能直跑
- 蒸馏原文:
  ```
  GS_WLM_INSTANCE_HISTORY
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM GS_WLM_INSTANCE_HISTORY LIMIT 50;`
  - `[view]` `SELECT * FROM gs_wlm_instance_history LIMIT 50;`  — 从 name 提取视图 gs_wlm_instance_history

## chk-explain-performance-windowagg-sort · EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r11-explain-needs-target` · explain 类 · 需诊断时目标 SQL · 不能盲跑
- 蒸馏原文:
  ```
  explain performance
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看每个算子 A-time 列`  — 按"算子耗时"派生

## chk-explain-performance-sql-streaming-redistribute · EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜）
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  SQL自诊断信息显示在做row_number()函数计算前的PARTITION BY T.ORDER_LINE_ID引入的重分布算子(Streaming(type: REDISTRIBUTE))有计算倾斜
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM gs_table_skewness LIMIT 50;`  — 按"数据倾斜"派生

## chk-order-line-id-null · 列统计信息 · ORDER_LINE_ID NULL 比例
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生

## chk-pgxc-wlm-session-history-dataskew-warning · pgxc_wlm_session_history · DataSkew warning
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  GaussDB 在执行 SQL 语句时，会对其性能表现进行分析和记录，通过视图和函数等手段呈现给用户。执行完一条代价大于resource_track_cost后，诊断信息会存放在内存hash表中，可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM gs_wlm_session_history LIMIT 50;`
  - `[view]` `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`
  - `[sql]` `SELECT * FROM gs_table_skewness LIMIT 50;`  — 按"数据倾斜"派生

## chk-pgxc-wlm-session-history-large-table-in-broadcast-warning · pgxc_wlm_session_history · Large Table in Broadcast warning
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM gs_wlm_session_history LIMIT 50;`
  - `[view]` `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`

## chk-dn · 各DN磁盘利用率
- layer: `os` · type: `metric`
- matched_rule: `r10-cluster-tool` · GaussDB 集群工具 (gs_ssh / gs_om / cm_ctl ...) · 需集群拓扑
- 蒸馏原文:
  ```
  gs_ssh -c "df -h
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `df -h $PGDATA $GAUSSDATA 2>/dev/null`  — 按"集群命令本机化 (df -h 走本地)"派生

## chk-warning · 执行计划统计信息Warning
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过explain verbose/explain performance打印语句的执行计划
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生

## chk-remote · 执行计划下推标识（__REMOTE关键字）
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过explain verbose打印语句执行计划
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-nestloop-3 · 执行计划算子类型（NestLoop）
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  首先观察SQL语句中有not in 语法；执行计划中有NestLoop
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 Nested Loop 算子`  — 按"嵌套循环排查"派生

## chk-partitioned-cstore-scan · 执行计划：Partitioned CStore Scan分区扫描范围
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  和客户收集几个典型的慢sql，分别打印执行计划。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`  — 按"慢查询"派生
  - `[sql]` `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`  — 按"列存扫描算子"派生

## chk-vecnestloopruntime · 进程堆栈（VecNestLoopRuntime）
- layer: `os` · type: `metric`
- matched_rule: `r9-pid-literal` · 含真 PID/OID 数字占位 · 需替换实际 PID 才能跑
- 蒸馏原文:
  ```
  gstack 14104
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `gstack 14104`
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 Nested Loop 算子`  — 按"嵌套循环排查"派生

## chk-max-process-memory-shared-buffers · 内存参数：max_process_memory, shared_buffers
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  检查内存相关参数，设置不合理
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW shared_buffers;`  — 从 name 提取 GUC shared_buffers
  - `[guc]` `SHOW max_process_memory;`  — 从 name 提取 GUC max_process_memory

## chk-in · 执行计划in条件处理方式
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  打印语句的执行计划
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <含 IN 子句的 SQL>;`  — 按"IN 条件处理"派生

## chk-sql-case-when · SQL 中 CASE WHEN 分支数量与执行次数
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  在业务查询中，CASE WHEN语句常用来进行条件判断，但如果在SQL查询中存在大量冗余的CASE WHEN
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的含 CASE WHEN 的 SQL>;`  — 按"CASE WHEN 执行计划"派生

## chk--40 · 系统表/用户表膨胀情况
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  用户可在管控面执行全库Vacuum/Vacuum Full，以定期进行空间回收
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生

## chk-pgxc-stat-table-dirty · 表脏页率 (PGXC_STAT_TABLE_DIRTY)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  DWS提供了查询脏页率的系统视图，具体使用请参见PGXC_STAT_TABLE_DIRTY。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM PGXC_STAT_TABLE_DIRTY LIMIT 50;`
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生
  - `[view]` `SELECT * FROM pgxc_stat_table_dirty LIMIT 50;`  — 从 name 提取视图 pgxc_stat_table_dirty

## chk-gds · GDS导入作业日志
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  检测GDS导入作业的日志，查看是否有执行失败的现象。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $GAUSSLOG -name 'gds_*.log' -mtime -1 | xargs grep -E 'ERROR|FAIL'`  — 按"GDS 导入日志"派生

## chk-fe-sync-be-parsecomplete · FE=>Sync 与 <=BE ParseComplete 日志时间间隔
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  用户可查看FE=> Syncr日志和<=BE ParseComplete日志之间的时间间隔
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `grep -E 'FE=>|<=BE' $GAUSSLOG/pg_log/*.log | tail -200`  — 按"协议交互日志 (FE/BE)"派生
  - `[os]` `grep -E '<=BE DataRow|FE=>Sync' $GAUSSLOG/pg_log/*.log | tail -100`  — 按"JDBC 协议日志"派生

## chk-be-datarow-select-count · <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查看日志，如果<=BE DataRow日志出现次数过多，或直接执行SELECT count(*);
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `grep -E '<=BE DataRow|FE=>Sync' $GAUSSLOG/pg_log/*.log | tail -100`  — 按"JDBC 协议日志"派生
  - `[sql]` `SELECT query_id, n_tuples_returned FROM statement_history ORDER BY n_tuples_returned DESC NULLS LAST LIMIT 20;`  — 按"返回行数"派生

## chk-modifyjdbccall-createparameterizedquery · modifyJdbcCall / createParameterizedQuery 阶段耗时
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $GAUSSLOG -name 'pg_log' -type d | head -1 | xargs -I{} grep -E 'modifyJdbc|createParameterized' {}/*.log 2>/dev/null | tail -50`  — 按"JDBC 阶段耗时"派生

## chk-analyze-2 · ANALYZE 后的查询性能
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  使用ANALYZE命令分析数据库。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `ANALYZE <schema.table>;  -- 或 ANALYZE; 收集全库统计`  — 按"ANALYZE 命令"派生

## chk--41 · 查询返回行数
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  检查查询语句是否返回了多余的数据信息。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT query_id, n_tuples_returned FROM statement_history ORDER BY n_tuples_returned DESC NULLS LAST LIMIT 20;`  — 按"返回行数"派生

## chk--42 · 主机负载下查询单独运行时延
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  尝试在数据库没有其他查询或查询较少的时候运行查询语句，并观察运行效率。
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk--43 · 重复执行同一查询语句的执行时间
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  重复执行相同的查询语句，如果后续执行的查询语句效率提升，则可能是由于上述原因导致。
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-disk-cache-pgxc-disk-cache-all-stats · Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats)
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过查询视图pgxc_disk_cache_all_stats可以查看当前缓存的命中率以及各个DN磁盘的使用大小情况
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pgxc_disk_cache_all_stats LIMIT 50;`

## chk-evs · EVS 磁盘空间占用百分比
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  日志中会出现\"Disk usage on the node %u has reached the read-only threshold 90%\
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `df -h $PGDATA $GAUSSDATA 2>/dev/null`  — 按"磁盘"派生

## chk-bucket · 入库分区数 / Bucket 数 / 攒批内存消耗
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  单并发攒批消耗： #Np * #Nb * #Nr 单并发攒批内存消耗： partition_max_cache_size， 默认2GB
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 20;`  — 按"分区/bucket"派生

## chk-explain-indexscan · EXPLAIN 执行计划 · 是否选择IndexScan
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  对表执行ANALYZE更新统计信息。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `ANALYZE <schema.table>;`  — 把 <schema.table> 换成实际表名
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生

## chk-waiting-in-queue · 查询等待状态 · waiting in queue
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  普通用户主要在waiting in queue/waiting in global queue时。当前的活跃语句数超过max_active_statements限制导致的普通用户排队，由于管理员用户不受管控所以无需排队。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM pg_stat_activity WHERE state='active' AND waiting=true;`  — 按"查询等待 queue"派生

## chk-explain-or-filter · EXPLAIN 执行计划 · 系统视图权限OR filter
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过执行计划可以看到系统视图中的权限判断中多用or条件判断：pg_has_role(c.relowner, 'USAGE'::text) OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text)
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-cn-2 · CN日志中不下推原因
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  不下推语句在pg_log中会打印不下推的原因。LOG: SQL can't be shipped, reason: ...
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $GAUSSLOG/pg_log -name '*.log' -mtime -1 | xargs grep -E '<keyword>'`  — 把 <keyword> 换成实际想抓的字符串

## chk-explain-verbose-warning-4 · EXPLAIN VERBOSE WARNING信息 · 统计信息缺失
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过EXPLAIN VERBOSE执行query分析执行计划时会提示WARNING信息
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL
  - `[sql]` `ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表`  — 按"收集统计信息"派生
  - `[sql]` `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`  — 按"统计信息缺失检测"派生

## chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has · pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史）
- layer: `db-system-view` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  SELECT start_time, block_time, duration, sql_hash, warning, max_peak_memory, max_spill_size, query_plan FROM pgxc_wlm_session_info were start_time > 'xxxx-xx-xx xx:xx' and sql_hash = 'xxx' ORDER BY start_time desc limit 10;
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pgxc_wlm_session_info LIMIT 50;`
  - `[sql]` `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`  — 按"算子落盘"派生

## chk-resource-track-level-operator-realtime · resource_track_level · operator_realtime 级别实时算子监控
- layer: `db-system-view` · type: `metric`
- matched_rule: `r12-not-blind-runnable` · 起始非无参只读命令(explain/set-only/copy/perf/日志片段等) · 不能盲跑
- 蒸馏原文:
  ```
  SET resource_track_level = 'operator_realtime';
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-pgxc-stat-activity-state-waiting-enqueue · PGXC_STAT_ACTIVITY · state / waiting / enqueue
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  SELECT coorname, usename,client_addr,application_name,state,waiting,enqueue,pid FROM PGXC_STAT_ACTIVITY WHERE DATNAME='数据库名称';
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM PGXC_STAT_ACTIVITY LIMIT 50;`
  - `[view]` `SELECT * FROM pgxc_stat_activity LIMIT 50;`  — 从 name 提取视图 pgxc_stat_activity

## chk-pg-locks · pg_locks · 阻塞会话与持锁会话关联
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  - **abnormal_patterns**: ["`该查询返回会话ID、CN名称、用户信息、查询状态，以及导致阻塞的表、模式信息。`"]
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_locks LIMIT 50;`  — 从 name 提取视图 pg_locks

## chk-dws-connector-connectiontimeout · DWS-Connector connectionTimeOut 默认值
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  DWS-Connector默认超时时间connectionTimeOut为5min，可调大该值。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SHOW connect_timeout; SELECT setting FROM pg_settings WHERE name LIKE '%timeout%';`  — 按"连接超时"派生

## chk-pg-stat-activity-pg-locks-sql-8-0-x · pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本）
- layer: `db-system-view` · type: `metric`
- matched_rule: `r3-distill-leak` · distill 字段残留 (- **field**: ...) · 不是命令
- 蒸馏原文:
  ```
  - **abnormal_patterns**: ["NULL"]
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pg_stat_activity LIMIT 50;`  — 从 name 提取视图 pg_stat_activity
  - `[view]` `SELECT * FROM pg_locks LIMIT 50;`  — 从 name 提取视图 pg_locks

## chk--44 · 写入方式
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT n_tup_ins, n_tup_upd, n_tup_del, last_vacuum FROM pg_stat_user_tables ORDER BY n_tup_ins DESC LIMIT 20;`  — 按"写入操作分布"派生

## chk--45 · 各节点磁盘使用率均衡性
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  登录DWS控制台。在"集群列表"页面，找到需要查看监控的集群。在指定集群所在行的"操作"列，单击"监控面板"。选择"监控 > 节点监控 > 磁盘"，查看磁盘使用率。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `df -h $PGDATA $GAUSSDATA 2>/dev/null`  — 按"磁盘"派生

## chk-explain-verbose-remote · EXPLAIN VERBOSE · __REMOTE 关键字
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过EXPLAIN VERBOSE打印语句执行计划。上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-cn-3 · CN日志 · 不下推原因
- layer: `log-grep` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  不下推语句在pg_log中会打印不下推的原因，上述语句在CN的日志中会找到类似以下的日志。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $GAUSSLOG/pg_log -name '*.log' -mtime -1 | xargs grep -E '<keyword>'`  — 把 <keyword> 换成实际想抓的字符串

## chk-nestloop-4 · 执行计划算子类型（NestLoop出现）
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过EXPLAIN VERBOSE打印语句执行计划，查看执行计划发现SQL语句中存在not in语句
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 Nested Loop 算子`  — 按"嵌套循环排查"派生

## chk-explain-partitioned-cstore-scan-selected-partitions · EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  收集几个典型的慢SQL语句，分别打印执行计划。从执行计划中可以看出来，两条SQL的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分区扫描上。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`  — 按"慢查询"派生
  - `[sql]` `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`  — 按"列存扫描算子"派生

## chk-i-o-cpu · 系统资源 I/O / 内存 / CPU 使用情况
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  排查当前的I/O、内存、CPU使用情况，没有发现资源占用高的情况。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `echo '=== top ===' && top -b -n 1 | head -20 && echo '=== iostat ===' && iostat -x 1 1 && echo '=== free ===' && free -h`  — 按"I/O + 内存 + CPU 一把抓"派生

## chk-gstack-vecnestloopruntime · gstack · 进程堆栈中 VecNestLoopRuntime
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  联系运维人员登录到相应的实例节点上，打印等待状态为none的线程堆栈信息
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 Nested Loop 算子`  — 按"嵌套循环排查"派生

## chk-cstore-scan · 执行计划算子：CStore Scan耗时占比
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过抓取问题SQL的执行信息，发现大部分的耗时都在\"CStore Scan\
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`  — 按"列存扫描算子"派生

## chk-cudesc-cu-row-count · cudesc表中CU的row_count分布
- layer: `db-system-view` · type: `metric`
- matched_rule: `r3-distill-leak` · distill 字段残留 (- **field**: ...) · 不是命令
- 蒸馏原文:
  ```
  - **abnormal_patterns**: ["row_count << 60000"]
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM pg_class WHERE relname LIKE 'cudesc_%' LIMIT 20;`  — 按"CU 描述表"派生

## chk-cu · 执行计划中CU扫描数量
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查看偶发慢业务慢时的执行计划信息，慢在cstore scan，且扫描数据量不大但扫描CU个数较多
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`  — 按"列存扫描算子"派生
  - `[sql]` `SELECT * FROM pg_class WHERE relname LIKE 'cudesc_%' LIMIT 20;`  — 按"CU 描述表"派生

## chk-explain-cstore-scan-cusome-cunone · EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  分析计划主要耗时在Cstore Scan。Cstore Scan的详细信息中，每个DN扫描出2w左右的数据，但是扫描了有数据的CU（CUSome）155079个，没有数据的CU（CUNone）156375个
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`  — 按"列存扫描算子"派生

## chk-explain-scan-vs · EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  某业务SQL总执行时间2.519s，其中Scan占了2.516s，同时该表的扫描最终只扫描到0条符合条件数据，过滤了20480条数据
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk--47 · 表脏页率
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  查看表脏页率为99%，VACUUM FULL后性能优化到100ms左右。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生

## chk-explain-scan-a-time-max-min-dn · EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  表Scan的A-time中，max time DN执行耗时6554ms，min time DN耗时0s，DN之间扫描差异超过10倍以上
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;  -- 看每个算子 A-time 列`  — 按"算子耗时"派生

## chk-table-distribution-dn-2 · table_distribution 各DN数据行数
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过table_distribution发现所有数据倾斜到了dn_6009单个DN
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM table_distribution LIMIT 50;`
  - `[sql]` `SELECT * FROM table_distribution('<schema>', '<table>');  -- 替换 schema/table`  — 按"表分布"派生
  - `[sql]` `SELECT * FROM gs_table_skewness LIMIT 50;`  — 按"数据倾斜"派生

## chk-explain-seq-scan-vs-index-scan · EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan）
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  Seq Scan扫描需要3767ms，因涉及从4096000条数据中获取8240条数据，符合索引扫描的场景（海量数据中寻找少量数据），在对过滤条件列增加索引后，计划依然是Seq Scan而没有走Index Scan。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-explain-selected-partitions · EXPLAIN 执行计划 · Selected Partitions 数量
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  对该表设计为分区表后没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms，I/O效率极低。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-pv-total-memory-detail-process-used-memory-vs-max-process-me · pv_total_memory_detail · process_used_memory vs max_process_memory
- layer: `db-system-view` · type: `metric`
- matched_rule: `r5-single-ident` · 单 token 视图 / 表名 · 没 SELECT FROM · 不能直跑
- 蒸馏原文:
  ```
  pv_total_memory_detail
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW max_process_memory;`  — 从 name 提取 GUC max_process_memory

## chk--48 · 列存表文件大小监控
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  列存表数据按列存储，一列的每60000行存储为一个CU，同一列的CU连续存储在一个文件中，当该文件大于1GB时，切换到新文件中。CU文件数据不能更改只能追加写。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $PGDATA -name 'cu_*' -size +100M 2>/dev/null | head -20`  — 按"列存文件大小"派生

## chk-pgxc-get-table-skewness-3 · PGXC_GET_TABLE_SKEWNESS 视图
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  分布差可以通过视图[PGXC_GET_TABLE_SKEWNESS]查看。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM gs_table_skewness LIMIT 50;`  — 按"数据倾斜"派生
  - `[view]` `SELECT * FROM pgxc_get_table_skewness LIMIT 50;`  — 从 name 提取视图 pgxc_get_table_skewness

## chk-dms · DMS 监控 · 节点磁盘使用率
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `df -h $PGDATA $GAUSSDATA 2>/dev/null`  — 按"磁盘"派生

## chk-explain-verbose-hashjoin-2 · EXPLAIN VERBOSE · HashJoin 行数估算偏差
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r11-explain-needs-target` · explain 类 · 需诊断时目标 SQL · 不能盲跑
- 蒸馏原文:
  ```
  set cost_param=2; explain verbose select nation, sum(amount) as sum_profit from (...) as profit group by nation order by nation
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN VERBOSE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-cpu-1-3-12-24 · 节点 CPU 使用率 (1/3/12/24 小时)
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  选择“监控 > 节点监控 > 概览”可查看当前集群各节点CPU使用率的具体情况，单击最右的监控按钮，查看最近1/3/12/24小时的CPU性能指标
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `top -b -n 1 | head -20`  — 按"CPU 使用率"派生

## chk-cpu-6 · 资源池 CPU 限额 / 配额配置
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  设置资源池CPU限额与配额。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM pg_settings WHERE name LIKE 'cgroup%' OR name LIKE 'workload%';`  — 按"资源池配置"派生

## chk-explain-4 · EXPLAIN · 执行计划顺序扫描阶段耗时
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  EXPLAIN` 查看多表 JOIN 执行计划
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-base-pgsql-tmp-pgsql-tmp-queryid-pid · base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件
- layer: `os` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  下盘文件位于实例目录的base/pgsql_tmp路径下，下盘文件以 pgsql_tmp$queryid_$pid 命名
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[os]` `find $PGDATA -name 'pgsql_tmp*' -mmin -60 -ls 2>/dev/null | head -20`  — 按"临时文件"派生

## chk-pgxc-thread-wait-status-wait-status-write-file · pgxc_thread_wait_status · wait_status='write file'
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  等待视图中，当出现write file时，表示发生了中间结果下盘
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[view]` `SELECT * FROM pgxc_thread_wait_status LIMIT 50;`  — 从 name 提取视图 pgxc_thread_wait_status

## chk-explain-performance-spill-written-disk-temp-file-num · EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`  — 按"算子落盘"派生
  - `[os]` `find $PGDATA -name 'pgsql_tmp*' -mmin -60 -ls 2>/dev/null | head -20`  — 按"临时文件"派生

## chk-topsql-spill-info · TopSQL.spill_info
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  实时TopSQL语句或历史TopSQL语句中，spill_info字段中会包含下盘信息，如果该字段不为空，说明有DN实例出现了下盘。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`  — 按"算子落盘"派生

## chk-explain-analyze-join-2 · EXPLAIN ANALYZE · JOIN 算子类型及执行时间
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  EXPLAIN ANALYZE` 查看两表 JOIN 的算子类型
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-explain-analyze-agg-2 · EXPLAIN ANALYZE · Agg 算子类型及执行时间
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  EXPLAIN ANALYZE` 查看聚合操作算子选择
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN ANALYZE <你的 SQL>;`  — 把 <你的 SQL> 换成实际慢 SQL

## chk-explain-performance-vs-a-rows-vs-e-rows · EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows）
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  EXPLAIN PERFORMANCE` 查看 TPC-DS Q24 部分语句执行计划
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-explain-data-node-scan · EXPLAIN · 是否含 Data Node Scan 节点
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  如果执行计划中有Data Node Scan节点，那么此执行计划为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-explain-performance-5 · EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  EXPLAIN PERFORMANCE` 查看是否有 Vector 前缀算子
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 把 <你的 SQL> 换成实际 SQL

## chk-copy-2 · COPY 语句等待视图 · 轻量级锁等待
- layer: `db-system-view` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  根据这5个COPY语句对应的query_id查看等待视图情况
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM pg_locks WHERE NOT granted;`  — 按"锁等待"派生
  - `[sql]` `SELECT n_tup_ins, n_tup_upd, n_tup_del, last_vacuum FROM pg_stat_user_tables ORDER BY n_tup_ins DESC LIMIT 20;`  — 按"写入操作分布"派生

## chk-explain-performance-cpu-io · EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络)
- layer: `db-interactive-cmd` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  通过执行态信息，我们可以分析出算子为单位的性能，也可以分析出算子内部各步骤的性能，进一步为诊断性能的瓶颈打下了基础。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql-stub]` `EXPLAIN <你的 SQL>;`  — 从 name 提取 · 需填实际 SQL

## chk-vacuum-defer-cleanup-age · vacuum_defer_cleanup_age 参数值
- layer: `db-shell` · type: `metric`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  参数vacuum_defer_cleanup_age不是0，该参数在老版本默认为8000，表示最近8000个事务产生的脏数据不进行回收。
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生

## chk-dn-warning · DN 间导入行数倾斜率(WARNING)
- layer: `log-grep` · type: `metric`
- matched_rule: `r6-cjk-placeholder` · 含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值
- 蒸馏原文:
  ```
  WARNING:  Skewness occurs, table name: xxx, min value: xxx, max value: xxx, sum value: xxx, avg value: xxx, skew ratio: xxx
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[sql]` `SELECT * FROM gs_table_skewness LIMIT 50;`  — 按"数据倾斜"派生

## chk-ubtree · ubtree页面分裂策略
- layer: `gaussdb-guc-param` · type: `parameter-current-value`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  gsql -d postgres -c "SHOW ubtree页面分裂策略;"
  ```
- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**

## chk-autovacuum · autovacuum相关参数
- layer: `gaussdb-guc-param` · type: `parameter-current-value`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  gsql -d postgres -c "SHOW autovacuum相关参数;"
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW autovacuum;`
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生

## chk-autovacuum-ustore · autovacuum (ustore表的自动清理)
- layer: `gaussdb-guc-param` · type: `parameter-current-value`
- matched_rule: `r1-cjk-ge-4` · 含 ≥4 个汉字 · 描述性中文 · 不是命令
- 蒸馏原文:
  ```
  gsql -d postgres -c "SHOW autovacuum (ustore表的自动清理);"
  ```
- 派生命令 (启发式 · 仅作参考起点):
  - `[guc]` `SHOW autovacuum;`
  - `[sql]` `VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名`  — 按"VACUUM (谨慎: 影响业务)"派生

