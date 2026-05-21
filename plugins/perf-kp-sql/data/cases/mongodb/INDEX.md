# Cases Index

> 生成时间: 2026-05-21T02:55:21.894Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 299 cases
> 配套: cases/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| mongo-cache-spike-replication-lag-cascade-01 | replica-lag | WiredTiger Cache 峰值与复制延迟级联失败 (MongoDB 3.0 → 3.4 升级修复) | 11558 |
| mongo-ulimit-low-defaults-mongod-issues-03 | startup-failure | 系统默认 ulimit 过低导致 mongod 运行异常 | 11638 |
| mongo-shard-chunk-migration-x-lock-timeout-balancer-stuck-01 | lock-contention | shard chunk migration 卡死 LockTimeout · balancer 一直 abort | 11682 |
| mongo-wt-large-page-eviction-fetch-pause-server-16479 | query-slow | WiredTiger 大页驱逐导致 fetch 期间多次显著停顿 | 11774 |
| mongo-wt-btree-sweep-eviction-collection-blocked-server-17907 | query-slow | sweep server 整 b-tree 驱逐期间集合访问被阻塞数分钟 | 11839 |
| mongo-tcmalloc-decommit-madvise-lock-stall-server-31417 | query-slow | tcmalloc 归还大量 pageheap free memory 时持内部锁数秒 · 全线程延迟尖峰 | 11904 |
| mongo-tcmalloc-heap-fragmentation-pageheap-free-server-33296 | memory-pressure | mongod 内存远超已分配数据 · pageheap_free_bytes 持续累积 | 11981 |
| mongo-wt-tcmalloc-fragmentation-durable-history-wt-6175 | memory-pressure | 4.4 引入 durable history 后 tcmalloc 碎片化加剧 · mongod VSZ 比 4.2.6 多约 9G | 12046 |
| mongo-globallock-current-queue-high-lock-contention-01 | lock-contention | globalLock.currentQueue.total 持续高 → 大量请求等锁 → 性能降级 | 12111 |
| mongo-pagination-skip-deep-page-rewrite-02 | query-slow | 大翻页 skip 性能塌陷: skip 100 页 12.8s → 改写 $gt 后稳定 10-20ms | 12173 |
| mongo-wt-checkpoint-period-tuning-disk-io-spike-02 | disk-io-saturation | WiredTiger checkpoint 周期偏长 → 磁盘 IO 短暂 100% 抖动 | 12223 |
| mongo-system-sessions-update-storm-primary-shard-degradation-03 | replica-lag | mongos 集中更新 system.sessions 拖垮主分片 → 集群瞬间数倍下降 | 12273 |
| mongo-slow-log-currentop-long-query-kill-02 | query-slow | 慢日志 grep + currentOp 定位长时执行操作并 kill | 12317 |
| wt-eviction-trigger-app-thread-throttle-01 | memory-pressure | cache 用量持续接近 eviction_trigger (默认 95%) → application threads 被拉去做 eviction | 12377 |
| mongo-snappy-hotspot-cpu-high-arm64-01 | cpu-high | MongoDB Snappy 压缩热点函数在鲲鹏 ARM64 上 CPU 占用偏高 | 12436 |
| app-thread-concurrency-mismatch-01 | cpu-high | 应用线程并发数过高导致上下文切换/锁竞争开销加大 | 12480 |
| app-malloc-jemalloc-multithread-audit-01 | cpu-high | 多线程内存分配场景未启用 jemalloc，glibc 默认分配器锁竞争激烈 | 12530 |
| mongo-aggregation-unbounded-pipeline-no-early-match-01 | query-slow | seller analytics 看板聚合 8.2s: $match 在 $lookup 之后 | 12580 |
| mongo-schema-too-many-lookups-should-embed-01 | query-slow | $lookup 用得过多 → 应改为 embed 单集合内 | 12624 |
| mongo-schema-unused-indexes-bloat-03 | disk-space-pressure | 集合上有未使用 index → 占盘 + 拖慢写性能 | 12668 |
| mongo-schema-document-too-large-04 | query-slow | 文档体积过大 → 频繁查询性能差 | 12712 |
| mongo-query-targeting-high-scan-ratio-01 | query-slow | Atlas Query Targeting alert: high scanned-to-returned document ratio | 12756 |
| mongo-slow-query-profiler-metric-01 | query-slow | Atlas Query Profiler: identify and interpret slow queries by multiple metrics | 12824 |
| mongo-locking-queue-buildup-01 | lock-contention | 锁等待队列堆积导致请求被阻塞 | 12910 |
| mongo-connection-storm-driver-error-02 | connection-storm | 连接数飙升 → 服务器吃不下请求 | 12978 |
| mongo-wt-tickets-exhausted-01 | lock-contention | WiredTiger 读写 ticket 持续 < 128 → 并发被限流 | 13043 |
| mongo-replication-lag-multi-cause-02 | replica-lag | 复制集 secondary 落后 primary(4 类互斥根因) | 13108 |
| mongo-open-cursor-rising-no-traffic-03 | other | open cursor 持续上升但流量未变 | 13170 |
| mongo-scan-and-order-high-04 | memory-pressure | Scan and Order 数高 → 服务端排序内存压力 | 13214 |
| mongo-unbound-array-rewrite-pressure-05 | query-slow | 文档中 array 无上限增长 → 每次更新触发整文档重写 | 13258 |
| mongo-driver-pool-size-too-small-vs-concurrent-requests-02 | connection-storm | driver 连接池大小 < 1.10×并发请求数 → 池排队 | 13302 |
| mongo-fs-nfs-dbpath-degraded-unstable-perf-01 | disk-io-saturation | dbPath 用 NFS 卷 → 性能下降且不稳定 | 13346 |
| mongo-fs-ext4-wiredtiger-perf-issue-should-use-xfs-02 | disk-io-saturation | WiredTiger + EXT4 → 已知性能问题 · 应改 XFS | 13390 |
| mongo-tuned-profile-default-rhel-perf-impact-05 | other | RHEL/CentOS tuned profile 用默认值 → 对 MongoDB 性能负向影响 | 13434 |
| mongo-startup-kernel-6-19-tcmalloc-incompat-01 | startup-failure | MongoDB 8.0+ 在 Linux Kernel 6.19 上启动 crash | 13478 |
| mongo-network-tcp-keepalive-too-long-cloud-lb-drops-02 | network-latency | tcp_keepalive_time 大于云 LB 空闲超时 → 连接被静默切断 | 13522 |
| mongo-numa-cross-node-memory-degradation-04 | cpu-high | MongoDB 在 NUMA 硬件上跨节点访问导致间歇性慢 | 13566 |
| mongo-os-vm-swappiness-default-60-aggressive-swap-05 | memory-pressure | vm.swappiness 默认 60 → MongoDB 频繁 swap 性能下降 | 13625 |
| mongo-aws-ec2-storage-network-tuning-06 | disk-io-saturation | AWS EC2 上 MongoDB 性能不可重现 / 不达上限 | 13669 |
| mongo-tcmalloc-percpu-caches-not-enabled-01 | memory-pressure | MongoDB 8.0 TCMalloc per-CPU caches 未启用 → 高负载下内存碎片与性能退化 | 13725 |
| mongo-inmemory-cache-full-overflow-01 | memory-pressure | In-memory storage engine 数据超出 inMemorySizeGB → WT_CACHE_FULL | 13799 |
| mongo-psa-majority-writeconcern-perf-degradation-01 | replica-lag | PSA 架构 + majority write concern · secondary 不可用/落后导致写性能下降与读 stale | 13852 |
| mongo-wt-cache-size-misconfigured-01 | memory-pressure | WiredTiger 内部 cache 大小被人工调高 → 与 filesystem cache 抢内存 | 13926 |
| mongo-explain-sort-stage-disk-spill-01 | memory-pressure | $sort 或 SORT 阶段 spill 到磁盘 → 排序内存压力 | 13976 |
| mongo-pool-connect-timeout-too-large-01 | network-latency | connectTimeoutMS 默认或过大 → 应用侧操作时间慢但 DB 侧未见 | 14035 |
| mongo-pool-socket-timeout-firewall-half-close-02 | connection-storm | 防火墙错关连接 driver 不感知 → 应通过 socketTimeoutMS 兜底 | 14079 |
| mongo-pool-minpoolsize-too-low-startup-creating-conns-03 | connection-storm | 启动期可用连接不足 → 应用频繁建新连接 → minPoolSize 太小 | 14129 |
| mongo-pool-maxpoolsize-too-low-underutilized-04 | query-slow | DB 负载低、活跃连接少、应用吞吐低于预期 → maxPoolSize 太小限流了 | 14173 |
| mongo-pool-maxpoolsize-too-high-cpu-pressure-05 | cpu-high | DB CPU 比预期高 + 连接尝试比预期多 → maxPoolSize 太大压垮服务端 | 14217 |
| mongo-slow-query-explain-multi-stage-01 | query-slow | 慢查询 explain() 五步排查链路 | 14261 |
| mongo-profiler-threshold-sampling-audit-01 | other | profiler 慢查询阈值 / 抽样率默认配置审计 | 14338 |
| mongo-8x-thp-disabled-tcmalloc-suboptimal-01 | memory-pressure | THP 未启用导致 MongoDB 8.0+ 新 TCMalloc 优化失效 | 14394 |
| mongo-replica-set-replication-lag-01 | replica-lag | 副本集复制延迟(replication lag) | 14444 |
| mongo-replica-lag-secondary-behind-primary-01 | replica-lag | Ops Manager replication lag alert: secondary behind primary | 14527 |
| mongo-slow-log-queue-wait-vs-working-time-mongodb8-01 | query-slow | MongoDB 8.0 慢日志: workingMillis 与 durationMillis 分离 → 区分真慢查询 vs queue 等待 | 14601 |
| mongo-plancache-bloat-sbe-7-0-oom-kills-01 | memory-pressure | MongoDB 7.0 SBE plan cache 膨胀: 单 query shape 5 万+ plan → OOM kill | 14666 |
| mongo-sharding-jumbo-chunk-uneven-write-load-01 | disk-io-saturation | jumbo chunks 无法被 balancer 迁移导致单 shard 写热点 | 14757 |
| mongo-sharding-equal-chunks-skewed-data-getshard-distribution-02 | disk-io-saturation | chunk 计数均衡但数据/查询全压在一个 shard(getShardDistribution 100%/0%) | 14831 |
| mongo-k8s-container-wt-cache-fallback-256mb-01 | memory-pressure | 容器中 WiredTiger 无法识别容器内存限制,回退 256MB 最小 cache | 14881 |
| mongo-k8s-operator-cachesize-bug-cpu-limit-required-02 | memory-pressure | PSMDB operator v1.9 / v1.10 已知 bug · cacheSizeRatio 改了但 mongod 仍按默认 cache 启动 | 14940 |
| mongo-8-0-tcmalloc-percpu-prerequisite-not-met-01 | memory-pressure | MongoDB 8.0 升级后未拿到预期性能提升 · TCMalloc 实际未启用 per-CPU caches | 14993 |
| mongo-query-ixscan-poor-selectivity-extra-sort-02 | query-slow | 索引存在但 totalDocsExamined ≫ nReturned + 出现独立 SORT stage | 15076 |
| mongo-write-regression-default-writeconcern-majority-journal-01 | query-slow | MongoDB 5.0+ 默认 writeConcern=majority 致 JournalFlusher 写盘成为热点 | 15135 |
| mongo-wt-checkpoint-time-grows-bulk-load-stall-01 | disk-io-saturation | bulk-load 期间 WiredTiger checkpoint 时间从几秒增至数分钟,期间业务停滞 | 15209 |
| wt-evict-cold-page-compact-cure-01 | other | WiredTiger 冷数据 evict 后 checkpoint 不再处理 · compact 触发 reconciliation 强制回收 | 15442 |
| wt-app-thread-evict-assist-pressure-01 | other | WiredTiger 应用线程被迫参与 eviction 助手(cache 使用率超阈值压力 signature) | 15469 |
| wt-evict-reconcile-blocked-ebusy-01 | other | WiredTiger eviction reconcile 被多重 EBUSY 阻碍(__evict_review → __evict_reconcile 链路热点) | 15496 |
| wt-capacity-throttle-cond-signal-crash-01 | other | WiredTiger io_capacity 配置语法错误后,后台 eviction 线程经 capacity_throttle 调用 __wt_cond_signal 解引用 NULL capacity_cond 触发 SIGSEGV | 15523 |
| wt-reconcile-row-tombstone-skip-01 | other | WiredTiger reconcile 在 row leaf 上跳过全局可见 stop_ts 的 key(磁盘清理读-判-跳路径 signature) | 15550 |
| wt-reconcile-write-wrapup-block-free-01 | other | WiredTiger reconcile 写入 wrapup 阶段释放旧页面磁盘块(block manager free-list 入队 signature) | 15577 |
| wt-reconcile-row-leaf-tombstone-not-globally-visible-01 | other | WiredTiger 行叶页 reconcile 路径下 tombstone 非全局可见 → 已删除数据被整页保留(oldest_timestamp 推进不足 signature) | 15604 |
