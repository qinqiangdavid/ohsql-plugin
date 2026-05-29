# GaussDB 离线采集清单(指标 + 抓取方法)

- 生成: 2026-05-29T07:57:42.142Z
- 关联 case 范围: `cases/gaussdb/` (77 case) + `cases/gaussdb-dws/` (120 case) · 共 197 case_id
- 数据源: `plugins/perf-kp-sql/data/cases/indices/by-check-item/CASES.md` (655 check 总,本清单是 gaussdb 关联子集)

## 用途

GaussDB 在内网/无 SSH 直连场景 perf-kp-sql skill 不能远程采集,把这份清单拿到目标机手工跑,
结果撞 `cases/<db>/CASES.md` 每条 case 的 `abnormal_pattern` 字段 → 命中即对应 case_id 候选。

- `type: metric` → 单纯采指标值跟阈值比
- `type: parameter-current-value` → 采参数现值跟 `recommended_value` 比

## 总览

| | 数 |
|---|---:|
| **GaussDB 关联 check 合计** | **290** |
| 其中 type=metric | 236 |
| 其中 type=parameter-current-value | 54 |

### 按 collection_layer 分布

| collection_layer | check 数 |
|---|---:|
| `db-system-view` | 94 |
| `db-interactive-cmd` | 82 |
| `gaussdb-guc-param` | 54 |
| `db-shell` | 19 |
| `db-internal-counter` | 15 |
| `log-grep` | 13 |
| `os` | 11 |
| `flamegraph` | 2 |

---

## collection_layer = `db-system-view` (94 check)

### type=metric (94 个)

| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |
|---|---|---|---|---:|
| `chk-buffer-wdr` | buffer命中率 (WDR报告或管控平台) | "可以借助GaussDB的管控平台或者WDR报告。通常情况下，TP数据库的buffer命中率应该在99%以上。" | "< 99%" | 1 |
| `chk-cn-savepoint-release` | 各 CN 上 SAVEPOINT/RELEASE 语句分布 | `SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';` | "结果显示SAVEPOINT/RELEASE语句处于idle in transaction。" | 1 |
| `chk-copy` | COPY 语句等待视图 · 轻量级锁等待 | "根据这5个COPY语句对应的query_id查看等待视图情况" | "同时只有 1 个 COPY 向 GTM 申请序列值，其余在等待轻量级锁" | 1 |
| `chk-cpu` | 资源池 CPU 限额 / 配额配置 | 设置资源池CPU限额与配额。 | "防止极端场景下某个语句占用CPU资源过多" | 1 |
| `chk-cudesc-cu-row-count` | cudesc表中CU的row_count分布 | - **abnormal_patterns**: ["row_count << 60000"] | "row_count << 60000" | 1 |
| `chk-dbe-perf-local-active-session` | dbe_perf.local_active_session (秒级抖动) | "对于短时间秒级性能抖动，分析相应时间点的dbe_perf.local_active_session，可排查点如下：•异常等待事件，当时SQL的异常等待事件，可参考整体性能慢-等待事件分析。•异常SQL，分析某些SQL出现的频率变化，以及执行速度，如多次采样均被采集到，即可反向分析到SQL执行时间。•异常连接数变化，比 | "\"如多次采样均被采集到，即可反向分析到SQL执行时间\"" | 1 |
| `chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam` | dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory | "查询dbe_perf.memory_node_detail视图，明确内存占用点。•max_dynamic_memory：最大可使用动态内存 •dynamic_used_memory：已使用动态内存" | "\"通常仅需要关注max_dynamic_memory和dynamic_used_memory差距，如果dynamic内存不足，会导致用户查询报错\"" | 1 |
| `chk-dbe-perf-session-memory-detail-dynamic-used-shrctx` | dbe_perf.session_memory_detail (dynamic_used_shrctx较小时) | "dynamic_used_shrctx较小，查询dbe_perf.session_memory_detail可获取到不同Session的内存消耗，通常来讲：用户会话数和用户每个session上内存占用都会导致动态内存异常问题。" | "\"dynamic_used_shrctx较小\"" | 1 |
| `chk-dbe-perf-shared-memory-detail-dynamic-used-shrctx` | dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时) | "dynamic_used_shrctx较大，查询dbe_perf.shared_memory_detail可获取到异常内存消耗的context，通常此处有过多的异常消耗，多数情况下为用户session上的内存异常消耗。" | "\"dynamic_used_shrctx较大\"" | 1 |
| `chk-dbe-perf-statement-cpu-time` | dbe_perf.statement.cpu_time | `select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_elapse_time/1000,2) as total_time,round( | "\"avg_time > 3ms\"" | 1 |
| `chk-dbe-perf-statement-cpu-time-cpu` | dbe_perf.statement.cpu_time (持续CPU高) | `dbe_perf.statement`：可查询分布式本CN发起的历史语句信息。`dbe_perf.summary_statement`：可查询分布式所有CN发起的历史语句信息。（对cpu_time字段进行逆序排序即可识别） | "\"对cpu_time字段进行逆序排序即可识别\"" | 1 |
| `chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io` | dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高) | "如果持续IO高，可查询dbe_perf.statement/dbe_perf.summary_statement内n_blocks_fetched/n_blocks_hit字段，通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。" | "\"通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。\"" | 1 |
| `chk-disk-cache-pgxc-disk-cache-all-stats` | Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats) | "通过查询视图pgxc_disk_cache_all_stats可以查看当前缓存的命中率以及各个DN磁盘的使用大小情况" | "\"用户查询数据时，会优先到Disk Cache中查看数据是否已存在于本地磁盘，如果不存在则再去OBS读取数据\"" | 1 |
| `chk-dms` | DMS 监控 · 节点磁盘使用率 | `选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。` | ">= 70%" | 1 |
| `chk-dms-max-min` | DMS · 节点磁盘使用率排序 (max - min) | `选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。` | "max - min >= 10%" | 1 |
| `chk-gs-asp` | gs_asp (两天内秒级抖动) | "对于两天内秒级性能抖动，分析相应时间点的gs_asp表" | "\"分析相应时间点的gs_asp表\"" | 1 |
| `chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ` | GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write | `GS_WLM_INSTANCE_HISTORY` | "\"io_util&io_await能够反应出磁盘的繁忙程度，disk_read&disk_write是发生的实际IO流量值，如果磁盘很繁忙，但实际IO流量值不高" | 1 |
| `chk-gs-wlm-session-history-warning` | GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警 | `SELECT query,warning FROM GS_WLM_SESSION_STATISTICS ORDER BY start_time DESC` | "\"Statistic Not Collect schema_test.t1\"" | 1 |
| `chk-gs-wlm-session-history-warning-sql` | GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息 | `SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC` | "内表行数 ≥ 外表行数 × 10 且内表每DN平均行数 > 10万行且发生下盘","平均每DN行数 > 10万行" | 2 |
| `chk-gtm-snapshot-oldestxmin-xid` | GTM snapshot · oldestxmin 与 xid 差值 | `SELECT * FROM pgxc_gtm_snapshot_status();` | "oldestxmin << base+min" | 1 |
| `chk-guc-shared-buffers-work-mem-thread-pool-attr` | GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值 | "常见的可能情况有：1. shared_buffers配置过小，导致buffer淘汰频繁。" | "\"shared_buffers配置过小，导致buffer淘汰频繁。\"" | 1 |
| `chk-hstore-delta-vs-cu` | HStore Delta表大小 vs 主表CU数据 | NULL | "\"Delta表空间复用受oldestXmin影响。长时间运行的事务可能导致空间复用延迟和膨胀。\"" | 1 |
| `chk-max-process-memory-shared-buffers-work-mem` | max_process_memory / shared_buffers / work_mem 内存参数 | NULL | "\"max_process_memory为12GB，设置过小。shared_buffers为32MB，设置过小。\"" | 1 |
| `chk-null-003` | 线程等待状态 | `select * from pg_thread_wait_status where query_id='149181737656737395';` | "\"根据线程等待状态，并没有出现都在等待某个DN的情况，初步排除中间结果集偏斜到了同一个DN的情况。\"" | 1 |
| `chk-null-004` | 表数据倾斜 | `select table_skewness('ioc_dm.m_ss_index_event');` | "NULL" | 1 |
| `chk-null-005` | 系统表/用户表膨胀情况 | "用户可在管控面执行全库Vacuum/Vacuum Full，以定期进行空间回收" | "\"用户数据膨胀严重，磁盘空间不足，性能低。\"" | 1 |
| `chk-null-010` | 各节点磁盘使用率均衡性 | `登录DWS控制台。在"集群列表"页面，找到需要查看监控的集群。在指定集群所在行的"操作"列，单击"监控面板"。选择"监控 > 节点监控 > 磁盘"，查看磁盘使用率。` | "> 5% 差值" | 1 |
| `chk-null-012` | 表脏页率 | `查看表脏页率为99%，VACUUM FULL后性能优化到100ms左右。` | "= 99%" | 1 |
| `chk-null-013` | 列存表文件大小监控 | "列存表数据按列存储，一列的每60000行存储为一个CU，同一列的CU连续存储在一个文件中，当该文件大于1GB时，切换到新文件中。CU文件数据不能更改只能追加写。" | "\"列存表多次执行INSERT后，发现表膨胀。\"" | 1 |
| `chk-null-014` | 活跃事务列表 | `SELECT txid_current_snapshot(); ` | "活跃事务列表中有 XID < 当前事务 XID" | 1 |
| `chk-order-line-id-null` | 列统计信息 · ORDER_LINE_ID NULL 比例 | `查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值` | "> 50% NULL" | 1 |
| `chk-pg-locks` | pg_locks · 阻塞会话与持锁会话关联 | - **abnormal_patterns**: ["`该查询返回会话ID、CN名称、用户信息、查询状态，以及导致阻塞的表、模式信息。`"] | "`该查询返回会话ID、CN名称、用户信息、查询状态，以及导致阻塞的表、模式信息。`" | 1 |
| `chk-pg-partition` | pg_partition 各表分区数 | `SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition GROUP BY parentid ) s ON c.oid = s.par | "> 3000分区" | 1 |
| `chk-pg-proc-provolatile` | pg_proc.provolatile | "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE" | "\"如果函数的provolatile属性为s或v，则仅当proshippable的值为t时，函数可以下推。\"" | 1 |
| `chk-pg-proc-provolatile-proshippable` | pg_proc.provolatile / proshippable | "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE。另外，在pg_proc中的proshippable字段，取值范围为t/f/NULL，这个字段与provolatile字段一起用于描述函数是否下推。" | "\"如果函数的provolatile属性为s或v，则仅当proshippable的值为t时，函数可以下推。\"","\"不下推语句在pg_log中会打印不下推的原因\"" | 3 |
| `chk-pg-proc-volatility` | pg_proc 函数 volatility 类型查询 | `查询pg_proc` | "查询pg_proc发现此处的to_date和to_char均为stable类型的函数，根据数据库对函数行为的约定，此类函数不能在预处理阶段转化为Const值" | 1 |
| `chk-pg-session-wlmstat-status-statement-mem` | pg_session_wlmstat · status / statement_mem | `SELECT usename,substr(query,0,20),threadid,status,statement_mem FROM pg_session_wlmstat where usename not in ('omm','Ruby') order by statement_mem,status desc; | "statement_mem > max_dynamic_memory 的 1/3" | 1 |
| `chk-pg-stat-activity-idle` | pg_stat_activity · idle 连接数 | `SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';` | "`non-active的个数表示空闲连接数，例如，non-active为508，说明当前有大量的空闲连接。`" | 1 |
| `chk-pg-stat-activity-pg-locks-sql-8-0-x` | pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本） | - **abnormal_patterns**: ["NULL"] | "NULL" | 1 |
| `chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu` | pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高) | "查询pg_stat_activity 获取正在运行的SQL的query_id。使用上一步的query_id，查询pg_thread_wait_status 获取正在运行的SQL的lwtid。使用操作系统命令top -Hp <gaussdb进程号>，查看相应lwtid(PID)的CPU使用率。" | "\"如果确实CPU占用较高，可能为目标SQL\"" | 1 |
| `chk-pg-stat-activity-sql` | pg_stat_activity 活跃SQL | `SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';` | "\"发现有大量的CREATE INDEX语句\"","\"发现有大量的CREATE INDEX语句，需要和用户确认该业务是否合理。\"" | 2 |
| `chk-pg-stat-get-last-data-changed-time` | 近期数据变更表列表（pg_stat_get_last_data_changed_time） | `gaussdb=# SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();` | "\"通过table_distribution(schemaname text, tablename text)查询出表在各个DN占用的存储空间\"" | 1 |
| `chk-pg-stat-get-last-data-changed-time` | pg_stat_get_last_data_changed_time 最近变更的表 | `SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();` | "NULL" | 1 |
| `chk-pg-stat-statements-total-time-calls` | pg_stat_statements · total_time + calls (慢查询统计) | - **abnormal_patterns**: ["total_time > 1000 AND calls > 10"] | "total_time > 1000 AND calls > 10" | 1 |
| `chk-pg-thread-wait-status` | pg_thread_wait_status · 线程等待状态 | `SELECT * FROM pg_thread_wait_status WHERE query_id='149181737656737395';` | "`根据线程等待状态，并没有出现都在等待某个DN的情况，初步排除中间结果集偏斜到了同一个DN的情况。`" | 1 |
| `chk-pg-thread-wait-status-pg-stat-activity-i-o-sql` | pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL | "通过查询pg_thread_wait_status视图的lwtid为上一步内的TID，获取对应的tid和sessionid。" | "\"查询pg_stat_activity视图内记录满足pid/sessionid为上一步内的tid/sessionid,即可找到造成I/O高的session信息，" | 1 |
| `chk-pg-thread-wait-status-wait-status-wait-event-io` | pg_thread_wait_status.wait_status / wait_event (当前IO高) | "如果当前IO高，可查询pg_thread_wait_status视图，查询wait_status/wait_event字段，通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。" | "\"通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。\"" | 1 |
| `chk-pgxc-get-stat-all-tables-dirty-page-rate` | PGXC_GET_STAT_ALL_TABLES.dirty_page_rate | `SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_ | "> 30","dirty_page_rate > 30" | 2 |
| `chk-pgxc-get-table-skewness` | PGXC_GET_TABLE_SKEWNESS | `gaussdb=#SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;` | "NULL" | 2 |
| `chk-pgxc-get-table-skewness` | pgxc_get_table_skewness · 全库倾斜视图 | `SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;` | "NULL" | 1 |
| `chk-pgxc-get-table-skewness` | PGXC_GET_TABLE_SKEWNESS 视图 | 分布差可以通过视图[PGXC_GET_TABLE_SKEWNESS]查看。 | "此处的数据分布差表示实际查询到DN上的数据量与DN平均数据量的差异。" | 1 |
| `chk-pgxc-lock-conflicts` | pgxc_lock_conflicts 锁冲突视图 | `SELECT * FROM pgxc_lock_conflicts;` | "NULL" | 1 |
| `chk-pgxc-lock-conflicts-8-1-x` | pgxc_lock_conflicts 锁冲突（8.1.x及以上） | `SELECT * FROM pgxc_lock_conflicts;` | "\"在查询结果中查看granted字段为\\\"f\\\"，表示VACUUM FULL语句正在等待其他锁。granted字段为\\\"t\\\"，表示INSERT语句是持有锁。\"" | 1 |
| `chk-pgxc-running-xacts` | 老事务列表 (pgxc_running_xacts) | `SELECT * FROM pgxc_running_xacts where xmin::text::bigint < $base+$min and xmin::text::bigint > 0;` | "存在 xmin < base+min 的活跃事务" | 1 |
| `chk-pgxc-stat-activity-runtime-current-timestamp-query-start` | PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start) | `SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle' order by 1 desc;` | "`查询会返回按执行时间长短从大到小排列的查询语句列表。第一条结果就是当前系统中执行时间最长的查询语句。`" | 1 |
| `chk-pgxc-stat-activity-state` | pgxc_stat_activity state 字段 | `SELECT state, query, query_id FROM pgxc_stat_activity;` | "state = 'idle in transaction'" | 1 |
| `chk-pgxc-stat-activity-state-waiting-enqueue` | PGXC_STAT_ACTIVITY · state / waiting / enqueue | `SELECT coorname, usename,client_addr,application_name,state,waiting,enqueue,pid FROM PGXC_STAT_ACTIVITY WHERE DATNAME='数据库名称';` | "NULL" | 1 |
| `chk-pgxc-stat-activity-state-waiting-query` | pgxc_stat_activity · state / waiting / query | `SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';` | "`查看当前处于阻塞状态的查询语句：SELECT coorname, pid,datname, usename, state,waiting,query FROM" | 1 |
| `chk-pgxc-stat-activity-vacuum-full-8-0-x` | pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前） | `SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';` | "NULL" | 1 |
| `chk-pgxc-stat-activity-waiting-true` | PGXC_STAT_ACTIVITY · waiting=true 阻塞查询 | `SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;` | "`大部分场景下，阻塞是因为系统内部锁而导致的，waiting字段才显示为true，此阻塞可在视图pgxc_stat_activity中体现。`" | 1 |
| `chk-pgxc-stat-table-dirty` | 表脏页率 (PGXC_STAT_TABLE_DIRTY) | "DWS提供了查询脏页率的系统视图，具体使用请参见PGXC_STAT_TABLE_DIRTY。" | "\"> 80%\"" | 1 |
| `chk-pgxc-thread-wait-status` | pgxc_thread_wait_status 锁等待状态 | `SELECT * FROM pgxc_thread_wait_status WHERE query_id = {query_id};` | "\"查询结果中\\\"wait_status\\\"存在\\\"acquire lock\\\"表示存在锁等待。\"" | 1 |
| `chk-pgxc-thread-wait-status-dn` | pgxc_thread_wait_status · 作业等待 DN 分布 | `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like  | "`发现作业总是等待部分DN或者个别DN`" | 1 |
| `chk-pgxc-thread-wait-status-wait-status` | pgxc_thread_wait_status.wait_status | `Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not like '%none%' and wait_status not like '%q | "\"通过等待视图查看作业的运行情况，发现作业总是等待部分DN，或者个别DN。\"" | 1 |
| `chk-pgxc-thread-wait-status-wait-status-wait-event` | pgxc_thread_wait_status · wait_status / wait_event | `SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_status <> 'synchronize quit' AND wait_statu | "`后台查看等待视图有大量wait wal sync和WALWriteLock状态，均为xlog同步状态。`" | 1 |
| `chk-pgxc-thread-wait-status-wait-status-write-file` | pgxc_thread_wait_status · wait_status='write file' | `等待视图中，当出现write file时，表示发生了中间结果下盘` | "wait_status = 'write file'" | 1 |
| `chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic-` | pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory | `SELECT * FROM pgxc_total_memory_detail;` | "dynamic_used_memory >= max_dynamic_memory" | 1 |
| `chk-pgxc-wlm-session-history` | pgxc_wlm_session_history · 同期并发作业数 | `pgxc_wlm_session_history` | "\"下一步需要接着查看本数据表，统计起始时间小于start_time、结束时间大于finish_time的作业数量。\"" | 1 |
| `chk-pgxc-wlm-session-history-block-time-duration` | pgxc_wlm_session_history · block_time / duration | `pgxc_wlm_session_history` | "\"block_time较大，而duration值并无明显变化，说明用户作业受其它作业影响，在真正开始执行前进行了较长时间的排队\"" | 1 |
| `chk-pgxc-wlm-session-history-dataskew-warning` | pgxc_wlm_session_history · DataSkew warning | "GaussDB 在执行 SQL 语句时，会对其性能表现进行分析和记录，通过视图和函数等手段呈现给用户。执行完一条代价大于resource_track_cost后，诊断信息会存放在内存hash表中，可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。" | "\"max_dn_tuples > min_dn_tuples * 10 且 max_dn_tuples > 100,000\"" | 1 |
| `chk-pgxc-wlm-session-history-large-table-in-broadcast-warning` | pgxc_wlm_session_history · Large Table in Broadcast warning | "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。" | "\"平均广播到每个DN上的数据行数 > 100,000\"" | 1 |
| `chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn-` | pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent | `pgxc_wlm_session_history` | "\"如果一个查询的DN执行时间有严重倾斜，那就需要考虑数据表的分区、分布列是否设置合适\"" | 1 |
| `chk-pgxc-wlm-session-history-nestloop` | pgxc_wlm_session_history · NestLoop大表告警 | "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。" | "\"内外表中最大行数 > DN数量 * 100,000\"" | 1 |
| `chk-pgxc-wlm-session-history-spill` | pgxc_wlm_session_history · Spill告警 | "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。" | "\"> 256MB\"" | 1 |
| `chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has` | pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史） | `SELECT start_time, block_time, duration, sql_hash, warning, max_peak_memory, max_spill_size, query_plan FROM pgxc_wlm_session_info were start_time > 'xxxx-xx-x | "`找到对应的快慢语句后，对比其执行计划query_plan，发现执行计划跳变严重。`" | 1 |
| `chk-pgxc-wlm-session-info-max-cpu-time-cpu` | pgxc_wlm_session_info · max_cpu_time（高CPU语句） | `SELECT * FROM pgxc_wlm_session_info WHERE start_time > 'xxxx-xx-xx' AND start_time < 'xxxx-xx-xx' ORDER BY max_cpu_time desc;` | "NULL" | 1 |
| `chk-pgxc-wlm-session-info-streaming-stream-count` | pgxc_wlm_session_info · Streaming 算子数（stream_count） | `SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM pgxc_wlm_session_info ORDER BY stream_c | "> 100" | 1 |
| `chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc` | pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent | `SELECT nodename,pid,dbname,username,application_name,min_peak_memory,max_peak_memory,average_peak_memory,memory_skew_percent,substr(query,0,50) as query FROM p | "`根据结果中的max_peak_memory以及memory_skew_percent值，较大的值就是消耗内存较多的语句。`" | 1 |
| `chk-pv-total-memory-detail-process-used-memory-vs-max-process-me` | pv_total_memory_detail · process_used_memory vs max_process_memory | `pv_total_memory_detail` | "\"可比较process_used_memory和max_process_memory的关系，如前者明显小于后者，则说明占用内存大的语句已经跑完或者被杀掉，当前系" | 1 |
| `chk-resource-track-level-operator-realtime` | resource_track_level · operator_realtime 级别实时算子监控 | `SET resource_track_level = 'operator_realtime';` | "`能够看出哪个算子执行时间长，通过算子执行时间和已处理行数等信息，确定是否需要终止SQL。`" | 1 |
| `chk-sql-create-index` | 活跃SQL及CREATE INDEX语句 | `select * from pg_stat_activity where state !='idle' and usename !='omm';` | "\"查询当前活跃sql，发现有大量的create index语句\"" | 1 |
| `chk-statement-history-cpu-time-vs-db-time` | statement_history.cpu_time vs db_time | "登录至各CN/DN节点查询相应时间段的statement_history 表。使用全局接口dbe_perf.get_global_full_sql_by_timestamp('开始时间','结束时间')。注意：需要切换至postgres库。" | "\"通常如果说语句的CPU消耗较高，慢SQL语句的cpu_time和db_time差距就较小\"" | 1 |
| `chk-statement-history-data-io-time-sql-io` | statement_history.data_io_time (慢SQL IO分析) | "查询statement_history表，慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录" | "\"慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录\"" | 1 |
| `chk-table-distribution-dn` | table_distribution() 各 DN 存储空间分布 | `SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();` | "NULL" | 1 |
| `chk-table-distribution-dn` | table_distribution 各DN数据行数 | `通过table_distribution发现所有数据倾斜到了dn_6009单个DN` | "`通过table_distribution发现所有数据倾斜到了dn_6009单个DN`" | 1 |
| `chk-table-distribution-dn-1w` | table_distribution() 各DN空间（大表个数超1W场景） | `gaussdb=#SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_catalog.pg_namespace n ON n.oid =  | "\"直接使用table_distribution()函数自定义输出，减少输出列进行计算优化\"" | 1 |
| `chk-table-skewness` | table_skewness · 数据倾斜率 | `SELECT table_skewness('store_sales');` | "NULL" | 1 |
| `chk-table-skewness-dn` | table_skewness() 各 DN 数据分布比例 | `openGauss=# select table_skewness('inventory');` | "NULL" | 1 |
| `chk-table-skewness-table-distribution` | table_skewness / table_distribution | `select table_skewness('store_sales');` | "\"数据最多的dn有22831616行，其他dn都是0行，数据有严重倾斜。\"" | 1 |
| `chk-topsql-spill-info` | TopSQL.spill_info | `实时TopSQL语句或历史TopSQL语句中，spill_info字段中会包含下盘信息，如果该字段不为空，说明有DN实例出现了下盘。` | "spill_info IS NOT NULL" | 1 |
| `chk-vs` | 脏数据膨胀率 / 表实际大小 vs 有效数据量 | NULL | "\"发现表数据膨胀严重，对其中一张8GB大小的表，总数据量5万条，做完VACUUM FULL后大小减小为5.6MB。\"" | 1 |
| `chk-waiting-in-queue` | 查询等待状态 · waiting in queue | "普通用户主要在waiting in queue/waiting in global queue时。当前的活跃语句数超过max_active_statements限制导致的普通用户排队，由于管理员用户不受管控所以无需排队。" | "\"普通用户在排队：waiting in queue/waiting in global queue/waiting in ccn queue.\"" | 1 |
| `chk-wdr-top-sql-order-by-cpu-time` | WDR 报告 Top SQL order by CPU Time | "可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句" | "\"如果CPU一直较高，方法一：可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句\"" | 1 |
| `chk-xid` | 当前事务 XID | `SELECT txid_current();` | "\"执行以下命令查询当前的事务XID。\"" | 1 |

---

## collection_layer = `db-interactive-cmd` (82 check)

### type=metric (82 个)

| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |
|---|---|---|---|---:|
| `chk-a-time-dn` | 算子 A-time(在单 DN 上的运行耗时) | - **abnormal_patterns**: ["NULL"] | "NULL" | 1 |
| `chk-analyze` | ANALYZE 后的查询性能 | "使用ANALYZE命令分析数据库。" | "\"如果此命令执行后性能恢复或者有所提升，则表明AUTOVACUUM未能很好的完成它的工作，有待进一步分析。\"" | 1 |
| `chk-b-tree-explain-analyze` | 创建 B-tree 索引后再次 EXPLAIN ANALYZE | 添加索引后，通过与无索引时执行计划的对比，查询时间从原来的382.624ms缩短到0.293 ms。 | "查询时间从原来的382.624ms缩短到0.293 ms。" | 1 |
| `chk-cstore-scan` | 执行计划算子：CStore Scan耗时占比 | "通过抓取问题SQL的执行信息，发现大部分的耗时都在\"CStore Scan\"" | "\"大部分的耗时都在\\\"CStore Scan\\\"\"" | 1 |
| `chk-cu` | 执行计划中CU扫描数量 | "查看偶发慢业务慢时的执行计划信息，慢在cstore scan，且扫描数据量不大但扫描CU个数较多" | "CU数量 >> 数据行数/60000" | 1 |
| `chk-data-node-scan` | 执行计划下推标识（Data Node Scan） | "将GUC参数enable_fast_query_shipping设置为off，使查询优化器使用分布式框架策略。查看执行计划。如果执行计划中有Data Node Scan节点，那么此执行计划是发送语句的分布式执行计划，为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。" | "\"可见，func_percent_2并没有被下推，而是将ss_sales_price和ss_list_price收到CN上，再进行计算，消耗大量CN的资源，而且" | 1 |
| `chk-enable-hashjoin` | enable_hashjoin 关闭后执行计划 | `SET enable_hashjoin = off;` | "`分析上述执行计划，发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。" | 1 |
| `chk-explain` | EXPLAIN 执行计划算子估算行数 | `EXPLAIN` | "第11层算子估算行数为2140，比实际行数严重低估" | 1 |
| `chk-explain` | EXPLAIN · 计划与实际行数比对 | `导致执行计划选择不优` | "`统计信息不是最新的情况`" | 1 |
| `chk-explain` | EXPLAIN执行计划耗时分布 | NULL | "\"打印执行计划，分析出耗时主要在index scan上，可能是I/O争抢导致\"" | 1 |
| `chk-explain` | EXPLAIN · 执行计划顺序扫描阶段耗时 | `EXPLAIN` 查看多表 JOIN 执行计划 | "\"分析执行计划可知，在顺序扫描阶段耗时较多\"" | 1 |
| `chk-explain-analyze` | EXPLAIN ANALYZE 算子落盘标志 | "为了优化性能，可以查看SQL的执行计划，如果算子存在落盘的情况，可适当调整work_mem参数值。" | "\"如果算子存在落盘的情况\"" | 1 |
| `chk-explain-analyze` | EXPLAIN ANALYZE 顺序扫描耗时 | `EXPLAIN` | "在顺序扫描阶段耗时较多" | 1 |
| `chk-explain-analyze-agg` | EXPLAIN ANALYZE Agg 算子类型 | `EXPLAIN ANALYZE` | "如果大结果集选择了Sort+GroupAgg" | 1 |
| `chk-explain-analyze-agg` | EXPLAIN ANALYZE · Agg 算子类型及执行时间 | `EXPLAIN ANALYZE` 查看聚合操作算子选择 | "\"如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时明显优于Sort+GroupAgg\"" | 1 |
| `chk-explain-analyze-hashjoin-dn` | EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围 | `EXPLAIN ANALYZE` | "HashJoin的执行时间信息[2657.406,93339.924 | 1 |
| `chk-explain-analyze-join` | EXPLAIN ANALYZE Join 算子类型与耗时 | `EXPLAIN ANALYZE` | "> 100s" | 1 |
| `chk-explain-analyze-join` | EXPLAIN ANALYZE · JOIN 算子类型及执行时间 | `EXPLAIN ANALYZE` 查看两表 JOIN 的算子类型 | "\"NestLoop耗时181秒\"" | 1 |
| `chk-explain-analyze-startup-vs-total` | EXPLAIN ANALYZE · 路径代价 (Startup vs Total) | "把explain_perf_mode设置为normal，查看原Nest Loop的启动代价" | "\"红框中的两个cost，分别是启动代价和总代价，在看Hash Join的cost，明显Hash Join的启动代价比Nest Loop的大很多（启动代价代表了输" | 1 |
| `chk-explain-analyze-stream` | EXPLAIN ANALYZE · Stream算子类型 | "GaussDB计划中常见的主要Stream算子包括Redistribute、Broadcast和Gather。" | "\"优化器认为适合做Broadcast。于是最终选择了一边Broadcast的计划。\"" | 1 |
| `chk-explain-cn-vs-dn` | EXPLAIN 执行计划算子位置（CN vs DN） | `EXPLAIN` | "可以看到window agg和sort全部在CN端执行，耗时非常严重" | 1 |
| `chk-explain-cstore-scan-cusome-cunone` | EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数 | `分析计划主要耗时在Cstore Scan。Cstore Scan的详细信息中，每个DN扫描出2w左右的数据，但是扫描了有数据的CU（CUSome）155079个，没有数据的CU（CUNone）156375个` | "`说明当前小CU、未命中数据的CU极多，即CU膨胀严重。`" | 1 |
| `chk-explain-data-node-scan` | EXPLAIN · 是否含 Data Node Scan 节点 | `如果执行计划中有Data Node Scan节点，那么此执行计划为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。` | "`Data Node Scan on store_sales \"_REMOTE_TABLE_QUERY_\"`" | 1 |
| `chk-explain-data-node-scan-on` | EXPLAIN 输出中 "Data Node Scan on" 是否在第一行 | "通常而言explain语句后没有显示具体的执行计划算子，执行计划中关键字\"Data Node Scan on\"出现在第一行（不包含计划格式）则说明语句已下推给DN去执行。" | "\"在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈\"" | 1 |
| `chk-explain-filter` | EXPLAIN 执行计划 Filter 条件分析 | `EXPLAIN` | "Filter条件中存在表达式to_char(add_months(to_date(''20170222'','yyyymmdd'), -11),'yyyymm'" | 1 |
| `chk-explain-groupagg-sort` | EXPLAIN · 算子(GroupAgg+Sort) | `计划中包含GroupAgg+Sort算子` | "`计划中包含GroupAgg+Sort算子，导致性能较差`" | 1 |
| `chk-explain-in-join` | EXPLAIN · in 条件是否转为 join | "打印语句的执行计划" | "执行计划中 in 仍作为 Filter 而非 Hash Join" | 1 |
| `chk-explain-indexscan` | EXPLAIN 执行计划 · 是否选择IndexScan | "对表执行ANALYZE更新统计信息。" | "\"如果表未执行ANALYZE或最近一次执行完ANALYZE后表进行过数据量较大的增删操作，会导致统计信息不准，该场景下也可能导致查询表时没有使用索引。\"" | 1 |
| `chk-explain-join` | EXPLAIN 执行计划 · Join 算子类型及耗时 | `分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。` | "`分析上述执行计划，发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。" | 1 |
| `chk-explain-join` | EXPLAIN 执行计划 Join 类型 | `EXPLAIN` | "join-condition实质上是一个不等式，这种不等值的join操作必须走nestloop" | 1 |
| `chk-explain-nest-loop-join` | EXPLAIN 执行计划 · Nest Loop Join 耗时 | `分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。` | "> 12s" | 1 |
| `chk-explain-or-filter` | EXPLAIN 执行计划 · 系统视图权限OR filter | "通过执行计划可以看到系统视图中的权限判断中多用or条件判断：pg_has_role(c.relowner, 'USAGE'::text) OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGG | "\"普通用户的or条件需要逐一判断，如果数据库中表个数比较多，最终会导致普通用户比dbadmin需要更长的执行时间。\"" | 1 |
| `chk-explain-partitioned-cstore-scan-selected-partitions` | EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量 | `收集几个典型的慢SQL语句，分别打印执行计划。从执行计划中可以看出来，两条SQL的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分区扫描上。` | "`慢SQL过滤条件中未涉及分区字段，导致执行计划未分区剪枝，进行了全表扫描，性能严重劣化。`" | 1 |
| `chk-explain-performance` | EXPLAIN PERFORMANCE 算子耗时 | `EXPLAIN PERFORMANCE` | "分析发现如图红框标识的两个性能瓶颈点均为表Scan动作" | 1 |
| `chk-explain-performance` | EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子 | `EXPLAIN PERFORMANCE` 查看是否有 Vector 前缀算子 | "\"经过分析发现计划走了行引擎。根本原因是：临时计划表input_acct_id_tbl和中间结果转储表row_unlogged_table使用了行存表。\"" | 1 |
| `chk-explain-performance` | EXPLAIN PERFORMANCE · 算子分布 | `explain performance` | "`执行计划中出现Sort和WindowAgg，第3~6步集中在一个DN上进行，使SQL非常缓慢`" | 1 |
| `chk-explain-performance-cpu-io` | EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络) | `通过执行态信息，我们可以分析出算子为单位的性能，也可以分析出算子内部各步骤的性能，进一步为诊断性能的瓶颈打下了基础。` | "NULL" | 1 |
| `chk-explain-performance-rows-hint` | EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时 | `select avg(netpaid) from (select /*+rows(store_sales store_returns * 11270)*/ c_last_name ...` | "\"最终计划如下图所示，运行时间94s，完成调优\"" | 1 |
| `chk-explain-performance-spill-written-disk-temp-file-num` | EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字 | `performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。` | "`performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。`" | 1 |
| `chk-explain-performance-sql-streaming-redistribute` | EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜） | `SQL自诊断信息显示在做row_number()函数计算前的PARTITION BY T.ORDER_LINE_ID引入的重分布算子(Streaming(type: REDISTRIBUTE))有计算倾斜` | "`Streaming(type: REDISTRIBUTE)有计算倾斜`" | 1 |
| `chk-explain-performance-vs-a-rows-vs-e-rows` | EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows） | `EXPLAIN PERFORMANCE` 查看 TPC-DS Q24 部分语句执行计划 | "\"第11层算子估算行数为2140，比实际行数严重低估\"" | 1 |
| `chk-explain-performance-windowagg-sort` | EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时 | `explain performance` | "\"执行计划中出现Sort和WindowAgg，第3~6步集中在一个DN上进行，使SQL非常缓慢。\"" | 1 |
| `chk-explain-remotequery-data-node-scan` | EXPLAIN · 是否含 RemoteQuery / Data Node Scan | - **abnormal_patterns**: ["`Data Node Scan on t1 \"_REMOTE_TABLE_QUERY_\"`"] | "`Data Node Scan on t1 \"_REMOTE_TABLE_QUERY_\"`" | 1 |
| `chk-explain-scan-a-time-max-min-dn` | EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比 | `表Scan的A-time中，max time DN执行耗时6554ms，min time DN耗时0s，DN之间扫描差异超过10倍以上` | "> 10倍" | 1 |
| `chk-explain-scan-vs` | EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数 | `某业务SQL总执行时间2.519s，其中Scan占了2.516s，同时该表的扫描最终只扫描到0条符合条件数据，过滤了20480条数据` | "`扫描时间与扫描数据量严重不符，此现象可判断为由于脏数据多从而影响扫描和I/O效率。`" | 1 |
| `chk-explain-selected-partitions` | EXPLAIN 执行计划 · Selected Partitions 数量 | `对该表设计为分区表后没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms，I/O效率极低。` | "`没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms`" | 1 |
| `chk-explain-seq-scan-vs-index-scan` | EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan） | `Seq Scan扫描需要3767ms，因涉及从4096000条数据中获取8240条数据，符合索引扫描的场景（海量数据中寻找少量数据），在对过滤条件列增加索引后，计划依然是Seq Scan而没有走Index Scan。` | "`计划依然是Seq Scan而没有走Index Scan。`" | 1 |
| `chk-explain-seqscan-vs-indexscan` | EXPLAIN · 算子(seqscan vs indexscan) | `在优化前，没有创建places.place_id和states.state_id索引，执行计划如下` | "NULL" | 1 |
| `chk-explain-stream` | EXPLAIN 执行计划 Stream 算子类型 | `EXPLAIN` | "劣化的原因主要为lineitem和part表join时stream类型由BroadCast变更为Redistribute导致" | 1 |
| `chk-explain-subplan` | EXPLAIN 执行计划 SubPlan 存在 | `EXPLAIN` | "此SQL性能较差，查看发现执行计划中存在SubPlan" | 1 |
| `chk-explain-verbose` | EXPLAIN VERBOSE 统计信息警告 | "通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, publ | "\"WARNING:Statistics in some tables or columns(...) are not collected.\"" | 1 |
| `chk-explain-verbose-anti-join` | EXPLAIN VERBOSE Anti Join 行数估算 | `explain verbose` | "估算Anti Join的行数与实际行数相差很大" | 1 |
| `chk-explain-verbose-hashjoin` | EXPLAIN VERBOSE hashjoin 行数估算 | `set cost_param=2; explain verbose` | "实际是将AND的两个过滤条件分别计算的2个选择率的值相乘来得到hashjoin条件的选择率，导致行数估算不准确，查询性能较差" | 1 |
| `chk-explain-verbose-hashjoin` | EXPLAIN VERBOSE · HashJoin 行数估算偏差 | `set cost_param=2; explain verbose select nation, sum(amount) as sum_profit from (...) as profit group by nation order by nation` | "\"导致行数估算不准确，查询性能较差\"" | 1 |
| `chk-explain-verbose-remote` | EXPLAIN VERBOSE · __REMOTE 关键字 | "通过EXPLAIN VERBOSE打印语句执行计划。上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。" | "\"上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。\"" | 1 |
| `chk-explain-verbose-remotequery` | explain verbose · RemoteQuery 计划 | `yshen=# set rewrite_rule='none'; SET yshen=# explain (verbose on, costs off)  select two_sum(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c | "`该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`" | 1 |
| `chk-explain-verbose-streaming-vs-data-node-scan` | EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan | `gaussdb=# set rewrite_rule='none'; SET gaussdb=# explain (verbose on, costs off)  select group_concat(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t | "`该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`" | 1 |
| `chk-explain-verbose-subplan` | explain verbose · SubPlan 执行方式 | `yshen=# set rewrite_rule='none'; SET yshen=# explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order | "`由于目标列中的相关子查询(select avg(c2) from t2 where t2.c2=t1.c2)无法提升的缘故，导致每扫描t1的一行数据，就会触发" | 1 |
| `chk-explain-verbose-subplan` | EXPLAIN VERBOSE · SubPlan 算子出现在目标列 | `gaussdb=# set rewrite_rule='none'; SET gaussdb=# explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 o | "`导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`" | 1 |
| `chk-explain-verbose-warning` | explain verbose WARNING · 统计信息缺失提示 | `通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, ...) are not collected. HINT:Do an | "`WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, pub" | 1 |
| `chk-explain-verbose-warning` | EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表 | `通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, publ | "`Statistics in some tables or columns(...) are not collected.`" | 1 |
| `chk-explain-verbose-warning` | EXPLAIN VERBOSE 执行计划 Warning | `explain verbose` | "\"WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, pub","\"执行计划中会有语句未收集统计信息的告警，并且通常E-rows估算非常小。\"" | 2 |
| `chk-explain-verbose-warning` | EXPLAIN VERBOSE WARNING信息 · 统计信息缺失 | "通过EXPLAIN VERBOSE执行query分析执行计划时会提示WARNING信息" | "\"WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, pub" | 1 |
| `chk-group-by-groupagg-sort` | GROUP BY 查询计划中是否包含 GroupAgg+Sort | "查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。" | "\"查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。\"" | 1 |
| `chk-in` | 执行计划in条件处理方式 | "打印语句的执行计划" | "\"执行计划中，in条件还是作为普通的过滤条件存在。这种场景下，最优的执行计划应该是将\\\"in 常量\\\"转化为join操作性能更好。\"" | 1 |
| `chk-leading-hint` | 加 leading hint 后执行时间 | select /*+ leading((s d)) */ a.ca_state state, count(*) cnt ... | "34268.322ms → 11095.046ms" | 1 |
| `chk-leading-no-nestloop-hint` | 加 leading + no nestloop hint 后执行时间 | select /*+ leading((s d)) no nestloop(s d) */ a.ca_state state, count(*) cnt ... | "11095.046ms → 4644.409ms" | 1 |
| `chk-memory-information-dn` | Memory Information 各 DN 内存消耗分布 | `EXPLAIN ANALYZE` (Memory Information 段) | "各个节点的内存资源消耗也存在极为严重的偏斜" | 1 |
| `chk-nestloop` | 语句执行时间 / 执行计划中 NestLoop 算子 | `该问题发生在实时场景下，语句执行时间因为达到了 3600s而自动终止运行` | ">= 3600s" | 1 |
| `chk-nestloop` | 执行计划算子类型（NestLoop） | "首先观察SQL语句中有not in 语法；执行计划中有NestLoop" | "\"NestLoop是导致语句性能慢的主要原因。\"" | 1 |
| `chk-nestloop` | 执行计划算子类型（NestLoop出现） | "通过EXPLAIN VERBOSE打印语句执行计划，查看执行计划发现SQL语句中存在not in语句" | "\"NestLoop是导致语句性能慢的主要原因\"" | 1 |
| `chk-null-006` | 查询返回行数 | "检查查询语句是否返回了多余的数据信息。" | "\"对于包含50条记录的表，查询起来是很快的；但是，当表中包含的记录达到50000，查询效率将会有所下降。\"" | 1 |
| `chk-null-007` | 主机负载下查询单独运行时延 | "尝试在数据库没有其他查询或查询较少的时候运行查询语句，并观察运行效率。" | "\"如果效率较高，则说明可能是由于之前运行数据库系统的主机负载过大导致查询低效。\"" | 1 |
| `chk-null-008` | 重复执行同一查询语句的执行时间 | "重复执行相同的查询语句，如果后续执行的查询语句效率提升，则可能是由于上述原因导致。" | "\"查询效率低的一个重要原因是查询所需信息没有缓存在内存中，这可能是由于内存资源紧张，缓存信息被其他查询处理覆盖。\"" | 1 |
| `chk-partitioned-cstore-scan` | 执行计划：Partitioned CStore Scan分区扫描范围 | "和客户收集几个典型的慢sql，分别打印执行计划。" | "\"从执行计划中可以看出来，两条sql的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分" | 1 |
| `chk-remote` | 执行计划下推标识（__REMOTE关键字） | "通过explain verbose打印语句执行计划" | "\"上述执行计划中有__REMOTE关键字，这就表明当前的语句是不下推执行的。\"" | 1 |
| `chk-rows-hint` | rows hint 后执行时间 | select /*+ rows(s #2880404) */ a.ca_state state, count(*) cnt ... | "34268.322ms → 1991.843ms (17x)" | 1 |
| `chk-scan-filter` | Scan filter 条件分析 | `EXPLAIN PERFORMANCE` | "进一步分析表Scan的filter条件发现两个表存在acct_id = 'A012709548'::bpchar这样的filter条件" | 1 |
| `chk-seq-scan-dn` | Seq Scan 各 DN 扫描时间 | `EXPLAIN ANALYZE` | "进一步向HashJoin算子的下层分析发现Seq Scan on s_riskrate_setting也存在极为严重的计算倾斜[38.885,2940.983 | 1 |
| `chk-skew-hint-agg` | skew hint 后双层 Agg 计划 | select /*+ skew(store_returns(sr_store_sk sr_customer_sk)) */sr_customer_sk as ctr_customer_sk ... | "对于HashAgg，由于其重分布存在倾斜，所以优化为双层Agg。" | 1 |
| `chk-sql-case-when` | SQL 中 CASE WHEN 分支数量与执行次数 | "在业务查询中，CASE WHEN语句常用来进行条件判断，但如果在SQL查询中存在大量冗余的CASE WHEN" | "\"该语句冗长，执行时每个分支的CASE WHEN均需执行，导致查询时间成倍增加\"" | 1 |
| `chk-warning` | 执行计划统计信息Warning | "通过explain verbose/explain performance打印语句的执行计划" | "\"执行计划中会有语句未收集统计信息的告警，并且通常E-rows估算非常小。\"" | 1 |

---

## collection_layer = `gaussdb-guc-param` (54 check)

> 全部是 GaussDB GUC 配置参数(autovacuum / enable_* / work_mem / comm_max_stream 等)。
> **统一采集方式**:
>
> ```sql
> -- 单条:
> SHOW <param_name>;
>
> -- 一次抓全 54 个 (推荐):
> SELECT name, setting, unit, context, source
> FROM pg_settings
> WHERE name IN ('autovacuum','enable_hashjoin','work_mem',...);  -- 列表见下表 param_name 列
> ```
>
> 拿到现值后跟 `recommended_value` (蒸馏里有的) 或 `rationales` 描述比对 → 越界即可疑。

### type=parameter-current-value (54 个)

| check_id | param_name | recommended_value | rationales (摘) | 关联 case 数 |
|---|---|---|---|---:|
| `chk-a-format-load-with-constraints-violation` | a_format_load_with_constraints_violation |  | "\"该功能下数据导入过程会从批量插入变为单行插入，对应的导入性能会有所劣化。\"" | 1 |
| `chk-abnormal-check-general-task` | abnormal_check_general_task |  | "\"默认值60s的定期清理时间间隔，对毫秒级业务性能影响较大，单个线程重新创建的开销大约需要300ms，有毫秒级性能敏感场景建议调大。\"" | 1 |
| `chk-autovacuum` | autovacuum |  | "\"用户未开启autovacuum的同时又没有合理的自定义vacuum调度，导致表的脏数据没有及时回收，新的数据又不断插入或更新，膨胀是必然的\"" | 1 |
| `chk-autovacuum-max-workers` | autovacuum_max_workers |  | "\"如果数据库的表很多，而且都比较大，那么当需要vacuum的表超过了配置autovacuum_max_workers的数量，这些表就要等待空闲的autovacuum线程\"" | 1 |
| `chk-autovacuum-max-workers-hstore` | autovacuum_max_workers_hstore |  | "\"入库速度不得超过MERGE处理能力。通过控制入库并发防止Delta表膨胀。\"" | 1 |
| `chk-autovacuum-naptime` | autovacuum_naptime |  | "\"autovacuum_naptime设置间隔时间过长\"" | 2 |
| `chk-autovacuum-vacuum-cost-delay` | autovacuum_vacuum_cost_delay |  | "\"开启autovacuum_vacuum_cost_delay后，会使用基于成本的脏数据回收策略...对于IO性能高的系统，开启autovacuum_vacuum_cost_delay反而会使得垃圾回收的时间变长\"" | 1 |
| `chk-behavior-compat-options` | behavior_compat_options |  | "\"选择不当的权限模式可能导致越权访问敏感数据，或进行未授权的资源操作。\"" | 1 |
| `chk-best-agg-plan` | best_agg_plan |  | "这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差","\"这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差，这时候就需要通过best_agg_plan进行agg计算模型的干预\"" | 2 |
| `chk-comm-max-stream` | comm_max_stream |  | "`否则Stream个数不够`" | 1 |
| `chk-connectiontimeout` | connectionTimeOut |  | "`Flink写入DWS报以下错误，此问题一般为SQL执行超时导致。canceling statement due to statement timeout`" | 1 |
| `chk-cost-param` | cost_param |  | "当使用cost_param的bit0为0时，估算Anti Join的行数与实际行数相差很大，导致查询性能下降","导致行数估算不准确，查询性能较差","\"估算Anti Join的行数与实际行数相差很大，导致查询性能下降\"","\"导致行数估算不准确，查询性能较差\"" | 4 |
| `chk-cstore-buffers` | cstore_buffers |  |  | 1 |
| `chk-default-statistics-target` | default_statistics_target |  | "计划相比于默认统计信息发生劣化" | 1 |
| `chk-disk-cache-dual-write-option` | disk_cache_dual_write_option |  |  | 1 |
| `chk-disk-cache-max-size` | disk_cache_max_size |  | "\"缩小Disk Cache可用规模后可能带来查询性能下降。\"","\"缺点是缩小Disk Cache可用规模后可能带来查询性能下降。\"" | 2 |
| `chk-enable-codegen` | enable_codegen |  |  | 1 |
| `chk-enable-delta` | ENABLE_DELTA |  | "\"列存表多次执行INSERT后，发现表膨胀。\"" | 1 |
| `chk-enable-fast-query-shipping` | enable_fast_query_shipping |  | "\"在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。\"" | 2 |
| `chk-enable-hashjoin` | enable_hashjoin |  | "`发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。`" | 2 |
| `chk-enable-index-nestloop` | enable_index_nestloop |  | "`语句执行时间因为达到了 3600s而自动终止运行，导致影响业务进度。`" | 1 |
| `chk-enable-indexscan` | enable_indexscan |  |  | 2 |
| `chk-enable-mergejoin` | enable_mergejoin |  |  | 2 |
| `chk-enable-nestloop` | enable_nestloop |  | "\"NestLoop耗时27秒\"","\"如下的例子中NestLoop耗时27秒\"","NestLoop耗时181秒","\"NestLoop耗时181秒\"" | 5 |
| `chk-enable-numa-bind` | enable_numa_bind |  |  | 1 |
| `chk-enable-sort` | enable_sort |  | "\"Sort+GroupAgg耗时2417ms，HashAgg耗时2324ms\"","如果大结果集选择了Sort+GroupAgg" | 5 |
| `chk-enable-stream-operator` | enable_stream_operator |  |  | 1 |
| `chk-fetchsize` | fetchSize |  | "\"结果集过大，一次性全部加载，消耗大量时间。\"" | 1 |
| `chk-lockwait-timeout` | lockwait_timeout |  | "\"当申请的锁等待时间超过GUC参数lockwait_timeout的设定值时，系统会报LOCK_WAIT_TIMEOUT的错误。\"" | 1 |
| `chk-max-active-statements` | max_active_statements |  | "\"当前的活跃语句数超过max_active_statements限制导致的普通用户排队\"" | 1 |
| `chk-max-connections` | max_connections |  | "`当前数据库连接已经超过了最大连接数`" | 1 |
| `chk-max-process-memory` | max_process_memory |  | "\"内存参数设置不合理\"" | 3 |
| `chk-min-batch-rows` | min_batch_rows |  |  | 1 |
| `chk-period` | period |  | "\"普通分区表无法自动创建新分区\"" | 1 |
| `chk-psort-work-mem` | psort_work_mem |  | "\"如果表较大或GUC参数psort_work_mem设置较小，会导致PCK排序时产生下盘（数据库选择将临时结果暂存到磁盘），进行外部排序；一旦进行外部排序，时间消耗就会增加很多。\"","\"如果无法在内存中完成排序时，会下盘写临时文件，这时就会产生较大的影响\"" | 2 |
| `chk-qrw-inlist2join-optmode` | qrw_inlist2join_optmode |  | "\"如果优化器估算不准，可能会出现需要转化的场景没有做转化，导致性能较差。\"" | 2 |
| `chk-query-dop` | query_dop |  |  | 1 |
| `chk-recovery-parse-workers` | recovery_parse_workers |  | "\"在系统长时间的运行后，备DN上会出现日志累积。当主DN故障后，数据恢复需要很长时间，数据库不可用，严重影响系统可用性。\"" | 1 |
| `chk-recovery-redo-workers` | recovery_redo_workers |  | "\"在系统长时间的运行后，备DN上会出现日志累积。\"" | 1 |
| `chk-resource-pool-cpu-dedicated-quota` | resource_pool.cpu_dedicated_quota |  | "防止极端场景下某个语句占用CPU资源过多，导致数据库内其他语句因争抢CPU而变得缓慢迟钝的情况" | 1 |
| `chk-resource-track-level` | resource_track_level |  | "`在作业无排队无死锁正常运行期间，发现作业长时间不结束，此时可查看算子级别的实时TopSQL监控，能够看出哪个算子执行时间长`" | 1 |
| `chk-rewrite-rule` | rewrite_rule |  | "`该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`","`导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`","\"由于目标列中的相关子查询无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下\"","`网络传输了大量数据，然后 | 10 |
| `chk-sequence-cache` | sequence.cache |  | "\"默认创建的sequence的cache为1，导致在并发COPY入库时，CN频繁与GTM建连，且多个并发之间存在轻量锁争抢，导致数据同步效率低\"" | 1 |
| `chk-session-timeout` | session_timeout |  | "`non-active的个数表示空闲连接数，例如，non-active为508，说明当前有大量的空闲连接。`" | 1 |
| `chk-shared-buffers` | shared_buffers |  | "\"共享缓存区不足，导致SQL的buffer命中率低\"","\"shared_buffers配置过小，导致buffer淘汰频繁。\"","\"内存参数设置不合理\"" | 5 |
| `chk-skew-option` | skew_option |  | "由于倾斜节点所需要运算的数据量远大于其它节点，导致倾斜节点降低系统整体性能","\"倾斜节点需要处理更多的数据，导致倾斜节点的计算性能远低于其他节点\"" | 2 |
| `chk-table-skewness-warning-rows` | table_skewness_warning_rows |  |  | 1 |
| `chk-table-skewness-warning-threshold` | table_skewness_warning_threshold |  |  | 1 |
| `chk-temp-file-limit` | temp_file_limit |  | "`防止下盘文件将磁盘空间占满，超过该值将报错退出`" | 1 |
| `chk-thread-pool-attr` | thread_pool_attr |  | "\"线程池worker参数thread_pool_attr设置过小，导致业务排队。\"" | 1 |
| `chk-track-activities` | track_activities |  |  | 1 |
| `chk-ttl` | ttl |  | "\"普通分区表无法...清理过期分区\"" | 1 |
| `chk-vacuum-defer-cleanup-age` | vacuum_defer_cleanup_age |  | "\"表示最近8000个事务产生的脏数据不进行回收\"" | 1 |
| `chk-work-mem` | work_mem |  | "\"如果work_mem所限定的物理内存不够，算子运算的数据将被写入临时表空间，会带来5-10倍的性能下降。\"","`可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差`","\"排序等算子可使用的work_mem过小，导致异常下盘过多\"","\"导致性能较差。\"","`当内存使用超过该 | 8 |

---

## collection_layer = `db-shell` (19 check)

### type=metric (19 个)

| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |
|---|---|---|---|---:|
| `chk-bucket` | 入库分区数 / Bucket 数 / 攒批内存消耗 | "单并发攒批消耗： #Np * #Nb * #Nr 单并发攒批内存消耗： partition_max_cache_size， 默认2GB" | "\"假设一次copy数据，涉及1000个分区，#Nb≈10, 单条记录大小1K，攒批大小10000行 单并发攒批消耗： 1000 * 10 * 1K * 1000" | 1 |
| `chk-commit-rollback-i-o` | COMMIT/ROLLBACK 频率与 I/O 开销 | 事务的COMMIT和ROLLBACK操作需要同步数据库的元数据和日志，频繁执行可能增加I/O开销，从而影响性能。 | "频繁执行可能增加I/O开销，从而影响性能。" | 1 |
| `chk-copy` | COPY 导入是否存在约束冲突类容错需求 | "gaussdb=# SET a_format_load_with_constraints_violation = 's2';" | "\"支持的约束冲突类型包括：非空约束、条件约束、主键约束、唯一性约束以及唯一性索引。\"" | 1 |
| `chk-dn` | 各DN数据量分布 | `SELECT pg_get_tabledef('customer_t1');` | "> 10%" | 1 |
| `chk-dn` | 磁盘利用率各 DN 差异 | `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like  | "> 5% 差值" | 1 |
| `chk-dws-connector-connectiontimeout` | DWS-Connector connectionTimeOut 默认值 | `DWS-Connector默认超时时间connectionTimeOut为5min，可调大该值。` | "5min (默认值过小)" | 1 |
| `chk-enable-codegen` | enable_codegen 参数状态 | `SHOW turbo_engine_version;` | "NULL" | 1 |
| `chk-exception` | 存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销 | "每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。" | "\"频繁地捕获和处理异常可能会导致性能下降。每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。\"" | 1 |
| `chk-max-process-memory-shared-buffers` | 内存参数：max_process_memory, shared_buffers | "检查内存相关参数，设置不合理" | "\"单节点总内存大小为256G，max_process_memory为12G，设置过小，shared_buffers为32M，设置过小\"" | 1 |
| `chk-null-002` | 存储过程默认权限模式 | "存储过程默认具有SECURITYINVOKER权限。" | "\"切换test_user2执行test_user1创建的存储过程，执行报错，对表user1_tb没有权限，因为执行存储过程默认使用调用者的权限。\"" | 1 |
| `chk-null-009` | 写入方式 | "如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈" | "\"如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈\"" | 1 |
| `chk-null-011` | 表倾斜情况 | `SELECT table_skewness('table name');` | "NULL" | 1 |
| `chk-pck` | 表定义是否存在PCK | `SELECT * FROM pg_get_tabledef('table name');` | "\"回显中存在\\\"PARTIAL CLUSTER KEY\\\"信息，表示存在PCK。\"" | 1 |
| `chk-psort-work-mem` | psort_work_mem 参数值 | `show psort_work_mem;` | "\"查看psort_work_mem是否设置过小\"" | 1 |
| `chk-savepoint` | 存储过程中 SAVEPOINT 的创建/释放配对 | 在使用完SAVEPOINT后，应及时使用RELEASE SAVEPOINT来释放资源。 | "同名的SAVEPOINT不会覆盖，而是会重新创建，这可能导致资源迅速累积。" | 1 |
| `chk-session-package` | SESSION 中 PACKAGE 变量数量与内存占用 | "PACKAGE变量是在PACKAGE内定义的全局变量，其生命周期覆盖整个数据库会话（SESSION）。" | "\"大量PACKAGE变量在SESSION中缓存可能占用大量内存。\"" | 1 |
| `chk-table-skewness-table-distribution` | table_skewness / table_distribution · 表数据倾斜率 | `SELECT table_skewness('store_sales')` | "\"某些DN有22831616行，其他DN都是0行，数据有严重倾斜\"" | 1 |
| `chk-vacuum-defer-cleanup-age` | vacuum_defer_cleanup_age 参数值 | "参数vacuum_defer_cleanup_age不是0，该参数在老版本默认为8000，表示最近8000个事务产生的脏数据不进行回收。" | "vacuum_defer_cleanup_age != 0" | 1 |
| `chk-vs` | 列存表物理大小 vs 有效数据量 | NULL | "\"多次对列存表UPDATE，发现表大小膨胀了十多倍。\"" | 1 |

---

## collection_layer = `db-internal-counter` (15 check)

### type=metric (15 个)

| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |
|---|---|---|---|---:|
| `chk-io-bandwidth-usage` | io_bandwidth_usage | 磁盘io带宽占用率 | "> 80% sustained 3 cycles" | 1 |
| `chk-iops-usage` | iops_usage | IOPS使用率 | "> 80% sustained 3 cycles" | 1 |
| `chk-rds001-cpu-util` | rds001_cpu_util | CPU使用率 | "> 80% sustained 3 cycles" | 1 |
| `chk-rds002-mem-util` | rds002_mem_util | 内存使用率 | "> 90% sustained 3 cycles" | 1 |
| `chk-rds007-instance-disk-usage` | rds007_instance_disk_usage | 实例数据磁盘已使用百分比 | "> 75%" | 1 |
| `chk-rds020-avg-disk-ms-per-write` | rds020_avg_disk_ms_per_write | 数据磁盘单次写入花费的时间 | "> 8 ms" | 1 |
| `chk-rds021-avg-disk-ms-per-read` | rds021_avg_disk_ms_per_read | 数据磁盘单次读取花费的时间 | "> 8 ms" | 1 |
| `chk-rds036-deadlocks` | rds036_deadlocks | 死锁次数 | "> 5 Counts / period" | 1 |
| `chk-rds048-p80` | rds048_P80 | 80% SQL的响应时间 | "> 10000000 us" | 1 |
| `chk-rds049-p95` | rds049_P95 | 95% SQL的响应时间 | "> 15000000 us" | 1 |
| `chk-rds060-long-running-transaction-exectime` | rds060_long_running_transaction_exectime | 数据库最长事务的执行时长 | "> 7200s" | 1 |
| `chk-rds063-slowquery-user` | rds063_slowquery_user | 用户库慢SQL数量 | "> 15 Counts / period" | 1 |
| `chk-rds065-dynamic-used-memory-usage` | rds065_dynamic_used_memory_usage | 动态内存使用率 | "> 80%" | 1 |
| `chk-rds066-replication-slot-wal-log-size` | rds066_replication_slot_wal_log_size | 复制槽保留的WAL日志大小 | "> 10% of disk size" | 1 |
| `chk-rds070-thread-pool` | rds070_thread_pool | 线程池使用率 | "> 85%" | 1 |

---

## collection_layer = `log-grep` (13 check)

### type=metric (13 个)

| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |
|---|---|---|---|---:|
| `chk-abort-transaction-due-to-concurrent-update` | 数据库错误日志 · abort transaction due to concurrent update | NULL | "\"并发更新同一条记录发生冲突不会等待锁，直接报错：abort transaction due to concurrent update\"" | 1 |
| `chk-be-datarow-select-count` | <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小 | "查看日志，如果<=BE DataRow日志出现次数过多，或直接执行SELECT count(*);" | "\"查询结果数目过大，则判断为结果集过大。\"" | 1 |
| `chk-cn` | CN日志中不下推原因 | "不下推语句在pg_log中会打印不下推的原因。LOG: SQL can't be shipped, reason: ..." | "\"LOG: SQL can't be shipped, reason: With-Recursive does not contain \\\"ALL\\\" to b" | 1 |
| `chk-cn` | CN日志 · 不下推原因 | "不下推语句在pg_log中会打印不下推的原因，上述语句在CN的日志中会找到类似以下的日志。" | "\"不下推语句在pg_log中会打印不下推的原因\"" | 1 |
| `chk-cn-pg-log-warning` | CN pg_log 日志中 Warning 信息 | NULL | "\"在CN的pg_log日志中也会有类似的Warning信息。同时，E-rows会比实际值小很多。\"" | 1 |
| `chk-dn-warning` | DN 间导入行数倾斜率(WARNING) | `WARNING:  Skewness occurs, table name: xxx, min value: xxx, max value: xxx, sum value: xxx, avg value: xxx, skew ratio: xxx` | "skew ratio > table_skewness_warning_threshold" | 1 |
| `chk-evs` | EVS 磁盘空间占用百分比 | "日志中会出现\"Disk usage on the node %u has reached the read-only threshold 90%\"" | "\"> 90%\"" | 1 |
| `chk-fe-sync-be-parsecomplete` | FE=>Sync 与 <=BE ParseComplete 日志时间间隔 | "用户可查看FE=> Syncr日志和<=BE ParseComplete日志之间的时间间隔" | "\"如果时间间隔较久，则判断为数据库执行慢。\"" | 1 |
| `chk-gds` | GDS导入作业日志 | "检测GDS导入作业的日志，查看是否有执行失败的现象。" | "\"在导入数据失败后，占用的磁盘空间没有释放。\"" | 1 |
| `chk-modifyjdbccall-createparameterizedquery` | modifyJdbcCall / createParameterizedQuery 阶段耗时 | "如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。" | "\"如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为pr" | 1 |
| `chk-pg-log` | pg_log 统计信息缺失日志 | "可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。" | "\"LOG:Statistics in some tables or columns(...) are not collected.\"" | 1 |
| `chk-pg-log-statistics-not-collected` | pg_log 日志 · Statistics not collected 日志行 | `可以通过在pg_log目录下的日志文件中查找以下信息来确认当前执行的query是否由于没有收集统计信息导致查询性能变差。` | "`LOG:Statistics in some tables or columns(...) are not collected.`" | 1 |
| `chk-pg-log-statistics-warning` | pg_log 日志中的 Statistics WARNING | NULL | "\"可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。\"" | 1 |

---

## collection_layer = `os` (11 check)

### type=metric (11 个)

| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |
|---|---|---|---|---:|
| `chk-base-pgsql-tmp-pgsql-tmp-queryid-pid` | base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件 | `下盘文件位于实例目录的base/pgsql_tmp路径下，下盘文件以 pgsql_tmp$queryid_$pid 命名` | "`下盘文件位于实例目录的base/pgsql_tmp路径下`" | 1 |
| `chk-cpu-1-3-12-24` | 节点 CPU 使用率 (1/3/12/24 小时) | 选择“监控 > 节点监控 > 概览”可查看当前集群各节点CPU使用率的具体情况，单击最右的监控按钮，查看最近1/3/12/24小时的CPU性能指标 | "判断是否有CPU使用率突然增大的情况。" | 1 |
| `chk-dn` | 各DN磁盘利用率 | `gs_ssh –c "df -h"` | "> 5%差异" | 1 |
| `chk-dn-cpu` | 备DN CPU使用率 · 回放线程资源 | "极致RTO采用了多个page redo线程并行加速回放进度。当备DN回放追平主DN，空载的情况下，单个page redo线程的CPU消耗大约在15%左右（实际值与具体硬件和参数配置相关），备DN回放的总CPU消耗值 = 单个page redo线程的CPU消耗值 x page redo线程数。" | "> 70%" | 1 |
| `chk-gstack-vecnestloopruntime` | gstack · 进程堆栈中 VecNestLoopRuntime | `联系运维人员登录到相应的实例节点上，打印等待状态为none的线程堆栈信息` | "`堆栈中有VecNestLoopRuntime，结合执行计划，初步判断是由于统计信息不准，优化器评估结果集较少，执行计划使用了NestLoop导致性能下降。`" | 1 |
| `chk-i-o-cpu` | 系统资源 I/O / 内存 / CPU 使用情况 | `排查当前的I/O、内存、CPU使用情况，没有发现资源占用高的情况。` | "NULL" | 1 |
| `chk-iostat-util-r-await-w-await` | iostat 中 %util / r_await / w_await | "iostat" | "\"%util 接近 100% 或 await > 3ms\"" | 1 |
| `chk-pidstat-iotop-i-o` | pidstat / iotop 显示线程 I/O 消耗 | "pidstat -dt -p gaussdb进程号" | "\"通常是TPLworker线程消耗的I/O读写量异常，代表用户SQL消耗I/O多\"" | 1 |
| `chk-top-gsql-cpu` | top · gsql 进程 CPU 占用 | `top 命令显示 gsql 进程占用率高` | "`数据库节点CPU持续满载，top 命令显示 gsql 进程占用率高`" | 1 |
| `chk-top-sar-gaussdb-cpu` | top / sar 中 gaussdb 进程 CPU 占用 | "$ top" | "\"10678 Ruby      20   0   54.8g  38.2g  34.6g S  1398 20.3 126085:50 gaussdb\"" | 1 |
| `chk-vecnestloopruntime` | 进程堆栈（VecNestLoopRuntime） | `gstack 14104` | "\"堆栈中有VecNestLoopRuntime，以及结合执行计划，初步判断是由于统计信息不准，优化器评估结果集较少，计划走了nestloop导致性能下降。\"" | 1 |

---

## collection_layer = `flamegraph` (2 check)

### type=metric (2 个)

| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |
|---|---|---|---|---:|
| `chk-gaussdb` | GaussDB内置火焰图 · 时区加载线程占比 | "GaussDB在内核505版本中内置了火焰图工具，默认每5分钟会自动采集一次，保存在$GAUSSLOG/gs_flamegraph/{datanode}路径下，详细信息可参考GaussDB产品文档《内置perf工具》章节。" | "> 40%" | 1 |
| `chk-null-001` | 内核代码热点函数火焰图 | "如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点" | "\"如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点\"" | 1 |

---
