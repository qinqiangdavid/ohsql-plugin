# Check Items Index · 指标集合

> 生成时间: 2026-05-20T07:48:43.493Z
> 数据源: 派生于 cases/CASES.md (每条 case 的 diagnostic_steps[*].metric_name + likely_causes.parameter_causes[*])
> 总计: 388 checks (metric 283 / param 105)
> 配套: cases/indices/by-check-item/CASES.md

## metric (283)

| check_id | metric_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-proc-cmdline-nohz-off | /proc/cmdline 中是否含 `nohz=off` | 1 | 9 |
| chk-timer-tick | timer_tick 调度次数(单位时间内) | 1 | 18 |
| chk-dtlb-load-misses-itlb-load-misses | dTLB-load-misses 比率 / iTLB-load-misses 比率 | 1 | 27 |
| chk-tps-vs | TPS / 业务吞吐 vs 线程并发数 | 1 | 36 |
| chk-mount-options | mount.options | 1 | 45 |
| chk-sysctl-net-7-keys | sysctl.net.* (7 keys) | 1 | 54 |
| chk-sysctl-net-8-keys | sysctl.net.* (8 keys) | 1 | 63 |
| chk-bios-advanced-misc-config-support-smmu | bios.advanced.misc_config.support_smmu | 1 | 2692 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 2700 |
| chk-systemd-unit-irqbalance-service-active-state | systemd.unit.irqbalance.service.active_state | 1 | 90 |
| chk-proc-interrupts-smp-affinity-list | proc.interrupts.smp_affinity_list | 1 | 99 |
| chk-blockdev-queue-nr-requests | blockdev.queue.nr_requests | 1 | 108 |
| chk-libvirt-domain-cputune-vcpupin | libvirt.domain.cputune.vcpupin | 1 | 2732 |
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
| chk-vm-dirty-ratio-vm-dirty-background-ratio | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 2860 |
| chk-kernel-boot-option-transparent-hugepage | kernel boot option transparent_hugepage | 1 | 234 |
| chk-block-device-read-ahead-kb-sectors | block device read_ahead_kb / sectors | 1 | 243 |
| chk-wiredtiger-cache-bytes-currently-in-the-cache | wiredTiger.cache.bytes_currently_in_the_cache | 1 | 252 |
| chk-replication-lag | replication_lag | 1 | 261 |
| chk-mongod-process-state | mongod_process_state | 1 | 270 |
| chk-sharding-balancer-migration-24h-results-sharding-collection- | sharding.balancer.migration_24h_results · sharding.collection.chunks_per_shard | 1 | 279 |
| chk-log-sharding-migrationfailed-error | log.SHARDING.MigrationFailed.error | 1 | 288 |
| chk-sh-movechunk-errmsg | sh.moveChunk.errmsg | 1 | 297 |
| chk-sharding-collection-jumbo-chunks | sharding.collection.jumbo_chunks | 1 | 306 |
| chk-currentop-locks-currentop-waitingforlock | currentOp.locks · currentOp.waitingForLock | 1 | 315 |
| chk-wiredtiger-cache-pages-written-from-cache-pages-read-into-ca | wiredTiger.cache.pages written from cache / pages read into cache | 1 | 324 |
| chk-mongod | mongod 进程栈采样函数命中分布 | 1 | 333 |
| chk-wiredtiger-cache-used-mongostat-used | wiredTiger cache used % (mongostat 输出列 used) | 1 | 342 |
| chk-db-collection-stats-1024-1024-size-totalindexsize | db.collection.stats(1024*1024).size + totalIndexSize | 1 | 351 |
| chk-serverstatus-tcmalloc-tcmalloc-pageheap-free-bytes | serverStatus.tcmalloc.tcmalloc.pageheap_free_bytes | 1 | 360 |
| chk-serverstatus-tcmalloc-tcmalloc-pageheap-unmapped-bytes | serverStatus.tcmalloc.tcmalloc.pageheap_unmapped_bytes | 1 | 369 |
| chk-mongod-rss | mongod 进程 RSS | 2 | 378 |
| chk-proc-meminfo-memfree | /proc/meminfo MemFree | 1 | 387 |
| chk-mongod-tcmalloc-tcmalloc-generic-heap-size-current-allocated | mongod tcmalloc.tcmalloc.generic.heap_size / current_allocated_bytes / pageheap_free_bytes | 1 | 396 |
| chk-mongod-vsz | mongod 进程 VSZ | 1 | 405 |
| chk-wiredtiger-cache-dirty | wiredTiger cache dirty % | 1 | 414 |
| chk-globallock-currentqueue-total | globalLock.currentQueue.total | 2 | 423 |
| chk-globallock-totaltime-vs-uptime | globalLock.totalTime_vs_uptime | 1 | 432 |
| chk-locks-avg-acquire-wait-micros | locks.avg_acquire_wait_micros | 1 | 441 |
| chk-explain-executiontimemillis-per-page | explain.executionTimeMillis_per_page | 1 | 450 |
| chk-disk-io-util | disk_io_util | 1 | 459 |
| chk-mongostat-qrw-arw-or-slow-log-count | mongostat.qrw_arw_or_slow_log_count | 1 | 468 |
| chk-mongod-log-collscan-count | mongod.log.COLLSCAN_count | 1 | 477 |
| chk-mongod-log-slow-query-1-10s | mongod.log.slow_query_1_10s | 1 | 486 |
| chk-currentop-secs-running | currentOp.secs_running | 1 | 495 |
| chk-wiredtiger-cache-bytes-currently-in-the-cache-wiredtiger-cac | wiredTiger.cache.bytes currently in the cache / wiredTiger.cache.maximum bytes configured | 1 | 504 |
| chk-wiredtiger-cache-eviction-worker-thread-evicting-pages-appli | wiredTiger.cache.eviction worker thread evicting pages / application thread time evicting | 1 | 513 |
| chk-flamegraph-snappy-cpu-pct | flamegraph.snappy.cpu_pct | 1 | 522 |
| chk-application-thread-concurrency-setting-business-tps | application thread concurrency setting + business TPS | 1 | 531 |
| chk-application-linked-memory-allocator-library | application linked memory allocator library | 1 | 540 |
| chk-aggregation-pipeline-duration | aggregation_pipeline_duration | 1 | 549 |
| chk-lookup-pipeline-stage | 慢查询中 $lookup pipeline stage 出现频率 | 1 | 558 |
| chk-indexstats-accesses-ops | $indexStats accesses.ops · 每索引使用次数 | 1 | 567 |
| chk-collstats-avgobjsize-p99 | collStats.avgObjSize / 文档大小 P99 | 1 | 576 |
| chk-atlas-query-targeting-scanned-returned-scanned-objects-retur | Atlas Query Targeting: Scanned/Returned & Scanned Objects/Returned | 1 | 585 |
| chk-mongod-slow-query-log-plansummary-keysexamined-docsexamined- | mongod slow query log: planSummary / keysExamined / docsExamined / nreturned | 1 | 594 |
| chk-explain-executionstats | explain.executionStats | 1 | 603 |
| chk-operation-execution-time-ms-plansummary | Operation Execution Time (ms) + planSummary | 1 | 612 |
| chk-docsexamined-keysexamined-docs-examined-returned-ratio | docsExamined / keysExamined / Docs Examined : Returned Ratio | 1 | 621 |
| chk-numyields-usedindex-hassort | numYields / usedIndex / hasSort | 1 | 630 |
| chk-globallock-totaltime-uptime | globalLock.totalTime / uptime | 1 | 639 |
| chk-locks-type-deadlockcount-locks-type-timeacquiringmicros-acqu | locks.<type>.deadlockCount + locks.<type>.timeAcquiringMicros / acquireWaitCount | 1 | 648 |
| chk-connections-current-connections-available | connections.current / connections.available | 1 | 657 |
| chk-connections-current-vs-workload-opcounters | connections.current vs workload (opcounters) | 1 | 666 |
| chk-wiredtiger-concurrenttransactions-read-write-available-out-t | wiredTiger.concurrentTransactions.{read,write}.{available,out,totalTickets} | 1 | 675 |
| chk-queues-execution-read-queues-execution-write | queues.execution.read / queues.execution.write | 1 | 684 |
| chk-replsetgetstatus-members-optimedate-oplog-window | replSetGetStatus.members[].optimeDate / oplog window | 1 | 693 |
| chk-metrics-cursor-open-total-opcounters-query-getmore | metrics.cursor.open.total / opcounters.{query,getmore} | 1 | 702 |
| chk-metrics-operation-scanandorder | metrics.operation.scanAndOrder | 1 | 711 |
| chk-system-profile-slow-query-log-collstats-avgobjsize | system.profile / slow query log + collStats.avgObjSize 趋势 | 1 | 720 |
| chk-driver-maxpoolsize | driver maxPoolSize · 应用层典型并发请求数 | 1 | 909 |
| chk-dbpath | dbPath 挂载点文件系统类型 | 2 | 738 |
| chk-tuned-adm-active-profile | tuned-adm active 当前 profile 名 | 1 | 747 |
| chk-net-ipv4-tcp-keepalive-time | net.ipv4.tcp_keepalive_time | 1 | 2676 |
| chk-mongod-startup-log-numa-warning | mongod startup log · NUMA warning 行 | 1 | 765 |
| chk-numad | numad 进程 | 1 | 774 |
| chk-vm-swappiness | vm.swappiness | 1 | 3020 |
| chk-ec2-instance-type-enhanced-networking-ebs-provisioned-iops | EC2 instance type / Enhanced Networking 状态 / EBS provisioned IOPS | 1 | 792 |
| chk-tcmalloc-usingpercpucaches-tcmalloc-tcmalloc-cpu-free | tcmalloc.usingPerCPUCaches / tcmalloc.tcmalloc.cpu_free | 1 | 801 |
| chk-glibc-pthread-rseq-tunable-glibc-tunables-env | glibc.pthread.rseq tunable / GLIBC_TUNABLES env | 1 | 810 |
| chk-kernel-version | kernel version | 1 | 819 |
| chk-replsetgetstatus-members-statestr-primary-secondary-arbiter | replSetGetStatus.members[] 的 stateStr 分布(PRIMARY/SECONDARY/ARBITER) | 1 | 828 |
| chk-secondary-health-state-optimedate-primary | secondary 的 health/state · optimeDate 与 primary 的差距 | 1 | 837 |
| chk-getdefaultrwconcern-defaultwriteconcern-w | getDefaultRWConcern → defaultWriteConcern.w | 1 | 846 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 3044 |
| chk-explain-queryplanner-winningplan-sort-stage | explain.queryPlanner.winningPlan SORT stage 是否存在 | 1 | 864 |
| chk-sort-useddisk-sort-spills-sort-spilledbytes-sort-spilledreco | $sort.usedDisk / $sort.spills / $sort.spilledBytes / $sort.spilledRecords / $sort.spilledDataStorageSize | 1 | 873 |
| chk-driver-connecttimeoutms-vs | driver connectTimeoutMS 当前值 vs 副本集成员最长网络延迟 | 1 | 882 |
| chk-driver-sockettimeoutms-vs | driver socketTimeoutMS 当前值 vs 应用最慢合法操作耗时 | 1 | 891 |
| chk-driver-minpoolsize-real-time-connection | driver minPoolSize · 服务器日志 / real time 面板 connection 创建速率 | 1 | 900 |
| chk-driver-maxpoolsize | driver maxPoolSize · 应用活跃线程数 / 实际每秒操作数 | 1 | 909 |
| chk-driver-maxpoolsize-cpu-connection-accept-rate | driver maxPoolSize · 服务端 CPU% · connection accept rate | 1 | 918 |
| chk-explain-executionstats-executiontimemillis | explain.executionStats.executionTimeMillis | 1 | 927 |
| chk-explain-executionstats-executionstages-inputstage-stage | explain.executionStats.executionStages.inputStage.stage | 1 | 936 |
| chk-executionstats-totalkeysexamined-executionstats-totaldocsexa | executionStats.totalKeysExamined / executionStats.totalDocsExamined | 1 | 945 |
| chk-executionstats-totaldocsexamined-executionstats-nreturned | executionStats.totalDocsExamined / executionStats.nReturned | 2 | 954 |
| chk-profile-slowms-profile-samplerate-profile-was | profile.slowms / profile.sampleRate / profile.was | 1 | 963 |
| chk-sys-kernel-mm-transparent-hugepage-enabled-defrag-khugepaged | /sys/kernel/mm/transparent_hugepage/{enabled,defrag,khugepaged/defrag} | 1 | 972 |
| chk-syncedto-time-per-secondary | syncedTo time per secondary | 1 | 981 |
| chk-flowcontrol-islagged | flowControl.isLagged | 1 | 990 |
| chk-replication-lag-seconds | Replication Lag (seconds) | 1 | 999 |
| chk-replication-headroom | Replication Headroom | 1 | 1008 |
| chk-network-metrics | Network metrics | 1 | 1017 |
| chk-mongod-slow-log-workingmillis | mongod_slow_log.workingMillis | 1 | 1026 |
| chk-workingmillis-vs-totaltimequeuedmicros | workingMillis_vs_totalTimeQueuedMicros | 1 | 1035 |
| chk-mongod-resident-memory | mongod_resident_memory | 1 | 1044 |
| chk-heap-profile-alloc-hotspots | heap_profile_alloc_hotspots | 1 | 1053 |
| chk-queryhash-uniqueness-per-shape | queryHash_uniqueness_per_shape | 1 | 1062 |
| chk-plancache-entries-count | planCache.entries_count | 1 | 1071 |
| chk-queryframework-per-version | queryFramework_per_version | 1 | 1080 |
| chk-sh-getbalancerstate | sh.getBalancerState() | 1 | 1089 |
| chk-sh-status-verbose-jumbo-flag | sh.status verbose 输出中的 jumbo flag | 1 | 1098 |
| chk-config-chunks-jumbo-true | config.chunks { jumbo: true } | 1 | 1107 |
| chk-getsharddistribution-per-shard-data-docs-chunks | getShardDistribution: per-shard data / docs / chunks | 1 | 1116 |
| chk-hostinfo-system-memsizemb-memlimitmb | hostInfo.system.memSizeMB / memLimitMB | 1 | 1125 |
| chk-wiredtiger-cache-maximum-bytes-configured | wiredTiger.cache."maximum bytes configured" | 1 | 1152 |
| chk-operator-version-replsets-resources-limits-cpu | operator version + replsets.resources.limits.cpu | 1 | 1143 |
| chk-wiredtiger-cache-maximum-bytes-configured | wiredTiger.cache.maximum bytes configured | 1 | 1152 |
| chk-serverstatus-tcmalloc-usingpercpucaches | serverStatus.tcmalloc.usingPerCpuCaches | 1 | 1161 |
| chk-serverstatus-tcmalloc-tcmalloc-cpu-free | serverStatus.tcmalloc.tcmalloc.cpu_free | 1 | 1170 |
| chk-uname-r-kernel-version | uname -r kernel version | 1 | 1179 |
| chk-sys-kernel-mm-transparent-hugepage-enabled | /sys/kernel/mm/transparent_hugepage/enabled | 1 | 1188 |
| chk-explain-queryplanner-winningplan-stage-sort | explain.queryPlanner.winningPlan.stage(子节点是否含 SORT) | 1 | 1197 |
| chk-flamegraph-cpu-stack-profile | flamegraph CPU stack profile | 1 | 1206 |
| chk-getdefaultrwconcern-defaultwriteconcern | getDefaultRWConcern.defaultWriteConcern | 1 | 1215 |
| chk-rs-conf-writeconcernmajorityjournaldefault | rs.conf().writeConcernMajorityJournalDefault | 1 | 1224 |
| chk-wiredtiger-checkpoint-duration | wiredTiger checkpoint duration | 1 | 1233 |
| chk-wiredtiger-cache-eviction-dirty-trigger-eviction-dirty-targe | wiredTiger.cache (eviction_dirty_trigger / eviction_dirty_target context) | 1 | 1242 |
| chk-dbe-perf-statement-cpu-time | dbe_perf.statement.cpu_time | 1 | 1251 |
| chk-explain-analyze | explain analyze 执行计划分析 | 1 | 1629 |
| chk-gaussdb | GaussDB内置火焰图 · 时区加载线程占比 | 1 | 1269 |
| chk-buffer-wdr | buffer命中率 (WDR报告或管控平台) | 1 | 1278 |
| chk-explain-analyze | EXPLAIN ANALYZE 算子落盘标志 | 1 | 1629 |
| chk-dbe-perf-statement-cpu-time-cpu | dbe_perf.statement.cpu_time (持续CPU高) | 1 | 1296 |
| chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu | pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高) | 1 | 1305 |
| chk-statement-history-cpu-time-vs-db-time | statement_history.cpu_time vs db_time | 1 | 1314 |
| chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io | dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高) | 1 | 1323 |
| chk-pg-thread-wait-status-wait-status-wait-event-io | pg_thread_wait_status.wait_status / wait_event (当前IO高) | 1 | 1332 |
| chk-statement-history-data-io-time-sql-io | statement_history.data_io_time (慢SQL IO分析) | 1 | 1341 |
| chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam | dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory | 1 | 1350 |
| chk-dbe-perf-session-memory-detail-dynamic-used-shrctx | dbe_perf.session_memory_detail (dynamic_used_shrctx较小时) | 1 | 1359 |
| chk-dbe-perf-shared-memory-detail-dynamic-used-shrctx | dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时) | 1 | 1368 |
| chk-dbe-perf-local-active-session | dbe_perf.local_active_session (秒级抖动) | 1 | 1377 |
| chk-gs-asp | gs_asp (两天内秒级抖动) | 1 | 1386 |
| chk-data-node-scan | 执行计划下推标识（Data Node Scan） | 1 | 1395 |
| chk-pg-proc-provolatile-proshippable | pg_proc.provolatile / proshippable | 3 | 1404 |
| chk-explain-verbose-remotequery | explain verbose · RemoteQuery 计划 | 1 | 1413 |
| chk-explain-verbose-subplan | explain verbose · SubPlan 执行方式 | 1 | 1548 |
| chk- | 执行计划下推标识 | 2 | 2538 |
| chk-pg-proc-provolatile | pg_proc.provolatile | 1 | 1440 |
| chk-explain-verbose-warning | explain verbose WARNING · 统计信息缺失提示 | 1 | 2034 |
| chk-explain-nest-loop-join | EXPLAIN 执行计划 · Nest Loop Join 耗时 | 1 | 1458 |
| chk-enable-hashjoin | enable_hashjoin 关闭后执行计划 | 1 | 3199 |
| chk-explain-verbose-warning | EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表 | 1 | 2034 |
| chk-pg-log-statistics-not-collected | pg_log 日志 · Statistics not collected 日志行 | 1 | 1485 |
| chk-explain-join | EXPLAIN 执行计划 · Join 算子类型及耗时 | 1 | 1494 |
| chk-explain-analyze-a-time-rows-removed-by-filter | explain analyze · A-time / Rows Removed by Filter | 1 | 1503 |
| chk-explain-analyze-nested-loop-a-time | explain analyze · Nested Loop A-time | 1 | 1512 |
| chk-explain-analyze-groupaggregate-a-time-vs-hashaggregate | explain analyze · GroupAggregate A-time vs HashAggregate | 1 | 1521 |
| chk-explain-analyze-a-time | EXPLAIN ANALYZE A-time 瓶颈算子识别 | 1 | 1530 |
| chk-explain-verbose-streaming-vs-data-node-scan | EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan | 1 | 1539 |
| chk-explain-verbose-subplan | EXPLAIN VERBOSE · SubPlan 算子出现在目标列 | 1 | 1548 |
| chk-pg-stat-get-last-data-changed-time | 近期数据变更表列表（pg_stat_get_last_data_changed_time） | 1 | 1557 |
| chk-pgxc-get-table-skewness | PGXC_GET_TABLE_SKEWNESS | 2 | 2241 |
| chk-table-distribution-dn-1w | table_distribution() 各DN空间（大表个数超1W场景） | 1 | 1575 |
| chk-explain-verbose-warning | EXPLAIN VERBOSE 执行计划 Warning | 2 | 2034 |
| chk-pg-log-statistics-warning | pg_log 日志中的 Statistics WARNING | 1 | 1593 |
| chk-explain-analyze-a-time-seqscan-vs-indexscan | EXPLAIN ANALYZE A-time · SeqScan vs IndexScan | 1 | 1602 |
| chk-explain-analyze-a-time-nestloop | EXPLAIN ANALYZE A-time · NestLoop算子耗时 | 1 | 1611 |
| chk-explain-analyze-a-time-sort-groupagg-vs-hashagg | EXPLAIN ANALYZE A-time · Sort+GroupAgg vs HashAgg | 1 | 1620 |
| chk-explain-analyze | EXPLAIN ANALYZE 执行计划 · 算子耗时 | 1 | 1629 |
| chk-explain-analyze-nestloop | EXPLAIN ANALYZE · NestLoop 算子耗时 | 1 | 1638 |
| chk-explain-analyze-sort-groupagg | EXPLAIN ANALYZE · Sort+GroupAgg 算子耗时 | 1 | 1647 |
| chk-hashaggregate | 执行计划中双层HashAggregate | 1 | 1656 |
| chk- | 执行计划子查询关联方式 | 1 | 2538 |
| chk-subplan | 执行计划中SubPlan节点 | 2 | 1674 |
| chk-dn-cpu | 备DN CPU使用率 · 回放线程资源 | 1 | 1683 |
| chk-explain-verbose | EXPLAIN VERBOSE 统计信息警告 | 1 | 1692 |
| chk-pg-log | pg_log 统计信息缺失日志 | 1 | 1701 |
| chk- | 执行计划子查询处理方式 | 1 | 2538 |
| chk-explain-analyze-stream | EXPLAIN ANALYZE · Stream算子类型 | 1 | 1719 |
| chk-explain-analyze-startup-vs-total | EXPLAIN ANALYZE · 路径代价 (Startup vs Total) | 1 | 1728 |
| chk-nestloop | 语句执行时间 / 执行计划中 NestLoop 算子 | 1 | 2277 |
| chk-pgxc-wlm-session-history-block-time-duration | pgxc_wlm_session_history · block_time / duration | 1 | 1746 |
| chk-pgxc-wlm-session-history | pgxc_wlm_session_history · 同期并发作业数 | 1 | 1755 |
| chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn- | pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent | 1 | 1764 |
| chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ | GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write | 1 | 1773 |
| chk-explain-performance-windowagg-sort | EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时 | 1 | 1782 |
| chk-explain-performance-sql-streaming-redistribute | EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜） | 1 | 1791 |
| chk-order-line-id-null | 列统计信息 · ORDER_LINE_ID NULL 比例 | 1 | 1800 |
| chk-pgxc-wlm-session-history-dataskew-warning | pgxc_wlm_session_history · DataSkew warning | 1 | 1809 |
| chk-pgxc-wlm-session-history-large-table-in-broadcast-warning | pgxc_wlm_session_history · Large Table in Broadcast warning | 1 | 1818 |
| chk-pgxc-wlm-session-history-spill | pgxc_wlm_session_history · Spill告警 | 1 | 1827 |
| chk-pgxc-wlm-session-history-nestloop | pgxc_wlm_session_history · NestLoop大表告警 | 1 | 1836 |
| chk-dn | 各DN磁盘利用率 | 1 | 2016 |
| chk-pgxc-thread-wait-status-wait-status | pgxc_thread_wait_status.wait_status | 1 | 1854 |
| chk-table-skewness-table-distribution | table_skewness / table_distribution | 1 | 1863 |
| chk-warning | 执行计划统计信息Warning | 1 | 1872 |
| chk-remote | 执行计划下推标识（__REMOTE关键字） | 1 | 1881 |
| chk-nestloop | 执行计划算子类型（NestLoop） | 1 | 2277 |
| chk-partitioned-cstore-scan | 执行计划：Partitioned CStore Scan分区扫描范围 | 1 | 1899 |
| chk- | 线程等待状态 | 1 | 2538 |
| chk-vecnestloopruntime | 进程堆栈（VecNestLoopRuntime） | 1 | 1917 |
| chk-sql-create-index | 活跃SQL及CREATE INDEX语句 | 1 | 1926 |
| chk- | 表数据倾斜 | 1 | 2538 |
| chk-max-process-memory-shared-buffers | 内存参数：max_process_memory, shared_buffers | 1 | 1944 |
| chk-in | 执行计划in条件处理方式 | 1 | 1953 |
| chk-pgxc-get-stat-all-tables-dirty-page-rate | PGXC_GET_STAT_ALL_TABLES.dirty_page_rate | 1 | 1962 |
| chk-explain-index-scan | EXPLAIN 执行计划 · 是否使用Index Scan | 1 | 1971 |
| chk-explain-indexscan | EXPLAIN 执行计划 · 是否选择IndexScan | 1 | 1980 |
| chk-explain-verbose-index-scan-vs-seq-scan | EXPLAIN VERBOSE · Index Scan vs Seq Scan | 1 | 1989 |
| chk-waiting-in-queue | 查询等待状态 · waiting in queue | 1 | 1998 |
| chk-explain-or-filter | EXPLAIN 执行计划 · 系统视图权限OR filter | 1 | 2007 |
| chk-dn | 各DN数据量分布 | 1 | 2016 |
| chk-cn | CN日志中不下推原因 | 1 | 2268 |
| chk-explain-verbose-warning | EXPLAIN VERBOSE WARNING信息 · 统计信息缺失 | 1 | 2034 |
| chk-hstore-delta-vs-cu | HStore Delta表大小 vs 主表CU数据 | 1 | 2043 |
| chk-enable-codegen | enable_codegen 参数状态 | 1 | 3341 |
| chk-pgxc-wlm-session-info-streaming-stream-count | pgxc_wlm_session_info · Streaming 算子数（stream_count） | 1 | 2061 |
| chk-pgxc-wlm-session-info-max-cpu-time-cpu | pgxc_wlm_session_info · max_cpu_time（高CPU语句） | 1 | 2070 |
| chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has | pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史） | 1 | 2079 |
| chk-resource-track-level-operator-realtime | resource_track_level · operator_realtime 级别实时算子监控 | 1 | 2088 |
| chk-pgxc-stat-activity-state-waiting-enqueue | PGXC_STAT_ACTIVITY · state / waiting / enqueue | 1 | 2097 |
| chk-pgxc-stat-activity-runtime-current-timestamp-query-start | PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start) | 1 | 2106 |
| chk-pgxc-stat-activity-waiting-true | PGXC_STAT_ACTIVITY · waiting=true 阻塞查询 | 1 | 2115 |
| chk-pg-locks | pg_locks · 阻塞会话与持锁会话关联 | 1 | 2124 |
| chk-dws-connector-connectiontimeout | DWS-Connector connectionTimeOut 默认值 | 1 | 2133 |
| chk-pgxc-lock-conflicts | pgxc_lock_conflicts 锁冲突视图 | 1 | 2142 |
| chk-pg-stat-activity-pg-locks-sql-8-0-x | pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本） | 1 | 2151 |
| chk- | 写入方式 | 1 | 2538 |
| chk-pgxc-stat-activity-state-waiting-query | pgxc_stat_activity · state / waiting / query | 1 | 2169 |
| chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic- | pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory | 1 | 2178 |
| chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc | pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent | 1 | 2187 |
| chk-vs | 列存表物理大小 vs 有效数据量 | 1 | 2349 |
| chk- | 各节点磁盘使用率均衡性 | 1 | 2538 |
| chk-pgxc-thread-wait-status-dn | pgxc_thread_wait_status · 作业等待 DN 分布 | 1 | 2214 |
| chk-explain-performance-dn | explain performance · DN 行数与耗时分布 | 1 | 2223 |
| chk-table-skewness | table_skewness · 数据倾斜率 | 1 | 2232 |
| chk-pgxc-get-table-skewness | pgxc_get_table_skewness · 全库倾斜视图 | 1 | 2241 |
| chk-cn-pg-log-warning | CN pg_log 日志中 Warning 信息 | 1 | 2250 |
| chk-explain-verbose-remote | EXPLAIN VERBOSE · __REMOTE 关键字 | 1 | 2259 |
| chk-cn | CN日志 · 不下推原因 | 1 | 2268 |
| chk-nestloop | 执行计划算子类型（NestLoop出现） | 1 | 2277 |
| chk-explain-partitioned-cstore-scan-selected-partitions | EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量 | 1 | 2286 |
| chk-i-o-cpu | 系统资源 I/O / 内存 / CPU 使用情况 | 1 | 2295 |
| chk-pg-thread-wait-status | pg_thread_wait_status · 线程等待状态 | 1 | 2304 |
| chk-gstack-vecnestloopruntime | gstack · 进程堆栈中 VecNestLoopRuntime | 1 | 2313 |
| chk-pg-stat-activity-sql | pg_stat_activity 活跃SQL | 2 | 2322 |
| chk- | 表倾斜情况 | 1 | 2538 |
| chk-max-process-memory-shared-buffers-work-mem | max_process_memory / shared_buffers / work_mem 内存参数 | 1 | 2340 |
| chk-vs | 脏数据膨胀率 / 表实际大小 vs 有效数据量 | 1 | 2349 |
| chk-explain | EXPLAIN执行计划耗时分布 | 1 | 2358 |
| chk-cstore-scan | 执行计划算子：CStore Scan耗时占比 | 1 | 2367 |
| chk-pg-session-wlmstat-status-statement-mem | pg_session_wlmstat · status / statement_mem | 1 | 2376 |
| chk-cudesc-cu-row-count | cudesc表中CU的row_count分布 | 1 | 2385 |
| chk-cu | 执行计划中CU扫描数量 | 1 | 2394 |
| chk-explain-cstore-scan-cusome-cunone | EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数 | 1 | 2403 |
| chk-explain-scan-vs | EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数 | 1 | 2412 |
| chk- | 表脏页率 | 1 | 2538 |
| chk-explain-scan-a-time-max-min-dn | EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比 | 1 | 2430 |
| chk-table-distribution-dn | table_distribution 各DN数据行数 | 1 | 2439 |
| chk-explain-seq-scan-vs-index-scan | EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan） | 1 | 2448 |
| chk-explain-selected-partitions | EXPLAIN 执行计划 · Selected Partitions 数量 | 1 | 2457 |
| chk-pgxc-thread-wait-status-wait-status-wait-event | pgxc_thread_wait_status · wait_status / wait_event | 1 | 2466 |
| chk-pg-partition | pg_partition 各表分区数 | 1 | 2475 |
| chk-pv-total-memory-detail-process-used-memory-vs-max-process-me | pv_total_memory_detail · process_used_memory vs max_process_memory | 1 | 2484 |
| chk-pgxc-lock-conflicts-8-1-x | pgxc_lock_conflicts 锁冲突（8.1.x及以上） | 1 | 2493 |
| chk-pgxc-stat-activity-vacuum-full-8-0-x | pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前） | 1 | 2502 |
| chk-pgxc-thread-wait-status | pgxc_thread_wait_status 锁等待状态 | 1 | 2511 |
| chk-pck | 表定义是否存在PCK | 1 | 2520 |
| chk-psort-work-mem | psort_work_mem 参数值 | 1 | 3401 |
| chk- | 列存表文件大小监控 | 1 | 2538 |
| chk-abort-transaction-due-to-concurrent-update | 数据库错误日志 · abort transaction due to concurrent update | 1 | 2547 |

## parameter-current-value (105)

| check_id | param_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-kernel-boot-cmdline-nohz-off | kernel boot cmdline `nohz=off` | 1 | 2556 |
| chk-linux-kernel-page-size | Linux kernel `Page size` 编译选项 | 1 | 2564 |
| chk-mysql-innodb-thread-concurrency-nginx-worker-processes | MySQL `innodb_thread_concurrency` / Nginx `worker_processes` / 其他应用并发设置 | 1 | 2572 |
| chk-mount-options-noatime | mount.options.noatime | 1 | 2580 |
| chk-mount-options-nobarrier | mount.options.nobarrier | 1 | 2588 |
| chk-net-ipv4-tcp-max-syn-backlog | net.ipv4.tcp_max_syn_backlog | 2 | 2596 |
| chk-net-core-somaxconn | net.core.somaxconn | 2 | 2604 |
| chk-net-core-rmem-max | net.core.rmem_max | 1 | 2612 |
| chk-net-core-wmem-max | net.core.wmem_max | 1 | 2620 |
| chk-net-ipv4-tcp-rmem | net.ipv4.tcp_rmem | 1 | 2628 |
| chk-net-ipv4-tcp-wmem | net.ipv4.tcp_wmem | 1 | 2636 |
| chk-net-ipv4-tcp-max-tw-buckets | net.ipv4.tcp_max_tw_buckets | 2 | 2644 |
| chk-net-ipv4-ip-local-port-range | net.ipv4.ip_local_port_range | 1 | 2652 |
| chk-net-ipv4-tcp-tw-reuse | net.ipv4.tcp_tw_reuse | 1 | 2660 |
| chk-net-core-netdev-max-backlog | net.core.netdev_max_backlog | 1 | 2668 |
| chk-net-ipv4-tcp-keepalive-time | net.ipv4.tcp_keepalive_time | 3 | 2676 |
| chk-net-ipv4-tcp-fin-timeout | net.ipv4.tcp_fin_timeout | 1 | 2684 |
| chk-bios-advanced-misc-config-support-smmu | bios.advanced.misc_config.support_smmu | 1 | 2692 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 2700 |
| chk-systemd-unit-irqbalance-service | systemd.unit.irqbalance.service | 1 | 2708 |
| chk-proc-irq-n-smp-affinity-list | proc.irq.<N>.smp_affinity_list | 1 | 2716 |
| chk-sys-block-device-queue-nr-requests | /sys/block/${device}/queue/nr_requests | 1 | 2724 |
| chk-libvirt-domain-cputune-vcpupin | libvirt.domain.cputune.vcpupin | 1 | 2732 |
| chk-grub-linux-default-hugepagesz | grub.linux.default_hugepagesz | 1 | 2740 |
| chk-libvirt-domain-memorybacking-hugepages | libvirt.domain.memoryBacking.hugepages | 1 | 2748 |
| chk-numactl-c-sched-setaffinity-worker-cpu-affinity | (非操作系统参数,而是**应用启动方式**或**应用配置**)`numactl -C` / `sched_setaffinity` / 应用配置中的 worker_cpu_affinity | 1 | 2756 |
| chk-proc-irq-irq-smp-affinity-list | /proc/irq/$irq/smp_affinity_list | 1 | 2764 |
| chk-ethtool-c-eth-adaptive-rx-adaptive-tx | ethtool -C $eth adaptive-rx / adaptive-tx | 1 | 2772 |
| chk-ethtool-c-eth-rx-usecs-tx-usecs-rx-frames-tx-frames | ethtool -C $eth rx-usecs / tx-usecs / rx-frames / tx-frames | 1 | 2780 |
| chk-sys-class-net-nic-queues-rx-0-rps-cpus | /sys/class/net/$nic/queues/rx-0/rps_cpus | 1 | 2788 |
| chk-sys-class-net-nic-queues-rx-0-rps-flow-cnt-proc-sys-net-core | /sys/class/net/$nic/queues/rx-0/rps_flow_cnt + /proc/sys/net/core/rps_sock_flow_entries | 1 | 2796 |
| chk-proc-sys-vm-dirty-expire-centisecs | /proc/sys/vm/dirty_expire_centisecs | 1 | 2804 |
| chk-proc-sys-vm-dirty-background-ratio | /proc/sys/vm/dirty_background_ratio | 1 | 2812 |
| chk-proc-sys-vm-dirty-ratio | /proc/sys/vm/dirty_ratio | 1 | 2820 |
| chk-sys-block-device-name-queue-scheduler | /sys/block/$DEVICE-NAME/queue/scheduler | 1 | 2828 |
| chk-mount-option-barrier-nobarrier | mount option · barrier / nobarrier | 1 | 2836 |
| chk-filesystem-type-mkfs-xfs-vs-mkfs-ext4 | filesystem type (mkfs.xfs vs mkfs.ext4) | 1 | 2844 |
| chk-mkfs-xfs-b-size | mkfs.xfs -b size= | 1 | 2852 |
| chk-vm-dirty-ratio-vm-dirty-background-ratio | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 2860 |
| chk-kernel-transparent-hugepage | kernel.transparent_hugepage | 2 | 2868 |
| chk-block-device-queue-read-ahead-kb-udev-attr-bdi-read-ahead-kb | block device queue/read_ahead_kb(udev ATTR{bdi/read_ahead_kb}) | 1 | 2876 |
| chk-wiredtiger-engineconfig-memory-page-max | wiredTiger.engineConfig.memory_page_max(诊断专用 · 实际生产不应调) | 1 | 2884 |
| chk-storage-wiredtiger-engineconfig-cachesizegb | storage.wiredTiger.engineConfig.cacheSizeGB | 1 | 2892 |
| chk-tcmalloc-aggressive-decommit | TCMALLOC_AGGRESSIVE_DECOMMIT(环境变量 / 启动参数) | 1 | 2900 |
| chk-wiredtiger-cache-eviction-updates-trigger-eviction-updates-t | wiredTiger.cache.eviction_updates_trigger / eviction_updates_target | 1 | 2908 |
| chk-wiredtigerengineruntimeconfig-checkpoint-wait-log-size | wiredTigerEngineRuntimeConfig.checkpoint.wait / log_size | 1 | 2916 |
| chk-eviction-trigger | eviction_trigger | 1 | 2924 |
| chk-innodb-thread-concurrency-mysql-worker-processes-nginx | innodb_thread_concurrency (MySQL) / worker_processes (Nginx) / 应用自有并发参数 | 1 | 2932 |
| chk-worker-processes | worker_processes | 1 | 2940 |
| chk-linker-flags-ljemalloc-l-jemalloc-config-libdir | linker flags · -ljemalloc + -L`jemalloc-config --libdir` | 1 | 2948 |
| chk-malloc-lib-my-cnf | malloc-lib (my.cnf) 或类似配置 | 1 | 2956 |
| chk-slowopthresholdms-atlas-managed-dynamic-fixed-100ms | slowOpThresholdMs (Atlas-managed dynamic / fixed 100ms) | 1 | 2964 |
| chk-maxincomingconnections-ulimit-n | maxIncomingConnections / ulimit -n | 1 | 2972 |
| chk-storageengineconcurrentreadtransactions-storageengineconcurr | storageEngineConcurrentReadTransactions / storageEngineConcurrentWriteTransactions | 1 | 2980 |
| chk-maxpoolsize | maxPoolSize | 3 | 2988 |
| chk-deployment-dbpath | (deployment) dbPath 挂载点文件系统 | 2 | 2996 |
| chk-tuned-profile | tuned profile | 1 | 3004 |
| chk-numactl-interleave-all-mongod | numactl --interleave=all (启动 mongod 时) | 1 | 3012 |
| chk-vm-swappiness | vm.swappiness | 1 | 3020 |
| chk-glibc-tunables-env | GLIBC_TUNABLES (env) | 1 | 3028 |
| chk-defaultwriteconcern-w-write-concern | defaultWriteConcern.w(及业务调用侧 write concern) | 1 | 3036 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 3044 |
| chk-connecttimeoutms | connectTimeoutMS | 1 | 3052 |
| chk-sockettimeoutms | socketTimeoutMS | 1 | 3060 |
| chk-minpoolsize | minPoolSize | 1 | 3068 |
| chk-operationprofiling-slowopthresholdms-db-setprofilinglevel-sl | operationProfiling.slowOpThresholdMs / db.setProfilingLevel slowms | 1 | 3076 |
| chk-operationprofiling-slowopsamplerate-setprofilinglevel-sample | operationProfiling.slowOpSampleRate / setProfilingLevel sampleRate | 1 | 3084 |
| chk-kernel-transparent-hugepage-enabled-systemd-init-d-kernel-bo | kernel transparent_hugepage/enabled(可通过 systemd / init.d / kernel boot param 启用) | 1 | 3092 |
| chk-writeconcernmajorityjournaldefault-writeconcern | writeConcernMajorityJournalDefault / 应用层 writeConcern | 1 | 3100 |
| chk-flowcontroltargetlagseconds | flowControlTargetLagSeconds | 1 | 3108 |
| chk-internalqueryframeworkcontrol | internalQueryFrameworkControl | 1 | 3116 |
| chk-sharding-chunk-size-64mb-25 | sharding chunk size(默认 64MB)/ 25 万文档上限 | 1 | 3124 |
| chk-replsets-storage-wiredtiger-engineconfig-cachesizeratio-cont | replsets.storage.wiredTiger.engineConfig.cacheSizeRatio + container resources.limits.memory | 1 | 3132 |
| chk-defaultwriteconcern-w | defaultWriteConcern.w | 1 | 3140 |
| chk-replicaset-config-writeconcernmajorityjournaldefault | replicaSet.config.writeConcernMajorityJournalDefault | 1 | 3148 |
| chk-wiredtigerengineruntimeconfig-eviction-dirty-trigger-evictio | wiredTigerEngineRuntimeConfig.eviction_dirty_trigger / eviction_dirty_target | 1 | 3156 |
| chk-wiredtigerengineruntimeconfig-eviction-threads-min-threads-m | wiredTigerEngineRuntimeConfig.eviction.threads_min / threads_max | 1 | 3164 |
| chk-shared-buffers | shared_buffers | 3 | 3172 |
| chk-work-mem | work_mem | 3 | 3181 |
| chk-rewrite-rule | rewrite_rule | 9 | 3190 |
| chk-enable-hashjoin | enable_hashjoin | 2 | 3199 |
| chk-enable-nestloop | enable_nestloop | 3 | 3208 |
| chk-enable-mergejoin | enable_mergejoin | 1 | 3217 |
| chk-enable-sort | enable_sort | 3 | 3225 |
| chk-recovery-parse-workers | recovery_parse_workers | 1 | 3234 |
| chk-recovery-redo-workers | recovery_redo_workers | 1 | 3243 |
| chk-enable-index-nestloop | enable_index_nestloop | 1 | 3252 |
| chk-enable-indexscan | enable_indexscan | 2 | 3261 |
| chk-max-process-memory | max_process_memory | 2 | 3269 |
| chk-qrw-inlist2join-optmode | qrw_inlist2join_optmode | 1 | 3278 |
| chk-autovacuum | autovacuum | 1 | 3287 |
| chk-autovacuum-vacuum-cost-delay | autovacuum_vacuum_cost_delay | 1 | 3296 |
| chk-autovacuum-max-workers | autovacuum_max_workers | 1 | 3305 |
| chk-autovacuum-naptime | autovacuum_naptime | 2 | 3314 |
| chk-max-active-statements | max_active_statements | 1 | 3323 |
| chk-autovacuum-max-workers-hstore | autovacuum_max_workers_hstore | 1 | 3332 |
| chk-enable-codegen | enable_codegen | 1 | 3341 |
| chk-enable-numa-bind | enable_numa_bind | 1 | 3349 |
| chk-abnormal-check-general-task | abnormal_check_general_task | 1 | 3357 |
| chk-resource-track-level | resource_track_level | 1 | 3366 |
| chk-track-activities | track_activities | 1 | 3375 |
| chk-connectiontimeout | connectionTimeOut | 1 | 3383 |
| chk-lockwait-timeout | lockwait_timeout | 1 | 3392 |
| chk-psort-work-mem | psort_work_mem | 1 | 3401 |
| chk-enable-delta | ENABLE_DELTA | 1 | 3410 |
