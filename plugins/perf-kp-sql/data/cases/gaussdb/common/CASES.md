<!-- ============ Diagnostic-Flow (gaussdb/common, 96 cases) ============ -->

## case_id: gaussdb-cpu-high-topsql-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB CPU使用率高——通过dbe_perf.statement定位高CPU SQL
- **source_heading**: 2.1 CPU使用率高
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://blog.csdn.net/GaussDB/article/details/143844792/
- **source_url_lang**: zh-cn

### symptom_description

> 数据库的CPU使用率高，通常是由业务SQL语句引起的。

### diagnostic_steps

```
[step 1]
  metric_name: dbe_perf.statement.cpu_time
  collection_layer: db-system-view
  collection_method_quote: `select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_elapse_time/1000,2) as total_time,round(cpu_time/1000,2) as cup_time from dbe_perf.statement t where  n_calls>10 and avg_time>3  and user_name='root'  order by cpu_time desc limit 5;`
  abnormal_pattern_quote: "对于平均执行时间超过阈值的SQL语句，重点进行分析与优化。"
  abnormal_pattern_threshold: "avg_time > 3ms"
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: explain analyze 执行计划分析
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain analyze SELECT c_id FROM bmsql_customer WHERE c_w_id = 1 AND c_d_id = 1 AND c_last = 'ABLEABLEABLE' ORDER BY c_first;`
  abnormal_pattern_quote: "结合SQL的执行计划，分析SQL性能的瓶颈点，再进行性能优化"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "SQL语句大量使用了全表扫描，这可能是由索引缺失、索引失效、执行计划不优等因素所导致。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "针对执行性能不优的SQL语句，通过unique_sql_id可以查看该SQL语句的执行详情，帮助分析SQL语句的性能瓶颈点。"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "SQL语句大量进行硬解析，通常是因为应用逻辑未使用PBE（Prepare Bind Execute）。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "如果SQL大量硬解析导致的数据库CPU飚高，可以通过该指标进行分析定位。"

```

## case_id: gaussdb-cpu-high-connection-timezone-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB CPU SYS高——高并发短连接重复加载时区文件
- **source_heading**: 2.1 CPU使用率高（火焰图案例）
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://blog.csdn.net/GaussDB/article/details/143844792/
- **source_url_lang**: zh-cn

### symptom_description

> 某客户在压测过程中发现数据库服务器的CPU SYS占用率超过70%，通过抓取压测期间的火焰图进行分析，如图9所示，发现数据库加载时区文件的线程占比超过40%。

### diagnostic_steps

```
[step 1]
  metric_name: GaussDB内置火焰图 · 时区加载线程占比
  collection_layer: flamegraph
  collection_method_quote: "GaussDB在内核505版本中内置了火焰图工具，默认每5分钟会自动采集一次，保存在$GAUSSLOG/gs_flamegraph/{datanode}路径下，详细信息可参考GaussDB产品文档《内置perf工具》章节。"
  abnormal_pattern_quote: "发现数据库加载时区文件的线程占比超过40%"
  abnormal_pattern_threshold: `> 40%`
  metric_unit: sample ratio
  prerequisite_steps: []
  flame_pattern:
    见下方

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "原因是在高并发频繁建立连接时，数据库每次建连都需要读取时区文件以获取时区信息，而应用未使用长连接，导致CPU SYS使用率飙升。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "应用未使用长连接"

```

## case_id: gaussdb-memory-shared-buffer-miss-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB内存不足——shared_buffers过小导致buffer命中率低
- **source_heading**: 2.2 内存不足（共享缓存区不足）
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://blog.csdn.net/GaussDB/article/details/143844792/
- **source_url_lang**: zh-cn

### symptom_description

> 共享缓存区不足，导致SQL的buffer命中率低。为了查看相应的性能指标，可以借助GaussDB的管控平台或者WDR报告。通常情况下，TP数据库的buffer命中率应该在99%以上。如果数据库的buffer命中率较低，建议排查数据库的shared_buffers参数设置是否合理。

### diagnostic_steps

```
[step 1]
  metric_name: buffer命中率 (WDR报告或管控平台)
  collection_layer: db-system-view
  collection_method_quote: "可以借助GaussDB的管控平台或者WDR报告。通常情况下，TP数据库的buffer命中率应该在99%以上。"
  abnormal_pattern_quote: "通常情况下，TP数据库的buffer命中率应该在99%以上。如果数据库的buffer命中率较低，建议排查数据库的shared_buffers参数设置是否合理"
  abnormal_pattern_threshold: `< 99%`
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] shared_buffers
  param_name: shared_buffers
  abnormal_value_pattern: 设值过小
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: "共享缓存区不足，导致SQL的buffer命中率低"
  reasoning_quote: "共享缓存区不足，导致SQL的buffer命中率低。通常情况下，TP数据库的buffer命中率应该在99%以上。如果数据库的buffer命中率较低，建议排查数据库的shared_buffers参数设置是否合理"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-memory-work-mem-spill-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB内存不足——work_mem过小导致Hash/Sort算子落盘
- **source_heading**: 2.2 内存不足（算子落盘）
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://blog.csdn.net/GaussDB/article/details/143844792/
- **source_url_lang**: zh-cn

### symptom_description

> 在GaussDB中，SQL的hash join或者sort算子存在数据落盘操作，work_mem参数控制可下盘算子可用的物理内存空间。如果work_mem所限定的物理内存不够，算子运算的数据将被写入临时表空间，会带来5-10倍的性能下降。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE 算子落盘标志
  collection_layer: db-interactive-cmd
  collection_method_quote: "为了优化性能，可以查看SQL的执行计划，如果算子存在落盘的情况，可适当调整work_mem参数值。"
  abnormal_pattern_quote: "如果算子存在落盘的情况"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] work_mem
  param_name: work_mem
  abnormal_value_pattern: 设值过小，不足以容纳算子运算数据
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: "如果work_mem所限定的物理内存不够，算子运算的数据将被写入临时表空间，会带来5-10倍的性能下降。"
  reasoning_quote: "work_mem参数控制可下盘算子可用的物理内存空间。如果work_mem所限定的物理内存不够，算子运算的数据将被写入临时表空间，会带来5-10倍的性能下降。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-disk-io-high-statement-view-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB整体IO高——通过性能视图定位高物理读SQL
- **source_heading**: •IO高
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/1881247803599499264/
- **source_url_lang**: zh-cn

### symptom_description

> GaussDB数据库整体性能慢，不满足客户作业对时延要求或者不满足客户预期。有可能会出现大量慢SQL。

### diagnostic_steps

```
[step 1]
  metric_name: dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高)
  collection_layer: db-system-view
  collection_method_quote: "如果持续IO高，可查询dbe_perf.statement/dbe_perf.summary_statement内n_blocks_fetched/n_blocks_hit字段，通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。"
  abnormal_pattern_quote: "通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: pg_thread_wait_status.wait_status / wait_event (当前IO高)
  collection_layer: db-system-view
  collection_method_quote: "如果当前IO高，可查询pg_thread_wait_status视图，查询wait_status/wait_event字段，通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。"
  abnormal_pattern_quote: "通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 3]
  metric_name: statement_history.data_io_time (慢SQL IO分析)
  collection_layer: db-system-view
  collection_method_quote: "查询statement_history表，慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录"
  abnormal_pattern_quote: "慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "通常可使用pidstat/iotop识别到导致IO高的线程，有可能是其它内核后台线程导致的IO高，比如刷WAL线程，这些场景不具有代表性，而且和特性业务场景强关，本部分仅关注由于用户语句导致的IO异常。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "如果持续IO高，可查询dbe_perf.statement/dbe_perf.summary_statement内n_blocks_fetched/n_blocks_hit字段，通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。"

```

## case_id: gaussdb-memory-pressure-node-detail-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB内存高——通过dbe_perf.memory_node_detail定位内存占用点
- **source_heading**: •内存高
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/1881247803599499264/
- **source_url_lang**: zh-cn

### symptom_description

> GaussDB数据库整体性能慢，不满足客户作业对时延要求或者不满足客户预期。有可能会出现大量慢SQL。

### diagnostic_steps

```
[step 1]
  metric_name: dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory
  collection_layer: db-system-view
  collection_method_quote: "查询dbe_perf.memory_node_detail视图，明确内存占用点。•max_dynamic_memory：最大可使用动态内存 •dynamic_used_memory：已使用动态内存"
  abnormal_pattern_quote: "通常仅需要关注max_dynamic_memory和dynamic_used_memory差距，如果dynamic内存不足，会导致用户查询报错"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

[step 2]
  metric_name: dbe_perf.session_memory_detail (dynamic_used_shrctx较小时)
  collection_layer: db-system-view
  collection_method_quote: "dynamic_used_shrctx较小，查询dbe_perf.session_memory_detail可获取到不同Session的内存消耗，通常来讲：用户会话数和用户每个session上内存占用都会导致动态内存异常问题。"
  abnormal_pattern_quote: "dynamic_used_shrctx较小"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [1]

[step 3]
  metric_name: dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时)
  collection_layer: db-system-view
  collection_method_quote: "dynamic_used_shrctx较大，查询dbe_perf.shared_memory_detail可获取到异常内存消耗的context，通常此处有过多的异常消耗，多数情况下为用户session上的内存异常消耗。"
  abnormal_pattern_quote: "dynamic_used_shrctx较大"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "dynamic_used_memory包含两部分内容：a.用户session上的内存消耗，比如：计划缓存、排序等。 b.内核模块的内存消耗，如：Global Sys Cache、Unique SQL等。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "通常仅需要关注max_dynamic_memory和dynamic_used_memory差距，如果dynamic内存不足，会导致用户查询报错"

```

## case_id: gaussdb-perf-jitter-asp-analysis-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB性能抖动——通过ASP/WDR定位抖动根因
- **source_heading**: •性能抖动
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/1881247803599499264/
- **source_url_lang**: zh-cn

### symptom_description

> GaussDB数据库整体性能慢，不满足客户作业对时延要求或者不满足客户预期。有可能会出现大量慢SQL。业务反馈业务接口时延高；或者数据库P80/P95等指标升高；业务时延受损，或者业务在预期时间内无法执行完成。

### diagnostic_steps

```
[step 1]
  metric_name: dbe_perf.local_active_session (秒级抖动)
  collection_layer: db-system-view
  collection_method_quote: "对于短时间秒级性能抖动，分析相应时间点的dbe_perf.local_active_session，可排查点如下：•异常等待事件，当时SQL的异常等待事件，可参考整体性能慢-等待事件分析。•异常SQL，分析某些SQL出现的频率变化，以及执行速度，如多次采样均被采集到，即可反向分析到SQL执行时间。•异常连接数变化，比如业务突然连接增加。"
  abnormal_pattern_quote: "如多次采样均被采集到，即可反向分析到SQL执行时间"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: gs_asp (两天内秒级抖动)
  collection_layer: db-system-view
  collection_method_quote: "对于两天内秒级性能抖动，分析相应时间点的gs_asp表"
  abnormal_pattern_quote: "分析相应时间点的gs_asp表"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "ASP默认每秒采样活跃会话信息，然后存入内存（dbe_perf.local_active_session），默认内存存储10W条记录，满后按十分之一采样率下盘（gs_asp）。◾所以理想情况下，ASP内存视图存储每秒的会话数据，物理表存储以10秒为间隔存储会话数据。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对于短时间秒级性能抖动，分析相应时间点的dbe_perf.local_active_session"

```

## case_id: gaussdb-plan-suboptimal-sql-x01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB迁移慢SQL执行计划算子特征筛查
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 由于两个数据库的机制不同，部分SQL如果直接运行，性能可能会出现劣化，因此需要对可能性能劣化的SQL改造

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划costs
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 优先关注costs（costs > 1000需要重点关注）
  abnormal_pattern_threshold: costs > 1000
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: SeqScan算子
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 如果有seqscan需要根据rows情况判断执行计划是否高效
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: NestLoop算子
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 如果有nestloop需要考虑是否有参数下推的可能，同时也需要考虑数据量的情况，来判定nestloop是否高效
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 有seqscan算子，全表扫描可能很慢，需要修改
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: 能够大幅提升性能的参数路径操作，只能使用NestloopJoin
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-cpu-high-cpu-x02

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB高并发压测场景CPU使用率100%诊断
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 高并发下 CPU 使用率长时间维持 100%（超出 80% 目标）。

### diagnostic_steps

```
[step 1]
  metric_name: CPU使用率
  collection_layer: manual-external
  collection_method_quote: `[需外部确认] 在监控平台查看CPU`
  abnormal_pattern_quote: 使用率长时间附在上边界
  abnormal_pattern_threshold: 100%
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: CPU核使用率
  collection_layer: manual-external
  collection_method_quote: `[需外部确认] 使用杀猪刀工具抓取CPU使用率峰值时的数据`
  abnormal_pattern_quote: 96个核的使用率均超过了99%
  abnormal_pattern_threshold: 99%
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: CPU堆栈
  collection_layer: flamegraph
  collection_method_quote: `NULL`
  abnormal_pattern_quote: 这段时间的堆栈属于正常的业务流程，并无异常堆栈
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: 慢SQL及调用频次
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
  abnormal_pattern_quote: 主要为大量调用小型自定义函数的查询SQL。这些底层查询，大部分执行速度低于300us，且索引完备，但调用频次过高（累计5min，9000w次，约30w次/s），无法降低调用频率，则无优化空间。
  abnormal_pattern_threshold: 30w次/s
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 主要为大量调用小型自定义函数的查询SQL。这些底层查询，大部分执行速度低于300us，且索引完备，但调用频次过高（累计5min，9000w次，约30w次/s），无法降低调用频率，则无优化空间。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-sql-x03

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB SQL执行疑似hang因未Analyze导致Nestloop计划不准
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 一条带 LEFT JOIN 的 SQL 执行长时间阻塞（运行数小时未完成），导致顺序执行的其他业务卡住；pg_stat_activity 显示该语句长期处于运行态。

### diagnostic_steps

```
[step 1]
  metric_name: explain performance结果
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain performance <目标SQL>;`
  abnormal_pattern_quote: 没有语句不过滤分区键，未分区剪枝导致全表扫描的情况
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 管理平台告警及通信层报错
  collection_layer: manual-external
  collection_method_quote: `[需外部确认] 查看管理平台无网络、慢盘等告警，通信层无报错`
  abnormal_pattern_quote: 无网络、慢盘等告警，通信层无报错
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 业务数据入库及analyze情况与执行计划
  collection_layer: manual-business
  collection_method_quote: `[需确认业务] 了解业务，发现业务每天该分区表都有近2亿条数据入库，入库后未做过analyze`
  abnormal_pattern_quote: 入库后未做过analyze，查看计划确实大的结果集条数走了nest loop导致较慢
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 未进行analyze充分收集统计信息时，优化器在选择执行计划时，对结果集评估较小，导致计划走了nestloop，性能下降，导致一天都执行不完
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-x05

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB回放模式参数配置不合理导致回放慢
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 排查参数了解回放模式...不同回放模式对回放性能的影响不同

### diagnostic_steps

```
[step 1]
  metric_name: recovery_max_workers/recovery_parse_workers/recovery_redo_workers
  collection_layer: db-shell
  collection_method_quote: `show recovery_max_workers; show recovery_parse_workers; show recovery_redo_workers; show shared_buffers;`
  abnormal_pattern_quote: 可以结合环境的机器规格和资料判断配置是否合理
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] recovery_max_workers/recovery_parse_workers/recovery_redo_workers
  param_name: recovery_max_workers/recovery_parse_workers/recovery_redo_workers
  abnormal_value_pattern: 这三个参数都为1，是串行回放
  recommended_value: NULL
  recommendation_quote: recovery_parse_workers或recovery_redo_workers大于1时，为极致RTO
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

```

## case_id: gaussdb-other-ddl-x07

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB DDL等特定日志类型导致回放慢
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 排查是否是特定日志类型引起的回放慢

### diagnostic_steps

```
[step 1]
  metric_name: 回放日志类型统计
  collection_layer: db-interactive-cmd
  collection_method_quote: `select * from local_xlog_redo_statics()`
  abnormal_pattern_quote: 关注特殊日志类型，尤其是ddl相关的xlog
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: print_redo_wal_count_info/print_redo_wal_time_info
  collection_layer: log-grep
  collection_method_quote: `在备机的gs_log检索“print_redo_wal”关键字`
  abnormal_pattern_quote: print_redo_wal_count_info显示的是该周期内新增回放数量（total num）最多的10种日志...print_redo_wal_time_info显示的是极致RTO回放模式下，对于上述10种日志类型的回放用时统计情况
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: redo_unlink_ddl
  collection_layer: log-grep
  collection_method_quote: `在gs_log中检索“redo_unlink_ddl”关键字`
  abnormal_pattern_quote: 可查看每10分钟周期内回放涉及删除文件的DDL数量
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 由于DDL如删除文件等操作的xlog，需要由事务回放线程（对于并行回放这个线程是startup线程，对于极致rto该线程为专门的事务日志回放线程）进行回放，这就涉及到该线程和页面数据回放线程的同步了，这时候回放的并行度就比较低，而且ddl操作本身大部分涉及对表结构整体的修改，本身回放速度也不快
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-disk-io-saturation-x08

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB备机IO时延高或缓存命中率低导致回放慢
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 备机回放对io读写时延比较敏感

### diagnostic_steps

```
[step 1]
  metric_name: buffer_hit_rate / read_buffer_io
  collection_layer: db-interactive-cmd
  collection_method_quote: `select * from gs_redo_stat_info()`
  abnormal_pattern_quote: buffer_hit_rate为近十分钟内的缓存命中率，一般而言数据缓存的命中率大于90%的情况下，才能保证数据库系统高效运行
  abnormal_pattern_threshold: 90%
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: WAIT_READ_DATA
  collection_layer: db-system-view
  collection_method_quote: `select * from dbe_perf.GLOBAL_WAIT_EVENTS where wait!=0 order by total_wait_time desc;`
  abnormal_pattern_quote: 查看读写data的等待事件时延等判断回放的瓶颈
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: buffer_hit_rate / WAIT_READ_DATA
  collection_layer: log-grep
  collection_method_quote: `在gs_log中检索“buffer_hit_rate”、“WAIT_READ_DATA”关键字`
  abnormal_pattern_quote: 可查看历史时间段上十分钟内回放线程的缓存命中率和等待事件统计信息
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] hardware-disk
  cause_type: hardware-disk
  description_quote: 磁盘随机io慢，buffer频繁换入换出，命中率低导致回放速度慢
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-data-skew-x09

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB并行回放业务数据倾斜导致回放慢
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 如果业务集中在个别物理表，则回放线程的利用是不充分的，这时候回放速度也无法达到最优

### diagnostic_steps

```
[step 1]
  metric_name: q_use / q_max_use / rec_cnt
  collection_layer: db-shell
  collection_method_quote: `cm_ctl query -rv或者select * from local_redo_stat();`
  abnormal_pattern_quote: 主要观察q_use几个现场是否不均衡，如果不均衡的严重，那就是当前业务的特点导致cpu利用不充分
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: queue usage
  collection_layer: log-grep
  collection_method_quote: `在日志中搜索queue statistic`
  abnormal_pattern_quote: 有历史上各个线程队列的queue usage信息...可以从这里观察分发是否均匀
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: 业务集中在个别物理表，则回放线程的利用是不充分的，这时候回放速度也无法达到最优
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-key-x10

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB高并发插入相同key值导致global索引空间膨胀
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 转账历史记录表的索引出现明显的空间膨胀（索引表占用存储空间比原表还要大），而包含对应字段的复合索引并未未出现存储空间膨胀问题。 基于分区字段deal_time创建的global索引idx_t_log_h_deal_time_a比基于deal_time和out_account_id创建的复合索引占用空间更大（单字段索引占用空间是复合索引的3.8倍），存在严重的空间膨胀问题。

### diagnostic_steps

```
[step 1]
  metric_name: 索引页面元组分布
  collection_layer: db-interactive-cmd
  collection_method_quote: `使用gs_parse_page_bypath函数解析索引表页面，分析表页面使用情况。`
  abnormal_pattern_quote: 大部分叶子页面内保存的索引元组中只有10+条，而页面1中保存了200+索引元组。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] ubtree页面分裂策略
  param_name: ubtree页面分裂策略
  abnormal_value_pattern: INSERTPT
  recommended_value: DEFAULT
  recommendation_quote: ubtree页面采用INSERTPT分裂策略，同key值场景右页面空间利用率低。（将分裂算法改成DEFAULT后，索引膨胀不明显）
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 高并发插入索引key值相同的用户数据，这些数据被分散到ctid不同的众多页面（低并发场景下ctid值分布不广，索引膨胀不明显），key值相同的索引元组在插入到索引页面时，需要根据ctid值进行排序插入。叠加分裂算法，导致页面分裂都发生在左叶子节点，右叶子节点中数据较少。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-lock-contention-sql-x11

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB大数据分批入库SQL执行超时等待log file switch事件
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 大数据分批入库的时候，每次入库1000条仍然出现sql执行超时问题。定位发现卡住的时候我们的session都在等待log file switch (checkpoint incomplete)事件。

### diagnostic_steps

```
[step 1]
  metric_name: v$logfile
  collection_layer: db-system-view
  collection_method_quote: `select * from v$logfile;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 改事件主要由数据库的redo日志大小来决定
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-disk-io-saturation-bm25-x13

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB BM25索引创建性能瓶颈（磁盘IO过高）
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> bm25创建涉及大量磁盘读写，性能瓶颈大部分是由于磁盘的iowait过高所导致。

### diagnostic_steps

```
[step 1]
  metric_name: 磁盘IO信息
  collection_layer: os
  collection_method_quote: `iostat -c -x -m -t 5`
  abnormal_pattern_quote: 磁盘的iowait过高
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] hardware-disk
  cause_type: hardware-disk
  description_quote: bm25创建涉及大量磁盘读写，性能瓶颈大部分是由于磁盘的iowait过高所导致。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-lock-contention-x14

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB锁冲突导致响应慢
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 锁冲突

### diagnostic_steps

```
[step 1]
  metric_name: wait_event_count
  collection_layer: db-system-view
  collection_method_quote: `select wait_status,wait_event,count(*) from pg_thread_wait_status group by wait_status,wait_event order by 3 desc;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: blocked_query
  collection_layer: db-system-view
  collection_method_quote: `select pid,sessionid,substr(query,0,100) from pg_stat_activity where sessionid in(select sessionid from pg_thread_wait_status where wait_event='wait_event');`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: blocking_query
  collection_layer: db-system-view
  collection_method_quote: `select pid,sessionid,substr(query,0,100) from pg_stat_activity where sessionid in(select block_sessionid from pg_thread_wait_status where wait_event='wait_event');`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 锁冲突
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-memory-pressure-x16

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB动态内存使用率高应急处理
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 动态内存使用率高

### diagnostic_steps

```
[step 1]
  metric_name: pg_total_memory_detail
  collection_layer: db-system-view
  collection_method_quote: `select * from pg_total_memory_detail;`
  abnormal_pattern_quote: 如果dynamic_used_memory较大，dynamic_used_shrctx较小，则可以确认是线程和session上内存占用较多；如果dynamic_used_memory较大，dynamic_used_shrctx和dynamic_used_memory相差不大，则是全局内存占用较多。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: thread_session_memory_context
  collection_layer: db-system-view
  collection_method_quote: `select contextname, sum(totalsize)/1024/1024 totalsize, sum(freesize)/1024/1024 freesize, count(*) sum from gs_thread_memory_context group by contextname order by sum desc limit 10;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 全局内存占用高 / 线程内存占用高 / session内存占用高
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: 出现了频繁的内存申请和释放的业务导致内存碎片缓存过多
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-x18

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB索引失效导致查询变慢
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 索引失效

### diagnostic_steps

```
[step 1]
  metric_name: pg_index_indisusable
  collection_layer: db-system-view
  collection_method_quote: `SELECT indexrelid，indisusable FROM pg_index WHERE indrelid = '<table>'::regclass;`
  abnormal_pattern_quote: 若indisusable = false，则索引失效
  abnormal_pattern_threshold: false
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 索引列使用函数 / 索引列执行计算 / 索引列发生隐式类型转换 / 索引列使用负向运算符 / WHERE中的OR条件 / 对索引列使用模糊匹配
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-tpcc-x20

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB TPCC性能波动大及CPU利用率低诊断
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 性能波动大 波动时（即下图中红框CPU利用率低的区段），由于受到日志扩页的影响，TPLworker线程都在等待日志插入

### diagnostic_steps

```
[step 1]
  metric_name: offcpu火焰图
  collection_layer: flamegraph
  collection_method_quote: `/usr/share/bcc/tools/offcputime -df -p <pid> 30 > off.stacks && flamegraph.pl off.stacks > offcpu.svg`
  abnormal_pattern_quote: 波动时（即下图中红框CPU利用率低的区段），由于受到日志扩页的影响，TPLworker线程都在等待日志插入
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] wal file init num
  param_name: wal file init num
  abnormal_value_pattern: 过小
  recommended_value: 增大
  recommendation_quote: 可以通过增大主机日志预扩参数wal file init num解决
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

```

## case_id: gaussdb-other-tpcc-x21

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB TPCC备机日志预扩阻塞导致性能波动
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 此时性能还是存在波动 备机日志预扩同样存在阻塞

### diagnostic_steps

```
[step 1]
  metric_name: offcpu火焰图
  collection_layer: flamegraph
  collection_method_quote: `/usr/share/bcc/tools/offcputime -df -p <pid> 30 > off.stacks && flamegraph.pl off.stacks > offcpu.svg`
  abnormal_pattern_quote: 备机日志预扩同样存在阻塞
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] advance_xlog_file_num
  param_name: advance_xlog_file_num
  abnormal_value_pattern: 过小
  recommended_value: 增大
  recommendation_quote: 解决办法：增大备机日志预扩参数advance_xlog_file_num
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

```

## case_id: gaussdb-other-astore-x22

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB astore表索引查询n_tuples_fetched统计值异常翻倍
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 发现在做索引查询的时候n_tuples_fetched的数量恒定是n_tuples_returned的数量的2倍

### diagnostic_steps

```
[step 1]
  metric_name: n_tuples_fetched / n_tuples_returned
  collection_layer: db-system-view
  collection_method_quote: `查询dbe_perf.statement_history`
  abnormal_pattern_quote: n_tuples_fetched的数量恒定是n_tuples_returned的数量的2倍
  abnormal_pattern_threshold: n_tuples_fetched = 2 * n_tuples_returned
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: t_tuples_fetched累加次数
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] 通过gdb获取上述t_counts中的t_tuples_returned变量地址，通过watch该地址观察到t_tupl`
  abnormal_pattern_quote: 可以看到在一轮tuple的获取过程中确实对t_tuples_fetched进行了2次累加。
  abnormal_pattern_threshold: 单轮获取过程中累加2次
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 参考pg的代码，在index_fetch_heap函数里做的计数增长，类似上图中的index_fetch_tuple，heapam_index_fetch_tuple函数里没有做fetch元组的计数增长
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-memory-pressure-other-x23

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 大量子事务导致other内存上涨
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 动态内存小幅上涨

### diagnostic_steps

```
[step 1]
  metric_name: subtransactions log
  collection_layer: log-grep
  collection_method_quote: `日志中可以尝试搜索关键字Transaction %lu has reached %d subtransactions!`
  abnormal_pattern_quote: 阈值为50000
  abnormal_pattern_threshold: 50000
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 大量子事务会对应大量小块的事务底噪上下文（例如ResourceOwnerCxt），导致线程顶级上下文产生大量碎片。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-query-slow-autosave-x24

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB开启autosave语句级回滚性能劣化诊断与优化
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 性能劣化30%~30倍；GaussDB通过JDBC配置autosave开启可以实现与MySQL的类同语句级回滚的功能，但是在性能上差异较大：只读场景：MySQL耗时114秒，GaussDB耗时3831秒；读写混合：MySQL耗时414秒，GaussDB耗时524秒；

### diagnostic_steps

```
[step 1]
  metric_name: 事务可见性判断函数(xact_is_current_xid)耗时
  collection_layer: flamegraph
  collection_method_quote: `NULL`
  abnormal_pattern_quote: 子事务嵌套，导致访问数据时，事务可见性判断代价大，也即火焰图中xact_is_current_xid函数；判断所访问数据可见性时，会遍历查询当前事务块管理的事务链表，根据父子事务链，从当前子事务逐个往前查找，直到找到或遍历完成。因此当事务块内语句越多时，autosave自动带出的保存点也就越多，导致遍历开销越大。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 保存点数量开销
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] NULL`
  abnormal_pattern_quote: 查询语句，也会生成保存点，存在不必要的保存点开销，并且使“瓶颈1”加剧
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 保存点SQL解析开销
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] NULL`
  abnormal_pattern_quote: 显式保存点，存在SQL解析开销
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 此差异是由于GaussDB事务机制引起：通过子事务实现保存点，其管理代价成本高。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-cpu-high-cpu-x25

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 索引缺少过滤性好的字段导致CPU冲高
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 确定为消耗CP高的SQL

### diagnostic_steps

```
[step 1]
  metric_name: SQL CPU消耗
  collection_layer: db-system-view
  collection_method_quote: `select * from gs_asp where sample_time > now() - interval '10 minute' order by sample_time;`
  abnormal_pattern_quote: 消耗CP高的SQL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 索引列过滤性
  collection_layer: db-interactive-cmd
  collection_method_quote: `select attname, n_distinct, most_common_vals from pg_stats where tablename='<表>';`
  abnormal_pattern_quote: cus_idr过滤性不好，crt_dttm的过滤性好一些
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 语句只用到了主键的第一个字段...cus_idr过滤性不好，crt_dttm的过滤性好一些，建议把分布列加到复合索引中，并放在复合索引的左侧
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-cpu-high-index-x26

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 不支持index skip scan导致扫描所有页面CPU冲高
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 在网版本不支持index skip scan导致cpu冲高问题

### diagnostic_steps

```
[step 1]
  metric_name: 活跃会话数
  collection_layer: db-system-view
  collection_method_quote: `查看gs_asp视图查看活跃会话数在冲高时间点`
  abnormal_pattern_quote: 92并发在同时运行
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 执行计划索引扫描范围
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 在索引扫描时扫描大量的页面，会消耗大量的CPU。使用的主键索引的后两列，没有使用第一列，导致扫描索引的所有页面
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: gaussdb目前ZH版本不支持index skip scan，而语句使用的列中actnum过滤性最好，基本上唯一，建议业务创建新额复合索引actnum、bancs_no解决问题
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-lock-contention-ddl-x27

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 业务高峰期大量DDL导致LockMgrLock热点引发线程池打满
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 业务高峰期线程池打满，触发线程池抗过载，约 2 分钟后多个 DN 节点触发主备切换，业务明显变慢。

### diagnostic_steps

```
[step 1]
  metric_name: ASP数据/等待事件
  collection_layer: db-system-view
  collection_method_quote: `select * from gs_asp where sample_time > now() - interval '10 minute' order by sample_time;`
  abnormal_pattern_quote: 大量的线程正在等待LockMgrLock。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 经排查在该时间段业务持续存在大量DLL语句。大量DDL导致低级锁无法走fastpath路径，导致LockMgrLock成为热点，概率性产生大量LockMgrLock等待事件。同时fastpath锁不够，也会加剧LockMgrLock的等待。在该阶段由于业务都为stream计划，计划涉及多个DN执行，当6055节点慢后，其他节点stream计划会等待6055节点，导致其他节点的线程池也会打满，触发抗过载。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-exists-x29

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: EXISTS子连接包含union导致无法提升引发慢SQL
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 查看执行计划，发现存在相关子连接，由于子连接中引用了外层表的列属性，导致外层表每获得一个元组，子查询就需要重新执行一次...但是计划中未提升

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 计划中未提升
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: EXISTS子句中包含两个SQL进行union操作，是一个非简单的EXISTS子连接，所以无法提升。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-not-x30

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: Not In子连接产生null值过滤导致无法走索引
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 查看计划发现NestLoop Anti Join的内表是大表，且无过滤条件，导致全表扫描数据

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: NestLoop Anti Join的内表是大表，且无过滤条件，导致全表扫描数据
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: not in产生的join过滤条件上会加上or is null，导致无法用上索引，计划变慢
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-x31

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: OR表达式不支持索引导致全表扫描
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 查看计划显示SEQSCAN

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 查看计划显示SEQSCAN
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 分析SQL中采用了or条件，导致无法使用索引
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-seqscan-x33

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: SeqScan+Stream算子效率低下未利用SMP并行
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 查看计划性能瓶颈在两处seqscan上，且上面有一层Stream算子

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 性能瓶颈在两处seqscan上，且上面有一层Stream算子
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] query_dop
  param_name: query_dop
  abnormal_value_pattern: 未开启SMP并行
  recommended_value: 16
  recommendation_quote: 采用SMP并行，设置query_dop为16以后
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: seqscan效率低下，未利用并行提升性能
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-disk-io-saturation-tps-x34

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB长稳测试TPS抖动性能修复
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 3
- **source_url_lang**: zh-cn

### symptom_description

> 高并发长稳压测下 TPS 周期性波动；并发线程与活跃会话稳定、CPU/内存未达瓶颈，IO 使用率偏高且存在 >4ms IO 等待。

### diagnostic_steps

```
[step 1]
  metric_name: 慢SQL数量及系统库大小
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
  abnormal_pattern_quote: 在TPS波动期间存在大量10ms以上的COMMIT语句，进一步确认发现GUC参数log_min_duration_statement为10ms，且压测完成后系统库大小为8GB，业务库慢SQL数量600万条。
  abnormal_pattern_threshold: 系统库大小8GB，慢SQL数量600万条
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 备机日志刷盘影响
  collection_layer: db-interactive-cmd
  collection_method_quote: `将GUC参数synchronous_commit设置为local进行长稳测试。`
  abnormal_pattern_quote: 将参数设置为local后，测试结果仍然存在TPS波动问题，排除备机日志刷盘对TPS波动的影响。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: WDR报告与等待事件
  collection_layer: db-system-view
  collection_method_quote: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
  abnormal_pattern_quote: 随着压测的进行，数据量增大，导致内存和磁盘之间的缓冲池buffer pool被填满，需要和磁盘进行换入换出，CPU的IO等待占比增大，导致TPS下降。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: 线程等待磁盘返回结果
  collection_layer: manual-external
  collection_method_quote: `[需外部确认] 在长稳测试TPS出现抖动时，抓取当前系统内的所有线程信息，通过杀猪刀工具分析发现`
  abnormal_pattern_quote: 在抖动点的1s内有近11次出现线程在等待磁盘返回结果（等待时间为20ms~50ms，合理值应为20~200us），说明磁盘IO能力较差。
  abnormal_pattern_threshold: 等待时间为20ms~50ms
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] log_min_duration_statement
  param_name: log_min_duration_statement
  abnormal_value_pattern: 10ms
  recommended_value: 3000ms
  recommendation_quote: 该参数出口值为3000ms，若设置过小，会导致大量慢SQL记录到系统表statement_history，写到磁盘文件，初步怀疑此参数设置过小，系统表statement_history膨胀后，发生刷盘行为，产生大量IO，影响业务TPS。
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[parameter_causes · cause 2] walwriter_cpu_bind
  param_name: walwriter_cpu_bind
  abnormal_value_pattern: 未绑定指定CPU核
  recommended_value: 31
  recommendation_quote: 通过将walwriter_cpu_bind 参数设置为31，即指定31号CPU核处理walwriter线程刷日志，缓解walwriter线程刷盘时等待CPU调度带来的开销（CPU可能等待其他worker线程磁盘IO，不能及时响应walwriter刷盘）。
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] hardware-disk
  cause_type: hardware-disk
  description_quote: 磁盘IO能力差，除了影响pagewriter刷脏页，还会影响walwriter进行日志刷盘。此次长稳TPS抖动，虽然是磁盘IO存在瓶颈导致。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-cpu-high-cpu-x36

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 核心系统 CPU 打满问题分析
- **diagnostic_steps_count**: 5
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> CPU 冲高至 100%（持续约 10 分钟）。

### diagnostic_steps

```
[step 1]
  metric_name: 语句执行情况与执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `通过gs_asp查看对应时间段的语句执行情况`
  abnormal_pattern_quote: 大批量语句计划变为seqscan，导致消耗大量资源，引发CPU冲高。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 代价估算与页面数
  collection_layer: db-system-view
  collection_method_quote: `识别上面的代价估算较低，仅为18，证明pg_class中记录的页面数较少。`
  abnormal_pattern_quote: 代价估算较低，仅为18，证明pg_class中记录的页面数较少。
  abnormal_pattern_threshold: 18
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: vacuum执行记录
  collection_layer: log-grep
  collection_method_quote: `通过pg_log,发现在某时刻开始，针对<库名> 中的分区sys_p22进行了vacuum。`
  abnormal_pattern_quote: 此表在导数后，直到25日前，未触发vacuum 并且此表分区间存在严重的数据倾斜
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: 慢SQL与计划跳变排查
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, count(*) from dbe_perf.statement_history where start_time > 'XXX' and start_time < 'XXX' group by 1 order by 2 desc; <br> select unique_query_id, query, query_plan from dbe_perf.statement_history where unique_query_id in (XXX,XXX); <br> select unique_query_id, count(*) from dbe_perf.local_active_session where sample_time > 'XXX' and sample_time < 'XXX' group by 1 order by 2 desc; <br> select unique_sql_id, query from dbe_perf.summary_statement where unique_sql_id in ('XXX', 'XXX');`
  abnormal_pattern_quote: 若预期该语句应该index_scan但plan中出现seq_scan，则初步判断出现了计划跳变。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 5]
  metric_name: 分区表统计信息准确性
  collection_layer: db-system-view
  collection_method_quote: `with sizeinfo as (select relname, parentid, pg_partition_size(parentid, oid) partsize, relpages from pg_partition where parttype = 'p') select tablename,tablesize/1024 as "size(KB)", pages*8.192 as "page(KB)" from (select parentid::regclass as tablename, sum(partsize) as tablesize, sum(relpages) as pages from sizeinfo group by parentid) where tablesize > 1000000 and pages < 10000 and pages*8192.0/tablesize < 0.1;`
  abnormal_pattern_quote: 所有分区的真实空间大小之和比所有分区预估大小之和的大10倍的展示出来后续做vacuum。
  abnormal_pattern_threshold: pages*8192.0/tablesize < 0.1
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: 此表分区间存在严重的数据倾斜 导致在vacuum此分区时扫描了较少的页面，导致更新了pg_class为较少页面数，引发计划代价变化，导致全表扫描。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: 此表在导数后，直到25日前，未触发vacuum
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-query-slow-dataarts-x37

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: Dataarts 业务中的ustore表死元组堆积导致查询变慢
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 模拟业务运行中，发现数据库查询越来越慢。

### diagnostic_steps

```
[step 1]
  metric_name: last_vacuum
  collection_layer: db-system-view
  collection_method_quote: `查看相关表的日志，以及pg_stat_all_tables视图，通过其中的last_vacuum字段`
  abnormal_pattern_quote: 确认相关表在创建后从未vacuum
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: n_tup_hot_upd / n_tup_upd / n_dead_tup / n_live_tup
  collection_layer: db-system-view
  collection_method_quote: `在pg_stat_all_tables中表现如下`
  abnormal_pattern_quote: HOT更新（n_tup_hot_upd），即一个元组的更新在同一block内，在所有更新（n_tup_upd）中占比很小。说明变长更新导致本来的原地更新，由于没有足够空位，变成了在其他block中异地更新。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 变长更新语句
  collection_layer: manual-business
  collection_method_quote: `[需确认业务] 对业务语句检查`
  abnormal_pattern_quote: 发现有很多变长更新的语句，如对某列更新为null之后，又更新为128长度char类型
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] autovacuum (ustore表的自动清理)
  param_name: autovacuum (ustore表的自动清理)
  abnormal_value_pattern: 不会清理用户表
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 变长更新导致本来的原地更新，由于没有足够空位，变成了在其他block中异地更新。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-tpcc-x38

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB某版本tpcc性能调优-绑核参数
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 在现有的出口参数线程池CPU亲和设置模式下会经常触发跨NUMA，导致内存访问导致延迟存在严重的不对称，在数据库中以进一步恶化OLTP瓶颈，numa间负载不均衡等问题。

### diagnostic_steps

```
[step 1]
  metric_name: thread_pool_attr
  collection_layer: db-shell
  collection_method_quote: `show thread_pool_attr;`
  abnormal_pattern_quote: 在现有的出口参数线程池CPU亲和设置模式下会经常触发跨NUMA
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] thread_pool_attr
  param_name: thread_pool_attr
  abnormal_value_pattern: '2048,2,(nobind)'
  recommended_value: '1024,4,(numabind:0-31,32-63,64-95,96-127)'
  recommendation_quote: 测试中将该参数由'2048,2,(nobind)'调优为'1024,4,(numabind:0-31,32-63,64-95,96-127)'。
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

```

## case_id: gaussdb-other-rpo-x39

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB异地容灾集群RPO达8000+秒
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 容灾集群RPO越来越高，当前显示8000+秒。

### diagnostic_steps

```
[step 1]
  metric_name: 容灾RPO
  collection_layer: db-system-view
  collection_method_quote: `select* from gs_hadr_remote_rto_and_rpo_stat();`
  abnormal_pattern_quote: 确实发现容灾RPO高
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 复制槽推动速度
  collection_layer: db-system-view
  collection_method_quote: `select * from dbe_perf.global_replication_stat;`
  abnormal_pattern_quote: 主集群产生的xlog速度，明显比接收的速度要快的多
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 网络带宽使用率
  collection_layer: manual-external
  collection_method_quote: `[需外部确认] 向客户方网络侧确认`
  abnormal_pattern_quote: 确实在异常时间段网络带宽占满
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 由于当前在TPCC性能压测，所以主集群产生的xlog数量较多，导致异地网络带宽打满
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-rto-x40

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB压测过程中备机RTO持续增高
- **diagnostic_steps_count**: 5
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 备 DN 的 RTO 持续升高（>1000s），未开启日志流控。

### diagnostic_steps

```
[step 1]
  metric_name: CPU使用率
  collection_layer: os
  collection_method_quote: `top -Hp <pid>`
  abnormal_pattern_quote: CPU使用率最高，约80%
  abnormal_pattern_threshold: 80%
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: IO相关等待事件平均时间
  collection_layer: db-system-view
  collection_method_quote: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
  abnormal_pattern_quote: 读取数据页面、读取wal日志等回放相关等待事件平均时间更长
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 磁盘IO性能和IO调度算法
  collection_layer: os
  collection_method_quote: `grep -H . /sys/block/*/queue/scheduler 2>/dev/null`
  abnormal_pattern_quote: 无明显区别
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: 线程CPU占用率
  collection_layer: os
  collection_method_quote: `top分析线程CPU占用`
  abnormal_pattern_quote: 问题节点某问题DN回放相关线程CPU占用率较低（相对于对照节点某对照DN），同时某问题DN整体CPU占用率也低于某对照DN
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 5]
  metric_name: xlog生成速率
  collection_layer: db-system-view
  collection_method_quote: `select * from dbe_perf.global_replication_stat;`
  abnormal_pattern_quote: 问题分片和对照分片的xlog生成速率不一致，差距约20%
  abnormal_pattern_threshold: 20%
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: RTO高现象在压测中仅发生在某问题DN所在机器的原因是压测负载不均衡以及数据倾斜，使得某问题DN问题机器CPU较高且需要回放的xlog量较多。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: 在高CPU压力负载下，如果xlog产生量过多，回放相关线程会遇到抢占不到CPU资源的情况，进而导致回放速度慢，RTO持续升高的现象。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-query-slow-sql-x42

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB统计信息缺失与并发更新同一行导致主键更新慢SQL
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 主键更新，平均调用时长1000ms+ UPDATE IB_XXX_LOG SET VOUCHERTYPE=?，...... WHERE （PR_SN=?）；

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
  abnormal_pattern_quote: 存在seq scan全表扫描导致耗时长（1000ms+）
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 锁等待事件
  collection_layer: db-system-view
  collection_method_quote: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
  abnormal_pattern_quote: 出现了并发更新
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 业务代码逻辑
  collection_layer: manual-business
  collection_method_quote: `[需确认业务] 排查业务代码发现主键更新语句的条件（主键）为单一固定值`
  abnormal_pattern_quote: 高并发压测时会出现并发更新等待事务锁和元组锁的现象
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 首次查询时可能缺乏准确或完整的统计信息，导致优化器没有生成最优的计划（index scan）
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: 主键更新语句的条件（主键）为单一固定值，高并发压测时会出现并发更新等待事务锁和元组锁的现象
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-disk-io-saturation-wal-x43

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB IO高及WAL日志生成量异常诊断
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> IO 饱和、磁盘读写量大；主 DN 持续快速产生 WAL（约 10GB/h），备 DN 在 Starting 阶段回放时间长。

### diagnostic_steps

```
[step 1]
  metric_name: WAL日志产生量
  collection_layer: log-grep
  collection_method_quote: `通过计算日志里的LSN节点可知`
  abnormal_pattern_quote: 故障演练期间主DN持续有WAL日志快速产生，约10GB/h
  abnormal_pattern_threshold: 10GB/h
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: WAL日志类型占比
  collection_layer: log-grep
  collection_method_quote: `对WAL日志分析可知`
  abnormal_pattern_quote: UBTree索引冻结事务号类型的WAL日志占比最大，超过50%，异常偏多
  abnormal_pattern_threshold: >50%
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: Freeze Page操作有效性
  collection_layer: log-grep
  collection_method_quote: `对产生的Freeze Page 类型WAL日志分析`
  abnormal_pattern_quote: 绝大部分的操作没有实际冻结任何一个事务号（nfrozen = 0），即这些WAL日志是无效的
  abnormal_pattern_threshold: nfrozen = 0
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: 磁盘读写线程
  collection_layer: db-system-view
  collection_method_quote: `识别磁盘读异常SQL(根据异常IO线程号查询pg_stat_activity + pg_thread_wait_status)`
  abnormal_pattern_quote: 磁盘读都是Vacuum操作 / 磁盘写主要是pagewriter线程
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 产生了无效的Freeze Page 类型WAL日志。对产生的Freeze Page 类型WAL日志分析，绝大部分的操作没有实际冻结任何一个事务号（nfrozen = 0），即这些WAL日志是无效的。 / AutoVacuum在分布式下DN执行时会走手动Vacuum逻辑，对于Ustore表会增加全表死元组清理，两个因素均增加了AutoVacuum的开销，以及增加了WAL日志产生量。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-autovacuum-x44

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB AutoVacuum清理Ustore分区表缓慢诊断
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> AutoVacuum Worker线程长时间清理一个Ustore分区表（总大小约122GB），12天未完成

### diagnostic_steps

```
[step 1]
  metric_name: 运行时堆栈
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] 检查运行时堆栈`
  abnormal_pattern_quote: 发现在清理该Ustore分区表上的其中一个GPI索引
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: gs_log日志清理时长
  collection_layer: log-grep
  collection_method_quote: `检查gs_log日志`
  abnormal_pattern_quote: 发现13天一直在清理第一个GPI索引
  abnormal_pattern_threshold: 13天
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: WAL日志清理模式
  collection_layer: log-grep
  collection_method_quote: `检查WAL日志`
  abnormal_pattern_quote: 发现Vacuum对索引页面按照页面号递增清理外，会按照叶子节点右链接折返清理叶子页面的现象 / 折返清理叶子页面提高了Vacuum清理索引的算法复杂度，接近O(n²)
  abnormal_pattern_threshold: O(n²)
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: Ustore配套的Vacuum索引并发分裂检测机制异常，遗漏清除并发分裂标记位造成冗余清理
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-ustore-x45

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: Ustore开启闪回特性下集中删除后SeqScan触发大事务查杀
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 3
- **source_url_lang**: zh-cn

### symptom_description

> Delete limit 1000操作因大事务被查杀

### diagnostic_steps

```
[step 1]
  metric_name: 事务日志内容
  collection_layer: db-interactive-cmd
  collection_method_quote: `使用gs_xlogdump_xid()系统函数获取被查杀事务对应的日志`
  abnormal_pattern_quote: 事务生成的日志中，全都是对heap进行WAL_UHEAP_CLEAN操作，并非元组删除操作。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: undo_retention_time
  collection_layer: db-system-view
  collection_method_quote: `show undo_retention_time;`
  abnormal_pattern_quote: 存在闪回窗口期内被垃圾元组无法回收清理，出现大量待整理的记录堆积
  abnormal_pattern_threshold: 900s
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 筛选条件有索引，但没走上索引，说明优化器评估SeqScan的代价比IndexScan更低
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] undo_retention_time
  param_name: undo_retention_time
  abnormal_value_pattern: 900s (开启闪回特性)
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: 数据在查询条件上存在严重的数据倾斜...测试配置错误，导致应用操作执行大量失败，t_app_log表中符合删除条件的数据量远远超出了不符合删除条件的数据。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: 目标表上采用相同的方式集中在短时间内对大量数据进行清理（Delete操作）。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-x47

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 打开文件句柄过多导致核心业务压测出现抖动
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 压力稳定下 TPS 概率性大幅下降。

### diagnostic_steps

```
[step 1]
  metric_name: cpu使用率
  collection_layer: os
  collection_method_quote: `top -Hp <pid>`
  abnormal_pattern_quote: tps下降时段cpu使用率升高
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: oncpu信息
  collection_layer: flamegraph
  collection_method_quote: `NULL`
  abnormal_pattern_quote: cpu主要消耗在事务提交时关闭文件操作
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 慢sql语句
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
  abnormal_pattern_quote: 找到commit语句，然后根据事务id找到对应事务的sql语句
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `手工explain计划如下`
  abnormal_pattern_quote: 通过TID SCAN更新一行记录遍历了289个分区
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 对包含GSI索引的表进行update操作时，会走Tid Scan的执行计划，而当前版本不支持动态分区裁剪，导致访问了所有分区。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: vfd当前实现每次commit时都大概率关闭本事务打开的所有物理fd，导致fd没有充分复用，系统频繁的open和close文件
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-cpu-high-jdbc-x48

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB应用JDBC建连超时及客户端CPU冲高诊断
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url_lang**: zh-cn

### symptom_description

> 客户端建连超时/失败，集中在三类场景：① 应用发布期大量建连；② 应用重启连接池瞬时大量建连；③ 跑批/压测并发量快速上升、应用侧 CPU 冲高。

### diagnostic_steps

```
[step 1]
  metric_name: 网络包时延
  collection_layer: manual-external
  collection_method_quote: `[需外部确认] 针对建连报错的应用环境上进行抓包`
  abnormal_pattern_quote: No.503的包在4s后才发出，这个包是向服务端发送加密后的密码，这个阶段耗时太高
  abnormal_pattern_threshold: 4s
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: CPU消耗分布
  collection_layer: flamegraph
  collection_method_quote: `NULL`
  abnormal_pattern_quote: 客户端大部分CPU消耗在密码迭代加密的流程上
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] loginTimeout
  param_name: loginTimeout
  abnormal_value_pattern: 6
  recommended_value: 30
  recommendation_quote: 提出了将loginTimeout=6修改到30的规避方案，降低建连超时的比例
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 密码加解密耗CPU资源高，原因是每次建连都要重新生成盐值和迭代计算导致大量建连场景CPU资源消耗比友商（Oracle）高不少
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: 进一步确认客户端环境是2C的容器环境，CPU资源紧缺
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-x49

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB容器化环境下lo网卡丢包告警
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 多套实例出现 lo 网卡网络丢包告警，业务量很小仍高频触发（高频实例约每半小时一次）。

### diagnostic_steps

```
[step 1]
  metric_name: dropped packets count
  collection_layer: db-shell
  collection_method_quote: `cat /proc/net/dev`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: rx_dropped call stack
  collection_layer: os
  collection_method_quote: `perf record -o perf_lo_drop.data -a -g -e mem:0xffff920fc37b31c8:w -- sleep 10`
  abnormal_pattern_quote: 调用栈数量也基本和ifconfig lo统计dropped的差值相同，所以只需分析以上调用栈即可。...实际晚上perf监控一晚发现所有lo的丢包都来自于avcworker。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: net.core.netdev_max_backlog
  collection_layer: os
  collection_method_quote: `sysctl net.core.netdev_max_backlog`
  abnormal_pattern_quote: qlen <= netdev_max_backlog为false的可能性最高，该参数是用来设置每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数配置为1000，但GaussDB数据库手册推荐值是65535。
  abnormal_pattern_threshold: 1000
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] net.core.netdev_max_backlog
  param_name: net.core.netdev_max_backlog
  abnormal_value_pattern: 1000
  recommended_value: 65535
  recommendation_quote: 需要将网卡队列参数net.core.netdev_max_backlog从1000修改成GaussDB推荐的65535解决。
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: GaussDB的的AVCworker线程定期执行打开大量的分区和本地索引，使大量的统计信息发生变化，在线程退出时需要更新大量的统计信息导致lo网卡队列满
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-rto-x50

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB 8C小规格备机并行回放与读冲突导致业务超时及极致RTO配置验证
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 读写分离架构下，备机读与并行回放存在冲突，数仓业务偶现超时失败；8C 小规格此前不建议开启极致 RTO（需更多线程）。

### diagnostic_steps

```
[step 1]
  metric_name: 备机CPU、主机CPU、内存使用率、IO、TPMC、Xlog回放速度、日志生成速度
  collection_layer: manual-business
  collection_method_quote: `[需确认业务] 8C规格极致RTO和并行回放对资源的消耗，跑TPCC数据量 70仓，70并发，分别测试极致RTO场景`
  abnormal_pattern_quote: 极致RTO配置三相比并行回放CPU和内存消耗高20%，且回放略有下降；配置三线程数量较多，资源争用严重，效果不太明显
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] recovery_parse_workers / recovery_redo_workers
  param_name: recovery_parse_workers / recovery_redo_workers
  abnormal_value_pattern: 并行回放参数设置：recovery_parse_workers=1，recovery_redo_workers=1，recovery_max_workers=4
  recommended_value: 极致RTO配置一：recovery_parse_workers = 1，recovery_redo_workers=2
  recommendation_quote: 8C规格下可以开启机制RTO，与业务方方讨论推荐使用配置一，避免日志生成速度超过备机回放极限速度
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 采用读写分离的架构，而当前备机读与并行回放存在诸多冲突
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-ustore-x51

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB Ustore单事务内多次更新Toast字段导致表膨胀
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 表数据仅几十万行，但死元组达 3600w+、表占用约 309GB（索引占用不大）；vacuum full 后回落、随后再次膨胀，膨胀主要发生在 toast 表。

### diagnostic_steps

```
[step 1]
  metric_name: 死元组数/表占用空间
  collection_layer: db-system-view
  collection_method_quote: `select relname, n_dead_tup, pg_relation_size(relid) sz from pg_stat_all_tables where relname='<表>';`
  abnormal_pattern_quote: 死元组3600w+，表占用309GB
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: toast表空间占用
  collection_layer: db-system-view
  collection_method_quote: `select pg_relation_size(reltoastrelid) from pg_class where relname='<表>';`
  abnormal_pattern_quote: 发现膨胀的主要再toast表上
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 列长度/事务更新频次
  collection_layer: manual-business
  collection_method_quote: `[需确认业务] NULL`
  abnormal_pattern_quote: 数据库的列长度超过2k字节会转为toast表存储，客户的该向量列是1024维度的floatvector，占用1024*4=4k字节，肯定发生转toast存储。业务上存在单个事务内大量update更新向量字段
  abnormal_pattern_threshold: 列长度>2k字节; 单事务内大量update
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 表中有大量toast字段且存在同一事务内多次更新，因当前Ustore不支持单个事务内的空间复用（功能上暂未实现），单事务内只有1条update语句不会存在这问题。当前USTORE在同一事务内更新数据的场景，先进行扩页让数据更新成功，优先保证业务快速执行，所以会存在空间上膨胀。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-lock-contention-commit-x52

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB事务Commit存在波动诊断
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 出现 commit 慢现象，慢 SQL 视图显示 wait xact commit command 等待耗时高。

### diagnostic_steps

```
[step 1]
  metric_name: wait xact commit command耗时
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
  abnormal_pattern_quote: wait xact commit command耗时较高
  abnormal_pattern_threshold: 1535511 (us)
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: palm_hang_detect_main等待锁日志
  collection_layer: log-grep
  collection_method_quote: `gaussdb-<日期>_180856.log.gz:<日期> 某时刻.054 dn_6007_6008_6009 [unkown] [unknown] localhost 281279935201968 0[0:0#0] 0 dn_6007 0 [BACKEND] WARNING: palm_hang_detect_main Cur time is 785847582052464, need_wait_time is 785847577052464, oldest_time is 785847564558141; wait_lock_type(4).`
  abnormal_pattern_quote: WARNING: palm_hang_detect_main Cur time is 785847582052464, need_wait_time is 785847577052464, oldest_time is 785847564558141; wait_lock_type(4).
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 通过分析数据库内核代码，找到是锁内部相关处理逻辑。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-query-slow-x53

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB千万笔交易偶现几十笔毛刺诊断
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 数千万笔毫秒级交易中偶现几十笔毛刺（抖动约 500ms）；慢 SQL 诊断视图显示 execution_time 异常增大。

### diagnostic_steps

```
[step 1]
  metric_name: execution_time
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
  abnormal_pattern_quote: execution_time过大
  abnormal_pattern_threshold: 583689 (us)
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: LWLOCK_EVENT ProcArrayLock等待事件
  collection_layer: db-system-view
  collection_method_quote: `Wait Events Area: ‘1’ LWLOCK_EVENT ProcArrayLock 11700 (us)`
  abnormal_pattern_quote: LWLOCK_EVENT ProcArrayLock 11700 (us)
  abnormal_pattern_threshold: 11700 (us)
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: unlink_half_dead_page索引日志
  collection_layer: log-grep
  collection_method_quote: `<日期> 某时刻.143 dn_6001_6002_6003 mecs mecs <IP> 281222782959760 375685[11206835某时刻7457#30802] 213523483 cn_5001 73183494132910882 [UBTREE] LOG: [unlink_half_dead_page:1386] IndexRnode:{16某时刻7某时刻227:-1} Xid:{213523483}. valid left sibling for deletion target could not be located: left sibling postmaster pool start, fd nums:4`
  abnormal_pattern_quote: valid left sibling for deletion target could not be located
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 相关相关团队分析代码，找到瓶颈点是在索引分裂相关逻辑。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-lock-contention-x54

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB轻量级锁防饿死机制误判导致性能抖动
- **diagnostic_steps_count**: 7
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 出现了不定时的性能抖动问题，导致部分关键业务处理延迟，批量出现业务端到端时延超 1 秒，甚至超过 3 秒的现象 commit有较为明显的性能波动，一天之内会发生多次超过1s的commit慢sql

### diagnostic_steps

```
[step 1]
  metric_name: 慢SQL等待事件统计
  collection_layer: db-system-view
  collection_method_quote: `select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;`
  abnormal_pattern_quote: 没有抓到长时间的等待事件
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: CPU、内存、IO使用率
  collection_layer: os
  collection_method_quote: `top -Hp <pid>`
  abnormal_pattern_quote: CPU、内存、IO 使用率均很低
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 轻量级锁排他锁等待时间日志
  collection_layer: log-grep
  collection_method_quote: `登录客户生产环境进行查询，确实找到了对应的日志打印`
  abnormal_pattern_quote: 日志中显示轻量级锁排他锁等待时间超过 5 秒
  abnormal_pattern_threshold: 5s
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: 轻量级锁持锁到放锁的时长
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] 统计轻量级锁持锁到放锁的时长`
  abnormal_pattern_quote: 并没有发现单个轻量级锁持锁时间过长的情况
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 5]
  metric_name: 持锁、等锁线程堆栈
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] 在一套生产环境部署了脚本，进行持锁、等锁线程堆栈的抓取`
  abnormal_pattern_quote: 所有抓到的持锁线程都是 checkpoint；一般来说，出现该warning日志时查询gs_lwlock_status系统函数都会出现等锁的现象，但是在日志打印的轻量级等锁时间段内，并没有发现持续等锁的线程堆栈
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 6]
  metric_name: 防饿死线程日志与慢SQL现象
  collection_layer: manual-business
  collection_method_quote: `[需确认业务] 对家里测试环境的 guc 参数进行了调整，加速了 checkpoint 的频率`
  abnormal_pattern_quote: 家里也复现出了防饿死线程的日志打印与慢 SQL 现象
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 7]
  metric_name: 慢SQL出现频率
  collection_layer: manual-business
  collection_method_quote: `[需确认业务] 观察关闭防饿死开关enable_wait_exclusive_lock 前后，问题出现频率`
  abnormal_pattern_quote: 启用防饿死机制时，稳定复现原问题；不启用防饿死机制时，稳定不出现原问题
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 用于保护事务日志并发读写的轻量级锁的最早等锁开始时间，具有概率性残留的问题，导致实际锁已获取，但后台防饿死检测线程误判锁饿死，导致其他线程无法及时拿到锁，进而影响事务提交阶段时延
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-x57

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 子查询内存在无用的窗口函数导致过滤条件无法触发索引扫描
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 其中p表在client_acnt_id上存在索引，但是发现过滤条件client_acnt_id = '1221'没有触发索引扫描

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze, verbose, buffers) <目标SQL>;`
  abnormal_pattern_quote: 过滤条件client_acnt_id = '1221'没有触发索引扫描
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 代码分析
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] 分析代码后发现`
  abnormal_pattern_quote: 主要是存在窗口函数 但是在sql语句中default_flag并没有使用
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 子查询内存在无用的窗口函数...但是在sql语句中default_flag并没有使用
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-union-x58

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: union all下cte无法自动内联导致恒为false的分支未被提前过滤
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 发现问题点，理论上恒为false的第二个union all并未被提前过滤掉

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain analyze select * from v_test1 where v_test.a = 10;`
  abnormal_pattern_quote: 理论上恒为false的第二个union all并未被提前过滤掉
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 代码定位
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] 定位发现`
  abnormal_pattern_quote: 若存在union all，cte 不会自动内联
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 若存在union all，cte 不会自动内联
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 目标列相关子查询无法提升，逐行触发子查询导致性能低下，intargetlist 参数转为 JOIN 提升性能
- **source_heading**: 目标列子查询提升参数intargetlist
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0224.html
- **source_url_lang**: zh-cn

### symptom_description

> 由于目标列中的相关子查询(select avg(c2) from t2 where t2.c2=t1.c2)无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。

### diagnostic_steps

```
[step 1]
  metric_name: explain verbose · SubPlan 执行方式
  collection_layer: db-interactive-cmd
  collection_method_quote: `yshen=# set rewrite_rule='none'; SET yshen=# explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;`
  abnormal_pattern_quote: `由于目标列中的相关子查询(select avg(c2) from t2 where t2.c2=t1.c2)无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 未包含 intargetlist，目标列相关子查询无法被提升转为 JOIN
  recommended_value: `intargetlist`
  recommendation_quote: `如果打开intargetlist参数会把子查询提升转为JOIN，来提升查询的性能`
  risk_if_violated_quote: `导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`
  reasoning_quote: `由于目标列中的相关子查询无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。如果打开intargetlist参数会把子查询提升转为JOIN，来提升查询的性能`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-plan-suboptimal-missing-analyze-dist-v8-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 未收集统计信息导致 GaussDB 分布式查询性能差（v8）
- **source_heading**: 实例分析1：未收集统计信息导致查询性能差
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0266.html
- **source_url_lang**: zh-cn

### symptom_description

> 在很多场景下，由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。

### diagnostic_steps

```
[step 1]
  metric_name: explain verbose WARNING · 统计信息缺失提示
  collection_layer: db-interactive-cmd
  collection_method_quote: `通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, ...) are not collected. HINT:Do analyze for them in order to generate optimized plan.`
  abnormal_pattern_quote: `WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected.`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `当通过以上方法查看到哪些表或列没有做analyze，可以通过对WARNING或日志中上报的表或列做analyze来解决由于未收集统计信息导致查询变慢的问题。`

```

## case_id: gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 多表 JOIN 中间结果估算不准，NestLoop 耗时 12s，改用 unlogged table + 禁 hashjoin 降至 3s
- **source_heading**: 实例分析2：多表join的复杂查询存在中间结果不准调优
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0266.html
- **source_url_lang**: zh-cn

### symptom_description

> 该查询实际耗时约12秒。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · Nest Loop Join 耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。`
  abnormal_pattern_quote: `该查询实际耗时约12秒。`
  abnormal_pattern_threshold: `> 12s`
  metric_unit: s
  prerequisite_steps: []

[step 2]
  metric_name: enable_hashjoin 关闭后执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `SET enable_hashjoin = off;`
  abnormal_pattern_quote: `分析上述执行计划，发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。`
  abnormal_pattern_threshold: NULL
  metric_unit: s
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] enable_hashjoin
  param_name: enable_hashjoin
  abnormal_value_pattern: 默认开启，导致优化器在小表与大表 JOIN 时选择了在大表上建 Hash Table 的计划
  recommended_value: `off` (当 temp_tsw 仅几百条记录、b_zyk_wbswxx 极大时临时关闭)
  recommendation_quote: `执行如下语句，将Join方式改为Nest Loop Join。SET enable_hashjoin = off;`
  risk_if_violated_quote: NULL
  reasoning_quote: `由于temp_tsw（上网人员信息）中仅包含几百条记录，且temp_tsw和b_zyk_wbswxx（网吧上网信息）均通过wbdm（网吧代码）执行等值连接。因此，如果Join方式改为Nest Loop Join，则扫描节点可以实现Index Scan，性能预计将会提升。`
  linked_diagnostic_step_no: 2

```

## case_id: gaussdb-query-slow-missing-analyze-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 未收集统计信息（analyze）导致查询性能差、执行计划选错
- **source_heading**: 实例分析1：未收集统计信息导致查询性能差
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0267.html
- **source_url_lang**: zh-cn

### symptom_description

> 在很多场景下，由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表
  collection_layer: db-interactive-cmd
  collection_method_quote: `通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan.`
  abnormal_pattern_quote: `Statistics in some tables or columns(...) are not collected.`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_log 日志 · Statistics not collected 日志行
  collection_layer: log-grep
  collection_method_quote: `可以通过在pg_log目录下的日志文件中查找以下信息来确认当前执行的query是否由于没有收集统计信息导致查询性能变差。`
  abnormal_pattern_quote: `LOG:Statistics in some tables or columns(...) are not collected.`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `当通过以上方法查看到哪些表或列没有做analyze，可以通过对WARNING或日志中上报的表或列做analyze来解决由于未收集统计信息导致查询变慢的问题。`

```

## case_id: gaussdb-query-slow-complex-join-intermediate-rows-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 多表 join 中间结果估算不准导致 Hash Join 建大 Hash Table、查询慢
- **source_heading**: 实例分析2：多表join的复杂查询存在中间结果不准调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0267.html
- **source_url_lang**: zh-cn

### symptom_description

> 查询与指定人在前后15分钟内、同一网吧登记上网的人员信息。该查询实际耗时约12秒。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · Join 算子类型及耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。`
  abnormal_pattern_quote: `分析上述执行计划，发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。`
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_hashjoin
  param_name: enable_hashjoin
  abnormal_value_pattern: on（默认），优化器选择 Hash Join 对大表建 Hash Table
  recommended_value: `off`（在 NestLoop 可利用索引扫描的场景下）
  recommendation_quote: `执行如下语句，将Join方式改为Nest Loop Join。SET enable_hashjoin = off;`
  risk_if_violated_quote: `发现执行了Hash Join，对大表b_zyk_wbswxx（网吧上网信息）建立了Hash Table。由于该表数据量大，创建过程耗时较长。`
  reasoning_quote: `由于temp_tsw（上网人员信息）中仅包含几百条记录，且temp_tsw和b_zyk_wbswxx（网吧上网信息）均通过wbdm（网吧代码）执行等值连接。因此，如果Join方式改为Nest Loop Join，则扫描节点可以实现Index Scan，性能预计将会提升。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-plan-suboptimal-seqscan-vs-indexscan-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: SeqScan 扫描过滤大量数据，点查场景应走 IndexScan
- **source_heading**: 示例1：基表扫描走 SeqScan 过滤大量数据
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0268.html
- **source_url_lang**: zh-cn

### symptom_description

> 基表扫描时，对于点查或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时

### diagnostic_steps

```
[step 1]
  metric_name: explain analyze · A-time / Rows Removed by Filter
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=#  explain (analyze on,costs off) select * from t1 where c2=10004;`
  abnormal_pattern_quote: `全表扫描返回5条数据，过滤掉大量数据，在c2列上建立索引后，使用IndexScan扫描效率显著提高，从20毫秒降低到3毫秒。`
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `基表扫描时，对于点查或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时，可以在条件列上建立索引选择IndexScan进行索引扫描提升扫描效率。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `gaussdb=#  create index idx on t1(c2);`

```

## case_id: gaussdb-plan-suboptimal-nestloop-large-outer-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 两表 JOIN 外表行数大时 NestLoop 耗时 5s，关闭 NestLoop+MergeJoin 改 HashJoin 降至 86ms
- **source_heading**: 示例2：NestLoop 外表行数大导致 JOIN 性能差
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0268.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果从执行计划中看，两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢。如下的例子中NestLoop耗时5秒

### diagnostic_steps

```
[step 1]
  metric_name: explain analyze · Nested Loop A-time
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=#  explain analyze select count(*) from t2,t1 where t1.c1=t2.c2;`
  abnormal_pattern_quote: `NestLoop耗时5秒，如果设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时降低至86毫秒。`
  abnormal_pattern_threshold: `NestLoop A-time > 5000ms`
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_nestloop
  param_name: enable_nestloop
  abnormal_value_pattern: 默认开启，在外表行数较大时导致选择 NestLoop
  recommended_value: `off` (与 enable_mergejoin=off 配合)
  recommendation_quote: `set enable_mergejoin=off; set enable_nestloop=off;`
  risk_if_violated_quote: NULL
  reasoning_quote: `如果从执行计划中看，两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢。`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] enable_mergejoin
  param_name: enable_mergejoin
  abnormal_value_pattern: 默认开启，干扰优化器选择 HashJoin
  recommended_value: `off`
  recommendation_quote: `set enable_mergejoin=off; set enable_nestloop=off;`
  risk_if_violated_quote: NULL
  reasoning_quote: `NestLoop耗时5秒，如果设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时降低至86毫秒。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 大结果集 Agg 走 Sort+GroupAgg 耗时长，关闭 Sort 改 HashAgg 性能提升
- **source_heading**: 示例3：Agg 选择 Sort+GroupAgg 耗时过长
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0268.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。

### diagnostic_steps

```
[step 1]
  metric_name: explain analyze · GroupAggregate A-time vs HashAggregate
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=#  explain analyze select count(*) from t1 group by c2;`
  abnormal_pattern_quote: `Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。`
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_sort
  param_name: enable_sort
  abnormal_value_pattern: 默认开启，大结果集时优化器选择 Sort+GroupAgg
  recommended_value: `off`
  recommendation_quote: `set enable_sort=off;`
  risk_if_violated_quote: NULL
  reasoning_quote: `通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-query-slow-correlated-subquery-target-list-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 目标列相关子查询未提升导致每行触发子查询、查询慢
- **source_heading**: 目标列子查询提升参数intargetlist
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0318.html
- **source_url_lang**: zh-cn

### symptom_description

> 由于目标列中的相关子查询（select avg(c2) from t2 where t2.c2=t1.c2）无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE · SubPlan 算子出现在目标列
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=# set rewrite_rule='none'; SET gaussdb=# explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;`
  abnormal_pattern_quote: `导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: none（未开启 intargetlist）
  recommended_value: `intargetlist`
  recommendation_quote: `如果打开intargetlist参数会把子查询提升转为JOIN，从而提升查询的性能。gaussdb=# set rewrite_rule='intargetlist';`
  risk_if_violated_quote: `导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。`
  reasoning_quote: `如果打开intargetlist参数会把子查询提升转为JOIN，从而提升查询的性能。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-savepoint-in-loop-resource-leak-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 循环内重复创建同名 SAVEPOINT 引发资源累积
- **source_heading**: 事务
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0058.html
- **source_url_lang**: zh-cn

### symptom_description

> 每次在事务中创建SAVEPOINT都会分配资源，若不及时释放，资源占用将逐渐累积。

### diagnostic_steps

```
[step 1]
  metric_name: 存储过程中 SAVEPOINT 的创建/释放配对
  collection_layer: db-shell
  collection_method_quote: 在使用完SAVEPOINT后，应及时使用RELEASE SAVEPOINT来释放资源。
  abnormal_pattern_quote: 同名的SAVEPOINT不会覆盖，而是会重新创建，这可能导致资源迅速累积。
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: COMMIT/ROLLBACK 频率与 I/O 开销
  collection_layer: db-shell
  collection_method_quote: 事务的COMMIT和ROLLBACK操作需要同步数据库的元数据和日志，频繁执行可能增加I/O开销，从而影响性能。
  abnormal_pattern_quote: 频繁执行可能增加I/O开销，从而影响性能。
  abnormal_pattern_threshold: NULL
  metric_unit: iops
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 每次在事务中创建SAVEPOINT都会分配资源，若不及时释放，资源占用将逐渐累积。
  linked_diagnostic_step_no: 1
  mitigation_quote: 避免在循环中创建SAVEPOINT，因为同名的SAVEPOINT不会覆盖，而是会重新创建，这可能导致资源迅速累积。

```

## case_id: gaussdb-seqscan-without-index-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 等值过滤无索引导致全表 Seq Scan 慢
- **source_heading**: 无索引和有索引性能对比
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0150.html
- **source_url_lang**: zh-cn

### symptom_description

> 从执行结果来看，执行时间需要382.624ms（全表扫描）。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE Seq Scan A-time / Total runtime
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE SELECT * FROM test_table WHERE email = 'user_500000@example.com';`
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: 创建 B-tree 索引后再次 EXPLAIN ANALYZE
  collection_layer: db-interactive-cmd
  collection_method_quote: 添加索引后，通过与无索引时执行计划的对比，查询时间从原来的382.624ms缩短到0.293 ms。
  abnormal_pattern_quote: 查询时间从原来的382.624ms缩短到0.293 ms。
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 添加索引后，通过与无索引时执行计划的对比，查询时间从原来的382.624ms缩短到0.293 ms。
  linked_diagnostic_step_no: 2
  mitigation_quote: `CREATE INDEX idx_test_table_email ON test_table(email);`

```

## case_id: gaussdb-query-slow-seqscan-index-missing-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 点查/范围扫描使用SeqScan全表扫描导致查询慢
- **source_heading**: 示例1：基表扫描点查使用SeqScan耗时
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0289.html
- **source_url_lang**: zh-cn

### symptom_description

> 基表扫描时，对于点查或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时，可以在条件列上建立索引选择IndexScan进行索引扫描提升扫描效率。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE A-time · SeqScan vs IndexScan
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=#  explain (analyze on, costs off) select * from t1 where c1=10004;`
  abnormal_pattern_quote: "全表扫描返回7条数据，过滤掉大量数据" (A-time: 2053.069ms, Rows Removed by Filter: 110000)
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "对于点查或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时，可以在条件列上建立索引选择IndexScan进行索引扫描提升扫描效率。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "在c1列上建立索引后，使用IndexScan扫描效率显著提高，从2秒降低到0.2毫秒。"

```

## case_id: gaussdb-query-slow-nestloop-hashjoin-02

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 两表Join选择NestLoop导致查询执行慢（大数据量场景）
- **source_heading**: 示例2：NestLoop Join大数据量场景耗时
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0289.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果从执行计划中看，两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢。如下的例子中NestLoop耗时27秒，如果设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时降低至2秒。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE A-time · NestLoop算子耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=#  explain analyze select count(*) from t1,t2 where t1.c1=t2.c2;`
  abnormal_pattern_quote: "NestLoop耗时27秒" (A-time: 27544.545ms for Nested Loop)
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_nestloop
  param_name: enable_nestloop
  abnormal_value_pattern: 默认开启，优化器选择了NestLoop
  recommended_value: `off`
  recommendation_quote: "如果设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时降低至2秒。"
  risk_if_violated_quote: "NestLoop耗时27秒"
  reasoning_quote: "如果从执行计划中看，两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-query-slow-groupagg-sort-03

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 大结果集聚合选择Sort+GroupAgg导致性能差
- **source_heading**: 示例3：大结果集使用Sort+GroupAgg性能差
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0289.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE A-time · Sort+GroupAgg vs HashAgg
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=#  explain analyze select count(*) from t1 group by c1;`
  abnormal_pattern_quote: "GroupAggregate A-time: 2417.004ms，Sort A-time: 2304.329ms，Peak Memory: 26466KB"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_sort
  param_name: enable_sort
  abnormal_value_pattern: 默认开启，导致优化器选择Sort+GroupAgg
  recommended_value: `off`
  recommendation_quote: "如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。"
  risk_if_violated_quote: "Sort+GroupAgg耗时2417ms，HashAgg耗时2324ms"
  reasoning_quote: "通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-query-slow-seqscan-no-index-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 点查或范围扫描选择SeqScan全表扫描导致查询慢
- **source_heading**: 算子级调优示例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0290.html
- **source_url_lang**: zh-cn

### symptom_description

> 基表扫描时，对于点查询或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE 执行计划 · 算子耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze on, costs off) select * from t1 where c1=10004;`
  abnormal_pattern_quote: "全表扫描返回7条数据，过滤掉大量数据"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "基表扫描时，对于点查询或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时，可以在条件列上建立索引选择IndexScan进行索引扫描提升扫描效率。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "create index idx on t1(c1); -- 建立索引后使用IndexScan扫描效率显著提高，从2秒降低到0.2毫秒。"

```

## case_id: gaussdb-query-slow-nestloop-large-rowset-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 两表Join选择NestLoop但实际行数大导致查询慢
- **source_heading**: 示例2
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0290.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果从执行计划中看，两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢。如下的例子中NestLoop耗时27秒

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE · NestLoop 算子耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain analyze select count(*) from t1,t2 where t1.c1=t2.c2;`
  abnormal_pattern_quote: "NestLoop耗时27秒"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_nestloop
  param_name: enable_nestloop
  abnormal_value_pattern: 默认on，导致优化器在行数估算偏小时选择NestLoop
  recommended_value: `off`
  recommendation_quote: "如果设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时降低至2秒。"
  risk_if_violated_quote: "如下的例子中NestLoop耗时27秒"
  reasoning_quote: "如果从执行计划中看，两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-query-slow-sort-groupagg-large-result-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 大结果集Agg选择Sort+GroupAgg导致查询慢
- **source_heading**: 示例3
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0290.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE · Sort+GroupAgg 算子耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain analyze select count(*) from t1 group by c1;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_sort
  param_name: enable_sort
  abnormal_value_pattern: 默认on，使优化器在某些场景错误选择Sort+GroupAgg
  recommended_value: `off`
  recommendation_quote: "如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时优于Sort+GroupAgg。"
  risk_if_violated_quote: NULL
  reasoning_quote: "通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-rewrite-lazyagg-double-aggregate-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 子查询与外层有相同GROUP BY时双层聚集运算效率低下
- **source_heading**: 消除子查询中的聚集运算参数lazyagg
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0318.html
- **source_url_lang**: zh-cn

### symptom_description

> 子查询与外层查询存在同样的group by条件，两层聚集运算可能导致查询效率低下

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划中双层HashAggregate
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=# EXPLAIN (costs off) SELECT t.c2, sum(cc) FROM (SELECT c2, sum(c3) AS cc FROM t1 GROUP BY c2) s1, t WHERE s1.c2=t.c2 GROUP BY t.c2 ORDER BY 1,2;`
  abnormal_pattern_quote: "Subquery Scan on s1 -> HashAggregate Group By Key: t1.c2 -> Seq Scan on t1"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 未包含lazyagg
  recommended_value: `lazyagg`
  recommendation_quote: "打开lazyagg参数，消除子查询中的聚集运算，提升查询性能"
  risk_if_violated_quote: NULL
  reasoning_quote: "子查询与外层查询存在同样的group by条件，两层聚集运算可能导致查询效率低下，打开lazyagg参数，消除子查询中的聚集运算，提升查询性能"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-partition-maxmin-fullscan-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 分区表 Max/Min 全分区扫描 + Sort 慢
- **source_heading**: Max/Min
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/fg-gaussdb-cent-v8/gaussdb-48-0084.html
- **source_url_lang**: zh-cn

### symptom_description

> 当对分区表使用Max/Min函数时，通常SQL引擎的实现方式是先通过Partition Iterator + PartitionScan对分区表做全量扫描然后进行Sort + Limit操作。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE Total runtime / 是否走 PartitionScan
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE SELECT min(b) FROM test_range_pt;`
  abnormal_pattern_quote: Partitioned Seq Scan on test_range_pt  (cost=0.00..139.00 rows=10000 width=4) (actual time=0.326..3.516 rows=10000 loops=5)
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: 创建 LOCAL 索引后 EXPLAIN ANALYZE Total runtime
  collection_layer: db-interactive-cmd
  collection_method_quote: `CREATE INDEX idx_range_b ON test_range_pt(b) LOCAL;`
  abnormal_pattern_quote: 优化后时间消耗远小于优化前。
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 如果分区是索引扫描，可以先对每个分区进行Limit操作，计算Max/Min值，最后在分区表上做Sort + Limit操作。这样分区表上做Sort时，由于每个分区已经获取Max/Min值，所以Sort的数据量跟分区数相同，这时极大的减少了Sort开销。
  linked_diagnostic_step_no: 2
  mitigation_quote: 当分区扫描路径为Index、Index Only时，才支持Max/Min优化。

```

## case_id: gaussdb-alert-thresholds-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB 指标告警配置建议 (CES 阈值基线)
- **source_heading**: 指标告警配置建议
- **diagnostic_steps_count**: 15
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb_practice_0071.html
- **source_url_lang**: zh-cn

### symptom_description

> 通过在云监控服务界面设置告警规则，用户可自定义监控目标与通知策略，及时了解实例的运行状况，从而起到预警作用。

### diagnostic_steps

```
[step 1]
  metric_name: rds001_cpu_util
  collection_layer: db-internal-counter
  collection_method_quote: CPU使用率
  abnormal_pattern_quote: 连续3个周期 原始值 > 80%
  abnormal_pattern_threshold: `> 80% sustained 3 cycles`
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: rds002_mem_util
  collection_layer: db-internal-counter
  collection_method_quote: 内存使用率
  abnormal_pattern_quote: 连续3个周期 原始值 > 90%
  abnormal_pattern_threshold: `> 90% sustained 3 cycles`
  metric_unit: %
  prerequisite_steps: []

[step 3]
  metric_name: io_bandwidth_usage
  collection_layer: db-internal-counter
  collection_method_quote: 磁盘io带宽占用率
  abnormal_pattern_quote: 连续3个周期 原始值 > 80%
  abnormal_pattern_threshold: `> 80% sustained 3 cycles`
  metric_unit: %
  prerequisite_steps: []

[step 4]
  metric_name: iops_usage
  collection_layer: db-internal-counter
  collection_method_quote: IOPS使用率
  abnormal_pattern_quote: 连续3个周期 原始值 > 80%
  abnormal_pattern_threshold: `> 80% sustained 3 cycles`
  metric_unit: %
  prerequisite_steps: []

[step 5]
  metric_name: rds007_instance_disk_usage
  collection_layer: db-internal-counter
  collection_method_quote: 实例数据磁盘已使用百分比
  abnormal_pattern_quote: 连续3个周期 原始值 > 75%（建议不能高于80%）
  abnormal_pattern_threshold: `> 75%`
  metric_unit: %
  prerequisite_steps: []

[step 6]
  metric_name: rds020_avg_disk_ms_per_write
  collection_layer: db-internal-counter
  collection_method_quote: 数据磁盘单次写入花费的时间
  abnormal_pattern_quote: 连续3个周期 原始值 > 8 ms
  abnormal_pattern_threshold: `> 8 ms`
  metric_unit: ms
  prerequisite_steps: []

[step 7]
  metric_name: rds021_avg_disk_ms_per_read
  collection_layer: db-internal-counter
  collection_method_quote: 数据磁盘单次读取花费的时间
  abnormal_pattern_quote: 连续3个周期 原始值 > 8 ms
  abnormal_pattern_threshold: `> 8 ms`
  metric_unit: ms
  prerequisite_steps: []

[step 8]
  metric_name: rds036_deadlocks
  collection_layer: db-internal-counter
  collection_method_quote: 死锁次数
  abnormal_pattern_quote: 连续3个周期 原始值 > 5 Counts
  abnormal_pattern_threshold: `> 5 Counts / period`
  metric_unit: count
  prerequisite_steps: []

[step 9]
  metric_name: rds048_P80
  collection_layer: db-internal-counter
  collection_method_quote: 80% SQL的响应时间
  abnormal_pattern_quote: 连续3个周期 原始值 > 10000000us
  abnormal_pattern_threshold: `> 10000000 us`
  metric_unit: us
  prerequisite_steps: []

[step 10]
  metric_name: rds049_P95
  collection_layer: db-internal-counter
  collection_method_quote: 95% SQL的响应时间
  abnormal_pattern_quote: 连续3个周期 原始值 > 15000000us
  abnormal_pattern_threshold: `> 15000000 us`
  metric_unit: us
  prerequisite_steps: []

[step 11]
  metric_name: rds060_long_running_transaction_exectime
  collection_layer: db-internal-counter
  collection_method_quote: 数据库最长事务的执行时长
  abnormal_pattern_quote: 连续3个周期 原始值 > 7200s（建议大于2小时手动kill掉，根据业务情况自行调整）
  abnormal_pattern_threshold: `> 7200s`
  metric_unit: s
  prerequisite_steps: []

[step 12]
  metric_name: rds063_slowquery_user
  collection_layer: db-internal-counter
  collection_method_quote: 用户库慢SQL数量
  abnormal_pattern_quote: 连续3个周期 原始值 > 15 Counts
  abnormal_pattern_threshold: `> 15 Counts / period`
  metric_unit: count
  prerequisite_steps: []

[step 13]
  metric_name: rds065_dynamic_used_memory_usage
  collection_layer: db-internal-counter
  collection_method_quote: 动态内存使用率
  abnormal_pattern_quote: 连续3个周期 原始值 > 80%
  abnormal_pattern_threshold: `> 80%`
  metric_unit: %
  prerequisite_steps: []

[step 14]
  metric_name: rds066_replication_slot_wal_log_size
  collection_layer: db-internal-counter
  collection_method_quote: 复制槽保留的WAL日志大小
  abnormal_pattern_quote: 连续3个周期 原始值 > [磁盘大小的10%] Byte（客户基于购买的磁盘大小动态调整，建议10%）
  abnormal_pattern_threshold: `> 10% of disk size`
  metric_unit: bytes
  prerequisite_steps: []

[step 15]
  metric_name: rds070_thread_pool
  collection_layer: db-internal-counter
  collection_method_quote: 线程池使用率
  abnormal_pattern_quote: 连续3个周期 原始值 > 85%
  abnormal_pattern_threshold: `> 85%`
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 是否触发告警取决于连续周期的数据是否达到阈值。例如CPU使用率监控周期为5分钟，连续三个周期平均值≥80%，则触发告警。
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-anti-join-row-estimate-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: Anti Join 自连接行数估算不准导致查询性能下降
- **source_heading**: 案例：设置cost_param对查询性能优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0216.html
- **source_url_lang**: zh-cn

### symptom_description

> 当使用cost_param的bit0为0时，估算Anti Join的行数与实际行数相差很大，导致查询性能下降

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE Anti Join 行数估算
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain verbose`
  abnormal_pattern_quote: 估算Anti Join的行数与实际行数相差很大
  abnormal_pattern_threshold: NULL
  metric_unit: rows
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] cost_param
  param_name: cost_param
  abnormal_value_pattern: bit0 为 0，Anti Join 自连接估算不准
  recommended_value: `1` (bit0=1)
  recommendation_quote: 可以通过设置cost_param的bit0为1时，使Anti Join的行数估算更准确，从而提高查询性能
  risk_if_violated_quote: 当使用cost_param的bit0为0时，估算Anti Join的行数与实际行数相差很大，导致查询性能下降
  reasoning_quote: cost_param的bit0(set cost_param=1)值为1时，表示对于求由不等式（!=）条件连接的选择率时选择一种改良机制，此方法在自连接（两个相同的表之间连接）的估算中更加准确
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-plan-suboptimal-correlated-filter-selectivity-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 多列强相关过滤条件选择率用乘积估算导致行数不准
- **source_heading**: 案例：设置cost_param对查询性能优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0216.html
- **source_url_lang**: zh-cn

### symptom_description

> 当cost_param的bit1(set cost_param=2)为1时，表示求多个过滤条件（Filter）的选择率时，选择最小的作为总的选择率，而非两者乘积，此方法在过滤条件的列之间关联性较强时估算更加准确

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE hashjoin 行数估算
  collection_layer: db-interactive-cmd
  collection_method_quote: `set cost_param=2; explain verbose`
  abnormal_pattern_quote: 实际是将AND的两个过滤条件分别计算的2个选择率的值相乘来得到hashjoin条件的选择率，导致行数估算不准确，查询性能较差
  abnormal_pattern_threshold: NULL
  metric_unit: rows
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] cost_param
  param_name: cost_param
  abnormal_value_pattern: bit1 为 0，强相关列选择率乘积估算不准
  recommended_value: `2` (bit1=1)
  recommendation_quote: 所以需要将cost_param的bit1为1时，选择最小的选择率作为总的选择率估算行数比较准确，查询性能较好
  risk_if_violated_quote: 导致行数估算不准确，查询性能较差
  reasoning_quote: 此方法在过滤条件的列之间关联性较强时估算更加准确
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-cpu-saturated-by-slowsql-06

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: DB 节点 CPU 持续满载,gsql 进程占用率高
- **source_heading**: 案例 3：慢查询导致的CPU资源争用
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://blog.csdn.net/GaussDB/article/details/146009597
- **source_url_lang**: zh-cn

### symptom_description

> 数据库节点CPU持续满载，top 命令显示 gsql 进程占用率高。

### diagnostic_steps

```
[step 1]
  metric_name: top · gsql 进程 CPU 占用
  collection_layer: os
  collection_method_quote: `top 命令显示 gsql 进程占用率高`
  abnormal_pattern_quote: `数据库节点CPU持续满载，top 命令显示 gsql 进程占用率高`
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: pg_stat_statements · total_time + calls (慢查询统计)
  collection_layer: db-system-view
  abnormal_pattern_quote: `total_time > 1000 AND calls > 10`
  abnormal_pattern_threshold: `total_time > 1000 AND calls > 10`
  metric_unit: ms / count
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `发现某聚合查询未命中索引，改用物化视图或添加复合索引`
  linked_diagnostic_step_no: 2
  mitigation_quote: `CREATE INDEX idx_sales_product ON sales(product_id, sale_date);`

```

## case_id: gaussdb-groupagg-sort-vs-hashagg-08

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GROUP BY 计划走 GroupAgg+Sort 而非 HashAgg 导致性能差
- **source_heading**: 选择hashagg
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0013.html
- **source_url_lang**: zh-cn

### symptom_description

> 查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · 算子(GroupAgg+Sort)
  collection_layer: db-interactive-cmd
  collection_method_quote: `计划中包含GroupAgg+Sort算子`
  abnormal_pattern_quote: `计划中包含GroupAgg+Sort算子，导致性能较差`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] work_mem
  param_name: work_mem
  abnormal_value_pattern: 设值过小,无法支持 HashAgg 所需 in-memory hash table
  recommended_value: `增大(具体值联系管理员)`
  recommendation_quote: `可以通过设置GUC参数work_mem增大可用内存，生成带有HashAgg的计划（Plan）避免排序操作从而提升性能。work_mem设置请联系管理员。`
  risk_if_violated_quote: `可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差`
  reasoning_quote: `可以通过设置GUC参数work_mem增大可用内存，生成带有HashAgg的计划（Plan）避免排序操作从而提升性能`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-query-slow-join-null-values-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: JOIN 列存在大量 NULL 值导致顺序扫描耗时过长
- **source_heading**: 案例：增加JOIN列非空条件
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0214.html
- **source_url_lang**: zh-cn

### symptom_description

> 分析执行计划可知，在顺序扫描阶段耗时较多。多表JOIN中，由于表PS.SDR_WEB_BSCRNC_1DAY的JOIN列"BSCRNC_ID"存在大量空值，JOIN性能差

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE 顺序扫描耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN`
  abnormal_pattern_quote: 在顺序扫描阶段耗时较多
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 由于表PS.SDR_WEB_BSCRNC_1DAY的JOIN列"BSCRNC_ID"存在大量空值，JOIN性能差
  linked_diagnostic_step_no: 1
  mitigation_quote: 建议在语句中手动添加JOIN列的非空判断

```

## case_id: gaussdb-missing-index-multi-join-05

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 多表 JOIN 中缺少连接列索引导致点查询走 seqscan
- **source_heading**: 一、建立合适的索引 · 2
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://blog.csdn.net/GaussDB/article/details/136251205
- **source_url_lang**: zh-cn

### symptom_description

> 在优化前，没有创建places.place_id和states.state_id索引

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · 算子(seqscan vs indexscan)
  collection_layer: db-interactive-cmd
  collection_method_quote: `在优化前，没有创建places.place_id和states.state_id索引，执行计划如下`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `在优化前，没有创建places.place_id和states.state_id索引`
  linked_diagnostic_step_no: 1
  mitigation_quote: `建议在places.place_id和states.state_id列上建立2个索引`

```

## case_id: gaussdb-query-slow-nestloop-any-clause-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: any-clause 导致不等值 Join 走 NestLoop，大数据量超 1 小时未返回
- **source_heading**: 案例：改写SQL消除in-clause
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0223.html
- **source_url_lang**: zh-cn

### symptom_description

> 测试发现由于两表结果集过大，导致nestloop耗时过长，超过一小时未返回结果

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 Join 类型
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN`
  abnormal_pattern_quote: join-condition实质上是一个不等式，这种不等值的join操作必须走nestloop
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: join-condition实质上是一个不等式，这种不等值的join操作必须走nestloop，对应执行计划如下
  linked_diagnostic_step_no: 1
  mitigation_quote: 性能优化的关键是消除nestloop，让join走更高效的hashjoin。从语义等价的角度消除any-clause

```

## case_id: gaussdb-plan-suboptimal-seqscan-no-index-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 全表顺序扫描过滤大量数据导致查询慢
- **source_heading**: 算子级调优示例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0189.html
- **source_url_lang**: zh-cn

### symptom_description

> 基表扫描时，对于点查或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE 执行计划耗时与过滤行数
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze on, costs off) select * from store_sales where ss_sold_date_sk = 2450944;`
  abnormal_pattern_quote: `Rows Removed by Filter: 4968936`
  abnormal_pattern_threshold: 过滤行数数量级远大于返回行数
  metric_unit: rows
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 在ss_sold_date_sk列上建立索引后，使用IndexScan扫描效率显著提高，从3.6秒提升到13毫秒
  linked_diagnostic_step_no: 1
  mitigation_quote: 可以在条件列上建立索引选择IndexScan进行索引扫描提升扫描效率

```

## case_id: gaussdb-plan-suboptimal-nestloop-large-table-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 大表 Join 使用 NestLoop 导致查询极慢
- **source_heading**: 算子级调优示例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0189.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果从执行计划中看，两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢。如下的例子中NestLoop耗时181秒

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE Join 算子类型与耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE`
  abnormal_pattern_quote: NestLoop耗时181秒
  abnormal_pattern_threshold: `> 100s`
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_nestloop
  param_name: enable_nestloop
  abnormal_value_pattern: 默认开启，大行数场景不优
  recommended_value: `off`
  recommendation_quote: 如果设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时提升至200多毫秒
  risk_if_violated_quote: NestLoop耗时181秒
  reasoning_quote: 如果设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时提升至200多毫秒
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] enable_mergejoin
  param_name: enable_mergejoin
  abnormal_value_pattern: 默认开启，大行数场景选 Merge Join 不优
  recommended_value: `off`
  recommendation_quote: 设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin
  risk_if_violated_quote: NULL
  reasoning_quote: 设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时提升至200多毫秒
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-plan-suboptimal-groupagg-sort-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GROUP BY 生成 Sort+GroupAgg 导致查询慢
- **source_heading**: 算子级调优示例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0189.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时明显优于Sort+GroupAgg

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE Agg 算子类型
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE`
  abnormal_pattern_quote: 如果大结果集选择了Sort+GroupAgg
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_sort
  param_name: enable_sort
  abnormal_value_pattern: 默认开启导致大结果集选择 Sort+GroupAgg
  recommended_value: `off`
  recommendation_quote: 则需要设置enable_sort=off，HashAgg耗时明显优于Sort+GroupAgg
  risk_if_violated_quote: 如果大结果集选择了Sort+GroupAgg
  reasoning_quote: 则需要设置enable_sort=off，HashAgg耗时明显优于Sort+GroupAgg
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-overall-slow-io-await-high-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: I/O 满或 await 高导致整体性能慢
- **source_heading**: I/O满或者I/O异常
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 3
- **source_url**: https://blog.csdn.net/GaussDB/article/details/131321486
- **source_url_lang**: zh-cn

### symptom_description

> 表现为iostat内%util满、或者r_await较高（一般大于3ms）、或者w_await较高（一般大于3ms）。

### diagnostic_steps

```
[step 1]
  metric_name: iostat 中 %util / r_await / w_await
  collection_layer: os
  collection_method_quote: "iostat"
  abnormal_pattern_quote: "表现为iostat内%util满、或者r_await较高（一般大于3ms）、或者w_await较高（一般大于3ms）。"
  abnormal_pattern_threshold: "%util 接近 100% 或 await > 3ms"
  metric_unit: % / ms
  prerequisite_steps: []

[step 2]
  metric_name: pidstat / iotop 显示线程 I/O 消耗
  collection_layer: os
  collection_method_quote: "pidstat -dt -p gaussdb进程号"
  abnormal_pattern_quote: "通常是TPLworker线程消耗的I/O读写量异常，代表用户SQL消耗I/O多"
  abnormal_pattern_threshold: NULL
  metric_unit: KB/s
  prerequisite_steps: [1]

[step 3]
  metric_name: pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL
  collection_layer: db-system-view
  collection_method_quote: "通过查询pg_thread_wait_status视图的lwtid为上一步内的TID，获取对应的tid和sessionid。"
  abnormal_pattern_quote: "查询pg_stat_activity视图内记录满足pid/sessionid为上一步内的tid/sessionid,即可找到造成I/O高的session信息，包括具体的语句。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [2]

```

### likely_causes

```
[non_parameter_causes · cause 1] hardware-disk
  cause_type: hardware-disk
  description_quote: "硬盘cache/raid写策略配置问题。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "可联系操作系统相关同事分析"

[non_parameter_causes · cause 2] hardware-disk
  cause_type: hardware-disk
  description_quote: "磁盘带宽被限流（OBS本身有流控）。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "对于I/O量一直很大，如果是用户语句导致，也可参照IO高进行处理。"
  linked_diagnostic_step_no: 3
  mitigation_quote: "单独去优化相关Query，减少I/O量"

```

## case_id: gaussdb-overall-slow-cpu-high-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: gaussdb 进程 CPU 占用高导致整体性能慢
- **source_heading**: CPU满
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://blog.csdn.net/GaussDB/article/details/131321486
- **source_url_lang**: zh-cn

### symptom_description

> 找到CPU使用率高的进程，如果是数据库导致的CPU异常，通常预期是gaussdb进程占用较高。

### diagnostic_steps

```
[step 1]
  metric_name: top / sar 中 gaussdb 进程 CPU 占用
  collection_layer: os
  collection_method_quote: "$ top"
  abnormal_pattern_quote: "10678 Ruby      20   0   54.8g  38.2g  34.6g S  1398 20.3 126085:50 gaussdb"
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: WDR 报告 Top SQL order by CPU Time
  collection_layer: db-system-view
  collection_method_quote: "可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句"
  abnormal_pattern_quote: "如果CPU一直较高，方法一：可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

[step 3]
  metric_name: 内核代码热点函数火焰图
  collection_layer: flamegraph
  collection_method_quote: "如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点"
  abnormal_pattern_quote: "如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点"
  abnormal_pattern_threshold: NULL
  metric_unit: sample ratio
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "如果CPU一直较高，方法一：可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句"
  linked_diagnostic_step_no: 2
  mitigation_quote: "可参考后续文章WDR报告分析；方法二：按照CPU高进行分析。"

```

## case_id: gaussdb-overall-slow-config-shared-buffers-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 数据库配置不优 (shared_buffers / work_mem / thread_pool_attr) 导致整体性能慢
- **source_heading**: 数据库配置问题
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://blog.csdn.net/GaussDB/article/details/131321486
- **source_url_lang**: zh-cn

### symptom_description

> 正常情况下，客户环境上面的GUC配置是默认较优的，一般不需要特别调整。但某一些情况下，可能未使用默认配置或者客户环境有些微调的地方。

### diagnostic_steps

```
[step 1]
  metric_name: GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值
  collection_layer: db-system-view
  collection_method_quote: "常见的可能情况有：1. shared_buffers配置过小，导致buffer淘汰频繁。"
  abnormal_pattern_quote: "shared_buffers配置过小，导致buffer淘汰频繁。"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] shared_buffers
  param_name: shared_buffers
  abnormal_value_pattern: 配置过小,导致 buffer 淘汰频繁
  recommended_value: NULL (按业务情况调大)
  recommendation_quote: NULL
  risk_if_violated_quote: "shared_buffers配置过小，导致buffer淘汰频繁。"
  reasoning_quote: "shared_buffers配置过小，导致buffer淘汰频繁。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] work_mem
  param_name: work_mem
  abnormal_value_pattern: 排序等算子可使用的 work_mem 过小,导致异常下盘过多
  recommended_value: 根据业务情况适当调大
  recommendation_quote: "排序等算子可使用的work_mem过小，导致异常下盘过多，建议根据业务情况适当优化。"
  risk_if_violated_quote: "排序等算子可使用的work_mem过小，导致异常下盘过多"
  reasoning_quote: "排序等算子可使用的work_mem过小，导致异常下盘过多"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] thread_pool_attr
  param_name: thread_pool_attr
  abnormal_value_pattern: 线程池 worker 参数设置过小,导致业务排队
  recommended_value: NULL (按业务规模调大)
  recommendation_quote: "线程池worker参数thread_pool_attr设置过小，导致业务排队。"
  risk_if_violated_quote: "线程池worker参数thread_pool_attr设置过小，导致业务排队。"
  reasoning_quote: "线程池worker参数thread_pool_attr设置过小，导致业务排队。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-package-variable-session-memory-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: PACKAGE变量大量缓存可能占用大量内存
- **source_heading**: PACKAGE变量
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0053.html
- **source_url_lang**: zh-cn

### symptom_description

> 大量PACKAGE变量在SESSION中缓存可能占用大量内存。

### diagnostic_steps

```
[step 1]
  metric_name: SESSION 中 PACKAGE 变量数量与内存占用
  collection_layer: db-shell
  collection_method_quote: "PACKAGE变量是在PACKAGE内定义的全局变量，其生命周期覆盖整个数据库会话（SESSION）。"
  abnormal_pattern_quote: "大量PACKAGE变量在SESSION中缓存可能占用大量内存。"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "由于PACKAGE变量的生命周期为SESSION级别，不当操作可能造成数据残留，影响其他存储过程。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "建议谨慎使用PACKAGE变量，并确保其访问和生命周期得到合理管理。"

```

## case_id: gaussdb-query-slow-partition-pruning-disabled-function-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 分区表过滤条件含非常量表达式，分区剪枝失效，全表扫描耗时 135s
- **source_heading**: 案例：改写SQL排除剪枝干扰
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0222.html
- **source_url_lang**: zh-cn

### symptom_description

> 测试结果显示此SQL的表Scan耗时长达135s。初步猜测可能是性能瓶颈点

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 Filter 条件分析
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN`
  abnormal_pattern_quote: Filter条件中存在表达式to_char(add_months(to_date(''20170222'','yyyymmdd'), -11),'yyyymm')，这种非常量的表达式是不能用来剪枝的
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_proc 函数 volatility 类型查询
  collection_layer: db-system-view
  collection_method_quote: `查询pg_proc`
  abnormal_pattern_quote: 查询pg_proc发现此处的to_date和to_char均为stable类型的函数，根据数据库对函数行为的约定，此类函数不能在预处理阶段转化为Const值
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 查询pg_proc发现此处的to_date和to_char均为stable类型的函数，根据数据库对函数行为的约定，此类函数不能在预处理阶段转化为Const值，这也是不能导致分区剪枝的根本原因
  linked_diagnostic_step_no: 2
  mitigation_quote: 改写之后，SQL执行时间从135s提升至18s

```

## case_id: gaussdb-procedure-exception-frequent-perf-degrade-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 存储过程频繁捕获和处理异常导致性能下降
- **source_heading**: 异常处理
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0058.html
- **source_url_lang**: zh-cn

### symptom_description

> 在存储过程中使用EXCEPTION处理机制可以提高代码的容错性，但频繁地捕获和处理异常可能会导致性能下降。

### diagnostic_steps

```
[step 1]
  metric_name: 存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销
  collection_layer: db-shell
  collection_method_quote: "每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。"
  abnormal_pattern_quote: "频繁地捕获和处理异常可能会导致性能下降。每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "频繁地捕获和处理异常可能会导致性能下降。每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。此外，由于异常被捕获，日志中不会记录错误信息，从而增加了问题定位的难度。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "建议在必要时才使用EXCEPTION处理机制，并确保传递充足的上下文信息，以便于问题的定位和解决。"

```

## case_id: gaussdb-procedure-security-definer-permission-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 存储过程权限模式选择不当导致越权或被拒访问
- **source_heading**: 权限控制
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0051.html
- **source_url_lang**: zh-cn

### symptom_description

> 选择不当的权限模式可能导致越权访问敏感数据，或进行未授权的资源操作。

### diagnostic_steps

```
[step 1]
  metric_name: 存储过程默认权限模式
  collection_layer: db-shell
  collection_method_quote: "存储过程默认具有SECURITYINVOKER权限。"
  abnormal_pattern_quote: "切换test_user2执行test_user1创建的存储过程，执行报错，对表user1_tb没有权限，因为执行存储过程默认使用调用者的权限。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] behavior_compat_options
  param_name: behavior_compat_options
  abnormal_value_pattern: 默认未设置 'plsql_security_definer'，存储过程使用调用者权限
  recommended_value: `'plsql_security_definer'` (当需要默认使用创建者权限时)
  recommendation_quote: "如果希望将默认行为改为SECURITYDEFINER权限，需要设置GUC参数 behavior_compat_options='plsql_security_definer'。"
  risk_if_violated_quote: "选择不当的权限模式可能导致越权访问敏感数据，或进行未授权的资源操作。"
  reasoning_quote: "存储过程默认具有SECURITYINVOKER权限。如果希望将默认行为改为SECURITYDEFINER权限，需要设置GUC参数 behavior_compat_options='plsql_security_definer'。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "选择不当的权限模式可能导致越权访问敏感数据，或进行未授权的资源操作。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "应谨慎选择和配置权限模式，以确保系统的安全性。"

```

## case_id: gaussdb-query-slow-scan-no-local-cluster-key-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 表 Scan 为性能瓶颈，过滤列无局部聚簇键
- **source_heading**: 案例：调整局部聚簇键
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0218.html
- **source_url_lang**: zh-cn

### symptom_description

> 某局点EXPLAIN PERFORMANCE信息如下。分析发现如图红框标识的两个性能瓶颈点均为表Scan动作

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE 算子耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE`
  abnormal_pattern_quote: 分析发现如图红框标识的两个性能瓶颈点均为表Scan动作
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: Scan filter 条件分析
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE`
  abnormal_pattern_quote: 进一步分析表Scan的filter条件发现两个表存在acct_id = 'A012709548'::bpchar这样的filter条件
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 两个表存在acct_id = 'A012709548'::bpchar这样的filter条件
  linked_diagnostic_step_no: 2
  mitigation_quote: 试着给两个表的acct_id列增加局部聚簇键，然后对两张表执行VACUUM FULL，使局部聚簇生效。调整后性能得到提升

```

## case_id: gaussdb-group-by-sort-perf-work-mem-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GROUP BY 产生 Sort 算子时通过增大 work_mem 生成 HashAgg 提升性能
- **source_heading**: 选择hashagg。
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0013.html
- **source_url_lang**: zh-cn

### symptom_description

> 查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。

### diagnostic_steps

```
[step 1]
  metric_name: GROUP BY 查询计划中是否包含 GroupAgg+Sort
  collection_layer: db-interactive-cmd
  collection_method_quote: "查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。"
  abnormal_pattern_quote: "查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] work_mem
  param_name: work_mem
  abnormal_value_pattern: 不足以容纳 hash table，导致优化器选择 GroupAgg+Sort
  recommended_value: 调大以容纳 HashAgg 所需内存
  recommendation_quote: "可以通过设置GUC参数work_mem增大可用内存，生成带有HashAgg的计划（Plan）避免排序操作从而提升性能。"
  risk_if_violated_quote: "导致性能较差。"
  reasoning_quote: "可以通过设置GUC参数work_mem增大可用内存，生成带有HashAgg的计划（Plan）避免排序操作从而提升性能。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-not-in-to-not-exists-rewrite-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: NOT IN 转换为 NOT EXISTS 通过 Hash Anti Join 提升查询效率
- **source_heading**: NOT IN转NOT EXISTS
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0013.html
- **source_url_lang**: zh-cn

### symptom_description

> NOT IN语句需要使用NESTLOOP ANTI JOIN来实现，而NOT EXISTS则可以通过HASH ANTI JOIN来实现。

### diagnostic_steps

```
[step 1]
  metric_name: 含 NOT IN 子查询的执行计划
  collection_layer: db-interactive-cmd
  collection_method_quote: "gaussdb=# EXPLAIN SELECT * FROM t1 WHERE c1 NOT IN (SELECT d2 FROM t2);"
  abnormal_pattern_quote: "NOT IN语句需要使用NESTLOOP ANTI JOIN来实现"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "在JOIN列不存在NULL值的情况下，NOT EXISTS和NOT IN等价。因此在确保没有NULL值时，可以通过将NOT IN转换为NOT EXISTS，通过生成HASH JOIN来提升查询效率。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "因为t2.d2字段中没有NULL值（t2.d2字段在表定义中为NOT NULL），所以查询可以等价修改如下："

```

## case_id: gaussdb-stale-stats-hint-fix-09

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 高频数据变化表统计信息滞后导致计划选择不优
- **source_heading**: 对于高频数据变化的表，在相关SQL语句中添加Hint，以固定执行计划
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0013.html
- **source_url_lang**: zh-cn

### symptom_description

> 高频数据变化的表可能在触发自动ANALYZE之前出现统计信息不是最新的情况，从而导致执行计划选择不优。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · 计划与实际行数比对
  collection_layer: db-interactive-cmd
  collection_method_quote: `导致执行计划选择不优`
  abnormal_pattern_quote: `统计信息不是最新的情况`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `高频数据变化的表可能在触发自动ANALYZE之前出现统计信息不是最新的情况，从而导致执行计划选择不优。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `建议通过在相关SQL中添加Hint来固定执行计划。`

```

## case_id: gaussdb-replica-lag-redo-workers-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: GaussDB业务压力大时备DN回放速度跟不上主DN，日志累积影响RTO
- **source_heading**: 当业务压力过大时，备DN的回放速度跟不上主DN的速度如何处理
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/gaussdb_faq/gaussdb_01_401.html
- **source_url_lang**: zh-cn

### symptom_description

> 当业务压力过大时，备DN的回放速度跟不上主DN的速度。在系统长时间的运行后，备DN上会出现日志累积。当主DN故障后，数据恢复需要很长时间，数据库不可用，严重影响系统可用性。

### diagnostic_steps

```
[step 1]
  metric_name: 备DN CPU使用率 · 回放线程资源
  collection_layer: os
  collection_method_quote: "极致RTO采用了多个page redo线程并行加速回放进度。当备DN回放追平主DN，空载的情况下，单个page redo线程的CPU消耗大约在15%左右（实际值与具体硬件和参数配置相关），备DN回放的总CPU消耗值 = 单个page redo线程的CPU消耗值 x page redo线程数。"
  abnormal_pattern_quote: "当节点的I/O和CPU使用过高时（建议不超过70%），回放和备机读性能会有明显下降。"
  abnormal_pattern_threshold: `> 70%`
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] recovery_parse_workers
  param_name: recovery_parse_workers
  abnormal_value_pattern: 未开启极致RTO，回放并行度低
  recommended_value: NULL
  recommendation_quote: "如需使用极致RTO能力，您可以通过控制台界面修改参数recovery_parse_workers和recovery_redo_workers的值以开启极致RTO"
  risk_if_violated_quote: "在系统长时间的运行后，备DN上会出现日志累积。当主DN故障后，数据恢复需要很长时间，数据库不可用，严重影响系统可用性。"
  reasoning_quote: "GaussDB提供极致RTO能力，开启极致RTO（Recovery Time Object，恢复时间目标），可以减少主DN故障后数据的恢复时间，提高了可用性。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] recovery_redo_workers
  param_name: recovery_redo_workers
  abnormal_value_pattern: 未开启极致RTO，回放并行度低
  recommended_value: NULL
  recommendation_quote: "如需使用极致RTO能力，您可以通过控制台界面修改参数recovery_parse_workers和recovery_redo_workers的值以开启极致RTO"
  risk_if_violated_quote: "在系统长时间的运行后，备DN上会出现日志累积。"
  reasoning_quote: "极致RTO采用了多个page redo线程并行加速回放进度。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "DDL日志的回放速度远远慢于页面修改日志的回放，频繁DDL可能导致主备时延增大。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-rewrite-intargetlist-subplan-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 目标列相关子查询无法提升导致每行触发SubPlan执行，查询性能低下
- **source_heading**: 目标列子查询提升参数intargetlist
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v2-gaussdb/gaussdb_42_0258.html
- **source_url_lang**: zh-cn

### symptom_description

> 由于目标列中的相关子查询(select avg(c2) from t2 where t2.c2=t1.c2)无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划中SubPlan节点
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;`
  abnormal_pattern_quote: "SubPlan 1 -> Aggregate ... -> Seq Scan on public.t2 Filter: (t2.c2 = t1.c2)"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 未包含intargetlist（如设为'none'）
  recommended_value: `intargetlist`
  recommendation_quote: "如果打开intargetlist参数会把子查询提升转为JOIN，来提升查询的性能"
  risk_if_violated_quote: "由于目标列中的相关子查询无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下"
  reasoning_quote: "通过将目标列中子查询提升，转为JOIN，往往可以极大提升查询性能"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-rewrite-uniquecheck-subquery-join-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: common
- **title**: 无agg子查询无法自动提升导致子链接重复执行
- **source_heading**: 提升无agg的子查询uniquecheck
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v2-gaussdb/gaussdb_42_0258.html
- **source_url_lang**: zh-cn

### symptom_description

> 子链接提升需要保证对于每个条件只有一行输出，对于有agg的子查询可以自动提升，对于无agg的子查询如：select t1.c1 from t1 where t1.c1 = (select t2.c1 from t2 where t1.c1=t2.c2) ...重写为join

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划子查询处理方式
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain verbose select t1.c1 from t1 where t1.c1 = (select t2.c1 from t2 where t1.c1=t2.c1);`
  abnormal_pattern_quote: "Hash Join ... Hash Cond: (t1.c1 = subquery.\"?column?\") ... Unique Check Required"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 未包含uniquecheck
  recommended_value: `uniquecheck`
  recommendation_quote: "打开uniquecheck查询重写参数保证可以提升并且等价，如果在运行时输出了多于一行的数据，就会报错。"
  risk_if_violated_quote: "打开之后报错。ERROR: more than one row returned by a subquery used as an expression（当数据中存在重复时）"
  reasoning_quote: "子链接提升需要保证对于每个条件只有一行输出，对于有agg的子查询可以自动提升，对于无agg的子查询...打开uniquecheck查询重写参数保证可以提升并且等价"
  linked_diagnostic_step_no: 1

```
