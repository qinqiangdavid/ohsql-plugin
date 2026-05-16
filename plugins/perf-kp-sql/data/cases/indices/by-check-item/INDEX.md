# Check Items Index · 指标集合

> 生成时间: 2026-05-16T12:08:50.649Z
> 数据源: 派生于 cases/CASES.md (每条 case 的 diagnostic_steps[*].metric_name + likely_causes.parameter_causes[*])
> 总计: 215 checks (metric 138 / param 77)
> 配套: cases/indices/by-check-item/CASES.md

## metric (138)

| check_id | metric_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-proc-cmdline-nohz-off | /proc/cmdline 中是否含 `nohz=off` | 1 | 9 |
| chk-timer-tick | timer_tick 调度次数(单位时间内) | 1 | 18 |
| chk-dtlb-load-misses-itlb-load-misses | dTLB-load-misses 比率 / iTLB-load-misses 比率 | 1 | 27 |
| chk-tps-vs | TPS / 业务吞吐 vs 线程并发数 | 1 | 36 |
| chk-mount-options | mount.options | 1 | 45 |
| chk-sysctl-net-7-keys | sysctl.net.* (7 keys) | 1 | 54 |
| chk-sysctl-net-8-keys | sysctl.net.* (8 keys) | 1 | 63 |
| chk-bios-advanced-misc-config-support-smmu | bios.advanced.misc_config.support_smmu | 1 | 1387 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 1395 |
| chk-systemd-unit-irqbalance-service-active-state | systemd.unit.irqbalance.service.active_state | 1 | 90 |
| chk-proc-interrupts-smp-affinity-list | proc.interrupts.smp_affinity_list | 1 | 99 |
| chk-blockdev-queue-nr-requests | blockdev.queue.nr_requests | 1 | 108 |
| chk-libvirt-domain-cputune-vcpupin | libvirt.domain.cputune.vcpupin | 1 | 1427 |
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
| chk-vm-dirty-ratio-vm-dirty-background-ratio | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 1555 |
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
| chk-net-ipv4-tcp-keepalive-time | net.ipv4.tcp_keepalive_time | 1 | 1371 |
| chk-mongod-startup-log-numa-warning | mongod startup log · NUMA warning 行 | 1 | 765 |
| chk-numad | numad 进程 | 1 | 774 |
| chk-vm-swappiness | vm.swappiness | 1 | 1715 |
| chk-ec2-instance-type-enhanced-networking-ebs-provisioned-iops | EC2 instance type / Enhanced Networking 状态 / EBS provisioned IOPS | 1 | 792 |
| chk-tcmalloc-usingpercpucaches-tcmalloc-tcmalloc-cpu-free | tcmalloc.usingPerCPUCaches / tcmalloc.tcmalloc.cpu_free | 1 | 801 |
| chk-glibc-pthread-rseq-tunable-glibc-tunables-env | glibc.pthread.rseq tunable / GLIBC_TUNABLES env | 1 | 810 |
| chk-kernel-version | kernel version | 1 | 819 |
| chk-replsetgetstatus-members-statestr-primary-secondary-arbiter | replSetGetStatus.members[] 的 stateStr 分布(PRIMARY/SECONDARY/ARBITER) | 1 | 828 |
| chk-secondary-health-state-optimedate-primary | secondary 的 health/state · optimeDate 与 primary 的差距 | 1 | 837 |
| chk-getdefaultrwconcern-defaultwriteconcern-w | getDefaultRWConcern → defaultWriteConcern.w | 1 | 846 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 1739 |
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

## parameter-current-value (77)

| check_id | param_name | 关联 case 数 | 行号 |
|---|---|---:|---:|
| chk-kernel-boot-cmdline-nohz-off | kernel boot cmdline `nohz=off` | 1 | 1251 |
| chk-linux-kernel-page-size | Linux kernel `Page size` 编译选项 | 1 | 1259 |
| chk-mysql-innodb-thread-concurrency-nginx-worker-processes | MySQL `innodb_thread_concurrency` / Nginx `worker_processes` / 其他应用并发设置 | 1 | 1267 |
| chk-mount-options-noatime | mount.options.noatime | 1 | 1275 |
| chk-mount-options-nobarrier | mount.options.nobarrier | 1 | 1283 |
| chk-net-ipv4-tcp-max-syn-backlog | net.ipv4.tcp_max_syn_backlog | 2 | 1291 |
| chk-net-core-somaxconn | net.core.somaxconn | 2 | 1299 |
| chk-net-core-rmem-max | net.core.rmem_max | 1 | 1307 |
| chk-net-core-wmem-max | net.core.wmem_max | 1 | 1315 |
| chk-net-ipv4-tcp-rmem | net.ipv4.tcp_rmem | 1 | 1323 |
| chk-net-ipv4-tcp-wmem | net.ipv4.tcp_wmem | 1 | 1331 |
| chk-net-ipv4-tcp-max-tw-buckets | net.ipv4.tcp_max_tw_buckets | 2 | 1339 |
| chk-net-ipv4-ip-local-port-range | net.ipv4.ip_local_port_range | 1 | 1347 |
| chk-net-ipv4-tcp-tw-reuse | net.ipv4.tcp_tw_reuse | 1 | 1355 |
| chk-net-core-netdev-max-backlog | net.core.netdev_max_backlog | 1 | 1363 |
| chk-net-ipv4-tcp-keepalive-time | net.ipv4.tcp_keepalive_time | 3 | 1371 |
| chk-net-ipv4-tcp-fin-timeout | net.ipv4.tcp_fin_timeout | 1 | 1379 |
| chk-bios-advanced-misc-config-support-smmu | bios.advanced.misc_config.support_smmu | 1 | 1387 |
| chk-bios-advanced-misc-config-cpu-prefetching-configuration | bios.advanced.misc_config.cpu_prefetching_configuration | 1 | 1395 |
| chk-systemd-unit-irqbalance-service | systemd.unit.irqbalance.service | 1 | 1403 |
| chk-proc-irq-n-smp-affinity-list | proc.irq.<N>.smp_affinity_list | 1 | 1411 |
| chk-sys-block-device-queue-nr-requests | /sys/block/${device}/queue/nr_requests | 1 | 1419 |
| chk-libvirt-domain-cputune-vcpupin | libvirt.domain.cputune.vcpupin | 1 | 1427 |
| chk-grub-linux-default-hugepagesz | grub.linux.default_hugepagesz | 1 | 1435 |
| chk-libvirt-domain-memorybacking-hugepages | libvirt.domain.memoryBacking.hugepages | 1 | 1443 |
| chk-numactl-c-sched-setaffinity-worker-cpu-affinity | (非操作系统参数,而是**应用启动方式**或**应用配置**)`numactl -C` / `sched_setaffinity` / 应用配置中的 worker_cpu_affinity | 1 | 1451 |
| chk-proc-irq-irq-smp-affinity-list | /proc/irq/$irq/smp_affinity_list | 1 | 1459 |
| chk-ethtool-c-eth-adaptive-rx-adaptive-tx | ethtool -C $eth adaptive-rx / adaptive-tx | 1 | 1467 |
| chk-ethtool-c-eth-rx-usecs-tx-usecs-rx-frames-tx-frames | ethtool -C $eth rx-usecs / tx-usecs / rx-frames / tx-frames | 1 | 1475 |
| chk-sys-class-net-nic-queues-rx-0-rps-cpus | /sys/class/net/$nic/queues/rx-0/rps_cpus | 1 | 1483 |
| chk-sys-class-net-nic-queues-rx-0-rps-flow-cnt-proc-sys-net-core | /sys/class/net/$nic/queues/rx-0/rps_flow_cnt + /proc/sys/net/core/rps_sock_flow_entries | 1 | 1491 |
| chk-proc-sys-vm-dirty-expire-centisecs | /proc/sys/vm/dirty_expire_centisecs | 1 | 1499 |
| chk-proc-sys-vm-dirty-background-ratio | /proc/sys/vm/dirty_background_ratio | 1 | 1507 |
| chk-proc-sys-vm-dirty-ratio | /proc/sys/vm/dirty_ratio | 1 | 1515 |
| chk-sys-block-device-name-queue-scheduler | /sys/block/$DEVICE-NAME/queue/scheduler | 1 | 1523 |
| chk-mount-option-barrier-nobarrier | mount option · barrier / nobarrier | 1 | 1531 |
| chk-filesystem-type-mkfs-xfs-vs-mkfs-ext4 | filesystem type (mkfs.xfs vs mkfs.ext4) | 1 | 1539 |
| chk-mkfs-xfs-b-size | mkfs.xfs -b size= | 1 | 1547 |
| chk-vm-dirty-ratio-vm-dirty-background-ratio | vm.dirty_ratio / vm.dirty_background_ratio | 1 | 1555 |
| chk-kernel-transparent-hugepage | kernel.transparent_hugepage | 2 | 1563 |
| chk-block-device-queue-read-ahead-kb-udev-attr-bdi-read-ahead-kb | block device queue/read_ahead_kb(udev ATTR{bdi/read_ahead_kb}) | 1 | 1571 |
| chk-wiredtiger-engineconfig-memory-page-max | wiredTiger.engineConfig.memory_page_max(诊断专用 · 实际生产不应调) | 1 | 1579 |
| chk-storage-wiredtiger-engineconfig-cachesizegb | storage.wiredTiger.engineConfig.cacheSizeGB | 1 | 1587 |
| chk-tcmalloc-aggressive-decommit | TCMALLOC_AGGRESSIVE_DECOMMIT(环境变量 / 启动参数) | 1 | 1595 |
| chk-wiredtiger-cache-eviction-updates-trigger-eviction-updates-t | wiredTiger.cache.eviction_updates_trigger / eviction_updates_target | 1 | 1603 |
| chk-wiredtigerengineruntimeconfig-checkpoint-wait-log-size | wiredTigerEngineRuntimeConfig.checkpoint.wait / log_size | 1 | 1611 |
| chk-eviction-trigger | eviction_trigger | 1 | 1619 |
| chk-innodb-thread-concurrency-mysql-worker-processes-nginx | innodb_thread_concurrency (MySQL) / worker_processes (Nginx) / 应用自有并发参数 | 1 | 1627 |
| chk-worker-processes | worker_processes | 1 | 1635 |
| chk-linker-flags-ljemalloc-l-jemalloc-config-libdir | linker flags · -ljemalloc + -L`jemalloc-config --libdir` | 1 | 1643 |
| chk-malloc-lib-my-cnf | malloc-lib (my.cnf) 或类似配置 | 1 | 1651 |
| chk-slowopthresholdms-atlas-managed-dynamic-fixed-100ms | slowOpThresholdMs (Atlas-managed dynamic / fixed 100ms) | 1 | 1659 |
| chk-maxincomingconnections-ulimit-n | maxIncomingConnections / ulimit -n | 1 | 1667 |
| chk-storageengineconcurrentreadtransactions-storageengineconcurr | storageEngineConcurrentReadTransactions / storageEngineConcurrentWriteTransactions | 1 | 1675 |
| chk-maxpoolsize | maxPoolSize | 3 | 1683 |
| chk-deployment-dbpath | (deployment) dbPath 挂载点文件系统 | 2 | 1691 |
| chk-tuned-profile | tuned profile | 1 | 1699 |
| chk-numactl-interleave-all-mongod | numactl --interleave=all (启动 mongod 时) | 1 | 1707 |
| chk-vm-swappiness | vm.swappiness | 1 | 1715 |
| chk-glibc-tunables-env | GLIBC_TUNABLES (env) | 1 | 1723 |
| chk-defaultwriteconcern-w-write-concern | defaultWriteConcern.w(及业务调用侧 write concern) | 1 | 1731 |
| chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct | storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct | 1 | 1739 |
| chk-connecttimeoutms | connectTimeoutMS | 1 | 1747 |
| chk-sockettimeoutms | socketTimeoutMS | 1 | 1755 |
| chk-minpoolsize | minPoolSize | 1 | 1763 |
| chk-operationprofiling-slowopthresholdms-db-setprofilinglevel-sl | operationProfiling.slowOpThresholdMs / db.setProfilingLevel slowms | 1 | 1771 |
| chk-operationprofiling-slowopsamplerate-setprofilinglevel-sample | operationProfiling.slowOpSampleRate / setProfilingLevel sampleRate | 1 | 1779 |
| chk-kernel-transparent-hugepage-enabled-systemd-init-d-kernel-bo | kernel transparent_hugepage/enabled(可通过 systemd / init.d / kernel boot param 启用) | 1 | 1787 |
| chk-writeconcernmajorityjournaldefault-writeconcern | writeConcernMajorityJournalDefault / 应用层 writeConcern | 1 | 1795 |
| chk-flowcontroltargetlagseconds | flowControlTargetLagSeconds | 1 | 1803 |
| chk-internalqueryframeworkcontrol | internalQueryFrameworkControl | 1 | 1811 |
| chk-sharding-chunk-size-64mb-25 | sharding chunk size(默认 64MB)/ 25 万文档上限 | 1 | 1819 |
| chk-replsets-storage-wiredtiger-engineconfig-cachesizeratio-cont | replsets.storage.wiredTiger.engineConfig.cacheSizeRatio + container resources.limits.memory | 1 | 1827 |
| chk-defaultwriteconcern-w | defaultWriteConcern.w | 1 | 1835 |
| chk-replicaset-config-writeconcernmajorityjournaldefault | replicaSet.config.writeConcernMajorityJournalDefault | 1 | 1843 |
| chk-wiredtigerengineruntimeconfig-eviction-dirty-trigger-evictio | wiredTigerEngineRuntimeConfig.eviction_dirty_trigger / eviction_dirty_target | 1 | 1851 |
| chk-wiredtigerengineruntimeconfig-eviction-threads-min-threads-m | wiredTigerEngineRuntimeConfig.eviction.threads_min / threads_max | 1 | 1859 |
