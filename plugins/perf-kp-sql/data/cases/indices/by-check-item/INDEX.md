# Check Items Index · 指标集合

> 生成时间: 2026-05-29T09:18:14.072Z
> 数据源: 派生于 cases/CASES.md (每条 case 的 diagnostic_steps[*].metric_name + likely_causes.parameter_causes[*])
> 总计: 655 checks (metric 429 / param 226)
> 配套: cases/indices/by-check-item/CASES.md

## metric (429)

| check_id | metric_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-proc-cmdline-nohz-off | /proc/cmdline 中是否含 `nohz=off` | 1 | 9 |
| chk-timer-tick | timer_tick 调度次数(单位时间内) | 1 | 18 |
| chk-dtlb-load-misses-itlb-load-misses | dTLB-load-misses 比率 / iTLB-load-misses 比率 | 1 | 27 |
| chk-tps-vs | TPS / 业务吞吐 vs 线程并发数 | 1 | 36 |
| chk-mount-options | mount.options | 1 | 45 |
| chk-sysctl-net-7-keys | sysctl.net.* (7 keys) | 1 | 54 |
| chk-sysctl-net-8-keys | sysctl.net.* (8 keys) | 1 | 63 |
| chk-bios-advanced-misc-config-support-smmu | bios.advanced.misc_config.support_smmu | 1 | 4006 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 4014 |
| chk-systemd-unit-irqbalance-service-active-state | systemd.unit.irqbalance.service.active_state | 1 | 90 |
| chk-proc-interrupts-smp-affinity-list | proc.interrupts.smp_affinity_list | 1 | 99 |
| chk-blockdev-queue-nr-requests | blockdev.queue.nr_requests | 1 | 108 |
| chk-libvirt-domain-cputune-vcpupin | libvirt.domain.cputune.vcpupin | 1 | 4046 |
| chk-sys-node-meminfo-hugepages | sys.node.meminfo.hugepages | 1 | 126 |
| chk-numa | 进程 NUMA 亲和绑定状态 | 1 | 135 |
| chk-nic-irq-cpu-core | NIC IRQ → CPU core 绑定分布 | 1 | 144 |
| chk-nic-interrupt-coalescing-settings-rx-tx-usecs-rx-tx-frames-a | NIC interrupt coalescing settings (rx/tx-usecs, rx/tx-frames, adaptive-rx/tx) | 1 | 153 |
| chk-rps-configuration-rps-cpus-mask-flow-tables | RPS configuration (rps_cpus mask, flow tables) | 1 | 162 |
| chk-disk-await-time-vm-dirty-params | disk await time + vm dirty params | 1 | 171 |
| chk-block-device-i-o-scheduler | block device I/O scheduler | 1 | 180 |
| chk-mount-options-for-filesystem | mount options for filesystem | 1 | 189 |
| chk-filesystem-type-blocksize | filesystem type + blocksize | 1 | 198 |
| chk-perf-top-top-n-functions | perf top top-N functions（关注锁/原子操作类） | 1 | 207 |
| chk-l1-l2-l3-cache-miss-false-sharing-event | L1/L2/L3 cache miss + false-sharing event | 1 | 216 |
| chk-vm-dirty-ratio-vm-dirty-background-ratio | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 4174 |
| chk-kernel-boot-option-transparent-hugepage | kernel boot option transparent_hugepage | 1 | 234 |
| chk-block-device-read-ahead-kb-sectors | block device read_ahead_kb / sectors | 1 | 243 |
| chk-dbe-perf-statement-cpu-time | dbe_perf.statement.cpu_time | 1 | 252 |
| chk-explain-analyze | explain analyze 执行计划分析 | 1 | 2547 |
| chk-gaussdb | GaussDB内置火焰图 · 时区加载线程占比 | 1 | 270 |
| chk-buffer-wdr | buffer命中率 (WDR报告或管控平台) | 1 | 279 |
| chk-explain-analyze | EXPLAIN ANALYZE 算子落盘标志 | 1 | 2547 |
| chk-dbe-perf-statement-cpu-time-cpu | dbe_perf.statement.cpu_time (持续CPU高) | 1 | 297 |
| chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu | pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高) | 1 | 306 |
| chk-statement-history-cpu-time-vs-db-time | statement_history.cpu_time vs db_time | 1 | 315 |
| chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io | dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高) | 1 | 324 |
| chk-pg-thread-wait-status-wait-status-wait-event-io | pg_thread_wait_status.wait_status / wait_event (当前IO高) | 1 | 333 |
| chk-statement-history-data-io-time-sql-io | statement_history.data_io_time (慢SQL IO分析) | 1 | 342 |
| chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam | dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory | 1 | 351 |
| chk-dbe-perf-session-memory-detail-dynamic-used-shrctx | dbe_perf.session_memory_detail (dynamic_used_shrctx较小时) | 1 | 360 |
| chk-dbe-perf-shared-memory-detail-dynamic-used-shrctx | dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时) | 1 | 369 |
| chk-dbe-perf-local-active-session | dbe_perf.local_active_session (秒级抖动) | 1 | 378 |
| chk-gs-asp | gs_asp (两天内秒级抖动) | 1 | 387 |
| chk-data-node-scan | 执行计划下推标识（Data Node Scan） | 1 | 396 |
| chk-pg-proc-provolatile-proshippable | pg_proc.provolatile / proshippable | 3 | 405 |
| chk-explain-verbose-remotequery | explain verbose · RemoteQuery 计划 | 1 | 414 |
| chk-explain-verbose-subplan | explain verbose · SubPlan 执行方式 | 1 | 549 |
| chk- | 执行计划下推标识 | 2 | 2763 |
| chk-pg-proc-provolatile | pg_proc.provolatile | 1 | 441 |
| chk-explain-verbose-warning | explain verbose WARNING · 统计信息缺失提示 | 1 | 1791 |
| chk-explain-nest-loop-join | EXPLAIN 执行计划 · Nest Loop Join 耗时 | 1 | 459 |
| chk-enable-hashjoin | enable_hashjoin 关闭后执行计划 | 1 | 4225 |
| chk-explain-verbose-warning | EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表 | 1 | 1791 |
| chk-pg-log-statistics-not-collected | pg_log 日志 · Statistics not collected 日志行 | 1 | 486 |
| chk-explain-join | EXPLAIN 执行计划 · Join 算子类型及耗时 | 1 | 1053 |
| chk-explain-analyze-a-time-rows-removed-by-filter | explain analyze · A-time / Rows Removed by Filter | 1 | 504 |
| chk-explain-analyze-nested-loop-a-time | explain analyze · Nested Loop A-time | 1 | 513 |
| chk-explain-analyze-groupaggregate-a-time-vs-hashaggregate | explain analyze · GroupAggregate A-time vs HashAggregate | 1 | 522 |
| chk-explain-analyze-a-time | EXPLAIN ANALYZE A-time 瓶颈算子识别 | 1 | 531 |
| chk-explain-verbose-streaming-vs-data-node-scan | EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan | 1 | 540 |
| chk-explain-verbose-subplan | EXPLAIN VERBOSE · SubPlan 算子出现在目标列 | 1 | 549 |
| chk-pg-stat-get-last-data-changed-time | 近期数据变更表列表（pg_stat_get_last_data_changed_time） | 1 | 954 |
| chk-pgxc-get-table-skewness | PGXC_GET_TABLE_SKEWNESS | 2 | 2322 |
| chk-table-distribution-dn-1w | table_distribution() 各DN空间（大表个数超1W场景） | 1 | 576 |
| chk-savepoint | 存储过程中 SAVEPOINT 的创建/释放配对 | 1 | 585 |
| chk-commit-rollback-i-o | COMMIT/ROLLBACK 频率与 I/O 开销 | 1 | 594 |
| chk-explain-analyze-seq-scan-a-time-total-runtime | EXPLAIN ANALYZE Seq Scan A-time / Total runtime | 1 | 603 |
| chk-b-tree-explain-analyze | 创建 B-tree 索引后再次 EXPLAIN ANALYZE | 1 | 612 |
| chk-explain-verbose-warning | EXPLAIN VERBOSE 执行计划 Warning | 2 | 1791 |
| chk-pg-log-statistics-warning | pg_log 日志中的 Statistics WARNING | 1 | 630 |
| chk-explain-analyze-a-time-seqscan-vs-indexscan | EXPLAIN ANALYZE A-time · SeqScan vs IndexScan | 1 | 639 |
| chk-explain-analyze-a-time-nestloop | EXPLAIN ANALYZE A-time · NestLoop算子耗时 | 1 | 648 |
| chk-explain-analyze-a-time-sort-groupagg-vs-hashagg | EXPLAIN ANALYZE A-time · Sort+GroupAgg vs HashAgg | 1 | 657 |
| chk-explain-analyze | EXPLAIN ANALYZE 执行计划 · 算子耗时 | 1 | 2547 |
| chk-explain-analyze-nestloop | EXPLAIN ANALYZE · NestLoop 算子耗时 | 1 | 675 |
| chk-explain-analyze-sort-groupagg | EXPLAIN ANALYZE · Sort+GroupAgg 算子耗时 | 1 | 684 |
| chk-hashaggregate | 执行计划中双层HashAggregate | 1 | 693 |
| chk- | 执行计划子查询关联方式 | 1 | 2763 |
| chk-subplan | 执行计划中SubPlan节点 | 2 | 711 |
| chk-explain-analyze-total-runtime-partitionscan | EXPLAIN ANALYZE Total runtime / 是否走 PartitionScan | 1 | 720 |
| chk-local-explain-analyze-total-runtime | 创建 LOCAL 索引后 EXPLAIN ANALYZE Total runtime | 1 | 729 |
| chk-rds001-cpu-util | rds001_cpu_util | 1 | 738 |
| chk-rds002-mem-util | rds002_mem_util | 1 | 747 |
| chk-io-bandwidth-usage | io_bandwidth_usage | 1 | 756 |
| chk-iops-usage | iops_usage | 1 | 765 |
| chk-rds007-instance-disk-usage | rds007_instance_disk_usage | 1 | 774 |
| chk-rds020-avg-disk-ms-per-write | rds020_avg_disk_ms_per_write | 1 | 783 |
| chk-rds021-avg-disk-ms-per-read | rds021_avg_disk_ms_per_read | 1 | 792 |
| chk-rds036-deadlocks | rds036_deadlocks | 1 | 801 |
| chk-rds048-p80 | rds048_P80 | 1 | 810 |
| chk-rds049-p95 | rds049_P95 | 1 | 819 |
| chk-rds060-long-running-transaction-exectime | rds060_long_running_transaction_exectime | 1 | 828 |
| chk-rds063-slowquery-user | rds063_slowquery_user | 1 | 837 |
| chk-rds065-dynamic-used-memory-usage | rds065_dynamic_used_memory_usage | 1 | 846 |
| chk-rds066-replication-slot-wal-log-size | rds066_replication_slot_wal_log_size | 1 | 855 |
| chk-rds070-thread-pool | rds070_thread_pool | 1 | 864 |
| chk-explain-agg | EXPLAIN 执行计划 Agg 算子模式 | 1 | 873 |
| chk-copy | COPY 导入是否存在约束冲突类容错需求 | 1 | 2700 |
| chk-explain-verbose-anti-join | EXPLAIN VERBOSE Anti Join 行数估算 | 1 | 2349 |
| chk-explain-verbose-hashjoin | EXPLAIN VERBOSE hashjoin 行数估算 | 1 | 2358 |
| chk-top-gsql-cpu | top · gsql 进程 CPU 占用 | 1 | 909 |
| chk-pg-stat-statements-total-time-calls | pg_stat_statements · total_time + calls (慢查询统计) | 1 | 918 |
| chk-explain-performance-dn | explain performance 各 DN 实际行数 | 1 | 1980 |
| chk-table-skewness-dn | table_skewness() 各 DN 数据分布比例 | 1 | 936 |
| chk-explain-analyze-streaming-redistribute-dn | EXPLAIN ANALYZE Streaming(REDISTRIBUTE) 各 DN 输出行数 | 1 | 945 |
| chk-pg-stat-get-last-data-changed-time | pg_stat_get_last_data_changed_time 最近变更的表 | 1 | 954 |
| chk-table-distribution-dn | table_distribution() 各 DN 存储空间分布 | 1 | 2196 |
| chk-xc-node-id | 按 xc_node_id 分组的表数据行数 | 1 | 972 |
| chk-explain-streaming | EXPLAIN 计划是否含 Streaming | 1 | 990 |
| chk-explain-streaming | 调整后 EXPLAIN 是否消除 Streaming | 1 | 990 |
| chk-explain-groupagg-sort | EXPLAIN · 算子(GroupAgg+Sort) | 1 | 999 |
| chk-explain-analyze-hashjoin-dn | EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围 | 1 | 1008 |
| chk-memory-information-dn | Memory Information 各 DN 内存消耗分布 | 1 | 1017 |
| chk-seq-scan-dn | Seq Scan 各 DN 扫描时间 | 1 | 1026 |
| chk-explain-analyze | EXPLAIN ANALYZE 顺序扫描耗时 | 1 | 2547 |
| chk-explain-seqscan-vs-indexscan | EXPLAIN · 算子(seqscan vs indexscan) | 1 | 1044 |
| chk-explain-join | EXPLAIN 执行计划 Join 类型 | 1 | 1053 |
| chk-explain-analyze | EXPLAIN ANALYZE 执行计划耗时与过滤行数 | 1 | 2547 |
| chk-explain-analyze-join | EXPLAIN ANALYZE Join 算子类型与耗时 | 1 | 2556 |
| chk-explain-analyze-agg | EXPLAIN ANALYZE Agg 算子类型 | 1 | 2565 |
| chk-iostat-util-r-await-w-await | iostat 中 %util / r_await / w_await | 1 | 1089 |
| chk-pidstat-iotop-i-o | pidstat / iotop 显示线程 I/O 消耗 | 1 | 1098 |
| chk-pg-thread-wait-status-pg-stat-activity-i-o-sql | pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL | 1 | 1107 |
| chk-top-sar-gaussdb-cpu | top / sar 中 gaussdb 进程 CPU 占用 | 1 | 1116 |
| chk-wdr-top-sql-order-by-cpu-time | WDR 报告 Top SQL order by CPU Time | 1 | 1125 |
| chk- | 内核代码热点函数火焰图 | 1 | 2763 |
| chk-guc-shared-buffers-work-mem-thread-pool-attr | GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值 | 1 | 1143 |
| chk-session-package | SESSION 中 PACKAGE 变量数量与内存占用 | 1 | 1152 |
| chk-explain-filter | EXPLAIN 执行计划 Filter 条件分析 | 1 | 1161 |
| chk-pg-proc-volatility | pg_proc 函数 volatility 类型查询 | 1 | 1170 |
| chk-explain | EXPLAIN 执行计划算子估算行数 | 1 | 2484 |
| chk-explain-stream | EXPLAIN 执行计划 Stream 算子类型 | 1 | 1188 |
| chk-exception | 存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销 | 1 | 1197 |
| chk- | 存储过程默认权限模式 | 1 | 2763 |
| chk-explain-remotequery-data-node-scan | EXPLAIN · 是否含 RemoteQuery / Data Node Scan | 1 | 1215 |
| chk-explain-performance | EXPLAIN PERFORMANCE 算子耗时 | 1 | 2817 |
| chk-scan-filter | Scan filter 条件分析 | 1 | 1233 |
| chk-explain-cn-vs-dn | EXPLAIN 执行计划算子位置（CN vs DN） | 1 | 1242 |
| chk-group-by-groupagg-sort | GROUP BY 查询计划中是否包含 GroupAgg+Sort | 1 | 1251 |
| chk-not-in | 含 NOT IN 子查询的执行计划 | 1 | 1260 |
| chk-explain | EXPLAIN · 计划与实际行数比对 | 1 | 2484 |
| chk-explain-data-node-scan-on | EXPLAIN 输出中 "Data Node Scan on" 是否在第一行 | 1 | 1278 |
| chk-explain-subplan | EXPLAIN 执行计划 SubPlan 存在 | 1 | 1287 |
| chk-dn-cpu | 备DN CPU使用率 · 回放线程资源 | 1 | 1296 |
| chk-explain-verbose | EXPLAIN VERBOSE 统计信息警告 | 1 | 1305 |
| chk-pg-log | pg_log 统计信息缺失日志 | 1 | 1314 |
| chk- | 执行计划子查询处理方式 | 1 | 2763 |
| chk-explain-analyze-stream | EXPLAIN ANALYZE · Stream算子类型 | 1 | 1332 |
| chk-explain-analyze-startup-vs-total | EXPLAIN ANALYZE · 路径代价 (Startup vs Total) | 1 | 1341 |
| chk-nestloop | 语句执行时间 / 执行计划中 NestLoop 算子 | 1 | 2034 |
| chk-pgxc-wlm-session-history-block-time-duration | pgxc_wlm_session_history · block_time / duration | 1 | 1359 |
| chk-pgxc-wlm-session-history | pgxc_wlm_session_history · 同期并发作业数 | 1 | 1368 |
| chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn- | pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent | 1 | 1377 |
| chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ | GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write | 1 | 1386 |
| chk-explain-performance-windowagg-sort | EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时 | 1 | 1395 |
| chk-explain-performance-sql-streaming-redistribute | EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜） | 1 | 1404 |
| chk-order-line-id-null | 列统计信息 · ORDER_LINE_ID NULL 比例 | 1 | 1413 |
| chk-pgxc-wlm-session-history-dataskew-warning | pgxc_wlm_session_history · DataSkew warning | 1 | 1422 |
| chk-pgxc-wlm-session-history-large-table-in-broadcast-warning | pgxc_wlm_session_history · Large Table in Broadcast warning | 1 | 1431 |
| chk-pgxc-wlm-session-history-spill | pgxc_wlm_session_history · Spill告警 | 1 | 1440 |
| chk-pgxc-wlm-session-history-nestloop | pgxc_wlm_session_history · NestLoop大表告警 | 1 | 1449 |
| chk-dn | 各DN磁盘利用率 | 1 | 2367 |
| chk-pgxc-thread-wait-status-wait-status | pgxc_thread_wait_status.wait_status | 1 | 1467 |
| chk-table-skewness-table-distribution | table_skewness / table_distribution | 1 | 2385 |
| chk-warning | 执行计划统计信息Warning | 1 | 1485 |
| chk-remote | 执行计划下推标识（__REMOTE关键字） | 1 | 1494 |
| chk-nestloop | 执行计划算子类型（NestLoop） | 1 | 2034 |
| chk-partitioned-cstore-scan | 执行计划：Partitioned CStore Scan分区扫描范围 | 1 | 1512 |
| chk- | 线程等待状态 | 1 | 2763 |
| chk-vecnestloopruntime | 进程堆栈（VecNestLoopRuntime） | 1 | 1530 |
| chk-sql-create-index | 活跃SQL及CREATE INDEX语句 | 1 | 1539 |
| chk- | 表数据倾斜 | 1 | 2763 |
| chk-max-process-memory-shared-buffers | 内存参数：max_process_memory, shared_buffers | 1 | 1557 |
| chk-in | 执行计划in条件处理方式 | 1 | 1566 |
| chk-sql-case-when | SQL 中 CASE WHEN 分支数量与执行次数 | 1 | 1575 |
| chk- | 系统表/用户表膨胀情况 | 1 | 2763 |
| chk-dn-xc-node-id | 各 DN 数据量分布 (xc_node_id 分组) | 1 | 1593 |
| chk-pgxc-stat-table-dirty | 表脏页率 (PGXC_STAT_TABLE_DIRTY) | 1 | 1602 |
| chk-gds | GDS导入作业日志 | 1 | 1611 |
| chk-fe-sync-be-parsecomplete | FE=>Sync 与 <=BE ParseComplete 日志时间间隔 | 1 | 1620 |
| chk-be-datarow-select-count | <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小 | 1 | 1629 |
| chk-modifyjdbccall-createparameterizedquery | modifyJdbcCall / createParameterizedQuery 阶段耗时 | 1 | 1638 |
| chk-period-ttl | 分区表 period / ttl 参数设置 | 1 | 1647 |
| chk-analyze | ANALYZE 后的查询性能 | 1 | 1656 |
| chk- | 查询返回行数 | 1 | 2763 |
| chk- | 主机负载下查询单独运行时延 | 1 | 2763 |
| chk- | 重复执行同一查询语句的执行时间 | 1 | 2763 |
| chk-disk-cache-pgxc-disk-cache-all-stats | Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats) | 1 | 1692 |
| chk-evs | EVS 磁盘空间占用百分比 | 1 | 1701 |
| chk-bucket | 入库分区数 / Bucket 数 / 攒批内存消耗 | 1 | 1710 |
| chk-pgxc-get-stat-all-tables-dirty-page-rate | PGXC_GET_STAT_ALL_TABLES.dirty_page_rate | 2 | 1719 |
| chk-explain-index-scan | EXPLAIN 执行计划 · 是否使用Index Scan | 1 | 1728 |
| chk-explain-indexscan | EXPLAIN 执行计划 · 是否选择IndexScan | 1 | 1737 |
| chk-explain-verbose-index-scan-vs-seq-scan | EXPLAIN VERBOSE · Index Scan vs Seq Scan | 1 | 1746 |
| chk-waiting-in-queue | 查询等待状态 · waiting in queue | 1 | 1755 |
| chk-explain-or-filter | EXPLAIN 执行计划 · 系统视图权限OR filter | 1 | 1764 |
| chk-dn | 各DN数据量分布 | 1 | 2367 |
| chk-cn | CN日志中不下推原因 | 1 | 2025 |
| chk-explain-verbose-warning | EXPLAIN VERBOSE WARNING信息 · 统计信息缺失 | 1 | 1791 |
| chk-hstore-delta-vs-cu | HStore Delta表大小 vs 主表CU数据 | 1 | 1800 |
| chk-enable-codegen | enable_codegen 参数状态 | 1 | 4491 |
| chk-pgxc-wlm-session-info-streaming-stream-count | pgxc_wlm_session_info · Streaming 算子数（stream_count） | 1 | 1818 |
| chk-pgxc-wlm-session-info-max-cpu-time-cpu | pgxc_wlm_session_info · max_cpu_time（高CPU语句） | 1 | 1827 |
| chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has | pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史） | 1 | 1836 |
| chk-resource-track-level-operator-realtime | resource_track_level · operator_realtime 级别实时算子监控 | 1 | 1845 |
| chk-pgxc-stat-activity-state-waiting-enqueue | PGXC_STAT_ACTIVITY · state / waiting / enqueue | 1 | 1854 |
| chk-pgxc-stat-activity-runtime-current-timestamp-query-start | PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start) | 1 | 1863 |
| chk-pgxc-stat-activity-waiting-true | PGXC_STAT_ACTIVITY · waiting=true 阻塞查询 | 1 | 1872 |
| chk-pg-locks | pg_locks · 阻塞会话与持锁会话关联 | 1 | 1881 |
| chk-dws-connector-connectiontimeout | DWS-Connector connectionTimeOut 默认值 | 1 | 1890 |
| chk-pgxc-lock-conflicts | pgxc_lock_conflicts 锁冲突视图 | 1 | 1899 |
| chk-pg-stat-activity-pg-locks-sql-8-0-x | pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本） | 1 | 1908 |
| chk- | 写入方式 | 1 | 2763 |
| chk-pgxc-stat-activity-state-waiting-query | pgxc_stat_activity · state / waiting / query | 1 | 1926 |
| chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic- | pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory | 1 | 1935 |
| chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc | pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent | 1 | 1944 |
| chk-vs | 列存表物理大小 vs 有效数据量 | 1 | 2106 |
| chk- | 各节点磁盘使用率均衡性 | 1 | 2763 |
| chk-pgxc-thread-wait-status-dn | pgxc_thread_wait_status · 作业等待 DN 分布 | 1 | 1971 |
| chk-explain-performance-dn | explain performance · DN 行数与耗时分布 | 1 | 1980 |
| chk-table-skewness | table_skewness · 数据倾斜率 | 1 | 1989 |
| chk-pgxc-get-table-skewness | pgxc_get_table_skewness · 全库倾斜视图 | 1 | 2322 |
| chk-cn-pg-log-warning | CN pg_log 日志中 Warning 信息 | 1 | 2007 |
| chk-explain-verbose-remote | EXPLAIN VERBOSE · __REMOTE 关键字 | 1 | 2016 |
| chk-cn | CN日志 · 不下推原因 | 1 | 2025 |
| chk-nestloop | 执行计划算子类型（NestLoop出现） | 1 | 2034 |
| chk-explain-partitioned-cstore-scan-selected-partitions | EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量 | 1 | 2043 |
| chk-i-o-cpu | 系统资源 I/O / 内存 / CPU 使用情况 | 1 | 2052 |
| chk-pg-thread-wait-status | pg_thread_wait_status · 线程等待状态 | 1 | 2061 |
| chk-gstack-vecnestloopruntime | gstack · 进程堆栈中 VecNestLoopRuntime | 1 | 2070 |
| chk-pg-stat-activity-sql | pg_stat_activity 活跃SQL | 2 | 2079 |
| chk- | 表倾斜情况 | 1 | 2763 |
| chk-max-process-memory-shared-buffers-work-mem | max_process_memory / shared_buffers / work_mem 内存参数 | 1 | 2097 |
| chk-vs | 脏数据膨胀率 / 表实际大小 vs 有效数据量 | 1 | 2106 |
| chk-explain | EXPLAIN执行计划耗时分布 | 1 | 2484 |
| chk-cstore-scan | 执行计划算子：CStore Scan耗时占比 | 1 | 2124 |
| chk-pg-session-wlmstat-status-statement-mem | pg_session_wlmstat · status / statement_mem | 1 | 2133 |
| chk-cudesc-cu-row-count | cudesc表中CU的row_count分布 | 1 | 2142 |
| chk-cu | 执行计划中CU扫描数量 | 1 | 2151 |
| chk-explain-cstore-scan-cusome-cunone | EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数 | 1 | 2160 |
| chk-explain-scan-vs | EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数 | 1 | 2169 |
| chk- | 表脏页率 | 1 | 2763 |
| chk-explain-scan-a-time-max-min-dn | EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比 | 1 | 2187 |
| chk-table-distribution-dn | table_distribution 各DN数据行数 | 1 | 2196 |
| chk-explain-seq-scan-vs-index-scan | EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan） | 1 | 2205 |
| chk-explain-selected-partitions | EXPLAIN 执行计划 · Selected Partitions 数量 | 1 | 2214 |
| chk-pgxc-thread-wait-status-wait-status-wait-event | pgxc_thread_wait_status · wait_status / wait_event | 1 | 2223 |
| chk-pg-partition | pg_partition 各表分区数 | 1 | 2232 |
| chk-pv-total-memory-detail-process-used-memory-vs-max-process-me | pv_total_memory_detail · process_used_memory vs max_process_memory | 1 | 2241 |
| chk-pgxc-lock-conflicts-8-1-x | pgxc_lock_conflicts 锁冲突（8.1.x及以上） | 1 | 2250 |
| chk-pgxc-stat-activity-vacuum-full-8-0-x | pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前） | 1 | 2259 |
| chk-pgxc-thread-wait-status | pgxc_thread_wait_status 锁等待状态 | 1 | 2268 |
| chk-pck | 表定义是否存在PCK | 1 | 2277 |
| chk-psort-work-mem | psort_work_mem 参数值 | 1 | 4551 |
| chk- | 列存表文件大小监控 | 1 | 2763 |
| chk-abort-transaction-due-to-concurrent-update | 数据库错误日志 · abort transaction due to concurrent update | 1 | 2304 |
| chk-dn | 各 DN 数据条数分布 | 1 | 2367 |
| chk-pgxc-get-table-skewness | PGXC_GET_TABLE_SKEWNESS 视图 | 1 | 2322 |
| chk-dms | DMS 监控 · 节点磁盘使用率 | 1 | 2331 |
| chk-explain-agg-hashagg-gather-vs-redistribute-hashagg | EXPLAIN · Agg 计划形态（hashagg+gather vs redistribute+hashagg） | 1 | 2340 |
| chk-explain-verbose-anti-join | EXPLAIN VERBOSE · Anti Join 执行计划及行数估算 | 1 | 2349 |
| chk-explain-verbose-hashjoin | EXPLAIN VERBOSE · HashJoin 行数估算偏差 | 1 | 2358 |
| chk-dn | 磁盘利用率各 DN 差异 | 1 | 2367 |
| chk-explain-performance-dn-scan | EXPLAIN PERFORMANCE 各 DN 基表 scan 行数及时间分布 | 1 | 2376 |
| chk-table-skewness-table-distribution | table_skewness / table_distribution · 表数据倾斜率 | 1 | 2385 |
| chk-explain-performance-stream-dn | EXPLAIN PERFORMANCE · Stream 算子各 DN 行数分布 | 1 | 2394 |
| chk-dms-max-min | DMS · 节点磁盘使用率排序 (max - min) | 1 | 2403 |
| chk-explain-streaming-type-redistribute | EXPLAIN · Streaming(type: REDISTRIBUTE) 算子是否出现 | 1 | 2412 |
| chk-cpu-1-3-12-24 | 节点 CPU 使用率 (1/3/12/24 小时) | 1 | 2421 |
| chk-cpu | 资源池 CPU 限额 / 配额配置 | 1 | 2430 |
| chk-pgxc-stat-activity-state | pgxc_stat_activity state 字段 | 1 | 2439 |
| chk-cn-savepoint-release | 各 CN 上 SAVEPOINT/RELEASE 语句分布 | 1 | 2448 |
| chk-explain-join-nestloop-vs-hashjoin | EXPLAIN · JOIN 算子类型 (NestLoop vs HashJoin) | 1 | 2457 |
| chk-explain-performance | EXPLAIN PERFORMANCE · 基表扫描方式及执行时间 | 1 | 2817 |
| chk-explain-in-join | EXPLAIN · in 条件是否转为 join | 1 | 2475 |
| chk-explain | EXPLAIN · 执行计划顺序扫描阶段耗时 | 1 | 2484 |
| chk-explain-verbose-not-in | EXPLAIN VERBOSE · NOT IN 执行计划算子类型 | 1 | 2493 |
| chk-explain-verbose-not-exists | EXPLAIN VERBOSE · NOT EXISTS 执行计划算子类型验证 | 1 | 2502 |
| chk-base-pgsql-tmp-pgsql-tmp-queryid-pid | base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件 | 1 | 2511 |
| chk-pgxc-thread-wait-status-wait-status-write-file | pgxc_thread_wait_status · wait_status='write file' | 1 | 2520 |
| chk-explain-performance-spill-written-disk-temp-file-num | EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字 | 1 | 2529 |
| chk-topsql-spill-info | TopSQL.spill_info | 1 | 2538 |
| chk-explain-analyze | EXPLAIN ANALYZE · 基表扫描算子类型及执行时间 | 1 | 2547 |
| chk-explain-analyze-join | EXPLAIN ANALYZE · JOIN 算子类型及执行时间 | 1 | 2556 |
| chk-explain-analyze-agg | EXPLAIN ANALYZE · Agg 算子类型及执行时间 | 1 | 2565 |
| chk-explain-analyze-verbose-sql-partition-iterator | EXPLAIN ANALYZE VERBOSE · SQL 自诊断信息 + Partition Iterator 扫描分区数 | 1 | 2574 |
| chk-explain-analyze-verbose-partition-iterator-iterations | EXPLAIN ANALYZE VERBOSE · 改写后 Partition Iterator Iterations | 1 | 2583 |
| chk-explain-performance-partition-iterator-iterations | EXPLAIN PERFORMANCE · 全表扫描时间及 Partition Iterator Iterations | 1 | 2592 |
| chk-explain-performance-cunone-filter | EXPLAIN PERFORMANCE · CUNone 比例及 filter 耗时 | 1 | 2601 |
| chk-explain-performance-cstore-scan-cu | EXPLAIN PERFORMANCE · CStore Scan CU 加载数量 | 1 | 2610 |
| chk-explain-performance | explain performance 执行时间 | 1 | 2817 |
| chk-leading-hint | 加 leading hint 后执行时间 | 1 | 2628 |
| chk-leading-no-nestloop-hint | 加 leading + no nestloop hint 后执行时间 | 1 | 2637 |
| chk-rows-hint | rows hint 后执行时间 | 1 | 2646 |
| chk-skew-hint-agg | skew hint 后双层 Agg 计划 | 1 | 2655 |
| chk-explain-performance-vs-a-rows-vs-e-rows | EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows） | 1 | 2664 |
| chk-explain-performance-rows-hint | EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时 | 1 | 2673 |
| chk-explain-data-node-scan | EXPLAIN · 是否含 Data Node Scan 节点 | 1 | 2682 |
| chk-explain-performance | EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子 | 1 | 2817 |
| chk-copy | COPY 语句等待视图 · 轻量级锁等待 | 1 | 2700 |
| chk-explain-performance-vector-windowagg | EXPLAIN PERFORMANCE 执行计划 · Vector WindowAgg 耗时及位置 | 1 | 2709 |
| chk-explain-performance | EXPLAIN PERFORMANCE 改写后执行计划 · 排序下推验证 | 1 | 2817 |
| chk-gs-wlm-session-history-warning-sql | GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息 | 2 | 2727 |
| chk-gs-wlm-session-history-warning | GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警 | 1 | 2736 |
| chk-explain-performance-cpu-io | EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络) | 1 | 2745 |
| chk-xid | 当前事务 XID | 1 | 2754 |
| chk- | 活跃事务列表 | 1 | 2763 |
| chk-vacuum-defer-cleanup-age | vacuum_defer_cleanup_age 参数值 | 1 | 4621 |
| chk-gtm-snapshot-oldestxmin-xid | GTM snapshot · oldestxmin 与 xid 差值 | 1 | 2781 |
| chk-pgxc-running-xacts | 老事务列表 (pgxc_running_xacts) | 1 | 2790 |
| chk-dn-warning | DN 间导入行数倾斜率(WARNING) | 1 | 2799 |
| chk-pg-stat-activity-idle | pg_stat_activity · idle 连接数 | 1 | 2808 |
| chk-explain-performance | EXPLAIN PERFORMANCE · 算子分布 | 1 | 2817 |
| chk-a-time-dn | 算子 A-time(在单 DN 上的运行耗时) | 1 | 2826 |
| chk-wiredtiger-cache-bytes-currently-in-the-cache | wiredTiger.cache.bytes_currently_in_the_cache | 1 | 2835 |
| chk-replication-lag | replication_lag | 1 | 2844 |
| chk-mongod-process-state | mongod_process_state | 1 | 2853 |
| chk-mongod-nofile-nproc-fsize-memlock-ulimit | mongod 进程 nofile / nproc / fsize / memlock 等 ulimit | 1 | 2862 |
| chk-sharding-balancer-migration-24h-results-sharding-collection- | sharding.balancer.migration_24h_results · sharding.collection.chunks_per_shard | 1 | 2871 |
| chk-log-sharding-migrationfailed-error | log.SHARDING.MigrationFailed.error | 1 | 2880 |
| chk-sh-movechunk-errmsg | sh.moveChunk.errmsg | 1 | 2889 |
| chk-sharding-collection-jumbo-chunks | sharding.collection.jumbo_chunks | 1 | 2898 |
| chk-currentop-locks-currentop-waitingforlock | currentOp.locks · currentOp.waitingForLock | 1 | 2907 |
| chk-wiredtiger-cache-pages-written-from-cache-pages-read-into-ca | wiredTiger.cache.pages written from cache / pages read into cache | 1 | 2916 |
| chk-mongod | mongod 进程栈采样函数命中分布 | 1 | 2925 |
| chk-wiredtiger-cache-used-mongostat-used | wiredTiger cache used % (mongostat 输出列 used) | 1 | 2934 |
| chk-db-collection-stats-1024-1024-size-totalindexsize | db.collection.stats(1024*1024).size + totalIndexSize | 1 | 2943 |
| chk-serverstatus-tcmalloc-tcmalloc-pageheap-free-bytes | serverStatus.tcmalloc.tcmalloc.pageheap_free_bytes | 1 | 2952 |
| chk-serverstatus-tcmalloc-tcmalloc-pageheap-unmapped-bytes | serverStatus.tcmalloc.tcmalloc.pageheap_unmapped_bytes | 1 | 2961 |
| chk-mongod-rss | mongod 进程 RSS | 2 | 2970 |
| chk-proc-meminfo-memfree | /proc/meminfo MemFree | 1 | 2979 |
| chk-mongod-tcmalloc-tcmalloc-generic-heap-size-current-allocated | mongod tcmalloc.tcmalloc.generic.heap_size / current_allocated_bytes / pageheap_free_bytes | 1 | 2988 |
| chk-mongod-vsz | mongod 进程 VSZ | 1 | 2997 |
| chk-wiredtiger-cache-dirty | wiredTiger cache dirty % | 1 | 3006 |
| chk-globallock-currentqueue-total | globalLock.currentQueue.total | 2 | 3015 |
| chk-globallock-totaltime-vs-uptime | globalLock.totalTime_vs_uptime | 1 | 3024 |
| chk-locks-avg-acquire-wait-micros | locks.avg_acquire_wait_micros | 1 | 3033 |
| chk-explain-executiontimemillis-per-page | explain.executionTimeMillis_per_page | 1 | 3042 |
| chk-disk-io-util | disk_io_util | 1 | 3051 |
| chk-mongostat-qrw-arw-or-slow-log-count | mongostat.qrw_arw_or_slow_log_count | 1 | 3060 |
| chk-mongod-log-collscan-count | mongod.log.COLLSCAN_count | 1 | 3069 |
| chk-mongod-log-slow-query-1-10s | mongod.log.slow_query_1_10s | 1 | 3078 |
| chk-currentop-secs-running | currentOp.secs_running | 1 | 3087 |
| chk-wiredtiger-cache-bytes-currently-in-the-cache-wiredtiger-cac | wiredTiger.cache.bytes currently in the cache / wiredTiger.cache.maximum bytes configured | 1 | 3096 |
| chk-wiredtiger-cache-eviction-worker-thread-evicting-pages-appli | wiredTiger.cache.eviction worker thread evicting pages / application thread time evicting | 1 | 3105 |
| chk-flamegraph-snappy-cpu-pct | flamegraph.snappy.cpu_pct | 1 | 3114 |
| chk-application-thread-concurrency-setting-business-tps | application thread concurrency setting + business TPS | 1 | 3123 |
| chk-application-linked-memory-allocator-library | application linked memory allocator library | 1 | 3132 |
| chk-aggregation-pipeline-duration | aggregation_pipeline_duration | 1 | 3141 |
| chk-lookup-pipeline-stage | 慢查询中 $lookup pipeline stage 出现频率 | 1 | 3150 |
| chk-indexstats-accesses-ops | $indexStats accesses.ops · 每索引使用次数 | 1 | 3159 |
| chk-collstats-avgobjsize-p99 | collStats.avgObjSize / 文档大小 P99 | 1 | 3168 |
| chk-atlas-query-targeting-scanned-returned-scanned-objects-retur | Atlas Query Targeting: Scanned/Returned & Scanned Objects/Returned | 1 | 3177 |
| chk-mongod-slow-query-log-plansummary-keysexamined-docsexamined- | mongod slow query log: planSummary / keysExamined / docsExamined / nreturned | 1 | 3186 |
| chk-explain-executionstats | explain.executionStats | 1 | 3195 |
| chk-operation-execution-time-ms-plansummary | Operation Execution Time (ms) + planSummary | 1 | 3204 |
| chk-docsexamined-keysexamined-docs-examined-returned-ratio | docsExamined / keysExamined / Docs Examined : Returned Ratio | 1 | 3213 |
| chk-numyields-usedindex-hassort | numYields / usedIndex / hasSort | 1 | 3222 |
| chk-globallock-totaltime-uptime | globalLock.totalTime / uptime | 1 | 3231 |
| chk-locks-type-deadlockcount-locks-type-timeacquiringmicros-acqu | locks.<type>.deadlockCount + locks.<type>.timeAcquiringMicros / acquireWaitCount | 1 | 3240 |
| chk-connections-current-connections-available | connections.current / connections.available | 1 | 3249 |
| chk-connections-current-vs-workload-opcounters | connections.current vs workload (opcounters) | 1 | 3258 |
| chk-wiredtiger-concurrenttransactions-read-write-available-out-t | wiredTiger.concurrentTransactions.{read,write}.{available,out,totalTickets} | 1 | 3267 |
| chk-queues-execution-read-queues-execution-write | queues.execution.read / queues.execution.write | 1 | 3276 |
| chk-replsetgetstatus-members-optimedate-oplog-window | replSetGetStatus.members[].optimeDate / oplog window | 1 | 3285 |
| chk-metrics-cursor-open-total-opcounters-query-getmore | metrics.cursor.open.total / opcounters.{query,getmore} | 1 | 3294 |
| chk-metrics-operation-scanandorder | metrics.operation.scanAndOrder | 1 | 3303 |
| chk-system-profile-slow-query-log-collstats-avgobjsize | system.profile / slow query log + collStats.avgObjSize 趋势 | 1 | 3312 |
| chk-driver-maxpoolsize | driver maxPoolSize · 应用层典型并发请求数 | 1 | 3528 |
| chk-dbpath | dbPath 挂载点文件系统类型 | 2 | 3330 |
| chk-tuned-adm-active-profile | tuned-adm active 当前 profile 名 | 1 | 3339 |
| chk-mongod-version-uname-r | mongod --version + uname -r | 1 | 3348 |
| chk-net-ipv4-tcp-keepalive-time | net.ipv4.tcp_keepalive_time | 1 | 3990 |
| chk-mongod-startup-log-numa-warning | mongod startup log · NUMA warning 行 | 1 | 3366 |
| chk-numad | numad 进程 | 1 | 3375 |
| chk-vm-swappiness | vm.swappiness | 1 | 4816 |
| chk-ec2-instance-type-enhanced-networking-ebs-provisioned-iops | EC2 instance type / Enhanced Networking 状态 / EBS provisioned IOPS | 1 | 3393 |
| chk-tcmalloc-usingpercpucaches-tcmalloc-tcmalloc-cpu-free | tcmalloc.usingPerCPUCaches / tcmalloc.tcmalloc.cpu_free | 1 | 3402 |
| chk-glibc-pthread-rseq-tunable-glibc-tunables-env | glibc.pthread.rseq tunable / GLIBC_TUNABLES env | 1 | 3411 |
| chk-kernel-version | kernel version | 1 | 3420 |
| chk-mongod-log-wt-cache-full | mongod log "WT_CACHE_FULL" 出现频次 | 1 | 3429 |
| chk-dbstats-collstats-size-vs-inmemorysizegb | dbStats / collStats 总 size vs inMemorySizeGB | 1 | 3438 |
| chk-replsetgetstatus-members-statestr-primary-secondary-arbiter | replSetGetStatus.members[] 的 stateStr 分布(PRIMARY/SECONDARY/ARBITER) | 1 | 3447 |
| chk-secondary-health-state-optimedate-primary | secondary 的 health/state · optimeDate 与 primary 的差距 | 1 | 3456 |
| chk-getdefaultrwconcern-defaultwriteconcern-w | getDefaultRWConcern → defaultWriteConcern.w | 1 | 3465 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 4848 |
| chk-explain-queryplanner-winningplan-sort-stage | explain.queryPlanner.winningPlan SORT stage 是否存在 | 1 | 3483 |
| chk-sort-useddisk-sort-spills-sort-spilledbytes-sort-spilledreco | $sort.usedDisk / $sort.spills / $sort.spilledBytes / $sort.spilledRecords / $sort.spilledDataStorageSize | 1 | 3492 |
| chk-driver-connecttimeoutms-vs | driver connectTimeoutMS 当前值 vs 副本集成员最长网络延迟 | 1 | 3501 |
| chk-driver-sockettimeoutms-vs | driver socketTimeoutMS 当前值 vs 应用最慢合法操作耗时 | 1 | 3510 |
| chk-driver-minpoolsize-real-time-connection | driver minPoolSize · 服务器日志 / real time 面板 connection 创建速率 | 1 | 3519 |
| chk-driver-maxpoolsize | driver maxPoolSize · 应用活跃线程数 / 实际每秒操作数 | 1 | 3528 |
| chk-driver-maxpoolsize-cpu-connection-accept-rate | driver maxPoolSize · 服务端 CPU% · connection accept rate | 1 | 3537 |
| chk-explain-executionstats-executiontimemillis | explain.executionStats.executionTimeMillis | 1 | 3546 |
| chk-explain-executionstats-executionstages-inputstage-stage | explain.executionStats.executionStages.inputStage.stage | 1 | 3555 |
| chk-executionstats-totalkeysexamined-executionstats-totaldocsexa | executionStats.totalKeysExamined / executionStats.totalDocsExamined | 1 | 3564 |
| chk-executionstats-totaldocsexamined-executionstats-nreturned | executionStats.totalDocsExamined / executionStats.nReturned | 2 | 3573 |
| chk-profile-slowms-profile-samplerate-profile-was | profile.slowms / profile.sampleRate / profile.was | 1 | 3582 |
| chk-sys-kernel-mm-transparent-hugepage-enabled-defrag-khugepaged | /sys/kernel/mm/transparent_hugepage/{enabled,defrag,khugepaged/defrag} | 1 | 3591 |
| chk-syncedto-time-per-secondary | syncedTo time per secondary | 1 | 3600 |
| chk-flowcontrol-islagged | flowControl.isLagged | 1 | 3609 |
| chk-replication-lag-seconds | Replication Lag (seconds) | 1 | 3618 |
| chk-replication-headroom | Replication Headroom | 1 | 3627 |
| chk-network-metrics | Network metrics | 1 | 3636 |
| chk-mongod-slow-log-workingmillis | mongod_slow_log.workingMillis | 1 | 3645 |
| chk-workingmillis-vs-totaltimequeuedmicros | workingMillis_vs_totalTimeQueuedMicros | 1 | 3654 |
| chk-mongod-resident-memory | mongod_resident_memory | 1 | 3663 |
| chk-heap-profile-alloc-hotspots | heap_profile_alloc_hotspots | 1 | 3672 |
| chk-queryhash-uniqueness-per-shape | queryHash_uniqueness_per_shape | 1 | 3681 |
| chk-plancache-entries-count | planCache.entries_count | 1 | 3690 |
| chk-queryframework-per-version | queryFramework_per_version | 1 | 3699 |
| chk-sh-getbalancerstate | sh.getBalancerState() | 1 | 3708 |
| chk-sh-status-verbose-jumbo-flag | sh.status verbose 输出中的 jumbo flag | 1 | 3717 |
| chk-config-chunks-jumbo-true | config.chunks { jumbo: true } | 1 | 3726 |
| chk-getsharddistribution-per-shard-data-docs-chunks | getShardDistribution: per-shard data / docs / chunks | 1 | 3735 |
| chk-hostinfo-system-memsizemb-memlimitmb | hostInfo.system.memSizeMB / memLimitMB | 1 | 3744 |
| chk-wiredtiger-cache-maximum-bytes-configured | wiredTiger.cache."maximum bytes configured" | 1 | 3771 |
| chk-operator-version-replsets-resources-limits-cpu | operator version + replsets.resources.limits.cpu | 1 | 3762 |
| chk-wiredtiger-cache-maximum-bytes-configured | wiredTiger.cache.maximum bytes configured | 1 | 3771 |
| chk-serverstatus-tcmalloc-usingpercpucaches | serverStatus.tcmalloc.usingPerCpuCaches | 1 | 3780 |
| chk-serverstatus-tcmalloc-tcmalloc-cpu-free | serverStatus.tcmalloc.tcmalloc.cpu_free | 1 | 3789 |
| chk-uname-r-kernel-version | uname -r kernel version | 1 | 3798 |
| chk-sys-kernel-mm-transparent-hugepage-enabled | /sys/kernel/mm/transparent_hugepage/enabled | 1 | 3807 |
| chk-explain-queryplanner-winningplan-stage-sort | explain.queryPlanner.winningPlan.stage(子节点是否含 SORT) | 1 | 3816 |
| chk-flamegraph-cpu-stack-profile | flamegraph CPU stack profile | 1 | 3825 |
| chk-getdefaultrwconcern-defaultwriteconcern | getDefaultRWConcern.defaultWriteConcern | 1 | 3834 |
| chk-rs-conf-writeconcernmajorityjournaldefault | rs.conf().writeConcernMajorityJournalDefault | 1 | 3843 |
| chk-wiredtiger-checkpoint-duration | wiredTiger checkpoint duration | 1 | 3852 |
| chk-wiredtiger-cache-eviction-dirty-trigger-eviction-dirty-targe | wiredTiger.cache (eviction_dirty_trigger / eviction_dirty_target context) | 1 | 3861 |

## parameter-current-value (226)

| check_id | param_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-kernel-boot-cmdline-nohz-off | kernel boot cmdline `nohz=off` | 1 | 3870 |
| chk-linux-kernel-page-size | Linux kernel `Page size` 编译选项 | 1 | 3878 |
| chk-mysql-innodb-thread-concurrency-nginx-worker-processes | MySQL `innodb_thread_concurrency` / Nginx `worker_processes` / 其他应用并发设置 | 1 | 3886 |
| chk-mount-options-noatime | mount.options.noatime | 1 | 3894 |
| chk-mount-options-nobarrier | mount.options.nobarrier | 1 | 3902 |
| chk-net-ipv4-tcp-max-syn-backlog | net.ipv4.tcp_max_syn_backlog | 2 | 3910 |
| chk-net-core-somaxconn | net.core.somaxconn | 2 | 3918 |
| chk-net-core-rmem-max | net.core.rmem_max | 1 | 3926 |
| chk-net-core-wmem-max | net.core.wmem_max | 1 | 3934 |
| chk-net-ipv4-tcp-rmem | net.ipv4.tcp_rmem | 1 | 3942 |
| chk-net-ipv4-tcp-wmem | net.ipv4.tcp_wmem | 1 | 3950 |
| chk-net-ipv4-tcp-max-tw-buckets | net.ipv4.tcp_max_tw_buckets | 2 | 3958 |
| chk-net-ipv4-ip-local-port-range | net.ipv4.ip_local_port_range | 1 | 3966 |
| chk-net-ipv4-tcp-tw-reuse | net.ipv4.tcp_tw_reuse | 1 | 3974 |
| chk-net-core-netdev-max-backlog | net.core.netdev_max_backlog | 1 | 3982 |
| chk-net-ipv4-tcp-keepalive-time | net.ipv4.tcp_keepalive_time | 3 | 3990 |
| chk-net-ipv4-tcp-fin-timeout | net.ipv4.tcp_fin_timeout | 1 | 3998 |
| chk-bios-advanced-misc-config-support-smmu | bios.advanced.misc_config.support_smmu | 1 | 4006 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 4014 |
| chk-systemd-unit-irqbalance-service | systemd.unit.irqbalance.service | 1 | 4022 |
| chk-proc-irq-n-smp-affinity-list | proc.irq.<N>.smp_affinity_list | 1 | 4030 |
| chk-sys-block-device-queue-nr-requests | /sys/block/${device}/queue/nr_requests | 1 | 4038 |
| chk-libvirt-domain-cputune-vcpupin | libvirt.domain.cputune.vcpupin | 1 | 4046 |
| chk-grub-linux-default-hugepagesz | grub.linux.default_hugepagesz | 1 | 4054 |
| chk-libvirt-domain-memorybacking-hugepages | libvirt.domain.memoryBacking.hugepages | 1 | 4062 |
| chk-numactl-c-sched-setaffinity-worker-cpu-affinity | (非操作系统参数,而是**应用启动方式**或**应用配置**)`numactl -C` / `sched_setaffinity` / 应用配置中的 worker_cpu_affinity | 1 | 4070 |
| chk-proc-irq-irq-smp-affinity-list | /proc/irq/$irq/smp_affinity_list | 1 | 4078 |
| chk-ethtool-c-eth-adaptive-rx-adaptive-tx | ethtool -C $eth adaptive-rx / adaptive-tx | 1 | 4086 |
| chk-ethtool-c-eth-rx-usecs-tx-usecs-rx-frames-tx-frames | ethtool -C $eth rx-usecs / tx-usecs / rx-frames / tx-frames | 1 | 4094 |
| chk-sys-class-net-nic-queues-rx-0-rps-cpus | /sys/class/net/$nic/queues/rx-0/rps_cpus | 1 | 4102 |
| chk-sys-class-net-nic-queues-rx-0-rps-flow-cnt-proc-sys-net-core | /sys/class/net/$nic/queues/rx-0/rps_flow_cnt + /proc/sys/net/core/rps_sock_flow_entries | 1 | 4110 |
| chk-proc-sys-vm-dirty-expire-centisecs | /proc/sys/vm/dirty_expire_centisecs | 1 | 4118 |
| chk-proc-sys-vm-dirty-background-ratio | /proc/sys/vm/dirty_background_ratio | 1 | 4126 |
| chk-proc-sys-vm-dirty-ratio | /proc/sys/vm/dirty_ratio | 1 | 4134 |
| chk-sys-block-device-name-queue-scheduler | /sys/block/$DEVICE-NAME/queue/scheduler | 1 | 4142 |
| chk-mount-option-barrier-nobarrier | mount option · barrier / nobarrier | 1 | 4150 |
| chk-filesystem-type-mkfs-xfs-vs-mkfs-ext4 | filesystem type (mkfs.xfs vs mkfs.ext4) | 1 | 4158 |
| chk-mkfs-xfs-b-size | mkfs.xfs -b size= | 1 | 4166 |
| chk-vm-dirty-ratio-vm-dirty-background-ratio | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 4174 |
| chk-kernel-transparent-hugepage | kernel.transparent_hugepage | 2 | 4182 |
| chk-block-device-queue-read-ahead-kb-udev-attr-bdi-read-ahead-kb | block device queue/read_ahead_kb(udev ATTR{bdi/read_ahead_kb}) | 1 | 4190 |
| chk-shared-buffers | shared_buffers | 5 | 4198 |
| chk-work-mem | work_mem | 8 | 4207 |
| chk-rewrite-rule | rewrite_rule | 10 | 4216 |
| chk-enable-hashjoin | enable_hashjoin | 2 | 4225 |
| chk-enable-nestloop | enable_nestloop | 5 | 4234 |
| chk-enable-mergejoin | enable_mergejoin | 2 | 4243 |
| chk-enable-sort | enable_sort | 5 | 4251 |
| chk-best-agg-plan | best_agg_plan | 2 | 4260 |
| chk-a-format-load-with-constraints-violation | a_format_load_with_constraints_violation | 1 | 4269 |
| chk-cost-param | cost_param | 4 | 4278 |
| chk-skew-option | skew_option | 2 | 4287 |
| chk-thread-pool-attr | thread_pool_attr | 1 | 4296 |
| chk-default-statistics-target | default_statistics_target | 1 | 4305 |
| chk-behavior-compat-options | behavior_compat_options | 1 | 4314 |
| chk-enable-fast-query-shipping | enable_fast_query_shipping | 2 | 4323 |
| chk-recovery-parse-workers | recovery_parse_workers | 1 | 4332 |
| chk-recovery-redo-workers | recovery_redo_workers | 1 | 4341 |
| chk-enable-index-nestloop | enable_index_nestloop | 1 | 4350 |
| chk-enable-indexscan | enable_indexscan | 2 | 4359 |
| chk-max-process-memory | max_process_memory | 3 | 4367 |
| chk-qrw-inlist2join-optmode | qrw_inlist2join_optmode | 2 | 4376 |
| chk-fetchsize | fetchSize | 1 | 4385 |
| chk-period | period | 1 | 4394 |
| chk-ttl | ttl | 1 | 4403 |
| chk-disk-cache-max-size | disk_cache_max_size | 2 | 4412 |
| chk-disk-cache-dual-write-option | disk_cache_dual_write_option | 1 | 4421 |
| chk-min-batch-rows | min_batch_rows | 1 | 4429 |
| chk-autovacuum | autovacuum | 1 | 4437 |
| chk-autovacuum-vacuum-cost-delay | autovacuum_vacuum_cost_delay | 1 | 4446 |
| chk-autovacuum-max-workers | autovacuum_max_workers | 1 | 4455 |
| chk-autovacuum-naptime | autovacuum_naptime | 2 | 4464 |
| chk-max-active-statements | max_active_statements | 1 | 4473 |
| chk-autovacuum-max-workers-hstore | autovacuum_max_workers_hstore | 1 | 4482 |
| chk-enable-codegen | enable_codegen | 1 | 4491 |
| chk-enable-numa-bind | enable_numa_bind | 1 | 4499 |
| chk-abnormal-check-general-task | abnormal_check_general_task | 1 | 4507 |
| chk-resource-track-level | resource_track_level | 1 | 4516 |
| chk-track-activities | track_activities | 1 | 4525 |
| chk-connectiontimeout | connectionTimeOut | 1 | 4533 |
| chk-lockwait-timeout | lockwait_timeout | 1 | 4542 |
| chk-psort-work-mem | psort_work_mem | 2 | 4551 |
| chk-enable-delta | ENABLE_DELTA | 1 | 4560 |
| chk-resource-pool-cpu-dedicated-quota | resource_pool.cpu_dedicated_quota | 1 | 4569 |
| chk-temp-file-limit | temp_file_limit | 1 | 4578 |
| chk-sequence-cache | sequence.cache | 1 | 4587 |
| chk-query-dop | query_dop | 1 | 4596 |
| chk-cstore-buffers | cstore_buffers | 1 | 4604 |
| chk-comm-max-stream | comm_max_stream | 1 | 4612 |
| chk-vacuum-defer-cleanup-age | vacuum_defer_cleanup_age | 1 | 4621 |
| chk-enable-stream-operator | enable_stream_operator | 1 | 4630 |
| chk-table-skewness-warning-threshold | table_skewness_warning_threshold | 1 | 4638 |
| chk-table-skewness-warning-rows | table_skewness_warning_rows | 1 | 4646 |
| chk-session-timeout | session_timeout | 1 | 4654 |
| chk-max-connections | max_connections | 1 | 4663 |
| chk-etc-security-limits-conf-ulimit | /etc/security/limits.conf 中各 ulimit 项 | 1 | 4672 |
| chk-wiredtiger-engineconfig-memory-page-max | wiredTiger.engineConfig.memory_page_max(诊断专用 · 实际生产不应调) | 1 | 4680 |
| chk-storage-wiredtiger-engineconfig-cachesizegb | storage.wiredTiger.engineConfig.cacheSizeGB | 1 | 4688 |
| chk-tcmalloc-aggressive-decommit | TCMALLOC_AGGRESSIVE_DECOMMIT(环境变量 / 启动参数) | 1 | 4696 |
| chk-wiredtiger-cache-eviction-updates-trigger-eviction-updates-t | wiredTiger.cache.eviction_updates_trigger / eviction_updates_target | 1 | 4704 |
| chk-wiredtigerengineruntimeconfig-checkpoint-wait-log-size | wiredTigerEngineRuntimeConfig.checkpoint.wait / log_size | 1 | 4712 |
| chk-eviction-trigger | eviction_trigger | 1 | 4720 |
| chk-innodb-thread-concurrency-mysql-worker-processes-nginx | innodb_thread_concurrency (MySQL) / worker_processes (Nginx) / 应用自有并发参数 | 1 | 4728 |
| chk-worker-processes | worker_processes | 1 | 4736 |
| chk-linker-flags-ljemalloc-l-jemalloc-config-libdir | linker flags · -ljemalloc + -L`jemalloc-config --libdir` | 1 | 4744 |
| chk-malloc-lib-my-cnf | malloc-lib (my.cnf) 或类似配置 | 1 | 4752 |
| chk-slowopthresholdms-atlas-managed-dynamic-fixed-100ms | slowOpThresholdMs (Atlas-managed dynamic / fixed 100ms) | 1 | 4760 |
| chk-maxincomingconnections-ulimit-n | maxIncomingConnections / ulimit -n | 1 | 4768 |
| chk-storageengineconcurrentreadtransactions-storageengineconcurr | storageEngineConcurrentReadTransactions / storageEngineConcurrentWriteTransactions | 1 | 4776 |
| chk-maxpoolsize | maxPoolSize | 3 | 4784 |
| chk-deployment-dbpath | (deployment) dbPath 挂载点文件系统 | 2 | 4792 |
| chk-tuned-profile | tuned profile | 1 | 4800 |
| chk-numactl-interleave-all-mongod | numactl --interleave=all (启动 mongod 时) | 1 | 4808 |
| chk-vm-swappiness | vm.swappiness | 1 | 4816 |
| chk-glibc-tunables-env | GLIBC_TUNABLES (env) | 1 | 4824 |
| chk-storage-inmemory-engineconfig-inmemorysizegb-inmemorysizegb | storage.inMemory.engineConfig.inMemorySizeGB / --inMemorySizeGB | 1 | 4832 |
| chk-defaultwriteconcern-w-write-concern | defaultWriteConcern.w(及业务调用侧 write concern) | 1 | 4840 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 4848 |
| chk-connecttimeoutms | connectTimeoutMS | 1 | 4856 |
| chk-sockettimeoutms | socketTimeoutMS | 1 | 4864 |
| chk-minpoolsize | minPoolSize | 1 | 5846 |
| chk-operationprofiling-slowopthresholdms-db-setprofilinglevel-sl | operationProfiling.slowOpThresholdMs / db.setProfilingLevel slowms | 1 | 4880 |
| chk-operationprofiling-slowopsamplerate-setprofilinglevel-sample | operationProfiling.slowOpSampleRate / setProfilingLevel sampleRate | 1 | 4888 |
| chk-kernel-transparent-hugepage-enabled-systemd-init-d-kernel-bo | kernel transparent_hugepage/enabled(可通过 systemd / init.d / kernel boot param 启用) | 1 | 4896 |
| chk-writeconcernmajorityjournaldefault-writeconcern | writeConcernMajorityJournalDefault / 应用层 writeConcern | 1 | 4904 |
| chk-flowcontroltargetlagseconds | flowControlTargetLagSeconds | 1 | 4912 |
| chk-internalqueryframeworkcontrol | internalQueryFrameworkControl | 1 | 4920 |
| chk-sharding-chunk-size-64mb-25 | sharding chunk size(默认 64MB)/ 25 万文档上限 | 1 | 4928 |
| chk-replsets-storage-wiredtiger-engineconfig-cachesizeratio-cont | replsets.storage.wiredTiger.engineConfig.cacheSizeRatio + container resources.limits.memory | 1 | 4936 |
| chk-defaultwriteconcern-w | defaultWriteConcern.w | 1 | 4944 |
| chk-replicaset-config-writeconcernmajorityjournaldefault | replicaSet.config.writeConcernMajorityJournalDefault | 1 | 4952 |
| chk-wiredtigerengineruntimeconfig-eviction-dirty-trigger-evictio | wiredTigerEngineRuntimeConfig.eviction_dirty_trigger / eviction_dirty_target | 1 | 4960 |
| chk-wiredtigerengineruntimeconfig-eviction-threads-min-threads-m | wiredTigerEngineRuntimeConfig.eviction.threads_min / threads_max | 1 | 4968 |
| chk-arm64-graviton2-march-armv8-2-a-lse | ARM64 Graviton2+ 编译时用 -march=armv8.2-a 启用 LSE 原子指令 | 0 | 4976 |
| chk-arm64-moutline-atomics-lse | ARM64 多代兼容部署时用 -moutline-atomics 运行期检测 LSE 支持 | 0 | 4991 |
| chk-graviton2-dmesg-lscpu-lse | Graviton2 部署后用 dmesg/lscpu 验证 LSE 原子指令已被内核检测启用 | 0 | 5006 |
| chk-xfs-mount-noatime-access-time | XFS 数据盘 mount 加 noatime · 避免读取时更新 access time 浪费资源 | 0 | 5021 |
| chk-raid-flash-xfs-mount-nobarrier-write-barrier | 底层存储具备掉电保护(RAID/Flash)时 · XFS 数据盘 mount 加 nobarrier · 避免 write barrier 性能损失 | 0 | 5036 |
| chk-mongodb-tcp-tw-reuse-time-wait-socket | MongoDB 客户端启用 tcp_tw_reuse 让 TIME-WAIT socket 可复用以新建连接 | 0 | 5051 |
| chk-mongodb-listen-backlog-somaxconn-65535-accept | MongoDB 客户端 listen() backlog 上限 somaxconn 调至 65535 防 accept 队列溢出 | 0 | 5066 |
| chk-mongodb-netdev-max-backlog-8096 | MongoDB 客户端调大 netdev_max_backlog 至 8096 避免高入流量丢包 | 0 | 5081 |
| chk-mongodb-tcp-max-syn-backlog-8192-syn | MongoDB 客户端调大 tcp_max_syn_backlog 至 8192 防 SYN 队列溢出 | 0 | 5096 |
| chk-mongodb-tcp-fin-timeout-30-fin-wait-2 | MongoDB 客户端调小 tcp_fin_timeout 至 30 秒缩短 FIN-WAIT-2 占用 | 0 | 5111 |
| chk-mongodb-tcp-max-tw-buckets-3000-time-wait | MongoDB 客户端调小 tcp_max_tw_buckets 至 3000 加快 TIME-WAIT 强制回收 | 0 | 5126 |
| chk-boostkit-vm-dirty-ratio-5 | 鲲鹏 BoostKit 数据库场景 vm.dirty_ratio 设为 5 限制脏页堆积 | 0 | 5141 |
| chk-kvm-mongod-vcpu-placement-static-cpuset-worker-numa-die | KVM 虚拟机部署 mongod 时 · vcpu placement=static + cpuset 限定 worker 线程范围 · 防跨 NUMA 跨 DIE | 0 | 5156 |
| chk-kvm-mongod-512mb-host-kernel-cmdline-vm-xml-memorybacking | KVM 虚拟化场景为 mongod 虚机分配 512MB 大页(Host kernel cmdline + VM xml memoryBacking) | 0 | 5171 |
| chk-read-ahead-kb-128kb-4096kb | 磁盘顺序读场景下将 read_ahead_kb 从默认 128KB 调大至 4096KB 以充分利用预取性能提升 | 0 | 5186 |
| chk-xfs-blocksize-8192b-i-o | 大文件操作场景使用 XFS 文件系统并将 blocksize 设为 8192B 以提升 I/O 吞吐 | 0 | 5201 |
| chk-jemalloc-glibc | 多线程高并发场景下应用链接 jemalloc 替代 glibc 默认分配器以减少锁竞争 | 0 | 5216 |
| chk-wiredtiger | 长事务导致 WiredTiger 缓存压力：拆分事务并确保索引覆盖 | 0 | 5231 |
| chk-1000 | 单次事务修改文档上限 1000 条：超出须拆批处理 | 0 | 5246 |
| chk-linearizable-maxtimems | linearizable 读关注配合 maxTimeMS 防止操作无限挂起 | 0 | 5261 |
| chk-mongodb-journal-io | MongoDB Journal 和系统日志应使用独立物理卷，避免日志 IO 竞争数据盘带宽 | 0 | 5276 |
| chk-w-majority | 重要数据写入应使用 w:majority，防止主节点故障转移时写操作被回滚 | 0 | 5291 |
| chk-wiredtiger-modified-evictions-nvme | WiredTiger 高脏页率 + 高 modified evictions 场景应换用 NVMe 替代机械盘 | 0 | 5306 |
| chk-bios-smmu-io | 鲲鹏平台非虚拟化场景下 · 在 BIOS 中关闭 SMMU 以避免数据库 IO 开销 | 0 | 5321 |
| chk-bios-cpu | 鲲鹏平台数据库场景 · 在 BIOS 中关闭 CPU 硬件预取以避免无效缓存流量 | 0 | 5336 |
| chk-numa-irqbalance-32 | 鲲鹏服务器手动绑定网卡中断到本地 NUMA · 关闭 irqbalance · 32 队列绑满获最佳网络性能 | 0 | 5351 |
| chk-thp | 数据库场景下关闭透明大页(THP)以减少内存碎片与利用率下降 | 0 | 5366 |
| chk-io-deadline-nvme | 数据库场景下 · 块设备 IO 调度器配置为 deadline(NVMe 除外) | 0 | 5381 |
| chk-nr-requests-2048 | 数据库高并发写入场景下 · 块设备 nr_requests 调到 2048 提升磁盘吞吐 | 0 | 5396 |
| chk-adaptive-rx-tx-off-ethtool-c | 鲲鹏网卡性能调优：禁用自适应中断聚合（adaptive-rx/tx off），使用静态 ethtool -C 参数 | 0 | 5411 |
| chk-mongodb-maxincomingconnections-raise-above-default-64k-for-h | MongoDB maxIncomingConnections: raise above default 64k for high-connection deployments | 0 | 5426 |
| chk-linux-ulimit-nofile-raise-open-file-descriptor-limit-for-hig | Linux ulimit nofile: raise open-file descriptor limit for high-connection MongoDB servers | 0 | 5441 |
| chk-linux-ulimit-nproc-raise-thread-count-limit-for-high-connect | Linux ulimit nproc: raise thread count limit for high-connection MongoDB deployments | 0 | 5456 |
| chk-linux-ulimit-stack-raise-per-thread-stack-size-limit-for-hig | Linux ulimit stack: raise per-thread stack size limit for high-connection MongoDB deployments | 0 | 5471 |
| chk-vm-max-map-count-raise-kernel-mmap-limit-when-running-many-t | vm.max_map_count: raise kernel mmap limit when running many threads (MongoDB high-connection) | 0 | 5486 |
| chk-net-ipv4-ip-local-port-range-expand-ephemeral-port-range-on- | net.ipv4.ip_local_port_range: expand ephemeral port range on benchmark/client hosts | 0 | 5501 |
| chk-3-voting-w-majority | 副本集部署需 ≥3 个数据承载 voting 成员 + 写操作走 w:majority · 否则数据耐久性无法满足 | 0 | 5516 |
| chk-7-arbiter | 副本集投票成员需为奇数(最多 7 个)· 偶数时用 arbiter 凑奇数 · 否则选举平票卡死 | 0 | 5531 |
| chk-driver-110-115 | driver 连接池大小起点应为应用层"典型并发请求数 × 110-115%" · 池太小将请求排队 | 0 | 5546 |
| chk-dbpath-nfs-vmware | dbPath 不要用 NFS · 用本地 / VMware 虚拟盘 | 0 | 5561 |
| chk-wiredtiger-xfs-ext4 | WiredTiger 数据盘强烈建议用 XFS · 不用 EXT4 | 0 | 5576 |
| chk-rhel-centos-tuned-tuned-profile | RHEL / CentOS 上用 tuned 时必须自定义 tuned profile | 0 | 5591 |
| chk-san | 副本集成员不要全放同一 SAN · 避免单点故障 | 0 | 5606 |
| chk-lb-mongod-tcp-keepalive-time-120 | 云 LB 后部署 mongod 时 · tcp_keepalive_time 设为 120 秒以避免静默断连 | 0 | 5621 |
| chk-raid-10-raid-5-raid-6 | 存储层用 RAID-10 · 不要用 RAID-5 / RAID-6 | 0 | 5636 |
| chk-nfs-etc-fstab-bg-hard-nolock-noatime-nointr | 必须用 NFS 时 · /etc/fstab 加 bg / hard / nolock / noatime / nointr 选项 | 0 | 5651 |
| chk-i-o-ssd-sata-ssd | I/O 吞吐瓶颈时 · 优先用 SSD(SATA SSD 性价比好)而非堆贵转盘 | 0 | 5666 |
| chk-mongod-vm-swappiness-1-0-60 | mongod 主机 vm.swappiness 设为 1 或 0(默认 60 太激进) | 0 | 5681 |
| chk-numa-mongod-numactl-interleave-all | NUMA 主机上 mongod 必须经 numactl --interleave=all 启动 | 0 | 5696 |
| chk-numa-vm-zone-reclaim-mode-0-numactl | NUMA 主机上 vm.zone_reclaim_mode 必须设为 0 · 与 numactl 配套 | 0 | 5711 |
| chk-vm-hypervisor-i-o-scheduler-none | VM / 云主机 + hypervisor 块设备 · I/O scheduler 用 none | 0 | 5726 |
| chk-i-o-scheduler-mq-deadline | 物理服务器 + 转盘 · I/O scheduler 用 mq-deadline | 0 | 5741 |
| chk-vm-i-o-scheduler-kyber-kernel-4-12 | 同 VM / 自建机房多负载混跑 · I/O scheduler 用 kyber(kernel 4.12+) | 0 | 5756 |
| chk-wiredtiger-readahead-8-32-sectors | WiredTiger 引擎 · readahead 设 8~32 (sectors) · 不要更高 | 0 | 5771 |
| chk-mongod-libssl-libcrypto-objdump | mongod 启动时 libssl/libcrypto 符号版本警告 · 通常不影响 · 可用 objdump 核对 | 0 | 5786 |
| chk-kvm-mongod-balloon-driver | KVM 上跑 mongod · 为虚机预留全部内存 · 不禁用 balloon driver | 0 | 5801 |
| chk-db-connecttimeoutms | 应用侧操作慢但 DB 侧未见对应 · 设 connectTimeoutMS 防止驱动连接阶段无限等待 | 0 | 5816 |
| chk-socket-sockettimeoutms-op-2-3-socket | 防火墙半关闭 socket · 设 socketTimeoutMS 为最慢 op 时长的 2~3 倍以确保 socket 总能释放 | 0 | 5831 |
| chk-minpoolsize | 应用启动时连接创建占用过多时间 · 设 minPoolSize 预热池子 | 0 | 5846 |
| chk-op-sockettimeoutms-maxtimems | 想取消服务端长 op 时不要用 socketTimeoutMS · 改用 maxTimeMS() 让服务端真正取消 | 0 | 5861 |
| chk-enable-mongodb-network-compression-to-reduce-client-server-b | Enable MongoDB network compression to reduce client-server bandwidth | 0 | 5876 |
| chk-rhel-centos-7-mongodb-tuned-percona-mongodb-profile-linux | RHEL/CentOS 7+ 运行 MongoDB · 使用 tuned-percona-mongodb profile 一键自动化应用所有 Linux 调参 | 0 | 5891 |
| chk-puppet-chef-ansible-tuned-profile | 使用配置管理工具（Puppet/Chef/Ansible）时 · 必须通过 tuned profile 部署调参而非直接修改系统文件 | 0 | 5906 |
| chk-serviceexecutor-adaptive-io | 高并发场景启用 serviceExecutor adaptive 实现网络 IO 复用 | 0 | 5921 |
| chk-eviction-dirty-target-trigger | 高写入负载下调低 eviction_dirty_target/trigger 让后台线程尽早淘汰脏页 | 0 | 5936 |
| chk-checkpoint-wait-25s-io | 高写入负载下缩短 checkpoint wait 周期至 25s 均摊 IO | 0 | 5951 |
| chk-ttl-delete | 高写入集群将 TTL 过期删除窗口移至夜间低峰期规避白天 delete 高峰 | 0 | 5966 |
| chk-index-build-workload | 对不能容忍 index build 期间性能下降的 workload 启用滚动方式构建索引 | 0 | 5981 |
| chk-wiredtiger-commitintervalms-increase-to-200-300ms-for-higher | WiredTiger commitIntervalMs: increase to 200-300ms for higher write throughput | 0 | 5996 |
| chk-wiredtiger-journal-enabled-disable-for-temporary-non-critica | WiredTiger journal.enabled: disable for temporary/non-critical data to maximize write speed | 0 | 6010 |
| chk-wiredtiger-blockcompressor-set-to-none-for-maximum-write-spe | WiredTiger blockCompressor: set to none for maximum write speed (no compression overhead) | 0 | 6024 |
| chk-storage-directoryperdb-enable-when-using-separate-storage-vo | storage.directoryPerDB: enable when using separate storage volumes for each database | 0 | 6038 |
| chk-oplogsizemb-oplog | oplogSizeMB 在高更新频率工作负载下调大——避免 oplog 空洞和从节点延迟 | 0 | 6052 |
| chk-cursortimeoutmillis | cursorTimeoutMillis 调小降低空闲游标资源开销 | 0 | 6067 |
| chk-transactionlifetimelimitseconds-wiredtiger | transactionLifetimeLimitSeconds 调小防长事务压垮 WiredTiger 缓存 | 0 | 6082 |
| chk-blockcompressor-zstd | 冷数据存储场景将 blockCompressor 改为 zstd 提升压缩比 | 0 | 6097 |
| chk-tcmallocaggressivememorydecommit-oom | tcmallocAggressiveMemoryDecommit 在内存 OOM/碎片场景启用加速内存回收 | 0 | 6112 |
| chk-minsnapshothistorywindowinseconds-0-wt | 不使用历史快照读时将 minSnapshotHistoryWindowInSeconds 调小到 0 释放 WT 缓存压力 | 0 | 6127 |
| chk-wiredtiger-tickets-10-setparameter | WiredTiger 并发读写 tickets 持续低于 10 时应用 setParameter 增加上限 | 0 | 6142 |
| chk-wiredtiger-max-50-ram-1gb-0-256gb | WiredTiger 内部缓存默认值 = max(50% × (RAM - 1GB), 0.256GB) · 不应擅自调高 | 0 | 6157 |
| chk-wiredtiger-snappy | WiredTiger 集合默认采用 Snappy 块压缩 · 索引默认前缀压缩 | 0 | 6172 |
| chk-encrypted-storage-engine-aes-ni-cpu | 使用 Encrypted Storage Engine 时 · 选支持 AES-NI 指令集的 CPU | 0 | 6187 |
| chk-lxc-cgroups-docker-mongod-wiredtigercachesizegb-wiredtigerca | 容器(lxc / cgroups / Docker)部署 mongod 时必须显式设 wiredTigerCacheSizeGB 或 wiredTigerCacheSizePct | 0 | 6202 |
| chk-mongod-wiredtiger | 单机多 mongod 实例时须按实例数缩减每个实例的 WiredTiger 缓存配置 | 0 | 6217 |
| chk-storage-syncperiodsecs-0-60 | 生产环境禁止将 storage.syncPeriodSecs 设为 0 · 保持默认值 60 | 0 | 6232 |
| chk-systemlog-quiet | 生产环境禁用 systemLog.quiet 模式 · 保留完整日志输出 | 0 | 6247 |
| chk-systemlog-destination-file-syslog | 生产环境 systemLog.destination 应设为 file 而非 syslog · 避免时间戳误导 | 0 | 6262 |
| chk-linux-logrotate-systemlog-logrotate-reopen | 使用 Linux logrotate 工具时须将 systemLog.logRotate 设为 reopen 以避免日志丢失 | 0 | 6277 |
| chk-bson-json | 审计日志落文件时使用 BSON 格式而非 JSON · 降低性能开销 | 0 | 6292 |
| chk-kmip-localauditkeyfile | 审计日志加密密钥生产环境必须使用外部 KMIP 服务 · 禁止使用 localAuditKeyFile | 0 | 6307 |
| chk-mongos-maxincomingconnections | mongos 部署中客户端连接泄漏时须显式设置 maxIncomingConnections 防止分片连接风暴 | 0 | 6322 |
| chk-profiler-diagnostic-log-slowms | profiler / diagnostic log slowms 阈值应设为业务可接受的最高值 · 避免性能退化 | 0 | 6337 |
| chk-database-profiler-atlas-query-profiler-performance-advisor-q | 启用 database profiler 前优先考虑 Atlas Query Profiler / Performance Advisor / $queryStats 等替代方案 · profiler 可能 degrade 性能 | 0 | 6352 |
