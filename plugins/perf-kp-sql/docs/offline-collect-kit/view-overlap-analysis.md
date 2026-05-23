# 视图查询重叠分析 (view-overlap-analysis.md)

> 本地工程文件 · 由 `_analyze-view-overlap.mjs` 扫 `collect-precompiled.sh` (auto inline) +
> `manual-audit.md` (manual 派生) 出。
>
> **目的**: 找出"查同一视图 N 次"的 hot view,验证"在环境查一次,本地过滤/聚合"
> 这条优化路径的收益。**完整版 (precompiled / manual-audit) 不动**,这只是只读分析。

## 总览

- 命中的可信视图 (`pg_*` / `pgxc_*` / `gs_*` / `dbe_perf.*` / 已知 GaussDB 表): **42** 个
- 合并前总查询次数 (auto + manual 派生): **134** 次
- 合并后理论查询次数 (每视图 1 次): **42** 次
- 可省 round-trip: **92** 次 (68.7%)

### Hot view (≥ 3 次命中) — 强合并候选

| 视图 | 总次数 | auto 内 | manual 派生 | 合并方案 |
|---|---:|---:|---:|---|
| `pg_stat_user_tables` | 12 | 0 | 12 | 拉 `SELECT * FROM pg_stat_user_tables` 一次 · 本地起 12 个 filter/agg |
| `pg_stat_activity` | 10 | 3 | 7 | 拉 `SELECT * FROM pg_stat_activity` 一次 · 本地起 10 个 filter/agg |
| `statement_history` | 10 | 0 | 10 | 拉 `SELECT * FROM statement_history` 一次 · 本地起 10 个 filter/agg |
| `gs_wlm_session_history` | 9 | 1 | 8 | 拉 `SELECT * FROM gs_wlm_session_history` 一次 · 本地起 9 个 filter/agg |
| `pg_class` | 8 | 2 | 6 | 拉 `SELECT * FROM pg_class` 一次 · 本地起 8 个 filter/agg |
| `pgxc_stat_activity` | 7 | 6 | 1 | 拉 `SELECT * FROM pgxc_stat_activity` 一次 · 本地起 7 个 filter/agg |
| `pgxc_wlm_session_history` | 7 | 0 | 7 | 拉 `SELECT * FROM pgxc_wlm_session_history` 一次 · 本地起 7 个 filter/agg |
| `gs_table_skewness` | 6 | 0 | 6 | 拉 `SELECT * FROM gs_table_skewness` 一次 · 本地起 6 个 filter/agg |
| `pg_thread_wait_status` | 6 | 2 | 4 | 拉 `SELECT * FROM pg_thread_wait_status` 一次 · 本地起 6 个 filter/agg |
| `pgxc_thread_wait_status` | 6 | 5 | 1 | 拉 `SELECT * FROM pgxc_thread_wait_status` 一次 · 本地起 6 个 filter/agg |
| `dbe_perf.memory_node_detail` | 5 | 0 | 5 | 拉 `SELECT * FROM dbe_perf.memory_node_detail` 一次 · 本地起 5 个 filter/agg |
| `pg_proc` | 4 | 0 | 4 | 拉 `SELECT * FROM pg_proc` 一次 · 本地起 4 个 filter/agg |
| `dbe_perf.statement` | 3 | 1 | 2 | 拉 `SELECT * FROM dbe_perf.statement` 一次 · 本地起 3 个 filter/agg |
| `pg_locks` | 3 | 0 | 3 | 拉 `SELECT * FROM pg_locks` 一次 · 本地起 3 个 filter/agg |
| `pg_stat_database` | 3 | 0 | 3 | 拉 `SELECT * FROM pg_stat_database` 一次 · 本地起 3 个 filter/agg |
| `pgxc_get_table_skewness` | 3 | 2 | 1 | 拉 `SELECT * FROM pgxc_get_table_skewness` 一次 · 本地起 3 个 filter/agg |
| `pgxc_wlm_session_info` | 3 | 2 | 1 | 拉 `SELECT * FROM pgxc_wlm_session_info` 一次 · 本地起 3 个 filter/agg |

### Cold view (< 3 次) — 合并收益低,留作单查

| 视图 | 总次数 | auto / manual |
|---|---:|---|
| `dbe_perf.summary_statement` | 2 | 0 / 2 |
| `pg_settings` | 2 | 0 / 2 |
| `pgxc_lock_conflicts` | 2 | 2 / 0 |
| `table_distribution` | 2 | 1 / 1 |
| `dbe_perf.get_global_full_sql_by_timestamp` | 1 | 0 / 1 |
| `dbe_perf.local_active_session` | 1 | 0 / 1 |
| `dbe_perf.session_memory_detail` | 1 | 0 / 1 |
| `dbe_perf.shared_memory_detail` | 1 | 0 / 1 |
| `gs_asp` | 1 | 0 / 1 |
| `gs_wlm_instance_history` | 1 | 0 / 1 |
| `gs_wlm_session_statistics` | 1 | 1 / 0 |
| `pg_get_tabledef` | 1 | 1 / 0 |
| `pg_ls_waldir` | 1 | 0 / 1 |
| `pg_namespace` | 1 | 1 / 0 |
| `pg_partition` | 1 | 1 / 0 |
| `pg_replication_slots` | 1 | 0 / 1 |
| `pg_session_wlmstat` | 1 | 1 / 0 |
| `pgxc_class` | 1 | 1 / 0 |
| `pgxc_disk_cache_all_stats` | 1 | 0 / 1 |
| `pgxc_get_stat_all_tables` | 1 | 1 / 0 |
| `pgxc_gtm_snapshot_status` | 1 | 1 / 0 |
| `pgxc_running_xacts` | 1 | 1 / 0 |
| `pgxc_stat_table_dirty` | 1 | 0 / 1 |
| `pgxc_total_memory_detail` | 1 | 1 / 0 |
| `pgxc_wlm_session_statistics` | 1 | 1 / 0 |

---

## 合并方案设计 (建议)

新增 collector 模式 `collect-merged.{sh,py}`,跟现有 `collect-precompiled.` 并列:

```
                                          ┌── auto 180 条 (不变 · 多数已是单次)
collect-precompiled.{sh,py} (完整版) ──────┤
                                          └── manual 153 → 派生 224 (跨视图重叠多)
                                                      ↓
                                       提取 hot view 17 个
                                                      ↓
collect-merged.{sh,py} (优化版) ─── 1. 服务器端: SELECT * FROM <hot view> 跑 17 次,落 raw/
                                  2. 本地: post-process.{mjs,py} 读 raw/,
                                           按 check_id 的 filter/agg 派生
                                           出 105 个 check 的结果
```

### 收益 vs 成本

| 维度 | 完整版 (当前) | 合并版 |
|---|---|---|
| 服务器端 gsql 调用 | 134+180 ≈ 314 次 | 17 (hot SELECT *) + 180 (auto) + 29 (cold 派生) = 226 次 |
| 拉回数据量 | 每次窄查 · 小 | 每 hot 视图全表 · 大 (但每个视图只 1 份) |
| 现场延迟 | gsql 启动 ×N | gsql 启动 ×226 |
| 本地处理 | 无 (现场出结果) | 需 post-process 脚本读 raw/ + 派生 check 结果 |
| 数据一致性 | 跨视图非快照一致 | hot 视图内一致 (一次 SELECT *) · 跨视图仍非快照 |

**适用场景**:

1. **现场 round-trip 慢** (跨网延迟 / gsql 启动重) → 合并版省启动
2. **想要多个 check 在同一时刻数据快照** (例如 `pg_stat_activity` 多 check 应基于同一秒) → 合并版强一致
3. **数据回传到本地做 ad-hoc 二次分析** → 合并版的 raw/ 比派生结果更原始,二次分析友好

**不适用**:

1. 视图量大 (`statement_history` 单次 SELECT * 可能 GB 级) → 仍需 LIMIT / WHERE
2. 客户内网 SCP 慢 → 拉小派生结果 < 拉全表 raw

---

## Hot view 详细命中清单

下面对每个 hot view 列出所有命中的 check_id + 各自怎么用 (snippet),便于设计 post-process 派生逻辑.

### `pg_stat_user_tables` · 12 次

**manual 派生 (12)**:

- `chk-explain-verbose-warning` · EXPLAIN VERBOSE WARNING信息 · 统计信息缺失
  - [sql] `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`
- `chk-explain-verbose-warning` · EXPLAIN VERBOSE WARNING信息 · 统计信息缺失
  - [sql] `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`
- `chk-pg-log` · pg_log 统计信息缺失日志
  - [sql] `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`
- `chk-partitioned-cstore-scan` · 执行计划：Partitioned CStore Scan分区扫描范围
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-bucket` · 入库分区数 / Bucket 数 / 攒批内存消耗
  - [sql] `SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 20;`
- `chk-explain-verbose-warning` · EXPLAIN VERBOSE WARNING信息 · 统计信息缺失
  - [sql] `SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;`
- `chk-null-012` · 写入方式
  - [sql] `SELECT n_tup_ins, n_tup_upd, n_tup_del, last_vacuum FROM pg_stat_user_tables ORDER BY n_tup_ins DESC LIMIT 20;`
- `chk-explain-partitioned-cstore-scan-selected-partitions` · EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-cstore-scan` · 执行计划算子：CStore Scan耗时占比
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-cu` · 执行计划中CU扫描数量
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-explain-cstore-scan-cusome-cunone` · EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-copy` · COPY 语句等待视图 · 轻量级锁等待
  - [sql] `SELECT n_tup_ins, n_tup_upd, n_tup_del, last_vacuum FROM pg_stat_user_tables ORDER BY n_tup_ins DESC LIMIT 20;`

---

### `pg_stat_activity` · 10 次

**auto inline (3)**:

- `chk-sql-create-index` · 活跃SQL及CREATE INDEX语句
  - snippet: `select * from pg_stat_activity where state !='idle' and usename !='omm';`
- `chk-pg-stat-activity-sql` · pg_stat_activity 活跃SQL
  - snippet: `SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';`
- `chk-pg-stat-activity-idle` · pg_stat_activity · idle 连接数
  - snippet: `SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';`

**manual 派生 (7)**:

- `chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu` · pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高)
  - [view] `SELECT * FROM pg_stat_activity LIMIT 50;`
- `chk-dbe-perf-session-memory-detail-dynamic-used-shrctx` · dbe_perf.session_memory_detail (dynamic_used_shrctx较小时)
  - [sql] `SELECT state, count(*) FROM pg_stat_activity GROUP BY state;`
- `chk-dbe-perf-local-active-session` · dbe_perf.local_active_session (秒级抖动)
  - [sql] `SELECT count(*) FROM pg_stat_activity; SHOW max_connections;`
- `chk-rds060-long-running-transaction-exectime` · rds060_long_running_transaction_exectime
  - [sql] `SELECT pid, usename, state, xact_start, query FROM pg_stat_activity WHERE state='active' AND xact_start < now() - interval '5 min' ORDER BY xact_start;`
- `chk-pg-thread-wait-status-pg-stat-activity-i-o-sql` · pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL
  - [view] `SELECT * FROM pg_stat_activity LIMIT 50;`
- `chk-waiting-in-queue` · 查询等待状态 · waiting in queue
  - [sql] `SELECT * FROM pg_stat_activity WHERE state='active' AND waiting=true;`
- `chk-pg-stat-activity-pg-locks-sql-8-0-x` · pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本）
  - [view] `SELECT * FROM pg_stat_activity LIMIT 50;`

---

### `statement_history` · 10 次

**manual 派生 (10)**:

- `chk-statement-history-cpu-time-vs-db-time` · statement_history.cpu_time vs db_time
  - [view] `SELECT * FROM statement_history LIMIT 50;`
- `chk-statement-history-data-io-time-sql-io` · statement_history.data_io_time (慢SQL IO分析)
  - [view] `SELECT * FROM statement_history LIMIT 50;`
- `chk-rds048-p80` · rds048_P80
  - [sql] `SELECT percentile_cont(0.8) WITHIN GROUP (ORDER BY duration) AS p80 FROM statement_history WHERE start_time > now() - interval '5 min';`
- `chk-rds049-p95` · rds049_P95
  - [sql] `SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY duration) AS p95 FROM statement_history WHERE start_time > now() - interval '5 min';`
- `chk-rds063-slowquery-user` · rds063_slowquery_user
  - [sql] `SHOW log_min_duration_statement; SELECT user_name, count(*) FROM statement_history WHERE duration > 1000 GROUP BY user_name ORDER BY count DESC LIMIT 20;`
- `chk-pg-stat-statements-total-time-calls` · pg_stat_statements · total_time + calls (慢查询统计)
  - [sql] `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`
- `chk-partitioned-cstore-scan` · 执行计划：Partitioned CStore Scan分区扫描范围
  - [sql] `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`
- `chk-be-datarow-select-count` · <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小
  - [sql] `SELECT query_id, n_tuples_returned FROM statement_history ORDER BY n_tuples_returned DESC NULLS LAST LIMIT 20;`
- `chk-null-009` · 查询返回行数
  - [sql] `SELECT query_id, n_tuples_returned FROM statement_history ORDER BY n_tuples_returned DESC NULLS LAST LIMIT 20;`
- `chk-explain-partitioned-cstore-scan-selected-partitions` · EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量
  - [sql] `SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;`

---

### `gs_wlm_session_history` · 9 次

**auto inline (1)**:

- `chk-gs-wlm-session-history-warning-sql` · GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息
  - snippet: `SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC`

**manual 派生 (8)**:

- `chk-explain-analyze` · EXPLAIN ANALYZE · 基表扫描算子类型及执行时间
  - [sql] `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`
- `chk-pgxc-wlm-session-history-dataskew-warning` · pgxc_wlm_session_history · DataSkew warning
  - [view] `SELECT * FROM gs_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-large-table-in-broadcast-warning` · pgxc_wlm_session_history · Large Table in Broadcast warning
  - [view] `SELECT * FROM gs_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-spill` · pgxc_wlm_session_history · Spill告警
  - [view] `SELECT * FROM gs_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-nestloop` · pgxc_wlm_session_history · NestLoop大表告警
  - [view] `SELECT * FROM gs_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has` · pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史）
  - [sql] `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`
- `chk-explain-performance-spill-written-disk-temp-file-num` · EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字
  - [sql] `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`
- `chk-topsql-spill-info` · TopSQL.spill_info
  - [sql] `SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;`

---

### `pg_class` · 8 次

**auto inline (2)**:

- `chk-table-distribution-dn-1w` · table_distribution() 各DN空间（大表个数超1W场景）
  - snippet: `SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_cata…`
- `chk-pg-partition` · pg_partition 各表分区数
  - snippet: `SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition…`

**manual 派生 (6)**:

- `chk-partitioned-cstore-scan` · 执行计划：Partitioned CStore Scan分区扫描范围
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-explain-partitioned-cstore-scan-selected-partitions` · EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-cstore-scan` · 执行计划算子：CStore Scan耗时占比
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-cudesc-cu-row-count` · cudesc表中CU的row_count分布
  - [sql] `SELECT * FROM pg_class WHERE relname LIKE 'cudesc_%' LIMIT 20;`
- `chk-cu` · 执行计划中CU扫描数量
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`
- `chk-explain-cstore-scan-cusome-cunone` · EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数
  - [sql] `SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions`

---

### `pgxc_stat_activity` · 7 次

**auto inline (6)**:

- `chk-pgxc-stat-activity-runtime-current-timestamp-query-start` · PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start)
  - snippet: `SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle'…`
- `chk-pgxc-stat-activity-waiting-true` · PGXC_STAT_ACTIVITY · waiting=true 阻塞查询
  - snippet: `SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;`
- `chk-pgxc-stat-activity-state-waiting-query` · pgxc_stat_activity · state / waiting / query
  - snippet: `SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';`
- `chk-pgxc-stat-activity-vacuum-full-8-0-x` · pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前）
  - snippet: `SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';`
- `chk-pgxc-stat-activity-state` · pgxc_stat_activity state 字段
  - snippet: `SELECT state, query, query_id FROM pgxc_stat_activity;`
- `chk-cn-savepoint-release` · 各 CN 上 SAVEPOINT/RELEASE 语句分布
  - snippet: `SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';`

**manual 派生 (1)**:

- `chk-pgxc-stat-activity-state-waiting-enqueue` · PGXC_STAT_ACTIVITY · state / waiting / enqueue
  - [view] `SELECT * FROM PGXC_STAT_ACTIVITY LIMIT 50;`

---

### `pgxc_wlm_session_history` · 7 次

**manual 派生 (7)**:

- `chk-pgxc-wlm-session-history-block-time-duration` · pgxc_wlm_session_history · block_time / duration
  - [view] `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history` · pgxc_wlm_session_history · 同期并发作业数
  - [view] `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn-` · pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent
  - [view] `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-dataskew-warning` · pgxc_wlm_session_history · DataSkew warning
  - [view] `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-large-table-in-broadcast-warning` · pgxc_wlm_session_history · Large Table in Broadcast warning
  - [view] `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-spill` · pgxc_wlm_session_history · Spill告警
  - [view] `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`
- `chk-pgxc-wlm-session-history-nestloop` · pgxc_wlm_session_history · NestLoop大表告警
  - [view] `SELECT * FROM pgxc_wlm_session_history LIMIT 50;`

---

### `gs_table_skewness` · 6 次

**manual 派生 (6)**:

- `chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn-` · pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent
  - [sql] `SELECT * FROM gs_table_skewness LIMIT 50;`
- `chk-explain-performance-sql-streaming-redistribute` · EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜）
  - [sql] `SELECT * FROM gs_table_skewness LIMIT 50;`
- `chk-pgxc-wlm-session-history-dataskew-warning` · pgxc_wlm_session_history · DataSkew warning
  - [sql] `SELECT * FROM gs_table_skewness LIMIT 50;`
- `chk-table-distribution-dn` · table_distribution 各DN数据行数
  - [sql] `SELECT * FROM gs_table_skewness LIMIT 50;`
- `chk-pgxc-get-table-skewness` · PGXC_GET_TABLE_SKEWNESS 视图
  - [sql] `SELECT * FROM gs_table_skewness LIMIT 50;`
- `chk-dn-warning` · DN 间导入行数倾斜率(WARNING)
  - [sql] `SELECT * FROM gs_table_skewness LIMIT 50;`

---

### `pg_thread_wait_status` · 6 次

**auto inline (2)**:

- `chk-null-006` · 线程等待状态
  - snippet: `select * from pg_thread_wait_status where query_id='149181737656737395';`
- `chk-pg-thread-wait-status` · pg_thread_wait_status · 线程等待状态
  - snippet: `SELECT * FROM pg_thread_wait_status WHERE query_id='149181737656737395';`

**manual 派生 (4)**:

- `chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu` · pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高)
  - [view] `SELECT * FROM pg_thread_wait_status LIMIT 50;`
- `chk-pg-thread-wait-status-wait-status-wait-event-io` · pg_thread_wait_status.wait_status / wait_event (当前IO高)
  - [view] `SELECT * FROM pg_thread_wait_status LIMIT 50;`
- `chk-dbe-perf-local-active-session` · dbe_perf.local_active_session (秒级抖动)
  - [sql] `SELECT wait_status, wait_event, count(*) FROM pg_thread_wait_status GROUP BY 1,2 ORDER BY 3 DESC;`
- `chk-pg-thread-wait-status-pg-stat-activity-i-o-sql` · pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL
  - [view] `SELECT * FROM pg_thread_wait_status LIMIT 50;`

---

### `pgxc_thread_wait_status` · 6 次

**auto inline (5)**:

- `chk-pgxc-thread-wait-status-wait-status` · pgxc_thread_wait_status.wait_status
  - snippet: `Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not lik…`
- `chk-pgxc-thread-wait-status-dn` · pgxc_thread_wait_status · 作业等待 DN 分布
  - snippet: `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not …`
- `chk-pgxc-thread-wait-status-wait-status-wait-event` · pgxc_thread_wait_status · wait_status / wait_event
  - snippet: `SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_stat…`
- `chk-pgxc-thread-wait-status` · pgxc_thread_wait_status 锁等待状态
  - snippet: `SELECT * FROM pgxc_thread_wait_status WHERE query_id = {query_id};`
- `chk-dn` · 磁盘利用率各 DN 差异
  - snippet: `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not …`

**manual 派生 (1)**:

- `chk-pgxc-thread-wait-status-wait-status-write-file` · pgxc_thread_wait_status · wait_status='write file'
  - [view] `SELECT * FROM pgxc_thread_wait_status LIMIT 50;`

---

### `dbe_perf.memory_node_detail` · 5 次

**manual 派生 (5)**:

- `chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam` · dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory
  - [view] `SELECT * FROM dbe_perf.memory_node_detail LIMIT 50;`
- `chk-dbe-perf-session-memory-detail-dynamic-used-shrctx` · dbe_perf.session_memory_detail (dynamic_used_shrctx较小时)
  - [sql] `SELECT * FROM dbe_perf.memory_node_detail;`
- `chk-rds002-mem-util` · rds002_mem_util
  - [sql] `SHOW max_dynamic_memory; SELECT * FROM dbe_perf.memory_node_detail;`
- `chk-rds065-dynamic-used-memory-usage` · rds065_dynamic_used_memory_usage
  - [sql] `SELECT * FROM dbe_perf.memory_node_detail;`
- `chk-session-package` · SESSION 中 PACKAGE 变量数量与内存占用
  - [sql] `SELECT * FROM dbe_perf.memory_node_detail;`

---

### `pg_proc` · 4 次

**manual 派生 (4)**:

- `chk-pg-proc-provolatile-proshippable` · pg_proc.provolatile / proshippable
  - [view] `SELECT * FROM pg_proc LIMIT 50;`
- `chk-pg-proc-provolatile` · pg_proc.provolatile
  - [view] `SELECT * FROM pg_proc LIMIT 50;`
- `chk-pg-proc-volatility` · pg_proc 函数 volatility 类型查询
  - [view] `SELECT * FROM pg_proc LIMIT 50;`
- `chk-null-004` · 存储过程默认权限模式
  - [sql] `SELECT proname, prosecdef FROM pg_proc WHERE prosecdef=true LIMIT 50;`

---

### `dbe_perf.statement` · 3 次

**auto inline (1)**:

- `chk-dbe-perf-statement-cpu-time` · dbe_perf.statement.cpu_time
  - snippet: `select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_e…`

**manual 派生 (2)**:

- `chk-dbe-perf-statement-cpu-time-cpu` · dbe_perf.statement.cpu_time (持续CPU高)
  - [view] `SELECT * FROM dbe_perf.statement LIMIT 50;`
- `chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io` · dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高)
  - [view] `SELECT * FROM dbe_perf.statement LIMIT 50;`

---

### `pg_locks` · 3 次

**manual 派生 (3)**:

- `chk-pg-locks` · pg_locks · 阻塞会话与持锁会话关联
  - [view] `SELECT * FROM pg_locks LIMIT 50;`
- `chk-pg-stat-activity-pg-locks-sql-8-0-x` · pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本）
  - [view] `SELECT * FROM pg_locks LIMIT 50;`
- `chk-copy` · COPY 语句等待视图 · 轻量级锁等待
  - [sql] `SELECT * FROM pg_locks WHERE NOT granted;`

---

### `pg_stat_database` · 3 次

**manual 派生 (3)**:

- `chk-buffer-wdr` · buffer命中率 (WDR报告或管控平台)
  - [sql] `SELECT datname, blks_hit::numeric/NULLIF(blks_hit+blks_read,0) AS hit_ratio FROM pg_stat_database WHERE blks_hit+blks_read > 0 ORDER BY hit_ratio LIMIT 10;`
- `chk-commit-rollback-i-o` · COMMIT/ROLLBACK 频率与 I/O 开销
  - [sql] `SELECT datname, xact_commit, xact_rollback FROM pg_stat_database;`
- `chk-rds036-deadlocks` · rds036_deadlocks
  - [sql] `SELECT datname, deadlocks FROM pg_stat_database ORDER BY deadlocks DESC LIMIT 10;`

---

### `pgxc_get_table_skewness` · 3 次

**auto inline (2)**:

- `chk-pgxc-get-table-skewness` · PGXC_GET_TABLE_SKEWNESS 视图
  - snippet: `SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;`
- `chk-pgxc-get-table-skewness` · PGXC_GET_TABLE_SKEWNESS 视图
  - snippet: `SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;`

**manual 派生 (1)**:

- `chk-pgxc-get-table-skewness` · PGXC_GET_TABLE_SKEWNESS 视图
  - [view] `SELECT * FROM pgxc_get_table_skewness LIMIT 50;`

---

### `pgxc_wlm_session_info` · 3 次

**auto inline (2)**:

- `chk-pgxc-wlm-session-info-streaming-stream-count` · pgxc_wlm_session_info · Streaming 算子数（stream_count）
  - snippet: `SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM …`
- `chk-pgxc-wlm-session-info-max-cpu-time-cpu` · pgxc_wlm_session_info · max_cpu_time（高CPU语句）
  - snippet: `SELECT * FROM pgxc_wlm_session_info WHERE start_time > 'xxxx-xx-xx' AND start_time < 'xxxx-xx-xx' ORDER BY max_cpu_time …`

**manual 派生 (1)**:

- `chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has` · pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史）
  - [view] `SELECT * FROM pgxc_wlm_session_info LIMIT 50;`

---

## 下一步 (建议 · 不在本次范围)

1. 设计 `raw-snapshot` 模式: 给 collector 加 `COLLECT_MODE=raw` env,跑时只对上面 17 个 hot view 做 `SELECT * FROM v` 落 `raw/<view>.tsv`
2. 写 `post-process.mjs`: 读 `raw/` · 按 check_id 的 filter/agg 规则 (`hot-view-recipes.json`,可手写或从 manual-audit 派生命令反推) 派生 105 个 check 结果
3. 现有 `collect-precompiled` 保留 (单查模式 · 完整版),两套并存
4. 在 README 里加 "什么时候用哪个" 决策矩阵
