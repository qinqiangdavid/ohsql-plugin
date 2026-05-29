<!-- ============ Diagnostic-Flow (_common, 25 cases) ============ -->

## case_id: kunpeng-nohz-clock-tick-overhead-03

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 周期时钟中断浪费 CPU 资源(nohz 未启用)
- **source_heading**: 1.3.3 定时器机制调整,减少不必要的时钟中断
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://www.cnblogs.com/huaweicloud/p/11861191.html
- **source_url_lang**: zh-cn

### symptom_description

> 在Linux内核2.6.17版本之前,Linux内核为每个CPU设置一个周期性的时钟中断,Linux内核利用这个中断处理一些定时任务,如线程调度等。这样导致就算CPU不需要定时器的时候,也会有很多时钟中断,导致资源的浪费。

### diagnostic_steps

```
[step 1] 看内核启动参数是否含 nohz=off
  metric_name: /proc/cmdline 中是否含 `nohz=off`
  collection_layer: os
  collection_method_quote: "执行cat /proc/cmdline查看Linux 内核的启动参数,如果有nohz=off关键字,说明nohz机制被关闭,需要打开。"
  abnormal_pattern_quote: "如果有nohz=off关键字,说明nohz机制被关闭"
  abnormal_pattern_threshold: `nohz=off` 出现在 /proc/cmdline
  metric_unit: bool
  prerequisite_steps: []

[step 2] 用 perf sched 观察 timer_tick 调度次数
  metric_name: timer_tick 调度次数(单位时间内)
  collection_layer: os
  collection_method_quote: "perf sched record -- sleep 1 -p $PID" 配 "perf sched latency -s max"
  abnormal_pattern_quote: "输出信息中有如下信息,其中591字段表示统计时间内的调度次数,数字变小说明修改生效。"
  abnormal_pattern_threshold: 修改前后调度次数显著未减小
  metric_unit: count
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] kernel boot cmdline `nohz=off`
  param_name: kernel boot cmdline `nohz=off`
  abnormal_value_pattern: 显式设了 nohz=off · 或某些 OS 默认 off(原文示例 Euler:nohz=off)
  reasoning_quote: "在Linux内核2.6.17版本之前,Linux内核为每个CPU设置一个周期性的时钟中断"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-tlb-miss-page-size-04

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 4K 页大小导致 TLB 命中率低
- **source_heading**: 1.3.4 调整内存页的大小为64K,提升TLB命中率
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.cnblogs.com/huaweicloud/p/11861191.html
- **source_url_lang**: zh-cn

### symptom_description

> TLB（Translation lookaside buffer）为页表（存放虚拟地址的页地址和物理地址的页地址的映射关系）在CPU内部的高速缓存。TLB的命中率越高,页表查询性能就越好。

### diagnostic_steps

```
[step 1] perf stat 看 TLB 命中率
  metric_name: dTLB-load-misses 比率 / iTLB-load-misses 比率
  collection_layer: os
  collection_method_quote: "perf stat -p $PID -d -d -d"
  abnormal_pattern_quote: "其中1.21%和0.59%分别表示数据的miss率和指令的miss率。"
  abnormal_pattern_threshold: dTLB miss > 1% / iTLB miss > 0.5%(原文示例值,可作经验阈值)
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] Linux kernel `Page size` 编译选项
  param_name: Linux kernel `Page size` 编译选项
  abnormal_value_pattern: 4K(默认)
  reasoning_quote: "TLB管理的内存大小 = TLB行数 x 内存的页大小"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-thread-concurrency-overload-05

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 线程并发数超过最佳点导致性能下降
- **source_heading**: 1.3.5 调整线程并发数
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.cnblogs.com/huaweicloud/p/11861191.html
- **source_url_lang**: zh-cn

### symptom_description

> 程序从单线程变为多线程时,CPU和内存资源得到充分利用,性能得到提升。但是系统的性能并不会随着线程数的增长而线性提升,因为随着线程数量的增加,线程之间的调度、上下文切换、关键资源和锁的竞争也会带来很大开销。

### diagnostic_steps

```
[step 1] 不同并发数下做 TPS 测试,找性能拐点
  metric_name: TPS / 业务吞吐 vs 线程并发数
  collection_layer: os
  collection_method_quote: "下面数据为某业务场景下,不同并发线程数下的TPS,可以看到并发线程数达到128后,性能达到高峰,随后开始下降。"
  abnormal_pattern_quote: "我们需要针对不同的业务模型和使用场景做多组测试,找到适合本业务场景的最佳并发线程数。"
  abnormal_pattern_threshold: 增加并发后 TPS 反降 → 已过拐点
  metric_unit: TPS
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] MySQL `innodb_thread_concurrency` / Nginx `worker_processes` / 其他应用并发设置
  param_name: MySQL `innodb_thread_concurrency` / Nginx `worker_processes` / 其他应用并发设置
  abnormal_value_pattern: 设置过大,超过最佳并发拐点
  reasoning_quote: "MySql可以通过innodb_thread_concurrency设置工作线程的最大并发数。" 与 "Nginx可以通过worker_processes参数设置并发的进程个数。"
  linked_diagnostic_step_no: 1

```

## case_id: mongo-fs-mount-noatime-nobarrier-missing-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: disk-io-saturation
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: XFS mount 未加 noatime/nobarrier 导致文件系统冗余开销
- **source_heading**: 文件系统调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0006.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常情况下，我们对文件的操作更多是读取而不是写入，而且我们很少需要关注一个文件最近被访问的时间。因此，我们建议使用noatime选项，这样文件系统在程序访问文件或文件夹时，不会更新对应的访问时间。文件系统不再记录访问时间，可以避免不必要的资源浪费。

### diagnostic_steps

```
[step 1] 读取数据盘当前 mount 选项
  metric_name: mount.options
  collection_layer: os
  collection_method_quote: (NULL · 原文未给读取命令)
  abnormal_pattern_quote: "建议在文件系统的mount参数上加上noatime、nobarrier两个选项，其中数据盘以及数据目录以实际为准。"
  abnormal_pattern_threshold: `mount options does NOT contain "noatime" OR does NOT contain "nobarrier" (XFS only)`
  metric_unit: flag
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] mount.options.noatime
  param_name: mount.options.noatime
  abnormal_value_pattern: `noatime not in mount options`
  reasoning_quote: "通常情况下，我们对文件的操作更多是读取而不是写入，而且我们很少需要关注一个文件最近被访问的时间。因此，我们建议使用noatime选项，这样文件系统在程序访问文件或文件夹时，不会更新对应的访问时间。文件系统不再记录访问时间，可以避免不必要的资源浪费。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] mount.options.nobarrier
  param_name: mount.options.nobarrier
  abnormal_value_pattern: `nobarrier not in mount options (XFS only) AND storage backend has battery-backed cache (RAID/Flash)`
  reasoning_quote: "在这种情况下，我们可以安全地使用nobarrier挂载文件系统，以避免write barriers的性能损失。对于ext3、ext4和reiserfs文件系统可以在mount时指定barrier=0。对于XFS可以指定nobarrier选项。"
  linked_diagnostic_step_no: 1

```

## case_id: mongo-os-tcp-stack-tuning-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: network-latency
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: OS 层 TCP 协议栈参数审计 (7 条 sysctl)
- **source_heading**: 网络参数调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 7
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0010.html
- **source_url_lang**: zh-cn

### symptom_description

> 对于不同的操作系统，通过在OS层面调整网络参数的配置，可以有效提升服务器性能。

### diagnostic_steps

```
[step 1] 读取 7 个 TCP 协议栈参数当前值
  metric_name: sysctl.net.* (7 keys)
  collection_layer: os
  collection_method_quote: (NULL · 原文只给 echo 写命令未给 sysctl 读命令)
  abnormal_pattern_quote: "tcp_max_syn_backlog是指定所能接收SYN同步包的最大客户端数量。"
  abnormal_pattern_threshold: `current value < recommended value (per-key)`
  metric_unit: mixed (count / bytes / triple)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] net.ipv4.tcp_max_syn_backlog
  param_name: net.ipv4.tcp_max_syn_backlog
  abnormal_value_pattern: `current = 2048 (default) < 8192 (recommended)`
  reasoning_quote: "tcp_max_syn_backlog是指定所能接收SYN同步包的最大客户端数量。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] net.core.somaxconn
  param_name: net.core.somaxconn
  abnormal_value_pattern: `current = 128 (default) < 1024 (recommended)`
  reasoning_quote: "服务端所能accept即处理数据的最大客户端数量，即完成连接上限。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] net.core.rmem_max
  param_name: net.core.rmem_max
  abnormal_value_pattern: `current = 229376 (default) < 16777216 (recommended)`
  reasoning_quote: "接收套接字缓冲区大小的最大值。单位为字节。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 4] net.core.wmem_max
  param_name: net.core.wmem_max
  abnormal_value_pattern: `current = 229376 (default) < 16777216 (recommended)`
  reasoning_quote: "发送套接字缓冲区大小的最大值。单位为字节。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 5] net.ipv4.tcp_rmem
  param_name: net.ipv4.tcp_rmem
  abnormal_value_pattern: `current = "4096 87380 6291456" (default) · 第三值 < 16777216 (recommended)`
  reasoning_quote: "配置读缓冲区的大小，共三个值，第一个是这个读缓冲区的最小值，第三个是最大值，中间的是默认值。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 6] net.ipv4.tcp_wmem
  param_name: net.ipv4.tcp_wmem
  abnormal_value_pattern: `current = "4096 16384 4194304" (default) · 第三值 < 16777216 (recommended)`
  reasoning_quote: "配置写缓冲区的大小，共三个值，第一个是这个写缓冲区的最小值，第三个是最大值，中间的是默认值。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 7] net.ipv4.tcp_max_tw_buckets
  param_name: net.ipv4.tcp_max_tw_buckets
  abnormal_value_pattern: `current = 262144 (default) < 360000 (recommended)`
  reasoning_quote: "表示系统同时保持TIME_WAIT套接字的最大数量。"
  linked_diagnostic_step_no: 1

```

## case_id: mongo-client-os-tcp-tuning-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: network-latency
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: MongoDB 客户端侧 OS 层 TCP 参数审计 (8 条 sysctl)
- **source_heading**: 客户端优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 8
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0031.html
- **source_url_lang**: zh-cn

### symptom_description

> 通过在OS层面调整一些参数配置，可以有效提升客户端网络性能。

### diagnostic_steps

```
[step 1] 读取 8 个 TCP 客户端参数当前值
  metric_name: sysctl.net.* (8 keys)
  collection_layer: os
  collection_method_quote: (NULL · 原文只给 vim 编辑 sysctl.conf 写法未给读命令)
  abnormal_pattern_quote: "允许将TIME-WAIT sockets重新用于新的TCP连接。"
  abnormal_pattern_threshold: `current value ≠ recommended value (per-key)`
  metric_unit: mixed (count / range / seconds)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] net.ipv4.ip_local_port_range
  param_name: net.ipv4.ip_local_port_range
  abnormal_value_pattern: `range narrower than "1024 65535"`
  reasoning_quote: "用于向外连接的端口范围。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] net.ipv4.tcp_tw_reuse
  param_name: net.ipv4.tcp_tw_reuse
  abnormal_value_pattern: `current = 0 (closed) ≠ 1 (recommended)`
  reasoning_quote: "允许将TIME-WAIT sockets重新用于新的TCP连接。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] net.core.somaxconn
  param_name: net.core.somaxconn
  abnormal_value_pattern: `current = 128 (default) < 65535 (recommended)`
  reasoning_quote: "定义了系统中每一个端口最大的监测队列的长度，这是个全局的参数，默认值为128。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 4] net.core.netdev_max_backlog
  param_name: net.core.netdev_max_backlog
  abnormal_value_pattern: `current < 8096 (recommended)`
  reasoning_quote: "每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 5] net.ipv4.tcp_max_syn_backlog
  param_name: net.ipv4.tcp_max_syn_backlog
  abnormal_value_pattern: `current = 1024 (default) < 8192 (recommended)`
  reasoning_quote: "表示那些尚未收到客户端确认信息的连接（SYN消息）队列的长度，默认为1024，加大队列长度为262144，可以容纳更多等待连接的网络连接数。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 6] net.ipv4.tcp_keepalive_time
  param_name: net.ipv4.tcp_keepalive_time
  abnormal_value_pattern: `current = 7200 (default 2h) ≠ 600 (recommended)`
  reasoning_quote: "表示如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间，默认为2小时。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 7] net.ipv4.tcp_fin_timeout
  param_name: net.ipv4.tcp_fin_timeout
  abnormal_value_pattern: `current = 0 (closed quick recycle) ≠ 30 (recommended)`
  reasoning_quote: "表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 8] net.ipv4.tcp_max_tw_buckets
  param_name: net.ipv4.tcp_max_tw_buckets
  abnormal_value_pattern: `current = 180000 (default) ≠ 3000 (recommended for client)`
  reasoning_quote: "表示系统同时保持TIME_WAIT sockets的最大数量，默认为180000。"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-bios-smmu-enabled-non-virt-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: disk-io-saturation
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: 鲲鹏 BIOS 中 SMMU 在非虚拟化场景未关闭(影响数据库 IO 性能)
- **source_heading**: BIOS调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0007.html
- **source_url_lang**: zh-cn

### symptom_description

> 因为数据库通常会使用大量的内存和IO资源，而SMMU会增加额外的开销和延迟，从而降低系统的性能。

### diagnostic_steps

```
[step 1] 读取 BIOS 中 Support Smmu 当前值
  metric_name: bios.advanced.misc_config.support_smmu
  collection_layer: bios-readout
  collection_method_quote: (NULL · 原文给的是"重启进入 BIOS 设置界面"操作流而非可脚本化读法)
  abnormal_pattern_quote: "将“Support Smmu”设置为“Disable”。"
  abnormal_pattern_threshold: `current = "Enable" ≠ "Disable" (in non-virtualization scenario)`
  metric_unit: enum (Enable/Disable)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] bios.advanced.misc_config.support_smmu
  param_name: bios.advanced.misc_config.support_smmu
  abnormal_value_pattern: `current = "Enable" AND scenario = non-virtualization`
  reasoning_quote: "因为数据库通常会使用大量的内存和IO资源，而SMMU会增加额外的开销和延迟，从而降低系统的性能。因此在数据库场景，开启SMMU并不能获得更好的性能。"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-bios-cpu-prefetch-enabled-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: cpu-high
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: 鲲鹏 BIOS 中硬件预取(CPU Prefetching)未关闭(影响数据库随机访问性能)
- **source_heading**: BIOS调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0007.html
- **source_url_lang**: zh-cn

### symptom_description

> 硬件预取是通过跟踪指令和数据地址的变化，将指令和地址提前读到Cache里，硬件预取对数据库场景的性能有影响，建议在BIOS中将预取功能关闭。

### diagnostic_steps

```
[step 1] 读取 BIOS 中 CPU Prefetching Configuration 当前值
  metric_name: bios.advanced.misc_config.cpu_prefetching_configuration
  collection_layer: bios-readout
  collection_method_quote: (NULL · 原文给的是"重启进入 BIOS 设置界面"操作流而非可脚本化读法)
  abnormal_pattern_quote: "将“CPU Prefetching Configuration”设置为“Disabled”，按“F10”键保存退出。"
  abnormal_pattern_threshold: `current = "Enabled" ≠ "Disabled"`
  metric_unit: enum (Enabled/Disabled)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] bios.advanced.misc_config.cpu_prefetching_configuration
  param_name: bios.advanced.misc_config.cpu_prefetching_configuration
  abnormal_value_pattern: `current = "Enabled" (default)`
  reasoning_quote: "硬件预取是通过跟踪指令和数据地址的变化，将指令和地址提前读到Cache里，硬件预取对数据库场景的性能有影响，建议在BIOS中将预取功能关闭。"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-net-irq-not-bound-irqbalance-on-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: network-latency
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: 鲲鹏服务器网卡中断未绑核(irqbalance 在线/中断分散到非本地 CPU)
- **source_heading**: 网卡中断绑核
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0013.html
- **source_url_lang**: zh-cn

### symptom_description

> 手动绑定网卡中断，根据网卡所属CPU将其进行分配，从而优化系统网络性能。

### diagnostic_steps

```
[step 1] 查看 irqbalance 服务当前状态
  metric_name: systemd.unit.irqbalance.service.active_state
  collection_layer: os
  collection_method_quote: "systemctl status irqbalance.service"
  abnormal_pattern_quote: "状态为inactive即为关闭。"
  abnormal_pattern_threshold: `active_state ≠ "inactive" (i.e. running)`
  metric_unit: enum (active/inactive)
  prerequisite_steps: []

[step 2] 查看网卡中断 smp_affinity 是否已绑定到本地 NUMA CPU
  metric_name: proc.interrupts.smp_affinity_list
  collection_layer: os
  collection_method_quote: (NULL · 原文给的是 mitigation 脚本中的 grep 片段而非独立读命令)
  abnormal_pattern_quote: "对于不同的硬件配置，用于绑中断的最佳CPU数目会有差异，比如对于鲲鹏920 5250处理器 + Huawei TM280 25G网卡（鲲鹏服务器的板载网卡）来说，最多可以绑定32个中断队列，建议将所有的队列都用在中断绑定上来获得最佳性能。"
  abnormal_pattern_threshold: `smp_affinity_list of NIC IRQs spans cores NOT on NIC's local NUMA node`
  metric_unit: cpu_id list
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] systemd.unit.irqbalance.service
  param_name: systemd.unit.irqbalance.service
  abnormal_value_pattern: `state = active (running)`
  reasoning_quote: "进行网卡中断绑核之前，需要先关闭irqbalance。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] proc.irq.<N>.smp_affinity_list
  param_name: proc.irq.<N>.smp_affinity_list
  abnormal_value_pattern: `smp_affinity_list NOT on NIC local NUMA cores`
  reasoning_quote: "手动绑定网卡中断，根据网卡所属CPU将其进行分配，从而优化系统网络性能。"
  linked_diagnostic_step_no: 2

```

## case_id: linux-blockdev-nr-requests-too-low-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: disk-io-saturation
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: 块设备 nr_requests 队列长度偏小(限制磁盘吞吐)
- **source_heading**: IO参数调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0018.html
- **source_url_lang**: zh-cn

### symptom_description

> 提升磁盘吞吐量，可以调整到更大。

### diagnostic_steps

```
[step 1] 读取 /sys/block/<device>/queue/nr_requests 当前值
  metric_name: blockdev.queue.nr_requests
  collection_layer: os
  collection_method_quote: (NULL · 原文给 echo 写命令未给 cat 读命令)
  abnormal_pattern_quote: "将指定设备的IO请求队列长度设置为“2048”。"
  abnormal_pattern_threshold: `current < 2048 (recommended)`
  metric_unit: int (request slots)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] /sys/block/${device}/queue/nr_requests
  param_name: /sys/block/${device}/queue/nr_requests
  abnormal_value_pattern: `current < 2048 (most distros default = 128/256)`
  reasoning_quote: "提升磁盘吞吐量，可以调整到更大。"
  linked_diagnostic_step_no: 1

```

## case_id: kvm-vcpupin-not-bound-numa-cross-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: cpu-high
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: KVM 虚拟机 vCPU 未绑核(跨 NUMA / 跨 DIE 切换)
- **source_heading**: 虚拟机绑核
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0019.html
- **source_url_lang**: zh-cn

### symptom_description

> 虚拟机绑核可以有效地减少操作系统的上下文切换和负载均衡的开销，从而提高程序的执行效率。

### diagnostic_steps

```
[step 1] 读取虚拟机 xml 当前 vcpupin/cputune 配置
  metric_name: libvirt.domain.cputune.vcpupin
  collection_layer: os
  collection_method_quote: (NULL · 原文给的是 `virsh edit vm1` 编辑写流程,未给独立读命令)
  abnormal_pattern_quote: "若不配置此参数，虚拟机任务线程会在CPU任意core上浮动，会存在更多的跨NUMA和跨DIE损耗。"
  abnormal_pattern_threshold: `xml does NOT contain <cputune><vcpupin .../></cputune> AND <vcpu placement='static' cpuset=...>`
  metric_unit: xml 节点
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] libvirt.domain.cputune.vcpupin
  param_name: libvirt.domain.cputune.vcpupin
  abnormal_value_pattern: `<vcpupin> 节点缺失`
  reasoning_quote: "vcpupin用于限制对CPU线程做虚拟机和物理机的一对一绑核。若不使用vcpupin绑CPU线程，则线程会在4～7这个4个核之间切换，造成额外开销。"
  linked_diagnostic_step_no: 1

```

## case_id: kvm-host-hugepages-not-allocated-tlb-miss-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: memory-pressure
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: KVM Host 未分配大页(虚拟机 TLB Miss / 内存访问密集业务下降)
- **source_heading**: 虚拟机使用内存大页
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/tngg/kunpengdbs_tuningguide_05_0021.html
- **source_url_lang**: zh-cn

### symptom_description

> 使用内存大页能保证虚拟机的所有内存在Host上始终以大页形式存在，并且保证物理连续，可以有效地减少TLB Miss，显著提升内存访问密集型业务的性能。

### diagnostic_steps

```
[step 1] 在 Host 侧查看各 NUMA 节点大页分配情况
  metric_name: sys.node.meminfo.hugepages
  collection_layer: os
  abnormal_pattern_quote: "如果HugePages显示信息为0，说明此时系统没有配置内存大页。"
  abnormal_pattern_threshold: `HugePages_Total = 0 on any NUMA node`
  metric_unit: count (pages per node)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] grub.linux.default_hugepagesz
  param_name: grub.linux.default_hugepagesz
  abnormal_value_pattern: `kernel cmdline NOT contain "default_hugepagesz" AND HugePages_Total = 0`
  reasoning_quote: "使用内存大页能保证虚拟机的所有内存在Host上始终以大页形式存在，并且保证物理连续，可以有效地减少TLB Miss，显著提升内存访问密集型业务的性能。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] libvirt.domain.memoryBacking.hugepages
  param_name: libvirt.domain.memoryBacking.hugepages
  abnormal_value_pattern: `domain xml does NOT contain <hugepages/>`
  reasoning_quote: "虚拟机配置大页内存。虚拟机xml文件的配置参考如下。"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-numa-cross-node-memory-access-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 跨 NUMA 节点访问内存导致应用性能下降
- **source_heading**: NUMA优化,减少跨NUMA访问内存
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0014.html
- **source_url_lang**: zh-cn

### symptom_description

> 不同NUMA内的CPU core访问同一个位置的内存,性能不同。内存访问延时从高到低为:跨CPU > 跨NUMA不跨CPU > NUMA内。

### diagnostic_steps

```
[step 1] 看进程当前的 NUMA 亲和绑定
  metric_name: 进程 NUMA 亲和绑定状态
  collection_layer: os
  collection_method_quote: 原文未直接给出**采集命令**,只给出**修改命令**(`numactl -C 28-31 ./test`)。诊断侧建议用 `numactl -H`(看节点拓扑)+ `numastat -p $PID`(看进程跨节点内存命中率)兜底,**该方法属于诊断常识推断,不是原文字面**(标 `inferred:true`)
  abnormal_pattern_quote: (原文未明示阈值)进程跨节点 numa_miss 计数显著大于 numa_hit
  abnormal_pattern_threshold: numa_miss / (numa_hit + numa_miss) > 0.1(经验值,非原文)
  metric_unit: ratio
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] (非操作系统参数,而是**应用启动方式**或**应用配置**)`numactl -C` / `sched_setaffinity` / 应用配置中的 worker_cpu_affinity
  param_name: (非操作系统参数,而是**应用启动方式**或**应用配置**)`numactl -C` / `sched_setaffinity` / 应用配置中的 worker_cpu_affinity
  abnormal_value_pattern: 默认不绑定核 → 调度器自由迁移线程 → 跨 NUMA 内存访问
  reasoning_quote: "在应用程序运行时要尽可能地避免跨NUMA访问内存,我们可以通过设置线程的CPU亲和性来实现。"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-network-irq-cross-numa-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: network-latency
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 网卡中断与网卡不在同一 NUMA 节点导致跨 NUMA 访问内存
- **source_heading**: 网络NUMA绑核
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0026.html
- **source_url_lang**: zh-cn

### symptom_description

> 在网卡开启多队列时，操作系统通过irqbalance服务来确定网卡队列中的网络数据包交由哪个CPU core处理，但是当处理中断的CPU core和网卡不在一个NUMA时，会触发跨NUMA访问内存。

### diagnostic_steps

```
[step 1] 查询网卡中断号 + 当前绑定 core
  metric_name: NIC IRQ → CPU core 绑定分布
  collection_layer: os
  abnormal_pattern_quote: "处理中断的CPU core和网卡不在一个NUMA时，会触发跨NUMA访问内存。"
  abnormal_pattern_threshold: (定性) IRQ 处理 core ∉ NIC NUMA node
  metric_unit: core id list
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] /proc/irq/$irq/smp_affinity_list
  param_name: /proc/irq/$irq/smp_affinity_list
  abnormal_value_pattern: 默认未显式绑定 → 继承 irqbalance 自由分发结果
  reasoning_quote: "我们可以将处理网卡中断的CPU core设置在网卡所在的NUMA上，从而减少跨NUMA的内存访问所带来的额外开销，提升网络处理性能。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "在网卡开启多队列时，操作系统通过irqbalance服务来确定网卡队列中的网络数据包交由哪个CPU core处理"
  linked_diagnostic_step_no: 1
  mitigation_quote: "# systemctl stop irqbalance.service"

```

## case_id: linux-nic-interrupt-coalescing-audit-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: network-latency
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: 网卡中断聚合参数（ethtool -C）未按业务调优
- **source_heading**: 中断聚合参数调整
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0027.html
- **source_url_lang**: zh-cn

### symptom_description

> 中断聚合特性允许网卡收到报文之后不立即产生中断，而是等待一小段时间有更多的报文到达之后再产生中断，这样就能让CPU一次中断处理多个报文，减少开销。

### diagnostic_steps

```
[step 1] 读取网卡当前中断聚合参数
  metric_name: NIC interrupt coalescing settings (rx/tx-usecs, rx/tx-frames, adaptive-rx/tx)
  collection_layer: os
  collection_method_quote: (NULL · 原文只给"调整命令"`ethtool -C`，未给"读取命令" `ethtool -c`，避免污染字段)
  abnormal_pattern_quote: "为了确保使用静态值，需禁用自适应调节，关闭Adaptive RX和Adaptive TX。"
  abnormal_pattern_threshold: (定性) Adaptive RX/TX = on ∧ 业务对延迟/吞吐有明确诉求
  metric_unit: usecs / frames
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] ethtool -C $eth adaptive-rx / adaptive-tx
  param_name: ethtool -C $eth adaptive-rx / adaptive-tx
  abnormal_value_pattern: adaptive-rx=on / adaptive-tx=on (默认)
  reasoning_quote: "为了确保使用静态值，需禁用自适应调节，关闭Adaptive RX和Adaptive TX。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] ethtool -C $eth rx-usecs / tx-usecs / rx-frames / tx-frames
  param_name: ethtool -C $eth rx-usecs / tx-usecs / rx-frames / tx-frames
  abnormal_value_pattern: N 取过大值
  reasoning_quote: "当增大聚合度时，单个数据包的延时会以微秒的级别增加。"
  linked_diagnostic_step_no: 1

```

## case_id: linux-rps-single-queue-nic-softirq-bottleneck-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: network-latency
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 单队列网卡软中断集中单 core 形成性能瓶颈（未启用 RPS）
- **source_heading**: 单队列网卡中断散列
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0030.html
- **source_url_lang**: zh-cn

### symptom_description

> 对单队列网卡可以使用RPS将中断分散到各个core处理，避免软中断集中到一个core导致该core软中断过高形成性能瓶颈。

### diagnostic_steps

```
[step 1] 读取 RPS 当前配置（rps_cpus / rps_flow_cnt / rps_sock_flow_entries）
  metric_name: RPS configuration (rps_cpus mask, flow tables)
  collection_layer: os
  collection_method_quote: "/sys/class/net/eth0/queues/rx-0/rps_cpus 0" + "/sys/class/net/eth0/queues/rx-0/rps_flow_cnt 0" + "/proc/sys/net/core/rps_sock_flow_entries 0"（原文以三行分别给出）
  abnormal_pattern_quote: "避免软中断集中到一个core导致该core软中断过高形成性能瓶颈。"
  abnormal_pattern_threshold: rps_cpus = 0（所有 bits 全 0 表示 RPS 未启用，软中断集中到默认 core）
  metric_unit: hex bitmask / count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] /sys/class/net/$nic/queues/rx-0/rps_cpus
  param_name: /sys/class/net/$nic/queues/rx-0/rps_cpus
  abnormal_value_pattern: 0（默认值，全 0 bitmask 表示未启用 RPS）
  reasoning_quote: "对单队列网卡可以使用RPS将中断分散到各个core处理"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] /sys/class/net/$nic/queues/rx-0/rps_flow_cnt + /proc/sys/net/core/rps_sock_flow_entries
  param_name: /sys/class/net/$nic/queues/rx-0/rps_flow_cnt + /proc/sys/net/core/rps_sock_flow_entries
  abnormal_value_pattern: 都为 0（默认）
  reasoning_quote: "将并发活动连接的最大预期数目设置为32768，因为这是Linux官方的内核推荐值。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] hardware-network
  cause_type: hardware-network
  description_quote: "RPS采用软件模拟的方式，实现了多队列网卡所提供的功能，分散了在多CPU系统上数据接收时的负载，把软中断分到各个CPU处理，而不需要硬件支持"
  linked_diagnostic_step_no: 1
  mitigation_quote: "#echo ff > /sys/class/net/eth0/queues/rx-0/rps_cpus"

```

## case_id: linux-vm-dirty-flush-burst-io-wait-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 脏页刷盘策略不当导致突发 I/O 等待与文件读写阻塞
- **source_heading**: 调整脏数据刷新策略，减小磁盘的I/O压力
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 4
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0037.html
- **source_url_lang**: zh-cn

### symptom_description

> 此参数的默认值为40，对于写入为主的业务，可以增加此参数，避免磁盘过早的进入到同步写状态。

### diagnostic_steps

```
[step 1] iostat 观察磁盘 await 时间波动 + 读取 dirty_* 三参数当前值
  metric_name: disk await time + vm dirty params
  collection_layer: os
  collection_method_quote: "可以结合业务并通过观察await的时间波动范围来识别。"
  abnormal_pattern_quote: "文件读写变为同步模式后，应用程序的文件读写操作的阻塞时间变长，会导致系统性能下降。"
  abnormal_pattern_threshold: (定性) await 突发性飙升 ∨ dirty_ratio 触发同步写
  metric_unit: ms (await) / ratio (%) / centisecs
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] /proc/sys/vm/dirty_expire_centisecs
  param_name: /proc/sys/vm/dirty_expire_centisecs
  abnormal_value_pattern: 默认 3000（30s）— 写入连续场景
  reasoning_quote: "如果业务的数据是连续性的写，可以适当调小此参数，这样可以避免I/O集中，导致突发的I/O等待。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] /proc/sys/vm/dirty_background_ratio
  param_name: /proc/sys/vm/dirty_background_ratio
  abnormal_value_pattern: 默认 10 — 写入为主业务可调小
  reasoning_quote: "但对于磁盘写入操作为主的业务，可以调小这个值，避免数据积压太多最后成为瓶颈"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] /proc/sys/vm/dirty_ratio
  param_name: /proc/sys/vm/dirty_ratio
  abnormal_value_pattern: 默认 40 — 写入为主业务可适当增大
  reasoning_quote: "为脏页面占用总内存最大的比例，超过这个值，系统不会新增加脏页面，文件读写也变为同步模式。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "对于需要立即存盘的数据，应该采用O_DIRECT模式避免关键数据的丢失。"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给出"如何让应用切到 O_DIRECT"的命令，只给出风险提示)

```

## case_id: linux-block-scheduler-mismatch-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: I/O 调度器与磁盘类型/业务模式不匹配（HDD 数据库使用 CFQ；SSD 未用 NOOP）
- **source_heading**: 优化磁盘I/O调度方式
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0040.html
- **source_url_lang**: zh-cn

### symptom_description

> 这个算法在I/O压力大，且I/O主要集中在某几个进程的时候，性能不太友好。

### diagnostic_steps

```
[step 1] 读取当前块设备 I/O 调度模式
  metric_name: block device I/O scheduler
  collection_layer: os
  collection_method_quote: "# cat /sys/block/$DEVICE-NAME/queue/scheduler"
  abnormal_pattern_quote: "[]中为当前使用的磁盘I/O调度模式。"
  abnormal_pattern_threshold: 当前调度器（[]中标识） ≠ 业务推荐值（HDD 数据库→deadline / SSD→noop）
  metric_unit: enum
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] /sys/block/$DEVICE-NAME/queue/scheduler
  param_name: /sys/block/$DEVICE-NAME/queue/scheduler
  abnormal_value_pattern: cfq（默认）∧ 磁盘类型=HDD ∧ 业务=数据库/大数据（I/O 集中型）
  reasoning_quote: "适合I/O压力大且I/O集中在某几个进程的场景，比如大数据、数据库使用HDD磁盘的场景。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] /sys/block/$DEVICE-NAME/queue/scheduler
  param_name: /sys/block/$DEVICE-NAME/queue/scheduler
  abnormal_value_pattern: cfq / deadline ∧ 磁盘类型=SSD
  reasoning_quote: "因为固态硬盘支持随机读写，所以固态硬盘可以选择这种最简单的调度策略，性能最好。"
  linked_diagnostic_step_no: 1

```

## case_id: linux-fs-mount-nobarrier-audit-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: disk-io-saturation
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: 带电池 RAID 卡环境未使用 nobarrier 挂载选项
- **source_heading**: 磁盘挂载方式优化nobarrier原理
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0041.html
- **source_url_lang**: zh-cn

### symptom_description

> Barrier（栅栏），即先加一个栅栏，保证日志总是先写入，然后对应数据才刷新到磁盘，这种方式保证了系统崩溃后磁盘恢复的正确性，但对写入性能有影响。

### diagnostic_steps

```
[step 1] 读取当前文件系统挂载选项
  metric_name: mount options for filesystem
  collection_layer: os
  collection_method_quote: (NULL · 原文未给"读取挂载选项"命令)
  abnormal_pattern_quote: "服务器如果采用了RAID卡，并且RAID本身有电池，或者采用其它保护方案，那么就可以避免异常断电后日志的丢失，我们就可以关闭这个栅栏"
  abnormal_pattern_threshold: 挂载未含 nobarrier ∧ RAID 卡有电池
  metric_unit: enum (mount options)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] mount option · barrier / nobarrier
  param_name: mount option · barrier / nobarrier
  abnormal_value_pattern: barrier (默认) ∧ RAID 有电池保护
  reasoning_quote: "nobarrier参数使得系统在异常断电时无法确保文件系统日志已经写入磁盘介质，因此只适用于使用了带有保护的RAID卡的情况。"
  linked_diagnostic_step_no: 1

```

## case_id: linux-fs-xfs-blocksize-audit-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: disk-io-saturation
- **case_pattern**: parameter-audit
- **topology**: common
- **title**: 大文件场景未选用 XFS 文件系统或 blocksize 仍为默认 4KB
- **source_heading**: 选用性能更优的文件系统XFS原理
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0041.html
- **source_url_lang**: zh-cn

### symptom_description

> XFS是一种高性能的日志文件系统，XFS极具伸缩性，非常健壮，特别擅长处理大文件，同时提供平滑的数据传输。

### diagnostic_steps

```
[step 1] 读取当前文件系统类型 + blocksize
  metric_name: filesystem type + blocksize
  collection_layer: os
  collection_method_quote: (NULL · 原文未给"读取文件系统类型/blocksize"命令)
  abnormal_pattern_quote: "XFS文件系统在创建时，可先选择加大文件系统的block，更加适用于大文件的操作场景。"
  abnormal_pattern_threshold: filesystem ≠ xfs ∧ workload=大文件 ∨ blocksize=4096 ∧ workload=大文件
  metric_unit: enum / bytes
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] filesystem type (mkfs.xfs vs mkfs.ext4)
  param_name: filesystem type (mkfs.xfs vs mkfs.ext4)
  abnormal_value_pattern: ext4 / 其他 ∧ workload=大文件
  reasoning_quote: "XFS是一种高性能的日志文件系统，XFS极具伸缩性，非常健壮，特别擅长处理大文件，同时提供平滑的数据传输。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] mkfs.xfs -b size=
  param_name: mkfs.xfs -b size=
  abnormal_value_pattern: 4096 (默认) ∧ workload=大文件
  reasoning_quote: "指定blocksize，默认情况下为4KB（4096B），我们假设在格式化时指定为8192B"
  linked_diagnostic_step_no: 1

```

## case_id: kunpeng-arm64-spinlock-cas-cpu-waste-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 自旋锁/CAS 失败循环导致 CPU 资源浪费（perf top 锁函数占比 ≥ 5%）
- **source_heading**: 锁优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 4
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0050.html
- **source_url_lang**: zh-cn

### symptom_description

> 自旋锁和CAS指令都是基于原子操作指令实现，当应用程序在执行原子操作失败后，并不会释放CPU资源，而是一直循环运行直到原子操作执行成功为止，导致CPU资源浪费。

### diagnostic_steps

```
[step 1] perf top 观察锁/原子操作函数 CPU 占比
  metric_name: perf top top-N functions（关注锁/原子操作类）
  collection_layer: flamegraph
  collection_method_quote: "可以通过perf top分析占用CPU资源靠前的函数"
  abnormal_pattern_quote: "如果锁的申请和释放在5%以上，可以考虑优化锁的实现"
  abnormal_pattern_threshold: lock_acquire+lock_release 函数 cpu_share ≥ 0.05
  metric_unit: ratio (%)
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "并发任务高的场景下，如果系统中存在唯一的全局变量，那么每个CPU core都会申请这个全局变量对应的锁，导致这个锁的争抢严重。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "可以基于业务逻辑，为每个CPU core或者线程分配对应的资源。"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "对于高频访问的锁变量，实际是对锁变量进行高频的读写操作，容易发生伪共享问题。"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文给的是设计建议描述非可执行命令)

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "使用ldaxr+stlxr两条指令实现原子操作时，可以同时保证内存一致性，而ldxr+stxr指令并不能保证内存一致性，从而需要内存屏障指令（dmb ish）配合来实现内存一致性。从测试情况看，ldaxr+stlxr指令比ldxr+stxr+dmb ish指令的性能高。"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给具体替换命令，仅说明指令组合差异)

[non_parameter_causes · cause 4] application-design
  cause_type: application-design
  description_quote: "减少线程并发数：参考调整线程并发数章节。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "减少线程并发数：参考调整线程并发数章节。"

```

## case_id: kunpeng-cacheline-false-sharing-arm64-128b-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-arm64-kunpeng
- **engine**: kunpeng-platform
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: x86 上对齐良好的代码迁移到鲲鹏 920（CacheLine 128B）出现伪共享
- **source_heading**: CacheLine优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0052.html
- **source_url_lang**: zh-cn

### symptom_description

> writeHighFreq在一个CPU core中被改写后，这个Cache中对应的CacheLine长度的数据被标识为无效，也就是readHighFreq被CPU core标识为无效数据，虽然readHighFreq并没有被修改，但是CPU在访问readHighFreq时，依然会从内存重新导入，出现伪共享导致性能降低。

### diagnostic_steps

```
[step 1] 通过 perf 观察 Cache 命中率/伪共享指标
  metric_name: L1/L2/L3 cache miss + false-sharing event
  collection_layer: flamegraph
  collection_method_quote: (NULL · 原文未给具体 perf 命令)
  abnormal_pattern_quote: "出现伪共享导致性能降低。"
  abnormal_pattern_threshold: (定性) cache miss 率显著升高 + 高频访问的读/写变量在同 CacheLine
  metric_unit: ratio / events
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "出现伪共享的常见原因是高频访问的数据未按照CacheLine大小对齐。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "使用动态申请内存的对齐方法：1int posix_memalign(void **memptr, size_t alignment, size_t size)"

[non_parameter_causes · cause 2] bios-firmware-issue
  cause_type: bios-firmware-issue
  description_quote: "x86 L3 Cache的CacheLine大小为64字节，鲲鹏920的CacheLine为128字节。"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文给的是源码改造建议描述非可执行命令)

```

## case_id: linux-vm-dirty-ratio-pause-on-large-memory-01

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: dirty_ratio 默认 20-30% 在大内存机上累积巨量脏页,触发同步 flush 卡顿
- **source_heading**: Virtual Memory · Dirty Ratio
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.percona.com/blog/tuning-linux-for-mongodb/
- **source_url_lang**: en

### symptom_description

> The “dirty_ratio” is the percentage of total system memory that can hold dirty pages. The default on most Linux hosts is between 20-30%. When you exceed the limit the dirty pages are committed to disk, creating a small pause.

### diagnostic_steps

```
[step 1] 读 dirty 比例当前值
  metric_name: vm.dirty_ratio / vm.dirty_background_ratio
  collection_layer: os
  abnormal_pattern_quote: "on large-memory database servers, this can be a lot of memory! For example, on a 128GB-memory host, this can allow up to 38.4GB of dirty pages. The background ratio won’t kick in until 12.8GB!"
  abnormal_pattern_threshold: dirty_ratio 默认 20-30% 且物理内存 ≥ 64GB
  metric_unit: percent
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] vm.dirty_ratio / vm.dirty_background_ratio
  param_name: vm.dirty_ratio / vm.dirty_background_ratio
  abnormal_value_pattern: dirty_ratio = 20-30(默认) · dirty_background_ratio = 10-15(默认)
  reasoning_quote: "A recommended setting for dirty ratios on large-memory (64GB+ perhaps) database servers is: “vm.dirty_ratio = 15″ and “vm.dirty_background_ratio = 5″, or possibly less. (Red Hat recommends lower ratios of 10 and 3 for high-performance/large-memory servers.)"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Reducing caches sizes also guarantees data gets written to disk in smaller batches more frequently, which increases disk throughput (than huge bulk writes less often)."
  linked_diagnostic_step_no: 1
  mitigation_quote: "vm.dirty_ratio = 15<br>vm.dirty_background_ratio = 5"

```

## case_id: linux-thp-mongodb-sparse-memory-access-02

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: Transparent HugePages 在 MongoDB 稀疏内存访问场景下产生开销
- **source_heading**: Transparent HugePages
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.percona.com/blog/tuning-linux-for-mongodb/
- **source_url_lang**: en

### symptom_description

> Transparent HugePages is an optimization introduced in CentOS/RedHat 6.0, with the goal of reducing overhead on systems with large amounts of memory. However, due to the way MongoDB uses memory, this feature actually does more harm than good as memory access are rarely contiguous.

### diagnostic_steps

```
[step 1] 读 THP 启动参数
  metric_name: kernel boot option transparent_hugepage
  collection_layer: os
  collection_method_quote: (NULL · 原文给出的是设置值 `transparent_hugepage=never`,未给读取命令)
  abnormal_pattern_quote: "due to the way MongoDB uses memory, this feature actually does more harm than good as memory access are rarely contiguous."
  abnormal_pattern_threshold: (Pre-8.0 视角)/sys/kernel/mm/transparent_hugepage/enabled 当前不为 `never`
  metric_unit: enum
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] kernel.transparent_hugepage
  param_name: kernel.transparent_hugepage
  abnormal_value_pattern: always 或 madvise(非 never)
  reasoning_quote: "due to the way MongoDB uses memory, this feature actually does more harm than good as memory access are rarely contiguous."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "due to the way MongoDB uses memory, this feature actually does more harm than good as memory access are rarely contiguous."
  linked_diagnostic_step_no: 1
  mitigation_quote: "transparent_hugepage=never"

```

## case_id: linux-readahead-default-128kb-wastes-fs-cache-04

- **entry_kind**: diagnostic-flow
- **db**: _common
- **platform**: linux-x86_64-generic
- **engine**: linux-os
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 块设备 read-ahead 默认 128KB 浪费 MongoDB 文件系统缓存
- **source_heading**: Read-Ahead
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.percona.com/blog/tuning-linux-for-mongodb/
- **source_url_lang**: en

### symptom_description

> MongoDB tends to have very random disk patterns and often does not benefit from the default read-ahead setting, wasting memory that could be used for more hot data. Most Linux systems have a default setting of 128KB/256 sectors (128KB = 256 x 512-byte sectors). This means if MongoDB fetches a 64kb document from disk, 128kb of filesystem cache is used and maybe the extra 64kb is never accessed later, wasting memory.

### diagnostic_steps

```
[step 1] 读 read-ahead 当前值
  metric_name: block device read_ahead_kb / sectors
  collection_layer: os
  collection_method_quote: "$ sudo blockdev --getra /dev/sda"
  abnormal_pattern_quote: "Most Linux systems have a default setting of 128KB/256 sectors (128KB = 256 x 512-byte sectors)."
  abnormal_pattern_threshold: 默认 256 扇区(=128KB),建议 32 扇区(=16KB)
  metric_unit: sectors
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] block device queue/read_ahead_kb(udev ATTR{bdi/read_ahead_kb})
  param_name: block device queue/read_ahead_kb(udev ATTR{bdi/read_ahead_kb})
  abnormal_value_pattern: 默认 128(=256 扇区),建议 16(=32 扇区)
  reasoning_quote: "For this setting, we suggest a starting-point of 32 sectors (=16KB) for most MongoDB workloads. From there you can test increasing/reducing this setting and then monitor a combination of query performance, cached memory usage, and disk read activity to find a better balance."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "MongoDB tends to have very random disk patterns and often does not benefit from the default read-ahead setting, wasting memory that could be used for more hot data."
  linked_diagnostic_step_no: 1

```
