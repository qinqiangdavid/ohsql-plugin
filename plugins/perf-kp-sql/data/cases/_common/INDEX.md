# Cases Index

> 生成时间: 2026-05-31T02:56:50.453Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 25 cases
> 配套: _common/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| kunpeng-nohz-clock-tick-overhead-03 | cpu-high | 周期时钟中断浪费 CPU 资源(nohz 未启用) | 3 |
| kunpeng-tlb-miss-page-size-04 | cpu-high | 4K 页大小导致 TLB 命中率低 | 57 |
| kunpeng-thread-concurrency-overload-05 | cpu-high | 线程并发数超过最佳点导致性能下降 | 102 |
| mongo-fs-mount-noatime-nobarrier-missing-01 | disk-io-saturation | XFS mount 未加 noatime/nobarrier 导致文件系统冗余开销 | 147 |
| mongo-os-tcp-stack-tuning-01 | network-latency | OS 层 TCP 协议栈参数审计 (7 条 sysctl) | 198 |
| mongo-client-os-tcp-tuning-01 | network-latency | MongoDB 客户端侧 OS 层 TCP 参数审计 (8 条 sysctl) | 279 |
| kunpeng-bios-smmu-enabled-non-virt-01 | disk-io-saturation | 鲲鹏 BIOS 中 SMMU 在非虚拟化场景未关闭(影响数据库 IO 性能) | 366 |
| kunpeng-bios-cpu-prefetch-enabled-01 | cpu-high | 鲲鹏 BIOS 中硬件预取(CPU Prefetching)未关闭(影响数据库随机访问性能) | 411 |
| kunpeng-net-irq-not-bound-irqbalance-on-01 | network-latency | 鲲鹏服务器网卡中断未绑核(irqbalance 在线/中断分散到非本地 CPU) | 456 |
| linux-blockdev-nr-requests-too-low-01 | disk-io-saturation | 块设备 nr_requests 队列长度偏小(限制磁盘吞吐) | 516 |
| kvm-vcpupin-not-bound-numa-cross-01 | cpu-high | KVM 虚拟机 vCPU 未绑核(跨 NUMA / 跨 DIE 切换) | 561 |
| kvm-host-hugepages-not-allocated-tlb-miss-01 | memory-pressure | KVM Host 未分配大页(虚拟机 TLB Miss / 内存访问密集业务下降) | 606 |
| kunpeng-numa-cross-node-memory-access-01 | cpu-high | 跨 NUMA 节点访问内存导致应用性能下降 | 656 |
| kunpeng-network-irq-cross-numa-01 | network-latency | 网卡中断与网卡不在同一 NUMA 节点导致跨 NUMA 访问内存 | 701 |
| linux-nic-interrupt-coalescing-audit-01 | network-latency | 网卡中断聚合参数（ethtool -C）未按业务调优 | 751 |
| linux-rps-single-queue-nic-softirq-bottleneck-01 | network-latency | 单队列网卡软中断集中单 core 形成性能瓶颈（未启用 RPS） | 802 |
| linux-vm-dirty-flush-burst-io-wait-01 | disk-io-saturation | 脏页刷盘策略不当导致突发 I/O 等待与文件读写阻塞 | 859 |
| linux-block-scheduler-mismatch-01 | disk-io-saturation | I/O 调度器与磁盘类型/业务模式不匹配（HDD 数据库使用 CFQ；SSD 未用 NOOP） | 922 |
| linux-fs-mount-nobarrier-audit-01 | disk-io-saturation | 带电池 RAID 卡环境未使用 nobarrier 挂载选项 | 973 |
| linux-fs-xfs-blocksize-audit-01 | disk-io-saturation | 大文件场景未选用 XFS 文件系统或 blocksize 仍为默认 4KB | 1018 |
| kunpeng-arm64-spinlock-cas-cpu-waste-01 | cpu-high | 自旋锁/CAS 失败循环导致 CPU 资源浪费（perf top 锁函数占比 ≥ 5%） | 1069 |
| kunpeng-cacheline-false-sharing-arm64-128b-01 | cpu-high | x86 上对齐良好的代码迁移到鲲鹏 920（CacheLine 128B）出现伪共享 | 1132 |
| linux-vm-dirty-ratio-pause-on-large-memory-01 | disk-io-saturation | dirty_ratio 默认 20-30% 在大内存机上累积巨量脏页,触发同步 flush 卡顿 | 1183 |
| linux-thp-mongodb-sparse-memory-access-02 | memory-pressure | Transparent HugePages 在 MongoDB 稀疏内存访问场景下产生开销 | 1233 |
| linux-readahead-default-128kb-wastes-fs-cache-04 | memory-pressure | 块设备 read-ahead 默认 128KB 浪费 MongoDB 文件系统缓存 | 1284 |
