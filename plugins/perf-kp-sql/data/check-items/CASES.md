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
- **recommended_values**: ["net.ipv4.tcp_max_syn_backlog = 8192"]
- **violation_patterns**: ["`current = 2048 (default) < 8192 (recommended)`","`current = 1024 (default) < 8192 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01","mongo-client-os-tcp-tuning-01"]
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。"]

## check_id: chk-net-core-somaxconn

- **type**: parameter-current-value
- **param_name**: net.core.somaxconn
- **recommended_values**: ["net.core.somaxconn = 65535"]
- **violation_patterns**: ["`current = 128 (default) < 1024 (recommended)`","`current = 128 (default) < 65535 (recommended)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01","mongo-client-os-tcp-tuning-01"]
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。"]

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
- **recommended_values**: ["net.ipv4.tcp_max_tw_buckets = 3000"]
- **violation_patterns**: ["`current = 262144 (default) < 360000 (recommended)`","`current = 180000 (default) ≠ 3000 (recommended for client)`"]
- **linked_case_ids**: ["mongo-os-tcp-stack-tuning-01","mongo-client-os-tcp-tuning-01"]
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。"]

## check_id: chk-net-ipv4-ip-local-port-range

- **type**: parameter-current-value
- **param_name**: net.ipv4.ip_local_port_range
- **recommended_values**: ["net.ipv4.ip_local_port_range = 1024 65530"]
- **violation_patterns**: ["`range narrower than \"1024 65535\"`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]
- **rationales**: ["echo \"net.ipv4.ip_local_port_range = 1024 65530\" | sudo tee -a /etc/sysctl.conf"]

## check_id: chk-net-ipv4-tcp-tw-reuse

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_tw_reuse
- **recommended_values**: ["net.ipv4.tcp_tw_reuse = 1"]
- **violation_patterns**: ["`current = 0 (closed) ≠ 1 (recommended)`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。"]

## check_id: chk-net-core-netdev-max-backlog

- **type**: parameter-current-value
- **param_name**: net.core.netdev_max_backlog
- **recommended_values**: ["net.core.netdev_max_backlog = 8096"]
- **violation_patterns**: ["`current < 8096 (recommended)`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。"]

## check_id: chk-net-ipv4-tcp-keepalive-time

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_keepalive_time
- **recommended_values**: ["net.ipv4.tcp_keepalive_time = 120"]
- **violation_patterns**: ["`current = 7200 (default 2h) ≠ 600 (recommended)`","默认 7200(2 小时),远大于云 LB 空闲超时","默认 7200,EC2 ELB/NLB 切连接"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01","mongo-network-tcp-keepalive-too-long-cloud-lb-drops-02","mongo-aws-ec2-storage-network-tuning-06"]
- **rationales**: ["there is a risk that the system might silently drop connections."]

## check_id: chk-net-ipv4-tcp-fin-timeout

- **type**: parameter-current-value
- **param_name**: net.ipv4.tcp_fin_timeout
- **recommended_values**: ["net.ipv4.tcp_fin_timeout = 30"]
- **violation_patterns**: ["`current = 0 (closed quick recycle) ≠ 30 (recommended)`"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01"]
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。"]

## check_id: chk-bios-advanced-misc-config-support-smmu

- **type**: parameter-current-value
- **param_name**: bios.advanced.misc_config.support_smmu
- **recommended_values**: ["Support Smmu = Disable"]
- **violation_patterns**: ["`current = \"Enable\" AND scenario = non-virtualization`"]
- **linked_case_ids**: ["kunpeng-bios-smmu-enabled-non-virt-01"]
- **rationales**: ["因为数据库通常会使用大量的内存和IO资源，而SMMU会增加额外的开销和延迟"]

## check_id: chk-bios-advanced-misc-config-cpu-prefetching-configuration

- **type**: parameter-current-value
- **param_name**: bios.advanced.misc_config.cpu_prefetching_configuration
- **recommended_values**: ["CPU Prefetching Configuration = Disabled"]
- **violation_patterns**: ["`current = \"Enabled\" (default)`"]
- **linked_case_ids**: ["kunpeng-bios-cpu-prefetch-enabled-01"]
- **rationales**: ["将“CPU Prefetching Configuration”设置为“Disabled”"]

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
- **recommended_values**: ["/sys/block/${device}/queue/nr_requests = 2048"]
- **violation_patterns**: ["`current < 2048 (most distros default = 128/256)`"]
- **linked_case_ids**: ["linux-blockdev-nr-requests-too-low-01"]
- **rationales**: ["echo 2048 > /sys/block/${device}/queue/nr_requests"]

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
- **recommended_values**: ["wiredTigerCacheSizeGB = max(0.5 × (RAM - 1GB), 0.256GB)","--wiredTigerCacheSizeGB or --wiredTigerCacheSizePct < amount of RAM available in the container","storage.wiredTiger.engineConfig.cacheSizeGB decrease to accommodate"]
- **violation_patterns**: ["cache 容纳了几乎一棵完整 b-tree;sweep 时整树一次性驱逐"]
- **linked_case_ids**: ["mongo-wt-btree-sweep-eviction-collection-blocked-server-17907"]
- **rationales**: ["The storage.wiredTiger.engineConfig.cacheSizeGB limits the size of the WiredTiger internal cache. The operating system uses the available free memory for filesystem cache, which allows the compressed ","as WiredTiger may not account for the memory limits of the specific container in certain cases","The default WiredTiger internal cache size value assumes that there is a single mongod instance per machine."]

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
- **recommended_values**: ["connection pool size = 110-115% × typical concurrent database requests"]
- **violation_patterns**: ["< 1.10 × 应用层典型并发请求数","小于应用层活跃线程数 / 实际并发需求","远大于服务端可承载并发,或应用线程数远大于实际需要"]
- **linked_case_ids**: ["mongo-driver-pool-size-too-small-vs-concurrent-requests-02","mongo-pool-maxpoolsize-too-low-underutilized-04","mongo-pool-maxpoolsize-too-high-cpu-pressure-05"]
- **rationales**: ["Adjust the connection pool size to suit your use case, beginning at 110-115% of the typical number of concurrent database requests"]

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
- **recommended_values**: ["vm.swappiness ∈ {0, 1}`(同机有 webserver 用 1 / dedicated 可用 0)","sudo make enable"]
- **violation_patterns**: ["默认 60"]
- **linked_case_ids**: ["mongo-os-vm-swappiness-default-60-aggressive-swap-05"]
- **rationales**: ["MongoDB performs best where swapping can be avoided or kept to a minimum, as retrieving data from swap will always be slower than accessing data in RAM.","performance-focused tuned profile for MongoDB on Linux"]

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
- **recommended_values**: ["connectTimeoutMS > longest network latency to any replica set member"]
- **violation_patterns**: ["< (副本集任一成员到 client 的网络延迟)"]
- **linked_case_ids**: ["mongo-pool-connect-timeout-too-large-01"]
- **rationales**: ["if a member has a latency of 10000 milliseconds, setting connectTimeoutMS to 5000 (milliseconds) prevents the driver from connecting to that member"]

## check_id: chk-sockettimeoutms

- **type**: parameter-current-value
- **param_name**: socketTimeoutMS
- **recommended_values**: ["socketTimeoutMS = 2~3 × longest legitimate operation duration","use maxTimeMS() instead of small socketTimeoutMS for server-side op cancellation"]
- **violation_patterns**: ["未设 / 远大于业务最慢操作耗时"]
- **linked_case_ids**: ["mongo-pool-socket-timeout-firewall-half-close-02"]
- **rationales**: ["socketTimeoutMS to ensure that sockets are always closed","use maxTimeMS() with queries so that the server can cancel long-running operations"]

## check_id: chk-minpoolsize

- **type**: parameter-current-value
- **param_name**: minPoolSize
- **recommended_values**: ["minPoolSize = number of connections required at startup"]
- **violation_patterns**: ["远小于启动期实际并发数"]
- **linked_case_ids**: ["mongo-pool-minpoolsize-too-low-startup-creating-conns-03"]
- **rationales**: ["The MongoClient instance ensures that number of connections exists at all times"]

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

## check_id: chk-march-armv8-2-a

- **type**: parameter-current-value
- **param_name**: -march=armv8.2-a
- **recommended_values**: ["-march=armv8.2-a"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["All Graviton processors after Graviton1 have support for the Large-System Extensions (LSE) which was first introduced in vArmv8.1. LSE provides low-cost atomic operations which can improve system thro"]
- **standalone**: true
- **bp_source_ids**: ["arm64-lse-march-armv82a-compile-flag-graviton-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: other
- **source_url**: https://raw.githubusercontent.com/aws/aws-graviton-getting-started/main/c-c++.md

## check_id: chk-moutline-atomics

- **type**: parameter-current-value
- **param_name**: -moutline-atomics
- **recommended_values**: ["-moutline-atomics"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["All Graviton processors after Graviton1 have support for the Large-System Extensions (LSE) which was first introduced in vArmv8.1. LSE provides low-cost atomic operations which can improve system thro"]
- **standalone**: true
- **bp_source_ids**: ["arm64-lse-outline-atomics-runtime-detect-graviton-02"]
- **risk_severity**: info
- **recommendation_layer**: other
- **scope**: other
- **source_url**: https://raw.githubusercontent.com/aws/aws-graviton-getting-started/main/c-c++.md

## check_id: chk-lse

- **type**: parameter-current-value
- **param_name**: LSE
- **recommended_values**: ["sudo dmesg"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The atomic instructions result in faster performance and less variability."]
- **standalone**: true
- **bp_source_ids**: ["arm64-lse-dmesg-lscpu-deploy-verify-percona-02"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: other
- **source_url**: https://dev.to/aws-builders/large-system-extensions-for-aws-graviton-processors-3eci

## check_id: chk-xfs-mount-noatime-access-time

- **type**: parameter-current-value
- **param_name**: XFS 数据盘 mount 加 noatime · 避免读取时更新 access time 浪费资源
- **recommended_values**: ["mount -o noatime (XFS data disk)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["文件系统不再记录访问时间，可以避免不必要的资源浪费。"]
- **standalone**: true
- **bp_source_ids**: ["bp-linux-fs-mount-noatime-xfs-rdb-server-01"]
- **risk_severity**: warning
- **recommendation_layer**: linux-mount-option
- **scope**: linux-fs
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0006.html

## check_id: chk-raid-flash-xfs-mount-nobarrier-write-barrier

- **type**: parameter-current-value
- **param_name**: 底层存储具备掉电保护(RAID/Flash)时 · XFS 数据盘 mount 加 nobarrier · 避免 write barrier 性能损失
- **recommended_values**: ["mount -o nobarrier (XFS data disk; storage with battery-backed cache; not openEuler)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["许多文件系统在数据提交时会使用write barriers来强制刷新Cache，以避免数据丢失。但是，其实我们数据库服务器底层存储设备要么采用RAID控制卡，RAID控制卡本身的电池可以掉电保护；要么采用Flash卡，它也有自我保护机制，保证数据不会丢失。"]
- **standalone**: true
- **bp_source_ids**: ["bp-linux-fs-mount-nobarrier-xfs-battery-backed-storage-02"]
- **risk_severity**: warning
- **recommendation_layer**: linux-mount-option
- **scope**: linux-fs
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0006.html

## check_id: chk-vm-dirty-ratio

- **type**: parameter-current-value
- **param_name**: vm.dirty_ratio
- **recommended_values**: ["vm.dirty_ratio=5"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["将dirty_ratio参数设置为“5”。"]
- **standalone**: true
- **bp_source_ids**: ["linux-mm-vm-dirty-ratio-5-kunpeng-dbs-os-cache-tuning-02"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-mm
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0017.html

## check_id: chk-vcpu-placement

- **type**: parameter-current-value
- **param_name**: vcpu placement
- **recommended_values**: ["vcpu placement='static' cpuset='<同 NUMA 节点 cpu 列表 · 例 4-7>'(用 cpuset 把 IO/worker threads 限定在同一 NUMA / DIE)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["若不配置此参数，虚拟机任务线程会在CPU任意core上浮动，会存在更多的跨NUMA和跨DIE损耗。"]
- **standalone**: true
- **bp_source_ids**: ["kvm-vcpu-placement-static-cpuset-numa-affinity-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: linux-sched
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0019.html

## check_id: chk-default-hugepagesz

- **type**: parameter-current-value
- **param_name**: default_hugepagesz
- **recommended_values**: ["default_hugepagesz=512M hugepagesz=512M hugepages=256"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["在Linux字段一行的最后输入以下配置。 1 default_hugepagesz=512M hugepagesz=512M hugepages=256 pci=realloc"]
- **standalone**: true
- **bp_source_ids**: ["os-kvm-vm-hugepages-allocate-tlb-miss-01"]
- **risk_severity**: warning
- **recommendation_layer**: kernel-cmdline
- **scope**: linux-mm
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0021.html

## check_id: chk-sys-block-device-name-queue-read-ahead-kb

- **type**: parameter-current-value
- **param_name**: /sys/block/$DEVICE-NAME/queue/read_ahead_kb
- **recommended_values**: ["read_ahead_kb = 4096"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["文件预取的原理，就是根据局部性原理，在读取数据时，会多读一定量的相邻数据缓存到内存。如果预读的数据是后续会使用的数据，那么系统性能会提升"]
- **standalone**: true
- **bp_source_ids**: ["linux-block-read-ahead-kb-sequential-io-4096-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: linux-block
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0039.html

## check_id: chk-mkfs-xfs

- **type**: parameter-current-value
- **param_name**: mkfs.xfs
- **recommended_values**: ["mkfs.xfs -b size=8192"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["mkfs.xfs /dev/sda1 -b size=8192"]
- **standalone**: true
- **bp_source_ids**: ["linux-fs-xfs-blocksize-large-file-01"]
- **risk_severity**: warning
- **recommendation_layer**: linux-mount-option
- **scope**: linux-fs
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0041.html

## check_id: chk-jemalloc-glibc

- **type**: parameter-current-value
- **param_name**: 多线程高并发场景下应用链接 jemalloc 替代 glibc 默认分配器以减少锁竞争
- **recommended_values**: ["-ljemalloc"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["在内存分配过程中，锁会造成线程等待，对性能影响巨大。"]
- **standalone**: true
- **bp_source_ids**: ["app-malloc-jemalloc-multithread-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: mem-allocator-jemalloc
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0051.html

## check_id: chk-wiredtiger

- **type**: parameter-current-value
- **param_name**: 长事务导致 WiredTiger 缓存压力：拆分事务并确保索引覆盖
- **recommended_values**: []
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["the cache must maintain state for all subsequent writes since the oldest snapshot was created. As a transaction always uses the same snapshot while it is running, new writes accumulate in the cache th"]
- **standalone**: true
- **bp_source_ids**: ["mongo-txn-long-running-wt-cache-pressure"]
- **risk_severity**: warning
- **recommendation_layer**: app-other
- **scope**: app-other
- **source_url**: https://www.mongodb.com/resources/products/capabilities/performance-best-practices-transactions-and-read-write-concerns

## check_id: chk-1000

- **type**: parameter-current-value
- **param_name**: 单次事务修改文档上限 1000 条：超出须拆批处理
- **recommended_values**: ["max_documents_per_transaction = 1000"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Creating long-running transactions, or attempting to perform an excessive number of operations in a single ACID transaction can result in high pressure on the WiredTiger storage engine cache. This is "]
- **standalone**: true
- **bp_source_ids**: ["mongo-txn-modify-1000-docs-max-batch"]
- **risk_severity**: warning
- **recommendation_layer**: app-other
- **scope**: app-other
- **source_url**: https://www.mongodb.com/resources/products/capabilities/performance-best-practices-transactions-and-read-write-concerns

## check_id: chk-linearizable-maxtimems

- **type**: parameter-current-value
- **param_name**: linearizable 读关注配合 maxTimeMS 防止操作无限挂起
- **recommended_values**: []
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Configuring this read concern level can have a significant impact on latency, therefore a maxTimeMS value should be supplied in order to timeout long-running operations."]
- **standalone**: true
- **bp_source_ids**: ["mongo-read-concern-linearizable-maxtimems"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: app-query-layer
- **source_url**: https://www.mongodb.com/resources/products/capabilities/performance-best-practices-transactions-and-read-write-concerns

## check_id: chk-mongodb-journal-io

- **type**: parameter-current-value
- **param_name**: MongoDB Journal 和系统日志应使用独立物理卷，避免日志 IO 竞争数据盘带宽
- **recommended_values**: []
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["MongoDB很多的性能瓶颈和IO相关。建议为日志盘（Journal和系统日志）单独设定一个物理卷，减少对数据盘IO的资源占用。"]
- **standalone**: true
- **bp_source_ids**: ["linux-block-journal-separate-volume-mongodb-01"]
- **risk_severity**: warning
- **recommendation_layer**: linux-block
- **scope**: linux-block
- **source_url**: https://mongoing.com/archives/3895

## check_id: chk-w-majority

- **type**: parameter-current-value
- **param_name**: 重要数据写入应使用 w:majority，防止主节点故障转移时写操作被回滚
- **recommended_values**: ["w = \"majority\""]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["{w: \"majority\"} 可以保证数据在复制到多数节点后才返回成功结果。使用该机制可以有效防止数据回滚的发生。"]
- **standalone**: true
- **bp_source_ids**: ["app-other-write-concern-majority-mongodb-failover-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://mongoing.com/archives/3895

## check_id: chk-storage-dbpath

- **type**: parameter-current-value
- **param_name**: storage.dbPath
- **recommended_values**: ["NVMe instead of spinning disk"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Use faster storage (NVMe instead of spinning disk)."]
- **standalone**: true
- **bp_source_ids**: ["linux-block-nvme-wt-dirty-eviction-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: linux-block
- **source_url**: https://oneuptime.com/blog/post/2026-03-31-mongodb-wiredtiger-storage-engine/view

## check_id: chk-irqbalance-service-active-state

- **type**: parameter-current-value
- **param_name**: irqbalance.service.active_state
- **recommended_values**: ["所有 NIC IRQ 队列(典型 32 个)绑到本地 NUMA CPU · /proc/irq/<N>/smp_affinity_list = 本地 NUMA 核 ID(前置:irqbalance 关闭)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["对于不同的硬件配置，用于绑中断的最佳CPU数目会有差异，比如对于鲲鹏920 5250处理器 + Huawei TM280 25G网卡（鲲鹏服务器的板载网卡）来说，最多可以绑定32个中断队列，建议将所有的队列都用在中断绑定上来获得最佳性能。"]
- **standalone**: true
- **bp_source_ids**: ["kunpeng-net-irq-affinity-bind-all-queues-to-local-numa-01"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0013.html

## check_id: chk-sys-kernel-mm-transparent-hugepage-enabled

- **type**: parameter-current-value
- **param_name**: /sys/kernel/mm/transparent_hugepage/enabled
- **recommended_values**: ["transparent_hugepage/enabled=never AND transparent_hugepage/defrag=never"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["这会导致内存的利用率下降，甚至会导致内存不足的情况。"]
- **standalone**: true
- **bp_source_ids**: ["linux-thp-disabled-db-mem-fragmentation-bp-01"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-mm
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0016.html

## check_id: chk-sys-block-device-queue-scheduler

- **type**: parameter-current-value
- **param_name**: /sys/block/${device}/queue/scheduler
- **recommended_values**: ["/sys/block/${device}/queue/scheduler = deadline"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["echo deadline > /sys/block/${device}/queue/scheduler"]
- **standalone**: true
- **bp_source_ids**: ["os-blockdev-scheduler-not-deadline-mysql-db-01"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-block
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0018.html

## check_id: chk-adaptive-rx-tx-off-ethtool-c

- **type**: parameter-current-value
- **param_name**: 鲲鹏网卡性能调优：禁用自适应中断聚合（adaptive-rx/tx off），使用静态 ethtool -C 参数
- **recommended_values**: ["adaptive-rx off, adaptive-tx off"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["当增大聚合度时，单个数据包的延时会以微秒的级别增加。"]
- **standalone**: true
- **bp_source_ids**: ["bp-linux-net-nic-interrupt-coalescing-static-kunpeng-01"]
- **risk_severity**: info
- **recommendation_layer**: other
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0027.html

## check_id: chk-maxincomingconnections

- **type**: parameter-current-value
- **param_name**: maxIncomingConnections
- **recommended_values**: ["maxIncomingConnections = 999999"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["maxIncomingConnections: 999999"]
- **standalone**: true
- **bp_source_ids**: ["os-mongod-maxincomingconnections-high-conn-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://www.mongodb.com/company/blog/technical/tuning-mongodb--linux-to-allow-for-tens-of-thousands-connections

## check_id: chk-nofile

- **type**: parameter-current-value
- **param_name**: nofile
- **recommended_values**: ["nofile = 9999999"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["TCP/IP connections are open files as far as ulimit is concerned."]
- **standalone**: true
- **bp_source_ids**: ["os-ulimit-nofile-high-conn-01"]
- **risk_severity**: critical
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.mongodb.com/company/blog/technical/tuning-mongodb--linux-to-allow-for-tens-of-thousands-connections

## check_id: chk-nproc

- **type**: parameter-current-value
- **param_name**: nproc
- **recommended_values**: ["nproc = 9999999"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["For historical reasons, nproc is really the number of threads. Historically a Linux process was a single thread and concurrent workloads were multi-process."]
- **standalone**: true
- **bp_source_ids**: ["os-ulimit-nproc-high-conn-02"]
- **risk_severity**: critical
- **recommendation_layer**: os-sysctl
- **scope**: linux-sched
- **source_url**: https://www.mongodb.com/company/blog/technical/tuning-mongodb--linux-to-allow-for-tens-of-thousands-connections

## check_id: chk-stack

- **type**: parameter-current-value
- **param_name**: stack
- **recommended_values**: ["stack = 9999999"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Threads allocate memory from the stack, which also has a maximum size."]
- **standalone**: true
- **bp_source_ids**: ["os-ulimit-stack-high-conn-03"]
- **risk_severity**: critical
- **recommendation_layer**: os-sysctl
- **scope**: linux-mm
- **source_url**: https://www.mongodb.com/company/blog/technical/tuning-mongodb--linux-to-allow-for-tens-of-thousands-connections

## check_id: chk-vm-max-map-count

- **type**: parameter-current-value
- **param_name**: vm.max_map_count
- **recommended_values**: ["vm.max_map_count = 9999999"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Creating threads uses mmap to allocate memory from stack. And on the kernel level there's a setting for max number of mmapped memory blocks per process, which must be increased too"]
- **standalone**: true
- **bp_source_ids**: ["os-vm-max-map-count-thread-mmap-01"]
- **risk_severity**: critical
- **recommendation_layer**: os-sysctl
- **scope**: linux-mm
- **source_url**: https://www.mongodb.com/company/blog/technical/tuning-mongodb--linux-to-allow-for-tens-of-thousands-connections

## check_id: chk-replication-replsetname

- **type**: parameter-current-value
- **param_name**: replication.replSetName
- **recommended_values**: ["replica set ≥ 3 data-bearing voting members + write concern w: majority","replica set members spread across ≥2 SANs (or mix SAN + local disk)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Ensure that your replica set includes at least three data-bearing voting members","Avoid placing all replica set members on the same SAN, as the SAN can be a single point of failure."]
- **standalone**: true
- **bp_source_ids**: ["mongo-replica-set-data-durability-three-voting-majority-01","linux-block-avoid-replica-set-members-same-san-checklist-05"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-development/

## check_id: chk-members-votes

- **type**: parameter-current-value
- **param_name**: members[].votes
- **recommended_values**: ["voting members ∈ {1,3,5,7} (odd, ≤7)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Use an odd number of voting members to ensure that elections proceed successfully. You can have up to 7 voting members"]
- **standalone**: true
- **bp_source_ids**: ["mongo-replica-set-odd-voting-members-elections-02"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-development/

## check_id: chk-dbpath

- **type**: parameter-current-value
- **param_name**: dbPath
- **recommended_values**: ["dbPath ∉ NFS · 用本地块设备 / VMware 虚拟盘","XFS for WT data drive (avoid EXT4 with WT)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Using NFS drives can result in degraded and unstable performance.","use of XFS is strongly recommended to avoid performance issues found when using EXT4 with WiredTiger."]
- **standalone**: true
- **bp_source_ids**: ["linux-fs-avoid-nfs-for-dbpath-checklist-01","linux-fs-xfs-strongly-recommended-for-wt-checklist-02"]
- **risk_severity**: warning
- **recommendation_layer**: linux-mount-option
- **scope**: linux-fs
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/

## check_id: chk-tuned-profile

- **type**: parameter-current-value
- **param_name**: tuned.profile
- **recommended_values**: ["customize tuned profile (THP per MongoDB version · readahead 8-32)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Many of the tuned profiles that ship with RHEL / CentOS can negatively impact performance with their default settings."]
- **standalone**: true
- **bp_source_ids**: ["linux-sched-customize-tuned-profile-rhel-centos-checklist-04"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-sched
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/

## check_id: chk-raid-10-raid-5-raid-6

- **type**: parameter-current-value
- **param_name**: 存储层用 RAID-10 · 不要用 RAID-5 / RAID-6
- **recommended_values**: ["RAID-10`(并明确反对 RAID-5 / RAID-6)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["RAID-5 and RAID-6 do not typically provide sufficient performance to support a MongoDB deployment."]
- **standalone**: true
- **bp_source_ids**: ["linux-block-raid-10-not-5-or-6-02"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: linux-block
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-fstab

- **type**: parameter-current-value
- **param_name**: fstab
- **recommended_values**: ["/etc/fstab 挂载选项含 bg, hard, nolock, noatime, nointr"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["using a remote file system for storage may degrade performance."]
- **standalone**: true
- **bp_source_ids**: ["linux-fs-nfs-mount-options-bg-hard-nolock-noatime-nointr-03"]
- **risk_severity**: warning
- **recommendation_layer**: linux-mount-option
- **scope**: linux-fs
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-i-o-ssd-sata-ssd

- **type**: parameter-current-value
- **param_name**: I/O 吞吐瓶颈时 · 优先用 SSD(SATA SSD 性价比好)而非堆贵转盘
- **recommended_values**: ["Use SSD if available and economical"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["the random I/O performance increase with more expensive spinning drives is not that dramatic (only on the order of 2x). Using SSDs or increasing RAM may be more effective in increasing I/O throughput."]
- **standalone**: true
- **bp_source_ids**: ["linux-block-use-ssd-for-random-io-04"]
- **risk_severity**: info
- **recommendation_layer**: other
- **scope**: linux-block
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-numactl

- **type**: parameter-current-value
- **param_name**: numactl
- **recommended_values**: ["numactl --interleave=all <mongod-cmd>"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Running MongoDB on a system with Non-Uniform Memory Access (NUMA) can cause a number of operational problems, including slow performance for periods of time and high system process usage."]
- **standalone**: true
- **bp_source_ids**: ["linux-mm-numactl-interleave-all-mongod-startup-07"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-cli-flag
- **scope**: linux-mm
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-vm-zone-reclaim-mode

- **type**: parameter-current-value
- **param_name**: vm.zone_reclaim_mode
- **recommended_values**: ["vm.zone_reclaim_mode = 0"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["If the NUMA configuration may degrade performance, MongoDB prints a warning."]
- **standalone**: true
- **bp_source_ids**: ["linux-mm-vm-zone-reclaim-mode-disable-08"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-mm
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-i-o-scheduler

- **type**: parameter-current-value
- **param_name**: I/O scheduler
- **recommended_values**: ["I/O scheduler = none","I/O scheduler = mq-deadline","I/O scheduler = kyber`(需 Linux kernel 4.12+)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The none scheduler allows the operating system to defer I/O scheduling to the underlying hypervisor.","The mq-deadline scheduler caps maximum latency per request and maintains a good disk throughput that is best for disk-intensive database applications.","use the kyber scheduler."]
- **standalone**: true
- **bp_source_ids**: ["linux-sched-none-for-vm-cloud-09","linux-sched-mq-deadline-for-spinning-disk-10","linux-sched-kyber-for-multi-workload-11"]
- **risk_severity**: info
- **recommendation_layer**: os-sysctl
- **scope**: linux-sched
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-readahead

- **type**: parameter-current-value
- **param_name**: readahead
- **recommended_values**: ["blockdev --getra <dev> 结果 ∈ [8, 32]"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Higher readahead commonly benefits sequential I/O operations. Since MongoDB disk access patterns are generally random, using higher readahead settings provides limited benefit or potential performance"]
- **standalone**: true
- **bp_source_ids**: ["linux-block-readahead-8-to-32-wt-12"]
- **risk_severity**: info
- **recommendation_layer**: os-sysctl
- **scope**: linux-block
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-mongod-libssl-libcrypto-objdump

- **type**: parameter-current-value
- **param_name**: mongod 启动时 libssl/libcrypto 符号版本警告 · 通常不影响 · 可用 objdump 核对
- **recommended_values**: ["用 objdump -T 核对 mongod 与系统库的符号版本是否兼容(忽略告警 / 或换库)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Typically these messages do not require intervention; however, you can use the following operations to determine the symbol versions that mongod expects"]
- **standalone**: true
- **bp_source_ids**: ["tls-crypto-ssl-symbol-version-mismatch-warn-13"]
- **risk_severity**: info
- **recommendation_layer**: other
- **scope**: tls-crypto
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-kvm-reservation

- **type**: parameter-current-value
- **param_name**: KVM reservation
- **recommended_values**: ["为 mongod KVM 虚机预留 (reserve) 全部分配内存 · 不禁用 balloon driver"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Reserving the appropriate amount of memory for the virtual machine prevents the balloon from inflating in the local operating system when there is memory pressure in the hypervisor."]
- **standalone**: true
- **bp_source_ids**: ["linux-mm-kvm-reserve-full-vm-memory-15"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: linux-mm
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-net-compression-compressors

- **type**: parameter-current-value
- **param_name**: net.compression.compressors
- **recommended_values**: ["net.compression.compressors = snappy"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Note that network compression can have a significant impact on network performance and CPU usage."]
- **standalone**: true
- **bp_source_ids**: ["mongo-net-compressor-enable-bandwidth-reduction-03"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: other
- **source_url**: https://www.percona.com/blog/compression-methods-in-mongodb-snappy-vs-zstd/

## check_id: chk-puppet-chef-ansible-tuned-profile

- **type**: parameter-current-value
- **param_name**: 使用配置管理工具（Puppet/Chef/Ansible）时 · 必须通过 tuned profile 部署调参而非直接修改系统文件
- **recommended_values**: ["configure those systems to deploy tunings via tuned profiles"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["tunings are not overridden or ignored"]
- **standalone**: true
- **bp_source_ids**: ["os-cm-deploy-tuning-via-tuned-profile-not-direct-02"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: other
- **source_url**: https://www.percona.com/blog/tuning-linux-for-mongodb-automated-tuning-redhat-and-centos/

## check_id: chk-net-serviceexecutor

- **type**: parameter-current-value
- **param_name**: net.serviceExecutor
- **recommended_values**: ["serviceExecutor: adaptive"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["加上serviceExecutor: adaptive配置后，借助boost:asio网络模块实现网络IO复用，同时实现网络IO和磁盘IO分离。这样高并发情况下，通过网络链接IO复用和mongodb的锁操作来控制磁盘IO访问线程数，最终降低了大量线程创建和消耗带来的高系统负载"]
- **standalone**: true
- **bp_source_ids**: ["mongo-service-executor-adaptive-high-concurrency-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://cloud.tencent.com/developer/news/710321

## check_id: chk-storage-wiredtiger-engineconfig-configstring

- **type**: parameter-current-value
- **param_name**: storage.wiredTiger.engineConfig.configString
- **recommended_values**: ["eviction_dirty_target=3%,eviction_dirty_trigger=25%","checkpoint=(wait=25,log_size=1GB)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["总体思想是让后台evict尽量早点淘汰脏页page到磁盘，同时调整evict淘汰线程数来加快脏数据淘汰，调整后mongostat及客户端超时现象进一步缓解。","如果我们把checkpoint的周期缩短，那么两个checkpoint期间的脏数据相应的也就会减少，磁盘IO 100%持续的时间也就会缩短。"]
- **standalone**: true
- **bp_source_ids**: ["mongo-wt-eviction-dirty-target-3pct-high-write-01","mongo-wt-checkpoint-wait-25s-io-smoothing-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://cloud.tencent.com/developer/news/710321

## check_id: chk-expireafterseconds

- **type**: parameter-current-value
- **param_name**: expireAfterSeconds
- **recommended_values**: ["expireAfterSeconds=0"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["通过随机散列expireAt在三天后的凌晨任意时间点，即可规避白天高峰期触发过期索引引入的集群大量delete，从而降低了高峰期集群负载，最终减少业务平均时延及抖动。"]
- **standalone**: true
- **bp_source_ids**: ["mongo-ttl-expiry-offpeak-window-high-write-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://cloud.tencent.com/developer/news/710321

## check_id: chk-operationprofiling-slowopthresholdms

- **type**: parameter-current-value
- **param_name**: operationProfiling.slowOpThresholdMs
- **recommended_values**: ["index build mode = rolling","slowms = highest-useful-value`(业务可接受的最大慢查询阈值 · 默认 100ms 仅在低 QPS/SLA 紧张时合理 · 高吞吐场景应调大至 200/500ms 等)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Building an index in a rolling fashion reduces the resiliency of your cluster and increases index build times","Set it to the highest useful value to avoid performance degradation."]
- **standalone**: true
- **bp_source_ids**: ["mongo-atlas-rolling-index-build-non-tolerant-workloads-01","mongo-profiler-slowms-highest-useful-value-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/atlas/performance-advisor/

## check_id: chk-storage-journal-commitintervalms

- **type**: parameter-current-value
- **param_name**: storage.journal.commitIntervalMs
- **recommended_values**: ["storage.journal.commitIntervalMs = 200"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **standalone**: true
- **bp_source_ids**: ["wt-journal-commit-interval-high-throughput-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-storage-journal-enabled

- **type**: parameter-current-value
- **param_name**: storage.journal.enabled
- **recommended_values**: ["storage.journal.enabled = false"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **standalone**: true
- **bp_source_ids**: ["wt-journal-disable-non-critical-max-write-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-storage-wiredtiger-collectionconfig-blockcompressor

- **type**: parameter-current-value
- **param_name**: storage.wiredTiger.collectionConfig.blockCompressor
- **recommended_values**: ["storage.wiredTiger.collectionConfig.blockCompressor = none","storage.wiredTiger.collectionConfig.blockCompressor = zstd","storage.wiredTiger.collectionConfig.blockCompressor = snappy"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["不同的压缩算法有着不同的表现，有的压缩率更高但压缩和解压时的CPU开销更大","Provides a lower compression rate than zlib or zstd but has a lower CPU cost than either."]
- **standalone**: true
- **bp_source_ids**: ["wt-block-compressor-none-max-write-speed-01","mongo-wt-block-compressor-cold-data-zstd-06","wt-compression-snappy-default-block-collections-03"]
- **risk_severity**: info
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-storage-directoryperdb

- **type**: parameter-current-value
- **param_name**: storage.directoryPerDB
- **recommended_values**: ["storage.directoryPerDB = true"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **standalone**: true
- **bp_source_ids**: ["wt-directory-per-db-separate-volumes-01"]
- **risk_severity**: info
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-replication-oplogsizemb

- **type**: parameter-current-value
- **param_name**: replication.oplogSizeMB
- **recommended_values**: ["replication.oplogSizeMB >= 1小时以上的oplog记录量"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["参数设置过小，可能会导致从节点跟不上而进入异常的RECOVERING状态；也有可能导致日志备份来不及覆盖所有oplog记录而出现空洞，进而无法进行按时间点恢复"]
- **standalone**: true
- **bp_source_ids**: ["mongo-oplog-size-high-write-update-workload-03"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-setparameter-cursortimeoutmillis

- **type**: parameter-current-value
- **param_name**: setParameter.cursorTimeoutMillis
- **recommended_values**: ["setParameter.cursorTimeoutMillis = 300000"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["为了降低空闲游标的资源开销，可以适当调小（比如300000）。无论何种场景，业务侧都应尽量避免出现长时间空闲游标的情况"]
- **standalone**: true
- **bp_source_ids**: ["mongo-cursor-timeout-idle-resource-overhead-04"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-setparam
- **scope**: app-other
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-setparameter-transactionlifetimelimitseconds

- **type**: parameter-current-value
- **param_name**: setParameter.transactionLifetimeLimitSeconds
- **recommended_values**: ["setParameter.transactionLifetimeLimitSeconds = 30"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["未提交的长事务可能会给WiredTiger存储引擎的缓存带来很大压力，一旦缓存压力超载通常会带来更多问题，包括数据库卡顿、请求延迟大幅增加、CPU使用率满等，导致业务受损"]
- **standalone**: true
- **bp_source_ids**: ["mongo-transaction-lifetime-long-wt-cache-pressure-05"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-setparam
- **scope**: storage-engine-wt
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-setparameter-tcmallocaggressivememorydecommit

- **type**: parameter-current-value
- **param_name**: setParameter.tcmallocAggressiveMemoryDecommit
- **recommended_values**: ["setParameter.tcmallocAggressiveMemoryDecommit = 1"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["有内存相关问题时可以考虑在业务低峰期时调整"]
- **standalone**: true
- **bp_source_ids**: ["mongo-tcmalloc-aggressive-decommit-oom-fragment-07"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-setparam
- **scope**: app-other
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-setparameter-minsnapshothistorywindowinseconds

- **type**: parameter-current-value
- **param_name**: setParameter.minSnapshotHistoryWindowInSeconds
- **recommended_values**: ["setParameter.minSnapshotHistoryWindowInSeconds = 0"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["此参数会带来一定的WT缓存（WT cache）压力，尤其是相同文档频繁更新的场景"]
- **standalone**: true
- **bp_source_ids**: ["mongo-snapshot-history-window-no-atclustertime-08"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-setparam
- **scope**: storage-engine-wt
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-wiredtigerconcurrentreadtransactions

- **type**: parameter-current-value
- **param_name**: wiredTigerConcurrentReadTransactions
- **recommended_values**: ["wiredTigerConcurrentReadTransactions = 256"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["WiredTiger uses a ticket system to limit concurrent operations. By default, 128 read tickets and 128 write tickets are available."]
- **standalone**: true
- **bp_source_ids**: ["wt-concurrent-tickets-low-increase-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-setparam
- **scope**: storage-engine-wt
- **source_url**: https://oneuptime.com/blog/post/2026-03-31-mongodb-wiredtiger-storage-engine/view

## check_id: chk-security-enableencryption

- **type**: parameter-current-value
- **param_name**: security.enableEncryption
- **recommended_values**: ["CPU 支持 AES-NI 指令集扩展"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["CPUs equipped with AES-NI instruction-set extensions show significant performance advantages."]
- **standalone**: true
- **bp_source_ids**: ["wt-encrypted-storage-aes-ni-cpu-required-04"]
- **risk_severity**: warning
- **recommendation_layer**: bios-firmware
- **scope**: storage-engine-wt
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-storage-syncperiodsecs

- **type**: parameter-current-value
- **param_name**: storage.syncPeriodSecs
- **recommended_values**: ["storage.syncPeriodSecs != 0"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["storage.syncPeriodSecs has no effect on Journaling , but if storage.syncPeriodSecs is set to 0 the journal eventually consumes all available disk space."]
- **standalone**: true
- **bp_source_ids**: ["mongo-config-syncperiodsecs-production-default-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-systemlog-quiet

- **type**: parameter-current-value
- **param_name**: systemLog.quiet
- **recommended_values**: ["systemLog.quiet false"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["systemLog.quiet Type : boolean Default : false Run mongos or mongod in a quiet mode that attempts to limit the amount of output. systemLog.quiet is not recommended for production systems as it may mak"]
- **standalone**: true
- **bp_source_ids**: ["mongo-config-quiet-mode-disable-production-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-systemlog-destination

- **type**: parameter-current-value
- **param_name**: systemLog.destination
- **recommended_values**: ["file option for production systems"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The syslog daemon generates timestamps when it logs a message, not when MongoDB issues the message. This can lead to misleading timestamps for log entries, especially when the system is under heavy lo"]
- **standalone**: true
- **bp_source_ids**: ["mongo-config-syslog-destination-file-production-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-systemlog-logrotate

- **type**: parameter-current-value
- **param_name**: systemLog.logRotate
- **recommended_values**: ["systemLog.logRotate reopen"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["reopen closes and reopens the log file following the typical Linux/Unix log rotate behavior. Use reopen when using the Linux/Unix logrotate utility to avoid log loss. If you specify reopen , you must "]
- **standalone**: true
- **bp_source_ids**: ["mongo-config-logrotate-reopen-logrotated-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-auditlog-format

- **type**: parameter-current-value
- **param_name**: auditLog.format
- **recommended_values**: ["auditLog.format BSON"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Printing audit events to a file in JSON format degrades server performance more than printing to a file in BSON format."]
- **standalone**: true
- **bp_source_ids**: ["mongo-config-auditlog-bson-format-perf-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-auditlog-localauditkeyfile

- **type**: parameter-current-value
- **param_name**: auditLog.localAuditKeyFile
- **recommended_values**: ["auditLog.auditEncryptionKeyIdentifier = <kmip-key-id>"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Only use auditLog.localAuditKeyFile for testing because the key is not secured."]
- **standalone**: true
- **bp_source_ids**: ["mongo-config-audit-kmip-not-local-key-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-net-maxincomingconnections

- **type**: parameter-current-value
- **param_name**: net.maxIncomingConnections
- **recommended_values**: ["net.maxIncomingConnections slightly higher than max client connections"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["This setting prevents the mongos from causing connection spikes on the individual shards . Spikes like these may disrupt the operation and memory allocation of the sharded cluster ."]
- **standalone**: true
- **bp_source_ids**: ["mongo-config-mongos-maxconn-connection-leak-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-operationprofiling-mode

- **type**: parameter-current-value
- **param_name**: operationProfiling.mode
- **recommended_values**: ["before enabling profiler · 优先用 Atlas Query Profiler / Atlas Performance Advisor / $queryStats(aggregation stage)等替代方案做慢查询观测 · 仅在替代方案无法覆盖时再启用 profiler"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The database profiler can degrade MongoDB performance."]
- **standalone**: true
- **bp_source_ids**: ["mongo-profiler-prefer-atlas-alternatives-before-enabling-02"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/manage-the-database-profiler/
