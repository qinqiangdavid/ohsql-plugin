# Check Items Index · 指标集合

> 生成时间: 2026-05-31T04:10:00.005Z
> 数据源: 派生于 cases/CASES.md (每条 case 的 diagnostic_steps[*].metric_name + likely_causes.parameter_causes[*])
> 总计: 795 checks (metric 555 / param 240)
> 配套: cases/indices/by-check-item/CASES.md

## metric (555)

| check_id | metric_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-proc-cmdline-nohz-off | /proc/cmdline 中是否含 `nohz=off` | 1 | 9 |
| chk-timer-tick | timer_tick 调度次数(单位时间内) | 1 | 18 |
| chk-dtlb-load-misses-itlb-load-misses | dTLB-load-misses 比率 / iTLB-load-misses 比率 | 1 | 27 |
| chk-tps-vs | TPS / 业务吞吐 vs 线程并发数 | 1 | 36 |
| chk-mount-options | mount.options | 1 | 45 |
| chk-sysctl-net-7-keys | sysctl.net.* (7 keys) | 1 | 54 |
| chk-sysctl-net-8-keys | sysctl.net.* (8 keys) | 1 | 63 |
| chk-bios-advanced-misc-config-support-smmu | bios.advanced.misc_config.support_smmu | 1 | 72 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 81 |
| chk-systemd-unit-irqbalance-service-active-state | systemd.unit.irqbalance.service.active_state | 1 | 90 |
| chk-proc-interrupts-smp-affinity-list | proc.interrupts.smp_affinity_list | 1 | 99 |
| chk-blockdev-queue-nr-requests | blockdev.queue.nr_requests | 1 | 108 |
| chk-libvirt-domain-cputune-vcpupin | libvirt.domain.cputune.vcpupin | 1 | 117 |
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
| chk-vm-dirty-ratio-vm-dirty-background-ratio | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 225 |
| chk-kernel-boot-option-transparent-hugepage | kernel boot option transparent_hugepage | 1 | 234 |
| chk-block-device-read-ahead-kb-sectors | block device read_ahead_kb / sectors | 1 | 243 |
| chk-dbe-perf-statement-cpu-time | dbe_perf.statement.cpu_time | 1 | 252 |
| chk-explain-analyze | explain analyze 执行计划分析 | 1 | 261 |
| chk-gaussdb | GaussDB内置火焰图 · 时区加载线程占比 | 1 | 270 |
| chk-buffer-wdr | buffer命中率 (WDR报告或管控平台) | 1 | 279 |
| chk-explain-analyze-2 | EXPLAIN ANALYZE 算子落盘标志 | 1 | 288 |
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
| chk-costs | 执行计划costs | 1 | 396 |
| chk-seqscan | SeqScan算子 | 1 | 405 |
| chk-nestloop | NestLoop算子 | 1 | 414 |
| chk-cpu | CPU使用率 | 3 | 423 |
| chk-cpu-2 | CPU核使用率 | 1 | 432 |
| chk-cpu-3 | CPU堆栈 | 1 | 441 |
| chk-sql | 慢SQL及调用频次 | 1 | 450 |
| chk-explain-performance | explain performance结果 | 1 | 459 |
| chk- | 管理平台告警及通信层报错 | 1 | 468 |
| chk-analyze | 业务数据入库及analyze情况与执行计划 | 1 | 477 |
| chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo | recovery_max_workers/recovery_parse_workers/recovery_redo_workers | 1 | 486 |
| chk--2 | 回放日志类型统计 | 1 | 495 |
| chk-print-redo-wal-count-info-print-redo-wal-time-info | print_redo_wal_count_info/print_redo_wal_time_info | 1 | 504 |
| chk-redo-unlink-ddl | redo_unlink_ddl | 1 | 513 |
| chk-buffer-hit-rate-read-buffer-io | buffer_hit_rate / read_buffer_io | 1 | 522 |
| chk-wait-read-data | WAIT_READ_DATA | 1 | 531 |
| chk-buffer-hit-rate-wait-read-data | buffer_hit_rate / WAIT_READ_DATA | 1 | 540 |
| chk-q-use-q-max-use-rec-cnt | q_use / q_max_use / rec_cnt | 1 | 549 |
| chk-queue-usage | queue usage | 1 | 558 |
| chk--3 | 索引页面元组分布 | 1 | 567 |
| chk-v-logfile | v$logfile | 1 | 576 |
| chk-pg-stat-activity | pg_stat_activity长事务执行时长 | 1 | 585 |
| chk-pg-thread-wait-status | pg_thread_wait_status等待事件 | 1 | 594 |
| chk-pg-thread-wait-status-2 | pg_thread_wait_status阻塞源会话 | 1 | 603 |
| chk-gs-asp-2 | gs_asp历史长事务采样记录 | 1 | 612 |
| chk-io | 磁盘IO信息 | 1 | 621 |
| chk-wait-event-count | wait_event_count | 1 | 630 |
| chk-blocked-query | blocked_query | 1 | 639 |
| chk-blocking-query | blocking_query | 1 | 648 |
| chk-pg-total-memory-detail | pg_total_memory_detail | 1 | 657 |
| chk-thread-session-memory-context | thread_session_memory_context | 1 | 666 |
| chk-last-analyze-time | last_analyze_time | 1 | 675 |
| chk-autovacuum-settings | autovacuum_settings | 1 | 684 |
| chk-autoanalyze-threshold | autoanalyze_threshold | 1 | 693 |
| chk-pg-index-indisusable | pg_index_indisusable | 1 | 702 |
| chk-cpu-io | CPU、IO、内存使用率 | 1 | 711 |
| chk-wait-cmd | wait cmd计数 | 1 | 720 |
| chk-tplworker-cpu-idle | TPLworker数量 / CPU idle空闲 | 1 | 729 |
| chk-offcpu | offcpu火焰图 | 2 | 738 |
| chk-n-tuples-fetched-n-tuples-returned | n_tuples_fetched / n_tuples_returned | 1 | 747 |
| chk-t-tuples-fetched | t_tuples_fetched累加次数 | 1 | 756 |
| chk-subtransactions-log | subtransactions log | 1 | 765 |
| chk-xact-is-current-xid | 事务可见性判断函数(xact_is_current_xid)耗时 | 1 | 774 |
| chk--4 | 保存点数量开销 | 1 | 783 |
| chk-sql-2 | 保存点SQL解析开销 | 1 | 792 |
| chk-sql-cpu | SQL CPU消耗 | 1 | 801 |
| chk--5 | 索引列过滤性 | 1 | 810 |
| chk--6 | 活跃会话数 | 1 | 819 |
| chk--7 | 执行计划索引扫描范围 | 1 | 828 |
| chk-asp | ASP数据/等待事件 | 1 | 837 |
| chk-other | other内存增长趋势 | 1 | 846 |
| chk--8 | 内存泄漏信息 | 1 | 855 |
| chk--9 | 代码调用栈/未释放函数 | 1 | 864 |
| chk--10 | 执行计划 | 10 | 873 |
| chk-provolatile-proshippable | 函数属性(provolatile/proshippable) | 1 | 882 |
| chk-sql-3 | 慢SQL数量及系统库大小 | 1 | 891 |
| chk--11 | 备机日志刷盘影响 | 1 | 900 |
| chk-wdr | WDR报告与等待事件 | 1 | 909 |
| chk--12 | 线程等待磁盘返回结果 | 1 | 918 |
| chk-procarraylock | 等待事件ProcArrayLock | 1 | 927 |
| chk--13 | 分布式事务两阶段提交火焰图 | 1 | 936 |
| chk--14 | 语句执行情况与执行计划 | 1 | 945 |
| chk--15 | 代价估算与页面数 | 1 | 954 |
| chk-vacuum | vacuum执行记录 | 1 | 963 |
| chk-sql-4 | 慢SQL与计划跳变排查 | 1 | 972 |
| chk--16 | 分区表统计信息准确性 | 1 | 981 |
| chk-last-vacuum | last_vacuum | 1 | 990 |
| chk-n-tup-hot-upd-n-tup-upd-n-dead-tup-n-live-tup | n_tup_hot_upd / n_tup_upd / n_dead_tup / n_live_tup | 1 | 999 |
| chk--17 | 变长更新语句 | 1 | 1008 |
| chk-thread-pool-attr | thread_pool_attr | 1 | 1017 |
| chk-rpo | 容灾RPO | 1 | 1026 |
| chk--18 | 复制槽推动速度 | 1 | 1035 |
| chk--19 | 网络带宽使用率 | 1 | 1044 |
| chk-io-2 | IO相关等待事件平均时间 | 1 | 1053 |
| chk-io-io | 磁盘IO性能和IO调度算法 | 1 | 1062 |
| chk-cpu-4 | 线程CPU占用率 | 1 | 1071 |
| chk-xlog | xlog生成速率 | 1 | 1080 |
| chk-pgxc-stat-activity-state | pgxc_stat_activity state | 1 | 1089 |
| chk-io-3 | IO使用率 | 1 | 1098 |
| chk-cn | CN节点压力分布 | 1 | 1107 |
| chk-druid | druid连接配置 | 1 | 1116 |
| chk-druid-monitor | druid monitor排队情况 | 1 | 1125 |
| chk--20 | 锁等待事件 | 1 | 1134 |
| chk--21 | 业务代码逻辑 | 1 | 1143 |
| chk-wal | WAL日志产生量 | 1 | 1152 |
| chk-wal-2 | WAL日志类型占比 | 1 | 1161 |
| chk-freeze-page | Freeze Page操作有效性 | 1 | 1170 |
| chk--22 | 磁盘读写线程 | 1 | 1179 |
| chk--23 | 运行时堆栈 | 1 | 1188 |
| chk-gs-log | gs_log日志清理时长 | 1 | 1197 |
| chk-wal-3 | WAL日志清理模式 | 1 | 1206 |
| chk--24 | 事务日志内容 | 1 | 1215 |
| chk-undo-retention-time | undo_retention_time | 1 | 1224 |
| chk-wait-node | wait node等待事件耗时 | 1 | 1233 |
| chk-cn-dn | CN和DN间网络交互次数 | 1 | 1242 |
| chk-poll-interrupt | poll_interrupt接口耗时/线程唤醒耗时 | 1 | 1251 |
| chk-oncpu | oncpu信息 | 1 | 1260 |
| chk-sql-5 | 慢sql语句 | 1 | 1269 |
| chk--25 | 网络包时延 | 1 | 1278 |
| chk-cpu-5 | CPU消耗分布 | 1 | 1287 |
| chk-dropped-packets-count | dropped packets count | 1 | 1296 |
| chk-rx-dropped-call-stack | rx_dropped call stack | 1 | 1305 |
| chk-net-core-netdev-max-backlog | net.core.netdev_max_backlog | 1 | 1314 |
| chk-cpu-cpu-io-tpmc-xlog | 备机CPU、主机CPU、内存使用率、IO、TPMC、Xlog回放速度、日志生成速度 | 1 | 1323 |
| chk--26 | 死元组数/表占用空间 | 1 | 1332 |
| chk-toast | toast表空间占用 | 1 | 1341 |
| chk--27 | 列长度/事务更新频次 | 1 | 1350 |
| chk-wait-xact-commit-command | wait xact commit command耗时 | 1 | 1359 |
| chk-palm-hang-detect-main | palm_hang_detect_main等待锁日志 | 1 | 1368 |
| chk-execution-time | execution_time | 1 | 1377 |
| chk-lwlock-event-procarraylock | LWLOCK_EVENT ProcArrayLock等待事件 | 1 | 1386 |
| chk-unlink-half-dead-page | unlink_half_dead_page索引日志 | 1 | 1395 |
| chk-sql-6 | 慢SQL等待事件统计 | 1 | 1404 |
| chk-cpu-io-2 | CPU、内存、IO使用率 | 1 | 1413 |
| chk--28 | 轻量级锁排他锁等待时间日志 | 1 | 1422 |
| chk--29 | 轻量级锁持锁到放锁的时长 | 1 | 1431 |
| chk--30 | 持锁、等锁线程堆栈 | 1 | 1440 |
| chk-sql-7 | 防饿死线程日志与慢SQL现象 | 1 | 1449 |
| chk-sql-8 | 慢SQL出现频率 | 1 | 1458 |
| chk-sql-details | 慢SQL details等待事件 | 1 | 1467 |
| chk-dn-sql | DN慢SQL信息 | 1 | 1476 |
| chk-az | 网络时延与跨AZ请求 | 1 | 1485 |
| chk-sql-9 | 慢SQL锁次数与软解析次数 | 1 | 1494 |
| chk-client-encoding-server-encoding | client encoding与server encoding配置 | 1 | 1503 |
| chk--31 | 代码分析 | 2 | 1512 |
| chk--32 | 代码定位 | 1 | 1521 |
| chk-data-node-scan | 执行计划下推标识（Data Node Scan） | 1 | 1530 |
| chk-pg-proc-provolatile-proshippable | pg_proc.provolatile / proshippable | 3 | 1539 |
| chk-explain-verbose-remotequery | explain verbose · RemoteQuery 计划 | 1 | 1548 |
| chk-explain-verbose-subplan | explain verbose · SubPlan 执行方式 | 1 | 1557 |
| chk--33 | 执行计划下推标识 | 2 | 1566 |
| chk-pg-proc-provolatile | pg_proc.provolatile | 1 | 1575 |
| chk-explain-verbose-warning | explain verbose WARNING · 统计信息缺失提示 | 1 | 1584 |
| chk-explain-nest-loop-join | EXPLAIN 执行计划 · Nest Loop Join 耗时 | 1 | 1593 |
| chk-enable-hashjoin | enable_hashjoin 关闭后执行计划 | 1 | 1602 |
| chk-explain-verbose-warning-2 | EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表 | 1 | 1611 |
| chk-pg-log-statistics-not-collected | pg_log 日志 · Statistics not collected 日志行 | 1 | 1620 |
| chk-explain-join | EXPLAIN 执行计划 · Join 算子类型及耗时 | 1 | 1629 |
| chk-explain-analyze-a-time-rows-removed-by-filter | explain analyze · A-time / Rows Removed by Filter | 1 | 1638 |
| chk-explain-analyze-nested-loop-a-time | explain analyze · Nested Loop A-time | 1 | 1647 |
| chk-explain-analyze-groupaggregate-a-time-vs-hashaggregate | explain analyze · GroupAggregate A-time vs HashAggregate | 1 | 1656 |
| chk-explain-analyze-a-time | EXPLAIN ANALYZE A-time 瓶颈算子识别 | 1 | 1665 |
| chk-explain-verbose-streaming-vs-data-node-scan | EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan | 1 | 1674 |
| chk-explain-verbose-subplan-2 | EXPLAIN VERBOSE · SubPlan 算子出现在目标列 | 1 | 1683 |
| chk-pg-stat-get-last-data-changed-time | 近期数据变更表列表（pg_stat_get_last_data_changed_time） | 1 | 1692 |
| chk-pgxc-get-table-skewness | PGXC_GET_TABLE_SKEWNESS | 2 | 1701 |
| chk-table-distribution-dn-1w | table_distribution() 各DN空间（大表个数超1W场景） | 1 | 1710 |
| chk-savepoint | 存储过程中 SAVEPOINT 的创建/释放配对 | 1 | 1719 |
| chk-commit-rollback-i-o | COMMIT/ROLLBACK 频率与 I/O 开销 | 1 | 1728 |
| chk-explain-analyze-seq-scan-a-time-total-runtime | EXPLAIN ANALYZE Seq Scan A-time / Total runtime | 1 | 1737 |
| chk-b-tree-explain-analyze | 创建 B-tree 索引后再次 EXPLAIN ANALYZE | 1 | 1746 |
| chk-explain-verbose-warning-3 | EXPLAIN VERBOSE 执行计划 Warning | 2 | 1755 |
| chk-pg-log-statistics-warning | pg_log 日志中的 Statistics WARNING | 1 | 1764 |
| chk-explain-analyze-a-time-seqscan-vs-indexscan | EXPLAIN ANALYZE A-time · SeqScan vs IndexScan | 1 | 1773 |
| chk-explain-analyze-a-time-nestloop | EXPLAIN ANALYZE A-time · NestLoop算子耗时 | 1 | 1782 |
| chk-explain-analyze-a-time-sort-groupagg-vs-hashagg | EXPLAIN ANALYZE A-time · Sort+GroupAgg vs HashAgg | 1 | 1791 |
| chk-explain-analyze-3 | EXPLAIN ANALYZE 执行计划 · 算子耗时 | 1 | 1800 |
| chk-explain-analyze-nestloop | EXPLAIN ANALYZE · NestLoop 算子耗时 | 1 | 1809 |
| chk-explain-analyze-sort-groupagg | EXPLAIN ANALYZE · Sort+GroupAgg 算子耗时 | 1 | 1818 |
| chk-hashaggregate | 执行计划中双层HashAggregate | 1 | 1827 |
| chk--34 | 执行计划子查询关联方式 | 1 | 1836 |
| chk-subplan | 执行计划中SubPlan节点 | 2 | 1845 |
| chk-explain-analyze-total-runtime-partitionscan | EXPLAIN ANALYZE Total runtime / 是否走 PartitionScan | 1 | 1854 |
| chk-local-explain-analyze-total-runtime | 创建 LOCAL 索引后 EXPLAIN ANALYZE Total runtime | 1 | 1863 |
| chk-rds001-cpu-util | rds001_cpu_util | 1 | 1872 |
| chk-rds002-mem-util | rds002_mem_util | 1 | 1881 |
| chk-io-bandwidth-usage | io_bandwidth_usage | 1 | 1890 |
| chk-iops-usage | iops_usage | 1 | 1899 |
| chk-rds007-instance-disk-usage | rds007_instance_disk_usage | 1 | 1908 |
| chk-rds020-avg-disk-ms-per-write | rds020_avg_disk_ms_per_write | 1 | 1917 |
| chk-rds021-avg-disk-ms-per-read | rds021_avg_disk_ms_per_read | 1 | 1926 |
| chk-rds036-deadlocks | rds036_deadlocks | 1 | 1935 |
| chk-rds048-p80 | rds048_P80 | 1 | 1944 |
| chk-rds049-p95 | rds049_P95 | 1 | 1953 |
| chk-rds060-long-running-transaction-exectime | rds060_long_running_transaction_exectime | 1 | 1962 |
| chk-rds063-slowquery-user | rds063_slowquery_user | 1 | 1971 |
| chk-rds065-dynamic-used-memory-usage | rds065_dynamic_used_memory_usage | 1 | 1980 |
| chk-rds066-replication-slot-wal-log-size | rds066_replication_slot_wal_log_size | 1 | 1989 |
| chk-rds070-thread-pool | rds070_thread_pool | 1 | 1998 |
| chk-explain-agg | EXPLAIN 执行计划 Agg 算子模式 | 1 | 2007 |
| chk-copy | COPY 导入是否存在约束冲突类容错需求 | 1 | 2016 |
| chk-explain-verbose-anti-join | EXPLAIN VERBOSE Anti Join 行数估算 | 1 | 2025 |
| chk-explain-verbose-hashjoin | EXPLAIN VERBOSE hashjoin 行数估算 | 1 | 2034 |
| chk-top-gsql-cpu | top · gsql 进程 CPU 占用 | 1 | 2043 |
| chk-pg-stat-statements-total-time-calls | pg_stat_statements · total_time + calls (慢查询统计) | 1 | 2052 |
| chk-explain-performance-dn | explain performance 各 DN 实际行数 | 1 | 2061 |
| chk-table-skewness-dn | table_skewness() 各 DN 数据分布比例 | 1 | 2070 |
| chk-explain-analyze-streaming-redistribute-dn | EXPLAIN ANALYZE Streaming(REDISTRIBUTE) 各 DN 输出行数 | 1 | 2079 |
| chk-pg-stat-get-last-data-changed-time-2 | pg_stat_get_last_data_changed_time 最近变更的表 | 1 | 2088 |
| chk-table-distribution-dn | table_distribution() 各 DN 存储空间分布 | 1 | 2097 |
| chk-xc-node-id | 按 xc_node_id 分组的表数据行数 | 1 | 2106 |
| chk-explain-streaming | EXPLAIN 计划是否含 Streaming | 1 | 2115 |
| chk-explain-streaming-2 | 调整后 EXPLAIN 是否消除 Streaming | 1 | 2124 |
| chk-explain-groupagg-sort | EXPLAIN · 算子(GroupAgg+Sort) | 1 | 2133 |
| chk-explain-analyze-hashjoin-dn | EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围 | 1 | 2142 |
| chk-memory-information-dn | Memory Information 各 DN 内存消耗分布 | 1 | 2151 |
| chk-seq-scan-dn | Seq Scan 各 DN 扫描时间 | 1 | 2160 |
| chk-explain-analyze-4 | EXPLAIN ANALYZE 顺序扫描耗时 | 1 | 2169 |
| chk-explain-seqscan-vs-indexscan | EXPLAIN · 算子(seqscan vs indexscan) | 1 | 2178 |
| chk-explain-join-2 | EXPLAIN 执行计划 Join 类型 | 1 | 2187 |
| chk-explain-analyze-5 | EXPLAIN ANALYZE 执行计划耗时与过滤行数 | 1 | 2196 |
| chk-explain-analyze-join | EXPLAIN ANALYZE Join 算子类型与耗时 | 1 | 2205 |
| chk-explain-analyze-agg | EXPLAIN ANALYZE Agg 算子类型 | 1 | 2214 |
| chk-iostat-util-r-await-w-await | iostat 中 %util / r_await / w_await | 1 | 2223 |
| chk-pidstat-iotop-i-o | pidstat / iotop 显示线程 I/O 消耗 | 1 | 2232 |
| chk-pg-thread-wait-status-pg-stat-activity-i-o-sql | pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL | 1 | 2241 |
| chk-top-sar-gaussdb-cpu | top / sar 中 gaussdb 进程 CPU 占用 | 1 | 2250 |
| chk-wdr-top-sql-order-by-cpu-time | WDR 报告 Top SQL order by CPU Time | 1 | 2259 |
| chk--35 | 内核代码热点函数火焰图 | 1 | 2268 |
| chk-guc-shared-buffers-work-mem-thread-pool-attr | GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值 | 1 | 2277 |
| chk-session-package | SESSION 中 PACKAGE 变量数量与内存占用 | 1 | 2286 |
| chk-explain-filter | EXPLAIN 执行计划 Filter 条件分析 | 1 | 2295 |
| chk-pg-proc-volatility | pg_proc 函数 volatility 类型查询 | 1 | 2304 |
| chk-explain | EXPLAIN 执行计划算子估算行数 | 1 | 2313 |
| chk-explain-stream | EXPLAIN 执行计划 Stream 算子类型 | 1 | 2322 |
| chk-exception | 存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销 | 1 | 2331 |
| chk--36 | 存储过程默认权限模式 | 1 | 2340 |
| chk-explain-remotequery-data-node-scan | EXPLAIN · 是否含 RemoteQuery / Data Node Scan | 1 | 2349 |
| chk-explain-performance-2 | EXPLAIN PERFORMANCE 算子耗时 | 1 | 2358 |
| chk-scan-filter | Scan filter 条件分析 | 1 | 2367 |
| chk-explain-cn-vs-dn | EXPLAIN 执行计划算子位置（CN vs DN） | 1 | 2376 |
| chk-group-by-groupagg-sort | GROUP BY 查询计划中是否包含 GroupAgg+Sort | 1 | 2385 |
| chk-not-in | 含 NOT IN 子查询的执行计划 | 1 | 2394 |
| chk-explain-2 | EXPLAIN · 计划与实际行数比对 | 1 | 2403 |
| chk-explain-data-node-scan-on | EXPLAIN 输出中 "Data Node Scan on" 是否在第一行 | 1 | 2412 |
| chk-explain-subplan | EXPLAIN 执行计划 SubPlan 存在 | 1 | 2421 |
| chk-dn-cpu | 备DN CPU使用率 · 回放线程资源 | 1 | 2430 |
| chk-explain-verbose | EXPLAIN VERBOSE 统计信息警告 | 1 | 2439 |
| chk-pg-log | pg_log 统计信息缺失日志 | 1 | 2448 |
| chk--37 | 执行计划子查询处理方式 | 1 | 2457 |
| chk-explain-analyze-stream | EXPLAIN ANALYZE · Stream算子类型 | 1 | 2466 |
| chk-explain-analyze-startup-vs-total | EXPLAIN ANALYZE · 路径代价 (Startup vs Total) | 1 | 2475 |
| chk-nestloop-2 | 语句执行时间 / 执行计划中 NestLoop 算子 | 1 | 2484 |
| chk-pgxc-wlm-session-history-block-time-duration | pgxc_wlm_session_history · block_time / duration | 1 | 2493 |
| chk-pgxc-wlm-session-history | pgxc_wlm_session_history · 同期并发作业数 | 1 | 2502 |
| chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn- | pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent | 1 | 2511 |
| chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ | GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write | 1 | 2520 |
| chk-explain-performance-windowagg-sort | EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时 | 1 | 2529 |
| chk-explain-performance-sql-streaming-redistribute | EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜） | 1 | 2538 |
| chk-order-line-id-null | 列统计信息 · ORDER_LINE_ID NULL 比例 | 1 | 2547 |
| chk-pgxc-wlm-session-history-dataskew-warning | pgxc_wlm_session_history · DataSkew warning | 1 | 2556 |
| chk-pgxc-wlm-session-history-large-table-in-broadcast-warning | pgxc_wlm_session_history · Large Table in Broadcast warning | 1 | 2565 |
| chk-pgxc-wlm-session-history-spill | pgxc_wlm_session_history · Spill告警 | 1 | 2574 |
| chk-pgxc-wlm-session-history-nestloop | pgxc_wlm_session_history · NestLoop大表告警 | 1 | 2583 |
| chk-dn | 各DN磁盘利用率 | 1 | 2592 |
| chk-pgxc-thread-wait-status-wait-status | pgxc_thread_wait_status.wait_status | 1 | 2601 |
| chk-table-skewness-table-distribution | table_skewness / table_distribution | 1 | 2610 |
| chk-warning | 执行计划统计信息Warning | 1 | 2619 |
| chk-remote | 执行计划下推标识（__REMOTE关键字） | 1 | 2628 |
| chk-nestloop-3 | 执行计划算子类型（NestLoop） | 1 | 2637 |
| chk-partitioned-cstore-scan | 执行计划：Partitioned CStore Scan分区扫描范围 | 1 | 2646 |
| chk--38 | 线程等待状态 | 1 | 2655 |
| chk-vecnestloopruntime | 进程堆栈（VecNestLoopRuntime） | 1 | 2664 |
| chk-sql-create-index | 活跃SQL及CREATE INDEX语句 | 1 | 2673 |
| chk--39 | 表数据倾斜 | 1 | 2682 |
| chk-max-process-memory-shared-buffers | 内存参数：max_process_memory, shared_buffers | 1 | 2691 |
| chk-in | 执行计划in条件处理方式 | 1 | 2700 |
| chk-sql-case-when | SQL 中 CASE WHEN 分支数量与执行次数 | 1 | 2709 |
| chk--40 | 系统表/用户表膨胀情况 | 1 | 2718 |
| chk-dn-xc-node-id | 各 DN 数据量分布 (xc_node_id 分组) | 1 | 2727 |
| chk-pgxc-stat-table-dirty | 表脏页率 (PGXC_STAT_TABLE_DIRTY) | 1 | 2736 |
| chk-gds | GDS导入作业日志 | 1 | 2745 |
| chk-fe-sync-be-parsecomplete | FE=>Sync 与 <=BE ParseComplete 日志时间间隔 | 1 | 2754 |
| chk-be-datarow-select-count | <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小 | 1 | 2763 |
| chk-modifyjdbccall-createparameterizedquery | modifyJdbcCall / createParameterizedQuery 阶段耗时 | 1 | 2772 |
| chk-period-ttl | 分区表 period / ttl 参数设置 | 1 | 2781 |
| chk-analyze-2 | ANALYZE 后的查询性能 | 1 | 2790 |
| chk--41 | 查询返回行数 | 1 | 2799 |
| chk--42 | 主机负载下查询单独运行时延 | 1 | 2808 |
| chk--43 | 重复执行同一查询语句的执行时间 | 1 | 2817 |
| chk-disk-cache-pgxc-disk-cache-all-stats | Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats) | 1 | 2826 |
| chk-evs | EVS 磁盘空间占用百分比 | 1 | 2835 |
| chk-bucket | 入库分区数 / Bucket 数 / 攒批内存消耗 | 1 | 2844 |
| chk-pgxc-get-stat-all-tables-dirty-page-rate | PGXC_GET_STAT_ALL_TABLES.dirty_page_rate | 2 | 2853 |
| chk-explain-index-scan | EXPLAIN 执行计划 · 是否使用Index Scan | 1 | 2862 |
| chk-explain-indexscan | EXPLAIN 执行计划 · 是否选择IndexScan | 1 | 2871 |
| chk-explain-verbose-index-scan-vs-seq-scan | EXPLAIN VERBOSE · Index Scan vs Seq Scan | 1 | 2880 |
| chk-waiting-in-queue | 查询等待状态 · waiting in queue | 1 | 2889 |
| chk-explain-or-filter | EXPLAIN 执行计划 · 系统视图权限OR filter | 1 | 2898 |
| chk-dn-2 | 各DN数据量分布 | 1 | 2907 |
| chk-cn-2 | CN日志中不下推原因 | 1 | 2916 |
| chk-explain-verbose-warning-4 | EXPLAIN VERBOSE WARNING信息 · 统计信息缺失 | 1 | 2925 |
| chk-hstore-delta-vs-cu | HStore Delta表大小 vs 主表CU数据 | 1 | 2934 |
| chk-enable-codegen | enable_codegen 参数状态 | 1 | 2943 |
| chk-pgxc-wlm-session-info-streaming-stream-count | pgxc_wlm_session_info · Streaming 算子数（stream_count） | 1 | 2952 |
| chk-pgxc-wlm-session-info-max-cpu-time-cpu | pgxc_wlm_session_info · max_cpu_time（高CPU语句） | 1 | 2961 |
| chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has | pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史） | 1 | 2970 |
| chk-resource-track-level-operator-realtime | resource_track_level · operator_realtime 级别实时算子监控 | 1 | 2979 |
| chk-pgxc-stat-activity-state-waiting-enqueue | PGXC_STAT_ACTIVITY · state / waiting / enqueue | 1 | 2988 |
| chk-pgxc-stat-activity-runtime-current-timestamp-query-start | PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start) | 1 | 2997 |
| chk-pgxc-stat-activity-waiting-true | PGXC_STAT_ACTIVITY · waiting=true 阻塞查询 | 1 | 3006 |
| chk-pg-locks | pg_locks · 阻塞会话与持锁会话关联 | 1 | 3015 |
| chk-dws-connector-connectiontimeout | DWS-Connector connectionTimeOut 默认值 | 1 | 3024 |
| chk-pgxc-lock-conflicts | pgxc_lock_conflicts 锁冲突视图 | 1 | 3033 |
| chk-pg-stat-activity-pg-locks-sql-8-0-x | pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本） | 1 | 3042 |
| chk--44 | 写入方式 | 1 | 3051 |
| chk-pgxc-stat-activity-state-waiting-query | pgxc_stat_activity · state / waiting / query | 1 | 3060 |
| chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic- | pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory | 1 | 3069 |
| chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc | pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent | 1 | 3078 |
| chk-vs | 列存表物理大小 vs 有效数据量 | 1 | 3087 |
| chk--45 | 各节点磁盘使用率均衡性 | 1 | 3096 |
| chk-pgxc-thread-wait-status-dn | pgxc_thread_wait_status · 作业等待 DN 分布 | 1 | 3105 |
| chk-explain-performance-dn-2 | explain performance · DN 行数与耗时分布 | 1 | 3114 |
| chk-table-skewness | table_skewness · 数据倾斜率 | 1 | 3123 |
| chk-pgxc-get-table-skewness-2 | pgxc_get_table_skewness · 全库倾斜视图 | 1 | 3132 |
| chk-cn-pg-log-warning | CN pg_log 日志中 Warning 信息 | 1 | 3141 |
| chk-explain-verbose-remote | EXPLAIN VERBOSE · __REMOTE 关键字 | 1 | 3150 |
| chk-cn-3 | CN日志 · 不下推原因 | 1 | 3159 |
| chk-nestloop-4 | 执行计划算子类型（NestLoop出现） | 1 | 3168 |
| chk-explain-partitioned-cstore-scan-selected-partitions | EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量 | 1 | 3177 |
| chk-i-o-cpu | 系统资源 I/O / 内存 / CPU 使用情况 | 1 | 3186 |
| chk-pg-thread-wait-status-3 | pg_thread_wait_status · 线程等待状态 | 1 | 3195 |
| chk-gstack-vecnestloopruntime | gstack · 进程堆栈中 VecNestLoopRuntime | 1 | 3204 |
| chk-pg-stat-activity-sql | pg_stat_activity 活跃SQL | 2 | 3213 |
| chk--46 | 表倾斜情况 | 1 | 3222 |
| chk-max-process-memory-shared-buffers-work-mem | max_process_memory / shared_buffers / work_mem 内存参数 | 1 | 3231 |
| chk-vs-2 | 脏数据膨胀率 / 表实际大小 vs 有效数据量 | 1 | 3240 |
| chk-explain-3 | EXPLAIN执行计划耗时分布 | 1 | 3249 |
| chk-cstore-scan | 执行计划算子：CStore Scan耗时占比 | 1 | 3258 |
| chk-pg-session-wlmstat-status-statement-mem | pg_session_wlmstat · status / statement_mem | 1 | 3267 |
| chk-cudesc-cu-row-count | cudesc表中CU的row_count分布 | 1 | 3276 |
| chk-cu | 执行计划中CU扫描数量 | 1 | 3285 |
| chk-explain-cstore-scan-cusome-cunone | EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数 | 1 | 3294 |
| chk-explain-scan-vs | EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数 | 1 | 3303 |
| chk--47 | 表脏页率 | 1 | 3312 |
| chk-explain-scan-a-time-max-min-dn | EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比 | 1 | 3321 |
| chk-table-distribution-dn-2 | table_distribution 各DN数据行数 | 1 | 3330 |
| chk-explain-seq-scan-vs-index-scan | EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan） | 1 | 3339 |
| chk-explain-selected-partitions | EXPLAIN 执行计划 · Selected Partitions 数量 | 1 | 3348 |
| chk-pgxc-thread-wait-status-wait-status-wait-event | pgxc_thread_wait_status · wait_status / wait_event | 1 | 3357 |
| chk-pg-partition | pg_partition 各表分区数 | 1 | 3366 |
| chk-pv-total-memory-detail-process-used-memory-vs-max-process-me | pv_total_memory_detail · process_used_memory vs max_process_memory | 1 | 3375 |
| chk-pgxc-lock-conflicts-8-1-x | pgxc_lock_conflicts 锁冲突（8.1.x及以上） | 1 | 3384 |
| chk-pgxc-stat-activity-vacuum-full-8-0-x | pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前） | 1 | 3393 |
| chk-pgxc-thread-wait-status | pgxc_thread_wait_status 锁等待状态 | 1 | 3402 |
| chk-pck | 表定义是否存在PCK | 1 | 3411 |
| chk-psort-work-mem | psort_work_mem 参数值 | 1 | 3420 |
| chk--48 | 列存表文件大小监控 | 1 | 3429 |
| chk-abort-transaction-due-to-concurrent-update | 数据库错误日志 · abort transaction due to concurrent update | 1 | 3438 |
| chk-dn-3 | 各 DN 数据条数分布 | 1 | 3447 |
| chk-pgxc-get-table-skewness-3 | PGXC_GET_TABLE_SKEWNESS 视图 | 1 | 3456 |
| chk-dms | DMS 监控 · 节点磁盘使用率 | 1 | 3465 |
| chk-explain-agg-hashagg-gather-vs-redistribute-hashagg | EXPLAIN · Agg 计划形态（hashagg+gather vs redistribute+hashagg） | 1 | 3474 |
| chk-explain-verbose-anti-join-2 | EXPLAIN VERBOSE · Anti Join 执行计划及行数估算 | 1 | 3483 |
| chk-explain-verbose-hashjoin-2 | EXPLAIN VERBOSE · HashJoin 行数估算偏差 | 1 | 3492 |
| chk-dn-4 | 磁盘利用率各 DN 差异 | 1 | 3501 |
| chk-explain-performance-dn-scan | EXPLAIN PERFORMANCE 各 DN 基表 scan 行数及时间分布 | 1 | 3510 |
| chk-table-skewness-table-distribution-2 | table_skewness / table_distribution · 表数据倾斜率 | 1 | 3519 |
| chk-explain-performance-stream-dn | EXPLAIN PERFORMANCE · Stream 算子各 DN 行数分布 | 1 | 3528 |
| chk-dms-max-min | DMS · 节点磁盘使用率排序 (max - min) | 1 | 3537 |
| chk-explain-streaming-type-redistribute | EXPLAIN · Streaming(type: REDISTRIBUTE) 算子是否出现 | 1 | 3546 |
| chk-cpu-1-3-12-24 | 节点 CPU 使用率 (1/3/12/24 小时) | 1 | 3555 |
| chk-cpu-6 | 资源池 CPU 限额 / 配额配置 | 1 | 3564 |
| chk-pgxc-stat-activity-state-2 | pgxc_stat_activity state 字段 | 1 | 3573 |
| chk-cn-savepoint-release | 各 CN 上 SAVEPOINT/RELEASE 语句分布 | 1 | 3582 |
| chk-explain-join-nestloop-vs-hashjoin | EXPLAIN · JOIN 算子类型 (NestLoop vs HashJoin) | 1 | 3591 |
| chk-explain-performance-3 | EXPLAIN PERFORMANCE · 基表扫描方式及执行时间 | 1 | 3600 |
| chk-explain-in-join | EXPLAIN · in 条件是否转为 join | 1 | 3609 |
| chk-explain-4 | EXPLAIN · 执行计划顺序扫描阶段耗时 | 1 | 3618 |
| chk-explain-verbose-not-in | EXPLAIN VERBOSE · NOT IN 执行计划算子类型 | 1 | 3627 |
| chk-explain-verbose-not-exists | EXPLAIN VERBOSE · NOT EXISTS 执行计划算子类型验证 | 1 | 3636 |
| chk-base-pgsql-tmp-pgsql-tmp-queryid-pid | base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件 | 1 | 3645 |
| chk-pgxc-thread-wait-status-wait-status-write-file | pgxc_thread_wait_status · wait_status='write file' | 1 | 3654 |
| chk-explain-performance-spill-written-disk-temp-file-num | EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字 | 1 | 3663 |
| chk-topsql-spill-info | TopSQL.spill_info | 1 | 3672 |
| chk-explain-analyze-6 | EXPLAIN ANALYZE · 基表扫描算子类型及执行时间 | 1 | 3681 |
| chk-explain-analyze-join-2 | EXPLAIN ANALYZE · JOIN 算子类型及执行时间 | 1 | 3690 |
| chk-explain-analyze-agg-2 | EXPLAIN ANALYZE · Agg 算子类型及执行时间 | 1 | 3699 |
| chk-explain-analyze-verbose-sql-partition-iterator | EXPLAIN ANALYZE VERBOSE · SQL 自诊断信息 + Partition Iterator 扫描分区数 | 1 | 3708 |
| chk-explain-analyze-verbose-partition-iterator-iterations | EXPLAIN ANALYZE VERBOSE · 改写后 Partition Iterator Iterations | 1 | 3717 |
| chk-explain-performance-partition-iterator-iterations | EXPLAIN PERFORMANCE · 全表扫描时间及 Partition Iterator Iterations | 1 | 3726 |
| chk-explain-performance-cunone-filter | EXPLAIN PERFORMANCE · CUNone 比例及 filter 耗时 | 1 | 3735 |
| chk-explain-performance-cstore-scan-cu | EXPLAIN PERFORMANCE · CStore Scan CU 加载数量 | 1 | 3744 |
| chk-explain-performance-4 | explain performance 执行时间 | 1 | 3753 |
| chk-leading-hint | 加 leading hint 后执行时间 | 1 | 3762 |
| chk-leading-no-nestloop-hint | 加 leading + no nestloop hint 后执行时间 | 1 | 3771 |
| chk-rows-hint | rows hint 后执行时间 | 1 | 3780 |
| chk-skew-hint-agg | skew hint 后双层 Agg 计划 | 1 | 3789 |
| chk-explain-performance-vs-a-rows-vs-e-rows | EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows） | 1 | 3798 |
| chk-explain-performance-rows-hint | EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时 | 1 | 3807 |
| chk-explain-data-node-scan | EXPLAIN · 是否含 Data Node Scan 节点 | 1 | 3816 |
| chk-explain-performance-5 | EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子 | 1 | 3825 |
| chk-copy-2 | COPY 语句等待视图 · 轻量级锁等待 | 1 | 3834 |
| chk-explain-performance-vector-windowagg | EXPLAIN PERFORMANCE 执行计划 · Vector WindowAgg 耗时及位置 | 1 | 3843 |
| chk-explain-performance-6 | EXPLAIN PERFORMANCE 改写后执行计划 · 排序下推验证 | 1 | 3852 |
| chk-gs-wlm-session-history-warning-sql | GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息 | 2 | 3861 |
| chk-gs-wlm-session-history-warning | GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警 | 1 | 3870 |
| chk-explain-performance-cpu-io | EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络) | 1 | 3879 |
| chk-xid | 当前事务 XID | 1 | 3888 |
| chk--49 | 活跃事务列表 | 1 | 3897 |
| chk-vacuum-defer-cleanup-age | vacuum_defer_cleanup_age 参数值 | 1 | 3906 |
| chk-gtm-snapshot-oldestxmin-xid | GTM snapshot · oldestxmin 与 xid 差值 | 1 | 3915 |
| chk-pgxc-running-xacts | 老事务列表 (pgxc_running_xacts) | 1 | 3924 |
| chk-dn-warning | DN 间导入行数倾斜率(WARNING) | 1 | 3933 |
| chk-pg-stat-activity-idle | pg_stat_activity · idle 连接数 | 1 | 3942 |
| chk-explain-performance-7 | EXPLAIN PERFORMANCE · 算子分布 | 1 | 3951 |
| chk-a-time-dn | 算子 A-time(在单 DN 上的运行耗时) | 1 | 3960 |
| chk-wiredtiger-cache-bytes-currently-in-the-cache | wiredTiger.cache.bytes_currently_in_the_cache | 1 | 3969 |
| chk-replication-lag | replication_lag | 1 | 3978 |
| chk-mongod-process-state | mongod_process_state | 1 | 3987 |
| chk-mongod-nofile-nproc-fsize-memlock-ulimit | mongod 进程 nofile / nproc / fsize / memlock 等 ulimit | 1 | 3996 |
| chk-sharding-balancer-migration-24h-results-sharding-collection- | sharding.balancer.migration_24h_results · sharding.collection.chunks_per_shard | 1 | 4005 |
| chk-log-sharding-migrationfailed-error | log.SHARDING.MigrationFailed.error | 1 | 4014 |
| chk-sh-movechunk-errmsg | sh.moveChunk.errmsg | 1 | 4023 |
| chk-sharding-collection-jumbo-chunks | sharding.collection.jumbo_chunks | 1 | 4032 |
| chk-currentop-locks-currentop-waitingforlock | currentOp.locks · currentOp.waitingForLock | 1 | 4041 |
| chk-wiredtiger-cache-pages-written-from-cache-pages-read-into-ca | wiredTiger.cache.pages written from cache / pages read into cache | 1 | 4050 |
| chk-mongod | mongod 进程栈采样函数命中分布 | 1 | 4059 |
| chk-wiredtiger-cache-used-mongostat-used | wiredTiger cache used % (mongostat 输出列 used) | 1 | 4068 |
| chk-db-collection-stats-1024-1024-size-totalindexsize | db.collection.stats(1024*1024).size + totalIndexSize | 1 | 4077 |
| chk-serverstatus-tcmalloc-tcmalloc-pageheap-free-bytes | serverStatus.tcmalloc.tcmalloc.pageheap_free_bytes | 1 | 4086 |
| chk-serverstatus-tcmalloc-tcmalloc-pageheap-unmapped-bytes | serverStatus.tcmalloc.tcmalloc.pageheap_unmapped_bytes | 1 | 4095 |
| chk-mongod-rss | mongod 进程 RSS | 2 | 4104 |
| chk-proc-meminfo-memfree | /proc/meminfo MemFree | 1 | 4113 |
| chk-mongod-tcmalloc-tcmalloc-generic-heap-size-current-allocated | mongod tcmalloc.tcmalloc.generic.heap_size / current_allocated_bytes / pageheap_free_bytes | 1 | 4122 |
| chk-mongod-vsz | mongod 进程 VSZ | 1 | 4131 |
| chk-wiredtiger-cache-dirty | wiredTiger cache dirty % | 1 | 4140 |
| chk-globallock-currentqueue-total | globalLock.currentQueue.total | 2 | 4149 |
| chk-globallock-totaltime-vs-uptime | globalLock.totalTime_vs_uptime | 1 | 4158 |
| chk-locks-avg-acquire-wait-micros | locks.avg_acquire_wait_micros | 1 | 4167 |
| chk-explain-executiontimemillis-per-page | explain.executionTimeMillis_per_page | 1 | 4176 |
| chk-disk-io-util | disk_io_util | 1 | 4185 |
| chk-mongostat-qrw-arw-or-slow-log-count | mongostat.qrw_arw_or_slow_log_count | 1 | 4194 |
| chk-mongod-log-collscan-count | mongod.log.COLLSCAN_count | 1 | 4203 |
| chk-mongod-log-slow-query-1-10s | mongod.log.slow_query_1_10s | 1 | 4212 |
| chk-currentop-secs-running | currentOp.secs_running | 1 | 4221 |
| chk-wiredtiger-cache-bytes-currently-in-the-cache-wiredtiger-cac | wiredTiger.cache.bytes currently in the cache / wiredTiger.cache.maximum bytes configured | 1 | 4230 |
| chk-wiredtiger-cache-eviction-worker-thread-evicting-pages-appli | wiredTiger.cache.eviction worker thread evicting pages / application thread time evicting | 1 | 4239 |
| chk-flamegraph-snappy-cpu-pct | flamegraph.snappy.cpu_pct | 1 | 4248 |
| chk-application-thread-concurrency-setting-business-tps | application thread concurrency setting + business TPS | 1 | 4257 |
| chk-application-linked-memory-allocator-library | application linked memory allocator library | 1 | 4266 |
| chk-aggregation-pipeline-duration | aggregation_pipeline_duration | 1 | 4275 |
| chk-lookup-pipeline-stage | 慢查询中 $lookup pipeline stage 出现频率 | 1 | 4284 |
| chk-indexstats-accesses-ops | $indexStats accesses.ops · 每索引使用次数 | 1 | 4293 |
| chk-collstats-avgobjsize-p99 | collStats.avgObjSize / 文档大小 P99 | 1 | 4302 |
| chk-atlas-query-targeting-scanned-returned-scanned-objects-retur | Atlas Query Targeting: Scanned/Returned & Scanned Objects/Returned | 1 | 4311 |
| chk-mongod-slow-query-log-plansummary-keysexamined-docsexamined- | mongod slow query log: planSummary / keysExamined / docsExamined / nreturned | 1 | 4320 |
| chk-explain-executionstats | explain.executionStats | 1 | 4329 |
| chk-operation-execution-time-ms-plansummary | Operation Execution Time (ms) + planSummary | 1 | 4338 |
| chk-docsexamined-keysexamined-docs-examined-returned-ratio | docsExamined / keysExamined / Docs Examined : Returned Ratio | 1 | 4347 |
| chk-numyields-usedindex-hassort | numYields / usedIndex / hasSort | 1 | 4356 |
| chk-globallock-totaltime-uptime | globalLock.totalTime / uptime | 1 | 4365 |
| chk-locks-type-deadlockcount-locks-type-timeacquiringmicros-acqu | locks.<type>.deadlockCount + locks.<type>.timeAcquiringMicros / acquireWaitCount | 1 | 4374 |
| chk-connections-current-connections-available | connections.current / connections.available | 1 | 4383 |
| chk-connections-current-vs-workload-opcounters | connections.current vs workload (opcounters) | 1 | 4392 |
| chk-wiredtiger-concurrenttransactions-read-write-available-out-t | wiredTiger.concurrentTransactions.{read,write}.{available,out,totalTickets} | 1 | 4401 |
| chk-queues-execution-read-queues-execution-write | queues.execution.read / queues.execution.write | 1 | 4410 |
| chk-replsetgetstatus-members-optimedate-oplog-window | replSetGetStatus.members[].optimeDate / oplog window | 1 | 4419 |
| chk-metrics-cursor-open-total-opcounters-query-getmore | metrics.cursor.open.total / opcounters.{query,getmore} | 1 | 4428 |
| chk-metrics-operation-scanandorder | metrics.operation.scanAndOrder | 1 | 4437 |
| chk-system-profile-slow-query-log-collstats-avgobjsize | system.profile / slow query log + collStats.avgObjSize 趋势 | 1 | 4446 |
| chk-driver-maxpoolsize | driver maxPoolSize · 应用层典型并发请求数 | 1 | 4455 |
| chk-dbpath | dbPath 挂载点文件系统类型 | 2 | 4464 |
| chk-tuned-adm-active-profile | tuned-adm active 当前 profile 名 | 1 | 4473 |
| chk-mongod-version-uname-r | mongod --version + uname -r | 1 | 4482 |
| chk-net-ipv4-tcp-keepalive-time | net.ipv4.tcp_keepalive_time | 1 | 4491 |
| chk-mongod-startup-log-numa-warning | mongod startup log · NUMA warning 行 | 1 | 4500 |
| chk-numad | numad 进程 | 1 | 4509 |
| chk-vm-swappiness | vm.swappiness | 1 | 4518 |
| chk-ec2-instance-type-enhanced-networking-ebs-provisioned-iops | EC2 instance type / Enhanced Networking 状态 / EBS provisioned IOPS | 1 | 4527 |
| chk-tcmalloc-usingpercpucaches-tcmalloc-tcmalloc-cpu-free | tcmalloc.usingPerCPUCaches / tcmalloc.tcmalloc.cpu_free | 1 | 4536 |
| chk-glibc-pthread-rseq-tunable-glibc-tunables-env | glibc.pthread.rseq tunable / GLIBC_TUNABLES env | 1 | 4545 |
| chk-kernel-version | kernel version | 1 | 4554 |
| chk-mongod-log-wt-cache-full | mongod log "WT_CACHE_FULL" 出现频次 | 1 | 4563 |
| chk-dbstats-collstats-size-vs-inmemorysizegb | dbStats / collStats 总 size vs inMemorySizeGB | 1 | 4572 |
| chk-replsetgetstatus-members-statestr-primary-secondary-arbiter | replSetGetStatus.members[] 的 stateStr 分布(PRIMARY/SECONDARY/ARBITER) | 1 | 4581 |
| chk-secondary-health-state-optimedate-primary | secondary 的 health/state · optimeDate 与 primary 的差距 | 1 | 4590 |
| chk-getdefaultrwconcern-defaultwriteconcern-w | getDefaultRWConcern → defaultWriteConcern.w | 1 | 4599 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 4608 |
| chk-explain-queryplanner-winningplan-sort-stage | explain.queryPlanner.winningPlan SORT stage 是否存在 | 1 | 4617 |
| chk-sort-useddisk-sort-spills-sort-spilledbytes-sort-spilledreco | $sort.usedDisk / $sort.spills / $sort.spilledBytes / $sort.spilledRecords / $sort.spilledDataStorageSize | 1 | 4626 |
| chk-driver-connecttimeoutms-vs | driver connectTimeoutMS 当前值 vs 副本集成员最长网络延迟 | 1 | 4635 |
| chk-driver-sockettimeoutms-vs | driver socketTimeoutMS 当前值 vs 应用最慢合法操作耗时 | 1 | 4644 |
| chk-driver-minpoolsize-real-time-connection | driver minPoolSize · 服务器日志 / real time 面板 connection 创建速率 | 1 | 4653 |
| chk-driver-maxpoolsize-2 | driver maxPoolSize · 应用活跃线程数 / 实际每秒操作数 | 1 | 4662 |
| chk-driver-maxpoolsize-cpu-connection-accept-rate | driver maxPoolSize · 服务端 CPU% · connection accept rate | 1 | 4671 |
| chk-explain-executionstats-executiontimemillis | explain.executionStats.executionTimeMillis | 1 | 4680 |
| chk-explain-executionstats-executionstages-inputstage-stage | explain.executionStats.executionStages.inputStage.stage | 1 | 4689 |
| chk-executionstats-totalkeysexamined-executionstats-totaldocsexa | executionStats.totalKeysExamined / executionStats.totalDocsExamined | 1 | 4698 |
| chk-executionstats-totaldocsexamined-executionstats-nreturned | executionStats.totalDocsExamined / executionStats.nReturned | 2 | 4707 |
| chk-profile-slowms-profile-samplerate-profile-was | profile.slowms / profile.sampleRate / profile.was | 1 | 4716 |
| chk-sys-kernel-mm-transparent-hugepage-enabled-defrag-khugepaged | /sys/kernel/mm/transparent_hugepage/{enabled,defrag,khugepaged/defrag} | 1 | 4725 |
| chk-syncedto-time-per-secondary | syncedTo time per secondary | 1 | 4734 |
| chk-flowcontrol-islagged | flowControl.isLagged | 1 | 4743 |
| chk-replication-lag-seconds | Replication Lag (seconds) | 1 | 4752 |
| chk-replication-headroom | Replication Headroom | 1 | 4761 |
| chk-network-metrics | Network metrics | 1 | 4770 |
| chk-mongod-slow-log-workingmillis | mongod_slow_log.workingMillis | 1 | 4779 |
| chk-workingmillis-vs-totaltimequeuedmicros | workingMillis_vs_totalTimeQueuedMicros | 1 | 4788 |
| chk-mongod-resident-memory | mongod_resident_memory | 1 | 4797 |
| chk-heap-profile-alloc-hotspots | heap_profile_alloc_hotspots | 1 | 4806 |
| chk-queryhash-uniqueness-per-shape | queryHash_uniqueness_per_shape | 1 | 4815 |
| chk-plancache-entries-count | planCache.entries_count | 1 | 4824 |
| chk-queryframework-per-version | queryFramework_per_version | 1 | 4833 |
| chk-sh-getbalancerstate | sh.getBalancerState() | 1 | 4842 |
| chk-sh-status-verbose-jumbo-flag | sh.status verbose 输出中的 jumbo flag | 1 | 4851 |
| chk-config-chunks-jumbo-true | config.chunks { jumbo: true } | 1 | 4860 |
| chk-getsharddistribution-per-shard-data-docs-chunks | getShardDistribution: per-shard data / docs / chunks | 1 | 4869 |
| chk-hostinfo-system-memsizemb-memlimitmb | hostInfo.system.memSizeMB / memLimitMB | 1 | 4878 |
| chk-wiredtiger-cache-maximum-bytes-configured | wiredTiger.cache."maximum bytes configured" | 1 | 4887 |
| chk-operator-version-replsets-resources-limits-cpu | operator version + replsets.resources.limits.cpu | 1 | 4896 |
| chk-wiredtiger-cache-maximum-bytes-configured-2 | wiredTiger.cache.maximum bytes configured | 1 | 4905 |
| chk-serverstatus-tcmalloc-usingpercpucaches | serverStatus.tcmalloc.usingPerCpuCaches | 1 | 4914 |
| chk-serverstatus-tcmalloc-tcmalloc-cpu-free | serverStatus.tcmalloc.tcmalloc.cpu_free | 1 | 4923 |
| chk-uname-r-kernel-version | uname -r kernel version | 1 | 4932 |
| chk-sys-kernel-mm-transparent-hugepage-enabled | /sys/kernel/mm/transparent_hugepage/enabled | 1 | 4941 |
| chk-explain-queryplanner-winningplan-stage-sort | explain.queryPlanner.winningPlan.stage(子节点是否含 SORT) | 1 | 4950 |
| chk-flamegraph-cpu-stack-profile | flamegraph CPU stack profile | 1 | 4959 |
| chk-getdefaultrwconcern-defaultwriteconcern | getDefaultRWConcern.defaultWriteConcern | 1 | 4968 |
| chk-rs-conf-writeconcernmajorityjournaldefault | rs.conf().writeConcernMajorityJournalDefault | 1 | 4977 |
| chk-wiredtiger-checkpoint-duration | wiredTiger checkpoint duration | 1 | 4986 |
| chk-wiredtiger-cache-eviction-dirty-trigger-eviction-dirty-targe | wiredTiger.cache (eviction_dirty_trigger / eviction_dirty_target context) | 1 | 4995 |

## parameter-current-value (240)

| check_id | param_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-kernel-boot-cmdline-nohz-off | kernel boot cmdline `nohz=off` | 1 | 5004 |
| chk-linux-kernel-page-size | Linux kernel `Page size` 编译选项 | 1 | 5012 |
| chk-mysql-innodb-thread-concurrency-nginx-worker-processes | MySQL `innodb_thread_concurrency` / Nginx `worker_processes` / 其他应用并发设置 | 1 | 5020 |
| chk-mount-options-noatime | mount.options.noatime | 1 | 5028 |
| chk-mount-options-nobarrier | mount.options.nobarrier | 1 | 5036 |
| chk-net-ipv4-tcp-max-syn-backlog | net.ipv4.tcp_max_syn_backlog | 2 | 5044 |
| chk-net-core-somaxconn | net.core.somaxconn | 2 | 5052 |
| chk-net-core-rmem-max | net.core.rmem_max | 1 | 5060 |
| chk-net-core-wmem-max | net.core.wmem_max | 1 | 5068 |
| chk-net-ipv4-tcp-rmem | net.ipv4.tcp_rmem | 1 | 5076 |
| chk-net-ipv4-tcp-wmem | net.ipv4.tcp_wmem | 1 | 5084 |
| chk-net-ipv4-tcp-max-tw-buckets | net.ipv4.tcp_max_tw_buckets | 2 | 5092 |
| chk-net-ipv4-ip-local-port-range | net.ipv4.ip_local_port_range | 1 | 5100 |
| chk-net-ipv4-tcp-tw-reuse | net.ipv4.tcp_tw_reuse | 1 | 5108 |
| chk-net-core-netdev-max-backlog-2 | net.core.netdev_max_backlog | 2 | 5116 |
| chk-net-ipv4-tcp-keepalive-time-2 | net.ipv4.tcp_keepalive_time | 3 | 5124 |
| chk-net-ipv4-tcp-fin-timeout | net.ipv4.tcp_fin_timeout | 1 | 5132 |
| chk-bios-advanced-misc-config-support-smmu-2 | bios.advanced.misc_config.support_smmu | 1 | 5140 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration-2 | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 5148 |
| chk-systemd-unit-irqbalance-service | systemd.unit.irqbalance.service | 1 | 5156 |
| chk-proc-irq-n-smp-affinity-list | proc.irq.<N>.smp_affinity_list | 1 | 5164 |
| chk-sys-block-device-queue-nr-requests | /sys/block/${device}/queue/nr_requests | 1 | 5172 |
| chk-libvirt-domain-cputune-vcpupin-2 | libvirt.domain.cputune.vcpupin | 1 | 5180 |
| chk-grub-linux-default-hugepagesz | grub.linux.default_hugepagesz | 1 | 5188 |
| chk-libvirt-domain-memorybacking-hugepages | libvirt.domain.memoryBacking.hugepages | 1 | 5196 |
| chk-numactl-c-sched-setaffinity-worker-cpu-affinity | (非操作系统参数,而是**应用启动方式**或**应用配置**)`numactl -C` / `sched_setaffinity` / 应用配置中的 worker_cpu_affinity | 1 | 5204 |
| chk-proc-irq-irq-smp-affinity-list | /proc/irq/$irq/smp_affinity_list | 1 | 5212 |
| chk-ethtool-c-eth-adaptive-rx-adaptive-tx | ethtool -C $eth adaptive-rx / adaptive-tx | 1 | 5220 |
| chk-ethtool-c-eth-rx-usecs-tx-usecs-rx-frames-tx-frames | ethtool -C $eth rx-usecs / tx-usecs / rx-frames / tx-frames | 1 | 5228 |
| chk-sys-class-net-nic-queues-rx-0-rps-cpus | /sys/class/net/$nic/queues/rx-0/rps_cpus | 1 | 5236 |
| chk-sys-class-net-nic-queues-rx-0-rps-flow-cnt-proc-sys-net-core | /sys/class/net/$nic/queues/rx-0/rps_flow_cnt + /proc/sys/net/core/rps_sock_flow_entries | 1 | 5244 |
| chk-proc-sys-vm-dirty-expire-centisecs | /proc/sys/vm/dirty_expire_centisecs | 1 | 5252 |
| chk-proc-sys-vm-dirty-background-ratio | /proc/sys/vm/dirty_background_ratio | 1 | 5260 |
| chk-proc-sys-vm-dirty-ratio | /proc/sys/vm/dirty_ratio | 1 | 5268 |
| chk-sys-block-device-name-queue-scheduler | /sys/block/$DEVICE-NAME/queue/scheduler | 1 | 5276 |
| chk-mount-option-barrier-nobarrier | mount option · barrier / nobarrier | 1 | 5284 |
| chk-filesystem-type-mkfs-xfs-vs-mkfs-ext4 | filesystem type (mkfs.xfs vs mkfs.ext4) | 1 | 5292 |
| chk-mkfs-xfs-b-size | mkfs.xfs -b size= | 1 | 5300 |
| chk-vm-dirty-ratio-vm-dirty-background-ratio-2 | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 5308 |
| chk-kernel-transparent-hugepage | kernel.transparent_hugepage | 2 | 5316 |
| chk-block-device-queue-read-ahead-kb-udev-attr-bdi-read-ahead-kb | block device queue/read_ahead_kb(udev ATTR{bdi/read_ahead_kb}) | 1 | 5324 |
| chk-shared-buffers | shared_buffers | 5 | 5332 |
| chk-work-mem | work_mem | 8 | 5341 |
| chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo-2 | recovery_max_workers/recovery_parse_workers/recovery_redo_workers | 1 | 5350 |
| chk-ubtree | ubtree页面分裂策略 | 1 | 5358 |
| chk-autovacuum | autovacuum相关参数 | 1 | 5366 |
| chk-wal-file-init-num | wal file init num | 1 | 5374 |
| chk-advance-xlog-file-num | advance_xlog_file_num | 1 | 5382 |
| chk-query-dop | query_dop | 2 | 5390 |
| chk-log-min-duration-statement | log_min_duration_statement | 1 | 5398 |
| chk-walwriter-cpu-bind | walwriter_cpu_bind | 1 | 5406 |
| chk-autovacuum-ustore | autovacuum (ustore表的自动清理) | 1 | 5414 |
| chk-thread-pool-attr-2 | thread_pool_attr | 2 | 5422 |
| chk-vacuum-cost-delay | vacuum_cost_delay | 1 | 5431 |
| chk-undo-retention-time-2 | undo_retention_time | 1 | 5439 |
| chk-sys-kernel-debug-sched-features | /sys/kernel/debug/sched_features | 1 | 5447 |
| chk-logintimeout | loginTimeout | 1 | 5455 |
| chk-recovery-parse-workers-recovery-redo-workers | recovery_parse_workers / recovery_redo_workers | 1 | 5463 |
| chk-client-encoding-server-encoding-2 | client_encoding / server_encoding | 1 | 5471 |
| chk-rewrite-rule | rewrite_rule | 10 | 5479 |
| chk-enable-hashjoin-2 | enable_hashjoin | 2 | 5488 |
| chk-enable-nestloop | enable_nestloop | 5 | 5497 |
| chk-enable-mergejoin | enable_mergejoin | 2 | 5506 |
| chk-enable-sort | enable_sort | 5 | 5514 |
| chk-best-agg-plan | best_agg_plan | 2 | 5523 |
| chk-a-format-load-with-constraints-violation | a_format_load_with_constraints_violation | 1 | 5532 |
| chk-cost-param | cost_param | 4 | 5541 |
| chk-skew-option | skew_option | 2 | 5550 |
| chk-default-statistics-target | default_statistics_target | 1 | 5559 |
| chk-behavior-compat-options | behavior_compat_options | 1 | 5568 |
| chk-enable-fast-query-shipping | enable_fast_query_shipping | 2 | 5577 |
| chk-recovery-parse-workers | recovery_parse_workers | 1 | 5586 |
| chk-recovery-redo-workers | recovery_redo_workers | 1 | 5595 |
| chk-enable-index-nestloop | enable_index_nestloop | 1 | 5604 |
| chk-enable-indexscan | enable_indexscan | 2 | 5613 |
| chk-max-process-memory | max_process_memory | 3 | 5621 |
| chk-qrw-inlist2join-optmode | qrw_inlist2join_optmode | 2 | 5630 |
| chk-fetchsize | fetchSize | 1 | 5639 |
| chk-period | period | 1 | 5648 |
| chk-ttl | ttl | 1 | 5657 |
| chk-disk-cache-max-size | disk_cache_max_size | 2 | 5666 |
| chk-disk-cache-dual-write-option | disk_cache_dual_write_option | 1 | 5675 |
| chk-min-batch-rows | min_batch_rows | 1 | 5683 |
| chk-autovacuum-2 | autovacuum | 1 | 5691 |
| chk-autovacuum-vacuum-cost-delay | autovacuum_vacuum_cost_delay | 1 | 5700 |
| chk-autovacuum-max-workers | autovacuum_max_workers | 1 | 5709 |
| chk-autovacuum-naptime | autovacuum_naptime | 2 | 5718 |
| chk-max-active-statements | max_active_statements | 1 | 5727 |
| chk-autovacuum-max-workers-hstore | autovacuum_max_workers_hstore | 1 | 5736 |
| chk-enable-codegen-2 | enable_codegen | 1 | 5745 |
| chk-enable-numa-bind | enable_numa_bind | 1 | 5753 |
| chk-abnormal-check-general-task | abnormal_check_general_task | 1 | 5761 |
| chk-resource-track-level | resource_track_level | 1 | 5770 |
| chk-track-activities | track_activities | 1 | 5779 |
| chk-connectiontimeout | connectionTimeOut | 1 | 5787 |
| chk-lockwait-timeout | lockwait_timeout | 1 | 5796 |
| chk-psort-work-mem-2 | psort_work_mem | 2 | 5805 |
| chk-enable-delta | ENABLE_DELTA | 1 | 5814 |
| chk-resource-pool-cpu-dedicated-quota | resource_pool.cpu_dedicated_quota | 1 | 5823 |
| chk-temp-file-limit | temp_file_limit | 1 | 5832 |
| chk-sequence-cache | sequence.cache | 1 | 5841 |
| chk-cstore-buffers | cstore_buffers | 1 | 5850 |
| chk-comm-max-stream | comm_max_stream | 1 | 5858 |
| chk-vacuum-defer-cleanup-age-2 | vacuum_defer_cleanup_age | 1 | 5867 |
| chk-enable-stream-operator | enable_stream_operator | 1 | 5876 |
| chk-table-skewness-warning-threshold | table_skewness_warning_threshold | 1 | 5884 |
| chk-table-skewness-warning-rows | table_skewness_warning_rows | 1 | 5892 |
| chk-session-timeout | session_timeout | 1 | 5900 |
| chk-max-connections | max_connections | 1 | 5909 |
| chk-etc-security-limits-conf-ulimit | /etc/security/limits.conf 中各 ulimit 项 | 1 | 5918 |
| chk-wiredtiger-engineconfig-memory-page-max | wiredTiger.engineConfig.memory_page_max(诊断专用 · 实际生产不应调) | 1 | 5926 |
| chk-storage-wiredtiger-engineconfig-cachesizegb | storage.wiredTiger.engineConfig.cacheSizeGB | 1 | 5934 |
| chk-tcmalloc-aggressive-decommit | TCMALLOC_AGGRESSIVE_DECOMMIT(环境变量 / 启动参数) | 1 | 5942 |
| chk-wiredtiger-cache-eviction-updates-trigger-eviction-updates-t | wiredTiger.cache.eviction_updates_trigger / eviction_updates_target | 1 | 5950 |
| chk-wiredtigerengineruntimeconfig-checkpoint-wait-log-size | wiredTigerEngineRuntimeConfig.checkpoint.wait / log_size | 1 | 5958 |
| chk-eviction-trigger | eviction_trigger | 1 | 5966 |
| chk-innodb-thread-concurrency-mysql-worker-processes-nginx | innodb_thread_concurrency (MySQL) / worker_processes (Nginx) / 应用自有并发参数 | 1 | 5974 |
| chk-worker-processes | worker_processes | 1 | 5982 |
| chk-linker-flags-ljemalloc-l-jemalloc-config-libdir | linker flags · -ljemalloc + -L`jemalloc-config --libdir` | 1 | 5990 |
| chk-malloc-lib-my-cnf | malloc-lib (my.cnf) 或类似配置 | 1 | 5998 |
| chk-slowopthresholdms-atlas-managed-dynamic-fixed-100ms | slowOpThresholdMs (Atlas-managed dynamic / fixed 100ms) | 1 | 6006 |
| chk-maxincomingconnections-ulimit-n | maxIncomingConnections / ulimit -n | 1 | 6014 |
| chk-storageengineconcurrentreadtransactions-storageengineconcurr | storageEngineConcurrentReadTransactions / storageEngineConcurrentWriteTransactions | 1 | 6022 |
| chk-maxpoolsize | maxPoolSize | 3 | 6030 |
| chk-deployment-dbpath | (deployment) dbPath 挂载点文件系统 | 2 | 6038 |
| chk-tuned-profile | tuned profile | 1 | 6046 |
| chk-numactl-interleave-all-mongod | numactl --interleave=all (启动 mongod 时) | 1 | 6054 |
| chk-vm-swappiness-2 | vm.swappiness | 1 | 6062 |
| chk-glibc-tunables-env | GLIBC_TUNABLES (env) | 1 | 6070 |
| chk-storage-inmemory-engineconfig-inmemorysizegb-inmemorysizegb | storage.inMemory.engineConfig.inMemorySizeGB / --inMemorySizeGB | 1 | 6078 |
| chk-defaultwriteconcern-w-write-concern | defaultWriteConcern.w(及业务调用侧 write concern) | 1 | 6086 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct-2 | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 6094 |
| chk-connecttimeoutms | connectTimeoutMS | 1 | 6102 |
| chk-sockettimeoutms | socketTimeoutMS | 1 | 6110 |
| chk-minpoolsize | minPoolSize | 1 | 6118 |
| chk-operationprofiling-slowopthresholdms-db-setprofilinglevel-sl | operationProfiling.slowOpThresholdMs / db.setProfilingLevel slowms | 1 | 6126 |
| chk-operationprofiling-slowopsamplerate-setprofilinglevel-sample | operationProfiling.slowOpSampleRate / setProfilingLevel sampleRate | 1 | 6134 |
| chk-kernel-transparent-hugepage-enabled-systemd-init-d-kernel-bo | kernel transparent_hugepage/enabled(可通过 systemd / init.d / kernel boot param 启用) | 1 | 6142 |
| chk-writeconcernmajorityjournaldefault-writeconcern | writeConcernMajorityJournalDefault / 应用层 writeConcern | 1 | 6150 |
| chk-flowcontroltargetlagseconds | flowControlTargetLagSeconds | 1 | 6158 |
| chk-internalqueryframeworkcontrol | internalQueryFrameworkControl | 1 | 6166 |
| chk-sharding-chunk-size-64mb-25 | sharding chunk size(默认 64MB)/ 25 万文档上限 | 1 | 6174 |
| chk-replsets-storage-wiredtiger-engineconfig-cachesizeratio-cont | replsets.storage.wiredTiger.engineConfig.cacheSizeRatio + container resources.limits.memory | 1 | 6182 |
| chk-defaultwriteconcern-w | defaultWriteConcern.w | 1 | 6190 |
| chk-replicaset-config-writeconcernmajorityjournaldefault | replicaSet.config.writeConcernMajorityJournalDefault | 1 | 6198 |
| chk-wiredtigerengineruntimeconfig-eviction-dirty-trigger-evictio | wiredTigerEngineRuntimeConfig.eviction_dirty_trigger / eviction_dirty_target | 1 | 6206 |
| chk-wiredtigerengineruntimeconfig-eviction-threads-min-threads-m | wiredTigerEngineRuntimeConfig.eviction.threads_min / threads_max | 1 | 6214 |
| chk-arm64-graviton2-march-armv8-2-a-lse | ARM64 Graviton2+ 编译时用 -march=armv8.2-a 启用 LSE 原子指令 | 0 | 6222 |
| chk-arm64-moutline-atomics-lse | ARM64 多代兼容部署时用 -moutline-atomics 运行期检测 LSE 支持 | 0 | 6237 |
| chk-graviton2-dmesg-lscpu-lse | Graviton2 部署后用 dmesg/lscpu 验证 LSE 原子指令已被内核检测启用 | 0 | 6252 |
| chk-xfs-mount-noatime-access-time | XFS 数据盘 mount 加 noatime · 避免读取时更新 access time 浪费资源 | 0 | 6267 |
| chk-raid-flash-xfs-mount-nobarrier-write-barrier | 底层存储具备掉电保护(RAID/Flash)时 · XFS 数据盘 mount 加 nobarrier · 避免 write barrier 性能损失 | 0 | 6282 |
| chk-mongodb-tcp-tw-reuse-time-wait-socket | MongoDB 客户端启用 tcp_tw_reuse 让 TIME-WAIT socket 可复用以新建连接 | 0 | 6297 |
| chk-mongodb-listen-backlog-somaxconn-65535-accept | MongoDB 客户端 listen() backlog 上限 somaxconn 调至 65535 防 accept 队列溢出 | 0 | 6312 |
| chk-mongodb-netdev-max-backlog-8096 | MongoDB 客户端调大 netdev_max_backlog 至 8096 避免高入流量丢包 | 0 | 6327 |
| chk-mongodb-tcp-max-syn-backlog-8192-syn | MongoDB 客户端调大 tcp_max_syn_backlog 至 8192 防 SYN 队列溢出 | 0 | 6342 |
| chk-mongodb-tcp-fin-timeout-30-fin-wait-2 | MongoDB 客户端调小 tcp_fin_timeout 至 30 秒缩短 FIN-WAIT-2 占用 | 0 | 6357 |
| chk-mongodb-tcp-max-tw-buckets-3000-time-wait | MongoDB 客户端调小 tcp_max_tw_buckets 至 3000 加快 TIME-WAIT 强制回收 | 0 | 6372 |
| chk-boostkit-vm-dirty-ratio-5 | 鲲鹏 BoostKit 数据库场景 vm.dirty_ratio 设为 5 限制脏页堆积 | 0 | 6387 |
| chk-kvm-mongod-vcpu-placement-static-cpuset-worker-numa-die | KVM 虚拟机部署 mongod 时 · vcpu placement=static + cpuset 限定 worker 线程范围 · 防跨 NUMA 跨 DIE | 0 | 6402 |
| chk-kvm-mongod-512mb-host-kernel-cmdline-vm-xml-memorybacking | KVM 虚拟化场景为 mongod 虚机分配 512MB 大页(Host kernel cmdline + VM xml memoryBacking) | 0 | 6417 |
| chk-read-ahead-kb-128kb-4096kb | 磁盘顺序读场景下将 read_ahead_kb 从默认 128KB 调大至 4096KB 以充分利用预取性能提升 | 0 | 6432 |
| chk-xfs-blocksize-8192b-i-o | 大文件操作场景使用 XFS 文件系统并将 blocksize 设为 8192B 以提升 I/O 吞吐 | 0 | 6447 |
| chk-jemalloc-glibc | 多线程高并发场景下应用链接 jemalloc 替代 glibc 默认分配器以减少锁竞争 | 0 | 6462 |
| chk-wiredtiger | 长事务导致 WiredTiger 缓存压力：拆分事务并确保索引覆盖 | 0 | 6477 |
| chk-1000 | 单次事务修改文档上限 1000 条：超出须拆批处理 | 0 | 6492 |
| chk-linearizable-maxtimems | linearizable 读关注配合 maxTimeMS 防止操作无限挂起 | 0 | 6507 |
| chk-mongodb-journal-io | MongoDB Journal 和系统日志应使用独立物理卷，避免日志 IO 竞争数据盘带宽 | 0 | 6522 |
| chk-w-majority | 重要数据写入应使用 w:majority，防止主节点故障转移时写操作被回滚 | 0 | 6537 |
| chk-wiredtiger-modified-evictions-nvme | WiredTiger 高脏页率 + 高 modified evictions 场景应换用 NVMe 替代机械盘 | 0 | 6552 |
| chk-bios-smmu-io | 鲲鹏平台非虚拟化场景下 · 在 BIOS 中关闭 SMMU 以避免数据库 IO 开销 | 0 | 6567 |
| chk-bios-cpu | 鲲鹏平台数据库场景 · 在 BIOS 中关闭 CPU 硬件预取以避免无效缓存流量 | 0 | 6582 |
| chk-numa-irqbalance-32 | 鲲鹏服务器手动绑定网卡中断到本地 NUMA · 关闭 irqbalance · 32 队列绑满获最佳网络性能 | 0 | 6597 |
| chk-thp | 数据库场景下关闭透明大页(THP)以减少内存碎片与利用率下降 | 0 | 6612 |
| chk-io-deadline-nvme | 数据库场景下 · 块设备 IO 调度器配置为 deadline(NVMe 除外) | 0 | 6627 |
| chk-nr-requests-2048 | 数据库高并发写入场景下 · 块设备 nr_requests 调到 2048 提升磁盘吞吐 | 0 | 6642 |
| chk-adaptive-rx-tx-off-ethtool-c | 鲲鹏网卡性能调优：禁用自适应中断聚合（adaptive-rx/tx off），使用静态 ethtool -C 参数 | 0 | 6657 |
| chk-mongodb-maxincomingconnections-raise-above-default-64k-for-h | MongoDB maxIncomingConnections: raise above default 64k for high-connection deployments | 0 | 6672 |
| chk-linux-ulimit-nofile-raise-open-file-descriptor-limit-for-hig | Linux ulimit nofile: raise open-file descriptor limit for high-connection MongoDB servers | 0 | 6687 |
| chk-linux-ulimit-nproc-raise-thread-count-limit-for-high-connect | Linux ulimit nproc: raise thread count limit for high-connection MongoDB deployments | 0 | 6702 |
| chk-linux-ulimit-stack-raise-per-thread-stack-size-limit-for-hig | Linux ulimit stack: raise per-thread stack size limit for high-connection MongoDB deployments | 0 | 6717 |
| chk-vm-max-map-count-raise-kernel-mmap-limit-when-running-many-t | vm.max_map_count: raise kernel mmap limit when running many threads (MongoDB high-connection) | 0 | 6732 |
| chk-net-ipv4-ip-local-port-range-expand-ephemeral-port-range-on- | net.ipv4.ip_local_port_range: expand ephemeral port range on benchmark/client hosts | 0 | 6747 |
| chk-3-voting-w-majority | 副本集部署需 ≥3 个数据承载 voting 成员 + 写操作走 w:majority · 否则数据耐久性无法满足 | 0 | 6762 |
| chk-7-arbiter | 副本集投票成员需为奇数(最多 7 个)· 偶数时用 arbiter 凑奇数 · 否则选举平票卡死 | 0 | 6777 |
| chk-driver-110-115 | driver 连接池大小起点应为应用层"典型并发请求数 × 110-115%" · 池太小将请求排队 | 0 | 6792 |
| chk-dbpath-nfs-vmware | dbPath 不要用 NFS · 用本地 / VMware 虚拟盘 | 0 | 6807 |
| chk-wiredtiger-xfs-ext4 | WiredTiger 数据盘强烈建议用 XFS · 不用 EXT4 | 0 | 6822 |
| chk-rhel-centos-tuned-tuned-profile | RHEL / CentOS 上用 tuned 时必须自定义 tuned profile | 0 | 6837 |
| chk-san | 副本集成员不要全放同一 SAN · 避免单点故障 | 0 | 6852 |
| chk-lb-mongod-tcp-keepalive-time-120 | 云 LB 后部署 mongod 时 · tcp_keepalive_time 设为 120 秒以避免静默断连 | 0 | 6867 |
| chk-raid-10-raid-5-raid-6 | 存储层用 RAID-10 · 不要用 RAID-5 / RAID-6 | 0 | 6882 |
| chk-nfs-etc-fstab-bg-hard-nolock-noatime-nointr | 必须用 NFS 时 · /etc/fstab 加 bg / hard / nolock / noatime / nointr 选项 | 0 | 6897 |
| chk-i-o-ssd-sata-ssd | I/O 吞吐瓶颈时 · 优先用 SSD(SATA SSD 性价比好)而非堆贵转盘 | 0 | 6912 |
| chk-mongod-vm-swappiness-1-0-60 | mongod 主机 vm.swappiness 设为 1 或 0(默认 60 太激进) | 0 | 6927 |
| chk-numa-mongod-numactl-interleave-all | NUMA 主机上 mongod 必须经 numactl --interleave=all 启动 | 0 | 6942 |
| chk-numa-vm-zone-reclaim-mode-0-numactl | NUMA 主机上 vm.zone_reclaim_mode 必须设为 0 · 与 numactl 配套 | 0 | 6957 |
| chk-vm-hypervisor-i-o-scheduler-none | VM / 云主机 + hypervisor 块设备 · I/O scheduler 用 none | 0 | 6972 |
| chk-i-o-scheduler-mq-deadline | 物理服务器 + 转盘 · I/O scheduler 用 mq-deadline | 0 | 6987 |
| chk-vm-i-o-scheduler-kyber-kernel-4-12 | 同 VM / 自建机房多负载混跑 · I/O scheduler 用 kyber(kernel 4.12+) | 0 | 7002 |
| chk-wiredtiger-readahead-8-32-sectors | WiredTiger 引擎 · readahead 设 8~32 (sectors) · 不要更高 | 0 | 7017 |
| chk-mongod-libssl-libcrypto-objdump | mongod 启动时 libssl/libcrypto 符号版本警告 · 通常不影响 · 可用 objdump 核对 | 0 | 7032 |
| chk-kvm-mongod-balloon-driver | KVM 上跑 mongod · 为虚机预留全部内存 · 不禁用 balloon driver | 0 | 7047 |
| chk-db-connecttimeoutms | 应用侧操作慢但 DB 侧未见对应 · 设 connectTimeoutMS 防止驱动连接阶段无限等待 | 0 | 7062 |
| chk-socket-sockettimeoutms-op-2-3-socket | 防火墙半关闭 socket · 设 socketTimeoutMS 为最慢 op 时长的 2~3 倍以确保 socket 总能释放 | 0 | 7077 |
| chk-minpoolsize-2 | 应用启动时连接创建占用过多时间 · 设 minPoolSize 预热池子 | 0 | 7092 |
| chk-op-sockettimeoutms-maxtimems | 想取消服务端长 op 时不要用 socketTimeoutMS · 改用 maxTimeMS() 让服务端真正取消 | 0 | 7107 |
| chk-enable-mongodb-network-compression-to-reduce-client-server-b | Enable MongoDB network compression to reduce client-server bandwidth | 0 | 7122 |
| chk-rhel-centos-7-mongodb-tuned-percona-mongodb-profile-linux | RHEL/CentOS 7+ 运行 MongoDB · 使用 tuned-percona-mongodb profile 一键自动化应用所有 Linux 调参 | 0 | 7137 |
| chk-puppet-chef-ansible-tuned-profile | 使用配置管理工具（Puppet/Chef/Ansible）时 · 必须通过 tuned profile 部署调参而非直接修改系统文件 | 0 | 7152 |
| chk-serviceexecutor-adaptive-io | 高并发场景启用 serviceExecutor adaptive 实现网络 IO 复用 | 0 | 7167 |
| chk-eviction-dirty-target-trigger | 高写入负载下调低 eviction_dirty_target/trigger 让后台线程尽早淘汰脏页 | 0 | 7182 |
| chk-checkpoint-wait-25s-io | 高写入负载下缩短 checkpoint wait 周期至 25s 均摊 IO | 0 | 7197 |
| chk-ttl-delete | 高写入集群将 TTL 过期删除窗口移至夜间低峰期规避白天 delete 高峰 | 0 | 7212 |
| chk-index-build-workload | 对不能容忍 index build 期间性能下降的 workload 启用滚动方式构建索引 | 0 | 7227 |
| chk-wiredtiger-commitintervalms-increase-to-200-300ms-for-higher | WiredTiger commitIntervalMs: increase to 200-300ms for higher write throughput | 0 | 7242 |
| chk-wiredtiger-journal-enabled-disable-for-temporary-non-critica | WiredTiger journal.enabled: disable for temporary/non-critical data to maximize write speed | 0 | 7256 |
| chk-wiredtiger-blockcompressor-set-to-none-for-maximum-write-spe | WiredTiger blockCompressor: set to none for maximum write speed (no compression overhead) | 0 | 7270 |
| chk-storage-directoryperdb-enable-when-using-separate-storage-vo | storage.directoryPerDB: enable when using separate storage volumes for each database | 0 | 7284 |
| chk-oplogsizemb-oplog | oplogSizeMB 在高更新频率工作负载下调大——避免 oplog 空洞和从节点延迟 | 0 | 7298 |
| chk-cursortimeoutmillis | cursorTimeoutMillis 调小降低空闲游标资源开销 | 0 | 7313 |
| chk-transactionlifetimelimitseconds-wiredtiger | transactionLifetimeLimitSeconds 调小防长事务压垮 WiredTiger 缓存 | 0 | 7328 |
| chk-blockcompressor-zstd | 冷数据存储场景将 blockCompressor 改为 zstd 提升压缩比 | 0 | 7343 |
| chk-tcmallocaggressivememorydecommit-oom | tcmallocAggressiveMemoryDecommit 在内存 OOM/碎片场景启用加速内存回收 | 0 | 7358 |
| chk-minsnapshothistorywindowinseconds-0-wt | 不使用历史快照读时将 minSnapshotHistoryWindowInSeconds 调小到 0 释放 WT 缓存压力 | 0 | 7373 |
| chk-wiredtiger-tickets-10-setparameter | WiredTiger 并发读写 tickets 持续低于 10 时应用 setParameter 增加上限 | 0 | 7388 |
| chk-wiredtiger-max-50-ram-1gb-0-256gb | WiredTiger 内部缓存默认值 = max(50% × (RAM - 1GB), 0.256GB) · 不应擅自调高 | 0 | 7403 |
| chk-wiredtiger-snappy | WiredTiger 集合默认采用 Snappy 块压缩 · 索引默认前缀压缩 | 0 | 7418 |
| chk-encrypted-storage-engine-aes-ni-cpu | 使用 Encrypted Storage Engine 时 · 选支持 AES-NI 指令集的 CPU | 0 | 7433 |
| chk-lxc-cgroups-docker-mongod-wiredtigercachesizegb-wiredtigerca | 容器(lxc / cgroups / Docker)部署 mongod 时必须显式设 wiredTigerCacheSizeGB 或 wiredTigerCacheSizePct | 0 | 7448 |
| chk-mongod-wiredtiger | 单机多 mongod 实例时须按实例数缩减每个实例的 WiredTiger 缓存配置 | 0 | 7463 |
| chk-storage-syncperiodsecs-0-60 | 生产环境禁止将 storage.syncPeriodSecs 设为 0 · 保持默认值 60 | 0 | 7478 |
| chk-systemlog-quiet | 生产环境禁用 systemLog.quiet 模式 · 保留完整日志输出 | 0 | 7493 |
| chk-systemlog-destination-file-syslog | 生产环境 systemLog.destination 应设为 file 而非 syslog · 避免时间戳误导 | 0 | 7508 |
| chk-linux-logrotate-systemlog-logrotate-reopen | 使用 Linux logrotate 工具时须将 systemLog.logRotate 设为 reopen 以避免日志丢失 | 0 | 7523 |
| chk-bson-json | 审计日志落文件时使用 BSON 格式而非 JSON · 降低性能开销 | 0 | 7538 |
| chk-kmip-localauditkeyfile | 审计日志加密密钥生产环境必须使用外部 KMIP 服务 · 禁止使用 localAuditKeyFile | 0 | 7553 |
| chk-mongos-maxincomingconnections | mongos 部署中客户端连接泄漏时须显式设置 maxIncomingConnections 防止分片连接风暴 | 0 | 7568 |
| chk-profiler-diagnostic-log-slowms | profiler / diagnostic log slowms 阈值应设为业务可接受的最高值 · 避免性能退化 | 0 | 7583 |
| chk-database-profiler-atlas-query-profiler-performance-advisor-q | 启用 database profiler 前优先考虑 Atlas Query Profiler / Performance Advisor / $queryStats 等替代方案 · profiler 可能 degrade 性能 | 0 | 7598 |
