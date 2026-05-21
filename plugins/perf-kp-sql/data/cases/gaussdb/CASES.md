<!-- ============ Diagnostic-Flow (gaussdb, 77 cases) ============ -->

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

## case_id: gaussdb-savepoint-in-loop-resource-leak-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-partition-maxmin-fullscan-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-query-slow-agg-plan-mode-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 优化器代价估算偏差导致 Agg 计算方式选择不优
- **source_heading**: 案例：调整GUC参数best_agg_plan
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0220.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常优化器总会选择最优的执行计划，但是众所周知代价估算，尤其是中间结果集的代价估算一般会有比较大的偏差，这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 Agg 算子模式
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain select b,count(1) from t1 group by b;`
  abnormal_pattern_quote: 代价估算，尤其是中间结果集的代价估算一般会有比较大的偏差，这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] best_agg_plan
  param_name: best_agg_plan
  abnormal_value_pattern: 默认值为 0，优化器自动选择，但代价估算偏差大时选择不优
  recommended_value: `3` (hashagg+redistribute+hashagg，当 agg 收敛度大时)
  recommendation_quote: GaussDB提供了guc参数best_agg_plan来干预执行计划，强制其生成上述对应的执行计划，此参数取值范围为0，1，2，3
  risk_if_violated_quote: 这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差
  reasoning_quote: 一般来说，当agg汇聚的收敛度很小时，即结果集的个数在agg之后并没有明显变少时（经验上以5倍为临界点），选择redistribute+hashagg执行方式，否则选择hashagg+redistribute+hashagg执行方式
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-copy-constraint-violation-tolerance-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: COPY 导入数据存在约束冲突时开启 Level2 容错降低性能
- **source_heading**: 数据存在错误时的导入操作指南
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0074.html
- **source_url_lang**: zh-cn

### symptom_description

> 该功能下数据导入过程会从批量插入变为单行插入，对应的导入性能会有所劣化。

### diagnostic_steps

```
[step 1]
  metric_name: COPY 导入是否存在约束冲突类容错需求
  collection_layer: db-shell
  collection_method_quote: "gaussdb=# SET a_format_load_with_constraints_violation = 's2';"
  abnormal_pattern_quote: "支持的约束冲突类型包括：非空约束、条件约束、主键约束、唯一性约束以及唯一性索引。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] a_format_load_with_constraints_violation
  param_name: a_format_load_with_constraints_violation
  abnormal_value_pattern: 默认未设置导致约束冲突无法容错；设置为 's2' 后性能劣化
  recommended_value: 默认不开启;仅在确有约束冲突时设为 's2'
  recommendation_quote: "推荐用户默认选择Level1。这是因为Level1所支持的错误类型较为常见，并且不会对导入性能产生任何影响。而Level2目前仅在集中式A兼容环境下支持，开启该特性会额外消耗导入性能和内存资源。因此，不建议用户默认使用Level2，仅在明确数据存在约束类型冲突时再开启。"
  risk_if_violated_quote: "该功能下数据导入过程会从批量插入变为单行插入，对应的导入性能会有所劣化。"
  reasoning_quote: "此容错选项默认不支持对约束冲突进行容错。如需要对约束冲突进行容错，可额外设置会话级GUC参数a_format_load_with_constraints_violation为\"s2\"后再次导入即可。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "在行级触发器中，即使操作表触发了约束冲突，该功能依然有效。行级触发器的约束冲突通过子事务来实现，子事务会占用更多的内存资源并延长执行时间。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "建议在明确存在约束冲突的可能性时使用该特性。此外，在这种场景下，单次COPY导入的数据量不要过大，建议不超过1GB。"

```

## case_id: gaussdb-plan-suboptimal-anti-join-row-estimate-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-data-skew-storage-distribution-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **title**: 分布列选择不合理导致存储倾斜影响查询性能
- **source_heading**: 存储层数据倾斜
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0190.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果数据分布存在倾斜，则会导致分布式执行某些DN成为瓶颈，影响查询性能。这种情况通常是由于分布列选择不合理

### diagnostic_steps

```
[step 1]
  metric_name: explain performance 各 DN 实际行数
  collection_layer: db-interactive-cmd
  collection_method_quote: `openGauss=# explain performance select count(*) from inventory;`
  abnormal_pattern_quote: 可以看到inventory表各DN的scan行数，发现各DN的行数差距较大，最大的为63000000，最小的只有15000000，差了4倍
  abnormal_pattern_threshold: `> 4x` 倍数差距
  metric_unit: rows
  prerequisite_steps: []

[step 2]
  metric_name: table_skewness() 各 DN 数据分布比例
  collection_layer: db-system-view
  collection_method_quote: `openGauss=# select table_skewness('inventory');`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: 通过查询建表定义，可以发现，目前该表是以inv_date_sk作为分布列的，导致存在倾斜
  linked_diagnostic_step_no: 2
  mitigation_quote: 通过查看各列的数据分布情况，建表时改为inv_item_sk作为分布列，则倾斜情况分布如下

```

## case_id: gaussdb-data-skew-compute-redistribute-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **title**: 重分布列存在倾斜值导致计算倾斜，部分 DN 处理数据量远大于其他节点
- **source_heading**: 计算层数据倾斜
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0190.html
- **source_url_lang**: zh-cn

### symptom_description

> 即使通过修改表的分布键，使得数据存储在各个节点上是均衡的，但是在执行查询的过程中，仍然可能出现数据倾斜的问题。在运算过程中某个算子在DN上输出的结果集出现倾斜，从而导致此算子上层的运算出现计算倾斜

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE Streaming(REDISTRIBUTE) 各 DN 输出行数
  collection_layer: db-interactive-cmd
  collection_method_quote: `openGauss=# explain select * from skew s,test t where s.x = t.x order by s.a limit 1;`
  abnormal_pattern_quote: 6 --Streaming(type: REDISTRIBUTE) datanode1 (rows=5050368) datanode2 (rows=15276032) datanode3 (rows=5174272) datanode4 (rows=5219328)
  abnormal_pattern_threshold: NULL
  metric_unit: rows
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] skew_option
  param_name: skew_option
  abnormal_value_pattern: 默认值未开启倾斜优化
  recommended_value: `normal`
  recommendation_quote: 该特性由GUC参数skew_option控制
  risk_if_violated_quote: 由于倾斜节点所需要运算的数据量远大于其它节点，导致倾斜节点降低系统整体性能
  reasoning_quote: RLBT方案主要分为两个层面，第一步是计算倾斜识别，第二步是计算倾斜解决
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: s.x列上存在倾斜数据，倾斜数据的值为0
  linked_diagnostic_step_no: 1
  mitigation_quote: 优化器通过统计信息，识别到了该倾斜数据，生成了倾斜优化计划

```

## case_id: gaussdb-disk-space-pressure-storage-skew-locate-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: 磁盘满后快速定位存储倾斜的表
- **source_heading**: 场景一：磁盘满后快速定位存储倾斜的表
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0470.html
- **source_url_lang**: zh-cn

### symptom_description

> 场景一：磁盘满后快速定位存储倾斜的表

### diagnostic_steps

```
[step 1]
  metric_name: pg_stat_get_last_data_changed_time 最近变更的表
  collection_layer: db-system-view
  collection_method_quote: `SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: table_distribution() 各 DN 存储空间分布
  collection_layer: db-system-view
  collection_method_quote: `SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: NULL
  linked_diagnostic_step_no: 2
  mitigation_quote: 通过table_distribution(schemaname text, tablename text)查询出表在各个DN占用的存储空间

```

## case_id: gaussdb-distribution-key-skew-xc-node-id-25

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **title**: 分布键选择不当致 DN 间数据量差 >10%,木桶效应拖慢整体
- **source_heading**: 数据倾斜
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://xie.infoq.cn/article/86d06ac0a01fbd403397523b7
- **source_url_lang**: zh-cn

### symptom_description

> 不合适的分布键会导致数据倾斜，导致木桶效应

### diagnostic_steps

```
[step 1]
  metric_name: 按 xc_node_id 分组的表数据行数
  collection_layer: db-system-view
  collection_method_quote: `SELECT a.count,b.node_name         FROM             (SELECT count(*) AS count,xc_node_id FROM tablename GROUP BY xc_node_id) a,               pgxc_node b         WHERE a.xc_node_id=b.node_id ORDER BY a.count DESC;`
  abnormal_pattern_quote: `一般来说，DN 的数据量相差 10%以上，则可能发生了数据倾斜，就要考虑按照前面的原则调整分布列。`
  abnormal_pattern_threshold: `DN 间数据量差异 >= 10%`
  metric_unit: rows
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  linked_diagnostic_step_no: 1
  mitigation_quote: `尽量选择 distinct 值比较多的列，保证数据均匀分布。`

[non_parameter_causes · cause 2] data-distribution
  cause_type: data-distribution
  description_quote: `b. 尽量选择 Join 列或 group 列做分布列。尽量选择 Join 列或 group 列是为了避免数据节点之间数据流动, 提高性能。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `尽量选择 Join 列或 group 列做分布列。`

```

## case_id: gaussdb-dws-distkey-choice-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **title**: 选择合适的分布列避免不必要 Streaming
- **source_heading**: 选择合适的分布列
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://blog.csdn.net/GaussDB/article/details/134704421
- **source_url_lang**: zh-cn

### symptom_description

> 则执行计划将存在"Streaming"，导致DN之间存在较大通信数据量。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 计划是否含 Streaming
  collection_layer: db-interactive-cmd
  collection_method_quote: CREATE TABLE t1 (a int, b int) DISTRIBUTE BY HASH (a); CREATE TABLE t2 (a int, b int) DISTRIBUTE BY HASH (a);
  abnormal_pattern_quote: 则执行计划将存在"Streaming"，导致DN之间存在较大通信数据量。
  abnormal_pattern_threshold: NULL
  metric_unit: plan-shape
  prerequisite_steps: []

[step 2]
  metric_name: 调整后 EXPLAIN 是否消除 Streaming
  collection_layer: db-interactive-cmd
  collection_method_quote: CREATE TABLE t1 (a int, b int) DISTRIBUTE BY HASH (a); CREATE TABLE t2 (a int, b int) DISTRIBUTE BY HASH (b);
  abnormal_pattern_quote: 则执行计划将不包含"Streaming"，减少DN之间存在的通信数据量，从而提升查询性能。
  abnormal_pattern_threshold: NULL
  metric_unit: plan-shape
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 如果将a作为t1的分布列，将b作为t2的分布列：则执行计划将不包含"Streaming"，减少DN之间存在的通信数据量，从而提升查询性能。
  linked_diagnostic_step_no: 2
  mitigation_quote: 将a作为t1的分布列，将b作为t2的分布列

```

## case_id: gaussdb-groupagg-sort-vs-hashagg-08

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-data-skew-hashjoin-dn-compute-skew-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **title**: 表数据分布倾斜导致 HashJoin DN 计算时间严重偏斜
- **source_heading**: 案例：调整分布键
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0217.html
- **source_url_lang**: zh-cn

### symptom_description

> 从执行信息上比较明确地可以看出HashJoin是整个计划的性能瓶颈点，并且从HashJoin的执行时间信息[2657.406,93339.924]，上可以看出HashJoin在不同的DN上存在严重的计算偏斜

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE`
  abnormal_pattern_quote: HashJoin的执行时间信息[2657.406,93339.924]，上可以看出HashJoin在不同的DN上存在严重的计算偏斜
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: Memory Information 各 DN 内存消耗分布
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE` (Memory Information 段)
  abnormal_pattern_quote: 各个节点的内存资源消耗也存在极为严重的偏斜
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [1]

[step 3]
  metric_name: Seq Scan 各 DN 扫描时间
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE`
  abnormal_pattern_quote: 进一步向HashJoin算子的下层分析发现Seq Scan on s_riskrate_setting也存在极为严重的计算倾斜[38.885,2940.983]
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: 实际分析之后确实发现表s_riskrate_setting存在严重的数据倾斜。整改之后性能从94s提升为50s
  linked_diagnostic_step_no: 3
  mitigation_quote: 整改之后性能从94s提升为50s

```

## case_id: gaussdb-query-slow-join-null-values-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-plan-suboptimal-row-estimate-broadcast-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 多列关联估算行数严重低估导致广播代价高
- **source_heading**: Plan Hint实际调优案例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0204.html
- **source_url_lang**: zh-cn

### symptom_description

> 该计划中，第10层算子使用broadcast性能较差，由于第11层算子估算行数为2140，比实际行数严重低估。错误行数估算主要来源于第13层算子的行数低估，根因是第13层hashjoin中，使用store_sales的(ss_ticket_number, ss_item_sk)列和store_returns的(sr_ticket_number, sr_item_sk)列进行关联，由于缺少多列相关性的估算导致行数严重低估

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划算子估算行数
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN`
  abnormal_pattern_quote: 第11层算子估算行数为2140，比实际行数严重低估
  abnormal_pattern_threshold: NULL
  metric_unit: rows
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 缺少多列相关性的估算导致行数严重低估
  linked_diagnostic_step_no: 1
  mitigation_quote: 使用如下的rows hint进行调优后

```

## case_id: gaussdb-plan-suboptimal-statistics-change-plan-regression-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **title**: 统计信息变更导致 Join 流方式从 Broadcast 切换为 Redistribute 引发计划劣化
- **source_heading**: Plan Hint实际调优案例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0204.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果有统计信息变更引起的查询劣化，可以考虑用plan hint来调整到之前的查询计划。这里以TPCH-Q17为例，在收集default_statistics_target设置为–2的统计信息之后，计划相比于默认统计信息发生劣化

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 Stream 算子类型
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN`
  abnormal_pattern_quote: 劣化的原因主要为lineitem和part表join时stream类型由BroadCast变更为Redistribute导致
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] default_statistics_target
  param_name: default_statistics_target
  abnormal_value_pattern: 设置为 -2，导致统计信息精度变化影响计划选择
  recommended_value: `100`
  recommendation_quote: 这里以TPCH-Q17为例，在收集default_statistics_target设置为–2的统计信息之后，计划相比于默认统计信息发生劣化
  risk_if_violated_quote: 计划相比于默认统计信息发生劣化
  reasoning_quote: 劣化的原因主要为lineitem和part表join时stream类型由BroadCast变更为Redistribute导致
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-procedure-exception-frequent-perf-degrade-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-rewrite-rule-partialpush-13

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **title**: 不下推函数(如 group_concat) 导致 RemoteQuery 拉全表回 CN
- **source_heading**: 部分下推参数partialpush的使用
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0315.html
- **source_url_lang**: zh-cn

### symptom_description

> 该计划很慢，原因是网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · 是否含 RemoteQuery / Data Node Scan
  collection_layer: db-interactive-cmd
  abnormal_pattern_quote: `Data Node Scan on t1 "_REMOTE_TABLE_QUERY_"`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] rewrite_rule
  param_name: rewrite_rule
  abnormal_value_pattern: 不含 partialpush 规则 → 含不下推函数的子查询无法部分下推
  recommended_value: `包含 'partialpush' (如 set rewrite_rule='partialpush')`
  recommendation_quote: `通过增加partialpush查询重写参数，可以把1,2,3下推到DN分布式执行，极大提升语句的性能`
  risk_if_violated_quote: `网络传输了大量数据，然后在CN上执行HASH JOIN，不能充分利用集群资源`
  reasoning_quote: `通过增加partialpush查询重写参数，可以把1,2,3下推到DN分布式执行，极大提升语句的性能`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-query-slow-scan-no-local-cluster-key-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-query-slow-windowagg-sort-on-cn-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: WindowAgg 与 Sort 全在 CN 端执行，占总执行时间 95% 以上
- **source_heading**: 案例：使排序下推
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0215.html
- **source_url_lang**: zh-cn

### symptom_description

> 在做场景性能测试时，发现某场景大部分时间是CN端在做window agg，占到总执行时间95%以上，系统资源不能充分利用

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划算子位置（CN vs DN）
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN`
  abnormal_pattern_quote: 可以看到window agg和sort全部在CN端执行，耗时非常严重
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 可以看到window agg和sort全部在CN端执行，耗时非常严重
  linked_diagnostic_step_no: 1
  mitigation_quote: 尝试将语句改写为子查询。将trunc两列的和作为一个子查询，然后在子查询的外面做window agg，这样排序就可以下推了

```

## case_id: gaussdb-group-by-sort-perf-work-mem-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-statement-not-shippable-cn-bottleneck-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 含不可下推函数/语法的查询导致 CN 成为性能瓶颈
- **source_heading**: 语句下推调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0264.html
- **source_url_lang**: zh-cn

### symptom_description

> 在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 输出中 "Data Node Scan on" 是否在第一行
  collection_layer: db-interactive-cmd
  collection_method_quote: "通常而言explain语句后没有显示具体的执行计划算子，执行计划中关键字\"Data Node Scan on\"出现在第一行（不包含计划格式）则说明语句已下推给DN去执行。"
  abnormal_pattern_quote: "在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_fast_query_shipping
  param_name: enable_fast_query_shipping
  abnormal_value_pattern: off 时无法生成下推语句计划
  recommended_value: `on`
  recommendation_quote: "在GaussDB优化器中如果想要支持语句下推需要将GUC参数enable_fast_query_shipping设置为on即可。"
  risk_if_violated_quote: "在第3种策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。"
  reasoning_quote: "在GaussDB优化器中如果想要支持语句下推需要将GUC参数enable_fast_query_shipping设置为on即可。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "执行语句不能下推是因为语句中含有不支持下推的函数或者不支持下推的语法。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "一般都可以通过等价改写规避执行计划不能下推的问题。"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "多表查询场景下语句能否下推通常与join条件以及分布列有关，即如果join条件与表分布列匹配得上则可下推，否则无法下推。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "如果join条件与表分布列匹配得上则可下推"

```

## case_id: gaussdb-query-slow-subplan-correlated-subquery-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 执行计划中存在 SubPlan+Broadcast，相关子查询性能差
- **source_heading**: 案例：改写SQL消除子查询
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0221.html
- **source_url_lang**: zh-cn

### symptom_description

> 此SQL性能较差，查看发现执行计划中存在SubPlan

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 SubPlan 存在
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN`
  abnormal_pattern_quote: 此SQL性能较差，查看发现执行计划中存在SubPlan
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 此SQL性能较差，查看发现执行计划中存在SubPlan
  linked_diagnostic_step_no: 1
  mitigation_quote: 此优化的核心就是消除子查询。分析业务场景发现 a.ca_address_sk不为null，那么从SQL语义出发，可以等价改写SQL

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

