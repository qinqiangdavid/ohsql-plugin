<!-- ============ Check Items · 派生指标集合 ============ -->

<!--
  运行期 SSH 一把采集这些项, 用结果撞 cases/CASES.md 每条 case 的 abnormal_pattern;
  type=metric → 单纯采指标值跟阈值比;
  type=parameter-current-value → 采参数现值跟 recommended_value 比.
-->

## check_id: chk-proc-cmdline-nohz-off

- **type**: metric
- **metric_name**: /proc/cmdline 中是否含 `nohz=off`
- **collection_layer**: os
- **collection_method**: "执行cat /proc/cmdline查看Linux 内核的启动参数,如果有nohz=off关键字,说明nohz机制被关闭,需要打开。"
- **abnormal_patterns**: ["nohz=off` 出现在 /proc/cmdline"]
- **linked_case_ids**: ["kunpeng-nohz-clock-tick-overhead-03"]

## check_id: chk-timer-tick

- **type**: metric
- **metric_name**: timer_tick 调度次数(单位时间内)
- **collection_layer**: os
- **collection_method**: "perf sched record -- sleep 1 -p $PID" 配 "perf sched latency -s max"
- **abnormal_patterns**: ["修改前后调度次数显著未减小"]
- **linked_case_ids**: ["kunpeng-nohz-clock-tick-overhead-03"]

## check_id: chk-dtlb-load-misses-itlb-load-misses

- **type**: metric
- **metric_name**: dTLB-load-misses 比率 / iTLB-load-misses 比率
- **collection_layer**: os
- **collection_method**: "perf stat -p $PID -d -d -d"
- **abnormal_patterns**: ["dTLB miss > 1% / iTLB miss > 0.5%(原文示例值,可作经验阈值)"]
- **linked_case_ids**: ["kunpeng-tlb-miss-page-size-04"]

## check_id: chk-tps-vs

- **type**: metric
- **metric_name**: TPS / 业务吞吐 vs 线程并发数
- **collection_layer**: os
- **collection_method**: "下面数据为某业务场景下,不同并发线程数下的TPS,可以看到并发线程数达到128后,性能达到高峰,随后开始下降。"
- **abnormal_patterns**: ["增加并发后 TPS 反降 → 已过拐点"]
- **linked_case_ids**: ["kunpeng-thread-concurrency-overload-05"]

## check_id: chk-mount-options

- **type**: metric
- **metric_name**: mount.options
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给读取命令)
- **abnormal_patterns**: ["mount options does NOT contain \"noatime\" OR does NOT contain \"nobarrier\" (XFS only)"]
- **linked_case_ids**: ["mongo-fs-mount-noatime-nobarrier-missing-01"]

## check_id: chk-sysctl-net-7-keys

- **type**: metric
- **metric_name**: sysctl.net.* (7 keys)
- **collection_layer**: os
- **collection_method**: (NULL · 原文只给 echo 写命令未给 sysctl 读命令)
- **abnormal_patterns**: ["current value < recommended value (per-key)"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01"]

## check_id: chk-sysctl-net-8-keys

- **type**: metric
- **metric_name**: sysctl.net.* (8 keys)
- **collection_layer**: os
- **collection_method**: (NULL · 原文只给 vim 编辑 sysctl.conf 写法未给读命令)
- **abnormal_patterns**: ["current value ≠ recommended value (per-key)"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]

## check_id: chk-bios-advanced-misc-config-support-smmu

- **type**: metric
- **metric_name**: bios.advanced.misc_config.support_smmu
- **collection_layer**: bios-readout
- **collection_method**: (NULL · 原文给的是"重启进入 BIOS 设置界面"操作流而非可脚本化读法)
- **abnormal_patterns**: ["current = \"Enable\" ≠ \"Disable\" (in non-virtualization scenario)"]
- **linked_case_ids**: ["kunpeng-bios-smmu-enabled-non-virt-01"]

## check_id: chk-bios-advanced-misc-config-cpu-prefetching-configuration

- **type**: metric
- **metric_name**: bios.advanced.misc_config.cpu_prefetching_configuration
- **collection_layer**: bios-readout
- **collection_method**: (NULL · 原文给的是"重启进入 BIOS 设置界面"操作流而非可脚本化读法)
- **abnormal_patterns**: ["current = \"Enabled\" ≠ \"Disabled\""]
- **linked_case_ids**: ["kunpeng-bios-cpu-prefetch-enabled-01"]

## check_id: chk-systemd-unit-irqbalance-service-active-state

- **type**: metric
- **metric_name**: systemd.unit.irqbalance.service.active_state
- **collection_layer**: os
- **collection_method**: "systemctl status irqbalance.service"
- **abnormal_patterns**: ["active_state ≠ \"inactive\" (i.e. running)"]
- **linked_case_ids**: ["kunpeng-net-irq-not-bound-irqbalance-on-01"]

## check_id: chk-proc-interrupts-smp-affinity-list

- **type**: metric
- **metric_name**: proc.interrupts.smp_affinity_list
- **collection_layer**: os
- **collection_method**: (NULL · 原文给的是 mitigation 脚本中的 grep 片段而非独立读命令)
- **abnormal_patterns**: ["smp_affinity_list of NIC IRQs spans cores NOT on NIC's local NUMA node"]
- **linked_case_ids**: ["kunpeng-net-irq-not-bound-irqbalance-on-01"]

## check_id: chk-blockdev-queue-nr-requests

- **type**: metric
- **metric_name**: blockdev.queue.nr_requests
- **collection_layer**: os
- **collection_method**: (NULL · 原文给 echo 写命令未给 cat 读命令)
- **abnormal_patterns**: ["current < 2048 (recommended)"]
- **linked_case_ids**: ["linux-blockdev-nr-requests-too-low-01"]

## check_id: chk-libvirt-domain-cputune-vcpupin

- **type**: metric
- **metric_name**: libvirt.domain.cputune.vcpupin
- **collection_layer**: os
- **collection_method**: (NULL · 原文给的是 `virsh edit vm1` 编辑写流程,未给独立读命令)
- **abnormal_patterns**: ["xml does NOT contain <cputune><vcpupin .../></cputune> AND <vcpu placement='static' cpuset=...>"]
- **linked_case_ids**: ["kvm-vcpupin-not-bound-numa-cross-01"]

## check_id: chk-sys-node-meminfo-hugepages

- **type**: metric
- **metric_name**: sys.node.meminfo.hugepages
- **collection_layer**: os
- **collection_method**: 
- **abnormal_patterns**: ["HugePages_Total = 0 on any NUMA node"]
- **linked_case_ids**: ["kvm-host-hugepages-not-allocated-tlb-miss-01"]

## check_id: chk-numa

- **type**: metric
- **metric_name**: 进程 NUMA 亲和绑定状态
- **collection_layer**: os
- **collection_method**: 原文未直接给出**采集命令**,只给出**修改命令**(`numactl -C 28-31 ./test`)。诊断侧建议用 `numactl -H`(看节点拓扑)+ `numastat -p $PID`(看进程跨节点内存命中率)兜底,**该方法属于诊断常识推断,不是原文字面**(标 `inferred:true`)
- **abnormal_patterns**: ["numa_miss / (numa_hit + numa_miss) > 0.1(经验值,非原文)"]
- **linked_case_ids**: ["kunpeng-numa-cross-node-memory-access-01"]

## check_id: chk-nic-irq-cpu-core

- **type**: metric
- **metric_name**: NIC IRQ → CPU core 绑定分布
- **collection_layer**: os
- **collection_method**: 
- **abnormal_patterns**: ["(定性) IRQ 处理 core ∉ NIC NUMA node"]
- **linked_case_ids**: ["kunpeng-network-irq-cross-numa-01"]

## check_id: chk-nic-interrupt-coalescing-settings-rx-tx-usecs-rx-tx-frames-a

- **type**: metric
- **metric_name**: NIC interrupt coalescing settings (rx/tx-usecs, rx/tx-frames, adaptive-rx/tx)
- **collection_layer**: os
- **collection_method**: (NULL · 原文只给"调整命令"`ethtool -C`，未给"读取命令" `ethtool -c`，避免污染字段)
- **abnormal_patterns**: ["(定性) Adaptive RX/TX = on ∧ 业务对延迟/吞吐有明确诉求"]
- **linked_case_ids**: ["linux-nic-interrupt-coalescing-audit-01"]

## check_id: chk-rps-configuration-rps-cpus-mask-flow-tables

- **type**: metric
- **metric_name**: RPS configuration (rps_cpus mask, flow tables)
- **collection_layer**: os
- **collection_method**: "/sys/class/net/eth0/queues/rx-0/rps_cpus 0" + "/sys/class/net/eth0/queues/rx-0/rps_flow_cnt 0" + "/proc/sys/net/core/rps_sock_flow_entries 0"（原文以三行分别给出）
- **abnormal_patterns**: ["rps_cpus = 0（所有 bits 全 0 表示 RPS 未启用，软中断集中到默认 core）"]
- **linked_case_ids**: ["linux-rps-single-queue-nic-softirq-bottleneck-01"]

## check_id: chk-disk-await-time-vm-dirty-params

- **type**: metric
- **metric_name**: disk await time + vm dirty params
- **collection_layer**: os
- **collection_method**: "可以结合业务并通过观察await的时间波动范围来识别。"
- **abnormal_patterns**: ["(定性) await 突发性飙升 ∨ dirty_ratio 触发同步写"]
- **linked_case_ids**: ["linux-vm-dirty-flush-burst-io-wait-01"]

## check_id: chk-block-device-i-o-scheduler

- **type**: metric
- **metric_name**: block device I/O scheduler
- **collection_layer**: os
- **collection_method**: "# cat /sys/block/$DEVICE-NAME/queue/scheduler"
- **abnormal_patterns**: ["当前调度器（[]中标识） ≠ 业务推荐值（HDD 数据库→deadline / SSD→noop）"]
- **linked_case_ids**: ["linux-block-scheduler-mismatch-01"]

## check_id: chk-mount-options-for-filesystem

- **type**: metric
- **metric_name**: mount options for filesystem
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给"读取挂载选项"命令)
- **abnormal_patterns**: ["挂载未含 nobarrier ∧ RAID 卡有电池"]
- **linked_case_ids**: ["linux-fs-mount-nobarrier-audit-01"]

## check_id: chk-filesystem-type-blocksize

- **type**: metric
- **metric_name**: filesystem type + blocksize
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给"读取文件系统类型/blocksize"命令)
- **abnormal_patterns**: ["filesystem ≠ xfs ∧ workload=大文件 ∨ blocksize=4096 ∧ workload=大文件"]
- **linked_case_ids**: ["linux-fs-xfs-blocksize-audit-01"]

## check_id: chk-perf-top-top-n-functions

- **type**: metric
- **metric_name**: perf top top-N functions（关注锁/原子操作类）
- **collection_layer**: flamegraph
- **collection_method**: "可以通过perf top分析占用CPU资源靠前的函数"
- **abnormal_patterns**: ["lock_acquire+lock_release 函数 cpu_share ≥ 0.05"]
- **linked_case_ids**: ["kunpeng-arm64-spinlock-cas-cpu-waste-01"]

## check_id: chk-l1-l2-l3-cache-miss-false-sharing-event

- **type**: metric
- **metric_name**: L1/L2/L3 cache miss + false-sharing event
- **collection_layer**: flamegraph
- **collection_method**: (NULL · 原文未给具体 perf 命令)
- **abnormal_patterns**: ["(定性) cache miss 率显著升高 + 高频访问的读/写变量在同 CacheLine"]
- **linked_case_ids**: ["kunpeng-cacheline-false-sharing-arm64-128b-01"]

## check_id: chk-vm-dirty-ratio-vm-dirty-background-ratio

- **type**: metric
- **metric_name**: vm.dirty_ratio / vm.dirty_background_ratio
- **collection_layer**: os
- **collection_method**: 
- **abnormal_patterns**: ["dirty_ratio 默认 20-30% 且物理内存 ≥ 64GB"]
- **linked_case_ids**: ["linux-vm-dirty-ratio-pause-on-large-memory-01"]

## check_id: chk-kernel-boot-option-transparent-hugepage

- **type**: metric
- **metric_name**: kernel boot option transparent_hugepage
- **collection_layer**: os
- **collection_method**: (NULL · 原文给出的是设置值 `transparent_hugepage=never`,未给读取命令)
- **abnormal_patterns**: ["(Pre-8.0 视角)/sys/kernel/mm/transparent_hugepage/enabled 当前不为 `never"]
- **linked_case_ids**: ["linux-thp-mongodb-sparse-memory-access-02"]

## check_id: chk-block-device-read-ahead-kb-sectors

- **type**: metric
- **metric_name**: block device read_ahead_kb / sectors
- **collection_layer**: os
- **collection_method**: "$ sudo blockdev --getra /dev/sda"
- **abnormal_patterns**: ["默认 256 扇区(=128KB),建议 32 扇区(=16KB)"]
- **linked_case_ids**: ["linux-readahead-default-128kb-wastes-fs-cache-04"]

## check_id: chk-wiredtiger-cache-bytes-currently-in-the-cache

- **type**: metric
- **metric_name**: wiredTiger.cache.bytes_currently_in_the_cache
- **collection_layer**: mongo-internal-counter
- **collection_method**: (NULL · 原文未给具体采集命令)
- **abnormal_patterns**: ["\"Cache Usage spiking\""]
- **linked_case_ids**: ["mongo-cache-spike-replication-lag-cascade-01"]

## check_id: chk-replication-lag

- **type**: metric
- **metric_name**: replication_lag
- **collection_layer**: mongo-shell
- **collection_method**: (NULL · 原文未给具体采集命令)
- **abnormal_patterns**: ["\"Replication Lag spiking\""]
- **linked_case_ids**: ["mongo-cache-spike-replication-lag-cascade-01"]

## check_id: chk-mongod-process-state

- **type**: metric
- **metric_name**: mongod_process_state
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给具体采集命令)
- **abnormal_patterns**: ["\"cache usage hits a certain point on the primary (left) server after which we ha"]
- **linked_case_ids**: ["mongo-cache-spike-replication-lag-cascade-01"]

## check_id: chk-sharding-balancer-migration-24h-results-sharding-collection-

- **type**: metric
- **metric_name**: sharding.balancer.migration_24h_results · sharding.collection.chunks_per_shard
- **collection_layer**: mongo-shell
- **collection_method**: (NULL · 原文给的是 sh.status() 的输出而非显式调用命令的字面 quote)
- **abnormal_patterns**: ["{\"failed_migrations_24h\": \">= 7000\", \"chunk_skew_max_min_ratio\": \">= 1.5\"}"]
- **linked_case_ids**: ["mongo-shard-chunk-migration-x-lock-timeout-balancer-stuck-01"]

## check_id: chk-log-sharding-migrationfailed-error

- **type**: metric
- **metric_name**: log.SHARDING.MigrationFailed.error
- **collection_layer**: log-grep
- **collection_method**: (NULL · 原文只说 "debug the issue through mongodb.log on the config server" 未给具体 grep 命令字面)
- **abnormal_patterns**: ["{\"error_class\": \"LockTimeout\", \"op\": \"MoveChunk\", \"lock_timeout_ms\": 500}"]
- **linked_case_ids**: ["mongo-shard-chunk-migration-x-lock-timeout-balancer-stuck-01"]

## check_id: chk-sh-movechunk-errmsg

- **type**: metric
- **metric_name**: sh.moveChunk.errmsg
- **collection_layer**: mongo-shell
- **collection_method**: "sh.moveChunk(\"X.A\", {\"Uuid\": \"XX\"}, \"mongo-3\" )"
- **abnormal_patterns**: ["{\"errmsg_class\": \"LockTimeout\", \"code\": 24, \"codeName\": \"LockTimeout\"}"]
- **linked_case_ids**: ["mongo-shard-chunk-migration-x-lock-timeout-balancer-stuck-01"]

## check_id: chk-sharding-collection-jumbo-chunks

- **type**: metric
- **metric_name**: sharding.collection.jumbo_chunks
- **collection_layer**: mongo-shell
- **collection_method**: "sh.status(true)"
- **abnormal_patterns**: ["{\"jumbo_chunks_count\": \"> 0 → suspect; == 0 → 排除\"}"]
- **linked_case_ids**: ["mongo-shard-chunk-migration-x-lock-timeout-balancer-stuck-01"]

## check_id: chk-currentop-locks-currentop-waitingforlock

- **type**: metric
- **metric_name**: currentOp.locks · currentOp.waitingForLock
- **collection_layer**: mongo-shell
- **collection_method**: "db.currentOp()"
- **abnormal_patterns**: ["{\"hint\": \"线索缺失 · 进入下一步源端切主验证\"}"]
- **linked_case_ids**: ["mongo-shard-chunk-migration-x-lock-timeout-balancer-stuck-01"]

## check_id: chk-wiredtiger-cache-pages-written-from-cache-pages-read-into-ca

- **type**: metric
- **metric_name**: wiredTiger.cache.pages written from cache / pages read into cache
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · JIRA 描述未给具体读取命令)
- **abnormal_patterns**: ["fetch 期间 pages written from cache 与 pages read into cache 周期性同步出现尖峰"]
- **linked_case_ids**: ["mongo-wt-large-page-eviction-fetch-pause-server-16479"]

## check_id: chk-mongod

- **type**: metric
- **metric_name**: mongod 进程栈采样函数命中分布
- **collection_layer**: flamegraph
- **collection_method**: "sampling periodically with gdb. The eviction shows up as a pause between the first query and the getmores from the app, coinciding with pages being written"
- **abnormal_patterns**: ["gdb 采样栈中重复出现 `__wt_btcur_reset` / `WiredTigerSession::releaseCursor"]
- **linked_case_ids**: ["mongo-wt-large-page-eviction-fetch-pause-server-16479"]

## check_id: chk-wiredtiger-cache-used-mongostat-used

- **type**: metric
- **metric_name**: wiredTiger cache used % (mongostat 输出列 used)
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "Start mongostat to monitor the cache statistics while paging in the b-trees using this command:"
- **abnormal_patterns**: ["cache 利用率从 80% 在数分钟内跌到 0%"]
- **linked_case_ids**: ["mongo-wt-btree-sweep-eviction-collection-blocked-server-17907"]

## check_id: chk-db-collection-stats-1024-1024-size-totalindexsize

- **type**: metric
- **metric_name**: db.collection.stats(1024*1024).size + totalIndexSize
- **collection_layer**: mongo-shell
- **collection_method**: "s = db.c.stats(1024*1024)"
- **abnormal_patterns**: ["size + totalIndexSize 接近 cacheSize 上限 + 长时间未访问后被 sweep"]
- **linked_case_ids**: ["mongo-wt-btree-sweep-eviction-collection-blocked-server-17907"]

## check_id: chk-serverstatus-tcmalloc-tcmalloc-pageheap-free-bytes

- **type**: metric
- **metric_name**: serverStatus.tcmalloc.tcmalloc.pageheap_free_bytes
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · ticket 描述未给具体读取命令)
- **abnormal_patterns**: ["pageheap_free_bytes 在数秒内由数 GB 跌到接近 0"]
- **linked_case_ids**: ["mongo-tcmalloc-decommit-madvise-lock-stall-server-31417"]

## check_id: chk-serverstatus-tcmalloc-tcmalloc-pageheap-unmapped-bytes

- **type**: metric
- **metric_name**: serverStatus.tcmalloc.tcmalloc.pageheap_unmapped_bytes
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 同 ref)
- **abnormal_patterns**: ["unmapped_bytes 同时段对称增加"]
- **linked_case_ids**: ["mongo-tcmalloc-decommit-madvise-lock-stall-server-31417"]

## check_id: chk-mongod-rss

- **type**: metric
- **metric_name**: mongod 进程 RSS
- **collection_layer**: os
- **collection_method**: (NULL)
- **abnormal_patterns**: ["RSS 同时段下降相同量级","RSS ≫ allocated_bytes(原文示例 ≈ 14GB vs 8GB)"]
- **linked_case_ids**: ["mongo-tcmalloc-decommit-madvise-lock-stall-server-31417","mongo-tcmalloc-heap-fragmentation-pageheap-free-server-33296"]

## check_id: chk-proc-meminfo-memfree

- **type**: metric
- **metric_name**: /proc/meminfo MemFree
- **collection_layer**: os
- **collection_method**: (NULL · ticket 未给读取命令)
- **abnormal_patterns**: ["OS 层 MemFree 同时段对应上升"]
- **linked_case_ids**: ["mongo-tcmalloc-decommit-madvise-lock-stall-server-31417"]

## check_id: chk-mongod-tcmalloc-tcmalloc-generic-heap-size-current-allocated

- **type**: metric
- **metric_name**: mongod tcmalloc.tcmalloc.generic.heap_size / current_allocated_bytes / pageheap_free_bytes
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · ticket 描述未给具体读取命令)
- **abnormal_patterns**: ["(heap_size - current_allocated_bytes) ≈ pageheap_free_bytes 且持续增长"]
- **linked_case_ids**: ["mongo-tcmalloc-heap-fragmentation-pageheap-free-server-33296"]

## check_id: chk-mongod-vsz

- **type**: metric
- **metric_name**: mongod 进程 VSZ
- **collection_layer**: os
- **collection_method**: (NULL · ticket 描述未给具体读取命令)
- **abnormal_patterns**: ["mongod VSZ 比 cacheSizeGB + 合理开销大数 GB(原文示例 4.4-rc4 多 9G)"]
- **linked_case_ids**: ["mongo-wt-tcmalloc-fragmentation-durable-history-wt-6175"]

## check_id: chk-wiredtiger-cache-dirty

- **type**: metric
- **metric_name**: wiredTiger cache dirty %
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · ticket 描述未给具体读取命令)
- **abnormal_patterns**: ["cache dirty % 长期接近 2.5% 而非 5%(说明被新 updates trigger 主导)"]
- **linked_case_ids**: ["mongo-wt-tcmalloc-fragmentation-durable-history-wt-6175"]

## check_id: chk-globallock-currentqueue-total

- **type**: metric
- **metric_name**: globalLock.currentQueue.total
- **collection_layer**: mongo-shell
- **collection_method**: (NULL · 原文未给字面 db.serverStatus() 命令)
- **abnormal_patterns**: ["\"如果 globalLock.currentQueue.total 值持续较高，有可能有大量的请求在等待锁释放。说明可能有影响性能的并发问题。\"","currentQueue.total 持续 > 0(即业务 RPS 远低于 globalLock 排队增量)"]
- **linked_case_ids**: ["mongo-globallock-current-queue-high-lock-contention-01","mongo-locking-queue-buildup-01"]

## check_id: chk-globallock-totaltime-vs-uptime

- **type**: metric
- **metric_name**: globalLock.totalTime_vs_uptime
- **collection_layer**: mongo-shell
- **collection_method**: (NULL · 同上)
- **abnormal_patterns**: ["\"如果  globalLock.totalTime  相对于  uptime 较高，说明数据库的死锁已经维持一段时间了。\""]
- **linked_case_ids**: ["mongo-globallock-current-queue-high-lock-contention-01"]

## check_id: chk-locks-avg-acquire-wait-micros

- **type**: metric
- **metric_name**: locks.avg_acquire_wait_micros
- **collection_layer**: mongo-shell
- **collection_method**: (NULL · 原文给指标名未给字面命令)
- **abnormal_patterns**: ["\"locks.timeAcquiringMicros除以locks.acquireWaitCount能计算出特定锁模式的平均等待时间。\""]
- **linked_case_ids**: ["mongo-globallock-current-queue-high-lock-contention-01"]

## check_id: chk-explain-executiontimemillis-per-page

- **type**: metric
- **metric_name**: explain.executionTimeMillis_per_page
- **collection_layer**: mongo-shell
- **collection_method**: "db.test.find({org:\"10000\", signT:{$gte:new Date(1590940800000), $lte: new Date(1591027199999)},signStatus:{$in:[0,1]} }).sort({no:1}).skip(50).limit(50).explain(\"executionStats\")"
- **abnormal_patterns**: ["{\"page2_ms\": 29, \"page10_ms\": 1001, \"page100_ms\": 12830}"]
- **linked_case_ids**: ["mongo-pagination-skip-deep-page-rewrite-02"]

## check_id: chk-disk-io-util

- **type**: metric
- **metric_name**: disk_io_util
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给字面 iostat 命令)
- **abnormal_patterns**: ["{\"disk_util_pct_low\": 0, \"disk_util_pct_high\": 100}"]
- **linked_case_ids**: ["mongo-wt-checkpoint-period-tuning-disk-io-spike-02"]

## check_id: chk-mongostat-qrw-arw-or-slow-log-count

- **type**: metric
- **metric_name**: mongostat.qrw_arw_or_slow_log_count
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文该 case 节未给字面采集命令(同篇问答 18 给的是另案命令))
- **abnormal_patterns**: ["\"该优化后system.sessions表更新引起的瞬间性能数倍降低和大量慢日志问题得到了解决。\""]
- **linked_case_ids**: ["mongo-system-sessions-update-storm-primary-shard-degradation-03"]

## check_id: chk-mongod-log-collscan-count

- **type**: metric
- **metric_name**: mongod.log.COLLSCAN_count
- **collection_layer**: log-grep
- **collection_method**: 
- **abnormal_patterns**: ["\"找出文件末尾1000000行中存在扫表的操作，不包含oplog，getMore\""]
- **linked_case_ids**: ["mongo-slow-log-currentop-long-query-kill-02"]

## check_id: chk-mongod-log-slow-query-1-10s

- **type**: metric
- **metric_name**: mongod.log.slow_query_1_10s
- **collection_layer**: log-grep
- **collection_method**: 
- **abnormal_patterns**: ["{\"window_ms_low\": 1000, \"window_ms_high\": 10000}"]
- **linked_case_ids**: ["mongo-slow-log-currentop-long-query-kill-02"]

## check_id: chk-currentop-secs-running

- **type**: metric
- **metric_name**: currentOp.secs_running
- **collection_layer**: mongo-shell
- **collection_method**: "db.currentOp({“secs_running”:{“$gt”:5}})"
- **abnormal_patterns**: ["{\"secs_running_gt_seconds\": 5}"]
- **linked_case_ids**: ["mongo-slow-log-currentop-long-query-kill-02"]

## check_id: chk-wiredtiger-cache-bytes-currently-in-the-cache-wiredtiger-cac

- **type**: metric
- **metric_name**: wiredTiger.cache.bytes currently in the cache / wiredTiger.cache.maximum bytes configured
- **collection_layer**: mongo-internal-counter
- **collection_method**: "The effectiveness of the chosen cache size can be measured by reviewing the page eviction statistics for the database"
- **abnormal_patterns**: ["bytes_in_cache / maximum_bytes 持续 ≈ 0.95"]
- **linked_case_ids**: ["wt-eviction-trigger-app-thread-throttle-01"]

## check_id: chk-wiredtiger-cache-eviction-worker-thread-evicting-pages-appli

- **type**: metric
- **metric_name**: wiredTiger.cache.eviction worker thread evicting pages / application thread time evicting
- **collection_layer**: mongo-internal-counter
- **collection_method**: "Operations will stall when the cache reaches 100% of the cache size"
- **abnormal_patterns**: ["application thread evicting time per sec 显著 > 0"]
- **linked_case_ids**: ["wt-eviction-trigger-app-thread-throttle-01"]

## check_id: chk-flamegraph-snappy-cpu-pct

- **type**: metric
- **metric_name**: flamegraph.snappy.cpu_pct
- **collection_layer**: flamegraph
- **collection_method**: (NULL · 原文未给采集命令)
- **abnormal_patterns**: ["snappy_*函数 CPU 占比 > 10% on flamegraph (qualitative)"]
- **linked_case_ids**: ["mongo-snappy-hotspot-cpu-high-arm64-01"]

## check_id: chk-application-thread-concurrency-setting-business-tps

- **type**: metric
- **metric_name**: application thread concurrency setting + business TPS
- **collection_layer**: mongo-shell
- **collection_method**: (NULL · 原文未给出"如何采集当前并发数"命令)
- **abnormal_patterns**: ["(定性) thread_count > optimal_concurrency_for_workload ∧ TPS 单调下降"]
- **linked_case_ids**: ["app-thread-concurrency-mismatch-01"]

## check_id: chk-application-linked-memory-allocator-library

- **type**: metric
- **metric_name**: application linked memory allocator library
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给"如何检查当前 allocator"命令)
- **abnormal_patterns**: ["当前 allocator ∈ {glibc-malloc, tcmalloc} ∧ 业务为多线程高分配率"]
- **linked_case_ids**: ["app-malloc-jemalloc-multithread-audit-01"]

## check_id: chk-aggregation-pipeline-duration

- **type**: metric
- **metric_name**: aggregation_pipeline_duration
- **collection_layer**: mongo-shell
- **collection_method**: "// BEFORE: Unoptimized pipeline (8.2s)\ndb.orders.aggregate([\n  { $lookup: { from: \"products\", ... } },\n  { $unwind: \"$items\" },\n  { $match: { sellerId: ObjectId(\"...\"), status: \"completed\" } },\n  { $group: { _id: \"$items.category\", revenue: { $sum: \"$total\" } } }\n])"
- **abnormal_patterns**: ["{\"before_seconds\": 8.2, \"before_doc_count\": 80000000}"]
- **linked_case_ids**: ["mongo-aggregation-unbounded-pipeline-no-early-match-01"]

## check_id: chk-lookup-pipeline-stage

- **type**: metric
- **metric_name**: 慢查询中 $lookup pipeline stage 出现频率
- **collection_layer**: atlas-advisor / mongo-runtime-cmd
- **collection_method**: "The Performance Advisor monitors slow queries to recognize certain schema issues, namely too many $lookup operations and not utilizing an index for case-sensitive regex queries."
- **abnormal_patterns**: ["(Atlas 内部启发式 · 自管理部署可统计 system.profile 中 $lookup 占比)"]
- **linked_case_ids**: ["mongo-schema-too-many-lookups-should-embed-01"]

## check_id: chk-indexstats-accesses-ops

- **type**: metric
- **metric_name**: $indexStats accesses.ops · 每索引使用次数
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (Atlas 文档未给具体命令 · 自管理标准做法 `db.coll.aggregate([{$indexStats:{}}])`)
- **abnormal_patterns**: ["索引 accesses.ops 长期为 0 / 极低"]
- **linked_case_ids**: ["mongo-schema-unused-indexes-bloat-03"]

## check_id: chk-collstats-avgobjsize-p99

- **type**: metric
- **metric_name**: collStats.avgObjSize / 文档大小 P99
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "The Performance Advisor analyzes the 20 most active collections based on the output of the top command."
- **abnormal_patterns**: ["avgObjSize 显著大(原文未给数字 · 经验值 > 1MB 即应警惕)"]
- **linked_case_ids**: ["mongo-schema-document-too-large-04"]

## check_id: chk-atlas-query-targeting-scanned-returned-scanned-objects-retur

- **type**: metric
- **metric_name**: Atlas Query Targeting: Scanned/Returned & Scanned Objects/Returned
- **collection_layer**: atlas-advisor
- **collection_method**: (NULL · 原文为 Atlas UI 操作而非命令)
- **abnormal_patterns**: ["{\"scanned_objects_to_returned\": \">= 1000:1 (default)\", \"scanned_index_keys_to_returned\": \"user-defined\"}"]
- **linked_case_ids**: ["mongo-query-targeting-high-scan-ratio-01"]

## check_id: chk-mongod-slow-query-log-plansummary-keysexamined-docsexamined-

- **type**: metric
- **metric_name**: mongod slow query log: planSummary / keysExamined / docsExamined / nreturned
- **collection_layer**: log-grep
- **collection_method**: (NULL · 原文给的是日志样例而非采集命令)
- **abnormal_patterns**: ["{\"planSummary\": \"COLLSCAN\", \"keysExamined\": 0, \"docsExamined_to_nreturned_ratio_observed\": 2500}"]
- **linked_case_ids**: ["mongo-query-targeting-high-scan-ratio-01"]

## check_id: chk-explain-executionstats

- **type**: metric
- **metric_name**: explain.executionStats
- **collection_layer**: mongo-shell
- **collection_method**: "The cursor.explain()\ncommand for mongosh provides performance details for\nall queries."
- **abnormal_patterns**: ["{\"docsExamined\": 10000, \"nreturned\": 4, \"ratio\": 2500}"]
- **linked_case_ids**: ["mongo-query-targeting-high-scan-ratio-01"]

## check_id: chk-operation-execution-time-ms-plansummary

- **type**: metric
- **metric_name**: Operation Execution Time (ms) + planSummary
- **collection_layer**: atlas-advisor
- **collection_method**: (NULL · 原文是 Atlas UI 操作)
- **abnormal_patterns**: ["{\"planSummary\": \"COLLSCAN\", \"operation_execution_time_ms\": \"consistently high\"}"]
- **linked_case_ids**: ["mongo-slow-query-profiler-metric-01"]

## check_id: chk-docsexamined-keysexamined-docs-examined-returned-ratio

- **type**: metric
- **metric_name**: docsExamined / keysExamined / Docs Examined : Returned Ratio
- **collection_layer**: atlas-advisor
- **collection_method**: (NULL · 原文是 Atlas UI 字段)
- **abnormal_patterns**: ["{\"keysExamined_with_filter\": 0, \"docsExamined_to_docsReturned\": \">> 1 (high)\"}"]
- **linked_case_ids**: ["mongo-slow-query-profiler-metric-01"]

## check_id: chk-numyields-usedindex-hassort

- **type**: metric
- **metric_name**: numYields / usedIndex / hasSort
- **collection_layer**: atlas-advisor
- **collection_method**: (NULL · 原文是 Atlas UI 字段)
- **abnormal_patterns**: ["{\"numYields\": \"frequent\", \"usedIndex\": false, \"hasSort_unindexed\": true}"]
- **linked_case_ids**: ["mongo-slow-query-profiler-metric-01"]

## check_id: chk-globallock-totaltime-uptime

- **type**: metric
- **metric_name**: globalLock.totalTime / uptime
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "globalLock section of the"
- **abnormal_patterns**: ["totalTime / uptime ≫ 等同业务持续在 lock 状态"]
- **linked_case_ids**: ["mongo-locking-queue-buildup-01"]

## check_id: chk-locks-type-deadlockcount-locks-type-timeacquiringmicros-acqu

- **type**: metric
- **metric_name**: locks.<type>.deadlockCount + locks.<type>.timeAcquiringMicros / acquireWaitCount
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "Dividing locks.<type>.timeAcquiringMicros by locks.<type>.acquireWaitCount can give an approximate average wait time for a particular lock mode."
- **abnormal_patterns**: ["平均等锁时间(微秒)偏离基线 ≫ 1× 或 deadlockCount > 0"]
- **linked_case_ids**: ["mongo-locking-queue-buildup-01"]

## check_id: chk-connections-current-connections-available

- **type**: metric
- **metric_name**: connections.current / connections.available
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "The following fields in the serverStatus document can provide insight"
- **abnormal_patterns**: ["connections.current 接近 maxIncomingConnections;available → 0"]
- **linked_case_ids**: ["mongo-connection-storm-driver-error-02"]

## check_id: chk-connections-current-vs-workload-opcounters

- **type**: metric
- **metric_name**: connections.current vs workload (opcounters)
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "the total number of current clients connected to the database instance."
- **abnormal_patterns**: ["connections.current 高 但 opcounters 平稳 → 驱动 / 配置异常"]
- **linked_case_ids**: ["mongo-connection-storm-driver-error-02"]

## check_id: chk-wiredtiger-concurrenttransactions-read-write-available-out-t

- **type**: metric
- **metric_name**: wiredTiger.concurrentTransactions.{read,write}.{available,out,totalTickets}
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "You can use the serverStatus command to check the current number of read and write tickets and their usage"
- **abnormal_patterns**: ["available 持续 < 128(7.0+ 动态阈值;6.x 默认 128)"]
- **linked_case_ids**: ["mongo-wt-tickets-exhausted-01"]

## check_id: chk-queues-execution-read-queues-execution-write

- **type**: metric
- **metric_name**: queues.execution.read / queues.execution.write
- **collection_layer**: mongo-internal-counter
- **collection_method**: "Look at the queues.execution section to understand the current load and ticket availability"
- **abnormal_patterns**: ["queues.execution.read 或 .write > 0 持续"]
- **linked_case_ids**: ["mongo-wt-tickets-exhausted-01"]

## check_id: chk-replsetgetstatus-members-optimedate-oplog-window

- **type**: metric
- **metric_name**: replSetGetStatus.members[].optimeDate / oplog window
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "you can examine the oplog-related metrics"
- **abnormal_patterns**: ["secondary optimeDate 落后 primary > SLA(原文未给具体阈值)"]
- **linked_case_ids**: ["mongo-replication-lag-multi-cause-02"]

## check_id: chk-metrics-cursor-open-total-opcounters-query-getmore

- **type**: metric
- **metric_name**: metrics.cursor.open.total / opcounters.{query,getmore}
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未直接给采集命令)
- **abnormal_patterns**: ["metrics.cursor.open.total 增速 ≫ opcounters 增速"]
- **linked_case_ids**: ["mongo-open-cursor-rising-no-traffic-03"]

## check_id: chk-metrics-operation-scanandorder

- **type**: metric
- **metric_name**: metrics.operation.scanAndOrder
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给逐字采集命令)
- **abnormal_patterns**: ["scanAndOrder 计数(累计或每秒) >= 20"]
- **linked_case_ids**: ["mongo-scan-and-order-high-04"]

## check_id: chk-system-profile-slow-query-log-collstats-avgobjsize

- **type**: metric
- **metric_name**: system.profile / slow query log + collStats.avgObjSize 趋势
- **collection_layer**: log-grep
- **collection_method**: "The query plan does not contain any metrics to reveal document structure antipatterns, but you can look for antipatterns when debugging slow queries."
- **abnormal_patterns**: ["collStats.avgObjSize 单调增长 + 同一 array $push 慢查询反复出现"]
- **linked_case_ids**: ["mongo-unbound-array-rewrite-pressure-05"]

## check_id: chk-driver-maxpoolsize

- **type**: metric
- **metric_name**: driver maxPoolSize · 应用层典型并发请求数
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#mongo-pool-maxpoolsize-readout-from-driver-knowledge)
- **abnormal_patterns**: ["maxPoolSize < 1.10 × 应用层典型并发请求数"]
- **linked_case_ids**: ["mongo-driver-pool-size-too-small-vs-concurrent-requests-02"]

## check_id: chk-dbpath

- **type**: metric
- **metric_name**: dbPath 挂载点文件系统类型
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#mongo-fs-mount-readout-from-shell-knowledge)
- **abnormal_patterns**: ["文件系统类型 ∈ {nfs, nfs4}","文件系统 = ext4 且 storage engine = wiredTiger"]
- **linked_case_ids**: ["mongo-fs-nfs-dbpath-degraded-unstable-perf-01","mongo-fs-ext4-wiredtiger-perf-issue-should-use-xfs-02"]

## check_id: chk-tuned-adm-active-profile

- **type**: metric
- **metric_name**: tuned-adm active 当前 profile 名
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#linux-tuned-profile-readout-from-linux-doc)
- **abnormal_patterns**: ["active profile ∈ 出厂默认 {throughput-performance, balanced, virtual-guest, ...} 且未做 MongoDB 适配"]
- **linked_case_ids**: ["mongo-tuned-profile-default-rhel-perf-impact-05"]

## check_id: chk-net-ipv4-tcp-keepalive-time

- **type**: metric
- **metric_name**: net.ipv4.tcp_keepalive_time
- **collection_layer**: os
- **collection_method**: "sysctl net.ipv4.tcp_keepalive_time"
- **abnormal_patterns**: ["当前值 > 云 LB 空闲超时(常见 60-120 秒)"]
- **linked_case_ids**: ["mongo-network-tcp-keepalive-too-long-cloud-lb-drops-02"]

## check_id: chk-mongod-startup-log-numa-warning

- **type**: metric
- **metric_name**: mongod startup log · NUMA warning 行
- **collection_layer**: log-grep
- **collection_method**: "MongoDB checks NUMA settings on start up when deployed on Linux (since version 2.0) and Windows (since version 2.6) machines. If the NUMA configuration may degrade performance, MongoDB prints a warning."
- **abnormal_patterns**: ["mongod 启动日志含 \"NUMA\" warning"]
- **linked_case_ids**: ["mongo-numa-cross-node-memory-degradation-04"]

## check_id: chk-numad

- **type**: metric
- **metric_name**: numad 进程
- **collection_layer**: os
- **collection_method**: (通用 `pgrep -f numad`)
- **abnormal_patterns**: ["numad 进程在跑"]
- **linked_case_ids**: ["mongo-numa-cross-node-memory-degradation-04"]

## check_id: chk-vm-swappiness

- **type**: metric
- **metric_name**: vm.swappiness
- **collection_layer**: os
- **collection_method**: (通用 `cat /proc/sys/vm/swappiness` 或 `sysctl vm.swappiness`)
- **abnormal_patterns**: ["当前值 > 1"]
- **linked_case_ids**: ["mongo-os-vm-swappiness-default-60-aggressive-swap-05"]

## check_id: chk-ec2-instance-type-enhanced-networking-ebs-provisioned-iops

- **type**: metric
- **metric_name**: EC2 instance type / Enhanced Networking 状态 / EBS provisioned IOPS
- **collection_layer**: os
- **collection_method**: (原文未给读取命令 · AWS 侧通用 `aws ec2 describe-instances` 或 `cat /sys/class/net/<eth>/queues/`)
- **abnormal_patterns**: ["Enhanced Networking 未启用 / 用 ephemeral SSD 而非 provisioned IOPS"]
- **linked_case_ids**: ["mongo-aws-ec2-storage-network-tuning-06"]

## check_id: chk-tcmalloc-usingpercpucaches-tcmalloc-tcmalloc-cpu-free

- **type**: metric
- **metric_name**: tcmalloc.usingPerCPUCaches / tcmalloc.tcmalloc.cpu_free
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "To verify that TCMalloc is running with per-CPU caches, ensure that"
- **abnormal_patterns**: ["usingPerCPUCaches != true 或 cpu_free <= 0"]
- **linked_case_ids**: ["mongo-tcmalloc-percpu-caches-not-enabled-01"]

## check_id: chk-glibc-pthread-rseq-tunable-glibc-tunables-env

- **type**: metric
- **metric_name**: glibc.pthread.rseq tunable / GLIBC_TUNABLES env
- **collection_layer**: os
- **collection_method**: (NULL · 原文给的是 mitigation env 设置,未给只读检查命令)
- **abnormal_patterns**: ["glibc rseq 已注册而 TCMalloc 启动时拿不到"]
- **linked_case_ids**: ["mongo-tcmalloc-percpu-caches-not-enabled-01"]

## check_id: chk-kernel-version

- **type**: metric
- **metric_name**: kernel version
- **collection_layer**: os
- **collection_method**: "uname -r"
- **abnormal_patterns**: ["uname -r 主版本 < 4.18"]
- **linked_case_ids**: ["mongo-tcmalloc-percpu-caches-not-enabled-01"]

## check_id: chk-replsetgetstatus-members-statestr-primary-secondary-arbiter

- **type**: metric
- **metric_name**: replSetGetStatus.members[] 的 stateStr 分布(PRIMARY/SECONDARY/ARBITER)
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给读取拓扑命令 · 见 reference/_pending/agent2.md#mongo-replset-status-readout-from-mongo-doc)
- **abnormal_patterns**: ["拓扑 = 1 PRIMARY + 1 SECONDARY + 1 ARBITER(只有 1 个 data-bearing secondary)"]
- **linked_case_ids**: ["mongo-psa-majority-writeconcern-perf-degradation-01"]

## check_id: chk-secondary-health-state-optimedate-primary

- **type**: metric
- **metric_name**: secondary 的 health/state · optimeDate 与 primary 的差距
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给具体命令 · 见 reference/_pending/agent2.md#mongo-replset-secondary-health-readout-from-mongo-doc)
- **abnormal_patterns**: ["secondary state ≠ SECONDARY · 或 lag (primary.optimeDate − secondary.optimeDate) 显著 > 0"]
- **linked_case_ids**: ["mongo-psa-majority-writeconcern-perf-degradation-01"]

## check_id: chk-getdefaultrwconcern-defaultwriteconcern-w

- **type**: metric
- **metric_name**: getDefaultRWConcern → defaultWriteConcern.w
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给具体命令 · 见 reference/_pending/agent2.md#mongo-default-rwconcern-readout-from-mongo-doc)
- **abnormal_patterns**: ["default write concern w < majority(== 2 in PSA) → 风险:stale read;w == majority → 风险:secondary 异常时写卡"]
- **linked_case_ids**: ["mongo-psa-majority-writeconcern-perf-degradation-01"]

## check_id: chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct

- **type**: metric
- **metric_name**: storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给具体读取命令)
- **abnormal_patterns**: ["cacheSizeGB > 默认 50%(RAM - 1GB);或 cacheSizePct > 80%"]
- **linked_case_ids**: ["mongo-wt-cache-size-misconfigured-01"]

## check_id: chk-explain-queryplanner-winningplan-sort-stage

- **type**: metric
- **metric_name**: explain.queryPlanner.winningPlan SORT stage 是否存在
- **collection_layer**: mongo-shell
- **collection_method**: "If the explain plan does not contain an explicit"
- **abnormal_patterns**: ["winningPlan 树中存在 stage='SORT' 节点(意味没用 index 排序)"]
- **linked_case_ids**: ["mongo-explain-sort-stage-disk-spill-01"]

## check_id: chk-sort-useddisk-sort-spills-sort-spilledbytes-sort-spilledreco

- **type**: metric
- **metric_name**: $sort.usedDisk / $sort.spills / $sort.spilledBytes / $sort.spilledRecords / $sort.spilledDataStorageSize
- **collection_layer**: mongo-shell
- **collection_method**: "Whether the stage wrote to disk"
- **abnormal_patterns**: ["usedDisk == true · spills > 0 · spilledBytes > 0"]
- **linked_case_ids**: ["mongo-explain-sort-stage-disk-spill-01"]

## check_id: chk-driver-connecttimeoutms-vs

- **type**: metric
- **metric_name**: driver connectTimeoutMS 当前值 vs 副本集成员最长网络延迟
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文是建议而非读取命令 · 见 reference/_pending/agent2.md#mongo-pool-connecttimeoutms-readout-from-driver-knowledge)
- **abnormal_patterns**: ["connectTimeoutMS 小于到副本集任一成员的网络延迟"]
- **linked_case_ids**: ["mongo-pool-connect-timeout-too-large-01"]

## check_id: chk-driver-sockettimeoutms-vs

- **type**: metric
- **metric_name**: driver socketTimeoutMS 当前值 vs 应用最慢合法操作耗时
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文是建议而非读取命令 · 见 reference/_pending/agent2.md#mongo-pool-sockettimeoutms-readout-from-driver-knowledge)
- **abnormal_patterns**: ["socketTimeoutMS 未设 / 设过大,导致 driver 持有半关连接长时间挂死"]
- **linked_case_ids**: ["mongo-pool-socket-timeout-firewall-half-close-02"]

## check_id: chk-driver-minpoolsize-real-time-connection

- **type**: metric
- **metric_name**: driver minPoolSize · 服务器日志 / real time 面板 connection 创建速率
- **collection_layer**: log-grep
- **collection_method**: (NULL · 原文未给具体读取命令,仅说"server logs or real time panel show" · 见 reference/_pending/agent2.md#mongo-pool-conn-create-rate-readout-shell-knowledge)
- **abnormal_patterns**: ["minPoolSize 远小于启动期峰值并发(导致大量临时建连)"]
- **linked_case_ids**: ["mongo-pool-minpoolsize-too-low-startup-creating-conns-03"]

## check_id: chk-driver-maxpoolsize

- **type**: metric
- **metric_name**: driver maxPoolSize · 应用活跃线程数 / 实际每秒操作数
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给读取命令,实际需读 driver 配置 + 应用线程池配置 · 见 reference/_pending/agent2.md#mongo-pool-maxpoolsize-readout-from-driver-knowledge)
- **abnormal_patterns**: ["maxPoolSize 接近活跃线程数;DB 资源未饱和但吞吐受限"]
- **linked_case_ids**: ["mongo-pool-maxpoolsize-too-low-underutilized-04"]

## check_id: chk-driver-maxpoolsize-cpu-connection-accept-rate

- **type**: metric
- **metric_name**: driver maxPoolSize · 服务端 CPU% · connection accept rate
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#mongo-pool-server-cpu-readout-from-shell-knowledge)
- **abnormal_patterns**: ["服务端 CPU 持续高位 + 连接尝试速率显著上升"]
- **linked_case_ids**: ["mongo-pool-maxpoolsize-too-high-cpu-pressure-05"]

## check_id: chk-explain-executionstats-executiontimemillis

- **type**: metric
- **metric_name**: explain.executionStats.executionTimeMillis
- **collection_layer**: mongo-shell
- **collection_method**: "to see the execution time in milliseconds"
- **abnormal_patterns**: ["单条 query executionTimeMillis > 业务 SLA 上限(原文未给数值)"]
- **linked_case_ids**: ["mongo-slow-query-explain-multi-stage-01"]

## check_id: chk-explain-executionstats-executionstages-inputstage-stage

- **type**: metric
- **metric_name**: explain.executionStats.executionStages.inputStage.stage
- **collection_layer**: mongo-shell
- **collection_method**: "for each execution stage"
- **abnormal_patterns**: ["inputStage.stage == COLLSCAN(应是 IXSCAN)"]
- **linked_case_ids**: ["mongo-slow-query-explain-multi-stage-01"]

## check_id: chk-executionstats-totalkeysexamined-executionstats-totaldocsexa

- **type**: metric
- **metric_name**: executionStats.totalKeysExamined / executionStats.totalDocsExamined
- **collection_layer**: mongo-shell
- **collection_method**: "Compare the number of keys examined to the number of documents examined. If the number of keys is significantly less than the number of documents, it indicates the indexes were ineffective"
- **abnormal_patterns**: ["totalKeysExamined ≪ totalDocsExamined → 索引未生效"]
- **linked_case_ids**: ["mongo-slow-query-explain-multi-stage-01"]

## check_id: chk-executionstats-totaldocsexamined-executionstats-nreturned

- **type**: metric
- **metric_name**: executionStats.totalDocsExamined / executionStats.nReturned
- **collection_layer**: mongo-shell
- **collection_method**: "Queries that use filters to specify the results may have issues"
- **abnormal_patterns**: ["totalDocsExamined / nReturned ≫ 1 → 过滤效率差","totalDocsExamined / nReturned ≫ 1(原文示例 ≈ 5×)"]
- **linked_case_ids**: ["mongo-slow-query-explain-multi-stage-01","mongo-query-ixscan-poor-selectivity-extra-sort-02"]

## check_id: chk-profile-slowms-profile-samplerate-profile-was

- **type**: metric
- **metric_name**: profile.slowms / profile.sampleRate / profile.was
- **collection_layer**: mongo-shell
- **collection_method**: "db.getProfilingStatus()"
- **abnormal_patterns**: ["slowms != 业务期望(默认 100ms);sampleRate < 1.0 但又依赖完整慢日志"]
- **linked_case_ids**: ["mongo-profiler-threshold-sampling-audit-01"]

## check_id: chk-sys-kernel-mm-transparent-hugepage-enabled-defrag-khugepaged

- **type**: metric
- **metric_name**: /sys/kernel/mm/transparent_hugepage/{enabled,defrag,khugepaged/defrag}
- **collection_layer**: os
- **collection_method**: "cat /sys/kernel/mm/transparent_hugepage/enabled && cat /sys/kernel/mm/transparent_hugepage/defrag && cat /sys/kernel/mm/transparent_hugepage/khugepaged"
- **abnormal_patterns**: ["enabled 当前值不是 `always"]
- **linked_case_ids**: ["mongo-8x-thp-disabled-tcmalloc-suboptimal-01"]

## check_id: chk-syncedto-time-per-secondary

- **type**: metric
- **metric_name**: syncedTo time per secondary
- **collection_layer**: mongo-shell
- **collection_method**: `rs.printSecondaryReplicationInfo()`
- **abnormal_patterns**: ["落后秒数显著大于 0;持续增长更可疑"]
- **linked_case_ids**: ["mongo-replica-set-replication-lag-01"]

## check_id: chk-flowcontrol-islagged

- **type**: metric
- **metric_name**: flowControl.isLagged
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: `db.runCommand( { serverStatus: 1 } ).flowControl.isLagged`
- **abnormal_patterns**: ["flowControl.isLagged === true` 表示已触发流控,主在限速等待 secondary"]
- **linked_case_ids**: ["mongo-replica-set-replication-lag-01"]

## check_id: chk-replication-lag-seconds

- **type**: metric
- **metric_name**: Replication Lag (seconds)
- **collection_layer**: atlas-advisor
- **collection_method**: "View the following charts to monitor your progress"
- **abnormal_patterns**: ["{\"replication_lag_persistent_seconds\": \">= 120\"}"]
- **linked_case_ids**: ["mongo-replica-lag-secondary-behind-primary-01"]

## check_id: chk-replication-headroom

- **type**: metric
- **metric_name**: Replication Headroom
- **collection_layer**: atlas-advisor
- **collection_method**: "Monitor replication headroom to determine whether the secondary might fall off the oplog."
- **abnormal_patterns**: ["(NULL)"]
- **linked_case_ids**: ["mongo-replica-lag-secondary-behind-primary-01"]

## check_id: chk-network-metrics

- **type**: metric
- **metric_name**: Network metrics
- **collection_layer**: atlas-advisor
- **collection_method**: "Monitor network metrics to track network performance."
- **abnormal_patterns**: ["(NULL)"]
- **linked_case_ids**: ["mongo-replica-lag-secondary-behind-primary-01"]

## check_id: chk-mongod-slow-log-workingmillis

- **type**: metric
- **metric_name**: mongod_slow_log.workingMillis
- **collection_layer**: log-grep
- **collection_method**: (NULL · 原文未给读取慢日志的字面命令)
- **abnormal_patterns**: ["{\"example_workingMillis\": 120, \"example_durationMillis\": 300, \"example_totalTimeQueuedMicros\": 180000}"]
- **linked_case_ids**: ["mongo-slow-log-queue-wait-vs-working-time-mongodb8-01"]

## check_id: chk-workingmillis-vs-totaltimequeuedmicros

- **type**: metric
- **metric_name**: workingMillis_vs_totalTimeQueuedMicros
- **collection_layer**: log-grep
- **collection_method**: (NULL · 原文未给字面比较命令)
- **abnormal_patterns**: ["\"High workingMillis, Low totalTimeQueuedMicrosDiagnosis: The query is expensive "]
- **linked_case_ids**: ["mongo-slow-log-queue-wait-vs-working-time-mongodb8-01"]

## check_id: chk-mongod-resident-memory

- **type**: metric
- **metric_name**: mongod_resident_memory
- **collection_layer**: os
- **collection_method**: "top - 19:14:57 up 80 days,  6:05,  5 users,  load average: 0.93, 0.89, 0.99"
- **abnormal_patterns**: ["{\"VIRT_GB\": 73.6, \"RES_GB\": 65.5, \"RAM_total_GiB\": 123}"]
- **linked_case_ids**: ["mongo-plancache-bloat-sbe-7-0-oom-kills-01"]

## check_id: chk-heap-profile-alloc-hotspots

- **type**: metric
- **metric_name**: heap_profile_alloc_hotspots
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文未给具体启用命令字面)
- **abnormal_patterns**: ["\"There was a high number of memory allocation logs for the query planner.\""]
- **linked_case_ids**: ["mongo-plancache-bloat-sbe-7-0-oom-kills-01"]

## check_id: chk-queryhash-uniqueness-per-shape

- **type**: metric
- **metric_name**: queryHash_uniqueness_per_shape
- **collection_layer**: log-grep
- **collection_method**: 
- **abnormal_patterns**: ["\"For the query below, the queryHash and planCacheKey values were changing with e"]
- **linked_case_ids**: ["mongo-plancache-bloat-sbe-7-0-oom-kills-01"]

## check_id: chk-plancache-entries-count

- **type**: metric
- **metric_name**: planCache.entries_count
- **collection_layer**: mongo-shell
- **collection_method**: "db.test.getPlanCache().list().length"
- **abnormal_patterns**: ["{\"plan_cache_entries\": 52891}"]
- **linked_case_ids**: ["mongo-plancache-bloat-sbe-7-0-oom-kills-01"]

## check_id: chk-queryframework-per-version

- **type**: metric
- **metric_name**: queryFramework_per_version
- **collection_layer**: log-grep
- **collection_method**: (NULL · 原文展示了 3 版本的日志样例但未给比对命令)
- **abnormal_patterns**: ["{\"affected_versions\": [\"7.0\"], \"fixed_in\": \"8.0\", \"jira\": \"SERVER-96924\"}"]
- **linked_case_ids**: ["mongo-plancache-bloat-sbe-7-0-oom-kills-01"]

## check_id: chk-sh-getbalancerstate

- **type**: metric
- **metric_name**: sh.getBalancerState()
- **collection_layer**: mongo-shell
- **collection_method**: "mongos> sh.getBalancerState()"
- **abnormal_patterns**: ["返回 false 即异常(本 case 期望 true 才能继续)"]
- **linked_case_ids**: ["mongo-sharding-jumbo-chunk-uneven-write-load-01"]

## check_id: chk-sh-status-verbose-jumbo-flag

- **type**: metric
- **metric_name**: sh.status verbose 输出中的 jumbo flag
- **collection_layer**: mongo-shell
- **collection_method**: "sh.status(true)"
- **abnormal_patterns**: ["sh.status 输出中含 `jumbo` 标记的 chunk 行"]
- **linked_case_ids**: ["mongo-sharding-jumbo-chunk-uneven-write-load-01"]

## check_id: chk-config-chunks-jumbo-true

- **type**: metric
- **metric_name**: config.chunks { jumbo: true }
- **collection_layer**: mongo-shell
- **collection_method**: "mongos> db.chunks.find({\"shard\" : \"shard0000\"},{\"shard\":1,\"jumbo\":1}).pretty()"
- **abnormal_patterns**: ["返回包含 `\"jumbo\" : true` 的文档"]
- **linked_case_ids**: ["mongo-sharding-jumbo-chunk-uneven-write-load-01"]

## check_id: chk-getsharddistribution-per-shard-data-docs-chunks

- **type**: metric
- **metric_name**: getShardDistribution: per-shard data / docs / chunks
- **collection_layer**: mongo-shell
- **collection_method**: "mongos> db.col.getShardDistribution()"
- **abnormal_patterns**: ["单 shard 占 100% 数据 / 100% docs;其他 shard 0%"]
- **linked_case_ids**: ["mongo-sharding-equal-chunks-skewed-data-getshard-distribution-02"]

## check_id: chk-hostinfo-system-memsizemb-memlimitmb

- **type**: metric
- **metric_name**: hostInfo.system.memSizeMB / memLimitMB
- **collection_layer**: mongo-shell
- **collection_method**: "rs0:PRIMARY> db.hostInfo()"
- **abnormal_patterns**: ["memSizeMB ≫ memLimitMB(本例 15006 vs 476)"]
- **linked_case_ids**: ["mongo-k8s-container-wt-cache-fallback-256mb-01"]

## check_id: chk-wiredtiger-cache-maximum-bytes-configured

- **type**: metric
- **metric_name**: wiredTiger.cache."maximum bytes configured"
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "rs0:PRIMARY> db.serverStatus().wiredTiger.cache[\"maximum bytes configured\"]/1024/1024"
- **abnormal_patterns**: ["maximum_bytes_configured = 256MB(回退到最小值)"]
- **linked_case_ids**: ["mongo-k8s-container-wt-cache-fallback-256mb-01"]

## check_id: chk-operator-version-replsets-resources-limits-cpu

- **type**: metric
- **metric_name**: operator version + replsets.resources.limits.cpu
- **collection_layer**: os
- **collection_method**: "$ kubectl get pods"
- **abnormal_patterns**: ["operator ≤ v1.10 且 cr.yaml 中 cpu limit 缺失或为 0"]
- **linked_case_ids**: ["mongo-k8s-operator-cachesize-bug-cpu-limit-required-02"]

## check_id: chk-wiredtiger-cache-maximum-bytes-configured

- **type**: metric
- **metric_name**: wiredTiger.cache.maximum bytes configured
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "rs0:PRIMARY> db.serverStatus().wiredTiger.cache[\"maximum bytes configured\"]/1024/1024"
- **abnormal_patterns**: ["yaml cacheSizeRatio 已改但 mongod 实际 cache 与 ratio*memlimit 公式不匹配"]
- **linked_case_ids**: ["mongo-k8s-operator-cachesize-bug-cpu-limit-required-02"]

## check_id: chk-serverstatus-tcmalloc-usingpercpucaches

- **type**: metric
- **metric_name**: serverStatus.tcmalloc.usingPerCpuCaches
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文给的是判定值"is true / is greater than 0",未给具体读取命令)
- **abnormal_patterns**: ["usingPerCpuCaches != true → 异常(说明回退到 legacy per-thread 实现)"]
- **linked_case_ids**: ["mongo-8-0-tcmalloc-percpu-prerequisite-not-met-01"]

## check_id: chk-serverstatus-tcmalloc-tcmalloc-cpu-free

- **type**: metric
- **metric_name**: serverStatus.tcmalloc.tcmalloc.cpu_free
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文给的是判定值"is greater than 0",未给具体读取命令 · 同 ref)
- **abnormal_patterns**: ["cpu_free 不大于 0 → 异常(per-CPU 缓存未真正建立)"]
- **linked_case_ids**: ["mongo-8-0-tcmalloc-percpu-prerequisite-not-met-01"]

## check_id: chk-uname-r-kernel-version

- **type**: metric
- **metric_name**: uname -r kernel version
- **collection_layer**: os
- **collection_method**: (NULL · 原文未给具体读取命令)
- **abnormal_patterns**: ["内核版本 < 4.18"]
- **linked_case_ids**: ["mongo-8-0-tcmalloc-percpu-prerequisite-not-met-01"]

## check_id: chk-sys-kernel-mm-transparent-hugepage-enabled

- **type**: metric
- **metric_name**: /sys/kernel/mm/transparent_hugepage/enabled
- **collection_layer**: os
- **collection_method**: (NULL · 同 ref)
- **abnormal_patterns**: ["(MongoDB 8.0 视角)THP 当前为 `never` → 异常(与 7.0 时代相反!)"]
- **linked_case_ids**: ["mongo-8-0-tcmalloc-percpu-prerequisite-not-met-01"]

## check_id: chk-explain-queryplanner-winningplan-stage-sort

- **type**: metric
- **metric_name**: explain.queryPlanner.winningPlan.stage(子节点是否含 SORT)
- **collection_layer**: mongo-shell
- **collection_method**: "MongoDB > exp.find( {\"cuisine\" : {$ne : \"American \"}, ... \"grades.grade\" :\"A\", ... \"borough\": \"Brooklyn\"}).sort({\"name\":1})"
- **abnormal_patterns**: ["winningPlan 包含独立 \"stage\": \"SORT\" 节点(非索引天然有序)"]
- **linked_case_ids**: ["mongo-query-ixscan-poor-selectivity-extra-sort-02"]

## check_id: chk-flamegraph-cpu-stack-profile

- **type**: metric
- **metric_name**: flamegraph CPU stack profile
- **collection_layer**: flamegraph
- **collection_method**: "I collected a Flamegraph (see here-https://github.com/brendangregg/FlameGraph) to see where the CPU resources spend a huge amount of time."
- **abnormal_patterns**: ["flamegraph 中 JournalFlusher 函数占据显著比例(对照态:disabled writeConcernMajorityJournalDefault 后 1.52%)"]
- **linked_case_ids**: ["mongo-write-regression-default-writeconcern-majority-journal-01"]

## check_id: chk-getdefaultrwconcern-defaultwriteconcern

- **type**: metric
- **metric_name**: getDefaultRWConcern.defaultWriteConcern
- **collection_layer**: mongo-shell
- **collection_method**: (NULL · 原文给的是 setDefaultRWConcern 修改命令(写入),未给读取版本)
- **abnormal_patterns**: ["mongod 版本 ≥ 5.0 且 defaultWriteConcern.w = \"majority\" 且业务写延迟敏感"]
- **linked_case_ids**: ["mongo-write-regression-default-writeconcern-majority-journal-01"]

## check_id: chk-rs-conf-writeconcernmajorityjournaldefault

- **type**: metric
- **metric_name**: rs.conf().writeConcernMajorityJournalDefault
- **collection_layer**: mongo-shell
- **collection_method**: "rs.conf()"
- **abnormal_patterns**: ["writeConcernMajorityJournalDefault = true(默认) 且业务对写延迟敏感"]
- **linked_case_ids**: ["mongo-write-regression-default-writeconcern-majority-journal-01"]

## check_id: chk-wiredtiger-checkpoint-duration

- **type**: metric
- **metric_name**: wiredTiger checkpoint duration
- **collection_layer**: mongo-internal-counter
- **collection_method**: (NULL · 原文未给具体读取命令,仅说"Doing some research by looking at metrics" + 强调 PMM 趋势)
- **abnormal_patterns**: ["checkpoint 时长持续上升;原文期望 < 10s 视为合理"]
- **linked_case_ids**: ["mongo-wt-checkpoint-time-grows-bulk-load-stall-01"]

## check_id: chk-wiredtiger-cache-eviction-dirty-trigger-eviction-dirty-targe

- **type**: metric
- **metric_name**: wiredTiger.cache (eviction_dirty_trigger / eviction_dirty_target context)
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: (NULL · 原文段落给的是 setParameter 命令(写入,见 mitigation),未给读取阈值的命令)
- **abnormal_patterns**: ["dirty 页规模超出磁盘单次 checkpoint 可消化容量"]
- **linked_case_ids**: ["mongo-wt-checkpoint-time-grows-bulk-load-stall-01"]

## check_id: chk-dbe-perf-statement-cpu-time

- **type**: metric
- **metric_name**: dbe_perf.statement.cpu_time
- **collection_layer**: db-system-view
- **collection_method**: `select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_elapse_time/1000,2) as total_time,round(cpu_time/1000,2) as cup_time from dbe_perf.statement t where  n_calls>10 and avg_time>3  and user_name='root'  order by cpu_time desc limit 5;`
- **abnormal_patterns**: ["\"avg_time > 3ms\""]
- **linked_case_ids**: ["gaussdb-cpu-high-topsql-01"]

## check_id: chk-explain-analyze

- **type**: metric
- **metric_name**: explain analyze 执行计划分析
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain analyze SELECT c_id FROM bmsql_customer WHERE c_w_id = 1 AND c_d_id = 1 AND c_last = 'ABLEABLEABLE' ORDER BY c_first;`
- **abnormal_patterns**: ["\"结合SQL的执行计划，分析SQL性能的瓶颈点，再进行性能优化\""]
- **linked_case_ids**: ["gaussdb-cpu-high-topsql-01"]

## check_id: chk-gaussdb

- **type**: metric
- **metric_name**: GaussDB内置火焰图 · 时区加载线程占比
- **collection_layer**: flamegraph
- **collection_method**: "GaussDB在内核505版本中内置了火焰图工具，默认每5分钟会自动采集一次，保存在$GAUSSLOG/gs_flamegraph/{datanode}路径下，详细信息可参考GaussDB产品文档《内置perf工具》章节。"
- **abnormal_patterns**: ["> 40%"]
- **linked_case_ids**: ["gaussdb-cpu-high-connection-timezone-01"]

## check_id: chk-buffer-wdr

- **type**: metric
- **metric_name**: buffer命中率 (WDR报告或管控平台)
- **collection_layer**: db-system-view
- **collection_method**: "可以借助GaussDB的管控平台或者WDR报告。通常情况下，TP数据库的buffer命中率应该在99%以上。"
- **abnormal_patterns**: ["< 99%"]
- **linked_case_ids**: ["gaussdb-memory-shared-buffer-miss-01"]

## check_id: chk-explain-analyze

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE 算子落盘标志
- **collection_layer**: db-interactive-cmd
- **collection_method**: "为了优化性能，可以查看SQL的执行计划，如果算子存在落盘的情况，可适当调整work_mem参数值。"
- **abnormal_patterns**: ["\"如果算子存在落盘的情况\""]
- **linked_case_ids**: ["gaussdb-memory-work-mem-spill-01"]

## check_id: chk-dbe-perf-statement-cpu-time-cpu

- **type**: metric
- **metric_name**: dbe_perf.statement.cpu_time (持续CPU高)
- **collection_layer**: db-system-view
- **collection_method**: `dbe_perf.statement`：可查询分布式本CN发起的历史语句信息。`dbe_perf.summary_statement`：可查询分布式所有CN发起的历史语句信息。（对cpu_time字段进行逆序排序即可识别）
- **abnormal_patterns**: ["\"对cpu_time字段进行逆序排序即可识别\""]
- **linked_case_ids**: ["gaussdb-cpu-high-statement-view-01"]

## check_id: chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu

- **type**: metric
- **metric_name**: pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高)
- **collection_layer**: db-system-view
- **collection_method**: "查询pg_stat_activity 获取正在运行的SQL的query_id。使用上一步的query_id，查询pg_thread_wait_status 获取正在运行的SQL的lwtid。使用操作系统命令top -Hp <gaussdb进程号>，查看相应lwtid(PID)的CPU使用率。"
- **abnormal_patterns**: ["\"如果确实CPU占用较高，可能为目标SQL\""]
- **linked_case_ids**: ["gaussdb-cpu-high-statement-view-01"]

## check_id: chk-statement-history-cpu-time-vs-db-time

- **type**: metric
- **metric_name**: statement_history.cpu_time vs db_time
- **collection_layer**: db-system-view
- **collection_method**: "登录至各CN/DN节点查询相应时间段的statement_history 表。使用全局接口dbe_perf.get_global_full_sql_by_timestamp('开始时间','结束时间')。注意：需要切换至postgres库。"
- **abnormal_patterns**: ["\"通常如果说语句的CPU消耗较高，慢SQL语句的cpu_time和db_time差距就较小\""]
- **linked_case_ids**: ["gaussdb-cpu-high-statement-view-01"]

## check_id: chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io

- **type**: metric
- **metric_name**: dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高)
- **collection_layer**: db-system-view
- **collection_method**: "如果持续IO高，可查询dbe_perf.statement/dbe_perf.summary_statement内n_blocks_fetched/n_blocks_hit字段，通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。"
- **abnormal_patterns**: ["\"通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。\""]
- **linked_case_ids**: ["gaussdb-disk-io-high-statement-view-01"]

## check_id: chk-pg-thread-wait-status-wait-status-wait-event-io

- **type**: metric
- **metric_name**: pg_thread_wait_status.wait_status / wait_event (当前IO高)
- **collection_layer**: db-system-view
- **collection_method**: "如果当前IO高，可查询pg_thread_wait_status视图，查询wait_status/wait_event字段，通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。"
- **abnormal_patterns**: ["\"通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。\""]
- **linked_case_ids**: ["gaussdb-disk-io-high-statement-view-01"]

## check_id: chk-statement-history-data-io-time-sql-io

- **type**: metric
- **metric_name**: statement_history.data_io_time (慢SQL IO分析)
- **collection_layer**: db-system-view
- **collection_method**: "查询statement_history表，慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录"
- **abnormal_patterns**: ["\"慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录\""]
- **linked_case_ids**: ["gaussdb-disk-io-high-statement-view-01"]

## check_id: chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam

- **type**: metric
- **metric_name**: dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory
- **collection_layer**: db-system-view
- **collection_method**: "查询dbe_perf.memory_node_detail视图，明确内存占用点。•max_dynamic_memory：最大可使用动态内存 •dynamic_used_memory：已使用动态内存"
- **abnormal_patterns**: ["\"通常仅需要关注max_dynamic_memory和dynamic_used_memory差距，如果dynamic内存不足，会导致用户查询报错\""]
- **linked_case_ids**: ["gaussdb-memory-pressure-node-detail-01"]

## check_id: chk-dbe-perf-session-memory-detail-dynamic-used-shrctx

- **type**: metric
- **metric_name**: dbe_perf.session_memory_detail (dynamic_used_shrctx较小时)
- **collection_layer**: db-system-view
- **collection_method**: "dynamic_used_shrctx较小，查询dbe_perf.session_memory_detail可获取到不同Session的内存消耗，通常来讲：用户会话数和用户每个session上内存占用都会导致动态内存异常问题。"
- **abnormal_patterns**: ["\"dynamic_used_shrctx较小\""]
- **linked_case_ids**: ["gaussdb-memory-pressure-node-detail-01"]

## check_id: chk-dbe-perf-shared-memory-detail-dynamic-used-shrctx

- **type**: metric
- **metric_name**: dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时)
- **collection_layer**: db-system-view
- **collection_method**: "dynamic_used_shrctx较大，查询dbe_perf.shared_memory_detail可获取到异常内存消耗的context，通常此处有过多的异常消耗，多数情况下为用户session上的内存异常消耗。"
- **abnormal_patterns**: ["\"dynamic_used_shrctx较大\""]
- **linked_case_ids**: ["gaussdb-memory-pressure-node-detail-01"]

## check_id: chk-dbe-perf-local-active-session

- **type**: metric
- **metric_name**: dbe_perf.local_active_session (秒级抖动)
- **collection_layer**: db-system-view
- **collection_method**: "对于短时间秒级性能抖动，分析相应时间点的dbe_perf.local_active_session，可排查点如下：•异常等待事件，当时SQL的异常等待事件，可参考整体性能慢-等待事件分析。•异常SQL，分析某些SQL出现的频率变化，以及执行速度，如多次采样均被采集到，即可反向分析到SQL执行时间。•异常连接数变化，比如业务突然连接增加。"
- **abnormal_patterns**: ["\"如多次采样均被采集到，即可反向分析到SQL执行时间\""]
- **linked_case_ids**: ["gaussdb-perf-jitter-asp-analysis-01"]

## check_id: chk-gs-asp

- **type**: metric
- **metric_name**: gs_asp (两天内秒级抖动)
- **collection_layer**: db-system-view
- **collection_method**: "对于两天内秒级性能抖动，分析相应时间点的gs_asp表"
- **abnormal_patterns**: ["\"分析相应时间点的gs_asp表\""]
- **linked_case_ids**: ["gaussdb-perf-jitter-asp-analysis-01"]

## check_id: chk-data-node-scan

- **type**: metric
- **metric_name**: 执行计划下推标识（Data Node Scan）
- **collection_layer**: db-interactive-cmd
- **collection_method**: "将GUC参数enable_fast_query_shipping设置为off，使查询优化器使用分布式框架策略。查看执行计划。如果执行计划中有Data Node Scan节点，那么此执行计划是发送语句的分布式执行计划，为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。"
- **abnormal_patterns**: ["\"可见，func_percent_2并没有被下推，而是将ss_sales_price和ss_list_price收到CN上，再进行计算，消耗大量CN的资源，而且"]
- **linked_case_ids**: ["gaussdb-dist-volatile-func-not-pushed-slow-01"]

## check_id: chk-pg-proc-provolatile-proshippable

- **type**: metric
- **metric_name**: pg_proc.provolatile / proshippable
- **collection_layer**: db-system-view
- **collection_method**: "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE。另外，在pg_proc中的proshippable字段，取值范围为t/f/NULL，这个字段与provolatile字段一起用于描述函数是否下推。"
- **abnormal_patterns**: ["\"如果函数的provolatile属性为s或v，则仅当proshippable的值为t时，函数可以下推。\"","\"不下推语句在pg_log中会打印不下推的原因\""]
- **linked_case_ids**: ["gaussdb-dist-volatile-func-not-pushed-slow-01","gaussdb-dws-statement-not-pushed-down-slow-01","gaussdb-dws-statement-not-pushed-down-volatile-func-01"]

## check_id: chk-explain-verbose-remotequery

- **type**: metric
- **metric_name**: explain verbose · RemoteQuery 计划
- **collection_layer**: db-interactive-cmd
- **collection_method**: `yshen=# set rewrite_rule='none'; SET yshen=# explain (verbose on, costs off)  select two_sum(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);`
- **abnormal_patterns**: ["`该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-rewrite-rule-partialpush-01"]

## check_id: chk-explain-verbose-subplan

- **type**: metric
- **metric_name**: explain verbose · SubPlan 执行方式
- **collection_layer**: db-interactive-cmd
- **collection_method**: `yshen=# set rewrite_rule='none'; SET yshen=# explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;`
- **abnormal_patterns**: ["`由于目标列中的相关子查询(select avg(c2) from t2 where t2.c2=t1.c2)无法提升的缘故，导致每扫描t1的一行数据，就会触发"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 执行计划下推标识
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=# explain select * from t where c1 > 1;`
- **abnormal_patterns**: ["\"通常而言explain语句后没有显示具体的执行计划算子，仅存在类似关键字\\\"Data Node Scan on\\\"则说明语句已下推给DN去执行\"","\"可见，func_percent_2并没有被下推，而是将ss_sales_price和ss_list_price收到CN上，再进行计算，消耗大量CN的资源，而且"]
- **linked_case_ids**: ["gaussdb-dist-v3-volatile-func-not-pushed-slow-01","gaussdb-dws-statement-not-pushed-down-volatile-func-01"]

## check_id: chk-pg-proc-provolatile

- **type**: metric
- **metric_name**: pg_proc.provolatile
- **collection_layer**: db-system-view
- **collection_method**: "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE"
- **abnormal_patterns**: ["\"如果函数的provolatile属性为s或v，则仅当proshippable的值为t时，函数可以下推。\""]
- **linked_case_ids**: ["gaussdb-dist-v3-volatile-func-not-pushed-slow-01"]

## check_id: chk-explain-verbose-warning

- **type**: metric
- **metric_name**: explain verbose WARNING · 统计信息缺失提示
- **collection_layer**: db-interactive-cmd
- **collection_method**: `通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, ...) are not collected. HINT:Do analyze for them in order to generate optimized plan.`
- **abnormal_patterns**: ["`WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, pub"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-missing-analyze-dist-v8-01"]

## check_id: chk-explain-nest-loop-join

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · Nest Loop Join 耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。`
- **abnormal_patterns**: ["> 12s"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01"]

## check_id: chk-enable-hashjoin

- **type**: metric
- **metric_name**: enable_hashjoin 关闭后执行计划
- **collection_layer**: db-interactive-cmd
- **collection_method**: `SET enable_hashjoin = off;`
- **abnormal_patterns**: ["`分析上述执行计划，发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01"]

## check_id: chk-explain-verbose-warning

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表
- **collection_layer**: db-interactive-cmd
- **collection_method**: `通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan.`
- **abnormal_patterns**: ["`Statistics in some tables or columns(...) are not collected.`"]
- **linked_case_ids**: ["gaussdb-query-slow-missing-analyze-01"]

## check_id: chk-pg-log-statistics-not-collected

- **type**: metric
- **metric_name**: pg_log 日志 · Statistics not collected 日志行
- **collection_layer**: log-grep
- **collection_method**: `可以通过在pg_log目录下的日志文件中查找以下信息来确认当前执行的query是否由于没有收集统计信息导致查询性能变差。`
- **abnormal_patterns**: ["`LOG:Statistics in some tables or columns(...) are not collected.`"]
- **linked_case_ids**: ["gaussdb-query-slow-missing-analyze-01"]

## check_id: chk-explain-join

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · Join 算子类型及耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。`
- **abnormal_patterns**: ["`分析上述执行计划，发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。"]
- **linked_case_ids**: ["gaussdb-query-slow-complex-join-intermediate-rows-01"]

## check_id: chk-explain-analyze-a-time-rows-removed-by-filter

- **type**: metric
- **metric_name**: explain analyze · A-time / Rows Removed by Filter
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=#  explain (analyze on,costs off) select * from t1 where c2=10004;`
- **abnormal_patterns**: ["`全表扫描返回5条数据，过滤掉大量数据，在c2列上建立索引后，使用IndexScan扫描效率显著提高，从20毫秒降低到3毫秒。`"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-seqscan-vs-indexscan-01"]

## check_id: chk-explain-analyze-nested-loop-a-time

- **type**: metric
- **metric_name**: explain analyze · Nested Loop A-time
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=#  explain analyze select count(*) from t2,t1 where t1.c1=t2.c2;`
- **abnormal_patterns**: ["NestLoop A-time > 5000ms"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-outer-01"]

## check_id: chk-explain-analyze-groupaggregate-a-time-vs-hashaggregate

- **type**: metric
- **metric_name**: explain analyze · GroupAggregate A-time vs HashAggregate
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=#  explain analyze select count(*) from t1 group by c2;`
- **abnormal_patterns**: ["`Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。`"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01"]

## check_id: chk-explain-analyze-a-time

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE A-time 瓶颈算子识别
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=# explain analyze select avg(netpaid) from (select c_last_name,c_first_name,s_store_name,ca_state,s_state,i_color,i_current_price,i_manager_id,i_units,i_size,sum(ss_sales_price) netpaid from store_sales,store_returns,store,item,customer,customer_address where ss_ticket_number = sr_ticket_number and ss_item_sk = sr_item_sk and ss_customer_sk = c_customer_sk and ss_item_sk = i_item_sk and ss_store_sk = s_store_sk and c_birth_country = upper(ca_country) and s_zip = ca_zip ...`
- **abnormal_patterns**: ["\"通用的优化手段是EXPLAIN ANALYZE/PERFORMANCE命令查看执行过程的瓶颈算子，然后进行针对性优化。\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-planhint-01"]

## check_id: chk-explain-verbose-streaming-vs-data-node-scan

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=# set rewrite_rule='none'; SET gaussdb=# explain (verbose on, costs off)  select group_concat(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);`
- **abnormal_patterns**: ["`该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`"]
- **linked_case_ids**: ["gaussdb-query-slow-no-partial-pushdown-01"]

## check_id: chk-explain-verbose-subplan

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · SubPlan 算子出现在目标列
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=# set rewrite_rule='none'; SET gaussdb=# explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;`
- **abnormal_patterns**: ["`导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`"]
- **linked_case_ids**: ["gaussdb-query-slow-correlated-subquery-target-list-01"]

## check_id: chk-pg-stat-get-last-data-changed-time

- **type**: metric
- **metric_name**: 近期数据变更表列表（pg_stat_get_last_data_changed_time）
- **collection_layer**: db-system-view
- **collection_method**: `gaussdb=# SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();`
- **abnormal_patterns**: ["\"通过table_distribution(schemaname text, tablename text)查询出表在各个DN占用的存储空间\""]
- **linked_case_ids**: ["gaussdb-dist-disk-full-storage-skew-01"]

## check_id: chk-pgxc-get-table-skewness

- **type**: metric
- **metric_name**: PGXC_GET_TABLE_SKEWNESS
- **collection_layer**: db-system-view
- **collection_method**: `gaussdb=#SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dist-routine-skew-inspection-01","gaussdb-dws-data-skew-query-slow-01"]

## check_id: chk-table-distribution-dn-1w

- **type**: metric
- **metric_name**: table_distribution() 各DN空间（大表个数超1W场景）
- **collection_layer**: db-system-view
- **collection_method**: `gaussdb=#SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace INNER JOIN pg_catalog.table_distribution() s ON s.schemaname = n.nspname AND s.tablename = c.relname INNER JOIN pg_catalog.pgxc_class x ON c.oid = x.pcrelid AND x.pclocatortype = 'H' GROUP BY schemaname,tablename;`
- **abnormal_patterns**: ["\"直接使用table_distribution()函数自定义输出，减少输出列进行计算优化\""]
- **linked_case_ids**: ["gaussdb-dist-routine-skew-inspection-01"]

## check_id: chk-explain-verbose-warning

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE 执行计划 Warning
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain verbose`
- **abnormal_patterns**: ["\"WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, pub","\"执行计划中会有语句未收集统计信息的告警，并且通常E-rows估算非常小。\""]
- **linked_case_ids**: ["gaussdb-query-slow-missing-statistics-explain-verbose-01","gaussdb-dws-query-slow-missing-statistics-01"]

## check_id: chk-pg-log-statistics-warning

- **type**: metric
- **metric_name**: pg_log 日志中的 Statistics WARNING
- **collection_layer**: log-grep
- **collection_method**: NULL
- **abnormal_patterns**: ["\"可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。\""]
- **linked_case_ids**: ["gaussdb-query-slow-missing-statistics-explain-verbose-01"]

## check_id: chk-explain-analyze-a-time-seqscan-vs-indexscan

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE A-time · SeqScan vs IndexScan
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=#  explain (analyze on, costs off) select * from t1 where c1=10004;`
- **abnormal_patterns**: ["\"全表扫描返回7条数据，过滤掉大量数据\" (A-time: 2053.069ms, Rows Removed by Filter: 110000)"]
- **linked_case_ids**: ["gaussdb-query-slow-seqscan-index-missing-01"]

## check_id: chk-explain-analyze-a-time-nestloop

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE A-time · NestLoop算子耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=#  explain analyze select count(*) from t1,t2 where t1.c1=t2.c2;`
- **abnormal_patterns**: ["\"NestLoop耗时27秒\" (A-time: 27544.545ms for Nested Loop)"]
- **linked_case_ids**: ["gaussdb-query-slow-nestloop-hashjoin-02"]

## check_id: chk-explain-analyze-a-time-sort-groupagg-vs-hashagg

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE A-time · Sort+GroupAgg vs HashAgg
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=#  explain analyze select count(*) from t1 group by c1;`
- **abnormal_patterns**: ["\"GroupAggregate A-time: 2417.004ms，Sort A-time: 2304.329ms，Peak Memory: 26466KB\""]
- **linked_case_ids**: ["gaussdb-query-slow-groupagg-sort-03"]

## check_id: chk-explain-analyze

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE 执行计划 · 算子耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze on, costs off) select * from t1 where c1=10004;`
- **abnormal_patterns**: ["\"全表扫描返回7条数据，过滤掉大量数据\""]
- **linked_case_ids**: ["gaussdb-query-slow-seqscan-no-index-01"]

## check_id: chk-explain-analyze-nestloop

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE · NestLoop 算子耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain analyze select count(*) from t1,t2 where t1.c1=t2.c2;`
- **abnormal_patterns**: ["\"NestLoop耗时27秒\""]
- **linked_case_ids**: ["gaussdb-query-slow-nestloop-large-rowset-01"]

## check_id: chk-explain-analyze-sort-groupagg

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE · Sort+GroupAgg 算子耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain analyze select count(*) from t1 group by c1;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-query-slow-sort-groupagg-large-result-01"]

## check_id: chk-hashaggregate

- **type**: metric
- **metric_name**: 执行计划中双层HashAggregate
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=# EXPLAIN (costs off) SELECT t.c2, sum(cc) FROM (SELECT c2, sum(c3) AS cc FROM t1 GROUP BY c2) s1, t WHERE s1.c2=t.c2 GROUP BY t.c2 ORDER BY 1,2;`
- **abnormal_patterns**: ["\"Subquery Scan on s1 -> HashAggregate Group By Key: t1.c2 -> Seq Scan on t1\""]
- **linked_case_ids**: ["gaussdb-rewrite-lazyagg-double-aggregate-slow-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 执行计划子查询关联方式
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=# EXPLAIN (costs off) SELECT t1 FROM t1 WHERE t1.c2 = 10 AND t1.c3 < (SELECT sum(c3) FROM t2 WHERE t1.c1 = t2.c1);`
- **abnormal_patterns**: ["\"先针对子查询的关联字段进行分组聚集，再和主查询进行关联，减少相关子链接的重复扫描\""]
- **linked_case_ids**: ["gaussdb-rewrite-magicset-correlated-subquery-slow-01"]

## check_id: chk-subplan

- **type**: metric
- **metric_name**: 执行计划中SubPlan节点
- **collection_layer**: db-interactive-cmd
- **collection_method**: `gaussdb=#  EXPLAIN (verbose on, costs off) SELECT c1,(SELECT avg(c2) FROM t2 WHERE t2.c2=t1.c2) FROM t1 WHERE t1.c1<100 ORDER BY t1.c2;`
- **abnormal_patterns**: ["\"SubPlan 1 -> Aggregate Output: avg(t2.c2) -> Seq Scan on public.t2 Output: t2.c","\"SubPlan 1 -> Aggregate ... -> Seq Scan on public.t2 Filter: (t2.c2 = t1.c2)\""]
- **linked_case_ids**: ["gaussdb-rewrite-v8-intargetlist-subplan-slow-01","gaussdb-rewrite-intargetlist-subplan-slow-01"]

## check_id: chk-dn-cpu

- **type**: metric
- **metric_name**: 备DN CPU使用率 · 回放线程资源
- **collection_layer**: os
- **collection_method**: "极致RTO采用了多个page redo线程并行加速回放进度。当备DN回放追平主DN，空载的情况下，单个page redo线程的CPU消耗大约在15%左右（实际值与具体硬件和参数配置相关），备DN回放的总CPU消耗值 = 单个page redo线程的CPU消耗值 x page redo线程数。"
- **abnormal_patterns**: ["> 70%"]
- **linked_case_ids**: ["gaussdb-replica-lag-redo-workers-01"]

## check_id: chk-explain-verbose

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE 统计信息警告
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan."
- **abnormal_patterns**: ["\"WARNING:Statistics in some tables or columns(...) are not collected.\""]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-missing-analyze-01"]

## check_id: chk-pg-log

- **type**: metric
- **metric_name**: pg_log 统计信息缺失日志
- **collection_layer**: log-grep
- **collection_method**: "可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。"
- **abnormal_patterns**: ["\"LOG:Statistics in some tables or columns(...) are not collected.\""]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-missing-analyze-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 执行计划子查询处理方式
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain verbose select t1.c1 from t1 where t1.c1 = (select t2.c1 from t2 where t1.c1=t2.c1);`
- **abnormal_patterns**: ["\"Hash Join ... Hash Cond: (t1.c1 = subquery.\\\"?column?\\\") ... Unique Check Requi"]
- **linked_case_ids**: ["gaussdb-rewrite-uniquecheck-subquery-join-01"]

## check_id: chk-explain-analyze-stream

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE · Stream算子类型
- **collection_layer**: db-interactive-cmd
- **collection_method**: "GaussDB计划中常见的主要Stream算子包括Redistribute、Broadcast和Gather。"
- **abnormal_patterns**: ["\"优化器认为适合做Broadcast。于是最终选择了一边Broadcast的计划。\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-broadcast-skew-redistribute-01"]

## check_id: chk-explain-analyze-startup-vs-total

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE · 路径代价 (Startup vs Total)
- **collection_layer**: db-interactive-cmd
- **collection_method**: "把explain_perf_mode设置为normal，查看原Nest Loop的启动代价"
- **abnormal_patterns**: ["\"红框中的两个cost，分别是启动代价和总代价，在看Hash Join的cost，明显Hash Join的启动代价比Nest Loop的大很多（启动代价代表了输"]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-nestloop-seqscan-cost-02"]

## check_id: chk-nestloop

- **type**: metric
- **metric_name**: 语句执行时间 / 执行计划中 NestLoop 算子
- **collection_layer**: db-interactive-cmd
- **collection_method**: `该问题发生在实时场景下，语句执行时间因为达到了 3600s而自动终止运行`
- **abnormal_patterns**: [">= 3600s"]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-nestloop-perf-jump-hint-01"]

## check_id: chk-pgxc-wlm-session-history-block-time-duration

- **type**: metric
- **metric_name**: pgxc_wlm_session_history · block_time / duration
- **collection_layer**: db-system-view
- **collection_method**: `pgxc_wlm_session_history`
- **abnormal_patterns**: ["\"block_time较大，而duration值并无明显变化，说明用户作业受其它作业影响，在真正开始执行前进行了较长时间的排队\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-topsql-queue-wait-01"]

## check_id: chk-pgxc-wlm-session-history

- **type**: metric
- **metric_name**: pgxc_wlm_session_history · 同期并发作业数
- **collection_layer**: db-system-view
- **collection_method**: `pgxc_wlm_session_history`
- **abnormal_patterns**: ["\"下一步需要接着查看本数据表，统计起始时间小于start_time、结束时间大于finish_time的作业数量。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-topsql-queue-wait-01"]

## check_id: chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn-

- **type**: metric
- **metric_name**: pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent
- **collection_layer**: db-system-view
- **collection_method**: `pgxc_wlm_session_history`
- **abnormal_patterns**: ["\"如果一个查询的DN执行时间有严重倾斜，那就需要考虑数据表的分区、分布列是否设置合适\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-data-skew-dn-time-01"]

## check_id: chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ

- **type**: metric
- **metric_name**: GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write
- **collection_layer**: db-system-view
- **collection_method**: `GS_WLM_INSTANCE_HISTORY`
- **abnormal_patterns**: ["\"io_util&io_await能够反应出磁盘的繁忙程度，disk_read&disk_write是发生的实际IO流量值，如果磁盘很繁忙，但实际IO流量值不高"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-dn-io-contention-01"]

## check_id: chk-explain-performance-windowagg-sort

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain performance`
- **abnormal_patterns**: ["\"执行计划中出现Sort和WindowAgg，第3~6步集中在一个DN上进行，使SQL非常缓慢。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-windowagg-single-dn-01"]

## check_id: chk-explain-performance-sql-streaming-redistribute

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜）
- **collection_layer**: db-interactive-cmd
- **collection_method**: `SQL自诊断信息显示在做row_number()函数计算前的PARTITION BY T.ORDER_LINE_ID引入的重分布算子(Streaming(type: REDISTRIBUTE))有计算倾斜`
- **abnormal_patterns**: ["`Streaming(type: REDISTRIBUTE)有计算倾斜`"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-row-number-partition-null-01"]

## check_id: chk-order-line-id-null

- **type**: metric
- **metric_name**: 列统计信息 · ORDER_LINE_ID NULL 比例
- **collection_layer**: db-system-view
- **collection_method**: `查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值`
- **abnormal_patterns**: ["> 50% NULL"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-row-number-partition-null-01"]

## check_id: chk-pgxc-wlm-session-history-dataskew-warning

- **type**: metric
- **metric_name**: pgxc_wlm_session_history · DataSkew warning
- **collection_layer**: db-system-view
- **collection_method**: "GaussDB 在执行 SQL 语句时，会对其性能表现进行分析和记录，通过视图和函数等手段呈现给用户。执行完一条代价大于resource_track_cost后，诊断信息会存放在内存hash表中，可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
- **abnormal_patterns**: ["\"max_dn_tuples > min_dn_tuples * 10 且 max_dn_tuples > 100,000\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-data-skew-01"]

## check_id: chk-pgxc-wlm-session-history-large-table-in-broadcast-warning

- **type**: metric
- **metric_name**: pgxc_wlm_session_history · Large Table in Broadcast warning
- **collection_layer**: db-system-view
- **collection_method**: "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
- **abnormal_patterns**: ["\"平均广播到每个DN上的数据行数 > 100,000\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-large-table-broadcast-02"]

## check_id: chk-pgxc-wlm-session-history-spill

- **type**: metric
- **metric_name**: pgxc_wlm_session_history · Spill告警
- **collection_layer**: db-system-view
- **collection_method**: "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
- **abnormal_patterns**: ["\"> 256MB\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-spill-overflow-03"]

## check_id: chk-pgxc-wlm-session-history-nestloop

- **type**: metric
- **metric_name**: pgxc_wlm_session_history · NestLoop大表告警
- **collection_layer**: db-system-view
- **collection_method**: "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
- **abnormal_patterns**: ["\"内外表中最大行数 > DN数量 * 100,000\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-nestloop-large-table-04"]

## check_id: chk-dn

- **type**: metric
- **metric_name**: 各DN磁盘利用率
- **collection_layer**: os
- **collection_method**: `gs_ssh –c "df -h"`
- **abnormal_patterns**: ["> 5%差异"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-query-slow-01"]

## check_id: chk-pgxc-thread-wait-status-wait-status

- **type**: metric
- **metric_name**: pgxc_thread_wait_status.wait_status
- **collection_layer**: db-system-view
- **collection_method**: `Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;`
- **abnormal_patterns**: ["\"通过等待视图查看作业的运行情况，发现作业总是等待部分DN，或者个别DN。\""]
- **linked_case_ids**: ["gaussdb-dws-data-skew-query-slow-01"]

## check_id: chk-table-skewness-table-distribution

- **type**: metric
- **metric_name**: table_skewness / table_distribution
- **collection_layer**: db-system-view
- **collection_method**: `select table_skewness('store_sales');`
- **abnormal_patterns**: ["\"数据最多的dn有22831616行，其他dn都是0行，数据有严重倾斜。\""]
- **linked_case_ids**: ["gaussdb-dws-data-skew-query-slow-01"]

## check_id: chk-warning

- **type**: metric
- **metric_name**: 执行计划统计信息Warning
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过explain verbose/explain performance打印语句的执行计划"
- **abnormal_patterns**: ["\"执行计划中会有语句未收集统计信息的告警，并且通常E-rows估算非常小。\""]
- **linked_case_ids**: ["gaussdb-dws-statistics-not-collected-plan-poor-01"]

## check_id: chk-remote

- **type**: metric
- **metric_name**: 执行计划下推标识（__REMOTE关键字）
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过explain verbose打印语句执行计划"
- **abnormal_patterns**: ["\"上述执行计划中有__REMOTE关键字，这就表明当前的语句是不下推执行的。\""]
- **linked_case_ids**: ["gaussdb-dws-statement-not-pushed-down-slow-01"]

## check_id: chk-nestloop

- **type**: metric
- **metric_name**: 执行计划算子类型（NestLoop）
- **collection_layer**: db-interactive-cmd
- **collection_method**: "首先观察SQL语句中有not in 语法；执行计划中有NestLoop"
- **abnormal_patterns**: ["\"NestLoop是导致语句性能慢的主要原因。\""]
- **linked_case_ids**: ["gaussdb-dws-notin-nestloop-slow-01"]

## check_id: chk-partitioned-cstore-scan

- **type**: metric
- **metric_name**: 执行计划：Partitioned CStore Scan分区扫描范围
- **collection_layer**: db-interactive-cmd
- **collection_method**: "和客户收集几个典型的慢sql，分别打印执行计划。"
- **abnormal_patterns**: ["\"从执行计划中可以看出来，两条sql的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分"]
- **linked_case_ids**: ["gaussdb-dws-no-partition-pruning-slow-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 线程等待状态
- **collection_layer**: db-system-view
- **collection_method**: `select * from pg_thread_wait_status where query_id='149181737656737395';`
- **abnormal_patterns**: ["\"根据线程等待状态，并没有出现都在等待某个DN的情况，初步排除中间结果集偏斜到了同一个DN的情况。\""]
- **linked_case_ids**: ["gaussdb-dws-row-estimate-small-nestloop-slow-01"]

## check_id: chk-vecnestloopruntime

- **type**: metric
- **metric_name**: 进程堆栈（VecNestLoopRuntime）
- **collection_layer**: os
- **collection_method**: `gstack 14104`
- **abnormal_patterns**: ["\"堆栈中有VecNestLoopRuntime，以及结合执行计划，初步判断是由于统计信息不准，优化器评估结果集较少，计划走了nestloop导致性能下降。\""]
- **linked_case_ids**: ["gaussdb-dws-row-estimate-small-nestloop-slow-01"]

## check_id: chk-sql-create-index

- **type**: metric
- **metric_name**: 活跃SQL及CREATE INDEX语句
- **collection_layer**: db-system-view
- **collection_method**: `select * from pg_stat_activity where state !='idle' and usename !='omm';`
- **abnormal_patterns**: ["\"查询当前活跃sql，发现有大量的create index语句\""]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-vacuum-slow-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 表数据倾斜
- **collection_layer**: db-system-view
- **collection_method**: `select table_skewness('ioc_dm.m_ss_index_event');`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-vacuum-slow-01"]

## check_id: chk-max-process-memory-shared-buffers

- **type**: metric
- **metric_name**: 内存参数：max_process_memory, shared_buffers
- **collection_layer**: db-shell
- **collection_method**: "检查内存相关参数，设置不合理"
- **abnormal_patterns**: ["\"单节点总内存大小为256G，max_process_memory为12G，设置过小，shared_buffers为32M，设置过小\""]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-vacuum-slow-01"]

## check_id: chk-in

- **type**: metric
- **metric_name**: 执行计划in条件处理方式
- **collection_layer**: db-interactive-cmd
- **collection_method**: "打印语句的执行计划"
- **abnormal_patterns**: ["\"执行计划中，in条件还是作为普通的过滤条件存在。这种场景下，最优的执行计划应该是将\\\"in 常量\\\"转化为join操作性能更好。\""]
- **linked_case_ids**: ["gaussdb-dws-in-constant-no-join-slow-01"]

## check_id: chk-pgxc-get-stat-all-tables-dirty-page-rate

- **type**: metric
- **metric_name**: PGXC_GET_STAT_ALL_TABLES.dirty_page_rate
- **collection_layer**: db-system-view
- **collection_method**: `SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_GET_STAT_ALL_TABLES WHERE schemaName NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'cstore', 'pmk') AND dirty_page_rate > 30 ORDER BY table_size DESC, dirty_page_rate DESC;`
- **abnormal_patterns**: ["> 30"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-autovacuum-01"]

## check_id: chk-explain-index-scan

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · 是否使用Index Scan
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain verbose select * from test where a = 101;`
- **abnormal_patterns**: ["\"结果集 > 70% 全表数据\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-index-large-result-01"]

## check_id: chk-explain-indexscan

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · 是否选择IndexScan
- **collection_layer**: db-interactive-cmd
- **collection_method**: "对表执行ANALYZE更新统计信息。"
- **abnormal_patterns**: ["\"如果表未执行ANALYZE或最近一次执行完ANALYZE后表进行过数据量较大的增删操作，会导致统计信息不准，该场景下也可能导致查询表时没有使用索引。\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-index-no-analyze-02"]

## check_id: chk-explain-verbose-index-scan-vs-seq-scan

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · Index Scan vs Seq Scan
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain verbose select * from test where a  = 101;`
- **abnormal_patterns**: ["\"where a = 101，where a = 102 - 1都使用了a列上的索引，但是where a + 1 = 102没有使用索引。\""]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-index-func-03"]

## check_id: chk-waiting-in-queue

- **type**: metric
- **metric_name**: 查询等待状态 · waiting in queue
- **collection_layer**: db-system-view
- **collection_method**: "普通用户主要在waiting in queue/waiting in global queue时。当前的活跃语句数超过max_active_statements限制导致的普通用户排队，由于管理员用户不受管控所以无需排队。"
- **abnormal_patterns**: ["\"普通用户在排队：waiting in queue/waiting in global queue/waiting in ccn queue.\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-max-active-statements-01"]

## check_id: chk-explain-or-filter

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · 系统视图权限OR filter
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过执行计划可以看到系统视图中的权限判断中多用or条件判断：pg_has_role(c.relowner, 'USAGE'::text) OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text)"
- **abnormal_patterns**: ["\"普通用户的or条件需要逐一判断，如果数据库中表个数比较多，最终会导致普通用户比dbadmin需要更长的执行时间。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-permission-or-filter-02"]

## check_id: chk-dn

- **type**: metric
- **metric_name**: 各DN数据量分布
- **collection_layer**: db-shell
- **collection_method**: `SELECT pg_get_tabledef('customer_t1');`
- **abnormal_patterns**: ["> 10%"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-bad-dist-key-01"]

## check_id: chk-cn

- **type**: metric
- **metric_name**: CN日志中不下推原因
- **collection_layer**: log-grep
- **collection_method**: "不下推语句在pg_log中会打印不下推的原因。LOG: SQL can't be shipped, reason: ..."
- **abnormal_patterns**: ["\"LOG: SQL can't be shipped, reason: With-Recursive does not contain \\\"ALL\\\" to b"]
- **linked_case_ids**: ["gaussdb-dws-with-recursive-not-pushed-slow-01"]

## check_id: chk-explain-verbose-warning

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE WARNING信息 · 统计信息缺失
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过EXPLAIN VERBOSE执行query分析执行计划时会提示WARNING信息"
- **abnormal_patterns**: ["\"WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, pub"]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-missing-analyze-01"]

## check_id: chk-hstore-delta-vs-cu

- **type**: metric
- **metric_name**: HStore Delta表大小 vs 主表CU数据
- **collection_layer**: db-system-view
- **collection_method**: NULL
- **abnormal_patterns**: ["\"Delta表空间复用受oldestXmin影响。长时间运行的事务可能导致空间复用延迟和膨胀。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-hstore-delta-bloat-01"]

## check_id: chk-enable-codegen

- **type**: metric
- **metric_name**: enable_codegen 参数状态
- **collection_layer**: db-shell
- **collection_method**: `SHOW turbo_engine_version;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-realtime-numa-codegen-01"]

## check_id: chk-pgxc-wlm-session-info-streaming-stream-count

- **type**: metric
- **metric_name**: pgxc_wlm_session_info · Streaming 算子数（stream_count）
- **collection_layer**: db-system-view
- **collection_method**: `SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM pgxc_wlm_session_info ORDER BY stream_count DESC limit 100;`
- **abnormal_patterns**: ["> 100"]
- **linked_case_ids**: ["gaussdb-dws-cpu-high-stream-count-01"]

## check_id: chk-pgxc-wlm-session-info-max-cpu-time-cpu

- **type**: metric
- **metric_name**: pgxc_wlm_session_info · max_cpu_time（高CPU语句）
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_wlm_session_info WHERE start_time > 'xxxx-xx-xx' AND start_time < 'xxxx-xx-xx' ORDER BY max_cpu_time desc;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-cpu-high-stream-count-01"]

## check_id: chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has

- **type**: metric
- **metric_name**: pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史）
- **collection_layer**: db-system-view
- **collection_method**: `SELECT start_time, block_time, duration, sql_hash, warning, max_peak_memory, max_spill_size, query_plan FROM pgxc_wlm_session_info were start_time > 'xxxx-xx-xx xx:xx' and sql_hash = 'xxx' ORDER BY start_time desc limit 10;`
- **abnormal_patterns**: ["`找到对应的快慢语句后，对比其执行计划query_plan，发现执行计划跳变严重。`"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-plan-jump-stale-stats-01"]

## check_id: chk-resource-track-level-operator-realtime

- **type**: metric
- **metric_name**: resource_track_level · operator_realtime 级别实时算子监控
- **collection_layer**: db-system-view
- **collection_method**: `SET resource_track_level = 'operator_realtime';`
- **abnormal_patterns**: ["`能够看出哪个算子执行时间长，通过算子执行时间和已处理行数等信息，确定是否需要终止SQL。`"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-long-running-operator-01"]

## check_id: chk-pgxc-stat-activity-state-waiting-enqueue

- **type**: metric
- **metric_name**: PGXC_STAT_ACTIVITY · state / waiting / enqueue
- **collection_layer**: db-system-view
- **collection_method**: `SELECT coorname, usename,client_addr,application_name,state,waiting,enqueue,pid FROM PGXC_STAT_ACTIVITY WHERE DATNAME='数据库名称';`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-pgxc-stat-activity-01"]

## check_id: chk-pgxc-stat-activity-runtime-current-timestamp-query-start

- **type**: metric
- **metric_name**: PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start)
- **collection_layer**: db-system-view
- **collection_method**: `SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle' order by 1 desc;`
- **abnormal_patterns**: ["`查询会返回按执行时间长短从大到小排列的查询语句列表。第一条结果就是当前系统中执行时间最长的查询语句。`"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-pgxc-stat-activity-01"]

## check_id: chk-pgxc-stat-activity-waiting-true

- **type**: metric
- **metric_name**: PGXC_STAT_ACTIVITY · waiting=true 阻塞查询
- **collection_layer**: db-system-view
- **collection_method**: `SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;`
- **abnormal_patterns**: ["`大部分场景下，阻塞是因为系统内部锁而导致的，waiting字段才显示为true，此阻塞可在视图pgxc_stat_activity中体现。`"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-pgxc-stat-activity-01"]

## check_id: chk-pg-locks

- **type**: metric
- **metric_name**: pg_locks · 阻塞会话与持锁会话关联
- **collection_layer**: db-system-view
- **collection_method**: 
- **abnormal_patterns**: ["`该查询返回会话ID、CN名称、用户信息、查询状态，以及导致阻塞的表、模式信息。`"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-pgxc-stat-activity-01"]

## check_id: chk-dws-connector-connectiontimeout

- **type**: metric
- **metric_name**: DWS-Connector connectionTimeOut 默认值
- **collection_layer**: db-shell
- **collection_method**: `DWS-Connector默认超时时间connectionTimeOut为5min，可调大该值。`
- **abnormal_patterns**: ["5min (默认值过小)"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-flink-connection-timeout-01"]

## check_id: chk-pgxc-lock-conflicts

- **type**: metric
- **metric_name**: pgxc_lock_conflicts 锁冲突视图
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_lock_conflicts;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-wait-timeout-01"]

## check_id: chk-pg-stat-activity-pg-locks-sql-8-0-x

- **type**: metric
- **metric_name**: pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本）
- **collection_layer**: db-system-view
- **collection_method**: 
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-wait-timeout-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 写入方式
- **collection_layer**: db-shell
- **collection_method**: "如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈"
- **abnormal_patterns**: ["\"如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈\""]
- **linked_case_ids**: ["gaussdb-dws-write-slow-single-insert-01"]

## check_id: chk-pgxc-stat-activity-state-waiting-query

- **type**: metric
- **metric_name**: pgxc_stat_activity · state / waiting / query
- **collection_layer**: db-system-view
- **collection_method**: `SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';`
- **abnormal_patterns**: ["`查看当前处于阻塞状态的查询语句：SELECT coorname, pid,datname, usename, state,waiting,query FROM"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-blocked-or-stale-stats-01"]

## check_id: chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic-

- **type**: metric
- **metric_name**: pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_total_memory_detail;`
- **abnormal_patterns**: ["dynamic_used_memory >= max_dynamic_memory"]
- **linked_case_ids**: ["gaussdb-dws-memory-pressure-oom-query-01"]

## check_id: chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc

- **type**: metric
- **metric_name**: pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent
- **collection_layer**: db-system-view
- **collection_method**: `SELECT nodename,pid,dbname,username,application_name,min_peak_memory,max_peak_memory,average_peak_memory,memory_skew_percent,substr(query,0,50) as query FROM pgxc_wlm_session_statistics;`
- **abnormal_patterns**: ["`根据结果中的max_peak_memory以及memory_skew_percent值，较大的值就是消耗内存较多的语句。`"]
- **linked_case_ids**: ["gaussdb-dws-memory-pressure-oom-query-01"]

## check_id: chk-vs

- **type**: metric
- **metric_name**: 列存表物理大小 vs 有效数据量
- **collection_layer**: db-shell
- **collection_method**: NULL
- **abnormal_patterns**: ["\"多次对列存表UPDATE，发现表大小膨胀了十多倍。\""]
- **linked_case_ids**: ["gaussdb-dws-disk-space-column-table-bloat-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 各节点磁盘使用率均衡性
- **collection_layer**: db-system-view
- **collection_method**: `登录DWS控制台。在"集群列表"页面，找到需要查看监控的集群。在指定集群所在行的"操作"列，单击"监控面板"。选择"监控 > 节点监控 > 磁盘"，查看磁盘使用率。`
- **abnormal_patterns**: ["> 5% 差值"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-hash-dist-01"]

## check_id: chk-pgxc-thread-wait-status-dn

- **type**: metric
- **metric_name**: pgxc_thread_wait_status · 作业等待 DN 分布
- **collection_layer**: db-system-view
- **collection_method**: `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;`
- **abnormal_patterns**: ["`发现作业总是等待部分DN或者个别DN`"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-hash-dist-01"]

## check_id: chk-explain-performance-dn

- **type**: metric
- **metric_name**: explain performance · DN 行数与耗时分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain performance select avg(ss_wholesale_cost) from store_sales;`
- **abnormal_patterns**: ["`基表scan的时间：最快的DN耗时5ms，最慢的DN耗时1173ms。数据分布情况：某些DN有22831616行，其他DN都是0行，数据有严重倾斜。`"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-hash-dist-01"]

## check_id: chk-table-skewness

- **type**: metric
- **metric_name**: table_skewness · 数据倾斜率
- **collection_layer**: db-system-view
- **collection_method**: `SELECT table_skewness('store_sales');`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-hash-dist-01"]

## check_id: chk-pgxc-get-table-skewness

- **type**: metric
- **metric_name**: pgxc_get_table_skewness · 全库倾斜视图
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-hash-dist-01"]

## check_id: chk-cn-pg-log-warning

- **type**: metric
- **metric_name**: CN pg_log 日志中 Warning 信息
- **collection_layer**: log-grep
- **collection_method**: NULL
- **abnormal_patterns**: ["\"在CN的pg_log日志中也会有类似的Warning信息。同时，E-rows会比实际值小很多。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-missing-statistics-01"]

## check_id: chk-explain-verbose-remote

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · __REMOTE 关键字
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过EXPLAIN VERBOSE打印语句执行计划。上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。"
- **abnormal_patterns**: ["\"上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-function-not-shipped-01"]

## check_id: chk-cn

- **type**: metric
- **metric_name**: CN日志 · 不下推原因
- **collection_layer**: log-grep
- **collection_method**: "不下推语句在pg_log中会打印不下推的原因，上述语句在CN的日志中会找到类似以下的日志。"
- **abnormal_patterns**: ["\"不下推语句在pg_log中会打印不下推的原因\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-function-not-shipped-01"]

## check_id: chk-nestloop

- **type**: metric
- **metric_name**: 执行计划算子类型（NestLoop出现）
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过EXPLAIN VERBOSE打印语句执行计划，查看执行计划发现SQL语句中存在not in语句"
- **abnormal_patterns**: ["\"NestLoop是导致语句性能慢的主要原因\""]
- **linked_case_ids**: ["gaussdb-dws-nestloop-not-in-query-slow-01"]

## check_id: chk-explain-partitioned-cstore-scan-selected-partitions

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量
- **collection_layer**: db-interactive-cmd
- **collection_method**: `收集几个典型的慢SQL语句，分别打印执行计划。从执行计划中可以看出来，两条SQL的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分区扫描上。`
- **abnormal_patterns**: ["`慢SQL过滤条件中未涉及分区字段，导致执行计划未分区剪枝，进行了全表扫描，性能严重劣化。`"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-partition-pruning-miss-01"]

## check_id: chk-i-o-cpu

- **type**: metric
- **metric_name**: 系统资源 I/O / 内存 / CPU 使用情况
- **collection_layer**: os
- **collection_method**: `排查当前的I/O、内存、CPU使用情况，没有发现资源占用高的情况。`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-plan-nestloop-row-underestimate-01"]

## check_id: chk-pg-thread-wait-status

- **type**: metric
- **metric_name**: pg_thread_wait_status · 线程等待状态
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pg_thread_wait_status WHERE query_id='149181737656737395';`
- **abnormal_patterns**: ["`根据线程等待状态，并没有出现都在等待某个DN的情况，初步排除中间结果集偏斜到了同一个DN的情况。`"]
- **linked_case_ids**: ["gaussdb-dws-plan-nestloop-row-underestimate-01"]

## check_id: chk-gstack-vecnestloopruntime

- **type**: metric
- **metric_name**: gstack · 进程堆栈中 VecNestLoopRuntime
- **collection_layer**: os
- **collection_method**: `联系运维人员登录到相应的实例节点上，打印等待状态为none的线程堆栈信息`
- **abnormal_patterns**: ["`堆栈中有VecNestLoopRuntime，结合执行计划，初步判断是由于统计信息不准，优化器评估结果集较少，执行计划使用了NestLoop导致性能下降。`"]
- **linked_case_ids**: ["gaussdb-dws-plan-nestloop-row-underestimate-01"]

## check_id: chk-pg-stat-activity-sql

- **type**: metric
- **metric_name**: pg_stat_activity 活跃SQL
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';`
- **abnormal_patterns**: ["\"发现有大量的CREATE INDEX语句\"","\"发现有大量的CREATE INDEX语句，需要和用户确认该业务是否合理。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-table-bloat-01","gaussdb-dws-query-slow-concurrent-index-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 表倾斜情况
- **collection_layer**: db-shell
- **collection_method**: `SELECT table_skewness('table name');`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-table-bloat-01"]

## check_id: chk-max-process-memory-shared-buffers-work-mem

- **type**: metric
- **metric_name**: max_process_memory / shared_buffers / work_mem 内存参数
- **collection_layer**: db-system-view
- **collection_method**: NULL
- **abnormal_patterns**: ["\"max_process_memory为12GB，设置过小。shared_buffers为32MB，设置过小。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-table-bloat-01"]

## check_id: chk-vs

- **type**: metric
- **metric_name**: 脏数据膨胀率 / 表实际大小 vs 有效数据量
- **collection_layer**: db-system-view
- **collection_method**: NULL
- **abnormal_patterns**: ["\"发现表数据膨胀严重，对其中一张8GB大小的表，总数据量5万条，做完VACUUM FULL后大小减小为5.6MB。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-table-bloat-01"]

## check_id: chk-explain

- **type**: metric
- **metric_name**: EXPLAIN执行计划耗时分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: NULL
- **abnormal_patterns**: ["\"打印执行计划，分析出耗时主要在index scan上，可能是I/O争抢导致\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-concurrent-index-01"]

## check_id: chk-cstore-scan

- **type**: metric
- **metric_name**: 执行计划算子：CStore Scan耗时占比
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通过抓取问题SQL的执行信息，发现大部分的耗时都在\"CStore Scan\""
- **abnormal_patterns**: ["\"大部分的耗时都在\\\"CStore Scan\\\"\""]
- **linked_case_ids**: ["gaussdb-dws-point-query-cstore-scan-slow-01"]

## check_id: chk-pg-session-wlmstat-status-statement-mem

- **type**: metric
- **metric_name**: pg_session_wlmstat · status / statement_mem
- **collection_layer**: db-system-view
- **collection_method**: `SELECT usename,substr(query,0,20),threadid,status,statement_mem FROM pg_session_wlmstat where usename not in ('omm','Ruby') order by statement_mem,status desc;`
- **abnormal_patterns**: ["statement_mem > max_dynamic_memory 的 1/3"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-ccn-queue-memory-01"]

## check_id: chk-cudesc-cu-row-count

- **type**: metric
- **metric_name**: cudesc表中CU的row_count分布
- **collection_layer**: db-system-view
- **collection_method**: 
- **abnormal_patterns**: ["row_count << 60000"]
- **linked_case_ids**: ["gaussdb-dws-cstore-small-cu-io-slow-01"]

## check_id: chk-cu

- **type**: metric
- **metric_name**: 执行计划中CU扫描数量
- **collection_layer**: db-interactive-cmd
- **collection_method**: "查看偶发慢业务慢时的执行计划信息，慢在cstore scan，且扫描数据量不大但扫描CU个数较多"
- **abnormal_patterns**: ["CU数量 >> 数据行数/60000"]
- **linked_case_ids**: ["gaussdb-dws-cstore-small-cu-io-slow-01"]

## check_id: chk-explain-cstore-scan-cusome-cunone

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数
- **collection_layer**: db-interactive-cmd
- **collection_method**: `分析计划主要耗时在Cstore Scan。Cstore Scan的详细信息中，每个DN扫描出2w左右的数据，但是扫描了有数据的CU（CUSome）155079个，没有数据的CU（CUNone）156375个`
- **abnormal_patterns**: ["`说明当前小CU、未命中数据的CU极多，即CU膨胀严重。`"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-column-cu-bloat-01"]

## check_id: chk-explain-scan-vs

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数
- **collection_layer**: db-interactive-cmd
- **collection_method**: `某业务SQL总执行时间2.519s，其中Scan占了2.516s，同时该表的扫描最终只扫描到0条符合条件数据，过滤了20480条数据`
- **abnormal_patterns**: ["`扫描时间与扫描数据量严重不符，此现象可判断为由于脏数据多从而影响扫描和I/O效率。`"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-dirty-data-bloat-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 表脏页率
- **collection_layer**: db-system-view
- **collection_method**: `查看表脏页率为99%，VACUUM FULL后性能优化到100ms左右。`
- **abnormal_patterns**: ["= 99%"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-dirty-data-bloat-01"]

## check_id: chk-explain-scan-a-time-max-min-dn

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比
- **collection_layer**: db-interactive-cmd
- **collection_method**: `表Scan的A-time中，max time DN执行耗时6554ms，min time DN耗时0s，DN之间扫描差异超过10倍以上`
- **abnormal_patterns**: ["> 10倍"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-data-skew-01"]

## check_id: chk-table-distribution-dn

- **type**: metric
- **metric_name**: table_distribution 各DN数据行数
- **collection_layer**: db-system-view
- **collection_method**: `通过table_distribution发现所有数据倾斜到了dn_6009单个DN`
- **abnormal_patterns**: ["`通过table_distribution发现所有数据倾斜到了dn_6009单个DN`"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-data-skew-01"]

## check_id: chk-explain-seq-scan-vs-index-scan

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan）
- **collection_layer**: db-interactive-cmd
- **collection_method**: `Seq Scan扫描需要3767ms，因涉及从4096000条数据中获取8240条数据，符合索引扫描的场景（海量数据中寻找少量数据），在对过滤条件列增加索引后，计划依然是Seq Scan而没有走Index Scan。`
- **abnormal_patterns**: ["`计划依然是Seq Scan而没有走Index Scan。`"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-no-index-or-index-miss-01"]

## check_id: chk-explain-selected-partitions

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 · Selected Partitions 数量
- **collection_layer**: db-interactive-cmd
- **collection_method**: `对该表设计为分区表后没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms，I/O效率极低。`
- **abnormal_patterns**: ["`没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms`"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-no-partition-pruning-01"]

## check_id: chk-pgxc-thread-wait-status-wait-status-wait-event

- **type**: metric
- **metric_name**: pgxc_thread_wait_status · wait_status / wait_event
- **collection_layer**: db-system-view
- **collection_method**: `SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_status <> 'synchronize quit' AND wait_status <> 'none'  GROUP BY 1,2 ORDER BY 3 DESC limit 50;`
- **abnormal_patterns**: ["`后台查看等待视图有大量wait wal sync和WALWriteLock状态，均为xlog同步状态。`"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-large-index-import-01"]

## check_id: chk-pg-partition

- **type**: metric
- **metric_name**: pg_partition 各表分区数
- **collection_layer**: db-system-view
- **collection_method**: `SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition GROUP BY parentid ) s ON c.oid = s.parentid ORDER BY partcount DESC;`
- **abnormal_patterns**: ["> 3000分区"]
- **linked_case_ids**: ["gaussdb-dws-disk-io-saturation-small-files-iops-01"]

## check_id: chk-pv-total-memory-detail-process-used-memory-vs-max-process-me

- **type**: metric
- **metric_name**: pv_total_memory_detail · process_used_memory vs max_process_memory
- **collection_layer**: db-system-view
- **collection_method**: `pv_total_memory_detail`
- **abnormal_patterns**: ["\"可比较process_used_memory和max_process_memory的关系，如前者明显小于后者，则说明占用内存大的语句已经跑完或者被杀掉，当前系"]
- **linked_case_ids**: ["gaussdb-dws-memory-pressure-high-mem-query-01"]

## check_id: chk-pgxc-lock-conflicts-8-1-x

- **type**: metric
- **metric_name**: pgxc_lock_conflicts 锁冲突（8.1.x及以上）
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_lock_conflicts;`
- **abnormal_patterns**: ["\"在查询结果中查看granted字段为\\\"f\\\"，表示VACUUM FULL语句正在等待其他锁。granted字段为\\\"t\\\"，表示INSERT语句是持有锁。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-vacuum-lock-wait-01"]

## check_id: chk-pgxc-stat-activity-vacuum-full-8-0-x

- **type**: metric
- **metric_name**: pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前）
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-vacuum-lock-wait-01"]

## check_id: chk-pgxc-thread-wait-status

- **type**: metric
- **metric_name**: pgxc_thread_wait_status 锁等待状态
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_thread_wait_status WHERE query_id = {query_id};`
- **abnormal_patterns**: ["\"查询结果中\\\"wait_status\\\"存在\\\"acquire lock\\\"表示存在锁等待。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-vacuum-lock-wait-01"]

## check_id: chk-pck

- **type**: metric
- **metric_name**: 表定义是否存在PCK
- **collection_layer**: db-shell
- **collection_method**: `SELECT * FROM pg_get_tabledef('table name');`
- **abnormal_patterns**: ["\"回显中存在\\\"PARTIAL CLUSTER KEY\\\"信息，表示存在PCK。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-vacuum-pck-sort-01"]

## check_id: chk-psort-work-mem

- **type**: metric
- **metric_name**: psort_work_mem 参数值
- **collection_layer**: db-shell
- **collection_method**: `show psort_work_mem;`
- **abnormal_patterns**: ["\"查看psort_work_mem是否设置过小\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-vacuum-pck-sort-01"]

## check_id: chk-

- **type**: metric
- **metric_name**: 列存表文件大小监控
- **collection_layer**: db-system-view
- **collection_method**: "列存表数据按列存储，一列的每60000行存储为一个CU，同一列的CU连续存储在一个文件中，当该文件大于1GB时，切换到新文件中。CU文件数据不能更改只能追加写。"
- **abnormal_patterns**: ["\"列存表多次执行INSERT后，发现表膨胀。\""]
- **linked_case_ids**: ["gaussdb-dws-disk-space-columnar-table-bloat-01"]

## check_id: chk-abort-transaction-due-to-concurrent-update

- **type**: metric
- **metric_name**: 数据库错误日志 · abort transaction due to concurrent update
- **collection_layer**: log-grep
- **collection_method**: NULL
- **abnormal_patterns**: ["\"并发更新同一条记录发生冲突不会等待锁，直接报错：abort transaction due to concurrent update\""]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-concurrent-update-01"]

## check_id: chk-kernel-boot-cmdline-nohz-off

- **type**: parameter-current-value
- **param_name**: kernel boot cmdline `nohz=off`
- **recommended_values**: []
- **violation_patterns**: ["显式设了 nohz=off · 或某些 OS 默认 off(原文示例 Euler:nohz=off)"]
- **linked_case_ids**: ["kunpeng-nohz-clock-tick-overhead-03"]

## check_id: chk-linux-kernel-page-size

- **type**: parameter-current-value
- **param_name**: Linux kernel `Page size` 编译选项
- **recommended_values**: []
- **violation_patterns**: ["4K(默认)"]
- **linked_case_ids**: ["kunpeng-tlb-miss-page-size-04"]

## check_id: chk-mysql-innodb-thread-concurrency-nginx-worker-processes

- **type**: parameter-current-value
- **param_name**: MySQL `innodb_thread_concurrency` / Nginx `worker_processes` / 其他应用并发设置
- **recommended_values**: []
- **violation_patterns**: ["设置过大,超过最佳并发拐点"]
- **linked_case_ids**: ["kunpeng-thread-concurrency-overload-05"]

## check_id: chk-mount-options-noatime

- **type**: parameter-current-value
- **param_name**: mount.options.noatime
- **recommended_values**: []
- **violation_patterns**: ["`noatime not in mount options`"]
- **linked_case_ids**: ["mongo-fs-mount-noatime-nobarrier-missing-01"]

## check_id: chk-mount-options-nobarrier

- **type**: parameter-current-value
- **param_name**: mount.options.nobarrier
- **recommended_values**: []
- **violation_patterns**: ["`nobarrier not in mount options (XFS only) AND storage backend has battery-backed cache (RAID/Flash)`"]
- **linked_case_ids**: ["mongo-fs-mount-noatime-nobarrier-missing-01"]

## check_id: chk-net-ipv4-tcp-max-syn-backlog

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_max_syn_backlog
- **recommended_values**: []
- **violation_patterns**: ["`current = 2048 (default) < 8192 (recommended)`","`current = 1024 (default) < 8192 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01","mongo-client-os-tcp-tuning-01"]

## check_id: chk-net-core-somaxconn

- **type**: parameter-current-value
- **param_name**: net.core.somaxconn
- **recommended_values**: []
- **violation_patterns**: ["`current = 128 (default) < 1024 (recommended)`","`current = 128 (default) < 65535 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01","mongo-client-os-tcp-tuning-01"]

## check_id: chk-net-core-rmem-max

- **type**: parameter-current-value
- **param_name**: net.core.rmem_max
- **recommended_values**: []
- **violation_patterns**: ["`current = 229376 (default) < 16777216 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01"]

## check_id: chk-net-core-wmem-max

- **type**: parameter-current-value
- **param_name**: net.core.wmem_max
- **recommended_values**: []
- **violation_patterns**: ["`current = 229376 (default) < 16777216 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01"]

## check_id: chk-net-ipv4-tcp-rmem

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_rmem
- **recommended_values**: []
- **violation_patterns**: ["`current = \"4096 87380 6291456\" (default) · 第三值 < 16777216 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01"]

## check_id: chk-net-ipv4-tcp-wmem

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_wmem
- **recommended_values**: []
- **violation_patterns**: ["`current = \"4096 16384 4194304\" (default) · 第三值 < 16777216 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01"]

## check_id: chk-net-ipv4-tcp-max-tw-buckets

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_max_tw_buckets
- **recommended_values**: []
- **violation_patterns**: ["`current = 262144 (default) < 360000 (recommended)`","`current = 180000 (default) ≠ 3000 (recommended for client)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01","mongo-client-os-tcp-tuning-01"]

## check_id: chk-net-ipv4-ip-local-port-range

- **type**: parameter-current-value
- **param_name**: net.ipv4.ip_local_port_range
- **recommended_values**: []
- **violation_patterns**: ["`range narrower than \"1024 65535\"`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]

## check_id: chk-net-ipv4-tcp-tw-reuse

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_tw_reuse
- **recommended_values**: []
- **violation_patterns**: ["`current = 0 (closed) ≠ 1 (recommended)`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]

## check_id: chk-net-core-netdev-max-backlog

- **type**: parameter-current-value
- **param_name**: net.core.netdev_max_backlog
- **recommended_values**: []
- **violation_patterns**: ["`current < 8096 (recommended)`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]

## check_id: chk-net-ipv4-tcp-keepalive-time

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_keepalive_time
- **recommended_values**: []
- **violation_patterns**: ["`current = 7200 (default 2h) ≠ 600 (recommended)`","默认 7200(2 小时),远大于云 LB 空闲超时","默认 7200,EC2 ELB/NLB 切连接"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01","mongo-network-tcp-keepalive-too-long-cloud-lb-drops-02","mongo-aws-ec2-storage-network-tuning-06"]

## check_id: chk-net-ipv4-tcp-fin-timeout

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_fin_timeout
- **recommended_values**: []
- **violation_patterns**: ["`current = 0 (closed quick recycle) ≠ 30 (recommended)`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]

## check_id: chk-bios-advanced-misc-config-support-smmu

- **type**: parameter-current-value
- **param_name**: bios.advanced.misc_config.support_smmu
- **recommended_values**: []
- **violation_patterns**: ["`current = \"Enable\" AND scenario = non-virtualization`"]
- **linked_case_ids**: ["kunpeng-bios-smmu-enabled-non-virt-01"]

## check_id: chk-bios-advanced-misc-config-cpu-prefetching-configuration

- **type**: parameter-current-value
- **param_name**: bios.advanced.misc_config.cpu_prefetching_configuration
- **recommended_values**: []
- **violation_patterns**: ["`current = \"Enabled\" (default)`"]
- **linked_case_ids**: ["kunpeng-bios-cpu-prefetch-enabled-01"]

## check_id: chk-systemd-unit-irqbalance-service

- **type**: parameter-current-value
- **param_name**: systemd.unit.irqbalance.service
- **recommended_values**: []
- **violation_patterns**: ["`state = active (running)`"]
- **linked_case_ids**: ["kunpeng-net-irq-not-bound-irqbalance-on-01"]

## check_id: chk-proc-irq-n-smp-affinity-list

- **type**: parameter-current-value
- **param_name**: proc.irq.<N>.smp_affinity_list
- **recommended_values**: []
- **violation_patterns**: ["`smp_affinity_list NOT on NIC local NUMA cores`"]
- **linked_case_ids**: ["kunpeng-net-irq-not-bound-irqbalance-on-01"]

## check_id: chk-sys-block-device-queue-nr-requests

- **type**: parameter-current-value
- **param_name**: /sys/block/${device}/queue/nr_requests
- **recommended_values**: []
- **violation_patterns**: ["`current < 2048 (most distros default = 128/256)`"]
- **linked_case_ids**: ["linux-blockdev-nr-requests-too-low-01"]

## check_id: chk-libvirt-domain-cputune-vcpupin

- **type**: parameter-current-value
- **param_name**: libvirt.domain.cputune.vcpupin
- **recommended_values**: []
- **violation_patterns**: ["`<vcpupin> 节点缺失`"]
- **linked_case_ids**: ["kvm-vcpupin-not-bound-numa-cross-01"]

## check_id: chk-grub-linux-default-hugepagesz

- **type**: parameter-current-value
- **param_name**: grub.linux.default_hugepagesz
- **recommended_values**: []
- **violation_patterns**: ["`kernel cmdline NOT contain \"default_hugepagesz\" AND HugePages_Total = 0`"]
- **linked_case_ids**: ["kvm-host-hugepages-not-allocated-tlb-miss-01"]

## check_id: chk-libvirt-domain-memorybacking-hugepages

- **type**: parameter-current-value
- **param_name**: libvirt.domain.memoryBacking.hugepages
- **recommended_values**: []
- **violation_patterns**: ["`domain xml does NOT contain <hugepages/>`"]
- **linked_case_ids**: ["kvm-host-hugepages-not-allocated-tlb-miss-01"]

## check_id: chk-numactl-c-sched-setaffinity-worker-cpu-affinity

- **type**: parameter-current-value
- **param_name**: (非操作系统参数,而是**应用启动方式**或**应用配置**)`numactl -C` / `sched_setaffinity` / 应用配置中的 worker_cpu_affinity
- **recommended_values**: []
- **violation_patterns**: ["默认不绑定核 → 调度器自由迁移线程 → 跨 NUMA 内存访问"]
- **linked_case_ids**: ["kunpeng-numa-cross-node-memory-access-01"]

## check_id: chk-proc-irq-irq-smp-affinity-list

- **type**: parameter-current-value
- **param_name**: /proc/irq/$irq/smp_affinity_list
- **recommended_values**: []
- **violation_patterns**: ["默认未显式绑定 → 继承 irqbalance 自由分发结果"]
- **linked_case_ids**: ["kunpeng-network-irq-cross-numa-01"]

## check_id: chk-ethtool-c-eth-adaptive-rx-adaptive-tx

- **type**: parameter-current-value
- **param_name**: ethtool -C $eth adaptive-rx / adaptive-tx
- **recommended_values**: []
- **violation_patterns**: ["adaptive-rx=on / adaptive-tx=on (默认)"]
- **linked_case_ids**: ["linux-nic-interrupt-coalescing-audit-01"]

## check_id: chk-ethtool-c-eth-rx-usecs-tx-usecs-rx-frames-tx-frames

- **type**: parameter-current-value
- **param_name**: ethtool -C $eth rx-usecs / tx-usecs / rx-frames / tx-frames
- **recommended_values**: []
- **violation_patterns**: ["N 取过大值"]
- **linked_case_ids**: ["linux-nic-interrupt-coalescing-audit-01"]

## check_id: chk-sys-class-net-nic-queues-rx-0-rps-cpus

- **type**: parameter-current-value
- **param_name**: /sys/class/net/$nic/queues/rx-0/rps_cpus
- **recommended_values**: []
- **violation_patterns**: ["0（默认值，全 0 bitmask 表示未启用 RPS）"]
- **linked_case_ids**: ["linux-rps-single-queue-nic-softirq-bottleneck-01"]

## check_id: chk-sys-class-net-nic-queues-rx-0-rps-flow-cnt-proc-sys-net-core

- **type**: parameter-current-value
- **param_name**: /sys/class/net/$nic/queues/rx-0/rps_flow_cnt + /proc/sys/net/core/rps_sock_flow_entries
- **recommended_values**: []
- **violation_patterns**: ["都为 0（默认）"]
- **linked_case_ids**: ["linux-rps-single-queue-nic-softirq-bottleneck-01"]

## check_id: chk-proc-sys-vm-dirty-expire-centisecs

- **type**: parameter-current-value
- **param_name**: /proc/sys/vm/dirty_expire_centisecs
- **recommended_values**: []
- **violation_patterns**: ["默认 3000（30s）— 写入连续场景"]
- **linked_case_ids**: ["linux-vm-dirty-flush-burst-io-wait-01"]

## check_id: chk-proc-sys-vm-dirty-background-ratio

- **type**: parameter-current-value
- **param_name**: /proc/sys/vm/dirty_background_ratio
- **recommended_values**: []
- **violation_patterns**: ["默认 10 — 写入为主业务可调小"]
- **linked_case_ids**: ["linux-vm-dirty-flush-burst-io-wait-01"]

## check_id: chk-proc-sys-vm-dirty-ratio

- **type**: parameter-current-value
- **param_name**: /proc/sys/vm/dirty_ratio
- **recommended_values**: []
- **violation_patterns**: ["默认 40 — 写入为主业务可适当增大"]
- **linked_case_ids**: ["linux-vm-dirty-flush-burst-io-wait-01"]

## check_id: chk-sys-block-device-name-queue-scheduler

- **type**: parameter-current-value
- **param_name**: /sys/block/$DEVICE-NAME/queue/scheduler
- **recommended_values**: []
- **violation_patterns**: ["cfq（默认）∧ 磁盘类型=HDD ∧ 业务=数据库/大数据（I/O 集中型）","cfq / deadline ∧ 磁盘类型=SSD"]
- **linked_case_ids**: ["linux-block-scheduler-mismatch-01"]

## check_id: chk-mount-option-barrier-nobarrier

- **type**: parameter-current-value
- **param_name**: mount option · barrier / nobarrier
- **recommended_values**: []
- **violation_patterns**: ["barrier (默认) ∧ RAID 有电池保护"]
- **linked_case_ids**: ["linux-fs-mount-nobarrier-audit-01"]

## check_id: chk-filesystem-type-mkfs-xfs-vs-mkfs-ext4

- **type**: parameter-current-value
- **param_name**: filesystem type (mkfs.xfs vs mkfs.ext4)
- **recommended_values**: []
- **violation_patterns**: ["ext4 / 其他 ∧ workload=大文件"]
- **linked_case_ids**: ["linux-fs-xfs-blocksize-audit-01"]

## check_id: chk-mkfs-xfs-b-size

- **type**: parameter-current-value
- **param_name**: mkfs.xfs -b size=
- **recommended_values**: []
- **violation_patterns**: ["4096 (默认) ∧ workload=大文件"]
- **linked_case_ids**: ["linux-fs-xfs-blocksize-audit-01"]

## check_id: chk-vm-dirty-ratio-vm-dirty-background-ratio

- **type**: parameter-current-value
- **param_name**: vm.dirty_ratio / vm.dirty_background_ratio
- **recommended_values**: []
- **violation_patterns**: ["dirty_ratio = 20-30(默认) · dirty_background_ratio = 10-15(默认)"]
- **linked_case_ids**: ["linux-vm-dirty-ratio-pause-on-large-memory-01"]

## check_id: chk-kernel-transparent-hugepage

- **type**: parameter-current-value
- **param_name**: kernel.transparent_hugepage
- **recommended_values**: []
- **violation_patterns**: ["always 或 madvise(非 never)","never · 但 mongod 是 8.0+"]
- **linked_case_ids**: ["linux-thp-mongodb-sparse-memory-access-02","mongo-8-0-tcmalloc-percpu-prerequisite-not-met-01"]

## check_id: chk-block-device-queue-read-ahead-kb-udev-attr-bdi-read-ahead-kb

- **type**: parameter-current-value
- **param_name**: block device queue/read_ahead_kb(udev ATTR{bdi/read_ahead_kb})
- **recommended_values**: []
- **violation_patterns**: ["默认 128(=256 扇区),建议 16(=32 扇区)"]
- **linked_case_ids**: ["linux-readahead-default-128kb-wastes-fs-cache-04"]

## check_id: chk-wiredtiger-engineconfig-memory-page-max

- **type**: parameter-current-value
- **param_name**: wiredTiger.engineConfig.memory_page_max(诊断专用 · 实际生产不应调)
- **recommended_values**: []
- **violation_patterns**: ["设到接近 1GB(诊断时为复现单次大停顿设的)"]
- **linked_case_ids**: ["mongo-wt-large-page-eviction-fetch-pause-server-16479"]

## check_id: chk-storage-wiredtiger-engineconfig-cachesizegb

- **type**: parameter-current-value
- **param_name**: storage.wiredTiger.engineConfig.cacheSizeGB
- **recommended_values**: []
- **violation_patterns**: ["cache 容纳了几乎一棵完整 b-tree;sweep 时整树一次性驱逐"]
- **linked_case_ids**: ["mongo-wt-btree-sweep-eviction-collection-blocked-server-17907"]

## check_id: chk-tcmalloc-aggressive-decommit

- **type**: parameter-current-value
- **param_name**: TCMALLOC_AGGRESSIVE_DECOMMIT(环境变量 / 启动参数)
- **recommended_values**: []
- **violation_patterns**: ["未启用(默认),pageheap_free_bytes 不主动归还 OS"]
- **linked_case_ids**: ["mongo-tcmalloc-heap-fragmentation-pageheap-free-server-33296"]

## check_id: chk-wiredtiger-cache-eviction-updates-trigger-eviction-updates-t

- **type**: parameter-current-value
- **param_name**: wiredTiger.cache.eviction_updates_trigger / eviction_updates_target
- **recommended_values**: []
- **violation_patterns**: ["默认 trigger=10%(eviction_dirty_trigger/2),target=2.5%(eviction_dirty_target/2);若与 workload 不匹配会过早 eviction 或不够 eviction"]
- **linked_case_ids**: ["mongo-wt-tcmalloc-fragmentation-durable-history-wt-6175"]

## check_id: chk-wiredtigerengineruntimeconfig-checkpoint-wait-log-size

- **type**: parameter-current-value
- **param_name**: wiredTigerEngineRuntimeConfig.checkpoint.wait / log_size
- **recommended_values**: []
- **violation_patterns**: ["\"默认 wait=60s, log_size=2GB\""]
- **linked_case_ids**: ["mongo-wt-checkpoint-period-tuning-disk-io-spike-02"]

## check_id: chk-eviction-trigger

- **type**: parameter-current-value
- **param_name**: eviction_trigger
- **recommended_values**: []
- **violation_patterns**: ["默认 95% · 业务峰值下 worker 来不及消化 → 应调低 trigger 给 worker 更多缓冲"]
- **linked_case_ids**: ["wt-eviction-trigger-app-thread-throttle-01"]

## check_id: chk-innodb-thread-concurrency-mysql-worker-processes-nginx

- **type**: parameter-current-value
- **param_name**: innodb_thread_concurrency (MySQL) / worker_processes (Nginx) / 应用自有并发参数
- **recommended_values**: []
- **violation_patterns**: ["高于\"针对不同业务模型多组测试找出的最佳并发数\""]
- **linked_case_ids**: ["app-thread-concurrency-mismatch-01"]

## check_id: chk-worker-processes

- **type**: parameter-current-value
- **param_name**: worker_processes
- **recommended_values**: []
- **violation_patterns**: ["超过 CPU core 数或业务最佳并发值"]
- **linked_case_ids**: ["app-thread-concurrency-mismatch-01"]

## check_id: chk-linker-flags-ljemalloc-l-jemalloc-config-libdir

- **type**: parameter-current-value
- **param_name**: linker flags · -ljemalloc + -L`jemalloc-config --libdir`
- **recommended_values**: []
- **violation_patterns**: ["链接默认 glibc malloc（编译选项中无 -ljemalloc）"]
- **linked_case_ids**: ["app-malloc-jemalloc-multithread-audit-01"]

## check_id: chk-malloc-lib-my-cnf

- **type**: parameter-current-value
- **param_name**: malloc-lib (my.cnf) 或类似配置
- **recommended_values**: []
- **violation_patterns**: ["malloc-lib 未设置 / 设置为非 jemalloc"]
- **linked_case_ids**: ["app-malloc-jemalloc-multithread-audit-01"]

## check_id: chk-slowopthresholdms-atlas-managed-dynamic-fixed-100ms

- **type**: parameter-current-value
- **param_name**: slowOpThresholdMs (Atlas-managed dynamic / fixed 100ms)
- **recommended_values**: []
- **violation_patterns**: ["阈值过高时漏报慢查询;过低时 Profiler 写入开销大"]
- **linked_case_ids**: ["mongo-slow-query-profiler-metric-01"]

## check_id: chk-maxincomingconnections-ulimit-n

- **type**: parameter-current-value
- **param_name**: maxIncomingConnections / ulimit -n
- **recommended_values**: []
- **violation_patterns**: ["maxIncomingConnections < 业务峰值;ulimit -n < maxIncomingConnections"]
- **linked_case_ids**: ["mongo-connection-storm-driver-error-02"]

## check_id: chk-storageengineconcurrentreadtransactions-storageengineconcurr

- **type**: parameter-current-value
- **param_name**: storageEngineConcurrentReadTransactions / storageEngineConcurrentWriteTransactions
- **recommended_values**: []
- **violation_patterns**: ["7.0+ 已禁用动态调整 或 手动设到 < 业务并发需求"]
- **linked_case_ids**: ["mongo-wt-tickets-exhausted-01"]

## check_id: chk-maxpoolsize

- **type**: parameter-current-value
- **param_name**: maxPoolSize
- **recommended_values**: []
- **violation_patterns**: ["< 1.10 × 应用层典型并发请求数","小于应用层活跃线程数 / 实际并发需求","远大于服务端可承载并发,或应用线程数远大于实际需要"]
- **linked_case_ids**: ["mongo-driver-pool-size-too-small-vs-concurrent-requests-02","mongo-pool-maxpoolsize-too-low-underutilized-04","mongo-pool-maxpoolsize-too-high-cpu-pressure-05"]

## check_id: chk-deployment-dbpath

- **type**: parameter-current-value
- **param_name**: (deployment) dbPath 挂载点文件系统
- **recommended_values**: []
- **violation_patterns**: ["NFS / NFSv4","ext4(配 storage.engine=wiredTiger)"]
- **linked_case_ids**: ["mongo-fs-nfs-dbpath-degraded-unstable-perf-01","mongo-fs-ext4-wiredtiger-perf-issue-should-use-xfs-02"]

## check_id: chk-tuned-profile

- **type**: parameter-current-value
- **param_name**: tuned profile
- **recommended_values**: []
- **violation_patterns**: ["出厂默认未做 MongoDB 适配(THP / readahead / scheduler 等)"]
- **linked_case_ids**: ["mongo-tuned-profile-default-rhel-perf-impact-05"]

## check_id: chk-numactl-interleave-all-mongod

- **type**: parameter-current-value
- **param_name**: numactl --interleave=all (启动 mongod 时)
- **recommended_values**: []
- **violation_patterns**: ["直接 `mongod` 启动 · 未走 numactl interleave"]
- **linked_case_ids**: ["mongo-numa-cross-node-memory-degradation-04"]

## check_id: chk-vm-swappiness

- **type**: parameter-current-value
- **param_name**: vm.swappiness
- **recommended_values**: []
- **violation_patterns**: ["默认 60"]
- **linked_case_ids**: ["mongo-os-vm-swappiness-default-60-aggressive-swap-05"]

## check_id: chk-glibc-tunables-env

- **type**: parameter-current-value
- **param_name**: GLIBC_TUNABLES (env)
- **recommended_values**: []
- **violation_patterns**: ["未设 glibc.pthread.rseq=0 → glibc 抢先注册 rseq"]
- **linked_case_ids**: ["mongo-tcmalloc-percpu-caches-not-enabled-01"]

## check_id: chk-defaultwriteconcern-w-write-concern

- **type**: parameter-current-value
- **param_name**: defaultWriteConcern.w(及业务调用侧 write concern)
- **recommended_values**: []
- **violation_patterns**: ["`\"majority\"` 同时 secondary 不健康(写卡);或 < majority(读 stale)"]
- **linked_case_ids**: ["mongo-psa-majority-writeconcern-perf-degradation-01"]

## check_id: chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct

- **type**: parameter-current-value
- **param_name**: storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct
- **recommended_values**: []
- **violation_patterns**: ["超过 \"50% of (RAM - 1GB)\" 默认基线 · 原文允许上限 80%"]
- **linked_case_ids**: ["mongo-wt-cache-size-misconfigured-01"]

## check_id: chk-connecttimeoutms

- **type**: parameter-current-value
- **param_name**: connectTimeoutMS
- **recommended_values**: []
- **violation_patterns**: ["< (副本集任一成员到 client 的网络延迟)"]
- **linked_case_ids**: ["mongo-pool-connect-timeout-too-large-01"]

## check_id: chk-sockettimeoutms

- **type**: parameter-current-value
- **param_name**: socketTimeoutMS
- **recommended_values**: []
- **violation_patterns**: ["未设 / 远大于业务最慢操作耗时"]
- **linked_case_ids**: ["mongo-pool-socket-timeout-firewall-half-close-02"]

## check_id: chk-minpoolsize

- **type**: parameter-current-value
- **param_name**: minPoolSize
- **recommended_values**: []
- **violation_patterns**: ["远小于启动期实际并发数"]
- **linked_case_ids**: ["mongo-pool-minpoolsize-too-low-startup-creating-conns-03"]

## check_id: chk-operationprofiling-slowopthresholdms-db-setprofilinglevel-sl

- **type**: parameter-current-value
- **param_name**: operationProfiling.slowOpThresholdMs / db.setProfilingLevel slowms
- **recommended_values**: []
- **violation_patterns**: ["默认 100ms · 业务期望更紧或更宽"]
- **linked_case_ids**: ["mongo-profiler-threshold-sampling-audit-01"]

## check_id: chk-operationprofiling-slowopsamplerate-setprofilinglevel-sample

- **type**: parameter-current-value
- **param_name**: operationProfiling.slowOpSampleRate / setProfilingLevel sampleRate
- **recommended_values**: []
- **violation_patterns**: ["sampleRate == 1.0 + profiling level 1 + 高 QPS → 写 system.profile 占比拉升"]
- **linked_case_ids**: ["mongo-profiler-threshold-sampling-audit-01"]

## check_id: chk-kernel-transparent-hugepage-enabled-systemd-init-d-kernel-bo

- **type**: parameter-current-value
- **param_name**: kernel transparent_hugepage/enabled(可通过 systemd / init.d / kernel boot param 启用)
- **recommended_values**: []
- **violation_patterns**: ["never 或 madvise(对 MongoDB 8.0+ 新 TCMalloc 不优化)"]
- **linked_case_ids**: ["mongo-8x-thp-disabled-tcmalloc-suboptimal-01"]

## check_id: chk-writeconcernmajorityjournaldefault-writeconcern

- **type**: parameter-current-value
- **param_name**: writeConcernMajorityJournalDefault / 应用层 writeConcern
- **recommended_values**: []
- **violation_patterns**: ["unacknowledged / w:1(未要求多数节点确认)"]
- **linked_case_ids**: ["mongo-replica-set-replication-lag-01"]

## check_id: chk-flowcontroltargetlagseconds

- **type**: parameter-current-value
- **param_name**: flowControlTargetLagSeconds
- **recommended_values**: []
- **violation_patterns**: ["默认值偏宽 / 业务期望更紧的延迟容忍度"]
- **linked_case_ids**: ["mongo-replica-set-replication-lag-01"]

## check_id: chk-internalqueryframeworkcontrol

- **type**: parameter-current-value
- **param_name**: internalQueryFrameworkControl
- **recommended_values**: []
- **violation_patterns**: ["(默认 trySbeEngine,在 7.0 上触发 SBE plan cache 不稳定 hash bug)"]
- **linked_case_ids**: ["mongo-plancache-bloat-sbe-7-0-oom-kills-01"]

## check_id: chk-sharding-chunk-size-64mb-25

- **type**: parameter-current-value
- **param_name**: sharding chunk size(默认 64MB)/ 25 万文档上限
- **recommended_values**: []
- **violation_patterns**: ["单 chunk 实际大小或文档数超出此阈值"]
- **linked_case_ids**: ["mongo-sharding-jumbo-chunk-uneven-write-load-01"]

## check_id: chk-replsets-storage-wiredtiger-engineconfig-cachesizeratio-cont

- **type**: parameter-current-value
- **param_name**: replsets.storage.wiredTiger.engineConfig.cacheSizeRatio + container resources.limits.memory
- **recommended_values**: []
- **violation_patterns**: ["cacheSizeRatio=0.5 默认 + memlimit ≤ 1G → 触发 minWiredTigerCacheSizeGB(256MB) 回退"]
- **linked_case_ids**: ["mongo-k8s-container-wt-cache-fallback-256mb-01"]

## check_id: chk-defaultwriteconcern-w

- **type**: parameter-current-value
- **param_name**: defaultWriteConcern.w
- **recommended_values**: []
- **violation_patterns**: ["5.0+ 默认 \"majority\"(对比 4.4 默认 1)"]
- **linked_case_ids**: ["mongo-write-regression-default-writeconcern-majority-journal-01"]

## check_id: chk-replicaset-config-writeconcernmajorityjournaldefault

- **type**: parameter-current-value
- **param_name**: replicaSet.config.writeConcernMajorityJournalDefault
- **recommended_values**: []
- **violation_patterns**: ["true(默认)"]
- **linked_case_ids**: ["mongo-write-regression-default-writeconcern-majority-journal-01"]

## check_id: chk-wiredtigerengineruntimeconfig-eviction-dirty-trigger-evictio

- **type**: parameter-current-value
- **param_name**: wiredTigerEngineRuntimeConfig.eviction_dirty_trigger / eviction_dirty_target
- **recommended_values**: []
- **violation_patterns**: ["dirty_trigger 默认 20% · dirty_target 默认 5% · 256GB cache 时 1% 即 2.56GB"]
- **linked_case_ids**: ["mongo-wt-checkpoint-time-grows-bulk-load-stall-01"]

## check_id: chk-wiredtigerengineruntimeconfig-eviction-threads-min-threads-m

- **type**: parameter-current-value
- **param_name**: wiredTigerEngineRuntimeConfig.eviction.threads_min / threads_max
- **recommended_values**: []
- **violation_patterns**: ["默认 threads_min=threads_max=4,bulk-load 下不足"]
- **linked_case_ids**: ["mongo-wt-checkpoint-time-grows-bulk-load-stall-01"]

## check_id: chk-shared-buffers

- **type**: parameter-current-value
- **param_name**: shared_buffers
- **recommended_values**: ["8GB"]
- **violation_patterns**: ["设值过小","设置过小（32M）","设置过小（示例为32MB）"]
- **linked_case_ids**: ["gaussdb-memory-shared-buffer-miss-01","gaussdb-dws-table-bloat-vacuum-slow-01","gaussdb-dws-query-slow-table-bloat-01"]
- **rationales**: ["\"共享缓存区不足，导致SQL的buffer命中率低\"","\"内存参数设置不合理\""]

## check_id: chk-work-mem

- **type**: parameter-current-value
- **param_name**: work_mem
- **recommended_values**: ["128MB"]
- **violation_patterns**: ["设值过小，不足以容纳算子运算数据","设置偏小（64M）","设置过小（CN/DN均为64MB）"]
- **linked_case_ids**: ["gaussdb-memory-work-mem-spill-01","gaussdb-dws-table-bloat-vacuum-slow-01","gaussdb-dws-query-slow-table-bloat-01"]
- **rationales**: ["\"如果work_mem所限定的物理内存不够，算子运算的数据将被写入临时表空间，会带来5-10倍的性能下降。\""]

## check_id: chk-rewrite-rule

- **type**: parameter-current-value
- **param_name**: rewrite_rule
- **recommended_values**: ["partialpush","intargetlist","lazyagg","magicset","uniquecheck"]
- **violation_patterns**: ["默认值不含 partialpush，无法对含不可下推函数的语句做部分下推优化","未包含 intargetlist，目标列相关子查询无法被提升转为 JOIN","none（未开启 partialpush）","none（未开启 intargetlist）","未包含lazyagg","未包含magicset","未包含intargetlist","未包含intargetlist（如设为'none'）","未包含uniquecheck"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-rewrite-rule-partialpush-01","gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01","gaussdb-query-slow-no-partial-pushdown-01","gaussdb-query-slow-correlated-subquery-target-list-01","gaussdb-rewrite-lazyagg-double-aggregate-slow-01","gaussdb-rewrite-magicset-correlated-subquery-slow-01","gaussdb-rewrite-v8-intargetlist-subplan-slow-01","gaussdb-rewrite-intargetlist-subplan-slow-01","gaussdb-rewrite-uniquecheck-subquery-join-01"]
- **rationales**: ["`该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`","`导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`","\"由于目标列中的相关子查询无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下\"","\"打开之后报错。ERROR: more than one row returned by a subquery used as an expression（当数据中存在重复时）\""]

## check_id: chk-enable-hashjoin

- **type**: parameter-current-value
- **param_name**: enable_hashjoin
- **recommended_values**: ["off` (当 temp_tsw 仅几百条记录、b_zyk_wbswxx 极大时临时关闭)","off`（在 NestLoop 可利用索引扫描的场景下）"]
- **violation_patterns**: ["默认开启，导致优化器在小表与大表 JOIN 时选择了在大表上建 Hash Table 的计划","on（默认），优化器选择 Hash Join 对大表建 Hash Table"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01","gaussdb-query-slow-complex-join-intermediate-rows-01"]
- **rationales**: ["`发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。`"]

## check_id: chk-enable-nestloop

- **type**: parameter-current-value
- **param_name**: enable_nestloop
- **recommended_values**: ["off` (与 enable_mergejoin=off 配合)","off"]
- **violation_patterns**: ["默认开启，在外表行数较大时导致选择 NestLoop","默认开启，优化器选择了NestLoop","默认on，导致优化器在行数估算偏小时选择NestLoop"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-outer-01","gaussdb-query-slow-nestloop-hashjoin-02","gaussdb-query-slow-nestloop-large-rowset-01"]
- **rationales**: ["\"NestLoop耗时27秒\"","\"如下的例子中NestLoop耗时27秒\""]

## check_id: chk-enable-mergejoin

- **type**: parameter-current-value
- **param_name**: enable_mergejoin
- **recommended_values**: ["off"]
- **violation_patterns**: ["默认开启，干扰优化器选择 HashJoin"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-outer-01"]

## check_id: chk-enable-sort

- **type**: parameter-current-value
- **param_name**: enable_sort
- **recommended_values**: ["off"]
- **violation_patterns**: ["默认开启，大结果集时优化器选择 Sort+GroupAgg","默认开启，导致优化器选择Sort+GroupAgg","默认on，使优化器在某些场景错误选择Sort+GroupAgg"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01","gaussdb-query-slow-groupagg-sort-03","gaussdb-query-slow-sort-groupagg-large-result-01"]
- **rationales**: ["\"Sort+GroupAgg耗时2417ms，HashAgg耗时2324ms\""]

## check_id: chk-recovery-parse-workers

- **type**: parameter-current-value
- **param_name**: recovery_parse_workers
- **recommended_values**: []
- **violation_patterns**: ["未开启极致RTO，回放并行度低"]
- **linked_case_ids**: ["gaussdb-replica-lag-redo-workers-01"]
- **rationales**: ["\"在系统长时间的运行后，备DN上会出现日志累积。当主DN故障后，数据恢复需要很长时间，数据库不可用，严重影响系统可用性。\""]

## check_id: chk-recovery-redo-workers

- **type**: parameter-current-value
- **param_name**: recovery_redo_workers
- **recommended_values**: []
- **violation_patterns**: ["未开启极致RTO，回放并行度低"]
- **linked_case_ids**: ["gaussdb-replica-lag-redo-workers-01"]
- **rationales**: ["\"在系统长时间的运行后，备DN上会出现日志累积。\""]

## check_id: chk-enable-index-nestloop

- **type**: parameter-current-value
- **param_name**: enable_index_nestloop
- **recommended_values**: []
- **violation_patterns**: ["执行计划中错误地选择了 NestLoop"]
- **linked_case_ids**: ["gaussdb-dws-plan-suboptimal-nestloop-perf-jump-hint-01"]
- **rationales**: ["`语句执行时间因为达到了 3600s而自动终止运行，导致影响业务进度。`"]

## check_id: chk-enable-indexscan

- **type**: parameter-current-value
- **param_name**: enable_indexscan
- **recommended_values**: ["off","off` (针对此类查询临时关闭)"]
- **violation_patterns**: ["on（默认开启，允许走索引+NestLoop）","默认开启，导致优化器在行数估算不准时选择 NestLoop+IndexScan"]
- **linked_case_ids**: ["gaussdb-dws-row-estimate-small-nestloop-slow-01","gaussdb-dws-plan-nestloop-row-underestimate-01"]

## check_id: chk-max-process-memory

- **type**: parameter-current-value
- **param_name**: max_process_memory
- **recommended_values**: ["25GB"]
- **violation_patterns**: ["设置过小（12G，节点总内存256G）","设置过小（示例为12GB）"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-vacuum-slow-01","gaussdb-dws-query-slow-table-bloat-01"]
- **rationales**: ["\"内存参数设置不合理\""]

## check_id: chk-qrw-inlist2join-optmode

- **type**: parameter-current-value
- **param_name**: qrw_inlist2join_optmode
- **recommended_values**: ["rule_base"]
- **violation_patterns**: ["cost_base（默认），优化器估算不准时不转化"]
- **linked_case_ids**: ["gaussdb-dws-in-constant-no-join-slow-01"]
- **rationales**: ["\"如果优化器估算不准，可能会出现需要转化的场景没有做转化，导致性能较差。\""]

## check_id: chk-autovacuum

- **type**: parameter-current-value
- **param_name**: autovacuum
- **recommended_values**: ["on"]
- **violation_patterns**: ["未开启（off）"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-autovacuum-01"]
- **rationales**: ["\"用户未开启autovacuum的同时又没有合理的自定义vacuum调度，导致表的脏数据没有及时回收，新的数据又不断插入或更新，膨胀是必然的\""]

## check_id: chk-autovacuum-vacuum-cost-delay

- **type**: parameter-current-value
- **param_name**: autovacuum_vacuum_cost_delay
- **recommended_values**: ["0"]
- **violation_patterns**: ["开启后使用基于成本的回收策略，IO性能高的系统反而变慢"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-autovacuum-01"]
- **rationales**: ["\"开启autovacuum_vacuum_cost_delay后，会使用基于成本的脏数据回收策略...对于IO性能高的系统，开启autovacuum_vacuum_cost_delay反而会使得垃圾回收的时间变长\""]

## check_id: chk-autovacuum-max-workers

- **type**: parameter-current-value
- **param_name**: autovacuum_max_workers
- **recommended_values**: ["10"]
- **violation_patterns**: ["配置过小，超过autovacuum线程数量的表需要等待"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-autovacuum-01"]
- **rationales**: ["\"如果数据库的表很多，而且都比较大，那么当需要vacuum的表超过了配置autovacuum_max_workers的数量，这些表就要等待空闲的autovacuum线程\""]

## check_id: chk-autovacuum-naptime

- **type**: parameter-current-value
- **param_name**: autovacuum_naptime
- **recommended_values**: ["1","20s"]
- **violation_patterns**: ["设置间隔时间过长","默认值过大，autovacuum轮询间隔过长"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-autovacuum-01","gaussdb-dws-query-slow-hstore-delta-bloat-01"]
- **rationales**: ["\"autovacuum_naptime设置间隔时间过长\""]

## check_id: chk-max-active-statements

- **type**: parameter-current-value
- **param_name**: max_active_statements
- **recommended_values**: []
- **violation_patterns**: ["值过小，活跃语句数超过限制"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-max-active-statements-01"]
- **rationales**: ["\"当前的活跃语句数超过max_active_statements限制导致的普通用户排队\""]

## check_id: chk-autovacuum-max-workers-hstore

- **type**: parameter-current-value
- **param_name**: autovacuum_max_workers_hstore
- **recommended_values**: ["3"]
- **violation_patterns**: ["配置过小，MERGE能力不足以消化入库速度"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-hstore-delta-bloat-01"]
- **rationales**: ["\"入库速度不得超过MERGE处理能力。通过控制入库并发防止Delta表膨胀。\""]

## check_id: chk-enable-codegen

- **type**: parameter-current-value
- **param_name**: enable_codegen
- **recommended_values**: ["off"]
- **violation_patterns**: ["默认on，短查询动态生成执行代码申请内存开销大"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-realtime-numa-codegen-01"]

## check_id: chk-enable-numa-bind

- **type**: parameter-current-value
- **param_name**: enable_numa_bind
- **recommended_values**: ["DN取值设置为on，CN取值设置为off"]
- **violation_patterns**: ["DN未开启NUMA绑定，跨numa访问进程开销大"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-realtime-numa-codegen-01"]

## check_id: chk-abnormal-check-general-task

- **type**: parameter-current-value
- **param_name**: abnormal_check_general_task
- **recommended_values**: ["3600"]
- **violation_patterns**: ["默认60s，频繁清理空闲连接导致毫秒级业务受损"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-realtime-numa-codegen-01"]
- **rationales**: ["\"默认值60s的定期清理时间间隔，对毫秒级业务性能影响较大，单个线程重新创建的开销大约需要300ms，有毫秒级性能敏感场景建议调大。\""]

## check_id: chk-resource-track-level

- **type**: parameter-current-value
- **param_name**: resource_track_level
- **recommended_values**: ["operator_realtime`（定位长时间运行SQL时）"]
- **violation_patterns**: ["默认 query 级别，无法显示算子级实时执行进度"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-long-running-operator-01"]
- **rationales**: ["`在作业无排队无死锁正常运行期间，发现作业长时间不结束，此时可查看算子级别的实时TopSQL监控，能够看出哪个算子执行时间长`"]

## check_id: chk-track-activities

- **type**: parameter-current-value
- **param_name**: track_activities
- **recommended_values**: ["on"]
- **violation_patterns**: ["未开启，无法收集当前活动查询运行信息"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-pgxc-stat-activity-01"]

## check_id: chk-connectiontimeout

- **type**: parameter-current-value
- **param_name**: connectionTimeOut
- **recommended_values**: ["600000` (ms，即 10min 或更大)"]
- **violation_patterns**: ["默认值 5min (300000ms)，在大批量写入场景下不足"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-flink-connection-timeout-01"]
- **rationales**: ["`Flink写入DWS报以下错误，此问题一般为SQL执行超时导致。canceling statement due to statement timeout`"]

## check_id: chk-lockwait-timeout

- **type**: parameter-current-value
- **param_name**: lockwait_timeout
- **recommended_values**: []
- **violation_patterns**: ["默认值20分钟，业务并发高时可能需要调整"]
- **linked_case_ids**: ["gaussdb-dws-lock-contention-wait-timeout-01"]
- **rationales**: ["\"当申请的锁等待时间超过GUC参数lockwait_timeout的设定值时，系统会报LOCK_WAIT_TIMEOUT的错误。\""]

## check_id: chk-psort-work-mem

- **type**: parameter-current-value
- **param_name**: psort_work_mem
- **recommended_values**: []
- **violation_patterns**: ["设置过小，导致PCK排序时下盘"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-vacuum-pck-sort-01"]
- **rationales**: ["\"如果表较大或GUC参数psort_work_mem设置较小，会导致PCK排序时产生下盘（数据库选择将临时结果暂存到磁盘），进行外部排序；一旦进行外部排序，时间消耗就会增加很多。\""]

## check_id: chk-enable-delta

- **type**: parameter-current-value
- **param_name**: ENABLE_DELTA
- **recommended_values**: ["ON"]
- **violation_patterns**: ["默认关闭（OFF），小批量INSERT产生大量小CU"]
- **linked_case_ids**: ["gaussdb-dws-disk-space-columnar-table-bloat-01"]
- **rationales**: ["\"列存表多次执行INSERT后，发现表膨胀。\""]
