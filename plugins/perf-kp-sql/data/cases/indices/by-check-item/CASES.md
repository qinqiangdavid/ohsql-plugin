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

## check_id: chk-explain-analyze-2

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

## check_id: chk-costs

- **type**: metric
- **metric_name**: 执行计划costs
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze, verbose, buffers) <目标SQL>;`
- **abnormal_patterns**: ["costs > 1000"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sql-x01"]

## check_id: chk-seqscan

- **type**: metric
- **metric_name**: SeqScan算子
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze, verbose, buffers) <目标SQL>;`
- **abnormal_patterns**: ["如果有seqscan需要根据rows情况判断执行计划是否高效"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sql-x01"]

## check_id: chk-nestloop

- **type**: metric
- **metric_name**: NestLoop算子
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze, verbose, buffers) <目标SQL>;`
- **abnormal_patterns**: ["如果有nestloop需要考虑是否有参数下推的可能，同时也需要考虑数据量的情况，来判定nestloop是否高效"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sql-x01"]

## check_id: chk-cpu

- **type**: metric
- **metric_name**: CPU使用率
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] 在监控平台查看CPU`
- **abnormal_patterns**: ["100%","80%","tps下降时段cpu使用率升高"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x02","gaussdb-other-rto-x40","gaussdb-plan-suboptimal-x47"]

## check_id: chk-cpu-2

- **type**: metric
- **metric_name**: CPU核使用率
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] 使用杀猪刀工具抓取CPU使用率峰值时的数据`
- **abnormal_patterns**: ["99%"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x02"]

## check_id: chk-cpu-3

- **type**: metric
- **metric_name**: CPU堆栈
- **collection_layer**: flamegraph
- **collection_method**: `NULL`
- **abnormal_patterns**: ["这段时间的堆栈属于正常的业务流程，并无异常堆栈"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x02"]

## check_id: chk-sql

- **type**: metric
- **metric_name**: 慢SQL及调用频次
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["30w次/s"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x02"]

## check_id: chk-explain-performance

- **type**: metric
- **metric_name**: explain performance结果
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain performance <目标SQL>;`
- **abnormal_patterns**: ["没有语句不过滤分区键，未分区剪枝导致全表扫描的情况"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sql-x03"]

## check_id: chk-

- **type**: metric
- **metric_name**: 管理平台告警及通信层报错
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] 查看管理平台无网络、慢盘等告警，通信层无报错`
- **abnormal_patterns**: ["无网络、慢盘等告警，通信层无报错"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sql-x03"]

## check_id: chk-analyze

- **type**: metric
- **metric_name**: 业务数据入库及analyze情况与执行计划
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] 了解业务，发现业务每天该分区表都有近2亿条数据入库，入库后未做过analyze`
- **abnormal_patterns**: ["入库后未做过analyze，查看计划确实大的结果集条数走了nest loop导致较慢"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sql-x03"]

## check_id: chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo

- **type**: metric
- **metric_name**: recovery_max_workers/recovery_parse_workers/recovery_redo_workers
- **collection_layer**: db-shell
- **collection_method**: `show recovery_max_workers; show recovery_parse_workers; show recovery_redo_workers; show shared_buffers;`
- **abnormal_patterns**: ["可以结合环境的机器规格和资料判断配置是否合理"]
- **linked_case_ids**: ["gaussdb-other-x05"]

## check_id: chk--2

- **type**: metric
- **metric_name**: 回放日志类型统计
- **collection_layer**: db-interactive-cmd
- **collection_method**: `select * from local_xlog_redo_statics()`
- **abnormal_patterns**: ["关注特殊日志类型，尤其是ddl相关的xlog"]
- **linked_case_ids**: ["gaussdb-other-ddl-x07"]

## check_id: chk-print-redo-wal-count-info-print-redo-wal-time-info

- **type**: metric
- **metric_name**: print_redo_wal_count_info/print_redo_wal_time_info
- **collection_layer**: log-grep
- **collection_method**: `在备机的gs_log检索“print_redo_wal”关键字`
- **abnormal_patterns**: ["print_redo_wal_count_info显示的是该周期内新增回放数量（total num）最多的10种日志...print_redo_wal_time"]
- **linked_case_ids**: ["gaussdb-other-ddl-x07"]

## check_id: chk-redo-unlink-ddl

- **type**: metric
- **metric_name**: redo_unlink_ddl
- **collection_layer**: log-grep
- **collection_method**: `在gs_log中检索“redo_unlink_ddl”关键字`
- **abnormal_patterns**: ["可查看每10分钟周期内回放涉及删除文件的DDL数量"]
- **linked_case_ids**: ["gaussdb-other-ddl-x07"]

## check_id: chk-buffer-hit-rate-read-buffer-io

- **type**: metric
- **metric_name**: buffer_hit_rate / read_buffer_io
- **collection_layer**: db-interactive-cmd
- **collection_method**: `select * from gs_redo_stat_info()`
- **abnormal_patterns**: ["90%"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-x08"]

## check_id: chk-wait-read-data

- **type**: metric
- **metric_name**: WAIT_READ_DATA
- **collection_layer**: db-system-view
- **collection_method**: `select * from dbe_perf.GLOBAL_WAIT_EVENTS where wait!=0 order by total_wait_time desc;`
- **abnormal_patterns**: ["查看读写data的等待事件时延等判断回放的瓶颈"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-x08"]

## check_id: chk-buffer-hit-rate-wait-read-data

- **type**: metric
- **metric_name**: buffer_hit_rate / WAIT_READ_DATA
- **collection_layer**: log-grep
- **collection_method**: `在gs_log中检索“buffer_hit_rate”、“WAIT_READ_DATA”关键字`
- **abnormal_patterns**: ["可查看历史时间段上十分钟内回放线程的缓存命中率和等待事件统计信息"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-x08"]

## check_id: chk-q-use-q-max-use-rec-cnt

- **type**: metric
- **metric_name**: q_use / q_max_use / rec_cnt
- **collection_layer**: db-shell
- **collection_method**: `cm_ctl query -rv或者select * from local_redo_stat();`
- **abnormal_patterns**: ["主要观察q_use几个现场是否不均衡，如果不均衡的严重，那就是当前业务的特点导致cpu利用不充分"]
- **linked_case_ids**: ["gaussdb-data-skew-x09"]

## check_id: chk-queue-usage

- **type**: metric
- **metric_name**: queue usage
- **collection_layer**: log-grep
- **collection_method**: `在日志中搜索queue statistic`
- **abnormal_patterns**: ["有历史上各个线程队列的queue usage信息...可以从这里观察分发是否均匀"]
- **linked_case_ids**: ["gaussdb-data-skew-x09"]

## check_id: chk--3

- **type**: metric
- **metric_name**: 索引页面元组分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: `使用gs_parse_page_bypath函数解析索引表页面，分析表页面使用情况。`
- **abnormal_patterns**: ["大部分叶子页面内保存的索引元组中只有10+条，而页面1中保存了200+索引元组。"]
- **linked_case_ids**: ["gaussdb-other-key-x10"]

## check_id: chk-v-logfile

- **type**: metric
- **metric_name**: v$logfile
- **collection_layer**: db-system-view
- **collection_method**: `select * from v$logfile;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-lock-contention-sql-x11"]

## check_id: chk-pg-stat-activity

- **type**: metric
- **metric_name**: pg_stat_activity长事务执行时长
- **collection_layer**: db-system-view
- **collection_method**: `select current_timestamp - query_start as runtime,datname,usename,sessionid,substr(query,0,100) from pg_stat_activity where state != 'idle' and datname in('$database') and usename in ('$user') and extract(epoch from current_timestamp-xact_start)/60 > 1 order by 1 desc;`
- **abnormal_patterns**: ["> 1 (分钟)"]
- **linked_case_ids**: ["gaussdb-lock-contention-x12"]

## check_id: chk-pg-thread-wait-status

- **type**: metric
- **metric_name**: pg_thread_wait_status等待事件
- **collection_layer**: db-system-view
- **collection_method**: `select * from pg_thread_wait_status where sessionid in (select sessionid from pg_stat_activity where state != 'idle' and datname in('$database') and usename in ('$user') and extract(epoch from current_timestamp-xact_start)/60 > 1);`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-lock-contention-x12"]

## check_id: chk-pg-thread-wait-status-2

- **type**: metric
- **metric_name**: pg_thread_wait_status阻塞源会话
- **collection_layer**: db-system-view
- **collection_method**: `select * from pg_thread_wait_status where sessionid in (select block_sessionid from pg_thread_wait_status where sessionid in (select sessionid from pg_stat_activity where state != 'idle' and datname in('$database') and usename in ('$user') and extract(epoch from current_timestamp-xact_start)/60 > 1));`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-lock-contention-x12"]

## check_id: chk-gs-asp-2

- **type**: metric
- **metric_name**: gs_asp历史长事务采样记录
- **collection_layer**: db-system-view
- **collection_method**: `SELECT DISTINCT a.xact_start_time, (a.sample_time - a.xact_start_time) as xact_run_time, a.thread_id, a.sessionid, d.datname AS database_name, u.usename AS username, a.application_name,a.client_addr, a.client_hostname FROM gs_asp a JOIN pg_database d ON a.databaseid = d.oid JOIN pg_user u ON a.userid = u.usesysid WHERE a.xact_start_time is not null AND username not in ('rdsAdmin') AND sample_time between '<日期> 某时刻' and '<日期> 某时刻' AND extract(epoch from xact_run_time)/60 > 1 --自定义执行时长，表示执行时间超过1min的事务 ORDER BY xact_run_time DESC;`
- **abnormal_patterns**: ["> 1 (分钟)"]
- **linked_case_ids**: ["gaussdb-lock-contention-x12"]

## check_id: chk-io

- **type**: metric
- **metric_name**: 磁盘IO信息
- **collection_layer**: os
- **collection_method**: `iostat -c -x -m -t 5`
- **abnormal_patterns**: ["磁盘的iowait过高"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-bm25-x13"]

## check_id: chk-wait-event-count

- **type**: metric
- **metric_name**: wait_event_count
- **collection_layer**: db-system-view
- **collection_method**: `select wait_status,wait_event,count(*) from pg_thread_wait_status group by wait_status,wait_event order by 3 desc;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-lock-contention-x14"]

## check_id: chk-blocked-query

- **type**: metric
- **metric_name**: blocked_query
- **collection_layer**: db-system-view
- **collection_method**: `select pid,sessionid,substr(query,0,100) from pg_stat_activity where sessionid in(select sessionid from pg_thread_wait_status where wait_event='wait_event');`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-lock-contention-x14"]

## check_id: chk-blocking-query

- **type**: metric
- **metric_name**: blocking_query
- **collection_layer**: db-system-view
- **collection_method**: `select pid,sessionid,substr(query,0,100) from pg_stat_activity where sessionid in(select block_sessionid from pg_thread_wait_status where wait_event='wait_event');`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-lock-contention-x14"]

## check_id: chk-pg-total-memory-detail

- **type**: metric
- **metric_name**: pg_total_memory_detail
- **collection_layer**: db-system-view
- **collection_method**: `select * from pg_total_memory_detail;`
- **abnormal_patterns**: ["如果dynamic_used_memory较大，dynamic_used_shrctx较小，则可以确认是线程和session上内存占用较多；如果dynamic_"]
- **linked_case_ids**: ["gaussdb-memory-pressure-x16"]

## check_id: chk-thread-session-memory-context

- **type**: metric
- **metric_name**: thread_session_memory_context
- **collection_layer**: db-system-view
- **collection_method**: `select contextname, sum(totalsize)/1024/1024 totalsize, sum(freesize)/1024/1024 freesize, count(*) sum from gs_thread_memory_context group by contextname order by sum desc limit 10;`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-memory-pressure-x16"]

## check_id: chk-last-analyze-time

- **type**: metric
- **metric_name**: last_analyze_time
- **collection_layer**: db-system-view
- **collection_method**: `select * from PG_STAT_ALL_TABLES where relname='tablename';`
- **abnormal_patterns**: ["确定系统/手动上一次 ANALYZE 是否过久。"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-x17"]

## check_id: chk-autovacuum-settings

- **type**: metric
- **metric_name**: autovacuum_settings
- **collection_layer**: db-system-view
- **collection_method**: `select * from pg_settings where name like '%vacuum%';`
- **abnormal_patterns**: ["如果 autovacuum 被关闭或配置阈值过高，则表更新后可能长期没有触发自动分析。"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-x17"]

## check_id: chk-autoanalyze-threshold

- **type**: metric
- **metric_name**: autoanalyze_threshold
- **collection_layer**: db-interactive-cmd
- **collection_method**: `select * from pg_stat_get_tuples_changed('table_name'::REGCLASS); select pg_autovac_status('table_name'::REGCLASS);`
- **abnormal_patterns**: ["确认是否达到触发autoanalyze阈值"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-x17"]

## check_id: chk-pg-index-indisusable

- **type**: metric
- **metric_name**: pg_index_indisusable
- **collection_layer**: db-system-view
- **collection_method**: `SELECT indexrelid，indisusable FROM pg_index WHERE indrelid = '<table>'::regclass;`
- **abnormal_patterns**: ["false"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-x18"]

## check_id: chk-cpu-io

- **type**: metric
- **metric_name**: CPU、IO、内存使用率
- **collection_layer**: os
- **collection_method**: `通过htop查看CPU、IO、内存使用情况`
- **abnormal_patterns**: ["CPU还没有压满，内存充足。未发现异常"]
- **linked_case_ids**: ["gaussdb-other-tps-x19"]

## check_id: chk-wait-cmd

- **type**: metric
- **metric_name**: wait cmd计数
- **collection_layer**: db-system-view
- **collection_method**: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
- **abnormal_patterns**: ["发现wait cmd计数很多，属于异常现象。"]
- **linked_case_ids**: ["gaussdb-other-tps-x19"]

## check_id: chk-tplworker-cpu-idle

- **type**: metric
- **metric_name**: TPLworker数量 / CPU idle空闲
- **collection_layer**: flamegraph
- **collection_method**: `NULL`
- **abnormal_patterns**: ["正常节点的TPLworker数量达到690个，但是异常节点的TPLworker数量只有380个"]
- **linked_case_ids**: ["gaussdb-other-tps-x19"]

## check_id: chk-offcpu

- **type**: metric
- **metric_name**: offcpu火焰图
- **collection_layer**: flamegraph
- **collection_method**: `/usr/share/bcc/tools/offcputime -df -p <pid> 30 > off.stacks && flamegraph.pl off.stacks > offcpu.svg`
- **abnormal_patterns**: ["波动时（即下图中红框CPU利用率低的区段），由于受到日志扩页的影响，TPLworker线程都在等待日志插入","备机日志预扩同样存在阻塞"]
- **linked_case_ids**: ["gaussdb-other-tpcc-x20","gaussdb-other-tpcc-x21"]

## check_id: chk-n-tuples-fetched-n-tuples-returned

- **type**: metric
- **metric_name**: n_tuples_fetched / n_tuples_returned
- **collection_layer**: db-system-view
- **collection_method**: `查询dbe_perf.statement_history`
- **abnormal_patterns**: ["n_tuples_fetched = 2 * n_tuples_returned"]
- **linked_case_ids**: ["gaussdb-other-astore-x22"]

## check_id: chk-t-tuples-fetched

- **type**: metric
- **metric_name**: t_tuples_fetched累加次数
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 通过gdb获取上述t_counts中的t_tuples_returned变量地址，通过watch该地址观察到t_tupl`
- **abnormal_patterns**: ["单轮获取过程中累加2次"]
- **linked_case_ids**: ["gaussdb-other-astore-x22"]

## check_id: chk-subtransactions-log

- **type**: metric
- **metric_name**: subtransactions log
- **collection_layer**: log-grep
- **collection_method**: `日志中可以尝试搜索关键字Transaction %lu has reached %d subtransactions!`
- **abnormal_patterns**: ["50000"]
- **linked_case_ids**: ["gaussdb-memory-pressure-other-x23"]

## check_id: chk-xact-is-current-xid

- **type**: metric
- **metric_name**: 事务可见性判断函数(xact_is_current_xid)耗时
- **collection_layer**: flamegraph
- **collection_method**: `NULL`
- **abnormal_patterns**: ["子事务嵌套，导致访问数据时，事务可见性判断代价大，也即火焰图中xact_is_current_xid函数；判断所访问数据可见性时，会遍历查询当前事务块管理的事务"]
- **linked_case_ids**: ["gaussdb-query-slow-autosave-x24"]

## check_id: chk--4

- **type**: metric
- **metric_name**: 保存点数量开销
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] NULL`
- **abnormal_patterns**: ["查询语句，也会生成保存点，存在不必要的保存点开销，并且使“瓶颈1”加剧"]
- **linked_case_ids**: ["gaussdb-query-slow-autosave-x24"]

## check_id: chk-sql-2

- **type**: metric
- **metric_name**: 保存点SQL解析开销
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] NULL`
- **abnormal_patterns**: ["显式保存点，存在SQL解析开销"]
- **linked_case_ids**: ["gaussdb-query-slow-autosave-x24"]

## check_id: chk-sql-cpu

- **type**: metric
- **metric_name**: SQL CPU消耗
- **collection_layer**: db-system-view
- **collection_method**: `select * from gs_asp where sample_time > now() - interval '10 minute' order by sample_time;`
- **abnormal_patterns**: ["消耗CP高的SQL"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x25"]

## check_id: chk--5

- **type**: metric
- **metric_name**: 索引列过滤性
- **collection_layer**: db-interactive-cmd
- **collection_method**: `select attname, n_distinct, most_common_vals from pg_stats where tablename='<表>';`
- **abnormal_patterns**: ["cus_idr过滤性不好，crt_dttm的过滤性好一些"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x25"]

## check_id: chk--6

- **type**: metric
- **metric_name**: 活跃会话数
- **collection_layer**: db-system-view
- **collection_method**: `查看gs_asp视图查看活跃会话数在冲高时间点`
- **abnormal_patterns**: ["92并发在同时运行"]
- **linked_case_ids**: ["gaussdb-cpu-high-index-x26"]

## check_id: chk--7

- **type**: metric
- **metric_name**: 执行计划索引扫描范围
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze, verbose, buffers) <目标SQL>;`
- **abnormal_patterns**: ["在索引扫描时扫描大量的页面，会消耗大量的CPU。使用的主键索引的后两列，没有使用第一列，导致扫描索引的所有页面"]
- **linked_case_ids**: ["gaussdb-cpu-high-index-x26"]

## check_id: chk-asp

- **type**: metric
- **metric_name**: ASP数据/等待事件
- **collection_layer**: db-system-view
- **collection_method**: `select * from gs_asp where sample_time > now() - interval '10 minute' order by sample_time;`
- **abnormal_patterns**: ["大量的线程正在等待LockMgrLock。"]
- **linked_case_ids**: ["gaussdb-lock-contention-ddl-x27"]

## check_id: chk-other

- **type**: metric
- **metric_name**: other内存增长趋势
- **collection_layer**: db-system-view
- **collection_method**: `select * from pg_total_memory_detail;`
- **abnormal_patterns**: ["jemalloc调优对于业务场景没有生效，other内存依然稳定斜率上涨。"]
- **linked_case_ids**: ["gaussdb-memory-pressure-other-x28"]

## check_id: chk--8

- **type**: metric
- **metric_name**: 内存泄漏信息
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] memcheck，1:1展开复现业务，打印如下泄露信息`
- **abnormal_patterns**: ["确认到是使用CRYPTO_zalloc存在未释放现象。"]
- **linked_case_ids**: ["gaussdb-memory-pressure-other-x28"]

## check_id: chk--9

- **type**: metric
- **metric_name**: 代码调用栈/未释放函数
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 进一步排查代码发现在pymysql驱动建连时，RSA鉴权过程中存在内存未及时释放的情况`
- **abnormal_patterns**: ["调用了 EVP_PKEY_CTX_new，但未调用对应的 EVP_PKEY_CTX_free"]
- **linked_case_ids**: ["gaussdb-memory-pressure-other-x28"]

## check_id: chk--10

- **type**: metric
- **metric_name**: 执行计划
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze, verbose, buffers) <目标SQL>;`
- **abnormal_patterns**: ["计划中未提升","NestLoop Anti Join的内表是大表，且无过滤条件，导致全表扫描数据","查看计划显示SEQSCAN","性能瓶颈在两处seqscan上，且上面有一层Stream算子","存在seq scan全表扫描导致耗时长（1000ms+）","筛选条件有索引，但没走上索引，说明优化器评估SeqScan的代价比IndexScan更低","通过TID SCAN更新一行记录遍历了289个分区","t表走了seqscan","过滤条件client_acnt_id = '1221'没有触发索引扫描","理论上恒为false的第二个union all并未被提前过滤掉"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-exists-x29","gaussdb-plan-suboptimal-not-x30","gaussdb-plan-suboptimal-x31","gaussdb-plan-suboptimal-seqscan-x33","gaussdb-query-slow-sql-x42","gaussdb-other-ustore-x45","gaussdb-plan-suboptimal-x47","gaussdb-plan-suboptimal-union-x56","gaussdb-plan-suboptimal-x57","gaussdb-plan-suboptimal-union-x58"]

## check_id: chk-provolatile-proshippable

- **type**: metric
- **metric_name**: 函数属性(provolatile/proshippable)
- **collection_layer**: db-system-view
- **collection_method**: `select proname, provolatile, proshippable from pg_proc where proname='<函数名>';`
- **abnormal_patterns**: ["clock_timestamp函数的provolatile属性为‘v’不稳定的，而且proshippable为空"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sysdate-x32"]

## check_id: chk-sql-3

- **type**: metric
- **metric_name**: 慢SQL数量及系统库大小
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["系统库大小8GB，慢SQL数量600万条"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-tps-x34"]

## check_id: chk--11

- **type**: metric
- **metric_name**: 备机日志刷盘影响
- **collection_layer**: db-interactive-cmd
- **collection_method**: `将GUC参数synchronous_commit设置为local进行长稳测试。`
- **abnormal_patterns**: ["将参数设置为local后，测试结果仍然存在TPS波动问题，排除备机日志刷盘对TPS波动的影响。"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-tps-x34"]

## check_id: chk-wdr

- **type**: metric
- **metric_name**: WDR报告与等待事件
- **collection_layer**: db-system-view
- **collection_method**: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
- **abnormal_patterns**: ["随着压测的进行，数据量增大，导致内存和磁盘之间的缓冲池buffer pool被填满，需要和磁盘进行换入换出，CPU的IO等待占比增大，导致TPS下降。"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-tps-x34"]

## check_id: chk--12

- **type**: metric
- **metric_name**: 线程等待磁盘返回结果
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] 在长稳测试TPS出现抖动时，抓取当前系统内的所有线程信息，通过杀猪刀工具分析发现`
- **abnormal_patterns**: ["等待时间为20ms~50ms"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-tps-x34"]

## check_id: chk-procarraylock

- **type**: metric
- **metric_name**: 等待事件ProcArrayLock
- **collection_layer**: db-system-view
- **collection_method**: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
- **abnormal_patterns**: ["数据库TOP1 等待事件ProcArrayLock"]
- **linked_case_ids**: ["gaussdb-lock-contention-procarraylock-x35"]

## check_id: chk--13

- **type**: metric
- **metric_name**: 分布式事务两阶段提交火焰图
- **collection_layer**: flamegraph
- **collection_method**: `NULL`
- **abnormal_patterns**: ["ProcArrayLock大锁的现在表现最明显的是在prepare阶段"]
- **linked_case_ids**: ["gaussdb-lock-contention-procarraylock-x35"]

## check_id: chk--14

- **type**: metric
- **metric_name**: 语句执行情况与执行计划
- **collection_layer**: db-interactive-cmd
- **collection_method**: `通过gs_asp查看对应时间段的语句执行情况`
- **abnormal_patterns**: ["大批量语句计划变为seqscan，导致消耗大量资源，引发CPU冲高。"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x36"]

## check_id: chk--15

- **type**: metric
- **metric_name**: 代价估算与页面数
- **collection_layer**: db-system-view
- **collection_method**: `识别上面的代价估算较低，仅为18，证明pg_class中记录的页面数较少。`
- **abnormal_patterns**: ["18"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x36"]

## check_id: chk-vacuum

- **type**: metric
- **metric_name**: vacuum执行记录
- **collection_layer**: log-grep
- **collection_method**: `通过pg_log,发现在某时刻开始，针对<库名> 中的分区sys_p22进行了vacuum。`
- **abnormal_patterns**: ["此表在导数后，直到25日前，未触发vacuum 并且此表分区间存在严重的数据倾斜"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x36"]

## check_id: chk-sql-4

- **type**: metric
- **metric_name**: 慢SQL与计划跳变排查
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, count(*) from dbe_perf.statement_history where start_time > 'XXX' and start_time < 'XXX' group by 1 order by 2 desc; <br> select unique_query_id, query, query_plan from dbe_perf.statement_history where unique_query_id in (XXX,XXX); <br> select unique_query_id, count(*) from dbe_perf.local_active_session where sample_time > 'XXX' and sample_time < 'XXX' group by 1 order by 2 desc; <br> select unique_sql_id, query from dbe_perf.summary_statement where unique_sql_id in ('XXX', 'XXX');`
- **abnormal_patterns**: ["若预期该语句应该index_scan但plan中出现seq_scan，则初步判断出现了计划跳变。"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x36"]

## check_id: chk--16

- **type**: metric
- **metric_name**: 分区表统计信息准确性
- **collection_layer**: db-system-view
- **collection_method**: `with sizeinfo as (select relname, parentid, pg_partition_size(parentid, oid) partsize, relpages from pg_partition where parttype = 'p') select tablename,tablesize/1024 as "size(KB)", pages*8.192 as "page(KB)" from (select parentid::regclass as tablename, sum(partsize) as tablesize, sum(relpages) as pages from sizeinfo group by parentid) where tablesize > 1000000 and pages < 10000 and pages*8192.0/tablesize < 0.1;`
- **abnormal_patterns**: ["pages*8192.0/tablesize < 0.1"]
- **linked_case_ids**: ["gaussdb-cpu-high-cpu-x36"]

## check_id: chk-last-vacuum

- **type**: metric
- **metric_name**: last_vacuum
- **collection_layer**: db-system-view
- **collection_method**: `查看相关表的日志，以及pg_stat_all_tables视图，通过其中的last_vacuum字段`
- **abnormal_patterns**: ["确认相关表在创建后从未vacuum"]
- **linked_case_ids**: ["gaussdb-query-slow-dataarts-x37"]

## check_id: chk-n-tup-hot-upd-n-tup-upd-n-dead-tup-n-live-tup

- **type**: metric
- **metric_name**: n_tup_hot_upd / n_tup_upd / n_dead_tup / n_live_tup
- **collection_layer**: db-system-view
- **collection_method**: `在pg_stat_all_tables中表现如下`
- **abnormal_patterns**: ["HOT更新（n_tup_hot_upd），即一个元组的更新在同一block内，在所有更新（n_tup_upd）中占比很小。说明变长更新导致本来的原地更新，由于没"]
- **linked_case_ids**: ["gaussdb-query-slow-dataarts-x37"]

## check_id: chk--17

- **type**: metric
- **metric_name**: 变长更新语句
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] 对业务语句检查`
- **abnormal_patterns**: ["发现有很多变长更新的语句，如对某列更新为null之后，又更新为128长度char类型"]
- **linked_case_ids**: ["gaussdb-query-slow-dataarts-x37"]

## check_id: chk-thread-pool-attr

- **type**: metric
- **metric_name**: thread_pool_attr
- **collection_layer**: db-shell
- **collection_method**: `show thread_pool_attr;`
- **abnormal_patterns**: ["在现有的出口参数线程池CPU亲和设置模式下会经常触发跨NUMA"]
- **linked_case_ids**: ["gaussdb-other-tpcc-x38"]

## check_id: chk-rpo

- **type**: metric
- **metric_name**: 容灾RPO
- **collection_layer**: db-system-view
- **collection_method**: `select* from gs_hadr_remote_rto_and_rpo_stat();`
- **abnormal_patterns**: ["确实发现容灾RPO高"]
- **linked_case_ids**: ["gaussdb-other-rpo-x39"]

## check_id: chk--18

- **type**: metric
- **metric_name**: 复制槽推动速度
- **collection_layer**: db-system-view
- **collection_method**: `select * from dbe_perf.global_replication_stat;`
- **abnormal_patterns**: ["主集群产生的xlog速度，明显比接收的速度要快的多"]
- **linked_case_ids**: ["gaussdb-other-rpo-x39"]

## check_id: chk--19

- **type**: metric
- **metric_name**: 网络带宽使用率
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] 向客户方网络侧确认`
- **abnormal_patterns**: ["确实在异常时间段网络带宽占满"]
- **linked_case_ids**: ["gaussdb-other-rpo-x39"]

## check_id: chk-io-2

- **type**: metric
- **metric_name**: IO相关等待事件平均时间
- **collection_layer**: db-system-view
- **collection_method**: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
- **abnormal_patterns**: ["读取数据页面、读取wal日志等回放相关等待事件平均时间更长"]
- **linked_case_ids**: ["gaussdb-other-rto-x40"]

## check_id: chk-io-io

- **type**: metric
- **metric_name**: 磁盘IO性能和IO调度算法
- **collection_layer**: os
- **collection_method**: `grep -H . /sys/block/*/queue/scheduler 2>/dev/null`
- **abnormal_patterns**: ["无明显区别"]
- **linked_case_ids**: ["gaussdb-other-rto-x40"]

## check_id: chk-cpu-4

- **type**: metric
- **metric_name**: 线程CPU占用率
- **collection_layer**: os
- **collection_method**: `top分析线程CPU占用`
- **abnormal_patterns**: ["问题节点某问题DN回放相关线程CPU占用率较低（相对于对照节点某对照DN），同时某问题DN整体CPU占用率也低于某对照DN"]
- **linked_case_ids**: ["gaussdb-other-rto-x40"]

## check_id: chk-xlog

- **type**: metric
- **metric_name**: xlog生成速率
- **collection_layer**: db-system-view
- **collection_method**: `select * from dbe_perf.global_replication_stat;`
- **abnormal_patterns**: ["20%"]
- **linked_case_ids**: ["gaussdb-other-rto-x40"]

## check_id: chk-pgxc-stat-activity-state

- **type**: metric
- **metric_name**: pgxc_stat_activity state
- **collection_layer**: db-system-view
- **collection_method**: `select state, count(*) from pgxc_stat_activity group by state;`
- **abnormal_patterns**: ["基本活跃会话很少，事务执行过程中状态较多，基本都在等待业务服务器向数据库发数据"]
- **linked_case_ids**: ["gaussdb-other-tps-x41"]

## check_id: chk-io-3

- **type**: metric
- **metric_name**: IO使用率
- **collection_layer**: os
- **collection_method**: `iostat -x -m 5 3`
- **abnormal_patterns**: ["数据库的IO使用率非常高"]
- **linked_case_ids**: ["gaussdb-other-tps-x41"]

## check_id: chk-cn

- **type**: metric
- **metric_name**: CN节点压力分布
- **collection_layer**: db-system-view
- **collection_method**: `select coorname, count(*) from pgxc_stat_activity group by coorname order by 2 desc;`
- **abnormal_patterns**: ["微服务压力只发往AZ1内一个CN，另外一个CN无压力"]
- **linked_case_ids**: ["gaussdb-other-tps-x41"]

## check_id: chk-druid

- **type**: metric
- **metric_name**: druid连接配置
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] NULL`
- **abnormal_patterns**: ["druid最小连接配置较小，仅20，会导致压测过程开始时建连排队"]
- **linked_case_ids**: ["gaussdb-other-tps-x41"]

## check_id: chk-druid-monitor

- **type**: metric
- **metric_name**: druid monitor排队情况
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] NULL`
- **abnormal_patterns**: ["在微服务连接池druid上，出现排队"]
- **linked_case_ids**: ["gaussdb-other-tps-x41"]

## check_id: chk--20

- **type**: metric
- **metric_name**: 锁等待事件
- **collection_layer**: db-system-view
- **collection_method**: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
- **abnormal_patterns**: ["出现了并发更新"]
- **linked_case_ids**: ["gaussdb-query-slow-sql-x42"]

## check_id: chk--21

- **type**: metric
- **metric_name**: 业务代码逻辑
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] 排查业务代码发现主键更新语句的条件（主键）为单一固定值`
- **abnormal_patterns**: ["高并发压测时会出现并发更新等待事务锁和元组锁的现象"]
- **linked_case_ids**: ["gaussdb-query-slow-sql-x42"]

## check_id: chk-wal

- **type**: metric
- **metric_name**: WAL日志产生量
- **collection_layer**: log-grep
- **collection_method**: `通过计算日志里的LSN节点可知`
- **abnormal_patterns**: ["10GB/h"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-wal-x43"]

## check_id: chk-wal-2

- **type**: metric
- **metric_name**: WAL日志类型占比
- **collection_layer**: log-grep
- **collection_method**: `对WAL日志分析可知`
- **abnormal_patterns**: [">50%"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-wal-x43"]

## check_id: chk-freeze-page

- **type**: metric
- **metric_name**: Freeze Page操作有效性
- **collection_layer**: log-grep
- **collection_method**: `对产生的Freeze Page 类型WAL日志分析`
- **abnormal_patterns**: ["nfrozen = 0"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-wal-x43"]

## check_id: chk--22

- **type**: metric
- **metric_name**: 磁盘读写线程
- **collection_layer**: db-system-view
- **collection_method**: `识别磁盘读异常SQL(根据异常IO线程号查询pg_stat_activity + pg_thread_wait_status)`
- **abnormal_patterns**: ["磁盘读都是Vacuum操作 / 磁盘写主要是pagewriter线程"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-wal-x43"]

## check_id: chk--23

- **type**: metric
- **metric_name**: 运行时堆栈
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 检查运行时堆栈`
- **abnormal_patterns**: ["发现在清理该Ustore分区表上的其中一个GPI索引"]
- **linked_case_ids**: ["gaussdb-other-autovacuum-x44"]

## check_id: chk-gs-log

- **type**: metric
- **metric_name**: gs_log日志清理时长
- **collection_layer**: log-grep
- **collection_method**: `检查gs_log日志`
- **abnormal_patterns**: ["13天"]
- **linked_case_ids**: ["gaussdb-other-autovacuum-x44"]

## check_id: chk-wal-3

- **type**: metric
- **metric_name**: WAL日志清理模式
- **collection_layer**: log-grep
- **collection_method**: `检查WAL日志`
- **abnormal_patterns**: ["O(n²)"]
- **linked_case_ids**: ["gaussdb-other-autovacuum-x44"]

## check_id: chk--24

- **type**: metric
- **metric_name**: 事务日志内容
- **collection_layer**: db-interactive-cmd
- **collection_method**: `使用gs_xlogdump_xid()系统函数获取被查杀事务对应的日志`
- **abnormal_patterns**: ["事务生成的日志中，全都是对heap进行WAL_UHEAP_CLEAN操作，并非元组删除操作。"]
- **linked_case_ids**: ["gaussdb-other-ustore-x45"]

## check_id: chk-undo-retention-time

- **type**: metric
- **metric_name**: undo_retention_time
- **collection_layer**: db-system-view
- **collection_method**: `show undo_retention_time;`
- **abnormal_patterns**: ["900s"]
- **linked_case_ids**: ["gaussdb-other-ustore-x45"]

## check_id: chk-wait-node

- **type**: metric
- **metric_name**: wait node等待事件耗时
- **collection_layer**: db-system-view
- **collection_method**: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
- **abnormal_patterns**: ["等待事件的计时是从pgstat_report_waitstatus_comm函数上报“wait node”时开始的，但是在pgstat_reset_waitSt"]
- **linked_case_ids**: ["gaussdb-query-slow-insert-x46"]

## check_id: chk-cn-dn

- **type**: metric
- **metric_name**: CN和DN间网络交互次数
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 从代码流程上看，单条INSERT语句在执行过程中，CN和DN间会有多次网络交互`
- **abnormal_patterns**: ["CN上wait node事件统计的是3次网络交互的总体开销，而DN上慢SQL视图里面记录的只是一次INSERT语句的耗时"]
- **linked_case_ids**: ["gaussdb-query-slow-insert-x46"]

## check_id: chk-poll-interrupt

- **type**: metric
- **metric_name**: poll_interrupt接口耗时/线程唤醒耗时
- **collection_layer**: log-grep / flamegraph
- **collection_method**: `从日志中我们发现，CN在调用poll_interrupt接口等待DN回复消息时存在偶现时延增大到4ms的情况。 / 我们抓取了火焰图`
- **abnormal_patterns**: ["4ms"]
- **linked_case_ids**: ["gaussdb-query-slow-insert-x46"]

## check_id: chk-oncpu

- **type**: metric
- **metric_name**: oncpu信息
- **collection_layer**: flamegraph
- **collection_method**: `NULL`
- **abnormal_patterns**: ["cpu主要消耗在事务提交时关闭文件操作"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-x47"]

## check_id: chk-sql-5

- **type**: metric
- **metric_name**: 慢sql语句
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["找到commit语句，然后根据事务id找到对应事务的sql语句"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-x47"]

## check_id: chk--25

- **type**: metric
- **metric_name**: 网络包时延
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] 针对建连报错的应用环境上进行抓包`
- **abnormal_patterns**: ["4s"]
- **linked_case_ids**: ["gaussdb-cpu-high-jdbc-x48"]

## check_id: chk-cpu-5

- **type**: metric
- **metric_name**: CPU消耗分布
- **collection_layer**: flamegraph
- **collection_method**: `NULL`
- **abnormal_patterns**: ["客户端大部分CPU消耗在密码迭代加密的流程上"]
- **linked_case_ids**: ["gaussdb-cpu-high-jdbc-x48"]

## check_id: chk-dropped-packets-count

- **type**: metric
- **metric_name**: dropped packets count
- **collection_layer**: db-shell
- **collection_method**: `cat /proc/net/dev`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-other-x49"]

## check_id: chk-rx-dropped-call-stack

- **type**: metric
- **metric_name**: rx_dropped call stack
- **collection_layer**: os
- **collection_method**: `perf record -o perf_lo_drop.data -a -g -e mem:0xffff920fc37b31c8:w -- sleep 10`
- **abnormal_patterns**: ["调用栈数量也基本和ifconfig lo统计dropped的差值相同，所以只需分析以上调用栈即可。...实际晚上perf监控一晚发现所有lo的丢包都来自于avc"]
- **linked_case_ids**: ["gaussdb-other-x49"]

## check_id: chk-net-core-netdev-max-backlog

- **type**: metric
- **metric_name**: net.core.netdev_max_backlog
- **collection_layer**: os
- **collection_method**: `sysctl net.core.netdev_max_backlog`
- **abnormal_patterns**: ["1000"]
- **linked_case_ids**: ["gaussdb-other-x49"]

## check_id: chk-cpu-cpu-io-tpmc-xlog

- **type**: metric
- **metric_name**: 备机CPU、主机CPU、内存使用率、IO、TPMC、Xlog回放速度、日志生成速度
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] 8C规格极致RTO和并行回放对资源的消耗，跑TPCC数据量 70仓，70并发，分别测试极致RTO场景`
- **abnormal_patterns**: ["极致RTO配置三相比并行回放CPU和内存消耗高20%，且回放略有下降；配置三线程数量较多，资源争用严重，效果不太明显"]
- **linked_case_ids**: ["gaussdb-other-rto-x50"]

## check_id: chk--26

- **type**: metric
- **metric_name**: 死元组数/表占用空间
- **collection_layer**: db-system-view
- **collection_method**: `select relname, n_dead_tup, pg_relation_size(relid) sz from pg_stat_all_tables where relname='<表>';`
- **abnormal_patterns**: ["死元组3600w+，表占用309GB"]
- **linked_case_ids**: ["gaussdb-other-ustore-x51"]

## check_id: chk-toast

- **type**: metric
- **metric_name**: toast表空间占用
- **collection_layer**: db-system-view
- **collection_method**: `select pg_relation_size(reltoastrelid) from pg_class where relname='<表>';`
- **abnormal_patterns**: ["发现膨胀的主要再toast表上"]
- **linked_case_ids**: ["gaussdb-other-ustore-x51"]

## check_id: chk--27

- **type**: metric
- **metric_name**: 列长度/事务更新频次
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] NULL`
- **abnormal_patterns**: ["列长度>2k字节; 单事务内大量update"]
- **linked_case_ids**: ["gaussdb-other-ustore-x51"]

## check_id: chk-wait-xact-commit-command

- **type**: metric
- **metric_name**: wait xact commit command耗时
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["1535511 (us)"]
- **linked_case_ids**: ["gaussdb-lock-contention-commit-x52"]

## check_id: chk-palm-hang-detect-main

- **type**: metric
- **metric_name**: palm_hang_detect_main等待锁日志
- **collection_layer**: log-grep
- **collection_method**: `gaussdb-<日期>_180856.log.gz:<日期> 某时刻.054 dn_6007_6008_6009 [unkown] [unknown] localhost 281279935201968 0[0:0#0] 0 dn_6007 0 [BACKEND] WARNING: palm_hang_detect_main Cur time is 785847582052464, need_wait_time is 785847577052464, oldest_time is 785847564558141; wait_lock_type(4).`
- **abnormal_patterns**: ["WARNING: palm_hang_detect_main Cur time is 785847582052464, need_wait_time is 78"]
- **linked_case_ids**: ["gaussdb-lock-contention-commit-x52"]

## check_id: chk-execution-time

- **type**: metric
- **metric_name**: execution_time
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["583689 (us)"]
- **linked_case_ids**: ["gaussdb-query-slow-x53"]

## check_id: chk-lwlock-event-procarraylock

- **type**: metric
- **metric_name**: LWLOCK_EVENT ProcArrayLock等待事件
- **collection_layer**: db-system-view
- **collection_method**: `Wait Events Area: ‘1’ LWLOCK_EVENT ProcArrayLock 11700 (us)`
- **abnormal_patterns**: ["11700 (us)"]
- **linked_case_ids**: ["gaussdb-query-slow-x53"]

## check_id: chk-unlink-half-dead-page

- **type**: metric
- **metric_name**: unlink_half_dead_page索引日志
- **collection_layer**: log-grep
- **collection_method**: `<日期> 某时刻.143 dn_6001_6002_6003 mecs mecs <IP> 281222782959760 375685[11206835某时刻7457#30802] 213523483 cn_5001 73183494132910882 [UBTREE] LOG: [unlink_half_dead_page:1386] IndexRnode:{16某时刻7某时刻227:-1} Xid:{213523483}. valid left sibling for deletion target could not be located: left sibling postmaster pool start, fd nums:4`
- **abnormal_patterns**: ["valid left sibling for deletion target could not be located"]
- **linked_case_ids**: ["gaussdb-query-slow-x53"]

## check_id: chk-sql-6

- **type**: metric
- **metric_name**: 慢SQL等待事件统计
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["没有抓到长时间的等待事件"]
- **linked_case_ids**: ["gaussdb-lock-contention-x54"]

## check_id: chk-cpu-io-2

- **type**: metric
- **metric_name**: CPU、内存、IO使用率
- **collection_layer**: os
- **collection_method**: `top -Hp <pid>`
- **abnormal_patterns**: ["CPU、内存、IO 使用率均很低"]
- **linked_case_ids**: ["gaussdb-lock-contention-x54"]

## check_id: chk--28

- **type**: metric
- **metric_name**: 轻量级锁排他锁等待时间日志
- **collection_layer**: log-grep
- **collection_method**: `登录客户生产环境进行查询，确实找到了对应的日志打印`
- **abnormal_patterns**: ["5s"]
- **linked_case_ids**: ["gaussdb-lock-contention-x54"]

## check_id: chk--29

- **type**: metric
- **metric_name**: 轻量级锁持锁到放锁的时长
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 统计轻量级锁持锁到放锁的时长`
- **abnormal_patterns**: ["并没有发现单个轻量级锁持锁时间过长的情况"]
- **linked_case_ids**: ["gaussdb-lock-contention-x54"]

## check_id: chk--30

- **type**: metric
- **metric_name**: 持锁、等锁线程堆栈
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 在一套生产环境部署了脚本，进行持锁、等锁线程堆栈的抓取`
- **abnormal_patterns**: ["所有抓到的持锁线程都是 checkpoint；一般来说，出现该warning日志时查询gs_lwlock_status系统函数都会出现等锁的现象，但是在日志打印"]
- **linked_case_ids**: ["gaussdb-lock-contention-x54"]

## check_id: chk-sql-7

- **type**: metric
- **metric_name**: 防饿死线程日志与慢SQL现象
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] 对家里测试环境的 guc 参数进行了调整，加速了 checkpoint 的频率`
- **abnormal_patterns**: ["家里也复现出了防饿死线程的日志打印与慢 SQL 现象"]
- **linked_case_ids**: ["gaussdb-lock-contention-x54"]

## check_id: chk-sql-8

- **type**: metric
- **metric_name**: 慢SQL出现频率
- **collection_layer**: manual-business
- **collection_method**: `[需确认业务] 观察关闭防饿死开关enable_wait_exclusive_lock 前后，问题出现频率`
- **abnormal_patterns**: ["启用防饿死机制时，稳定复现原问题；不启用防饿死机制时，稳定不出现原问题"]
- **linked_case_ids**: ["gaussdb-lock-contention-x54"]

## check_id: chk-sql-details

- **type**: metric
- **metric_name**: 慢SQL details等待事件
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["主要是两个等待事件比较突出，和1.5s也比较接近 wait node: 主要是CN在等DN gtm get snapshot: CN向GTM请求快照信息"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-jdbc-x55"]

## check_id: chk-dn-sql

- **type**: metric
- **metric_name**: DN慢SQL信息
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["500ms"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-jdbc-x55"]

## check_id: chk-az

- **type**: metric
- **metric_name**: 网络时延与跨AZ请求
- **collection_layer**: manual-external
- **collection_method**: `[需外部确认] NULL`
- **abnormal_patterns**: ["确实有CN_5003/CN_5004访问另外一个机房的GTM和DN主的情况，同时发现：此语句的所有慢SQL都是CN_5003/CN_5004发起（即跨AZ请求）"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-jdbc-x55"]

## check_id: chk-sql-9

- **type**: metric
- **metric_name**: 慢SQL锁次数与软解析次数
- **collection_layer**: db-system-view
- **collection_method**: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
- **abnormal_patterns**: ["两者在单语句内都不应该出现这么多次数"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-jdbc-x55"]

## check_id: chk-client-encoding-server-encoding

- **type**: metric
- **metric_name**: client encoding与server encoding配置
- **collection_layer**: db-shell
- **collection_method**: `show client_encoding; show server_encoding;`
- **abnormal_patterns**: ["业务库当前主要是encoding: GB18030-2022 （2）JDBC侧设置成非GB18030-2022和设置成GB18030-2022 （3）测试发现性"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-jdbc-x55"]

## check_id: chk--31

- **type**: metric
- **metric_name**: 代码分析
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 通过代码分析发现`
- **abnormal_patterns**: ["若两个不同union all分支的target列类型不一致 会导致谓词无法下推到子查询中","主要是存在窗口函数 但是在sql语句中default_flag并没有使用"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-union-x56","gaussdb-plan-suboptimal-x57"]

## check_id: chk--32

- **type**: metric
- **metric_name**: 代码定位
- **collection_layer**: manual-code
- **collection_method**: `[需确认代码] 定位发现`
- **abnormal_patterns**: ["若存在union all，cte 不会自动内联"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-union-x58"]

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

## check_id: chk--33

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

## check_id: chk-explain-verbose-warning-2

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

## check_id: chk-explain-verbose-subplan-2

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

## check_id: chk-savepoint

- **type**: metric
- **metric_name**: 存储过程中 SAVEPOINT 的创建/释放配对
- **collection_layer**: db-shell
- **collection_method**: 在使用完SAVEPOINT后，应及时使用RELEASE SAVEPOINT来释放资源。
- **abnormal_patterns**: ["同名的SAVEPOINT不会覆盖，而是会重新创建，这可能导致资源迅速累积。"]
- **linked_case_ids**: ["gaussdb-savepoint-in-loop-resource-leak-01"]

## check_id: chk-commit-rollback-i-o

- **type**: metric
- **metric_name**: COMMIT/ROLLBACK 频率与 I/O 开销
- **collection_layer**: db-shell
- **collection_method**: 事务的COMMIT和ROLLBACK操作需要同步数据库的元数据和日志，频繁执行可能增加I/O开销，从而影响性能。
- **abnormal_patterns**: ["频繁执行可能增加I/O开销，从而影响性能。"]
- **linked_case_ids**: ["gaussdb-savepoint-in-loop-resource-leak-01"]

## check_id: chk-explain-analyze-seq-scan-a-time-total-runtime

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE Seq Scan A-time / Total runtime
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE SELECT * FROM test_table WHERE email = 'user_500000@example.com';`
- **abnormal_patterns**: []
- **linked_case_ids**: ["gaussdb-seqscan-without-index-slow-01"]

## check_id: chk-b-tree-explain-analyze

- **type**: metric
- **metric_name**: 创建 B-tree 索引后再次 EXPLAIN ANALYZE
- **collection_layer**: db-interactive-cmd
- **collection_method**: 添加索引后，通过与无索引时执行计划的对比，查询时间从原来的382.624ms缩短到0.293 ms。
- **abnormal_patterns**: ["查询时间从原来的382.624ms缩短到0.293 ms。"]
- **linked_case_ids**: ["gaussdb-seqscan-without-index-slow-01"]

## check_id: chk-explain-verbose-warning-3

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

## check_id: chk-explain-analyze-3

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

## check_id: chk--34

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

## check_id: chk-explain-analyze-total-runtime-partitionscan

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE Total runtime / 是否走 PartitionScan
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE SELECT min(b) FROM test_range_pt;`
- **abnormal_patterns**: ["Partitioned Seq Scan on test_range_pt  (cost=0.00..139.00 rows=10000 width=4) (a"]
- **linked_case_ids**: ["gaussdb-partition-maxmin-fullscan-01"]

## check_id: chk-local-explain-analyze-total-runtime

- **type**: metric
- **metric_name**: 创建 LOCAL 索引后 EXPLAIN ANALYZE Total runtime
- **collection_layer**: db-interactive-cmd
- **collection_method**: `CREATE INDEX idx_range_b ON test_range_pt(b) LOCAL;`
- **abnormal_patterns**: ["优化后时间消耗远小于优化前。"]
- **linked_case_ids**: ["gaussdb-partition-maxmin-fullscan-01"]

## check_id: chk-rds001-cpu-util

- **type**: metric
- **metric_name**: rds001_cpu_util
- **collection_layer**: db-internal-counter
- **collection_method**: CPU使用率
- **abnormal_patterns**: ["> 80% sustained 3 cycles"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds002-mem-util

- **type**: metric
- **metric_name**: rds002_mem_util
- **collection_layer**: db-internal-counter
- **collection_method**: 内存使用率
- **abnormal_patterns**: ["> 90% sustained 3 cycles"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-io-bandwidth-usage

- **type**: metric
- **metric_name**: io_bandwidth_usage
- **collection_layer**: db-internal-counter
- **collection_method**: 磁盘io带宽占用率
- **abnormal_patterns**: ["> 80% sustained 3 cycles"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-iops-usage

- **type**: metric
- **metric_name**: iops_usage
- **collection_layer**: db-internal-counter
- **collection_method**: IOPS使用率
- **abnormal_patterns**: ["> 80% sustained 3 cycles"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds007-instance-disk-usage

- **type**: metric
- **metric_name**: rds007_instance_disk_usage
- **collection_layer**: db-internal-counter
- **collection_method**: 实例数据磁盘已使用百分比
- **abnormal_patterns**: ["> 75%"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds020-avg-disk-ms-per-write

- **type**: metric
- **metric_name**: rds020_avg_disk_ms_per_write
- **collection_layer**: db-internal-counter
- **collection_method**: 数据磁盘单次写入花费的时间
- **abnormal_patterns**: ["> 8 ms"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds021-avg-disk-ms-per-read

- **type**: metric
- **metric_name**: rds021_avg_disk_ms_per_read
- **collection_layer**: db-internal-counter
- **collection_method**: 数据磁盘单次读取花费的时间
- **abnormal_patterns**: ["> 8 ms"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds036-deadlocks

- **type**: metric
- **metric_name**: rds036_deadlocks
- **collection_layer**: db-internal-counter
- **collection_method**: 死锁次数
- **abnormal_patterns**: ["> 5 Counts / period"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds048-p80

- **type**: metric
- **metric_name**: rds048_P80
- **collection_layer**: db-internal-counter
- **collection_method**: 80% SQL的响应时间
- **abnormal_patterns**: ["> 10000000 us"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds049-p95

- **type**: metric
- **metric_name**: rds049_P95
- **collection_layer**: db-internal-counter
- **collection_method**: 95% SQL的响应时间
- **abnormal_patterns**: ["> 15000000 us"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds060-long-running-transaction-exectime

- **type**: metric
- **metric_name**: rds060_long_running_transaction_exectime
- **collection_layer**: db-internal-counter
- **collection_method**: 数据库最长事务的执行时长
- **abnormal_patterns**: ["> 7200s"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds063-slowquery-user

- **type**: metric
- **metric_name**: rds063_slowquery_user
- **collection_layer**: db-internal-counter
- **collection_method**: 用户库慢SQL数量
- **abnormal_patterns**: ["> 15 Counts / period"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds065-dynamic-used-memory-usage

- **type**: metric
- **metric_name**: rds065_dynamic_used_memory_usage
- **collection_layer**: db-internal-counter
- **collection_method**: 动态内存使用率
- **abnormal_patterns**: ["> 80%"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds066-replication-slot-wal-log-size

- **type**: metric
- **metric_name**: rds066_replication_slot_wal_log_size
- **collection_layer**: db-internal-counter
- **collection_method**: 复制槽保留的WAL日志大小
- **abnormal_patterns**: ["> 10% of disk size"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-rds070-thread-pool

- **type**: metric
- **metric_name**: rds070_thread_pool
- **collection_layer**: db-internal-counter
- **collection_method**: 线程池使用率
- **abnormal_patterns**: ["> 85%"]
- **linked_case_ids**: ["gaussdb-alert-thresholds-01"]

## check_id: chk-explain-agg

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 Agg 算子模式
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain select b,count(1) from t1 group by b;`
- **abnormal_patterns**: ["代价估算，尤其是中间结果集的代价估算一般会有比较大的偏差，这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差"]
- **linked_case_ids**: ["gaussdb-query-slow-agg-plan-mode-01"]

## check_id: chk-copy

- **type**: metric
- **metric_name**: COPY 导入是否存在约束冲突类容错需求
- **collection_layer**: db-shell
- **collection_method**: "gaussdb=# SET a_format_load_with_constraints_violation = 's2';"
- **abnormal_patterns**: ["\"支持的约束冲突类型包括：非空约束、条件约束、主键约束、唯一性约束以及唯一性索引。\""]
- **linked_case_ids**: ["gaussdb-copy-constraint-violation-tolerance-01"]

## check_id: chk-explain-verbose-anti-join

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE Anti Join 行数估算
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain verbose`
- **abnormal_patterns**: ["估算Anti Join的行数与实际行数相差很大"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-anti-join-row-estimate-01"]

## check_id: chk-explain-verbose-hashjoin

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE hashjoin 行数估算
- **collection_layer**: db-interactive-cmd
- **collection_method**: `set cost_param=2; explain verbose`
- **abnormal_patterns**: ["实际是将AND的两个过滤条件分别计算的2个选择率的值相乘来得到hashjoin条件的选择率，导致行数估算不准确，查询性能较差"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-correlated-filter-selectivity-01"]

## check_id: chk-top-gsql-cpu

- **type**: metric
- **metric_name**: top · gsql 进程 CPU 占用
- **collection_layer**: os
- **collection_method**: `top 命令显示 gsql 进程占用率高`
- **abnormal_patterns**: ["`数据库节点CPU持续满载，top 命令显示 gsql 进程占用率高`"]
- **linked_case_ids**: ["gaussdb-cpu-saturated-by-slowsql-06"]

## check_id: chk-pg-stat-statements-total-time-calls

- **type**: metric
- **metric_name**: pg_stat_statements · total_time + calls (慢查询统计)
- **collection_layer**: db-system-view
- **collection_method**: 
- **abnormal_patterns**: ["total_time > 1000 AND calls > 10"]
- **linked_case_ids**: ["gaussdb-cpu-saturated-by-slowsql-06"]

## check_id: chk-explain-performance-dn

- **type**: metric
- **metric_name**: explain performance 各 DN 实际行数
- **collection_layer**: db-interactive-cmd
- **collection_method**: `openGauss=# explain performance select count(*) from inventory;`
- **abnormal_patterns**: ["> 4x` 倍数差距"]
- **linked_case_ids**: ["gaussdb-data-skew-storage-distribution-01"]

## check_id: chk-table-skewness-dn

- **type**: metric
- **metric_name**: table_skewness() 各 DN 数据分布比例
- **collection_layer**: db-system-view
- **collection_method**: `openGauss=# select table_skewness('inventory');`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-data-skew-storage-distribution-01"]

## check_id: chk-explain-analyze-streaming-redistribute-dn

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE Streaming(REDISTRIBUTE) 各 DN 输出行数
- **collection_layer**: db-interactive-cmd
- **collection_method**: `openGauss=# explain select * from skew s,test t where s.x = t.x order by s.a limit 1;`
- **abnormal_patterns**: ["6 --Streaming(type: REDISTRIBUTE) datanode1 (rows=5050368) datanode2 (rows=15276"]
- **linked_case_ids**: ["gaussdb-data-skew-compute-redistribute-01"]

## check_id: chk-pg-stat-get-last-data-changed-time-2

- **type**: metric
- **metric_name**: pg_stat_get_last_data_changed_time 最近变更的表
- **collection_layer**: db-system-view
- **collection_method**: `SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-disk-space-pressure-storage-skew-locate-01"]

## check_id: chk-table-distribution-dn

- **type**: metric
- **metric_name**: table_distribution() 各 DN 存储空间分布
- **collection_layer**: db-system-view
- **collection_method**: `SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-disk-space-pressure-storage-skew-locate-01"]

## check_id: chk-xc-node-id

- **type**: metric
- **metric_name**: 按 xc_node_id 分组的表数据行数
- **collection_layer**: db-system-view
- **collection_method**: `SELECT a.count,b.node_name         FROM             (SELECT count(*) AS count,xc_node_id FROM tablename GROUP BY xc_node_id) a,               pgxc_node b         WHERE a.xc_node_id=b.node_id ORDER BY a.count DESC;`
- **abnormal_patterns**: ["DN 间数据量差异 >= 10%"]
- **linked_case_ids**: ["gaussdb-distribution-key-skew-xc-node-id-25"]

## check_id: chk-explain-streaming

- **type**: metric
- **metric_name**: EXPLAIN 计划是否含 Streaming
- **collection_layer**: db-interactive-cmd
- **collection_method**: CREATE TABLE t1 (a int, b int) DISTRIBUTE BY HASH (a); CREATE TABLE t2 (a int, b int) DISTRIBUTE BY HASH (a);
- **abnormal_patterns**: ["则执行计划将存在\"Streaming\"，导致DN之间存在较大通信数据量。"]
- **linked_case_ids**: ["gaussdb-dws-distkey-choice-01"]

## check_id: chk-explain-streaming-2

- **type**: metric
- **metric_name**: 调整后 EXPLAIN 是否消除 Streaming
- **collection_layer**: db-interactive-cmd
- **collection_method**: CREATE TABLE t1 (a int, b int) DISTRIBUTE BY HASH (a); CREATE TABLE t2 (a int, b int) DISTRIBUTE BY HASH (b);
- **abnormal_patterns**: ["则执行计划将不包含\"Streaming\"，减少DN之间存在的通信数据量，从而提升查询性能。"]
- **linked_case_ids**: ["gaussdb-dws-distkey-choice-01"]

## check_id: chk-explain-groupagg-sort

- **type**: metric
- **metric_name**: EXPLAIN · 算子(GroupAgg+Sort)
- **collection_layer**: db-interactive-cmd
- **collection_method**: `计划中包含GroupAgg+Sort算子`
- **abnormal_patterns**: ["`计划中包含GroupAgg+Sort算子，导致性能较差`"]
- **linked_case_ids**: ["gaussdb-groupagg-sort-vs-hashagg-08"]

## check_id: chk-explain-analyze-hashjoin-dn

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE`
- **abnormal_patterns**: ["HashJoin的执行时间信息[2657.406,93339.924]，上可以看出HashJoin在不同的DN上存在严重的计算偏斜"]
- **linked_case_ids**: ["gaussdb-data-skew-hashjoin-dn-compute-skew-01"]

## check_id: chk-memory-information-dn

- **type**: metric
- **metric_name**: Memory Information 各 DN 内存消耗分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE` (Memory Information 段)
- **abnormal_patterns**: ["各个节点的内存资源消耗也存在极为严重的偏斜"]
- **linked_case_ids**: ["gaussdb-data-skew-hashjoin-dn-compute-skew-01"]

## check_id: chk-seq-scan-dn

- **type**: metric
- **metric_name**: Seq Scan 各 DN 扫描时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE`
- **abnormal_patterns**: ["进一步向HashJoin算子的下层分析发现Seq Scan on s_riskrate_setting也存在极为严重的计算倾斜[38.885,2940.983]"]
- **linked_case_ids**: ["gaussdb-data-skew-hashjoin-dn-compute-skew-01"]

## check_id: chk-explain-analyze-4

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE 顺序扫描耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN`
- **abnormal_patterns**: ["在顺序扫描阶段耗时较多"]
- **linked_case_ids**: ["gaussdb-query-slow-join-null-values-01"]

## check_id: chk-explain-seqscan-vs-indexscan

- **type**: metric
- **metric_name**: EXPLAIN · 算子(seqscan vs indexscan)
- **collection_layer**: db-interactive-cmd
- **collection_method**: `在优化前，没有创建places.place_id和states.state_id索引，执行计划如下`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-missing-index-multi-join-05"]

## check_id: chk-explain-join-2

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 Join 类型
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN`
- **abnormal_patterns**: ["join-condition实质上是一个不等式，这种不等值的join操作必须走nestloop"]
- **linked_case_ids**: ["gaussdb-query-slow-nestloop-any-clause-01"]

## check_id: chk-explain-analyze-5

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE 执行计划耗时与过滤行数
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze on, costs off) select * from store_sales where ss_sold_date_sk = 2450944;`
- **abnormal_patterns**: ["过滤行数数量级远大于返回行数"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-seqscan-no-index-01"]

## check_id: chk-explain-analyze-join

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE Join 算子类型与耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE`
- **abnormal_patterns**: ["> 100s"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-table-01"]

## check_id: chk-explain-analyze-agg

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE Agg 算子类型
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE`
- **abnormal_patterns**: ["如果大结果集选择了Sort+GroupAgg"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-groupagg-sort-01"]

## check_id: chk-iostat-util-r-await-w-await

- **type**: metric
- **metric_name**: iostat 中 %util / r_await / w_await
- **collection_layer**: os
- **collection_method**: "iostat"
- **abnormal_patterns**: ["\"%util 接近 100% 或 await > 3ms\""]
- **linked_case_ids**: ["gaussdb-overall-slow-io-await-high-01"]

## check_id: chk-pidstat-iotop-i-o

- **type**: metric
- **metric_name**: pidstat / iotop 显示线程 I/O 消耗
- **collection_layer**: os
- **collection_method**: "pidstat -dt -p gaussdb进程号"
- **abnormal_patterns**: ["\"通常是TPLworker线程消耗的I/O读写量异常，代表用户SQL消耗I/O多\""]
- **linked_case_ids**: ["gaussdb-overall-slow-io-await-high-01"]

## check_id: chk-pg-thread-wait-status-pg-stat-activity-i-o-sql

- **type**: metric
- **metric_name**: pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL
- **collection_layer**: db-system-view
- **collection_method**: "通过查询pg_thread_wait_status视图的lwtid为上一步内的TID，获取对应的tid和sessionid。"
- **abnormal_patterns**: ["\"查询pg_stat_activity视图内记录满足pid/sessionid为上一步内的tid/sessionid,即可找到造成I/O高的session信息，"]
- **linked_case_ids**: ["gaussdb-overall-slow-io-await-high-01"]

## check_id: chk-top-sar-gaussdb-cpu

- **type**: metric
- **metric_name**: top / sar 中 gaussdb 进程 CPU 占用
- **collection_layer**: os
- **collection_method**: "$ top"
- **abnormal_patterns**: ["\"10678 Ruby      20   0   54.8g  38.2g  34.6g S  1398 20.3 126085:50 gaussdb\""]
- **linked_case_ids**: ["gaussdb-overall-slow-cpu-high-01"]

## check_id: chk-wdr-top-sql-order-by-cpu-time

- **type**: metric
- **metric_name**: WDR 报告 Top SQL order by CPU Time
- **collection_layer**: db-system-view
- **collection_method**: "可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句"
- **abnormal_patterns**: ["\"如果CPU一直较高，方法一：可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句\""]
- **linked_case_ids**: ["gaussdb-overall-slow-cpu-high-01"]

## check_id: chk--35

- **type**: metric
- **metric_name**: 内核代码热点函数火焰图
- **collection_layer**: flamegraph
- **collection_method**: "如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点"
- **abnormal_patterns**: ["\"如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点\""]
- **linked_case_ids**: ["gaussdb-overall-slow-cpu-high-01"]

## check_id: chk-guc-shared-buffers-work-mem-thread-pool-attr

- **type**: metric
- **metric_name**: GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值
- **collection_layer**: db-system-view
- **collection_method**: "常见的可能情况有：1. shared_buffers配置过小，导致buffer淘汰频繁。"
- **abnormal_patterns**: ["\"shared_buffers配置过小，导致buffer淘汰频繁。\""]
- **linked_case_ids**: ["gaussdb-overall-slow-config-shared-buffers-01"]

## check_id: chk-session-package

- **type**: metric
- **metric_name**: SESSION 中 PACKAGE 变量数量与内存占用
- **collection_layer**: db-shell
- **collection_method**: "PACKAGE变量是在PACKAGE内定义的全局变量，其生命周期覆盖整个数据库会话（SESSION）。"
- **abnormal_patterns**: ["\"大量PACKAGE变量在SESSION中缓存可能占用大量内存。\""]
- **linked_case_ids**: ["gaussdb-package-variable-session-memory-01"]

## check_id: chk-explain-filter

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 Filter 条件分析
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN`
- **abnormal_patterns**: ["Filter条件中存在表达式to_char(add_months(to_date(''20170222'','yyyymmdd'), -11),'yyyymm'"]
- **linked_case_ids**: ["gaussdb-query-slow-partition-pruning-disabled-function-01"]

## check_id: chk-pg-proc-volatility

- **type**: metric
- **metric_name**: pg_proc 函数 volatility 类型查询
- **collection_layer**: db-system-view
- **collection_method**: `查询pg_proc`
- **abnormal_patterns**: ["查询pg_proc发现此处的to_date和to_char均为stable类型的函数，根据数据库对函数行为的约定，此类函数不能在预处理阶段转化为Const值"]
- **linked_case_ids**: ["gaussdb-query-slow-partition-pruning-disabled-function-01"]

## check_id: chk-explain

- **type**: metric
- **metric_name**: EXPLAIN 执行计划算子估算行数
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN`
- **abnormal_patterns**: ["第11层算子估算行数为2140，比实际行数严重低估"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-row-estimate-broadcast-01"]

## check_id: chk-explain-stream

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 Stream 算子类型
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN`
- **abnormal_patterns**: ["劣化的原因主要为lineitem和part表join时stream类型由BroadCast变更为Redistribute导致"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-statistics-change-plan-regression-01"]

## check_id: chk-exception

- **type**: metric
- **metric_name**: 存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销
- **collection_layer**: db-shell
- **collection_method**: "每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。"
- **abnormal_patterns**: ["\"频繁地捕获和处理异常可能会导致性能下降。每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。\""]
- **linked_case_ids**: ["gaussdb-procedure-exception-frequent-perf-degrade-01"]

## check_id: chk--36

- **type**: metric
- **metric_name**: 存储过程默认权限模式
- **collection_layer**: db-shell
- **collection_method**: "存储过程默认具有SECURITYINVOKER权限。"
- **abnormal_patterns**: ["\"切换test_user2执行test_user1创建的存储过程，执行报错，对表user1_tb没有权限，因为执行存储过程默认使用调用者的权限。\""]
- **linked_case_ids**: ["gaussdb-procedure-security-definer-permission-01"]

## check_id: chk-explain-remotequery-data-node-scan

- **type**: metric
- **metric_name**: EXPLAIN · 是否含 RemoteQuery / Data Node Scan
- **collection_layer**: db-interactive-cmd
- **collection_method**: 
- **abnormal_patterns**: ["`Data Node Scan on t1 \"_REMOTE_TABLE_QUERY_\"`"]
- **linked_case_ids**: ["gaussdb-rewrite-rule-partialpush-13"]

## check_id: chk-explain-performance-2

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE 算子耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE`
- **abnormal_patterns**: ["分析发现如图红框标识的两个性能瓶颈点均为表Scan动作"]
- **linked_case_ids**: ["gaussdb-query-slow-scan-no-local-cluster-key-01"]

## check_id: chk-scan-filter

- **type**: metric
- **metric_name**: Scan filter 条件分析
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE`
- **abnormal_patterns**: ["进一步分析表Scan的filter条件发现两个表存在acct_id = 'A012709548'::bpchar这样的filter条件"]
- **linked_case_ids**: ["gaussdb-query-slow-scan-no-local-cluster-key-01"]

## check_id: chk-explain-cn-vs-dn

- **type**: metric
- **metric_name**: EXPLAIN 执行计划算子位置（CN vs DN）
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN`
- **abnormal_patterns**: ["可以看到window agg和sort全部在CN端执行，耗时非常严重"]
- **linked_case_ids**: ["gaussdb-query-slow-windowagg-sort-on-cn-01"]

## check_id: chk-group-by-groupagg-sort

- **type**: metric
- **metric_name**: GROUP BY 查询计划中是否包含 GroupAgg+Sort
- **collection_layer**: db-interactive-cmd
- **collection_method**: "查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。"
- **abnormal_patterns**: ["\"查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。\""]
- **linked_case_ids**: ["gaussdb-group-by-sort-perf-work-mem-01"]

## check_id: chk-not-in

- **type**: metric
- **metric_name**: 含 NOT IN 子查询的执行计划
- **collection_layer**: db-interactive-cmd
- **collection_method**: "gaussdb=# EXPLAIN SELECT * FROM t1 WHERE c1 NOT IN (SELECT d2 FROM t2);"
- **abnormal_patterns**: ["\"NOT IN语句需要使用NESTLOOP ANTI JOIN来实现\""]
- **linked_case_ids**: ["gaussdb-not-in-to-not-exists-rewrite-01"]

## check_id: chk-explain-2

- **type**: metric
- **metric_name**: EXPLAIN · 计划与实际行数比对
- **collection_layer**: db-interactive-cmd
- **collection_method**: `导致执行计划选择不优`
- **abnormal_patterns**: ["`统计信息不是最新的情况`"]
- **linked_case_ids**: ["gaussdb-stale-stats-hint-fix-09"]

## check_id: chk-explain-data-node-scan-on

- **type**: metric
- **metric_name**: EXPLAIN 输出中 "Data Node Scan on" 是否在第一行
- **collection_layer**: db-interactive-cmd
- **collection_method**: "通常而言explain语句后没有显示具体的执行计划算子，执行计划中关键字\"Data Node Scan on\"出现在第一行（不包含计划格式）则说明语句已下推给DN去执行。"
- **abnormal_patterns**: ["\"在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈\""]
- **linked_case_ids**: ["gaussdb-statement-not-shippable-cn-bottleneck-01"]

## check_id: chk-explain-subplan

- **type**: metric
- **metric_name**: EXPLAIN 执行计划 SubPlan 存在
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN`
- **abnormal_patterns**: ["此SQL性能较差，查看发现执行计划中存在SubPlan"]
- **linked_case_ids**: ["gaussdb-query-slow-subplan-correlated-subquery-01"]

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

## check_id: chk--37

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

## check_id: chk-nestloop-2

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

## check_id: chk-nestloop-3

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

## check_id: chk--38

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

## check_id: chk--39

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

## check_id: chk-sql-case-when

- **type**: metric
- **metric_name**: SQL 中 CASE WHEN 分支数量与执行次数
- **collection_layer**: db-interactive-cmd
- **collection_method**: "在业务查询中，CASE WHEN语句常用来进行条件判断，但如果在SQL查询中存在大量冗余的CASE WHEN"
- **abnormal_patterns**: ["\"该语句冗长，执行时每个分支的CASE WHEN均需执行，导致查询时间成倍增加\""]
- **linked_case_ids**: ["dws-case-when-redundant-rewrite-01"]

## check_id: chk--40

- **type**: metric
- **metric_name**: 系统表/用户表膨胀情况
- **collection_layer**: db-system-view
- **collection_method**: "用户可在管控面执行全库Vacuum/Vacuum Full，以定期进行空间回收"
- **abnormal_patterns**: ["\"用户数据膨胀严重，磁盘空间不足，性能低。\""]
- **linked_case_ids**: ["dws-data-bloat-disk-shortage-perf-low-01"]

## check_id: chk-dn-xc-node-id

- **type**: metric
- **metric_name**: 各 DN 数据量分布 (xc_node_id 分组)
- **collection_layer**: db-system-view
- **collection_method**: "SELECT a.count,b.node_name FROM (SELECT count(*) AS count,xc_node_id FROM table_name GROUP BY xc_node_id) a, pgxc_node b WHERE a.xc_node_id=b.node_id ORDER BY a.count desc;"
- **abnormal_patterns**: ["\"> 5% diff (视为倾斜); > 10% diff (必须调整)\""]
- **linked_case_ids**: ["dws-data-skew-distribute-column-01"]

## check_id: chk-pgxc-stat-table-dirty

- **type**: metric
- **metric_name**: 表脏页率 (PGXC_STAT_TABLE_DIRTY)
- **collection_layer**: db-system-view
- **collection_method**: "DWS提供了查询脏页率的系统视图，具体使用请参见PGXC_STAT_TABLE_DIRTY。"
- **abnormal_patterns**: ["\"> 80%\""]
- **linked_case_ids**: ["dws-dirty-page-high-vacuum-full-01"]

## check_id: chk-gds

- **type**: metric
- **metric_name**: GDS导入作业日志
- **collection_layer**: log-grep
- **collection_method**: "检测GDS导入作业的日志，查看是否有执行失败的现象。"
- **abnormal_patterns**: ["\"在导入数据失败后，占用的磁盘空间没有释放。\""]
- **linked_case_ids**: ["dws-gds-failed-disk-not-released-01"]

## check_id: chk-fe-sync-be-parsecomplete

- **type**: metric
- **metric_name**: FE=>Sync 与 <=BE ParseComplete 日志时间间隔
- **collection_layer**: log-grep
- **collection_method**: "用户可查看FE=> Syncr日志和<=BE ParseComplete日志之间的时间间隔"
- **abnormal_patterns**: ["\"如果时间间隔较久，则判断为数据库执行慢。\""]
- **linked_case_ids**: ["dws-jdbc-processresult-slow-01"]

## check_id: chk-be-datarow-select-count

- **type**: metric
- **metric_name**: <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小
- **collection_layer**: log-grep
- **collection_method**: "查看日志，如果<=BE DataRow日志出现次数过多，或直接执行SELECT count(*);"
- **abnormal_patterns**: ["\"查询结果数目过大，则判断为结果集过大。\""]
- **linked_case_ids**: ["dws-jdbc-processresult-slow-01"]

## check_id: chk-modifyjdbccall-createparameterizedquery

- **type**: metric
- **metric_name**: modifyJdbcCall / createParameterizedQuery 阶段耗时
- **collection_layer**: log-grep
- **collection_method**: "如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。"
- **abnormal_patterns**: ["\"如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为pr"]
- **linked_case_ids**: ["dws-jdbc-modifyjdbccall-slow-01"]

## check_id: chk-period-ttl

- **type**: metric
- **metric_name**: 分区表 period / ttl 参数设置
- **collection_layer**: db-shell
- **collection_method**: "CREATE TABLE CPU1(...) with (TTL='7 days',PERIOD='1 day', TIME_FORMAT='YYYYMMDD')"
- **abnormal_patterns**: ["\"普通分区表无法自动创建新分区或清理过期分区，需维护人员定期手动操作\""]
- **linked_case_ids**: ["dws-partition-auto-period-ttl-01"]

## check_id: chk-analyze-2

- **type**: metric
- **metric_name**: ANALYZE 后的查询性能
- **collection_layer**: db-interactive-cmd
- **collection_method**: "使用ANALYZE命令分析数据库。"
- **abnormal_patterns**: ["\"如果此命令执行后性能恢复或者有所提升，则表明AUTOVACUUM未能很好的完成它的工作，有待进一步分析。\""]
- **linked_case_ids**: ["dws-query-efficiency-degraded-01"]

## check_id: chk--41

- **type**: metric
- **metric_name**: 查询返回行数
- **collection_layer**: db-interactive-cmd
- **collection_method**: "检查查询语句是否返回了多余的数据信息。"
- **abnormal_patterns**: ["\"对于包含50条记录的表，查询起来是很快的；但是，当表中包含的记录达到50000，查询效率将会有所下降。\""]
- **linked_case_ids**: ["dws-query-efficiency-degraded-01"]

## check_id: chk--42

- **type**: metric
- **metric_name**: 主机负载下查询单独运行时延
- **collection_layer**: db-interactive-cmd
- **collection_method**: "尝试在数据库没有其他查询或查询较少的时候运行查询语句，并观察运行效率。"
- **abnormal_patterns**: ["\"如果效率较高，则说明可能是由于之前运行数据库系统的主机负载过大导致查询低效。\""]
- **linked_case_ids**: ["dws-query-efficiency-degraded-01"]

## check_id: chk--43

- **type**: metric
- **metric_name**: 重复执行同一查询语句的执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: "重复执行相同的查询语句，如果后续执行的查询语句效率提升，则可能是由于上述原因导致。"
- **abnormal_patterns**: ["\"查询效率低的一个重要原因是查询所需信息没有缓存在内存中，这可能是由于内存资源紧张，缓存信息被其他查询处理覆盖。\""]
- **linked_case_ids**: ["dws-query-efficiency-degraded-01"]

## check_id: chk-disk-cache-pgxc-disk-cache-all-stats

- **type**: metric
- **metric_name**: Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats)
- **collection_layer**: db-system-view
- **collection_method**: "通过查询视图pgxc_disk_cache_all_stats可以查看当前缓存的命中率以及各个DN磁盘的使用大小情况"
- **abnormal_patterns**: ["\"用户查询数据时，会优先到Disk Cache中查看数据是否已存在于本地磁盘，如果不存在则再去OBS读取数据\""]
- **linked_case_ids**: ["dws-3-0-disk-cache-size-low-hit-01"]

## check_id: chk-evs

- **type**: metric
- **metric_name**: EVS 磁盘空间占用百分比
- **collection_layer**: log-grep
- **collection_method**: "日志中会出现\"Disk usage on the node %u has reached the read-only threshold 90%\""
- **abnormal_patterns**: ["\"> 90%\""]
- **linked_case_ids**: ["dws-3-0-disk-usage-readonly-01"]

## check_id: chk-bucket

- **type**: metric
- **metric_name**: 入库分区数 / Bucket 数 / 攒批内存消耗
- **collection_layer**: db-shell
- **collection_method**: "单并发攒批消耗： #Np * #Nb * #Nr 单并发攒批内存消耗： partition_max_cache_size， 默认2GB"
- **abnormal_patterns**: ["\"假设一次copy数据，涉及1000个分区，#Nb≈10, 单条记录大小1K，攒批大小10000行 单并发攒批消耗： 1000 * 10 * 1K * 1000"]
- **linked_case_ids**: ["dws-3-0-batching-import-memory-01"]

## check_id: chk-pgxc-get-stat-all-tables-dirty-page-rate

- **type**: metric
- **metric_name**: PGXC_GET_STAT_ALL_TABLES.dirty_page_rate
- **collection_layer**: db-system-view
- **collection_method**: `SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_GET_STAT_ALL_TABLES WHERE schemaName NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'cstore', 'pmk') AND dirty_page_rate > 30 ORDER BY table_size DESC, dirty_page_rate DESC;`
- **abnormal_patterns**: ["> 30","dirty_page_rate > 30"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-autovacuum-01","gaussdb-dws-disk-high-dirty-pages-15"]

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

## check_id: chk-dn-2

- **type**: metric
- **metric_name**: 各DN数据量分布
- **collection_layer**: db-shell
- **collection_method**: `SELECT pg_get_tabledef('customer_t1');`
- **abnormal_patterns**: ["> 10%"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-bad-dist-key-01"]

## check_id: chk-cn-2

- **type**: metric
- **metric_name**: CN日志中不下推原因
- **collection_layer**: log-grep
- **collection_method**: "不下推语句在pg_log中会打印不下推的原因。LOG: SQL can't be shipped, reason: ..."
- **abnormal_patterns**: ["\"LOG: SQL can't be shipped, reason: With-Recursive does not contain \\\"ALL\\\" to b"]
- **linked_case_ids**: ["gaussdb-dws-with-recursive-not-pushed-slow-01"]

## check_id: chk-explain-verbose-warning-4

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

## check_id: chk--44

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

## check_id: chk--45

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

## check_id: chk-explain-performance-dn-2

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

## check_id: chk-pgxc-get-table-skewness-2

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

## check_id: chk-cn-3

- **type**: metric
- **metric_name**: CN日志 · 不下推原因
- **collection_layer**: log-grep
- **collection_method**: "不下推语句在pg_log中会打印不下推的原因，上述语句在CN的日志中会找到类似以下的日志。"
- **abnormal_patterns**: ["\"不下推语句在pg_log中会打印不下推的原因\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-function-not-shipped-01"]

## check_id: chk-nestloop-4

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

## check_id: chk-pg-thread-wait-status-3

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

## check_id: chk--46

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

## check_id: chk-vs-2

- **type**: metric
- **metric_name**: 脏数据膨胀率 / 表实际大小 vs 有效数据量
- **collection_layer**: db-system-view
- **collection_method**: NULL
- **abnormal_patterns**: ["\"发现表数据膨胀严重，对其中一张8GB大小的表，总数据量5万条，做完VACUUM FULL后大小减小为5.6MB。\""]
- **linked_case_ids**: ["gaussdb-dws-query-slow-table-bloat-01"]

## check_id: chk-explain-3

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

## check_id: chk--47

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

## check_id: chk-table-distribution-dn-2

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

## check_id: chk--48

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

## check_id: chk-dn-3

- **type**: metric
- **metric_name**: 各 DN 数据条数分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: `SELECT a.count,b.node_name FROM (SELECT count(*) AS count,xc_node_id FROM table_name GROUP BY xc_node_id) a, pgxc_node b WHERE a.xc_node_id=b.node_id ORDER BY a.count desc;`
- **abnormal_patterns**: [">= 10%"]
- **linked_case_ids**: ["dws-distkey-skew-10pct-01"]

## check_id: chk-pgxc-get-table-skewness-3

- **type**: metric
- **metric_name**: PGXC_GET_TABLE_SKEWNESS 视图
- **collection_layer**: db-system-view
- **collection_method**: 分布差可以通过视图[PGXC_GET_TABLE_SKEWNESS]查看。
- **abnormal_patterns**: ["此处的数据分布差表示实际查询到DN上的数据量与DN平均数据量的差异。"]
- **linked_case_ids**: ["dws-distkey-skew-10pct-01"]

## check_id: chk-dms

- **type**: metric
- **metric_name**: DMS 监控 · 节点磁盘使用率
- **collection_layer**: db-system-view
- **collection_method**: `选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。`
- **abnormal_patterns**: [">= 70%"]
- **linked_case_ids**: ["gaussdb-dws-disk-high-dirty-pages-15"]

## check_id: chk-explain-agg-hashagg-gather-vs-redistribute-hashagg

- **type**: metric
- **metric_name**: EXPLAIN · Agg 计划形态（hashagg+gather vs redistribute+hashagg）
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain select b,count(1) from t1 group by b`
- **abnormal_patterns**: ["\"通常优化器总会选择最优的执行计划，但是众所周知代价估算，尤其是中间结果集的代价估算一般会有比较大的偏差，这种比较大的偏差就可能会导致agg的计算方式出现比较大"]
- **linked_case_ids**: ["gaussdb-dws-agg-plan-tuning-01"]

## check_id: chk-explain-verbose-anti-join-2

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · Anti Join 执行计划及行数估算
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain verbose select count(*) as numwait from lineitem l1, orders where o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and not exists (select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) order by numwait desc`
- **abnormal_patterns**: ["\"估算Anti Join的行数与实际行数相差很大，导致查询性能下降\""]
- **linked_case_ids**: ["gaussdb-dws-cost-param-anti-join-01"]

## check_id: chk-explain-verbose-hashjoin-2

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · HashJoin 行数估算偏差
- **collection_layer**: db-interactive-cmd
- **collection_method**: `set cost_param=2; explain verbose select nation, sum(amount) as sum_profit from (...) as profit group by nation order by nation`
- **abnormal_patterns**: ["\"导致行数估算不准确，查询性能较差\""]
- **linked_case_ids**: ["gaussdb-dws-cost-param-filter-selectivity-01"]

## check_id: chk-dn-4

- **type**: metric
- **metric_name**: 磁盘利用率各 DN 差异
- **collection_layer**: db-shell
- **collection_method**: `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc`
- **abnormal_patterns**: ["> 5% 差值"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-storage-01"]

## check_id: chk-explain-performance-dn-scan

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE 各 DN 基表 scan 行数及时间分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain performance select avg(ss_wholesale_cost) from store_sales`
- **abnormal_patterns**: ["\"基表scan的时间：最快的DN耗时5ms，最慢的DN耗时1173ms。数据分布情况：某些DN有22831616行，其他DN都是0行，数据有严重倾斜。\""]
- **linked_case_ids**: ["gaussdb-dws-data-skew-storage-01"]

## check_id: chk-table-skewness-table-distribution-2

- **type**: metric
- **metric_name**: table_skewness / table_distribution · 表数据倾斜率
- **collection_layer**: db-shell
- **collection_method**: `SELECT table_skewness('store_sales')`
- **abnormal_patterns**: ["\"某些DN有22831616行，其他DN都是0行，数据有严重倾斜\""]
- **linked_case_ids**: ["gaussdb-dws-data-skew-storage-01"]

## check_id: chk-explain-performance-stream-dn

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · Stream 算子各 DN 行数分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: `select * from skew s,test t where s.x = t.x order by s.a limit 1`
- **abnormal_patterns**: ["\"6 --Streaming(type: REDISTRIBUTE) datanode1 (rows=5050368) datanode2 (rows=1527"]
- **linked_case_ids**: ["gaussdb-dws-data-skew-compute-01"]

## check_id: chk-dms-max-min

- **type**: metric
- **metric_name**: DMS · 节点磁盘使用率排序 (max - min)
- **collection_layer**: db-system-view
- **collection_method**: `选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。`
- **abnormal_patterns**: ["max - min >= 10%"]
- **linked_case_ids**: ["gaussdb-dws-disk-skew-16"]

## check_id: chk-explain-streaming-type-redistribute

- **type**: metric
- **metric_name**: EXPLAIN · Streaming(type: REDISTRIBUTE) 算子是否出现
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN SELECT * FROM t1, t2 WHERE t1.a = t2.b`
- **abnormal_patterns**: ["\"执行计划存在\\\"Streaming(type: REDISTRIBUTE)\\\"，即DN根据选定的列把数据重分布到所有的DN，这将导致DN之间存在较大通信数据量"]
- **linked_case_ids**: ["gaussdb-dws-distribution-key-redistribution-01"]

## check_id: chk-cpu-1-3-12-24

- **type**: metric
- **metric_name**: 节点 CPU 使用率 (1/3/12/24 小时)
- **collection_layer**: os
- **collection_method**: 选择“监控 > 节点监控 > 概览”可查看当前集群各节点CPU使用率的具体情况，单击最右的监控按钮，查看最近1/3/12/24小时的CPU性能指标
- **abnormal_patterns**: ["判断是否有CPU使用率突然增大的情况。"]
- **linked_case_ids**: ["gaussdb-dws-high-cpu-01"]

## check_id: chk-cpu-6

- **type**: metric
- **metric_name**: 资源池 CPU 限额 / 配额配置
- **collection_layer**: db-system-view
- **collection_method**: 设置资源池CPU限额与配额。
- **abnormal_patterns**: ["防止极端场景下某个语句占用CPU资源过多"]
- **linked_case_ids**: ["gaussdb-dws-high-cpu-01"]

## check_id: chk-pgxc-stat-activity-state-2

- **type**: metric
- **metric_name**: pgxc_stat_activity state 字段
- **collection_layer**: db-system-view
- **collection_method**: `SELECT state, query, query_id FROM pgxc_stat_activity;`
- **abnormal_patterns**: ["state = 'idle in transaction'"]
- **linked_case_ids**: ["gaussdb-dws-idle-in-transaction-01"]

## check_id: chk-cn-savepoint-release

- **type**: metric
- **metric_name**: 各 CN 上 SAVEPOINT/RELEASE 语句分布
- **collection_layer**: db-system-view
- **collection_method**: `SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';`
- **abnormal_patterns**: ["结果显示SAVEPOINT/RELEASE语句处于idle in transaction。"]
- **linked_case_ids**: ["gaussdb-dws-idle-in-transaction-01"]

## check_id: chk-explain-join-nestloop-vs-hashjoin

- **type**: metric
- **metric_name**: EXPLAIN · JOIN 算子类型 (NestLoop vs HashJoin)
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN SELECT ls_pid_cusr1,COALESCE(max(round((current_date-bthdate)/365)),0) FROM calc_empfyc_c1_result_tmp_t1 t1,p10_md_tmp_t2 t2 WHERE t1.ls_pid_cusr1 = any(values(id),(id15)) GROUP BY ls_pid_cusr1`
- **abnormal_patterns**: ["\"因此join-condition实质上是一个不等式，这种不等值的join操作必须走nestloop\""]
- **linked_case_ids**: ["gaussdb-dws-in-clause-nestloop-01"]

## check_id: chk-explain-performance-3

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · 基表扫描方式及执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE SELECT * FROM orders WHERE o_custkey = '1106459'`
- **abnormal_patterns**: ["\"发现执行时间为48毫秒\""]
- **linked_case_ids**: ["gaussdb-dws-index-missing-slow-query-01"]

## check_id: chk-explain-in-join

- **type**: metric
- **metric_name**: EXPLAIN · in 条件是否转为 join
- **collection_layer**: db-interactive-cmd
- **collection_method**: "打印语句的执行计划"
- **abnormal_patterns**: ["执行计划中 in 仍作为 Filter 而非 Hash Join"]
- **linked_case_ids**: ["gaussdb-dws-inlist2join-large-constants-01"]

## check_id: chk-explain-4

- **type**: metric
- **metric_name**: EXPLAIN · 执行计划顺序扫描阶段耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN` 查看多表 JOIN 执行计划
- **abnormal_patterns**: ["\"分析执行计划可知，在顺序扫描阶段耗时较多\""]
- **linked_case_ids**: ["gaussdb-dws-join-null-values-01"]

## check_id: chk-explain-verbose-not-in

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · NOT IN 执行计划算子类型
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN VERBOSE SELECT * FROM t1 WHERE t1.c NOT IN (SELECT t2.c FROM t2)`
- **abnormal_patterns**: ["\"从返回结果可知执行计划走NestLoop\""]
- **linked_case_ids**: ["gaussdb-dws-not-in-nestloop-01"]

## check_id: chk-explain-verbose-not-exists

- **type**: metric
- **metric_name**: EXPLAIN VERBOSE · NOT EXISTS 执行计划算子类型验证
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN VERBOSE SELECT * FROM t1 WHERE NOT EXISTS (SELECT 1 FROM t2 WHERE t2.c = t1.c)`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-not-in-nestloop-01"]

## check_id: chk-base-pgsql-tmp-pgsql-tmp-queryid-pid

- **type**: metric
- **metric_name**: base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件
- **collection_layer**: os
- **collection_method**: `下盘文件位于实例目录的base/pgsql_tmp路径下，下盘文件以 pgsql_tmp$queryid_$pid 命名`
- **abnormal_patterns**: ["`下盘文件位于实例目录的base/pgsql_tmp路径下`"]
- **linked_case_ids**: ["gaussdb-dws-operator-spill-23"]

## check_id: chk-pgxc-thread-wait-status-wait-status-write-file

- **type**: metric
- **metric_name**: pgxc_thread_wait_status · wait_status='write file'
- **collection_layer**: db-system-view
- **collection_method**: `等待视图中，当出现write file时，表示发生了中间结果下盘`
- **abnormal_patterns**: ["wait_status = 'write file'"]
- **linked_case_ids**: ["gaussdb-dws-operator-spill-23"]

## check_id: chk-explain-performance-spill-written-disk-temp-file-num

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字
- **collection_layer**: db-interactive-cmd
- **collection_method**: `performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。`
- **abnormal_patterns**: ["`performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。`"]
- **linked_case_ids**: ["gaussdb-dws-operator-spill-23"]

## check_id: chk-topsql-spill-info

- **type**: metric
- **metric_name**: TopSQL.spill_info
- **collection_layer**: db-system-view
- **collection_method**: `实时TopSQL语句或历史TopSQL语句中，spill_info字段中会包含下盘信息，如果该字段不为空，说明有DN实例出现了下盘。`
- **abnormal_patterns**: ["spill_info IS NOT NULL"]
- **linked_case_ids**: ["gaussdb-dws-operator-spill-23"]

## check_id: chk-explain-analyze-6

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE · 基表扫描算子类型及执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain (analyze on, costs off) select * from store_sales where ss_sold_date_sk = 2450944`
- **abnormal_patterns**: ["\"Seq Scan on store_sales [3594.611,3594.611] 3360 Rows Removed by Filter: 496893"]
- **linked_case_ids**: ["gaussdb-dws-seqscan-vs-indexscan-01"]

## check_id: chk-explain-analyze-join-2

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE · JOIN 算子类型及执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE` 查看两表 JOIN 的算子类型
- **abnormal_patterns**: ["\"NestLoop耗时181秒\""]
- **linked_case_ids**: ["gaussdb-dws-nestloop-to-hashjoin-01"]

## check_id: chk-explain-analyze-agg-2

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE · Agg 算子类型及执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN ANALYZE` 查看聚合操作算子选择
- **abnormal_patterns**: ["\"如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时明显优于Sort+GroupAgg\""]
- **linked_case_ids**: ["gaussdb-dws-groupagg-to-hashagg-01"]

## check_id: chk-explain-analyze-verbose-sql-partition-iterator

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE VERBOSE · SQL 自诊断信息 + Partition Iterator 扫描分区数
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN (ANALYZE ON, VERBOSE ON) SELECT count(1) FROM t_ddw_f10_op_cust_asset_mon b1 WHERE b1.year_mth < substr('20200722',1 ,6 ) AND b1.year_mth + 1 >= cast(substr('20200722',1 ,6 ) AS int)`
- **abnormal_patterns**: ["\"Partitioned table unprunable Qual table public.t_ddw_f10_op_cust_asset_mon b1: "]
- **linked_case_ids**: ["gaussdb-dws-partition-pruning-failure-01"]

## check_id: chk-explain-analyze-verbose-partition-iterator-iterations

- **type**: metric
- **metric_name**: EXPLAIN ANALYZE VERBOSE · 改写后 Partition Iterator Iterations
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN (analyze ON, verbose ON) SELECT count(1) FROM t_ddw_f10_op_cust_asset_mon b1 WHERE b1.year_mth < substr('20200722',1 ,6 ) AND b1.year_mth >= cast(substr('20200722',1 ,6 ) AS int) - 1`
- **abnormal_patterns**: ["\"不剪枝告警已经消除，剪枝后需要扫描分区数为1，执行时间从10s提升至3s\""]
- **linked_case_ids**: ["gaussdb-dws-partition-pruning-failure-01"]

## check_id: chk-explain-performance-partition-iterator-iterations

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · 全表扫描时间及 Partition Iterator Iterations
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE SELECT count(*) FROM orders_no_part WHERE o_orderdate >= '1996-01-01 00:00:00'::timestamp(0)`
- **abnormal_patterns**: ["\"执行时间为73毫秒，其中全表扫描的时间为44~45毫秒\""]
- **linked_case_ids**: ["gaussdb-dws-partition-table-scan-optimization-01"]

## check_id: chk-explain-performance-cunone-filter

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · CUNone 比例及 filter 耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE SELECT * FROM orders_no_pck WHERE o_orderkey = '13095143' ORDER BY o_orderdate`
- **abnormal_patterns**: ["CUNone比例 = 0"]
- **linked_case_ids**: ["gaussdb-dws-pck-point-query-01"]

## check_id: chk-explain-performance-cstore-scan-cu

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · CStore Scan CU 加载数量
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE SELECT sum(l_extendedprice * l_discount) as revenue FROM lineitem WHERE l_shipdate >= '1994-01-01'::date and l_shipdate < '1994-01-01'::date + interval '1 year' and l_discount between 0.06 - 0.01 and 0.06 + 0.01 and l_quantity < 24`
- **abnormal_patterns**: ["\"使用partial cluster key后，5-- CStore Scan on public.lineitem的时间减少了1.2s，得益于有84个CU被过"]
- **linked_case_ids**: ["gaussdb-dws-pck-scan-acceleration-01"]

## check_id: chk-explain-performance-4

- **type**: metric
- **metric_name**: explain performance 执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: explain performance select a.ca_state state, count(*) cnt from customer_address a ,customer c ,store_sales s ,date_dim d ,item i where a.ca_address_sk = c.c_current_addr_sk ...
- **abnormal_patterns**: ["store_sales和item表join后未过滤掉任何数据，所以这两个表join并生成hash表的时间都比较长。"]
- **linked_case_ids**: ["gaussdb-dws-plan-hint-leading-01"]

## check_id: chk-leading-hint

- **type**: metric
- **metric_name**: 加 leading hint 后执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: select /*+ leading((s d)) */ a.ca_state state, count(*) cnt ...
- **abnormal_patterns**: ["34268.322ms → 11095.046ms"]
- **linked_case_ids**: ["gaussdb-dws-plan-hint-leading-01"]

## check_id: chk-leading-no-nestloop-hint

- **type**: metric
- **metric_name**: 加 leading + no nestloop hint 后执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: select /*+ leading((s d)) no nestloop(s d) */ a.ca_state state, count(*) cnt ...
- **abnormal_patterns**: ["11095.046ms → 4644.409ms"]
- **linked_case_ids**: ["gaussdb-dws-plan-hint-nojoin-method-02"]

## check_id: chk-rows-hint

- **type**: metric
- **metric_name**: rows hint 后执行时间
- **collection_layer**: db-interactive-cmd
- **collection_method**: select /*+ rows(s #2880404) */ a.ca_state state, count(*) cnt ...
- **abnormal_patterns**: ["34268.322ms → 1991.843ms (17x)"]
- **linked_case_ids**: ["gaussdb-dws-plan-hint-rows-03"]

## check_id: chk-skew-hint-agg

- **type**: metric
- **metric_name**: skew hint 后双层 Agg 计划
- **collection_layer**: db-interactive-cmd
- **collection_method**: select /*+ skew(store_returns(sr_store_sk sr_customer_sk)) */sr_customer_sk as ctr_customer_sk ...
- **abnormal_patterns**: ["对于HashAgg，由于其重分布存在倾斜，所以优化为双层Agg。"]
- **linked_case_ids**: ["gaussdb-dws-plan-hint-skew-04"]

## check_id: chk-explain-performance-vs-a-rows-vs-e-rows

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows）
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE` 查看 TPC-DS Q24 部分语句执行计划
- **abnormal_patterns**: ["\"第11层算子估算行数为2140，比实际行数严重低估\""]
- **linked_case_ids**: ["gaussdb-dws-planhint-rows-estimate-01"]

## check_id: chk-explain-performance-rows-hint

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时
- **collection_layer**: db-interactive-cmd
- **collection_method**: `select avg(netpaid) from (select /*+rows(store_sales store_returns * 11270)*/ c_last_name ...`
- **abnormal_patterns**: ["\"最终计划如下图所示，运行时间94s，完成调优\""]
- **linked_case_ids**: ["gaussdb-dws-planhint-rows-estimate-01"]

## check_id: chk-explain-data-node-scan

- **type**: metric
- **metric_name**: EXPLAIN · 是否含 Data Node Scan 节点
- **collection_layer**: db-interactive-cmd
- **collection_method**: `如果执行计划中有Data Node Scan节点，那么此执行计划为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。`
- **abnormal_patterns**: ["`Data Node Scan on store_sales \"_REMOTE_TABLE_QUERY_\"`"]
- **linked_case_ids**: ["gaussdb-dws-pushdown-data-node-scan-12"]

## check_id: chk-explain-performance-5

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE` 查看是否有 Vector 前缀算子
- **abnormal_patterns**: ["\"经过分析发现计划走了行引擎。根本原因是：临时计划表input_acct_id_tbl和中间结果转储表row_unlogged_table使用了行存表。\""]
- **linked_case_ids**: ["gaussdb-dws-row-vs-column-store-01"]

## check_id: chk-copy-2

- **type**: metric
- **metric_name**: COPY 语句等待视图 · 轻量级锁等待
- **collection_layer**: db-system-view
- **collection_method**: "根据这5个COPY语句对应的query_id查看等待视图情况"
- **abnormal_patterns**: ["同时只有 1 个 COPY 向 GTM 申请序列值，其余在等待轻量级锁"]
- **linked_case_ids**: ["gaussdb-dws-copy-cdm-sequence-cache-01"]

## check_id: chk-explain-performance-vector-windowagg

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE 执行计划 · Vector WindowAgg 耗时及位置
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE SELECT COUNT(1) over() AS DATACNT, IMSI AS IMSI_IMSI, CAST(TRUNC(((SUM(L4_UL_THROUGHPUT) + SUM(L4_DW_THROUGHPUT))), 0) AS DECIMAL(20)) AS TOTAL_VOLUME_KPIID FROM public.test AS test GROUP BY IMSI ORDER BY TOTAL_VOLUME_KPIID DESC LIMIT 10`
- **abnormal_patterns**: ["\"window agg和sort全部在CN端执行，耗时非常严重\""]
- **linked_case_ids**: ["gaussdb-dws-sort-pushdown-cn-bottleneck-01"]

## check_id: chk-explain-performance-6

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE 改写后执行计划 · 排序下推验证
- **collection_layer**: db-interactive-cmd
- **collection_method**: `EXPLAIN PERFORMANCE SELECT COUNT(1) over() AS DATACNT, IMSI_IMSI, TOTAL_VOLUME_KPIID FROM (SELECT IMSI AS IMSI_IMSI, CAST(TRUNC(((SUM(L4_UL_THROUGHPUT) + SUM(L4_DW_THROUGHPUT))), 0) AS DECIMAL(20)) AS TOTAL_VOLUME_KPIID FROM public.test AS test GROUP BY IMSI ORDER BY TOTAL_VOLUME_KPIID DESC LIMIT 10)`
- **abnormal_patterns**: ["\"经过SQL改写，性能由2.862s提升0.955s，优化效果明显\""]
- **linked_case_ids**: ["gaussdb-dws-sort-pushdown-cn-bottleneck-01"]

## check_id: chk-gs-wlm-session-history-warning-sql

- **type**: metric
- **metric_name**: GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息
- **collection_layer**: db-system-view
- **collection_method**: `SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC`
- **abnormal_patterns**: ["内表行数 ≥ 外表行数 × 10 且内表每DN平均行数 > 10万行且发生下盘","平均每DN行数 > 10万行"]
- **linked_case_ids**: ["gaussdb-dws-hashjoin-large-inner-table-01","gaussdb-dws-large-table-broadcast-01"]

## check_id: chk-gs-wlm-session-history-warning

- **type**: metric
- **metric_name**: GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警
- **collection_layer**: db-system-view
- **collection_method**: `SELECT query,warning FROM GS_WLM_SESSION_STATISTICS ORDER BY start_time DESC`
- **abnormal_patterns**: ["\"Statistic Not Collect schema_test.t1\""]
- **linked_case_ids**: ["gaussdb-dws-stats-not-collected-slow-01"]

## check_id: chk-explain-performance-cpu-io

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络)
- **collection_layer**: db-interactive-cmd
- **collection_method**: `通过执行态信息，我们可以分析出算子为单位的性能，也可以分析出算子内部各步骤的性能，进一步为诊断性能的瓶颈打下了基础。`
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-dws-system-level-tuning-24"]

## check_id: chk-xid

- **type**: metric
- **metric_name**: 当前事务 XID
- **collection_layer**: db-system-view
- **collection_method**: `SELECT txid_current();`
- **abnormal_patterns**: ["\"执行以下命令查询当前的事务XID。\""]
- **linked_case_ids**: ["gaussdb-dws-vacuum-full-long-tx-01"]

## check_id: chk--49

- **type**: metric
- **metric_name**: 活跃事务列表
- **collection_layer**: db-system-view
- **collection_method**: `SELECT txid_current_snapshot(); `
- **abnormal_patterns**: ["活跃事务列表中有 XID < 当前事务 XID"]
- **linked_case_ids**: ["gaussdb-dws-vacuum-full-long-tx-01"]

## check_id: chk-vacuum-defer-cleanup-age

- **type**: metric
- **metric_name**: vacuum_defer_cleanup_age 参数值
- **collection_layer**: db-shell
- **collection_method**: "参数vacuum_defer_cleanup_age不是0，该参数在老版本默认为8000，表示最近8000个事务产生的脏数据不进行回收。"
- **abnormal_patterns**: ["vacuum_defer_cleanup_age != 0"]
- **linked_case_ids**: ["gaussdb-dws-vacuum-defer-cleanup-age-01"]

## check_id: chk-gtm-snapshot-oldestxmin-xid

- **type**: metric
- **metric_name**: GTM snapshot · oldestxmin 与 xid 差值
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_gtm_snapshot_status();`
- **abnormal_patterns**: ["oldestxmin << base+min"]
- **linked_case_ids**: ["gaussdb-dws-cant-fit-xid-old-tx-01"]

## check_id: chk-pgxc-running-xacts

- **type**: metric
- **metric_name**: 老事务列表 (pgxc_running_xacts)
- **collection_layer**: db-system-view
- **collection_method**: `SELECT * FROM pgxc_running_xacts where xmin::text::bigint < $base+$min and xmin::text::bigint > 0;`
- **abnormal_patterns**: ["存在 xmin < base+min 的活跃事务"]
- **linked_case_ids**: ["gaussdb-dws-cant-fit-xid-old-tx-01"]

## check_id: chk-dn-warning

- **type**: metric
- **metric_name**: DN 间导入行数倾斜率(WARNING)
- **collection_layer**: log-grep
- **collection_method**: `WARNING:  Skewness occurs, table name: xxx, min value: xxx, max value: xxx, sum value: xxx, avg value: xxx, skew ratio: xxx`
- **abnormal_patterns**: ["skew ratio > table_skewness_warning_threshold"]
- **linked_case_ids**: ["gaussdb-import-skew-warning-07"]

## check_id: chk-pg-stat-activity-idle

- **type**: metric
- **metric_name**: pg_stat_activity · idle 连接数
- **collection_layer**: db-system-view
- **collection_method**: `SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';`
- **abnormal_patterns**: ["`non-active的个数表示空闲连接数，例如，non-active为508，说明当前有大量的空闲连接。`"]
- **linked_case_ids**: ["gaussdb-too-many-clients-21"]

## check_id: chk-explain-performance-7

- **type**: metric
- **metric_name**: EXPLAIN PERFORMANCE · 算子分布
- **collection_layer**: db-interactive-cmd
- **collection_method**: `explain performance`
- **abnormal_patterns**: ["`执行计划中出现Sort和WindowAgg，第3~6步集中在一个DN上进行，使SQL非常缓慢`"]
- **linked_case_ids**: ["gaussdb-windowagg-single-dn-04"]

## check_id: chk-a-time-dn

- **type**: metric
- **metric_name**: 算子 A-time(在单 DN 上的运行耗时)
- **collection_layer**: db-interactive-cmd
- **collection_method**: 
- **abnormal_patterns**: ["NULL"]
- **linked_case_ids**: ["gaussdb-windowagg-single-dn-04"]

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

## check_id: chk-mongod-nofile-nproc-fsize-memlock-ulimit

- **type**: metric
- **metric_name**: mongod 进程 nofile / nproc / fsize / memlock 等 ulimit
- **collection_layer**: os
- **collection_method**: (Ampere 文档未直接给读法 · 通用方法 `cat /proc/$(pgrep -f mongod)/limits`)
- **abnormal_patterns**: ["nofile < 64000 / nproc < 64000(基于 mitigation 给定的推荐值)"]
- **linked_case_ids**: ["mongo-ulimit-low-defaults-mongod-issues-03"]

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

## check_id: chk-mongod-version-uname-r

- **type**: metric
- **metric_name**: mongod --version + uname -r
- **collection_layer**: os
- **collection_method**: (原文未给具体命令 · 通用 `mongod --version` + `uname -r`)
- **abnormal_patterns**: ["mongod major >= 8 AND kernel == 6.19.x"]
- **linked_case_ids**: ["mongo-startup-kernel-6-19-tcmalloc-incompat-01"]

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

## check_id: chk-mongod-log-wt-cache-full

- **type**: metric
- **metric_name**: mongod log "WT_CACHE_FULL" 出现频次
- **collection_layer**: log-grep
- **collection_method**: (NULL · 原文未给具体 grep 命令)
- **abnormal_patterns**: ["任意一次出现该错误即异常"]
- **linked_case_ids**: ["mongo-inmemory-cache-full-overflow-01"]

## check_id: chk-dbstats-collstats-size-vs-inmemorysizegb

- **type**: metric
- **metric_name**: dbStats / collStats 总 size vs inMemorySizeGB
- **collection_layer**: mongo-runtime-cmd
- **collection_method**: "To specify a new size, use the"
- **abnormal_patterns**: ["sum(dbStats.dataSize) + indexes + oplog 接近 inMemorySizeGB"]
- **linked_case_ids**: ["mongo-inmemory-cache-full-overflow-01"]

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

## check_id: chk-driver-maxpoolsize-2

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

## check_id: chk-wiredtiger-cache-maximum-bytes-configured-2

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

## check_id: chk-net-core-netdev-max-backlog-2

- **type**: parameter-current-value
- **param_name**: net.core.netdev_max_backlog
- **recommended_values**: ["65535"]
- **violation_patterns**: ["`current < 8096 (recommended)`","1000"]
- **linked_case_ids**: ["mongo-client-os-tcp-tuning-01","gaussdb-other-x49"]

## check_id: chk-net-ipv4-tcp-keepalive-time-2

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

## check_id: chk-bios-advanced-misc-config-support-smmu-2

- **type**: parameter-current-value
- **param_name**: bios.advanced.misc_config.support_smmu
- **recommended_values**: []
- **violation_patterns**: ["`current = \"Enable\" AND scenario = non-virtualization`"]
- **linked_case_ids**: ["kunpeng-bios-smmu-enabled-non-virt-01"]

## check_id: chk-bios-advanced-misc-config-cpu-prefetching-configuration-2

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

## check_id: chk-libvirt-domain-cputune-vcpupin-2

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

## check_id: chk-vm-dirty-ratio-vm-dirty-background-ratio-2

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

## check_id: chk-shared-buffers

- **type**: parameter-current-value
- **param_name**: shared_buffers
- **recommended_values**: ["NULL (按业务情况调大)","8GB"]
- **violation_patterns**: ["设值过小","配置过小,导致 buffer 淘汰频繁","设置过小（32M）","设置过小（示例为32MB）","设置过小,数据页面频繁从磁盘加载"]
- **linked_case_ids**: ["gaussdb-memory-shared-buffer-miss-01","gaussdb-overall-slow-config-shared-buffers-01","gaussdb-dws-table-bloat-vacuum-slow-01","gaussdb-dws-query-slow-table-bloat-01","gaussdb-dws-system-level-tuning-24"]
- **rationales**: ["\"共享缓存区不足，导致SQL的buffer命中率低\"","\"shared_buffers配置过小，导致buffer淘汰频繁。\"","\"内存参数设置不合理\""]

## check_id: chk-work-mem

- **type**: parameter-current-value
- **param_name**: work_mem
- **recommended_values**: ["增大(具体值联系管理员)","根据业务情况适当调大","调大以容纳 HashAgg 所需内存","128MB","适当调大 (依据 Explain Performance 输出)"]
- **violation_patterns**: ["设值过小，不足以容纳算子运算数据","设值过小,无法支持 HashAgg 所需 in-memory hash table","排序等算子可使用的 work_mem 过小,导致异常下盘过多","不足以容纳 hash table，导致优化器选择 GroupAgg+Sort","设置偏小（64M）","设置过小（CN/DN均为64MB）","非自适应场景下设置过小,导致 hash/agg/sort 等可下盘算子触发下盘","非内存自适应场景下未设置,算子越过阈值即下盘"]
- **linked_case_ids**: ["gaussdb-memory-work-mem-spill-01","gaussdb-groupagg-sort-vs-hashagg-08","gaussdb-overall-slow-config-shared-buffers-01","gaussdb-group-by-sort-perf-work-mem-01","gaussdb-dws-table-bloat-vacuum-slow-01","gaussdb-dws-query-slow-table-bloat-01","gaussdb-dws-operator-spill-23","gaussdb-dws-system-level-tuning-24"]
- **rationales**: ["\"如果work_mem所限定的物理内存不够，算子运算的数据将被写入临时表空间，会带来5-10倍的性能下降。\"","`可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差`","\"排序等算子可使用的work_mem过小，导致异常下盘过多\"","\"导致性能较差。\"","`当内存使用超过该参数后将触发算子下盘`","`超过阈值则下盘`"]

## check_id: chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo-2

- **type**: parameter-current-value
- **param_name**: recovery_max_workers/recovery_parse_workers/recovery_redo_workers
- **recommended_values**: []
- **violation_patterns**: ["这三个参数都为1，是串行回放"]
- **linked_case_ids**: ["gaussdb-other-x05"]

## check_id: chk-ubtree

- **type**: parameter-current-value
- **param_name**: ubtree页面分裂策略
- **recommended_values**: ["DEFAULT"]
- **violation_patterns**: ["INSERTPT"]
- **linked_case_ids**: ["gaussdb-other-key-x10"]

## check_id: chk-autovacuum

- **type**: parameter-current-value
- **param_name**: autovacuum相关参数
- **recommended_values**: []
- **violation_patterns**: ["被关闭或配置阈值过高"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-x17"]

## check_id: chk-wal-file-init-num

- **type**: parameter-current-value
- **param_name**: wal file init num
- **recommended_values**: ["增大"]
- **violation_patterns**: ["过小"]
- **linked_case_ids**: ["gaussdb-other-tpcc-x20"]

## check_id: chk-advance-xlog-file-num

- **type**: parameter-current-value
- **param_name**: advance_xlog_file_num
- **recommended_values**: ["增大"]
- **violation_patterns**: ["过小"]
- **linked_case_ids**: ["gaussdb-other-tpcc-x21"]

## check_id: chk-query-dop

- **type**: parameter-current-value
- **param_name**: query_dop
- **recommended_values**: ["16","0 (动态) — 需开启 use_workload_manager=on"]
- **violation_patterns**: ["未开启SMP并行","未配置或为 0,未按系统资源动态获取并行度"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-seqscan-x33","gaussdb-dws-system-level-tuning-24"]

## check_id: chk-log-min-duration-statement

- **type**: parameter-current-value
- **param_name**: log_min_duration_statement
- **recommended_values**: ["3000ms"]
- **violation_patterns**: ["10ms"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-tps-x34"]

## check_id: chk-walwriter-cpu-bind

- **type**: parameter-current-value
- **param_name**: walwriter_cpu_bind
- **recommended_values**: ["31"]
- **violation_patterns**: ["未绑定指定CPU核"]
- **linked_case_ids**: ["gaussdb-disk-io-saturation-tps-x34"]

## check_id: chk-autovacuum-ustore

- **type**: parameter-current-value
- **param_name**: autovacuum (ustore表的自动清理)
- **recommended_values**: []
- **violation_patterns**: ["不会清理用户表"]
- **linked_case_ids**: ["gaussdb-query-slow-dataarts-x37"]

## check_id: chk-thread-pool-attr-2

- **type**: parameter-current-value
- **param_name**: thread_pool_attr
- **recommended_values**: ["'1024,4,(numabind:0-31,32-63,64-95,96-127)'","NULL (按业务规模调大)"]
- **violation_patterns**: ["'2048,2,(nobind)'","线程池 worker 参数设置过小,导致业务排队"]
- **linked_case_ids**: ["gaussdb-other-tpcc-x38","gaussdb-overall-slow-config-shared-buffers-01"]
- **rationales**: ["\"线程池worker参数thread_pool_attr设置过小，导致业务排队。\""]

## check_id: chk-vacuum-cost-delay

- **type**: parameter-current-value
- **param_name**: vacuum_cost_delay
- **recommended_values**: ["30ms"]
- **violation_patterns**: ["1ms"]
- **linked_case_ids**: ["gaussdb-other-tps-x41"]

## check_id: chk-undo-retention-time-2

- **type**: parameter-current-value
- **param_name**: undo_retention_time
- **recommended_values**: []
- **violation_patterns**: ["900s (开启闪回特性)"]
- **linked_case_ids**: ["gaussdb-other-ustore-x45"]

## check_id: chk-sys-kernel-debug-sched-features

- **type**: parameter-current-value
- **param_name**: /sys/kernel/debug/sched_features
- **recommended_values**: ["NO_SIS_PROP"]
- **violation_patterns**: ["SIS_PROP"]
- **linked_case_ids**: ["gaussdb-query-slow-insert-x46"]

## check_id: chk-logintimeout

- **type**: parameter-current-value
- **param_name**: loginTimeout
- **recommended_values**: ["30"]
- **violation_patterns**: ["6"]
- **linked_case_ids**: ["gaussdb-cpu-high-jdbc-x48"]

## check_id: chk-recovery-parse-workers-recovery-redo-workers

- **type**: parameter-current-value
- **param_name**: recovery_parse_workers / recovery_redo_workers
- **recommended_values**: ["极致RTO配置一：recovery_parse_workers = 1，recovery_redo_workers=2"]
- **violation_patterns**: ["并行回放参数设置：recovery_parse_workers=1，recovery_redo_workers=1，recovery_max_workers=4"]
- **linked_case_ids**: ["gaussdb-other-rto-x50"]

## check_id: chk-client-encoding-server-encoding-2

- **type**: parameter-current-value
- **param_name**: client_encoding / server_encoding
- **recommended_values**: ["保持client encoding和server encoding一致(JDBC连接串设置GB18030-2022)"]
- **violation_patterns**: ["client encoding和server encoding不同(JDBC侧非GB18030-2022，而DB侧为GB18030-2022)"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-jdbc-x55"]

## check_id: chk-rewrite-rule

- **type**: parameter-current-value
- **param_name**: rewrite_rule
- **recommended_values**: ["partialpush","intargetlist","lazyagg","magicset","包含 'partialpush' (如 set rewrite_rule='partialpush')","uniquecheck"]
- **violation_patterns**: ["默认值不含 partialpush，无法对含不可下推函数的语句做部分下推优化","未包含 intargetlist，目标列相关子查询无法被提升转为 JOIN","none（未开启 partialpush）","none（未开启 intargetlist）","未包含lazyagg","未包含magicset","未包含intargetlist","不含 partialpush 规则 → 含不下推函数的子查询无法部分下推","未包含intargetlist（如设为'none'）","未包含uniquecheck"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-rewrite-rule-partialpush-01","gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01","gaussdb-query-slow-no-partial-pushdown-01","gaussdb-query-slow-correlated-subquery-target-list-01","gaussdb-rewrite-lazyagg-double-aggregate-slow-01","gaussdb-rewrite-magicset-correlated-subquery-slow-01","gaussdb-rewrite-v8-intargetlist-subplan-slow-01","gaussdb-rewrite-rule-partialpush-13","gaussdb-rewrite-intargetlist-subplan-slow-01","gaussdb-rewrite-uniquecheck-subquery-join-01"]
- **rationales**: ["`该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`","`导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`","\"由于目标列中的相关子查询无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下\"","`网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源`","\"打开之后报错。ERROR: more than one row returned by a subquery used as an expression（当数据中存在重复时）\""]

## check_id: chk-enable-hashjoin-2

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
- **violation_patterns**: ["默认开启，在外表行数较大时导致选择 NestLoop","默认开启，优化器选择了NestLoop","默认on，导致优化器在行数估算偏小时选择NestLoop","默认开启，大行数场景不优","on（默认），大表 JOIN 时优化器错误选择 NestLoop"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-outer-01","gaussdb-query-slow-nestloop-hashjoin-02","gaussdb-query-slow-nestloop-large-rowset-01","gaussdb-plan-suboptimal-nestloop-large-table-01","gaussdb-dws-nestloop-to-hashjoin-01"]
- **rationales**: ["\"NestLoop耗时27秒\"","\"如下的例子中NestLoop耗时27秒\"","NestLoop耗时181秒","\"NestLoop耗时181秒\""]

## check_id: chk-enable-mergejoin

- **type**: parameter-current-value
- **param_name**: enable_mergejoin
- **recommended_values**: ["off"]
- **violation_patterns**: ["默认开启，干扰优化器选择 HashJoin","默认开启，大行数场景选 Merge Join 不优"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-nestloop-large-outer-01","gaussdb-plan-suboptimal-nestloop-large-table-01"]

## check_id: chk-enable-sort

- **type**: parameter-current-value
- **param_name**: enable_sort
- **recommended_values**: ["off"]
- **violation_patterns**: ["默认开启，大结果集时优化器选择 Sort+GroupAgg","默认开启，导致优化器选择Sort+GroupAgg","默认on，使优化器在某些场景错误选择Sort+GroupAgg","默认开启导致大结果集选择 Sort+GroupAgg","on（默认），导致优化器在大结果集场景错误选择 Sort+GroupAgg"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01","gaussdb-query-slow-groupagg-sort-03","gaussdb-query-slow-sort-groupagg-large-result-01","gaussdb-plan-suboptimal-groupagg-sort-01","gaussdb-dws-groupagg-to-hashagg-01"]
- **rationales**: ["\"Sort+GroupAgg耗时2417ms，HashAgg耗时2324ms\"","如果大结果集选择了Sort+GroupAgg"]

## check_id: chk-best-agg-plan

- **type**: parameter-current-value
- **param_name**: best_agg_plan
- **recommended_values**: ["3` (hashagg+redistribute+hashagg，当 agg 收敛度大时)","2` （收敛度小时选择 redistribute+hashagg）或 `3`（hashagg+redistribute+hashagg）"]
- **violation_patterns**: ["默认值为 0，优化器自动选择，但代价估算偏差大时选择不优","默认 0（优化器自动选择），中间结果集估算偏差大时可能选择次优计划"]
- **linked_case_ids**: ["gaussdb-query-slow-agg-plan-mode-01","gaussdb-dws-agg-plan-tuning-01"]
- **rationales**: ["这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差","\"这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差，这时候就需要通过best_agg_plan进行agg计算模型的干预\""]

## check_id: chk-a-format-load-with-constraints-violation

- **type**: parameter-current-value
- **param_name**: a_format_load_with_constraints_violation
- **recommended_values**: ["默认不开启;仅在确有约束冲突时设为 's2'"]
- **violation_patterns**: ["默认未设置导致约束冲突无法容错；设置为 's2' 后性能劣化"]
- **linked_case_ids**: ["gaussdb-copy-constraint-violation-tolerance-01"]
- **rationales**: ["\"该功能下数据导入过程会从批量插入变为单行插入，对应的导入性能会有所劣化。\""]

## check_id: chk-cost-param

- **type**: parameter-current-value
- **param_name**: cost_param
- **recommended_values**: ["1` (bit0=1)","2` (bit1=1)","1` （bit0 = 1，使用改良的选择率估算方法）","2` （bit1 = 1，过滤条件强相关时选最小选择率）"]
- **violation_patterns**: ["bit0 为 0，Anti Join 自连接估算不准","bit1 为 0，强相关列选择率乘积估算不准","bit0 = 0（默认），对自连接 Anti Join 的选择率估算不准确","bit1 = 0（默认），多过滤条件列强相关时选择率计算方式不准确"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-anti-join-row-estimate-01","gaussdb-plan-suboptimal-correlated-filter-selectivity-01","gaussdb-dws-cost-param-anti-join-01","gaussdb-dws-cost-param-filter-selectivity-01"]
- **rationales**: ["当使用cost_param的bit0为0时，估算Anti Join的行数与实际行数相差很大，导致查询性能下降","导致行数估算不准确，查询性能较差","\"估算Anti Join的行数与实际行数相差很大，导致查询性能下降\"","\"导致行数估算不准确，查询性能较差\""]

## check_id: chk-skew-option

- **type**: parameter-current-value
- **param_name**: skew_option
- **recommended_values**: ["normal"]
- **violation_patterns**: ["默认值未开启倾斜优化","未启用或设置为 lazy 时，优化器不对已知倾斜做额外优化"]
- **linked_case_ids**: ["gaussdb-data-skew-compute-redistribute-01","gaussdb-dws-data-skew-compute-01"]
- **rationales**: ["由于倾斜节点所需要运算的数据量远大于其它节点，导致倾斜节点降低系统整体性能","\"倾斜节点需要处理更多的数据，导致倾斜节点的计算性能远低于其他节点\""]

## check_id: chk-default-statistics-target

- **type**: parameter-current-value
- **param_name**: default_statistics_target
- **recommended_values**: ["100"]
- **violation_patterns**: ["设置为 -2，导致统计信息精度变化影响计划选择"]
- **linked_case_ids**: ["gaussdb-plan-suboptimal-statistics-change-plan-regression-01"]
- **rationales**: ["计划相比于默认统计信息发生劣化"]

## check_id: chk-behavior-compat-options

- **type**: parameter-current-value
- **param_name**: behavior_compat_options
- **recommended_values**: ["'plsql_security_definer'` (当需要默认使用创建者权限时)"]
- **violation_patterns**: ["默认未设置 'plsql_security_definer'，存储过程使用调用者权限"]
- **linked_case_ids**: ["gaussdb-procedure-security-definer-permission-01"]
- **rationales**: ["\"选择不当的权限模式可能导致越权访问敏感数据，或进行未授权的资源操作。\""]

## check_id: chk-enable-fast-query-shipping

- **type**: parameter-current-value
- **param_name**: enable_fast_query_shipping
- **recommended_values**: ["on","off (诊断时)"]
- **violation_patterns**: ["off 时无法生成下推语句计划","默认开启 + 不下推 SQL 仍走 fast-shipping 屏蔽真实计划"]
- **linked_case_ids**: ["gaussdb-statement-not-shippable-cn-bottleneck-01","gaussdb-dws-pushdown-data-node-scan-12"]
- **rationales**: ["\"在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。\""]

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
- **violation_patterns**: ["设置过小（12G，节点总内存256G）","设置过小（示例为12GB）","内存自适应场景下设置过小,算子无法获得足够内存"]
- **linked_case_ids**: ["gaussdb-dws-table-bloat-vacuum-slow-01","gaussdb-dws-query-slow-table-bloat-01","gaussdb-dws-system-level-tuning-24"]
- **rationales**: ["\"内存参数设置不合理\""]

## check_id: chk-qrw-inlist2join-optmode

- **type**: parameter-current-value
- **param_name**: qrw_inlist2join_optmode
- **recommended_values**: ["rule_base"]
- **violation_patterns**: ["cost_base（默认），优化器估算不准时不转化","默认 cost_base 时优化器估算不准导致未做转化"]
- **linked_case_ids**: ["gaussdb-dws-in-constant-no-join-slow-01","gaussdb-dws-inlist2join-large-constants-01"]
- **rationales**: ["\"如果优化器估算不准，可能会出现需要转化的场景没有做转化，导致性能较差。\""]

## check_id: chk-fetchsize

- **type**: parameter-current-value
- **param_name**: fetchSize
- **recommended_values**: ["较小的值 (如 10)"]
- **violation_patterns**: ["默认值导致一次性加载全部结果集"]
- **linked_case_ids**: ["dws-jdbc-processresult-slow-01"]
- **rationales**: ["\"结果集过大，一次性全部加载，消耗大量时间。\""]

## check_id: chk-period

- **type**: parameter-current-value
- **param_name**: period
- **recommended_values**: ["1 day` (默认; 范围 1 hour ~ 100 years)"]
- **violation_patterns**: ["未设置导致无法自动创建分区"]
- **linked_case_ids**: ["dws-partition-auto-period-ttl-01"]
- **rationales**: ["\"普通分区表无法自动创建新分区\""]

## check_id: chk-ttl

- **type**: parameter-current-value
- **param_name**: ttl
- **recommended_values**: ["大于或等于 period (范围 1 hour ~ 100 years)"]
- **violation_patterns**: ["未设置导致无法自动淘汰过期分区"]
- **linked_case_ids**: ["dws-partition-auto-period-ttl-01"]
- **rationales**: ["\"普通分区表无法...清理过期分区\""]

## check_id: chk-disk-cache-max-size

- **type**: parameter-current-value
- **param_name**: disk_cache_max_size
- **recommended_values**: ["EVS 容量的 1/2 (默认值);若列存表没有索引可适当调大","在没有可清理资源时，可缩小至 300GB 或更小"]
- **violation_patterns**: ["配置过小导致缓存空间不足无法容纳热数据","设置过大占用 EVS 较多空间"]
- **linked_case_ids**: ["dws-3-0-disk-cache-size-low-hit-01","dws-3-0-disk-usage-readonly-01"]
- **rationales**: ["\"缩小Disk Cache可用规模后可能带来查询性能下降。\"","\"缺点是缩小Disk Cache可用规模后可能带来查询性能下降。\""]

## check_id: chk-disk-cache-dual-write-option

- **type**: parameter-current-value
- **param_name**: disk_cache_dual_write_option
- **recommended_values**: ["all` (对普通 v3 表和 HStore 表都开启缓存双写)"]
- **violation_patterns**: ["默认 hstore_only,首次读普通 v3 表性能差"]
- **linked_case_ids**: ["dws-3-0-disk-cache-size-low-hit-01"]

## check_id: chk-min-batch-rows

- **type**: parameter-current-value
- **param_name**: min_batch_rows
- **recommended_values**: ["通过 SET 调整为更小值 (session 级生效)"]
- **violation_patterns**: ["攒批大小过大"]
- **linked_case_ids**: ["dws-3-0-batching-import-memory-01"]

## check_id: chk-autovacuum-2

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

## check_id: chk-enable-codegen-2

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

## check_id: chk-psort-work-mem-2

- **type**: parameter-current-value
- **param_name**: psort_work_mem
- **recommended_values**: []
- **violation_patterns**: ["设置过小，导致PCK排序时下盘","设值过小，导致 PCK 排序下盘写临时文件，影响导入性能"]
- **linked_case_ids**: ["gaussdb-dws-query-slow-vacuum-pck-sort-01","gaussdb-dws-pck-scan-acceleration-01"]
- **rationales**: ["\"如果表较大或GUC参数psort_work_mem设置较小，会导致PCK排序时产生下盘（数据库选择将临时结果暂存到磁盘），进行外部排序；一旦进行外部排序，时间消耗就会增加很多。\"","\"如果无法在内存中完成排序时，会下盘写临时文件，这时就会产生较大的影响\""]

## check_id: chk-enable-delta

- **type**: parameter-current-value
- **param_name**: ENABLE_DELTA
- **recommended_values**: ["ON"]
- **violation_patterns**: ["默认关闭（OFF），小批量INSERT产生大量小CU"]
- **linked_case_ids**: ["gaussdb-dws-disk-space-columnar-table-bloat-01"]
- **rationales**: ["\"列存表多次执行INSERT后，发现表膨胀。\""]

## check_id: chk-resource-pool-cpu-dedicated-quota

- **type**: parameter-current-value
- **param_name**: resource_pool.cpu_dedicated_quota
- **recommended_values**: []
- **violation_patterns**: ["未配置专属限额，导致复杂作业争抢 CPU"]
- **linked_case_ids**: ["gaussdb-dws-high-cpu-01"]
- **rationales**: ["防止极端场景下某个语句占用CPU资源过多，导致数据库内其他语句因争抢CPU而变得缓慢迟钝的情况"]

## check_id: chk-temp-file-limit

- **type**: parameter-current-value
- **param_name**: temp_file_limit
- **recommended_values**: ["根据实际磁盘可用空间设置上限"]
- **violation_patterns**: ["默认或过大,可能导致下盘填满磁盘"]
- **linked_case_ids**: ["gaussdb-dws-operator-spill-23"]
- **rationales**: ["`防止下盘文件将磁盘空间占满，超过该值将报错退出`"]

## check_id: chk-sequence-cache

- **type**: parameter-current-value
- **param_name**: sequence.cache
- **recommended_values**: ["10000 (按业务每次同步量评估)"]
- **violation_patterns**: ["default 为 1, 并发 COPY 入库时 CN 频繁与 GTM 建连"]
- **linked_case_ids**: ["gaussdb-dws-copy-cdm-sequence-cache-01"]
- **rationales**: ["\"默认创建的sequence的cache为1，导致在并发COPY入库时，CN频繁与GTM建连，且多个并发之间存在轻量锁争抢，导致数据同步效率低\""]

## check_id: chk-cstore-buffers

- **type**: parameter-current-value
- **param_name**: cstore_buffers
- **recommended_values**: []
- **violation_patterns**: ["设置过小,列存表场景下扫描频繁触发 IO"]
- **linked_case_ids**: ["gaussdb-dws-system-level-tuning-24"]

## check_id: chk-comm-max-stream

- **type**: parameter-current-value
- **param_name**: comm_max_stream
- **recommended_values**: ["调大但不可过大(过大占内存)"]
- **violation_patterns**: ["并发/并行度提升后,Stream 算子不足"]
- **linked_case_ids**: ["gaussdb-dws-system-level-tuning-24"]
- **rationales**: ["`否则Stream个数不够`"]

## check_id: chk-vacuum-defer-cleanup-age-2

- **type**: parameter-current-value
- **param_name**: vacuum_defer_cleanup_age
- **recommended_values**: ["0"]
- **violation_patterns**: ["非 0 (老版本默认 8000) 导致延迟清理"]
- **linked_case_ids**: ["gaussdb-dws-vacuum-defer-cleanup-age-01"]
- **rationales**: ["\"表示最近8000个事务产生的脏数据不进行回收\""]

## check_id: chk-enable-stream-operator

- **type**: parameter-current-value
- **param_name**: enable_stream_operator
- **recommended_values**: ["on"]
- **violation_patterns**: ["关闭(off) 状态下,DN 一次性返回导入行数受影响,无法在 CN 计算倾斜率"]
- **linked_case_ids**: ["gaussdb-import-skew-warning-07"]

## check_id: chk-table-skewness-warning-threshold

- **type**: parameter-current-value
- **param_name**: table_skewness_warning_threshold
- **recommended_values**: ["0~1 (设为 <1 即开启)"]
- **violation_patterns**: ["默认值 1(关闭状态),不会触发告警"]
- **linked_case_ids**: ["gaussdb-import-skew-warning-07"]

## check_id: chk-table-skewness-warning-rows

- **type**: parameter-current-value
- **param_name**: table_skewness_warning_rows
- **recommended_values**: ["default 100000 (设为业务可接受最小行数)"]
- **violation_patterns**: ["设过小会在小数据量导入时无意义告警"]
- **linked_case_ids**: ["gaussdb-import-skew-warning-07"]

## check_id: chk-session-timeout

- **type**: parameter-current-value
- **param_name**: session_timeout
- **recommended_values**: ["> 0 (不建议设为 0)"]
- **violation_patterns**: ["默认 600s,在空闲连接积压场景下可调小"]
- **linked_case_ids**: ["gaussdb-too-many-clients-21"]
- **rationales**: ["`non-active的个数表示空闲连接数，例如，non-active为508，说明当前有大量的空闲连接。`"]

## check_id: chk-max-connections

- **type**: parameter-current-value
- **param_name**: max_connections
- **recommended_values**: ["> default · 由 DBA 根据并发评估"]
- **violation_patterns**: ["默认 800(CN) / 5000(DN),已达上限"]
- **linked_case_ids**: ["gaussdb-too-many-clients-21"]
- **rationales**: ["`当前数据库连接已经超过了最大连接数`"]

## check_id: chk-etc-security-limits-conf-ulimit

- **type**: parameter-current-value
- **param_name**: /etc/security/limits.conf 中各 ulimit 项
- **recommended_values**: []
- **violation_patterns**: ["默认偏低(发行版自带)"]
- **linked_case_ids**: ["mongo-ulimit-low-defaults-mongod-issues-03"]

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

## check_id: chk-vm-swappiness-2

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

## check_id: chk-storage-inmemory-engineconfig-inmemorysizegb-inmemorysizegb

- **type**: parameter-current-value
- **param_name**: storage.inMemory.engineConfig.inMemorySizeGB / --inMemorySizeGB
- **recommended_values**: []
- **violation_patterns**: ["inMemorySizeGB < 当前业务总数据(含索引 + oplog)"]
- **linked_case_ids**: ["mongo-inmemory-cache-full-overflow-01"]

## check_id: chk-defaultwriteconcern-w-write-concern

- **type**: parameter-current-value
- **param_name**: defaultWriteConcern.w(及业务调用侧 write concern)
- **recommended_values**: []
- **violation_patterns**: ["`\"majority\"` 同时 secondary 不健康(写卡);或 < majority(读 stale)"]
- **linked_case_ids**: ["mongo-psa-majority-writeconcern-perf-degradation-01"]

## check_id: chk-storage-wiredtiger-engineconfig-cachesizegb-cachesizepct-2

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

## check_id: chk-arm64-graviton2-march-armv8-2-a-lse

- **type**: parameter-current-value
- **param_name**: ARM64 Graviton2+ 编译时用 -march=armv8.2-a 启用 LSE 原子指令
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

## check_id: chk-arm64-moutline-atomics-lse

- **type**: parameter-current-value
- **param_name**: ARM64 多代兼容部署时用 -moutline-atomics 运行期检测 LSE 支持
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

## check_id: chk-graviton2-dmesg-lscpu-lse

- **type**: parameter-current-value
- **param_name**: Graviton2 部署后用 dmesg/lscpu 验证 LSE 原子指令已被内核检测启用
- **recommended_values**: []
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

## check_id: chk-mongodb-tcp-tw-reuse-time-wait-socket

- **type**: parameter-current-value
- **param_name**: MongoDB 客户端启用 tcp_tw_reuse 让 TIME-WAIT socket 可复用以新建连接
- **recommended_values**: ["net.ipv4.tcp_tw_reuse = 1"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。\n\n原文 sysctl.conf 增量内容(逐字 · 补充 recommendation_value 依据):\n\n```\nnet.ipv4.tcp_tw_reuse = 1\n```\n\n表 1 参数说明(逐字 · 补充场景理解): 允许将TIME-WAIT sockets重新用于新的TCP连接。"]
- **standalone**: true
- **bp_source_ids**: ["os-net-tcp-tw-reuse-enable-mongo-client-02"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0031.html

## check_id: chk-mongodb-listen-backlog-somaxconn-65535-accept

- **type**: parameter-current-value
- **param_name**: MongoDB 客户端 listen() backlog 上限 somaxconn 调至 65535 防 accept 队列溢出
- **recommended_values**: ["net.core.somaxconn = 65535"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。\n\n原文 sysctl.conf 增量内容(逐字 · 补充 recommendation_value 依据):\n\n```\nnet.core.somaxconn = 65535\n```\n\n表 1 参数说明(逐字 · 补充场景理解): 定义了系统中每一个端口最大的监测队列的长度，这是个全局的参数，默认值为128。"]
- **standalone**: true
- **bp_source_ids**: ["os-net-somaxconn-mongo-client-65535-03"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0031.html

## check_id: chk-mongodb-netdev-max-backlog-8096

- **type**: parameter-current-value
- **param_name**: MongoDB 客户端调大 netdev_max_backlog 至 8096 避免高入流量丢包
- **recommended_values**: ["net.core.netdev_max_backlog = 8096"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。\n\n原文 sysctl.conf 增量内容(逐字 · 补充 recommendation_value 依据):\n\n```\nnet.core.netdev_max_backlog = 8096\n```\n\n表 1 参数说明(逐字 · 补充场景理解): 每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目。"]
- **standalone**: true
- **bp_source_ids**: ["os-net-netdev-max-backlog-mongo-client-8096-04"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0031.html

## check_id: chk-mongodb-tcp-max-syn-backlog-8192-syn

- **type**: parameter-current-value
- **param_name**: MongoDB 客户端调大 tcp_max_syn_backlog 至 8192 防 SYN 队列溢出
- **recommended_values**: ["net.ipv4.tcp_max_syn_backlog = 8192"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。\n\n原文 sysctl.conf 增量内容(逐字 · 补充 recommendation_value 依据):\n\n```\nnet.ipv4.tcp_max_syn_backlog = 8192\n```\n\n表 1 参数说明(逐字 · 补充场景理解): 表示那些尚未收到客户端确认信息的连接（SYN消息）队列的长度，默认为1024，加大队列长度"]
- **standalone**: true
- **bp_source_ids**: ["os-net-tcp-max-syn-backlog-mongo-client-8192-05"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0031.html

## check_id: chk-mongodb-tcp-fin-timeout-30-fin-wait-2

- **type**: parameter-current-value
- **param_name**: MongoDB 客户端调小 tcp_fin_timeout 至 30 秒缩短 FIN-WAIT-2 占用
- **recommended_values**: ["net.ipv4.tcp_fin_timeout = 30"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。\n\n原文 sysctl.conf 增量内容(逐字 · 补充 recommendation_value 依据):\n\n```\nnet.ipv4.tcp_fin_timeout = 30\n```"]
- **standalone**: true
- **bp_source_ids**: ["os-net-tcp-fin-timeout-mongo-client-30s-07"]
- **risk_severity**: info
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0031.html

## check_id: chk-mongodb-tcp-max-tw-buckets-3000-time-wait

- **type**: parameter-current-value
- **param_name**: MongoDB 客户端调小 tcp_max_tw_buckets 至 3000 加快 TIME-WAIT 强制回收
- **recommended_values**: ["net.ipv4.tcp_max_tw_buckets = 3000"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。\n\n原文 sysctl.conf 增量内容(逐字 · 补充 recommendation_value 依据):\n\n```\nnet.ipv4.tcp_max_tw_buckets = 3000\n```\n\n表 1 参数说明(逐字 · 补充场景理解): 表示系统同时保持TIME_WAIT sockets的最大数量，默认为180000。"]
- **standalone**: true
- **bp_source_ids**: ["os-net-tcp-max-tw-buckets-mongo-client-3000-08"]
- **risk_severity**: info
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0031.html

## check_id: chk-boostkit-vm-dirty-ratio-5

- **type**: parameter-current-value
- **param_name**: 鲲鹏 BoostKit 数据库场景 vm.dirty_ratio 设为 5 限制脏页堆积
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

## check_id: chk-kvm-mongod-vcpu-placement-static-cpuset-worker-numa-die

- **type**: parameter-current-value
- **param_name**: KVM 虚拟机部署 mongod 时 · vcpu placement=static + cpuset 限定 worker 线程范围 · 防跨 NUMA 跨 DIE
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

## check_id: chk-kvm-mongod-512mb-host-kernel-cmdline-vm-xml-memorybacking

- **type**: parameter-current-value
- **param_name**: KVM 虚拟化场景为 mongod 虚机分配 512MB 大页(Host kernel cmdline + VM xml memoryBacking)
- **recommended_values**: ["default_hugepagesz=512M hugepagesz=512M hugepages=256"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["在Linux字段一行的最后输入以下配置。 1 default_hugepagesz=512M hugepagesz=512M  hugepages=256 pci=realloc\n\n补充原文配套的 VM xml 步:\n 虚拟机配置大页内存。虚拟机xml文件的配置参考如下。"]
- **standalone**: true
- **bp_source_ids**: ["os-kvm-vm-hugepages-allocate-tlb-miss-01"]
- **risk_severity**: warning
- **recommendation_layer**: kernel-cmdline
- **scope**: linux-mm
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0021.html

## check_id: chk-read-ahead-kb-128kb-4096kb

- **type**: parameter-current-value
- **param_name**: 磁盘顺序读场景下将 read_ahead_kb 从默认 128KB 调大至 4096KB 以充分利用预取性能提升
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

## check_id: chk-xfs-blocksize-8192b-i-o

- **type**: parameter-current-value
- **param_name**: 大文件操作场景使用 XFS 文件系统并将 blocksize 设为 8192B 以提升 I/O 吞吐
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
- **recommended_values**: ["(NULL · 原文无具体参数名+推荐值双命中 · 推荐为应用设计模式)"]
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
- **recommended_values**: ["(NULL · 原文无具体参数名+推荐值双命中 · 推荐为应用设计模式)"]
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
- **recommended_values**: ["(NULL · 原文只给\"should be supplied\"定性要求无具体超时值 · AND 互证 value 端无法命中)"]
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
- **recommended_values**: ["(NULL · 原文无参数名 AND 推荐值的双命中组合，「单独设定一个物理卷」是定性目标无可结构化 value)"]
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

## check_id: chk-wiredtiger-modified-evictions-nvme

- **type**: parameter-current-value
- **param_name**: WiredTiger 高脏页率 + 高 modified evictions 场景应换用 NVMe 替代机械盘
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

## check_id: chk-bios-smmu-io

- **type**: parameter-current-value
- **param_name**: 鲲鹏平台非虚拟化场景下 · 在 BIOS 中关闭 SMMU 以避免数据库 IO 开销
- **recommended_values**: ["Support Smmu = Disable"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["因为数据库通常会使用大量的内存和IO资源，而SMMU会增加额外的开销和延迟"]
- **standalone**: true
- **bp_source_ids**: ["kunpeng-bios-smmu-disable-non-virt-db-01"]
- **risk_severity**: warning
- **recommendation_layer**: bios-firmware
- **scope**: other
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0007.html

## check_id: chk-bios-cpu

- **type**: parameter-current-value
- **param_name**: 鲲鹏平台数据库场景 · 在 BIOS 中关闭 CPU 硬件预取以避免无效缓存流量
- **recommended_values**: ["CPU Prefetching Configuration = Disabled"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["将“CPU Prefetching Configuration”设置为“Disabled”"]
- **standalone**: true
- **bp_source_ids**: ["kunpeng-bios-cpu-prefetch-disable-db-01"]
- **risk_severity**: warning
- **recommendation_layer**: bios-firmware
- **scope**: other
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0007.html

## check_id: chk-numa-irqbalance-32

- **type**: parameter-current-value
- **param_name**: 鲲鹏服务器手动绑定网卡中断到本地 NUMA · 关闭 irqbalance · 32 队列绑满获最佳网络性能
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

## check_id: chk-thp

- **type**: parameter-current-value
- **param_name**: 数据库场景下关闭透明大页(THP)以减少内存碎片与利用率下降
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

## check_id: chk-io-deadline-nvme

- **type**: parameter-current-value
- **param_name**: 数据库场景下 · 块设备 IO 调度器配置为 deadline(NVMe 除外)
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

## check_id: chk-nr-requests-2048

- **type**: parameter-current-value
- **param_name**: 数据库高并发写入场景下 · 块设备 nr_requests 调到 2048 提升磁盘吞吐
- **recommended_values**: ["/sys/block/${device}/queue/nr_requests = 2048"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["echo 2048 > /sys/block/${device}/queue/nr_requests"]
- **standalone**: true
- **bp_source_ids**: ["os-blockdev-nr-requests-too-low-disk-throughput-01"]
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

## check_id: chk-mongodb-maxincomingconnections-raise-above-default-64k-for-h

- **type**: parameter-current-value
- **param_name**: MongoDB maxIncomingConnections: raise above default 64k for high-connection deployments
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

## check_id: chk-linux-ulimit-nofile-raise-open-file-descriptor-limit-for-hig

- **type**: parameter-current-value
- **param_name**: Linux ulimit nofile: raise open-file descriptor limit for high-connection MongoDB servers
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

## check_id: chk-linux-ulimit-nproc-raise-thread-count-limit-for-high-connect

- **type**: parameter-current-value
- **param_name**: Linux ulimit nproc: raise thread count limit for high-connection MongoDB deployments
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

## check_id: chk-linux-ulimit-stack-raise-per-thread-stack-size-limit-for-hig

- **type**: parameter-current-value
- **param_name**: Linux ulimit stack: raise per-thread stack size limit for high-connection MongoDB deployments
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

## check_id: chk-vm-max-map-count-raise-kernel-mmap-limit-when-running-many-t

- **type**: parameter-current-value
- **param_name**: vm.max_map_count: raise kernel mmap limit when running many threads (MongoDB high-connection)
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

## check_id: chk-net-ipv4-ip-local-port-range-expand-ephemeral-port-range-on-

- **type**: parameter-current-value
- **param_name**: net.ipv4.ip_local_port_range: expand ephemeral port range on benchmark/client hosts
- **recommended_values**: ["net.ipv4.ip_local_port_range = 1024 65530"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["echo \"net.ipv4.ip_local_port_range = 1024 65530\" | sudo tee -a /etc/sysctl.conf"]
- **standalone**: true
- **bp_source_ids**: ["os-net-ip-local-port-range-client-01"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.mongodb.com/company/blog/technical/tuning-mongodb--linux-to-allow-for-tens-of-thousands-connections

## check_id: chk-3-voting-w-majority

- **type**: parameter-current-value
- **param_name**: 副本集部署需 ≥3 个数据承载 voting 成员 + 写操作走 w:majority · 否则数据耐久性无法满足
- **recommended_values**: ["replica set ≥ 3 data-bearing voting members + write concern w: majority"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Ensure that your replica set includes at least three data-bearing voting members\n\n紧邻同段补强:\n w: majority write concern"]
- **standalone**: true
- **bp_source_ids**: ["mongo-replica-set-data-durability-three-voting-majority-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-development/

## check_id: chk-7-arbiter

- **type**: parameter-current-value
- **param_name**: 副本集投票成员需为奇数(最多 7 个)· 偶数时用 arbiter 凑奇数 · 否则选举平票卡死
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

## check_id: chk-driver-110-115

- **type**: parameter-current-value
- **param_name**: driver 连接池大小起点应为应用层"典型并发请求数 × 110-115%" · 池太小将请求排队
- **recommended_values**: ["connection pool size = 110-115% × typical concurrent database requests"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Adjust the connection pool size to suit your use case, beginning at 110-115% of the typical number of concurrent database requests"]
- **standalone**: true
- **bp_source_ids**: ["mongo-driver-connection-pool-size-110-115pct-concurrent-03"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: app-query-layer
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-development/

## check_id: chk-dbpath-nfs-vmware

- **type**: parameter-current-value
- **param_name**: dbPath 不要用 NFS · 用本地 / VMware 虚拟盘
- **recommended_values**: ["dbPath ∉ NFS · 用本地块设备 / VMware 虚拟盘"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Using NFS drives can result in degraded and unstable performance."]
- **standalone**: true
- **bp_source_ids**: ["linux-fs-avoid-nfs-for-dbpath-checklist-01"]
- **risk_severity**: warning
- **recommendation_layer**: linux-mount-option
- **scope**: linux-fs
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/

## check_id: chk-wiredtiger-xfs-ext4

- **type**: parameter-current-value
- **param_name**: WiredTiger 数据盘强烈建议用 XFS · 不用 EXT4
- **recommended_values**: ["XFS for WT data drive (avoid EXT4 with WT)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["use of XFS is strongly recommended to avoid performance issues found when using EXT4 with WiredTiger."]
- **standalone**: true
- **bp_source_ids**: ["linux-fs-xfs-strongly-recommended-for-wt-checklist-02"]
- **risk_severity**: warning
- **recommendation_layer**: linux-mount-option
- **scope**: linux-fs
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/

## check_id: chk-rhel-centos-tuned-tuned-profile

- **type**: parameter-current-value
- **param_name**: RHEL / CentOS 上用 tuned 时必须自定义 tuned profile
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

## check_id: chk-san

- **type**: parameter-current-value
- **param_name**: 副本集成员不要全放同一 SAN · 避免单点故障
- **recommended_values**: ["replica set members spread across ≥2 SANs (or mix SAN + local disk)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Avoid placing all replica set members on the same SAN, as the SAN can be a single point of failure."]
- **standalone**: true
- **bp_source_ids**: ["linux-block-avoid-replica-set-members-same-san-checklist-05"]
- **risk_severity**: critical
- **recommendation_layer**: other
- **scope**: linux-block
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/

## check_id: chk-lb-mongod-tcp-keepalive-time-120

- **type**: parameter-current-value
- **param_name**: 云 LB 后部署 mongod 时 · tcp_keepalive_time 设为 120 秒以避免静默断连
- **recommended_values**: ["net.ipv4.tcp_keepalive_time = 120"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["there is a risk that the system might silently drop connections."]
- **standalone**: true
- **bp_source_ids**: ["os-net-tcp-keepalive-time-cloud-lb-120s-01"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-net
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

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

## check_id: chk-nfs-etc-fstab-bg-hard-nolock-noatime-nointr

- **type**: parameter-current-value
- **param_name**: 必须用 NFS 时 · /etc/fstab 加 bg / hard / nolock / noatime / nointr 选项
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

## check_id: chk-mongod-vm-swappiness-1-0-60

- **type**: parameter-current-value
- **param_name**: mongod 主机 vm.swappiness 设为 1 或 0(默认 60 太激进)
- **recommended_values**: ["vm.swappiness ∈ {0, 1}`(同机有 webserver 用 1 / dedicated 可用 0)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["MongoDB performs best where swapping can be avoided or kept to a minimum, as retrieving data from swap will always be slower than accessing data in RAM."]
- **standalone**: true
- **bp_source_ids**: ["linux-mm-vm-swappiness-1-or-0-mongo-host-05"]
- **risk_severity**: warning
- **recommendation_layer**: os-sysctl
- **scope**: linux-mm
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-numa-mongod-numactl-interleave-all

- **type**: parameter-current-value
- **param_name**: NUMA 主机上 mongod 必须经 numactl --interleave=all 启动
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

## check_id: chk-numa-vm-zone-reclaim-mode-0-numactl

- **type**: parameter-current-value
- **param_name**: NUMA 主机上 vm.zone_reclaim_mode 必须设为 0 · 与 numactl 配套
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

## check_id: chk-vm-hypervisor-i-o-scheduler-none

- **type**: parameter-current-value
- **param_name**: VM / 云主机 + hypervisor 块设备 · I/O scheduler 用 none
- **recommended_values**: ["I/O scheduler = none"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The none scheduler allows the operating system to defer I/O scheduling to the underlying hypervisor."]
- **standalone**: true
- **bp_source_ids**: ["linux-sched-none-for-vm-cloud-09"]
- **risk_severity**: info
- **recommendation_layer**: os-sysctl
- **scope**: linux-sched
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-i-o-scheduler-mq-deadline

- **type**: parameter-current-value
- **param_name**: 物理服务器 + 转盘 · I/O scheduler 用 mq-deadline
- **recommended_values**: ["I/O scheduler = mq-deadline"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The mq-deadline scheduler caps maximum latency per request and maintains a good disk throughput that is best for disk-intensive database applications."]
- **standalone**: true
- **bp_source_ids**: ["linux-sched-mq-deadline-for-spinning-disk-10"]
- **risk_severity**: info
- **recommendation_layer**: os-sysctl
- **scope**: linux-sched
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-vm-i-o-scheduler-kyber-kernel-4-12

- **type**: parameter-current-value
- **param_name**: 同 VM / 自建机房多负载混跑 · I/O scheduler 用 kyber(kernel 4.12+)
- **recommended_values**: ["I/O scheduler = kyber`(需 Linux kernel 4.12+)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["use the kyber scheduler.\n\n并紧邻给出版本前提:\n The kyber scheduler is only available on Linux kernels starting in version 4.12."]
- **standalone**: true
- **bp_source_ids**: ["linux-sched-kyber-for-multi-workload-11"]
- **risk_severity**: info
- **recommendation_layer**: os-sysctl
- **scope**: linux-sched
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-wiredtiger-readahead-8-32-sectors

- **type**: parameter-current-value
- **param_name**: WiredTiger 引擎 · readahead 设 8~32 (sectors) · 不要更高
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

## check_id: chk-kvm-mongod-balloon-driver

- **type**: parameter-current-value
- **param_name**: KVM 上跑 mongod · 为虚机预留全部内存 · 不禁用 balloon driver
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

## check_id: chk-db-connecttimeoutms

- **type**: parameter-current-value
- **param_name**: 应用侧操作慢但 DB 侧未见对应 · 设 connectTimeoutMS 防止驱动连接阶段无限等待
- **recommended_values**: ["connectTimeoutMS > longest network latency to any replica set member"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["if a member has a latency of 10000 milliseconds, setting connectTimeoutMS to 5000 (milliseconds) prevents the driver from connecting to that member"]
- **standalone**: true
- **bp_source_ids**: ["bp-mongo-pool-connecttimeoutms-network-latency-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: app-query-layer
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/

## check_id: chk-socket-sockettimeoutms-op-2-3-socket

- **type**: parameter-current-value
- **param_name**: 防火墙半关闭 socket · 设 socketTimeoutMS 为最慢 op 时长的 2~3 倍以确保 socket 总能释放
- **recommended_values**: ["socketTimeoutMS = 2~3 × longest legitimate operation duration"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["socketTimeoutMS to ensure that sockets are always closed"]
- **standalone**: true
- **bp_source_ids**: ["bp-mongo-pool-sockettimeoutms-firewall-half-close-02"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: app-query-layer
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/

## check_id: chk-minpoolsize-2

- **type**: parameter-current-value
- **param_name**: 应用启动时连接创建占用过多时间 · 设 minPoolSize 预热池子
- **recommended_values**: ["minPoolSize = number of connections required at startup"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The MongoClient instance ensures that number of connections exists at all times"]
- **standalone**: true
- **bp_source_ids**: ["bp-mongo-pool-minpoolsize-startup-warmup-03"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: app-query-layer
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/

## check_id: chk-op-sockettimeoutms-maxtimems

- **type**: parameter-current-value
- **param_name**: 想取消服务端长 op 时不要用 socketTimeoutMS · 改用 maxTimeMS() 让服务端真正取消
- **recommended_values**: ["use maxTimeMS() instead of small socketTimeoutMS for server-side op cancellation"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["use maxTimeMS() with queries so that the server can cancel long-running operations"]
- **standalone**: true
- **bp_source_ids**: ["bp-mongo-pool-sockettimeoutms-not-for-server-cancel-use-maxtimems-06"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: app-query-layer
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/

## check_id: chk-enable-mongodb-network-compression-to-reduce-client-server-b

- **type**: parameter-current-value
- **param_name**: Enable MongoDB network compression to reduce client-server bandwidth
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

## check_id: chk-rhel-centos-7-mongodb-tuned-percona-mongodb-profile-linux

- **type**: parameter-current-value
- **param_name**: RHEL/CentOS 7+ 运行 MongoDB · 使用 tuned-percona-mongodb profile 一键自动化应用所有 Linux 调参
- **recommended_values**: ["sudo make enable"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["performance-focused tuned profile for MongoDB on Linux"]
- **standalone**: true
- **bp_source_ids**: ["os-tuned-percona-mongodb-profile-rhel-centos-automated-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: other
- **source_url**: https://www.percona.com/blog/tuning-linux-for-mongodb-automated-tuning-redhat-and-centos/

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

## check_id: chk-serviceexecutor-adaptive-io

- **type**: parameter-current-value
- **param_name**: 高并发场景启用 serviceExecutor adaptive 实现网络 IO 复用
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

## check_id: chk-eviction-dirty-target-trigger

- **type**: parameter-current-value
- **param_name**: 高写入负载下调低 eviction_dirty_target/trigger 让后台线程尽早淘汰脏页
- **recommended_values**: ["eviction_dirty_target=3%,eviction_dirty_trigger=25%"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["总体思想是让后台evict尽量早点淘汰脏页page到磁盘，同时调整evict淘汰线程数来加快脏数据淘汰，调整后mongostat及客户端超时现象进一步缓解。"]
- **standalone**: true
- **bp_source_ids**: ["mongo-wt-eviction-dirty-target-3pct-high-write-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://cloud.tencent.com/developer/news/710321

## check_id: chk-checkpoint-wait-25s-io

- **type**: parameter-current-value
- **param_name**: 高写入负载下缩短 checkpoint wait 周期至 25s 均摊 IO
- **recommended_values**: ["checkpoint=(wait=25,log_size=1GB)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["如果我们把checkpoint的周期缩短，那么两个checkpoint期间的脏数据相应的也就会减少，磁盘IO 100%持续的时间也就会缩短。"]
- **standalone**: true
- **bp_source_ids**: ["mongo-wt-checkpoint-wait-25s-io-smoothing-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://cloud.tencent.com/developer/news/710321

## check_id: chk-ttl-delete

- **type**: parameter-current-value
- **param_name**: 高写入集群将 TTL 过期删除窗口移至夜间低峰期规避白天 delete 高峰
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

## check_id: chk-index-build-workload

- **type**: parameter-current-value
- **param_name**: 对不能容忍 index build 期间性能下降的 workload 启用滚动方式构建索引
- **recommended_values**: ["index build mode = rolling"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Building an index in a rolling fashion reduces the resiliency of your cluster and increases index build times"]
- **standalone**: true
- **bp_source_ids**: ["mongo-atlas-rolling-index-build-non-tolerant-workloads-01"]
- **risk_severity**: warning
- **recommendation_layer**: other
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/atlas/performance-advisor/

## check_id: chk-wiredtiger-commitintervalms-increase-to-200-300ms-for-higher

- **type**: parameter-current-value
- **param_name**: WiredTiger commitIntervalMs: increase to 200-300ms for higher write throughput
- **recommended_values**: ["storage.journal.commitIntervalMs = 200"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **standalone**: true
- **bp_source_ids**: ["wt-journal-commit-interval-high-throughput-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-wiredtiger-journal-enabled-disable-for-temporary-non-critica

- **type**: parameter-current-value
- **param_name**: WiredTiger journal.enabled: disable for temporary/non-critical data to maximize write speed
- **recommended_values**: ["storage.journal.enabled = false"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **standalone**: true
- **bp_source_ids**: ["wt-journal-disable-non-critical-max-write-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-wiredtiger-blockcompressor-set-to-none-for-maximum-write-spe

- **type**: parameter-current-value
- **param_name**: WiredTiger blockCompressor: set to none for maximum write speed (no compression overhead)
- **recommended_values**: ["storage.wiredTiger.collectionConfig.blockCompressor = none"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **standalone**: true
- **bp_source_ids**: ["wt-block-compressor-none-max-write-speed-01"]
- **risk_severity**: info
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-storage-directoryperdb-enable-when-using-separate-storage-vo

- **type**: parameter-current-value
- **param_name**: storage.directoryPerDB: enable when using separate storage volumes for each database
- **recommended_values**: ["storage.directoryPerDB = true"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **standalone**: true
- **bp_source_ids**: ["wt-directory-per-db-separate-volumes-01"]
- **risk_severity**: info
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://dev.to/devaaai/complete-configuration-guide-for-maximum-read-and-write-performance-2bm6

## check_id: chk-oplogsizemb-oplog

- **type**: parameter-current-value
- **param_name**: oplogSizeMB 在高更新频率工作负载下调大——避免 oplog 空洞和从节点延迟
- **recommended_values**: ["replication.oplogSizeMB >= 1小时以上的oplog记录量"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["(NULL · 原文无纯因果机制句，最接近机制候选「参数设置过小，可能会导致从节点跟不上...」含「设置」触发 lint prescription_in_rationale，依 §4.4 NULL 优先原则置 NULL)"]
- **standalone**: true
- **bp_source_ids**: ["mongo-oplog-size-high-write-update-workload-03"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: app-other
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-cursortimeoutmillis

- **type**: parameter-current-value
- **param_name**: cursorTimeoutMillis 调小降低空闲游标资源开销
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

## check_id: chk-transactionlifetimelimitseconds-wiredtiger

- **type**: parameter-current-value
- **param_name**: transactionLifetimeLimitSeconds 调小防长事务压垮 WiredTiger 缓存
- **recommended_values**: ["setParameter.transactionLifetimeLimitSeconds = 30"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["(NULL · 原文最接近机制句「未提交的长事务可能会给WiredTiger存储引擎的缓存带来很大压力...」含「使用」命中 RE_ACTION_VERB_BP 而无机制连接词，依 §4.4 NULL 优先原则置 NULL)"]
- **standalone**: true
- **bp_source_ids**: ["mongo-transaction-lifetime-long-wt-cache-pressure-05"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-setparam
- **scope**: storage-engine-wt
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-blockcompressor-zstd

- **type**: parameter-current-value
- **param_name**: 冷数据存储场景将 blockCompressor 改为 zstd 提升压缩比
- **recommended_values**: ["storage.wiredTiger.collectionConfig.blockCompressor = zstd"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["不同的压缩算法有着不同的表现，有的压缩率更高但压缩和解压时的CPU开销更大"]
- **standalone**: true
- **bp_source_ids**: ["mongo-wt-block-compressor-cold-data-zstd-06"]
- **risk_severity**: info
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-tcmallocaggressivememorydecommit-oom

- **type**: parameter-current-value
- **param_name**: tcmallocAggressiveMemoryDecommit 在内存 OOM/碎片场景启用加速内存回收
- **recommended_values**: ["setParameter.tcmallocAggressiveMemoryDecommit = 1"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["(NULL · 原文最接近机制句「此参数用于控制是否开启TCMalloc的激进回收策略。开启后，MongoDB会主动尝试合并相邻的空闲内存块并归还一部分内存给操作系统」含「使用」命中 RE_ACTION_VERB_BP 而无机制连接词，依 §4.4 NULL 优先原则置 NULL)"]
- **standalone**: true
- **bp_source_ids**: ["mongo-tcmalloc-aggressive-decommit-oom-fragment-07"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-setparam
- **scope**: app-other
- **source_url**: https://help.aliyun.com/zh/mongodb/user-guide/parameter-tuning-recommendations

## check_id: chk-minsnapshothistorywindowinseconds-0-wt

- **type**: parameter-current-value
- **param_name**: 不使用历史快照读时将 minSnapshotHistoryWindowInSeconds 调小到 0 释放 WT 缓存压力
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

## check_id: chk-wiredtiger-tickets-10-setparameter

- **type**: parameter-current-value
- **param_name**: WiredTiger 并发读写 tickets 持续低于 10 时应用 setParameter 增加上限
- **recommended_values**: ["wiredTigerConcurrentReadTransactions = 256"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["WiredTiger uses a ticket system to limit concurrent operations. By default, 128 read tickets and 128 write tickets are available.\n\n(原文未给显式 because/since 机制句；rationale_quote 为背景说明句，含机制描述但缺因果连词)"]
- **standalone**: true
- **bp_source_ids**: ["wt-concurrent-tickets-low-increase-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-setparam
- **scope**: storage-engine-wt
- **source_url**: https://oneuptime.com/blog/post/2026-03-31-mongodb-wiredtiger-storage-engine/view

## check_id: chk-wiredtiger-max-50-ram-1gb-0-256gb

- **type**: parameter-current-value
- **param_name**: WiredTiger 内部缓存默认值 = max(50% × (RAM - 1GB), 0.256GB) · 不应擅自调高
- **recommended_values**: ["wiredTigerCacheSizeGB = max(0.5 × (RAM - 1GB), 0.256GB)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The storage.wiredTiger.engineConfig.cacheSizeGB limits the size of the WiredTiger internal cache. The operating system uses the available free memory for filesystem cache, which allows the compressed "]
- **standalone**: true
- **bp_source_ids**: ["wt-cache-size-default-half-ram-minus-1g-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-wiredtiger-snappy

- **type**: parameter-current-value
- **param_name**: WiredTiger 集合默认采用 Snappy 块压缩 · 索引默认前缀压缩
- **recommended_values**: ["storage.wiredTiger.collectionConfig.blockCompressor = snappy"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Provides a lower compression rate than zlib or zstd but has a lower CPU cost than either."]
- **standalone**: true
- **bp_source_ids**: ["wt-compression-snappy-default-block-collections-03"]
- **risk_severity**: info
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/

## check_id: chk-encrypted-storage-engine-aes-ni-cpu

- **type**: parameter-current-value
- **param_name**: 使用 Encrypted Storage Engine 时 · 选支持 AES-NI 指令集的 CPU
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

## check_id: chk-lxc-cgroups-docker-mongod-wiredtigercachesizegb-wiredtigerca

- **type**: parameter-current-value
- **param_name**: 容器(lxc / cgroups / Docker)部署 mongod 时必须显式设 wiredTigerCacheSizeGB 或 wiredTigerCacheSizePct
- **recommended_values**: ["--wiredTigerCacheSizeGB or --wiredTigerCacheSizePct < amount of RAM available in the container"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["as WiredTiger may not account for the memory limits of the specific container in certain cases"]
- **standalone**: true
- **bp_source_ids**: ["wt-cache-size-container-cgroup-explicit-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-cli-flag
- **scope**: storage-engine-wt
- **source_url**: https://www.mongodb.com/docs/manual/core/wiredtiger/

## check_id: chk-mongod-wiredtiger

- **type**: parameter-current-value
- **param_name**: 单机多 mongod 实例时须按实例数缩减每个实例的 WiredTiger 缓存配置
- **recommended_values**: ["storage.wiredTiger.engineConfig.cacheSizeGB decrease to accommodate"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["The default WiredTiger internal cache size value assumes that there is a single mongod instance per machine."]
- **standalone**: true
- **bp_source_ids**: ["wt-cache-size-multi-instance-decrease-01"]
- **risk_severity**: critical
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-wt
- **source_url**: https://www.mongodb.com/docs/manual/reference/configuration-options/

## check_id: chk-storage-syncperiodsecs-0-60

- **type**: parameter-current-value
- **param_name**: 生产环境禁止将 storage.syncPeriodSecs 设为 0 · 保持默认值 60
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
- **param_name**: 生产环境禁用 systemLog.quiet 模式 · 保留完整日志输出
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

## check_id: chk-systemlog-destination-file-syslog

- **type**: parameter-current-value
- **param_name**: 生产环境 systemLog.destination 应设为 file 而非 syslog · 避免时间戳误导
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

## check_id: chk-linux-logrotate-systemlog-logrotate-reopen

- **type**: parameter-current-value
- **param_name**: 使用 Linux logrotate 工具时须将 systemLog.logRotate 设为 reopen 以避免日志丢失
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

## check_id: chk-bson-json

- **type**: parameter-current-value
- **param_name**: 审计日志落文件时使用 BSON 格式而非 JSON · 降低性能开销
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

## check_id: chk-kmip-localauditkeyfile

- **type**: parameter-current-value
- **param_name**: 审计日志加密密钥生产环境必须使用外部 KMIP 服务 · 禁止使用 localAuditKeyFile
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

## check_id: chk-mongos-maxincomingconnections

- **type**: parameter-current-value
- **param_name**: mongos 部署中客户端连接泄漏时须显式设置 maxIncomingConnections 防止分片连接风暴
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

## check_id: chk-profiler-diagnostic-log-slowms

- **type**: parameter-current-value
- **param_name**: profiler / diagnostic log slowms 阈值应设为业务可接受的最高值 · 避免性能退化
- **recommended_values**: ["slowms = highest-useful-value`(业务可接受的最大慢查询阈值 · 默认 100ms 仅在低 QPS/SLA 紧张时合理 · 高吞吐场景应调大至 200/500ms 等)"]
- **violation_patterns**: []
- **linked_case_ids**: []
- **rationales**: ["Set it to the highest useful value to avoid performance degradation."]
- **standalone**: true
- **bp_source_ids**: ["mongo-profiler-slowms-highest-useful-value-01"]
- **risk_severity**: warning
- **recommendation_layer**: mongodb-config
- **scope**: storage-engine-other
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/manage-the-database-profiler/

## check_id: chk-database-profiler-atlas-query-profiler-performance-advisor-q

- **type**: parameter-current-value
- **param_name**: 启用 database profiler 前优先考虑 Atlas Query Profiler / Performance Advisor / $queryStats 等替代方案 · profiler 可能 degrade 性能
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
