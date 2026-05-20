<!-- ============ Diagnostic-Flow (gaussdb, 38 cases) ============ -->

## case_id: gaussdb-cpu-high-topsql-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-cpu-high-statement-view-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **title**: GaussDB整体CPU高——通过性能视图定位高CPU SQL
- **source_heading**: •CPU高
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/1881247803599499264/
- **source_url_lang**: zh-cn

### symptom_description

> GaussDB数据库整体性能慢，不满足客户作业对时延要求或者不满足客户预期。有可能会出现大量慢SQL。业务反馈业务接口时延高；或者数据库P80/P95等指标升高；业务时延受损，或者业务在预期时间内无法执行完成。

### diagnostic_steps

```
[step 1]
  metric_name: dbe_perf.statement.cpu_time (持续CPU高)
  collection_layer: db-system-view
  collection_method_quote: `dbe_perf.statement`：可查询分布式本CN发起的历史语句信息。`dbe_perf.summary_statement`：可查询分布式所有CN发起的历史语句信息。（对cpu_time字段进行逆序排序即可识别）
  abnormal_pattern_quote: "对cpu_time字段进行逆序排序即可识别"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高)
  collection_layer: db-system-view
  collection_method_quote: "查询pg_stat_activity 获取正在运行的SQL的query_id。使用上一步的query_id，查询pg_thread_wait_status 获取正在运行的SQL的lwtid。使用操作系统命令top -Hp <gaussdb进程号>，查看相应lwtid(PID)的CPU使用率。"
  abnormal_pattern_quote: "如果确实CPU占用较高，可能为目标SQL"
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: []

[step 3]
  metric_name: statement_history.cpu_time vs db_time
  collection_layer: db-system-view
  collection_method_quote: "登录至各CN/DN节点查询相应时间段的statement_history 表。使用全局接口dbe_perf.get_global_full_sql_by_timestamp('开始时间','结束时间')。注意：需要切换至postgres库。"
  abnormal_pattern_quote: "通常如果说语句的CPU消耗较高，慢SQL语句的cpu_time和db_time差距就较小"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "如果CPU高是gaussdb进程导致的，通常是由于不优SQL导致，关注由于用户语句导致的CPU异常。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "可查询如下两个视图，对cpu_time字段进行逆序排序即可识别。a. dbe_perf.statement：可查询分布式本CN发起的历史语句信息。b. dbe_perf.summary_statement：可查询分布式所有CN发起的历史语句信息。"

```

## case_id: gaussdb-disk-io-high-statement-view-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-dist-volatile-func-not-pushed-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **title**: 自定义函数VOLATILE属性导致分布式语句不下推
- **source_heading**: 语句下推调优 · 实例分析：自定义函数（分布式v2）
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0186.html
- **source_url_lang**: zh-cn

### symptom_description

> 在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划下推标识（Data Node Scan）
  collection_layer: db-interactive-cmd
  collection_method_quote: "将GUC参数enable_fast_query_shipping设置为off，使查询优化器使用分布式框架策略。查看执行计划。如果执行计划中有Data Node Scan节点，那么此执行计划是发送语句的分布式执行计划，为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。"
  abnormal_pattern_quote: "可见，func_percent_2并没有被下推，而是将ss_sales_price和ss_list_price收到CN上，再进行计算，消耗大量CN的资源，而且计算缓慢。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_proc.provolatile / proshippable
  collection_layer: db-system-view
  collection_method_quote: "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE。另外，在pg_proc中的proshippable字段，取值范围为t/f/NULL，这个字段与provolatile字段一起用于描述函数是否下推。"
  abnormal_pattern_quote: "如果函数的provolatile属性为s或v，则仅当proshippable的值为t时，函数可以下推。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "可见，func_percent_2并没有被下推，而是将ss_sales_price和ss_list_price收到CN上，再进行计算，消耗大量CN的资源，而且计算缓慢。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "对于自定义函数，如果对于确定的输入，有确定的输出，则应将函数定义为immutable类型。"

```

## case_id: gaussdb-plan-suboptimal-rewrite-rule-partialpush-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **title**: 自定义函数无法下推导致 CN 上全量 HASH JOIN，partialpush 参数可提升性能
- **source_heading**: 部分下推参数partialpush的使用
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0224.html
- **source_url_lang**: zh-cn

### symptom_description

> 查询下推到DN分布式执行，可以大大加速查询。如果查询语句中有一个不能下推的因素，整个语句就不能下推，无法生成Stream计划在DN分布式执行，性能通常较差。

### diagnostic_steps

```
[step 1]
  metric_name: explain verbose · RemoteQuery 计划
  collection_layer: db-interactive-cmd
  collection_method_quote: `yshen=# set rewrite_rule='none'; SET yshen=# explain (verbose on, costs off)  select two_sum(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);`
  abnormal_pattern_quote: `该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 默认值不含 partialpush，无法对含不可下推函数的语句做部分下推优化
  recommended_value: `partialpush`
  recommendation_quote: `通过增加partialpush查询重写参数，可以把1,2,3下推到DN分布式执行，极大提升语句的性能`
  risk_if_violated_quote: `该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`
  reasoning_quote: `如果查询语句中有一个不能下推的因素，整个语句就不能下推，无法生成Stream计划在DN分布式执行，性能通常较差。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-dist-v3-volatile-func-not-pushed-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **title**: 分布式v3：自定义函数VOLATILE属性导致语句不下推、CN性能瓶颈
- **source_heading**: 语句下推调优 · 实例分析：自定义函数（分布式v3）
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0265.html
- **source_url_lang**: zh-cn

### symptom_description

> 在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。在进行性能调优的时候，应尽量避免只能选择第3种策略的查询语句。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划下推标识
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=# explain select * from t where c1 > 1;`
  abnormal_pattern_quote: "通常而言explain语句后没有显示具体的执行计划算子，仅存在类似关键字\"Data Node Scan on\"则说明语句已下推给DN去执行"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_proc.provolatile
  collection_layer: db-system-view
  collection_method_quote: "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE"
  abnormal_pattern_quote: "如果函数的provolatile属性为s或v，则仅当proshippable的值为t时，函数可以下推。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "可见函数func_percent_1被下推到DN执行。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "对于自定义函数，如果对于确定的输入，有确定的输出，则应将函数定义为immutable类型。"

```

## case_id: gaussdb-plan-suboptimal-missing-analyze-dist-v8-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-dws-plan-suboptimal-planhint-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **title**: TPC-DS Q24查询执行计划不优——使用Plan Hint调优
- **source_heading**: Plan Hint实际调优案例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0284.html
- **source_url_lang**: zh-cn

### symptom_description

> 本节以TPC-DS(Decision Support)标准测试的Q24的部分语句为例，在1000X数据集，24DN环境上，说明使用plan hint进行实际调优的过程。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE A-time 瓶颈算子识别
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=# explain analyze select avg(netpaid) from (select c_last_name,c_first_name,s_store_name,ca_state,s_state,i_color,i_current_price,i_manager_id,i_units,i_size,sum(ss_sales_price) netpaid from store_sales,store_returns,store,item,customer,customer_address where ss_ticket_number = sr_ticket_number and ss_item_sk = sr_item_sk and ss_customer_sk = c_customer_sk and ss_item_sk = i_item_sk and ss_store_sk = s_store_sk and c_birth_country = upper(ca_country) and s_zip = ca_zip ...`
  abnormal_pattern_quote: "通用的优化手段是EXPLAIN ANALYZE/PERFORMANCE命令查看执行过程的瓶颈算子，然后进行针对性优化。"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "一个查询语句要经过多个算子步骤才会输出最终的结果。由于个别算子耗时过长导致整体查询性能下降的情况比较常见。这些算子是整个查询的瓶颈算子。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "通用的优化手段是EXPLAIN ANALYZE/PERFORMANCE命令查看执行过程的瓶颈算子，然后进行针对性优化。"

```

## case_id: gaussdb-query-slow-no-partial-pushdown-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 含不可下推函数的查询未使用 partialpush 导致大量数据在 CN 上做 Hash Join、查询慢
- **source_heading**: 部分下推参数partialpush的使用
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0318.html
- **source_url_lang**: zh-cn

### symptom_description

> 查询下推到DN分布式执行，可以大大加速查询。如果查询语句中有一个不能下推的因素，整个语句就不能下推，无法生成Stream计划在DN分布式执行，性能通常较差。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=# set rewrite_rule='none'; SET gaussdb=# explain (verbose on, costs off)  select group_concat(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);`
  abnormal_pattern_quote: `该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: none（未开启 partialpush）
  recommended_value: `partialpush`
  recommendation_quote: `通过增加partialpush查询重写参数，可以把1、2、3下推到DN分布式执行，极大提升语句的性能：gaussdb=# set rewrite_rule='partialpush';`
  risk_if_violated_quote: `该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。`
  reasoning_quote: `通过增加partialpush查询重写参数，可以把1、2、3下推到DN分布式执行，极大提升语句的性能`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-query-slow-correlated-subquery-target-list-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-dist-disk-full-storage-skew-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: 磁盘满后快速定位存储倾斜表
- **source_heading**: 场景一：磁盘满后快速定位存储倾斜的表
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0016.html
- **source_url_lang**: zh-cn

### symptom_description

> 场景一：磁盘满后快速定位存储倾斜的表

### diagnostic_steps

```
[step 1]
  metric_name: 近期数据变更表列表（pg_stat_get_last_data_changed_time）
  collection_layer: db-system-view
  collection_method_quote: `gaussdb=# SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();`
  abnormal_pattern_quote: "通过table_distribution(schemaname text, tablename text)查询出表在各个DN占用的存储空间"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: NULL
  linked_diagnostic_step_no: 1
  mitigation_quote: "通过table_distribution(schemaname text, tablename text)查询出表在各个DN占用的存储空间"

```

## case_id: gaussdb-dist-routine-skew-inspection-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **title**: 常规数据倾斜巡检：表个数少于1W时使用PGXC_GET_TABLE_SKEWNESS视图
- **source_heading**: 场景二：常规数据倾斜巡检
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0016.html
- **source_url_lang**: zh-cn

### symptom_description

> 在库中表个数少于1W的场景，直接使用倾斜视图查询当前库内所有表的数据倾斜情况。

### diagnostic_steps

```
[step 1]
  metric_name: PGXC_GET_TABLE_SKEWNESS
  collection_layer: db-system-view
  collection_method_quote: `gaussdb=#SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

[step 2]
  metric_name: table_distribution() 各DN空间（大表个数超1W场景）
  collection_layer: db-system-view
  collection_method_quote: `gaussdb=#SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace INNER JOIN pg_catalog.table_distribution() s ON s.schemaname = n.nspname AND s.tablename = c.relname INNER JOIN pg_catalog.pgxc_class x ON c.oid = x.pcrelid AND x.pclocatortype = 'H' GROUP BY schemaname,tablename;`
  abnormal_pattern_quote: "直接使用table_distribution()函数自定义输出，减少输出列进行计算优化"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: NULL
  linked_diagnostic_step_no: 1
  mitigation_quote: "在库中表个数少于1W的场景，直接使用倾斜视图查询当前库内所有表的数据倾斜情况"

```

## case_id: gaussdb-query-slow-missing-statistics-explain-verbose-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **title**: 未收集统计信息导致查询性能差（集中式v3）
- **source_heading**: 统计信息调优
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0288.html
- **source_url_lang**: zh-cn

### symptom_description

> 在很多场景下，由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE 执行计划 Warning
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain verbose`
  abnormal_pattern_quote: "WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan."
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_log 日志中的 Statistics WARNING
  collection_layer: log-grep
  collection_method_quote: NULL
  abnormal_pattern_quote: "可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "当通过以上方法查看到哪些表或列没有做analyze，可以通过对WARNING或日志中上报的表或列做analyze来解决由于未收集统计信息导致查询变慢的问题。"

```

## case_id: gaussdb-query-slow-seqscan-index-missing-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-rewrite-magicset-correlated-subquery-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 带聚集算子的相关子查询重复扫描导致性能差
- **source_heading**: 从主查询下推条件到子查询参数magicset
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0318.html
- **source_url_lang**: zh-cn

### symptom_description

> 先针对子查询的关联字段进行分组聚集，再和主查询进行关联，减少相关子链接的重复扫描，提升查询效率

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划子查询关联方式
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=# EXPLAIN (costs off) SELECT t1 FROM t1 WHERE t1.c2 = 10 AND t1.c3 < (SELECT sum(c3) FROM t2 WHERE t1.c1 = t2.c1);`
  abnormal_pattern_quote: "先针对子查询的关联字段进行分组聚集，再和主查询进行关联，减少相关子链接的重复扫描"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 未包含magicset
  recommended_value: `magicset`
  recommendation_quote: "先针对子查询的关联字段进行分组聚集，再和主查询进行关联，减少相关子链接的重复扫描，提升查询效率，修改重写参数后，计划改变"
  risk_if_violated_quote: NULL
  reasoning_quote: "将带有聚集算子的子查询提前和主查询进行关联"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-rewrite-v8-intargetlist-subplan-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 集中式v8：目标列相关子查询无法提升（intargetlist）
- **source_heading**: 目标列子查询提升参数intargetlist（v8版）
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0321.html
- **source_url_lang**: zh-cn

### symptom_description

> 由于目标列中的相关子查询(select avg(c2) from t2 where t2.c2=t1.c2)无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下。如果打开intargetlist参数会把子查询提升转为join，从而提升查询的性能。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划中SubPlan节点
  collection_layer: db-interactive-cmd
  collection_method_quote: `gaussdb=#  EXPLAIN (verbose on, costs off) SELECT c1,(SELECT avg(c2) FROM t2 WHERE t2.c2=t1.c2) FROM t1 WHERE t1.c1<100 ORDER BY t1.c2;`
  abnormal_pattern_quote: "SubPlan 1 -> Aggregate Output: avg(t2.c2) -> Seq Scan on public.t2 Output: t2.c1, t2.c2 Filter: (t2.c2 = t1.c2)"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 未包含intargetlist
  recommended_value: `intargetlist`
  recommendation_quote: "如果打开intargetlist参数会把子查询提升转为join，从而提升查询的性能。"
  risk_if_violated_quote: "由于目标列中的相关子查询无法提升的缘故，导致每扫描t1的一行数据，就会触发子查询的一次执行，效率低下"
  reasoning_quote: "通过将目标列中子查询提升，转为join，往往可以极大提升查询性能"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-replica-lag-redo-workers-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-plan-suboptimal-missing-analyze-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **title**: 未收集统计信息导致查询性能差（集中式GaussDB）
- **source_heading**: 实例分析1：未收集统计信息导致查询性能差
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/centralized-devg-v2-gaussdb/gaussdb_42_0238.html
- **source_url_lang**: zh-cn

### symptom_description

> 在很多场景下，由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE 统计信息警告
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan."
  abnormal_pattern_quote: "WARNING:Statistics in some tables or columns(...) are not collected."
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_log 统计信息缺失日志
  collection_layer: log-grep
  collection_method_quote: "可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。"
  abnormal_pattern_quote: "LOG:Statistics in some tables or columns(...) are not collected."
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "由于查询中涉及到的表或列没有收集统计信息，会对查询性能有很大的影响。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "当通过以上方法查看到哪些表或列没有做analyze，可以通过对WARNING或日志中上报的表或列做analyze可以解决由于未收集统计信息导致查询变慢的问题。"

```

## case_id: gaussdb-rewrite-intargetlist-subplan-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

