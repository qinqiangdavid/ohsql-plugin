<!-- ============ Diagnostic-Flow (gaussdb-dws, 120 cases) ============ -->

## case_id: gaussdb-dws-plan-suboptimal-broadcast-skew-redistribute-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS统计信息不准导致小表被误判为大表走Broadcast，应改用Redistribute
- **source_heading**: 四、Stream方式的选择
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/41146/
- **source_url_lang**: zh-cn

### symptom_description

> 由于sr_tbl表统计信息不准确（如果是中间结果集，则表示中间结果集估算不准），一种调优的方法是，将sr_tbl的表统计信息重新收集准确一些（如果sr_tbl是中间结果集，则无法收集），另一种方法是让sr_tbl走Redistribute路径，而后者我们又有两种方式来实现，一是用Plan Hint，即在生成计划时，告诉优化器走Redistribute路径，二是把Broadcast关掉。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE · Stream算子类型
  collection_layer: db-interactive-cmd
  collection_method_quote: "GaussDB计划中常见的主要Stream算子包括Redistribute、Broadcast和Gather。"
  abnormal_pattern_quote: "优化器认为适合做Broadcast。于是最终选择了一边Broadcast的计划。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "由于sr_tbl表统计信息不准确（如果是中间结果集，则表示中间结果集估算不准），一种调优的方法是，将sr_tbl的表统计信息重新收集准确一些"
  linked_diagnostic_step_no: 1
  mitigation_quote: "另一种方法是让sr_tbl走Redistribute路径，而后者我们又有两种方式来实现，一是用Plan Hint，即在生成计划时，告诉优化器走Redistribute路径，二是把Broadcast关掉。禁用Broadcast后，执行计划如下："

```

## case_id: gaussdb-dws-plan-suboptimal-nestloop-seqscan-cost-02

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS索引扫描关闭后Seq Scan触发NestLoop但Hash Join启动代价更高
- **source_heading**: 二、Scan方式的选择
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/41146/
- **source_url_lang**: zh-cn

### symptom_description

> 优化器在比较路径时，综合了这两个代价，最终推荐了Nest Loop的路径。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE · 路径代价 (Startup vs Total)
  collection_layer: db-interactive-cmd
  collection_method_quote: "把explain_perf_mode设置为normal，查看原Nest Loop的启动代价"
  abnormal_pattern_quote: "红框中的两个cost，分别是启动代价和总代价，在看Hash Join的cost，明显Hash Join的启动代价比Nest Loop的大很多（启动代价代表了输出第一条数据的代价），优化器在比较路径时，综合了这两个代价，最终推荐了Nest Loop的路径。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "从代价上看出Hash Join的总代价比Nest Loop的小，但优化器没有选择Hash Join，这是因为优化器比较路径代价时，会比较Startup和Total代价，即启动代价和总代价，综合考虑"
  linked_diagnostic_step_no: 1
  mitigation_quote: "Scan、Join、Stream调控的基本依据也是代价，代价一般体现在执行耗时上，调优时可从Performance中识别出性能的瓶颈点，分析选择的算子是否与代价匹配。"

```

## case_id: gaussdb-dws-plan-suboptimal-nestloop-perf-jump-hint-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 实时场景执行时间跳变至 3600s 超时，NestLoop 选择错误，通过 enable_index_nestloop hint 修复
- **source_heading**: 实时场景下的性能跳变问题案例
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://bbs.huaweicloud.com/blogs/409217
- **source_url_lang**: zh-cn

### symptom_description

> 该问题发生在实时场景下，语句执行时间因为达到了 3600s而自动终止运行，导致影响业务进度。

### diagnostic_steps

```
[step 1]
  metric_name: 语句执行时间 / 执行计划中 NestLoop 算子
  collection_layer: db-interactive-cmd
  collection_method_quote: `该问题发生在实时场景下，语句执行时间因为达到了 3600s而自动终止运行`
  abnormal_pattern_quote: `语句执行时间因为达到了 3600s而自动终止运行，导致影响业务进度。`
  abnormal_pattern_threshold: `>= 3600s`
  metric_unit: s
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_index_nestloop
  param_name: enable_index_nestloop
  abnormal_value_pattern: 执行计划中错误地选择了 NestLoop
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: `语句执行时间因为达到了 3600s而自动终止运行，导致影响业务进度。`
  reasoning_quote: `该案例主要针对这一类问题利用hint中的enable_index_nestloop参数进行分析解决`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-query-slow-topsql-queue-wait-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: SQL作业block_time大但duration无明显变化——受其他作业排队影响
- **source_heading**: 功能一：历史TopSQL
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://bbs.huaweicloud.com/blogs/214157
- **source_url_lang**: zh-cn

### symptom_description

> block_time较大，而duration值并无明显变化，说明用户作业受其它作业影响，在真正开始执行前进行了较长时间的排队

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_history · block_time / duration
  collection_layer: db-system-view
  collection_method_quote: `pgxc_wlm_session_history`
  abnormal_pattern_quote: "block_time较大，而duration值并无明显变化，说明用户作业受其它作业影响，在真正开始执行前进行了较长时间的排队"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: pgxc_wlm_session_history · 同期并发作业数
  collection_layer: db-system-view
  collection_method_quote: `pgxc_wlm_session_history`
  abnormal_pattern_quote: "下一步需要接着查看本数据表，统计起始时间小于start_time、结束时间大于finish_time的作业数量。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "因其它并发作业抢占，导致作业排队，从而导致作业执行时间增加，可以分析A1/B1/D1"
  linked_diagnostic_step_no: 2
  mitigation_quote: "第一步，调整作业执行顺序，减少并发作业数量，减少阻塞时间"

```

## case_id: gaussdb-dws-query-slow-data-skew-dn-time-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DN执行时间倾斜导致SQL作业整体执行慢
- **source_heading**: 功能一：历史TopSQL
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://bbs.huaweicloud.com/blogs/214157
- **source_url_lang**: zh-cn

### symptom_description

> DN上的执行时间，结合duration数据，如果一个查询的DN执行时间有严重倾斜，那就需要考虑数据表的分区、分布列是否设置合适；不合理的分区、分布列，可能会导致本应分散到多个DN的执行任务被集中到个别DN上执行，执行时间必然大大增加。

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent
  collection_layer: db-system-view
  collection_method_quote: `pgxc_wlm_session_history`
  abnormal_pattern_quote: "如果一个查询的DN执行时间有严重倾斜，那就需要考虑数据表的分区、分布列是否设置合适"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: "不合理的分区、分布列，可能会导致本应分散到多个DN的执行任务被集中到个别DN上执行，执行时间必然大大增加。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-query-slow-dn-io-contention-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DN的IO指标偏低反映作业受IO抢占影响
- **source_heading**: 功能三：历史实例资源监视
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://bbs.huaweicloud.com/blogs/214157
- **source_url_lang**: zh-cn

### symptom_description

> IO有点独特的是，往往IOPS变小反而反应了作业受其它作业影响，IO跑步起来，拖长了作业执行时间

### diagnostic_steps

```
[step 1]
  metric_name: GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write
  collection_layer: db-system-view
  collection_method_quote: `GS_WLM_INSTANCE_HISTORY`
  abnormal_pattern_quote: "io_util&io_await能够反应出磁盘的繁忙程度，disk_read&disk_write是发生的实际IO流量值，如果磁盘很繁忙，但实际IO流量值不高，可以进一步分析磁盘是否有坏道，是否有硬件故障。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] hardware-disk
  cause_type: hardware-disk
  description_quote: "如果磁盘很繁忙，但实际IO流量值不高，可以进一步分析磁盘是否有坏道，是否有硬件故障。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: "如果磁盘很繁忙，实际IO流量也很高，但是process_read&process_write却较低，说明造成磁盘繁忙的原因并不是该GaussDB实例，可能是备机catchup或者其它运行在该磁盘上的程序消耗了大量IO，可做进一步定位。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-query-slow-windowagg-single-dn-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: row_number() over / count() over 窗口函数集中在单DN运行导致查询慢
- **source_heading**: 1、【问题描述】
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://bbs.huaweicloud.com/blogs/416344
- **source_url_lang**: zh-cn

### symptom_description

> row_number() over(), count() over()慢，执行计划中出现sort、WindowAgg，窗口函数集中在一个DN上运行。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain performance`
  abnormal_pattern_quote: "执行计划中出现Sort和WindowAgg，第3~6步集中在一个DN上进行，使SQL非常缓慢。"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "为了消除对大量数据的WindowAgg，需要对SQL进行改写，目的是通过等价逻辑改写，消除窗口函数。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "改写逻辑：把t2写成with子查询以在join时使用其别名，使用left join (select count() from t2)代替count() over()，使用limit offset代替row_number() over()和对rn的过滤。从PERFORMANCE执行计划可以看到，SQL的运行时间从7s+缩减到了600ms-。"

```

## case_id: gaussdb-dws-data-skew-row-number-partition-null-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: row_number() PARTITION BY 列存在大量 NULL 值导致计算倾斜、SQL 性能慢
- **source_heading**: GaussDB(DWS)性能调优：row_number()的PARTITION BY列倾斜场景的性能优化
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://bbs.huaweicloud.com/blogs/407523
- **source_url_lang**: zh-cn

### symptom_description

> SQL自诊断信息显示在做row_number()函数计算前的PARTITION BY T.ORDER_LINE_ID引入的重分布算子(Streaming(type: REDISTRIBUTE))有计算倾斜，查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值，这必然导致严重的计算倾斜

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜）
  collection_layer: db-interactive-cmd
  collection_method_quote: `SQL自诊断信息显示在做row_number()函数计算前的PARTITION BY T.ORDER_LINE_ID引入的重分布算子(Streaming(type: REDISTRIBUTE))有计算倾斜`
  abnormal_pattern_quote: `Streaming(type: REDISTRIBUTE)有计算倾斜`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: 列统计信息 · ORDER_LINE_ID NULL 比例
  collection_layer: db-system-view
  collection_method_quote: `查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值`
  abnormal_pattern_quote: `ORDER_LINE_ID上87.6^%左右都是NULL值，这必然导致严重的计算倾斜`
  abnormal_pattern_threshold: `> 50% NULL`
  metric_unit: %
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: `查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值，这必然导致严重的计算倾斜`
  linked_diagnostic_step_no: 2
  mitigation_quote: `优化的整体思路是把倾斜值单独拿出来进行row_number()排序操作，这部分数据可以忽略PARTITION BY字段(因为PARTITION BY字段值都一样)，这部分可以借助DWS的vVALUE REDISTRIBUTE优化机制，做全局排序的优化。改写后的SQL如下`

```

## case_id: gaussdb-dws-plan-suboptimal-data-skew-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS数据倾斜——DN间数据分布不均导致性能瓶颈
- **source_heading**: ◇数据倾斜
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://xie.infoq.cn/article/c3e71e83ba437213fb4584e40/
- **source_url_lang**: zh-cn

### symptom_description

> 数据在 DN 之间分布不均匀，可导致数据较多的节点成为性能瓶颈。如果发现数据倾斜严重，会给出如下告警信息：PlanNode[%d] DataSkew:"%s", min_dn_tuples:%.0f, max_dn_tuples:%.0f

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_history · DataSkew warning
  collection_layer: db-system-view
  collection_method_quote: "GaussDB 在执行 SQL 语句时，会对其性能表现进行分析和记录，通过视图和函数等手段呈现给用户。执行完一条代价大于resource_track_cost后，诊断信息会存放在内存hash表中，可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
  abnormal_pattern_quote: "PlanNode[%d] DataSkew:\"%s\", min_dn_tuples:%.0f, max_dn_tuples:%.0f"
  abnormal_pattern_threshold: "max_dn_tuples > min_dn_tuples * 10 且 max_dn_tuples > 100,000"
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: "数据在 DN 之间分布不均匀，可导致数据较多的节点成为性能瓶颈。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-plan-suboptimal-large-table-broadcast-02

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS大表Broadcast导致网络传输量大、查询慢
- **source_heading**: ◇Broadcast 量过大
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://xie.infoq.cn/article/c3e71e83ba437213fb4584e40/
- **source_url_lang**: zh-cn

### symptom_description

> Broadcast 主要适合小表。对于大表来说，通常采用 Hash+重分布（Redistribute）的方式效率更高。如果发现计划中有大表被广播的环节，会给出如下告警信息：PlanNode[%d] Large Table in Broadcast "%s"

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_history · Large Table in Broadcast warning
  collection_layer: db-system-view
  collection_method_quote: "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
  abnormal_pattern_quote: "PlanNode[%d] Large Table in Broadcast \"%s\""
  abnormal_pattern_threshold: "平均广播到每个DN上的数据行数 > 100,000"
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Broadcast 主要适合小表。对于大表来说，通常采用 Hash+重分布（Redistribute）的方式效率更高。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "目前对大表广播的认定标准为平均广播到每个 DN 上的数据行数大于 100,000。"

```

## case_id: gaussdb-dws-plan-suboptimal-spill-overflow-03

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS SQL执行落盘量过大或过早落盘导致性能低下
- **source_heading**: ◇下盘量过大或过早下盘
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://xie.infoq.cn/article/c3e71e83ba437213fb4584e40/
- **source_url_lang**: zh-cn

### symptom_description

> SQL 语句执行过程中，因为内存不足等原因，可能需要将中间结果的全部或一部分转储的磁盘上。下盘可能导致性能低下，应该尽量避免。如果监测到下盘量过大或过早下盘等情况，会给出如下告警信息：• Spill file size large than 256MB • Broadcast size large than 100MB • Early spill

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_history · Spill告警
  collection_layer: db-system-view
  collection_method_quote: "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
  abnormal_pattern_quote: "Spill file size large than 256MB"
  abnormal_pattern_threshold: "> 256MB"
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "下盘可能是因为缓冲区设置得过小，也可能是因为表的连接顺序或连接方式不合理等原因，要结合具体的 SQL 进行分析。可以通过改写 SQL 语句，或者 HINT 指定连接方式等手段来解决。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "可以通过改写 SQL 语句，或者 HINT 指定连接方式等手段来解决。"

```

## case_id: gaussdb-dws-plan-suboptimal-nestloop-large-table-04

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS大表等值连接使用NestLoop导致查询慢
- **source_heading**: ◇大表等值连接使用 NestLoop
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://xie.infoq.cn/article/c3e71e83ba437213fb4584e40/
- **source_url_lang**: zh-cn

### symptom_description

> 如果发现对大表做等值连接时使用了 NestLoop 方式，会给出如下告警信息：PlanNode[%d] Large Table with Equal-Condition use Nestloop"%s"

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_history · NestLoop大表告警
  collection_layer: db-system-view
  collection_method_quote: "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"
  abnormal_pattern_quote: "PlanNode[%d] Large Table with Equal-Condition use Nestloop\"%s\""
  abnormal_pattern_threshold: "内外表中最大行数 > DN数量 * 100,000"
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "如果发现对大表做等值连接时使用了 NestLoop 方式，会给出如下告警信息"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-data-skew-query-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 数据倾斜导致SQL执行不出结果
- **source_heading**: 1 数据倾斜
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 某局点SQL执行慢，涉及大表的SQL执行不出来结果。

### diagnostic_steps

```
[step 1]
  metric_name: 各DN磁盘利用率
  collection_layer: os
  collection_method_quote: `gs_ssh –c "df -h"`
  abnormal_pattern_quote: "查看各个数据磁盘的利用率，会有不均衡的现象。正常情况下，利用率最高和利用率最高的磁盘空间相差不大，如果磁盘利用率相差超过了5%就要引起重视。"
  abnormal_pattern_threshold: `> 5%差异`
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: pgxc_thread_wait_status.wait_status
  collection_layer: db-system-view
  collection_method_quote: `Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;`
  abnormal_pattern_quote: "通过等待视图查看作业的运行情况，发现作业总是等待部分DN，或者个别DN。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [1]

[step 3]
  metric_name: table_skewness / table_distribution
  collection_layer: db-system-view
  collection_method_quote: `select table_skewness('store_sales');`
  abnormal_pattern_quote: "数据最多的dn有22831616行，其他dn都是0行，数据有严重倾斜。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [2]

[step 4]
  metric_name: PGXC_GET_TABLE_SKEWNESS
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [3]

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: "倾斜造成的负面影响非常大。首先，SQL的性能会非常差，因为数据只分布在部分DN，那么SQL运行的时候就只有部分DN参与计算，没有发挥分布式的优势。"
  linked_diagnostic_step_no: 3
  mitigation_quote: "这个列的distinct值比较大，并且没有明显的数据倾斜。也可以把多列定义成分布列。"

```

## case_id: gaussdb-dws-statistics-not-collected-plan-poor-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 统计信息未收集导致优化器估算偏差、执行计划差
- **source_heading**: 2 统计信息未收集
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 执行计划中会有语句未收集统计信息的告警，并且通常E-rows估算非常小。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划统计信息Warning
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过explain verbose/explain performance打印语句的执行计划"
  abnormal_pattern_quote: "执行计划中会有语句未收集统计信息的告警，并且通常E-rows估算非常小。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "统计信息是优化器生成执行计划的基础，没有收集统计信息，优化器生成的执行计划会非常差"
  linked_diagnostic_step_no: 1
  mitigation_quote: "周期性地运行ANALYZE，或者在对表的大部分内容做了更改之后马上执行analyze。"

```

## case_id: gaussdb-dws-statement-not-pushed-down-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 语句不下推导致CN成为性能瓶颈
- **source_heading**: 3 语句不下推
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 不下推语句的执行方式没有利用分布式的优势，他的执行过程相当于把大量的数据和计算过程汇集到一个节点上去做，因此性能往往非常差。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划下推标识（__REMOTE关键字）
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过explain verbose打印语句执行计划"
  abnormal_pattern_quote: "上述执行计划中有__REMOTE关键字，这就表明当前的语句是不下推执行的。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_proc.provolatile / proshippable
  collection_layer: db-system-view
  collection_method_quote: "函数相关的所有属性都在pg_proc这张系统表中可以查到。其中与函数能否下推相关的两个属性是provolatile 和 proshippable。"
  abnormal_pattern_quote: "不下推语句在pg_log中会打印不下推的原因"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "不下推函数的场景主要出现在自定义函数属性定义错误的场景。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "审视用户自定义函数的provolatile属性是否定义正确。如果定义不正确，要修改对应的属性，使它能够下推执行。如果一个函数对于同样的输入，一定有相同的输出，那么这类函数就是IMMUTABLE的。"

```

## case_id: gaussdb-dws-notin-nestloop-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: NOT IN语义导致NestLoop，SQL执行慢
- **source_heading**: 4 not in 和 not exists
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 客户的SQL语句执行慢，执行计划中有NestLoop。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划算子类型（NestLoop）
  collection_layer: db-interactive-cmd
  collection_method_quote: "首先观察SQL语句中有not in 语法；执行计划中有NestLoop"
  abnormal_pattern_quote: "NestLoop是导致语句性能慢的主要原因。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "导致出现这个现象的原因是由not in的语义决定的"
  linked_diagnostic_step_no: 1
  mitigation_quote: "大多数场景下，客户需要的结果集其实是可以通过not exists获得的，因此上述语句可以通过修改将not in 修改为not exists。"

```

## case_id: gaussdb-dws-no-partition-pruning-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 查询条件未包含分区键导致未分区剪枝、全表扫描
- **source_heading**: 5 未分区剪枝
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 三条sql查询慢，查询的分区表总共185亿条数据，查询条件中没有涉及分区键。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划：Partitioned CStore Scan分区扫描范围
  collection_layer: db-interactive-cmd
  collection_method_quote: "和客户收集几个典型的慢sql，分别打印执行计划。"
  abnormal_pattern_quote: "从执行计划中可以看出来，两条sql的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分区扫描上"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "慢sql过滤条件中未涉及分区字段，导致执行计划未分区剪枝，走了全表扫描，性能严重裂化。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "在慢sql的过滤条件中增加分区筛选条件，避免走全表扫描。"

```

## case_id: gaussdb-dws-row-estimate-small-nestloop-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 行数估算过小导致优化器选择NestLoop，查询卡住
- **source_heading**: 6 行数估算过小，走了nestloop
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 查询语句执行慢，卡住无法返回结果

### diagnostic_steps

```
[step 1]
  metric_name: 线程等待状态
  collection_layer: db-system-view
  collection_method_quote: `select * from pg_thread_wait_status where query_id='149181737656737395';`
  abnormal_pattern_quote: "根据线程等待状态，并没有出现都在等待某个DN的情况，初步排除中间结果集偏斜到了同一个DN的情况。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: 进程堆栈（VecNestLoopRuntime）
  collection_layer: os
  collection_method_quote: `gstack 14104`
  abnormal_pattern_quote: "堆栈中有VecNestLoopRuntime，以及结合执行计划，初步判断是由于统计信息不准，优化器评估结果集较少，计划走了nestloop导致性能下降。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] enable_indexscan
  param_name: enable_indexscan
  abnormal_value_pattern: on（默认开启，允许走索引+NestLoop）
  recommended_value: `off`
  recommendation_quote: "通过set enable_indexscan = off;执行计划被改变，走了Hash Left Join，慢sql在3秒左右跑出结果，满足客户需求。"
  risk_if_violated_quote: NULL
  reasoning_quote: "优化器在选择执行计划时，对结果集评估较小，导致计划走了nestloop，性能下降。"
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "优化器在选择执行计划时，对结果集评估较小，导致计划走了nestloop，性能下降。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "通过set set enable_indexscan = off;关闭索引功能，让优化器生成的执行计划不走nestloop，而走Hashjoin。"

```

## case_id: gaussdb-dws-table-bloat-vacuum-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 表数据膨胀未清理脏数据导致性能时快时慢
- **source_heading**: 7 表数据膨胀，未清理脏数据
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 4
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 数据库性能时快时慢问题。GaussDB 数据库性能时快时慢问题，原先几秒钟的sql，目前20几秒出来，导致前台IOC页面数据加载超时，无法对用户提供图表显示。

### diagnostic_steps

```
[step 1]
  metric_name: 活跃SQL及CREATE INDEX语句
  collection_layer: db-system-view
  collection_method_quote: `select * from pg_stat_activity where state !='idle' and usename !='omm';`
  abnormal_pattern_quote: "查询当前活跃sql，发现有大量的create index语句"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: 表数据倾斜
  collection_layer: db-system-view
  collection_method_quote: `select table_skewness('ioc_dm.m_ss_index_event');`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

[step 3]
  metric_name: 内存参数：max_process_memory, shared_buffers
  collection_layer: db-shell
  collection_method_quote: "检查内存相关参数，设置不合理"
  abnormal_pattern_quote: "单节点总内存大小为256G，max_process_memory为12G，设置过小，shared_buffers为32M，设置过小"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [2]

```

### likely_causes

```
[parameter_causes · cause 1] max_process_memory
  param_name: max_process_memory
  abnormal_value_pattern: 设置过小（12G，节点总内存256G）
  recommended_value: `25GB`
  recommendation_quote: `gs_guc set -Z coordinator -Z datanode -N all -I all -c "max_process_memory=25GB"`
  risk_if_violated_quote: "内存参数设置不合理"
  reasoning_quote: "单节点总内存大小为256G，max_process_memory为12G，设置过小"
  linked_diagnostic_step_no: 3

[parameter_causes · cause 2] shared_buffers
  param_name: shared_buffers
  abnormal_value_pattern: 设置过小（32M）
  recommended_value: `8GB`
  recommendation_quote: `gs_guc set -Z coordinator -Z datanode -N all -I all -c "shared_buffers=8GB"`
  risk_if_violated_quote: "内存参数设置不合理"
  reasoning_quote: "shared_buffers为32M，设置过小"
  linked_diagnostic_step_no: 3

[parameter_causes · cause 3] work_mem
  param_name: work_mem
  abnormal_value_pattern: 设置偏小（64M）
  recommended_value: `128MB`
  recommendation_quote: `gs_guc set -Z coordinator -Z datanode -N all -I all -c "work_mem=128MB"`
  risk_if_violated_quote: NULL
  reasoning_quote: "work_mem：CN：64M 、DN：64M"
  linked_diagnostic_step_no: 3

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "大量表频繁增删改，未及时清理，导致脏数据过多，表数据膨胀，查询慢。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对业务涉及到的常用的大表，执行vacuum full操作，清理脏数据"

```

## case_id: gaussdb-dws-in-constant-no-join-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: in常量数量过多未转为join导致查询慢
- **source_heading**: 8 "in 常量"优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.modb.pro/db/48531
- **source_url_lang**: zh-cn

### symptom_description

> 简单的大表过滤的SQL语句中有一个"in 常量"的过滤条件，常量的个数非常多(约有2000多个)，基表数据量比较大，SQL语句执行不出来。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划in条件处理方式
  collection_layer: db-interactive-cmd
  collection_method_quote: "打印语句的执行计划"
  abnormal_pattern_quote: "执行计划中，in条件还是作为普通的过滤条件存在。这种场景下，最优的执行计划应该是将\"in 常量\"转化为join操作性能更好。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] qrw_inlist2join_optmode
  param_name: qrw_inlist2join_optmode
  abnormal_value_pattern: cost_base（默认），优化器估算不准时不转化
  recommended_value: `rule_base`
  recommendation_quote: "这种情况下可以通过设置qrw_inlist2join_optmode为rule_base来规避解决。"
  risk_if_violated_quote: "如果优化器估算不准，可能会出现需要转化的场景没有做转化，导致性能较差。"
  reasoning_quote: "qrw_inlist2join_optmode可以控制把\"in 常量\"转join的行为。默认是cost_base的。如果优化器估算不准，可能会出现需要转化的场景没有做转化，导致性能较差。"
  linked_diagnostic_step_no: 1

```

## case_id: dws-case-when-redundant-rewrite-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 大量冗余 CASE WHEN 导致查询性能下降
- **source_heading**: 如何优化包含多个CASE WHEN条件的SQL查询？
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2116.html
- **source_url_lang**: zh-cn

### symptom_description

> 该语句冗长，执行时每个分支的CASE WHEN均需执行，导致查询时间成倍增加，影响查询性能。

### diagnostic_steps

```
[step 1]
  metric_name: SQL 中 CASE WHEN 分支数量与执行次数
  collection_layer: db-interactive-cmd
  collection_method_quote: "在业务查询中，CASE WHEN语句常用来进行条件判断，但如果在SQL查询中存在大量冗余的CASE WHEN"
  abnormal_pattern_quote: "该语句冗长，执行时每个分支的CASE WHEN均需执行，导致查询时间成倍增加"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "该语句冗长，执行时每个分支的CASE WHEN均需执行，导致查询时间成倍增加，影响查询性能。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "将复杂的CASE WHEN计算部分提取出来，放到一个临时的结果集中或者子查询中。这样可以减少在主查询中的重复计算逻辑。"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "将CASE WHEN的逻辑封装成一个函数。这样在查询中只需要调用该函数，而不是多次编写相同的CASE WHEN逻辑。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "再使用自定义函数count_a_gt_value进行查询。"

```

## case_id: dws-data-bloat-disk-shortage-perf-low-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 数据膨胀磁盘空间不足，导致性能降低
- **source_heading**: 数据膨胀磁盘空间不足，导致性能降低
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0629.html
- **source_url_lang**: zh-cn

### symptom_description

> 用户数据膨胀严重，磁盘空间不足，性能低。

### diagnostic_steps

```
[step 1]
  metric_name: 系统表/用户表膨胀情况
  collection_layer: db-system-view
  collection_method_quote: "用户可在管控面执行全库Vacuum/Vacuum Full，以定期进行空间回收"
  abnormal_pattern_quote: "用户数据膨胀严重，磁盘空间不足，性能低。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "用户频繁创建、删除表，导致系统表膨胀严重，需要对系统表执行Vacuum。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "Vacuum目标选择系统表或用户表"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "用户频繁执行UPDATE、DELETE语句，导致用户表膨胀严重，需要对用户表执行Vacuum/Vacuum Full。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "如果用户业务UPDATE、DELETE较多，选择用户表。"

[non_parameter_causes · cause 3] other
  cause_type: other
  description_quote: "VACUUM FULL执行过程中，本身持有8级锁，会阻塞其他业务，导致锁冲突产生，业务本身会陷入锁等待，20分钟后超时报错。因此，在用户配置时间窗内，应尽量避开执行所有处理表的相关业务。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "推荐选择\"周期型任务\"，DWS将自动在自定义时间窗内执行Vacuum。"

```

## case_id: dws-data-skew-distribute-column-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Hash 分布列选择不当导致数据倾斜，部分 DN I/O 短板
- **source_heading**: 步骤4：创建新表并加载数据
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0014.html
- **source_url_lang**: zh-cn

### symptom_description

> 对于Hash分表策略，如果分布列选择不当，可能导致数据倾斜，查询时出现部分DN的I/O短板，从而影响整体查询性能。

### diagnostic_steps

```
[step 1]
  metric_name: 各 DN 数据量分布 (xc_node_id 分组)
  collection_layer: db-system-view
  collection_method_quote: "SELECT a.count,b.node_name FROM (SELECT count(*) AS count,xc_node_id FROM table_name GROUP BY xc_node_id) a, pgxc_node b WHERE a.xc_node_id=b.node_id ORDER BY a.count desc;"
  abnormal_pattern_quote: "不同DN的数据量相差5%以上即可视为倾斜，如果相差10%以上就必须要调整分布列"
  abnormal_pattern_threshold: "> 5% diff (视为倾斜); > 10% diff (必须调整)"
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: "对于Hash分表策略，如果分布列选择不当，可能导致数据倾斜，查询时出现部分DN的I/O短板，从而影响整体查询性能。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "DWS支持多分布列特性，可以更好地满足数据分布的均匀性要求。"

```

## case_id: dws-dirty-page-high-vacuum-full-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS的脏页过高导致磁盘空间膨胀
- **source_heading**: DWS的脏页是如何产生的？
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2143.html
- **source_url_lang**: zh-cn

### symptom_description

> 因此当表的脏页率高时，则认为表内部被标记为已删除的数据占比高。

### diagnostic_steps

```
[step 1]
  metric_name: 表脏页率 (PGXC_STAT_TABLE_DIRTY)
  collection_layer: db-system-view
  collection_method_quote: "DWS提供了查询脏页率的系统视图，具体使用请参见PGXC_STAT_TABLE_DIRTY。"
  abnormal_pattern_quote: "建议对查询脏页率超过80%的非系统表执行VACUUM FULL"
  abnormal_pattern_threshold: "> 80%"
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "DWS采用多版本控制技术（Multi-Version Concurrency Control，简称MVCC）的并发控制机制保证多个事务访问数据库时的一致性和并发性，其优点是读写互不阻塞，缺点则是会造成磁盘膨胀的问题，而MVCC机制是产生脏页的主要原因。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "为了解决脏页率高导致磁盘空间膨胀的问题，DWS提供了VACUUM的功能，可以有效清理delete、update操作后标记的已删除数据"

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: "VACUUM不会释放已经分配好的空间，如果要彻底回收已删除的空间，则需要使用VACUUM FULL。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "为降低磁盘膨胀对数据库性能的影响，建议对查询脏页率超过80%的非系统表执行VACUUM FULL，用户也可根据业务场景自行选择是否执行VACUUM FULL。"

```

## case_id: dws-gds-failed-disk-not-released-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: GDS导入失败后，磁盘占用空间增大
- **source_heading**: GDS导入失败后，磁盘占用空间增大
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0007.html
- **source_url_lang**: zh-cn

### symptom_description

> 使用GDS导入数据失败，触发作业重跑。重新开始数据导入，完成导入作业后查看磁盘空间，发现磁盘占用空间比导入数据量大很多。

### diagnostic_steps

```
[step 1]
  metric_name: GDS导入作业日志
  collection_layer: log-grep
  collection_method_quote: "检测GDS导入作业的日志，查看是否有执行失败的现象。"
  abnormal_pattern_quote: "在导入数据失败后，占用的磁盘空间没有释放。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "在导入数据失败后，占用的磁盘空间没有释放。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对表或者分区执行清理操作。"

```

## case_id: dws-jdbc-processresult-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 在processResult阶段耗时
- **source_heading**: 在processResult阶段耗时
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0204.html
- **source_url_lang**: zh-cn

### symptom_description

> 设置loglevel=3，打开JDBC日志，主要耗时在processResult阶段

### diagnostic_steps

```
[step 1]
  metric_name: FE=>Sync 与 <=BE ParseComplete 日志时间间隔
  collection_layer: log-grep
  collection_method_quote: "用户可查看FE=> Syncr日志和<=BE ParseComplete日志之间的时间间隔"
  abnormal_pattern_quote: "如果时间间隔较久，则判断为数据库执行慢。"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小
  collection_layer: log-grep
  collection_method_quote: "查看日志，如果<=BE DataRow日志出现次数过多，或直接执行SELECT count(*);"
  abnormal_pattern_quote: "查询结果数目过大，则判断为结果集过大。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] fetchSize
  param_name: fetchSize
  abnormal_value_pattern: 默认值导致一次性加载全部结果集
  recommended_value: 较小的值 (如 10)
  recommendation_quote: "设置fetchSize参数为一个较小的值，使数据按批次返回，客户端得到快速响应。"
  risk_if_violated_quote: "结果集过大，一次性全部加载，消耗大量时间。"
  reasoning_quote: "结果集过大，一次性全部加载，消耗大量时间。"
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "JDBC端等待数据库返回的报文时间过长。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "分析SQL执行慢的原因"

```

## case_id: dws-jdbc-modifyjdbccall-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 在modifyJdbcCall和createParameterizedQuery阶段耗时
- **source_heading**: 在modifyJdbcCall和createParameterizedQuery阶段耗时
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0204.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。

### diagnostic_steps

```
[step 1]
  metric_name: modifyJdbcCall / createParameterizedQuery 阶段耗时
  collection_layer: log-grep
  collection_method_quote: "如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。"
  abnormal_pattern_quote: "如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "JDBC本身没办法优化这部分耗时，可在应用端查看是否可优化传入的SQL语句"
  linked_diagnostic_step_no: 1
  mitigation_quote: "可在应用端查看是否可优化传入的SQL语句"

```

## case_id: dws-partition-auto-period-ttl-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 普通分区表无法自动创建/清理分区导致运维成本高
- **source_heading**: 使用DWS分区自动管理功能降低电商和物联网行业数据分区维护成本
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0120.html
- **source_url_lang**: zh-cn

### symptom_description

> 但普通分区表无法自动创建新分区或清理过期分区，需维护人员定期手动操作，导致运维成本居高不下。

### diagnostic_steps

```
[step 1]
  metric_name: 分区表 period / ttl 参数设置
  collection_layer: db-shell
  collection_method_quote: "CREATE TABLE CPU1(...) with (TTL='7 days',PERIOD='1 day', TIME_FORMAT='YYYYMMDD')"
  abnormal_pattern_quote: "普通分区表无法自动创建新分区或清理过期分区，需维护人员定期手动操作"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] period
  param_name: period
  abnormal_value_pattern: 未设置导致无法自动创建分区
  recommended_value: `1 day` (默认; 范围 1 hour ~ 100 years)
  recommendation_quote: "period：设置自动创建分区的间隔时间，默认值为1 day，取值范围：1 hour ~ 100 years。例如period为1 day，则每过一天，就会创建新的分区。"
  risk_if_violated_quote: "普通分区表无法自动创建新分区"
  reasoning_quote: "只要成功设置了表级参数period，即开启了自动创建新分区功能"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] ttl
  param_name: ttl
  abnormal_value_pattern: 未设置导致无法自动淘汰过期分区
  recommended_value: 大于或等于 period (范围 1 hour ~ 100 years)
  recommendation_quote: "表级参数ttl不支持单独存在，必须要提前或同时设置period，并且要大于或等于period。"
  risk_if_violated_quote: "普通分区表无法...清理过期分区"
  reasoning_quote: "ttl：设置自动淘汰分区的时间，取值范围：1 hour ~ 100 years。淘汰分区的策略是通过计算nowtime - 分区boundary time> ttl，满足该条件的分区将被清理掉。"
  linked_diagnostic_step_no: 1

```

## case_id: dws-query-efficiency-degraded-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 分析查询效率异常降低的问题
- **source_heading**: 分析查询效率异常降低的问题
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 4
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0014.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常在几十毫秒内完成的查询，有时会突然需要几秒的时间完成；而通常需要几秒完成的查询，有时需要半小时才能完成。如何分析这种查询效率异常降低的问题呢？

### diagnostic_steps

```
[step 1]
  metric_name: ANALYZE 后的查询性能
  collection_layer: db-interactive-cmd
  collection_method_quote: "使用ANALYZE命令分析数据库。"
  abnormal_pattern_quote: "如果此命令执行后性能恢复或者有所提升，则表明AUTOVACUUM未能很好的完成它的工作，有待进一步分析。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: 查询返回行数
  collection_layer: db-interactive-cmd
  collection_method_quote: "检查查询语句是否返回了多余的数据信息。"
  abnormal_pattern_quote: "对于包含50条记录的表，查询起来是很快的；但是，当表中包含的记录达到50000，查询效率将会有所下降。"
  abnormal_pattern_threshold: NULL
  metric_unit: rows
  prerequisite_steps: []

[step 3]
  metric_name: 主机负载下查询单独运行时延
  collection_layer: db-interactive-cmd
  collection_method_quote: "尝试在数据库没有其他查询或查询较少的时候运行查询语句，并观察运行效率。"
  abnormal_pattern_quote: "如果效率较高，则说明可能是由于之前运行数据库系统的主机负载过大导致查询低效。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 4]
  metric_name: 重复执行同一查询语句的执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: "重复执行相同的查询语句，如果后续执行的查询语句效率提升，则可能是由于上述原因导致。"
  abnormal_pattern_quote: "查询效率低的一个重要原因是查询所需信息没有缓存在内存中，这可能是由于内存资源紧张，缓存信息被其他查询处理覆盖。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "若业务应用中存在只需要部分数据信息，但是查询语句却是返回所有信息的情况，建议修改查询语句，增加LIMIT子句来限制返回的记录数。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "建议修改查询语句，增加LIMIT子句来限制返回的记录数。这样至少使数据库优化器有了一定的优化空间，一定程度上会提升查询效率。"

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: "如果此命令执行后性能恢复或者有所提升，则表明AUTOVACUUM未能很好的完成它的工作，有待进一步分析。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "使用ANALYZE命令分析数据库。"

[non_parameter_causes · cause 3] other
  cause_type: other
  description_quote: "如果效率较高，则说明可能是由于之前运行数据库系统的主机负载过大导致查询低效。"
  linked_diagnostic_step_no: 3
  mitigation_quote: NULL

[non_parameter_causes · cause 4] other
  cause_type: other
  description_quote: "查询效率低的一个重要原因是查询所需信息没有缓存在内存中，这可能是由于内存资源紧张，缓存信息被其他查询处理覆盖。"
  linked_diagnostic_step_no: 4
  mitigation_quote: NULL

```

## case_id: dws-3-0-disk-cache-size-low-hit-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 存算分离场景下 Disk Cache 命中率低导致 OBS 直读多
- **source_heading**: 关于磁盘缓存
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0027.html
- **source_url_lang**: zh-cn

### symptom_description

> 用户查询数据时，会优先到Disk Cache中查看数据是否已存在于本地磁盘，如果不存在则再去OBS读取数据

### diagnostic_steps

```
[step 1]
  metric_name: Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats)
  collection_layer: db-system-view
  collection_method_quote: "通过查询视图pgxc_disk_cache_all_stats可以查看当前缓存的命中率以及各个DN磁盘的使用大小情况"
  abnormal_pattern_quote: "用户查询数据时，会优先到Disk Cache中查看数据是否已存在于本地磁盘，如果不存在则再去OBS读取数据"
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] disk_cache_max_size
  param_name: disk_cache_max_size
  abnormal_value_pattern: 配置过小导致缓存空间不足无法容纳热数据
  recommended_value: EVS 容量的 1/2 (默认值);若列存表没有索引可适当调大
  recommendation_quote: "集群默认的缓存大小（disk_cache_max_size，该参数需联系技术支持设置）配置为：EVS容量的1/2。"
  risk_if_violated_quote: "缩小Disk Cache可用规模后可能带来查询性能下降。"
  reasoning_quote: "如果列存表没有创建索引，则可适当调大缓存配置参数disk_cache_max_size。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] disk_cache_dual_write_option
  param_name: disk_cache_dual_write_option
  abnormal_value_pattern: 默认 hstore_only,首次读普通 v3 表性能差
  recommended_value: `all` (对普通 v3 表和 HStore 表都开启缓存双写)
  recommendation_quote: "开启缓存双写可以提升首次查询数据的性能，即用户在写数据到远端OBS的同时，将数据也写到本地Disk Cache上。当第一次读取数据时，可显著提升读取效率。"
  risk_if_violated_quote: NULL
  reasoning_quote: "用户可通过disk_cache_dual_write_option来设置是否开启缓存双写"
  linked_diagnostic_step_no: 1

```

## case_id: dws-3-0-disk-usage-readonly-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 存算分离场景下 EVS 磁盘空间占用过高触发集群只读
- **source_heading**: 集群空间不足与磁盘缓存空间调整
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0027.html
- **source_url_lang**: zh-cn

### symptom_description

> 容量不足：磁盘空间占用或者文件描述符使用超过ThresholdReadRisk(默认90%)，触发集群只读

### diagnostic_steps

```
[step 1]
  metric_name: EVS 磁盘空间占用百分比
  collection_layer: log-grep
  collection_method_quote: "日志中会出现\"Disk usage on the node %u has reached the read-only threshold 90%\""
  abnormal_pattern_quote: "磁盘空间占用或者文件描述符使用超过ThresholdReadRisk(默认90%)，触发集群只读"
  abnormal_pattern_threshold: "> 90%"
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] disk_cache_max_size
  param_name: disk_cache_max_size
  abnormal_value_pattern: 设置过大占用 EVS 较多空间
  recommended_value: 在没有可清理资源时，可缩小至 300GB 或更小
  recommendation_quote: "在没有可清理的列存2.0表和索引资源的情况下，可将disk_cache_max_size的大小调整为300GB或者更小的数值来缓解空间不足问题"
  risk_if_violated_quote: "缺点是缩小Disk Cache可用规模后可能带来查询性能下降。"
  reasoning_quote: "通过调整disk_cache_max_size参数缩小Disk Cache的实际使用空间缓解集群空间不足"
  linked_diagnostic_step_no: 1

```

## case_id: dws-3-0-batching-import-memory-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 存算分离 3.0 表多分区入库攒批内存消耗过大
- **source_heading**: 入库的攒批开销与建议
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0027.html
- **source_url_lang**: zh-cn

### symptom_description

> 单并发攒批消耗： #Np * #Nb * #Nr

### diagnostic_steps

```
[step 1]
  metric_name: 入库分区数 / Bucket 数 / 攒批内存消耗
  collection_layer: db-shell
  collection_method_quote: "单并发攒批消耗： #Np * #Nb * #Nr 单并发攒批内存消耗： partition_max_cache_size， 默认2GB"
  abnormal_pattern_quote: "假设一次copy数据，涉及1000个分区，#Nb≈10, 单条记录大小1K，攒批大小10000行 单并发攒批消耗： 1000 * 10 * 1K * 10000 * 1.2 = 120G"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] min_batch_rows
  param_name: min_batch_rows
  abnormal_value_pattern: 攒批大小过大
  recommended_value: 通过 SET 调整为更小值 (session 级生效)
  recommendation_quote: "调整攒批大小，通过修改min_batch_rows进行控制，该参数为session级别，可以通过set语句设置当前session生效，或者通过修改配置文件让所有session生效。"
  risk_if_violated_quote: NULL
  reasoning_quote: "数据库内核参数优化：调整攒批大小，通过修改min_batch_rows进行控制"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "最大的影响因素是分区数目，建议用单分区入库，单并发攒批消耗 120G->120M，就可以直接内存攒批了。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "应用层优化：最大的影响因素是分区数目，建议用单分区入库"

```

## case_id: gaussdb-dws-table-bloat-autovacuum-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS表膨胀：autovacuum未开启或回收不及时导致存储增长和性能下降
- **source_heading**: DWS表膨胀原因有哪些？该如何处理？
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 6
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_0103.html
- **source_url_lang**: zh-cn

### symptom_description

> DWS数据仓库中保存的数据在删除后，可能没有释放占用的磁盘空间形成脏数据，导致磁盘浪费、创建及恢复快照性能下降等问题

### diagnostic_steps

```
[step 1]
  metric_name: PGXC_GET_STAT_ALL_TABLES.dirty_page_rate
  collection_layer: db-system-view
  collection_method_quote: `SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_GET_STAT_ALL_TABLES WHERE schemaName NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'cstore', 'pmk') AND dirty_page_rate > 30 ORDER BY table_size DESC, dirty_page_rate DESC;`
  abnormal_pattern_quote: "对于表大小超过10G的表，则执行" VACUUM FULL（dirty_page_rate > 30 为阈值）
  abnormal_pattern_threshold: `> 30`
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] autovacuum
  param_name: autovacuum
  abnormal_value_pattern: 未开启（off）
  recommended_value: `on`
  recommendation_quote: "开启autovacuum"
  risk_if_violated_quote: "用户未开启autovacuum的同时又没有合理的自定义vacuum调度，导致表的脏数据没有及时回收，新的数据又不断插入或更新，膨胀是必然的"
  reasoning_quote: "DWS提供自动执行VACUUM和ANALYZE命令的系统自动清理进程（autovacuum），用于回收被标识为删除状态的记录空间，并更新表的统计数据"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] autovacuum_vacuum_cost_delay
  param_name: autovacuum_vacuum_cost_delay
  abnormal_value_pattern: 开启后使用基于成本的回收策略，IO性能高的系统反而变慢
  recommended_value: `0`
  recommendation_quote: "IO性能较好的系统，关闭autovacuum_vacuum_cost_delay"
  risk_if_violated_quote: "开启autovacuum_vacuum_cost_delay后，会使用基于成本的脏数据回收策略...对于IO性能高的系统，开启autovacuum_vacuum_cost_delay反而会使得垃圾回收的时间变长"
  reasoning_quote: "可以有利于降低VACUUM带来的IO影响，但是对于IO性能高的系统，开启autovacuum_vacuum_cost_delay反而会使得垃圾回收的时间变长"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] autovacuum_max_workers
  param_name: autovacuum_max_workers
  abnormal_value_pattern: 配置过小，超过autovacuum线程数量的表需要等待
  recommended_value: `10`
  recommendation_quote: "增加autovacuum_max_workers和autovacuum_work_mem，同时增加系统内存"
  risk_if_violated_quote: "如果数据库的表很多，而且都比较大，那么当需要vacuum的表超过了配置autovacuum_max_workers的数量，这些表就要等待空闲的autovacuum线程"
  reasoning_quote: "所有自动清理线程繁忙，某些表产生的脏数据超过阈值，但是在此期间没有autovacuum线程可以处理脏数据回收的事情，可能发生表膨胀"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 4] autovacuum_naptime
  param_name: autovacuum_naptime
  abnormal_value_pattern: 设置间隔时间过长
  recommended_value: `1`
  recommendation_quote: NULL
  risk_if_violated_quote: "autovacuum_naptime设置间隔时间过长"
  reasoning_quote: "autovacuum_naptime设置间隔时间过长"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "数据库中存在长SQL或带XID的长事务，在此SQL执行时间范围内或在此事务过程中产生的脏数据无法回收，导致数据库膨胀"
  linked_diagnostic_step_no: 1
  mitigation_quote: "应用程序设计时，尽量避免下列操作：打开游标后不关闭；在不必要的场景使用repeatable read或serializable事务隔离级别；对大的数据库执行gs_dump进行逻辑备份；长时间不关闭申请了事务号的事务"

[non_parameter_causes · cause 2] hardware-disk
  cause_type: hardware-disk
  description_quote: "当数据库非常繁忙时，如果IO性能较差，会导致回收脏数据变慢，从而导致表膨胀"
  linked_diagnostic_step_no: 1
  mitigation_quote: "提高系统的IO能力"

```

## case_id: gaussdb-dws-plan-suboptimal-index-large-result-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS返回结果集过大时索引失效导致查询走全表扫描
- **source_heading**: 场景一：返回结果集很大
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2105.html
- **source_url_lang**: zh-cn

### symptom_description

> 对表建立索引可提高数据库查询性能，但有时会出现建立了索引，但查询计划中却发现索引没有被使用的情况。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · 是否使用Index Scan
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain verbose select * from test where a = 101;`
  abnormal_pattern_quote: "多数情况下，Index Scan要比Seq Scan快。但是如果获取的结果集占所有数据的比重很大时（超过70%），这时Index Scan因为要先扫描索引再读表数据反而不如直接全表扫描的速度快。"
  abnormal_pattern_threshold: "结果集 > 70% 全表数据"
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "如果获取的结果集占所有数据的比重很大时（超过70%），这时Index Scan因为要先扫描索引再读表数据反而不如直接全表扫描的速度快。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-plan-suboptimal-index-no-analyze-02

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS表未及时ANALYZE导致索引未被使用
- **source_heading**: 场景二：未及时ANALYZE
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2105.html
- **source_url_lang**: zh-cn

### symptom_description

> ANALYZE更新表的统计信息，如果表未执行ANALYZE或最近一次执行完ANALYZE后表进行过数据量较大的增删操作，会导致统计信息不准，该场景下也可能导致查询表时没有使用索引。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · 是否选择IndexScan
  collection_layer: db-interactive-cmd
  collection_method_quote: "对表执行ANALYZE更新统计信息。"
  abnormal_pattern_quote: "如果表未执行ANALYZE或最近一次执行完ANALYZE后表进行过数据量较大的增删操作，会导致统计信息不准，该场景下也可能导致查询表时没有使用索引。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "ANALYZE更新表的统计信息，如果表未执行ANALYZE或最近一次执行完ANALYZE后表进行过数据量较大的增删操作，会导致统计信息不准，该场景下也可能导致查询表时没有使用索引。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "优化方法：对表执行ANALYZE更新统计信息。"

```

## case_id: gaussdb-dws-plan-suboptimal-index-func-03

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS过滤条件使用函数或隐式类型转换导致索引失效
- **source_heading**: 场景三：过滤条件使用了函数或隐式类型转化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2105.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果在过滤条件中使用了计算、函数、隐式类型转化，都可能导致无法选择索引。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE · Index Scan vs Seq Scan
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain verbose select * from test where a  = 101;`
  abnormal_pattern_quote: "where a = 101，where a = 102 - 1都使用了a列上的索引，但是where a + 1 = 102没有使用索引。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "如果在过滤条件中使用了计算、函数、隐式类型转化，都可能导致无法选择索引。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-query-slow-max-active-statements-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS普通用户查询慢——受max_active_statements资源管控排队
- **source_heading**: 场景一：普通用户受资源管理的管控
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2112.html
- **source_url_lang**: zh-cn

### symptom_description

> DWS在使用过程中会出现普通用户比dbadmin用户执行慢的场景主要有以下三种：

### diagnostic_steps

```
[step 1]
  metric_name: 查询等待状态 · waiting in queue
  collection_layer: db-system-view
  collection_method_quote: "普通用户主要在waiting in queue/waiting in global queue时。当前的活跃语句数超过max_active_statements限制导致的普通用户排队，由于管理员用户不受管控所以无需排队。"
  abnormal_pattern_quote: "普通用户在排队：waiting in queue/waiting in global queue/waiting in ccn queue."
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] max_active_statements
  param_name: max_active_statements
  abnormal_value_pattern: 值过小，活跃语句数超过限制
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: "当前的活跃语句数超过max_active_statements限制导致的普通用户排队"
  reasoning_quote: "当前的活跃语句数超过max_active_statements限制导致的普通用户排队，由于管理员用户不受管控所以无需排队。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-query-slow-permission-or-filter-02

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS普通用户查询慢——系统视图权限OR条件逐一判断耗时
- **source_heading**: 场景二：执行计划中的or条件对普通用户执行语句逐一判断耗时
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2112.html
- **source_url_lang**: zh-cn

### symptom_description

> 执行计划中的or条件里有权限相关的判断，此场景多发生在使用系统视图时。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · 系统视图权限OR filter
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过执行计划可以看到系统视图中的权限判断中多用or条件判断：pg_has_role(c.relowner, 'USAGE'::text) OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text)"
  abnormal_pattern_quote: "普通用户的or条件需要逐一判断，如果数据库中表个数比较多，最终会导致普通用户比dbadmin需要更长的执行时间。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "由于dbadmin用户pg_has_role总能返回true，因此or之后的条件无需继续判断；而普通用户的or条件需要逐一判断，如果数据库中表个数比较多，最终会导致普通用户比dbadmin需要更长的执行时间。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "这种场景如果输出结果集很少，可以考虑尝试设置set enable_hashjoin = off; set enable_seqscan = off; 走index + nestloop的计划。"

```

## case_id: gaussdb-dws-data-skew-bad-dist-key-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 分布列选择不当导致数据倾斜，影响查询性能和磁盘空间
- **source_heading**: 如何调整DWS分布列？
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2126.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果表的分布列选择不当，在数据导入后有可能出现数据分布倾斜，进而导致某些磁盘的使用明显高于其他磁盘，极端情况下会导致集群只读。对于Hash分表策略，存在数据倾斜情况下，查询时出现部分DN的I/O短板，从而影响整体查询性能。

### diagnostic_steps

```
[step 1]
  metric_name: 各DN数据量分布
  collection_layer: db-shell
  collection_method_quote: `SELECT pg_get_tabledef('customer_t1');`
  abnormal_pattern_quote: "不同DN的数据量相差5%以上即可视为倾斜，如果相差10%以上就必须要调整分布列。"
  abnormal_pattern_threshold: `> 10%`
  metric_unit: ratio
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: "如果表的分布列选择不当，在数据导入后有可能出现数据分布倾斜，进而导致某些磁盘的使用明显高于其他磁盘，极端情况下会导致集群只读。对于Hash分表策略，存在数据倾斜情况下，查询时出现部分DN的I/O短板，从而影响整体查询性能。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "ALTER TABLE customer_t1 DISTRIBUTE BY hash (c_customer_sk); -- 将分布列修改为更均匀分布的列"

```

## case_id: gaussdb-dws-statement-not-pushed-down-volatile-func-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 自定义函数provolatile属性定义错误导致语句不下推，CN成为性能瓶颈
- **source_heading**: 语句下推调优 · 实例分析：自定义函数
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0447.html
- **source_url_lang**: zh-cn

### symptom_description

> 在"发送语句的分布式执行计划"策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划下推标识
  collection_layer: db-interactive-cmd
  collection_method_quote: "将GUC参数\"enable_fast_query_shipping\"设置为off，使查询优化器使用分布式框架策略；查看执行计划。如果执行计划中有Data Node Scan节点，那么此执行计划为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。"
  abnormal_pattern_quote: "可见，func_percent_2并没有被下推，而是将ss_sales_price和ss_list_price收到CN上，再进行计算，消耗大量CN的资源，而且计算缓慢。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pg_proc.provolatile / proshippable
  collection_layer: db-system-view
  collection_method_quote: "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE。另外，在pg_proc中的proshippable字段，取值范围为t/f/NULL"
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
  mitigation_quote: "如果是自定义函数，建议分析客户业务场景，看函数的provolatile和proshippable属性定义是否正确。对于自定义函数，如果对于确定的输入，有确定的输出，则应将函数定义为immutable类型。（TPCDS 1000X，3CN18DN，查询效率提升100倍以上）"

```

## case_id: gaussdb-dws-with-recursive-not-pushed-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: WITH RECURSIVE查询不下推场景导致性能差
- **source_heading**: 不支持下推的语法 · With Recursive
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0447.html
- **source_url_lang**: zh-cn

### symptom_description

> 在进行性能调优的时候，应尽量避免只能选择该策略的查询语句。

### diagnostic_steps

```
[step 1]
  metric_name: CN日志中不下推原因
  collection_layer: log-grep
  collection_method_quote: "不下推语句在pg_log中会打印不下推的原因。LOG: SQL can't be shipped, reason: ..."
  abnormal_pattern_quote: "LOG: SQL can't be shipped, reason: With-Recursive does not contain \"ALL\" to bind recursive & none-recursive branches"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "With Recursive当前版本不支持下推的场景和原因如下：包含外表、HDFS表的查询场景；多nodegroup场景；UNION不带ALL，需要去重；基表中有系统表；基表扫描只有VALUES子句"
  linked_diagnostic_step_no: 1
  mitigation_quote: "一般都可以通过等价改写规避执行计划不能下推的问题。"

```

## case_id: gaussdb-dws-plan-suboptimal-missing-analyze-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS未收集统计信息导致查询执行计划不优（查询性能差）
- **source_heading**: 实例分析1：未收集统计信息导致查询性能差
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-dws/dws_04_0449.html
- **source_url_lang**: zh-cn

### symptom_description

> 在很多场景中，由于查询中涉及到的表或列没有收集统计信息，对查询性能产生很大的影响。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE WARNING信息 · 统计信息缺失
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过EXPLAIN VERBOSE执行query分析执行计划时会提示WARNING信息"
  abnormal_pattern_quote: "WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan."
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "由于查询中涉及到的表或列没有收集统计信息，对查询性能产生很大的影响。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "DWS是基于代价估算生成的最优执行计划。优化器需要根据ANALYZE收集的统计信息行数估算和代价估算，因此统计信息对优化器行数估算和代价估算起着至关重要的作用。"

```

## case_id: gaussdb-dws-query-slow-hstore-delta-bloat-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: HStore Delta表膨胀导致入库性能劣化
- **source_heading**: MERGE相关
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0029.html
- **source_url_lang**: zh-cn

### symptom_description

> 入库速度不得超过MERGE处理能力。通过控制入库并发防止Delta表膨胀。

### diagnostic_steps

```
[step 1]
  metric_name: HStore Delta表大小 vs 主表CU数据
  collection_layer: db-system-view
  collection_method_quote: NULL
  abnormal_pattern_quote: "Delta表空间复用受oldestXmin影响。长时间运行的事务可能导致空间复用延迟和膨胀。"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] autovacuum_max_workers_hstore
  param_name: autovacuum_max_workers_hstore
  abnormal_value_pattern: 配置过小，MERGE能力不足以消化入库速度
  recommended_value: `3`
  recommendation_quote: "设置hstore表automerge工作线程的数量，autovacuum_max_workers的取值一定大于autovacuum_max_workers_hstore取值，建议autovacuum_max_workers=6，autovacuum_max_workers_hstore=3。"
  risk_if_violated_quote: "入库速度不得超过MERGE处理能力。通过控制入库并发防止Delta表膨胀。"
  reasoning_quote: "设置hstore表automerge工作线程的数量，autovacuum_max_workers的取值一定大于autovacuum_max_workers_hstore取值"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] autovacuum_naptime
  param_name: autovacuum_naptime
  abnormal_value_pattern: 默认值过大，autovacuum轮询间隔过长
  recommended_value: `20s`
  recommendation_quote: "控制autovacuum的轮询间隔。推荐值：20s"
  risk_if_violated_quote: NULL
  reasoning_quote: "控制autovacuum的轮询间隔。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-query-slow-realtime-numa-codegen-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 实时数仓enable_codegen/enable_numa_bind参数未优化导致性能差
- **source_heading**: 实时数仓GUC参数最佳配置
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0029.html
- **source_url_lang**: zh-cn

### symptom_description

> 默认值60s的定期清理时间间隔，对毫秒级业务性能影响较大，单个线程重新创建的开销大约需要300ms，有毫秒级性能敏感场景建议调大。

### diagnostic_steps

```
[step 1]
  metric_name: enable_codegen 参数状态
  collection_layer: db-shell
  collection_method_quote: `SHOW turbo_engine_version;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_codegen
  param_name: enable_codegen
  abnormal_value_pattern: 默认on，短查询动态生成执行代码申请内存开销大
  recommended_value: `off`
  recommendation_quote: "修改enable_codegen为off，减少短查询动态生产执行代码时申请内存的开销。"
  risk_if_violated_quote: NULL
  reasoning_quote: "修改enable_codegen为off，减少短查询动态生产执行代码时申请内存的开销。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] enable_numa_bind
  param_name: enable_numa_bind
  abnormal_value_pattern: DN未开启NUMA绑定，跨numa访问进程开销大
  recommended_value: `DN取值设置为on，CN取值设置为off`
  recommendation_quote: "修改DN上的NUMA为on，CN上NUMA为off，numa进程绑定可减少跨numa访问进程的开销。"
  risk_if_violated_quote: NULL
  reasoning_quote: "numa进程绑定可减少跨numa访问进程的开销。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] abnormal_check_general_task
  param_name: abnormal_check_general_task
  abnormal_value_pattern: 默认60s，频繁清理空闲连接导致毫秒级业务受损
  recommended_value: `3600`
  recommendation_quote: "修改CM清理空闲连接的时间abnormal_check_general_task取值，从默认值60修改为3600，减少反复建立连接的开销。"
  risk_if_violated_quote: "默认值60s的定期清理时间间隔，对毫秒级业务性能影响较大，单个线程重新创建的开销大约需要300ms，有毫秒级性能敏感场景建议调大。"
  reasoning_quote: "默认值60s的定期清理时间间隔，对毫秒级业务性能影响较大"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-cpu-high-stream-count-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: CPU 持续飙高 · TopSQL 识别 Stream 算子数超阈值的语句
- **source_heading**: 案例1：某客户集群出现系统级性能问题，CPU持续飚高，业务受阻
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0033.html
- **source_url_lang**: zh-cn

### symptom_description

> 某客户集群出现系统级性能问题，CPU持续飚高，业务受阻。通过TopSQL历史视图查询到有10+业务SQL存在stream数超过100，判断为CPU高的原因。

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_info · Streaming 算子数（stream_count）
  collection_layer: db-system-view
  collection_method_quote: `SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM pgxc_wlm_session_info ORDER BY stream_count DESC limit 100;`
  abnormal_pattern_quote: `通过TopSQL历史视图查询到有10+业务SQL存在stream数超过100，判断为CPU高的原因`
  abnormal_pattern_threshold: `> 100`
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: pgxc_wlm_session_info · max_cpu_time（高CPU语句）
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_wlm_session_info WHERE start_time > 'xxxx-xx-xx' AND start_time < 'xxxx-xx-xx' ORDER BY max_cpu_time desc;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `通过TopSQL历史视图查询到有10+业务SQL存在stream数超过100，判断为CPU高的原因`
  linked_diagnostic_step_no: 1
  mitigation_quote: `针对此业务SQL进行下线并进行优化后，问题解决。`

```

## case_id: gaussdb-dws-query-slow-plan-jump-stale-stats-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: SQL 性能突然下降：统计信息不准导致执行计划跳变
- **source_heading**: 案例2：业务语句性能下降，业务起初较快后来变慢
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0033.html
- **source_url_lang**: zh-cn

### symptom_description

> 业务语句性能下降，业务起初较快后来变慢。因为TopSQL记录了一些语句的执行情况和资源消耗情况，在定位性能问题的时候非常有帮助，比如周期执行的SQL，突然有一天变慢了，可以通过分析语句的执行时间和阻塞时间判断是语句被阻塞了（排队等）还是执行慢了，通过记录的执行计划分析语句为什么慢了，是不是当时的统计信息统计不准，还是没有对表做ANALYZE，也可以根据下盘量大小分析是不是下盘量大造成的性能变慢。

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史）
  collection_layer: db-system-view
  collection_method_quote: `SELECT start_time, block_time, duration, sql_hash, warning, max_peak_memory, max_spill_size, query_plan FROM pgxc_wlm_session_info were start_time > 'xxxx-xx-xx xx:xx' and sql_hash = 'xxx' ORDER BY start_time desc limit 10;`
  abnormal_pattern_quote: `找到对应的快慢语句后，对比其执行计划query_plan，发现执行计划跳变严重。`
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `统计信息不准，导致计划跳变，是十分常见语句变慢原因，ANALYZE不影响读写，遇见语句变慢可预先做ANALYZE。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `对相应的表做ANALYZE后，恢复合理计划，语句性能恢复。ANALYZE dwrdim_dw1.dwr_dim_region_rc_d;`

```

## case_id: gaussdb-dws-query-slow-long-running-operator-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 作业长时间运行不结束：通过算子级 TopSQL 定位瓶颈算子
- **source_heading**: 案例3：作业长时间运行不结束
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0033.html
- **source_url_lang**: zh-cn

### symptom_description

> 在作业无排队无死锁正常运行期间，发现作业长时间不结束，此时可查看算子级别的实时TopSQL监控，能够看出哪个算子执行时间长，通过算子执行时间和已处理行数等信息，确定是否需要终止SQL。

### diagnostic_steps

```
[step 1]
  metric_name: resource_track_level · operator_realtime 级别实时算子监控
  collection_layer: db-system-view
  collection_method_quote: `SET resource_track_level = 'operator_realtime';`
  abnormal_pattern_quote: `能够看出哪个算子执行时间长，通过算子执行时间和已处理行数等信息，确定是否需要终止SQL。`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] resource_track_level
  param_name: resource_track_level
  abnormal_value_pattern: 默认 query 级别，无法显示算子级实时执行进度
  recommended_value: `operator_realtime`（定位长时间运行SQL时）
  recommendation_quote: `开启实时算子监控：SET resource_track_level = 'operator_realtime';`
  risk_if_violated_quote: `在作业无排队无死锁正常运行期间，发现作业长时间不结束，此时可查看算子级别的实时TopSQL监控，能够看出哪个算子执行时间长`
  reasoning_quote: `在作业无排队无死锁正常运行期间，发现作业长时间不结束，此时可查看算子级别的实时TopSQL监控，能够看出哪个算子执行时间长，通过算子执行时间和已处理行数等信息，确定是否需要终止SQL。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-lock-contention-pgxc-stat-activity-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 使用 PGXC_STAT_ACTIVITY 视图定位 DWS 慢 SQL、连接积压与业务阻塞
- **source_heading**: 使用PGXC_STAT_ACTIVITY视图分析正在执行的SQL以处理DWS业务阻塞
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0057.html
- **source_url_lang**: zh-cn

### symptom_description

> 在开发过程中，开发者常遇到SQL连接数超限、SQL查询时间过长、SQL查询阻塞等问题

### diagnostic_steps

```
[step 1]
  metric_name: PGXC_STAT_ACTIVITY · state / waiting / enqueue
  collection_layer: db-system-view
  collection_method_quote: `SELECT coorname, usename,client_addr,application_name,state,waiting,enqueue,pid FROM PGXC_STAT_ACTIVITY WHERE DATNAME='数据库名称';`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start)
  collection_layer: db-system-view
  collection_method_quote: `SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle' order by 1 desc;`
  abnormal_pattern_quote: `查询会返回按执行时间长短从大到小排列的查询语句列表。第一条结果就是当前系统中执行时间最长的查询语句。`
  abnormal_pattern_threshold: NULL
  metric_unit: interval
  prerequisite_steps: []

[step 3]
  metric_name: PGXC_STAT_ACTIVITY · waiting=true 阻塞查询
  collection_layer: db-system-view
  collection_method_quote: `SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;`
  abnormal_pattern_quote: `大部分场景下，阻塞是因为系统内部锁而导致的，waiting字段才显示为true，此阻塞可在视图pgxc_stat_activity中体现。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 4]
  metric_name: pg_locks · 阻塞会话与持锁会话关联
  collection_layer: db-system-view
  abnormal_pattern_quote: `该查询返回会话ID、CN名称、用户信息、查询状态，以及导致阻塞的表、模式信息。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [3]

```

### likely_causes

```
[parameter_causes · cause 1] track_activities
  param_name: track_activities
  abnormal_value_pattern: 未开启，无法收集当前活动查询运行信息
  recommended_value: `on`
  recommendation_quote: `设置参数track_activities为on：SET track_activities = on; 当此参数为on时，数据库系统才会收集当前活动查询的运行信息。`
  risk_if_violated_quote: NULL
  reasoning_quote: `设置参数track_activities为on：当此参数为on时，数据库系统才会收集当前活动查询的运行信息。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-query-slow-flink-connection-timeout-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Flink 写入 DWS 时报 canceling statement due to statement timeout，connectionTimeOut 默认值过小
- **source_heading**: Flink写入DWS报 canceling statement due to statement timeout
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0015.html
- **source_url_lang**: zh-cn

### symptom_description

> Flink写入DWS报以下错误，此问题一般为SQL执行超时导致。canceling statement due to statement timeout

### diagnostic_steps

```
[step 1]
  metric_name: DWS-Connector connectionTimeOut 默认值
  collection_layer: db-shell
  collection_method_quote: `DWS-Connector默认超时时间connectionTimeOut为5min，可调大该值。`
  abnormal_pattern_quote: `DWS-Connector默认超时时间connectionTimeOut为5min`
  abnormal_pattern_threshold: `5min (默认值过小)`
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] connectionTimeOut
  param_name: connectionTimeOut
  abnormal_value_pattern: 默认值 5min (300000ms)，在大批量写入场景下不足
  recommended_value: `600000` (ms，即 10min 或更大)
  recommendation_quote: `在sink表定义的with参数中增加connectionTimeOut参数，单位为毫秒（ms），配置参考如下：'connectionTimeOut' = '600000'`
  risk_if_violated_quote: `Flink写入DWS报以下错误，此问题一般为SQL执行超时导致。canceling statement due to statement timeout`
  reasoning_quote: `DWS-Connector默认超时时间connectionTimeOut为5min，可调大该值。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-lock-contention-wait-timeout-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 执行SQL时出现LOCK_WAIT_TIMEOUT锁等待超时
- **source_heading**: 执行SQL时出现表死锁，提示LOCK_WAIT_TIMEOUT锁等待超时
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0018.html
- **source_url_lang**: zh-cn

### symptom_description

> 执行SQL时出现LOCK_WAIT_TIMEOUT锁等待超时的错误。

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_lock_conflicts 锁冲突视图
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_lock_conflicts;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本）
  collection_layer: db-system-view
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] lockwait_timeout
  param_name: lockwait_timeout
  abnormal_value_pattern: 默认值20分钟，业务并发高时可能需要调整
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: "当申请的锁等待时间超过GUC参数lockwait_timeout的设定值时，系统会报LOCK_WAIT_TIMEOUT的错误。"
  reasoning_quote: "还可以通过设置GUC参数lockwait_timeout，控制单个锁的最长等待时间，即单个锁的等待超时时间。lockwait_timeout单位为毫秒（ms），默认值为20分钟。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "这种情况一般是因为业务调度不太合理，建议合理安排各个业务的调度时间。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "查询到阻塞的表及模式信息后，请根据实际查询语句ID结束会话：SELECT pgxc_terminate_query(query_id);"

```

## case_id: gaussdb-dws-write-slow-single-insert-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 往DWS写数据慢，客户端数据积压：单条INSERT低并发场景吞吐不足
- **source_heading**: 往DWS写数据慢，客户端数据会有积压
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0040.html
- **source_url_lang**: zh-cn

### symptom_description

> 客户端往DWS写入数据较慢，客户端数据会有积压。

### diagnostic_steps

```
[step 1]
  metric_name: 写入方式
  collection_layer: db-shell
  collection_method_quote: "如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈"
  abnormal_pattern_quote: "如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "INSERT是最简单的一种数据写入方式，适合数据写入量不大，并发度不高的场景。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "建议选择其他更加高效的数据导入方式，例如使用COPY方式导入数据；增大客户端并发数。"

```

## case_id: gaussdb-dws-query-slow-blocked-or-stale-stats-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: SQL 执行慢：阻塞或统计信息失效导致性能低
- **source_heading**: SQL执行很慢，性能低，有时长时间运行未结束
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0041.html
- **source_url_lang**: zh-cn

### symptom_description

> SQL执行很慢，性能低，有时长时间运行未结束。

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_stat_activity · state / waiting / query
  collection_layer: db-system-view
  collection_method_quote: `SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';`
  abnormal_pattern_quote: `查看当前处于阻塞状态的查询语句：SELECT coorname, pid,datname, usename, state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle' and waiting=true;`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `如果存在语句阻塞，根据所查找的问题会话的线程ID，结束阻塞的执行语句。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `execute direct on (cn_5001) 'SELECT pg_terminate_backend(pid)';`

```

## case_id: gaussdb-dws-memory-pressure-oom-query-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS 集群内存临时不可用 (memory is temporarily unavailable)
- **source_heading**: 集群报错内存溢出
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0051.html
- **source_url_lang**: zh-cn

### symptom_description

> 查看日志提示：[ERROR] Mpp task queryDataAnalyseById or updateDataAnalyseHistoryEndTimesAndResult fail, dataAnalyseId:17615 org.postgresql.util.PSQLException: ERROR: memory is temporarily unavailable

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_total_memory_detail;`
  abnormal_pattern_quote: `观察是否有实例的dynamic_used_memory已经大于或者接近于该实例的max_dynamic_memory，出现上述报错，一般为dynamic_used_memory达到上限。`
  abnormal_pattern_threshold: `dynamic_used_memory >= max_dynamic_memory`
  metric_unit: bytes
  prerequisite_steps: []

[step 2]
  metric_name: pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent
  collection_layer: db-system-view
  collection_method_quote: `SELECT nodename,pid,dbname,username,application_name,min_peak_memory,max_peak_memory,average_peak_memory,memory_skew_percent,substr(query,0,50) as query FROM pgxc_wlm_session_statistics;`
  abnormal_pattern_quote: `根据结果中的max_peak_memory以及memory_skew_percent值，较大的值就是消耗内存较多的语句。`
  abnormal_pattern_threshold: NULL
  metric_unit: KB
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `存在部分SQL语句使用内存资源过多，造成内存资源耗尽，其余语句执行作业时无法分配到内存就提示内存不足。`
  linked_diagnostic_step_no: 2
  mitigation_quote: `根据步骤2查询的会话信息，通过执行pg_terminate_backend函数结束相应会话，即可恢复内存。恢复后可根据实际业务情况重新优化该SQL语句。`

```

## case_id: gaussdb-dws-disk-space-column-table-bloat-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 列存表多次UPDATE后出现表膨胀
- **source_heading**: 列存表更新失败或多次更新后出现表膨胀
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0052.html
- **source_url_lang**: zh-cn

### symptom_description

> 多次对列存表UPDATE，发现表大小膨胀了十多倍。

### diagnostic_steps

```
[step 1]
  metric_name: 列存表物理大小 vs 有效数据量
  collection_layer: db-shell
  collection_method_quote: NULL
  abnormal_pattern_quote: "多次对列存表UPDATE，发现表大小膨胀了十多倍。"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "列存表的更新操作，空间不会回收旧记录。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对列存表更新操作后，需要进行VACUUM FULL清理。VACUUM FULL table_name;"

```

## case_id: gaussdb-dws-data-skew-hash-dist-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Hash 分布表数据倾斜导致 SQL 执行慢或无结果
- **source_heading**: 数据倾斜导致SQL执行慢，大表SQL执行无结果
- **diagnostic_steps_count**: 5
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0072.html
- **source_url_lang**: zh-cn

### symptom_description

> 某场景下SQL执行慢，涉及大表的SQL执行不出来结果。

### diagnostic_steps

```
[step 1]
  metric_name: 各节点磁盘使用率均衡性
  collection_layer: db-system-view
  collection_method_quote: `登录DWS控制台。在"集群列表"页面，找到需要查看监控的集群。在指定集群所在行的"操作"列，单击"监控面板"。选择"监控 > 节点监控 > 磁盘"，查看磁盘使用率。`
  abnormal_pattern_quote: `各个数据磁盘的利用率，会有不均衡的现象。正常情况下，利用率最高和利用率最低的磁盘空间相差不大，如果磁盘利用率相差超过了5%就要注意是不是有资源倾斜的情况。`
  abnormal_pattern_threshold: `> 5% 差值`
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: pgxc_thread_wait_status · 作业等待 DN 分布
  collection_layer: db-system-view
  collection_method_quote: `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;`
  abnormal_pattern_quote: `发现作业总是等待部分DN或者个别DN`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [1]

[step 3]
  metric_name: explain performance · DN 行数与耗时分布
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain performance select avg(ss_wholesale_cost) from store_sales;`
  abnormal_pattern_quote: `基表scan的时间：最快的DN耗时5ms，最慢的DN耗时1173ms。数据分布情况：某些DN有22831616行，其他DN都是0行，数据有严重倾斜。`
  abnormal_pattern_threshold: NULL
  metric_unit: ms / rows
  prerequisite_steps: [2]

[step 4]
  metric_name: table_skewness · 数据倾斜率
  collection_layer: db-system-view
  collection_method_quote: `SELECT table_skewness('store_sales');`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: ratio
  prerequisite_steps: [3]

[step 5]
  metric_name: pgxc_get_table_skewness · 全库倾斜视图
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: `倾斜造成以下负面影响：SQL的性能会非常差，因为数据只分布在部分DN，那么SQL运行的时候就只有部分DN参与计算，没有发挥分布式的优势。会导致资源倾斜，尤其是磁盘。可能部分磁盘的空间已经接近极限，但是其他磁盘利用率很低。可能出现部分节点CPU过高等问题。`
  linked_diagnostic_step_no: 3
  mitigation_quote: `如果此列的distinct值比较大，并且没有明显的数据倾斜，也可以把多列定义成分布列。选用经常做JOIN或group by的列，可以减少STREAM运算。不推荐以下分布键选择方式：分布列用默认值（第一列）。分布列用sequence自增生成。`

```

## case_id: gaussdb-dws-query-slow-missing-statistics-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 未收集统计信息导致查询性能差
- **source_heading**: 未收集统计信息导致查询性能差
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0073.html
- **source_url_lang**: zh-cn

### symptom_description

> SQL查询性能差，对语句执行EXPLAIN VERBOSE时有Warning信息。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE 执行计划 Warning
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN VERBOSE`
  abnormal_pattern_quote: "执行计划中会有语句未收集统计信息的告警，并且通常E-rows估算非常小。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: CN pg_log 日志中 Warning 信息
  collection_layer: log-grep
  collection_method_quote: NULL
  abnormal_pattern_quote: "在CN的pg_log日志中也会有类似的Warning信息。同时，E-rows会比实际值小很多。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "查询中涉及到的表或列没有收集统计信息。统计信息是优化器生成执行计划的基础，没有收集统计信息，优化器生成的执行计划会非常差"
  linked_diagnostic_step_no: 1
  mitigation_quote: "周期性地运行ANALYZE，或者在对表的大部分内容执行更改操作后立即执行ANALYZE。"

```

## case_id: gaussdb-dws-query-slow-function-not-shipped-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS自定义函数属性定义错误导致SQL不下推，性能极差
- **source_heading**: 带自定义函数的语句不下推
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0074.html
- **source_url_lang**: zh-cn

### symptom_description

> SQL语句不下推。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE · __REMOTE 关键字
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过EXPLAIN VERBOSE打印语句执行计划。上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。"
  abnormal_pattern_quote: "上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: CN日志 · 不下推原因
  collection_layer: log-grep
  collection_method_quote: "不下推语句在pg_log中会打印不下推的原因，上述语句在CN的日志中会找到类似以下的日志。"
  abnormal_pattern_quote: "不下推语句在pg_log中会打印不下推的原因"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "不下推函数的场景主要出现在自定义函数属性定义错误的情况下。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "审视用户自定义函数的provolatile属性是否定义正确。如果定义不正确，要修改对应的属性，使它能够下推执行。"

```

## case_id: gaussdb-dws-nestloop-not-in-query-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 执行计划中有NestLoop导致SQL语句执行慢
- **source_heading**: 执行计划中有NestLoop导致SQL语句执行慢
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0076.html
- **source_url_lang**: zh-cn

### symptom_description

> 某业务场景中SQL语句执行慢，打印执行计划发现存在NestLoop。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划算子类型（NestLoop出现）
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过EXPLAIN VERBOSE打印语句执行计划，查看执行计划发现SQL语句中存在not in语句"
  abnormal_pattern_quote: "NestLoop是导致语句性能慢的主要原因"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "由于NOT IN对于NULL值的特殊处理，导致语句无法使用高效的HashJoin进行高效处理，性能较差。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "若业务场景中用户不关注NULL值的处理，或者数据中根本不存在NULL值，则可以通过等价改写将NOT IN改写为NOT EXISTS来进行优化。"

```

## case_id: gaussdb-dws-query-slow-partition-pruning-miss-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 查询条件未涉及分区键导致全表扫描，SQL 执行慢
- **source_heading**: 未分区剪枝导致SQL查询慢
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0077.html
- **source_url_lang**: zh-cn

### symptom_description

> SQL语句查询慢，查询的分区表总共185亿条数据，查询条件中没有涉及分区键。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量
  collection_layer: db-interactive-cmd
  collection_method_quote: `收集几个典型的慢SQL语句，分别打印执行计划。从执行计划中可以看出来，两条SQL的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分区扫描上。`
  abnormal_pattern_quote: `慢SQL过滤条件中未涉及分区字段，导致执行计划未分区剪枝，进行了全表扫描，性能严重劣化。`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `慢SQL过滤条件中未涉及分区字段，导致执行计划未分区剪枝，进行了全表扫描，性能严重劣化。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `在慢SQL的过滤条件中增加分区筛选条件，避免走全表扫描。优化后的SQL和执行计划如下，性能从十几分钟，优化到了12秒左右，性能有明显提升。`

```

## case_id: gaussdb-dws-plan-nestloop-row-underestimate-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 行数估算过小导致优化器选择 NestLoop 执行计划，查询性能下降
- **source_heading**: 行数估算过小，优化器选择走NestLoop导致性能下降
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0078.html
- **source_url_lang**: zh-cn

### symptom_description

> 查询语句执行慢，卡住无法返回结果。SQL语句的特点是2~3张表left join，然后通过SELECT查询结果。

### diagnostic_steps

```
[step 1]
  metric_name: 系统资源 I/O / 内存 / CPU 使用情况
  collection_layer: os
  collection_method_quote: `排查当前的I/O、内存、CPU使用情况，没有发现资源占用高的情况。`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: pg_thread_wait_status · 线程等待状态
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pg_thread_wait_status WHERE query_id='149181737656737395';`
  abnormal_pattern_quote: `根据线程等待状态，并没有出现都在等待某个DN的情况，初步排除中间结果集偏斜到了同一个DN的情况。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [1]

[step 3]
  metric_name: gstack · 进程堆栈中 VecNestLoopRuntime
  collection_layer: os
  collection_method_quote: `联系运维人员登录到相应的实例节点上，打印等待状态为none的线程堆栈信息`
  abnormal_pattern_quote: `堆栈中有VecNestLoopRuntime，结合执行计划，初步判断是由于统计信息不准，优化器评估结果集较少，执行计划使用了NestLoop导致性能下降。`
  abnormal_pattern_threshold: NULL
  metric_unit: stack-frame
  prerequisite_steps: [2]

```

### likely_causes

```
[parameter_causes · cause 1] enable_indexscan
  param_name: enable_indexscan
  abnormal_value_pattern: 默认开启，导致优化器在行数估算不准时选择 NestLoop+IndexScan
  recommended_value: `off` (针对此类查询临时关闭)
  recommendation_quote: `通过SET enable_indexscan = off，执行计划被改变，使用了Hash Left Join，慢SQL在3秒左右返回结果，查询性能恢复。`
  risk_if_violated_quote: NULL
  reasoning_quote: `通过set enable_indexscan = off关闭索引功能，让优化器生成的执行计划不走NestLoop，而走Hashjoin。`
  linked_diagnostic_step_no: 3

```

## case_id: gaussdb-dws-query-slow-table-bloat-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 表数据膨胀导致SQL查询慢，用户前台页面数据加载不出
- **source_heading**: 表数据膨胀导致SQL查询慢，用户前台页面数据加载不出
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 4
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0079.html
- **source_url_lang**: zh-cn

### symptom_description

> 数据库中原先执行几秒钟的SQL语句，现在执行二十几秒未出结果，导致前台页面数据加载超时，无法对用户提供图表显示。

### diagnostic_steps

```
[step 1]
  metric_name: pg_stat_activity 活跃SQL
  collection_layer: db-system-view
  collection_method_quote: `SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';`
  abnormal_pattern_quote: "发现有大量的CREATE INDEX语句"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: 表倾斜情况
  collection_layer: db-shell
  collection_method_quote: `SELECT table_skewness('table name');`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: ratio
  prerequisite_steps: [1]

[step 3]
  metric_name: max_process_memory / shared_buffers / work_mem 内存参数
  collection_layer: db-system-view
  collection_method_quote: NULL
  abnormal_pattern_quote: "max_process_memory为12GB，设置过小。shared_buffers为32MB，设置过小。"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

[step 4]
  metric_name: 脏数据膨胀率 / 表实际大小 vs 有效数据量
  collection_layer: db-system-view
  collection_method_quote: NULL
  abnormal_pattern_quote: "发现表数据膨胀严重，对其中一张8GB大小的表，总数据量5万条，做完VACUUM FULL后大小减小为5.6MB。"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] max_process_memory
  param_name: max_process_memory
  abnormal_value_pattern: 设置过小（示例为12GB）
  recommended_value: `25GB`
  recommendation_quote: "gs_guc set -Z coordinator -Z datanode -N all -I all -c \"max_process_memory=25GB\""
  risk_if_violated_quote: NULL
  reasoning_quote: "联系运维人员登录集群实例，检查内存相关参数，设置不合理，需要优化。max_process_memory为12GB，设置过小。"
  linked_diagnostic_step_no: 3

[parameter_causes · cause 2] shared_buffers
  param_name: shared_buffers
  abnormal_value_pattern: 设置过小（示例为32MB）
  recommended_value: `8GB`
  recommendation_quote: "gs_guc set -Z coordinator -Z datanode -N all -I all -c \"shared_buffers=8GB\""
  risk_if_violated_quote: NULL
  reasoning_quote: "shared_buffers为32MB，设置过小。"
  linked_diagnostic_step_no: 3

[parameter_causes · cause 3] work_mem
  param_name: work_mem
  abnormal_value_pattern: 设置过小（CN/DN均为64MB）
  recommended_value: `128MB`
  recommendation_quote: "gs_guc set -Z coordinator -Z datanode -N all -I all -c \"work_mem=128MB\""
  risk_if_violated_quote: NULL
  reasoning_quote: "work_mem：CN：64MB 、DN：64MB。"
  linked_diagnostic_step_no: 3

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "大量表频繁增删改，未及时清理，导致脏数据过多、表数据膨胀、查询慢。"
  linked_diagnostic_step_no: 4
  mitigation_quote: "对业务涉及到的常用的大表，执行VACUUM FULL操作，清理脏数据。"

```

## case_id: gaussdb-dws-query-slow-concurrent-index-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 大量并发CREATE INDEX操作导致SQL查询慢
- **source_heading**: 分析过程
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0079.html
- **source_url_lang**: zh-cn

### symptom_description

> 数据库中原先执行几秒钟的SQL语句，现在执行二十几秒未出结果

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN执行计划耗时分布
  collection_layer: db-interactive-cmd
  collection_method_quote: NULL
  abnormal_pattern_quote: "打印执行计划，分析出耗时主要在index scan上，可能是I/O争抢导致"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: pg_stat_activity 活跃SQL
  collection_layer: db-system-view
  collection_method_quote: `SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';`
  abnormal_pattern_quote: "发现有大量的CREATE INDEX语句，需要和用户确认该业务是否合理。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "查询当前活跃SQL，发现有大量的CREATE INDEX语句，需要和用户确认该业务是否合理。"
  linked_diagnostic_step_no: 2
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-point-query-cstore-scan-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 单表点查性能差：列存表用于点查场景导致耗时超预期
- **source_heading**: 单表点查询性能差
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0082.html
- **source_url_lang**: zh-cn

### symptom_description

> 单表查询的场景下，预期1s以内返回结果，实际执行耗时超过10s。

### diagnostic_steps

```
[step 1]
  metric_name: 执行计划算子：CStore Scan耗时占比
  collection_layer: db-interactive-cmd
  collection_method_quote: "通过抓取问题SQL的执行信息，发现大部分的耗时都在\"CStore Scan\""
  abnormal_pattern_quote: "大部分的耗时都在\"CStore Scan\""
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "行列存表选择错误导致的问题，点查询场景应该使用行存表+B-Tree索引。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "调整表定义，将表修改为行存表，同时建立B-Tree索引，索引建立的原则：在经常需要搜索查询的列上创建索引，可以加快搜索的速度；不要定义冗余或重复的索引；建立组合索引时候，要把过滤性比较好的列往前放；为经常出现在关键字ORDER BY、GROUP BY、DISTINCT后面的字段建立索引；在经常使用WHERE子句的列上创建索引，加快条件的判断速度。"

```

## case_id: gaussdb-dws-query-slow-ccn-queue-memory-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 动态负载管理下语句估算内存过大导致 CCN 排队、业务整体缓慢
- **source_heading**: 动态负载管理下的CCN排队
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0106.html
- **source_url_lang**: zh-cn

### symptom_description

> 业务整体缓慢，只有少量语句在执行，其余业务语句都在排队中（wait in ccn queue）。

### diagnostic_steps

```
[step 1]
  metric_name: pg_session_wlmstat · status / statement_mem
  collection_layer: db-system-view
  collection_method_quote: `SELECT usename,substr(query,0,20),threadid,status,statement_mem FROM pg_session_wlmstat where usename not in ('omm','Ruby') order by statement_mem,status desc;`
  abnormal_pattern_quote: `只有最后一个语句是running状态，其余语句都是pending状态。根据statement_mem可以看到该语句占据2576MB内存。`
  abnormal_pattern_threshold: `statement_mem > max_dynamic_memory 的 1/3`
  metric_unit: MB
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `语句估算内存过大，造成排队。查询pg_session_wlmstat视图，查看状态为running的语句是否个数很少，而且statement_mem字段数值是否较大（单位为MB，一般认为大于max_dynamic_memory 1/3即为大内存语句）。如果都符合就可以判断是此类语句占据内存导致整体运行缓慢。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `此时根据语句的threadid，执行以下命令终止对应的查询语句，终止后即可释放资源，其余语句正常运行。SELECT pg_terminate_backend(threadid);`

```

## case_id: gaussdb-dws-cstore-small-cu-io-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 列存小CU过多导致I/O飙升和查询偶发性变慢
- **source_heading**: 列存小CU多导致的性能慢问题
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0110.html
- **source_url_lang**: zh-cn

### symptom_description

> 系统I/O长期飙升过高，查询偶发性变慢。查看偶发慢业务慢时的执行计划信息，慢在cstore scan，且扫描数据量不大但扫描CU个数较多。

### diagnostic_steps

```
[step 1]
  metric_name: cudesc表中CU的row_count分布
  collection_layer: db-system-view
  abnormal_pattern_quote: "查询结果类似如下，主要关注row_count过小（远小于6w）的CU数量，如果此数量较大，说明当前小CU多，CU膨胀问题严重，影响存储效率和查询访问效率"
  abnormal_pattern_threshold: `row_count << 60000`
  metric_unit: count
  prerequisite_steps: []

[step 2]
  metric_name: 执行计划中CU扫描数量
  collection_layer: db-interactive-cmd
  collection_method_quote: "查看偶发慢业务慢时的执行计划信息，慢在cstore scan，且扫描数据量不大但扫描CU个数较多"
  abnormal_pattern_quote: "一个CU能够存放6W条记录，而计划中7W记录需要扫描2000+ CU，说明当前可能存在小CU较多的情况"
  abnormal_pattern_threshold: `CU数量 >> 数据行数/60000`
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "列存频繁小批量导入，针对含分区且分区个数比较多的场景，小CU问题更加突出。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对列存表进行攒批入库，单次入库量（有分区则针对单分区单次入库量）接近或大于6w*主DN个数；表数据量不大时建议改为行存表；当业务侧因业务特征无法调整入库量时，定期对列存表进行vacuum full可达到整合小CU的目的，一定程度缓解小CU问题。"

```

## case_id: gaussdb-dws-disk-io-saturation-column-cu-bloat-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 列存表小CU膨胀导致I/O高、查询慢
- **source_heading**: 场景1：列存小CU膨胀
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0111.html
- **source_url_lang**: zh-cn

### symptom_description

> 某业务SQL查询出390871条数据需43248ms，分析计划主要耗时在Cstore Scan。Cstore Scan的详细信息中，每个DN扫描出2w左右的数据，但是扫描了有数据的CU（CUSome）155079个，没有数据的CU（CUNone）156375个，说明当前小CU、未命中数据的CU极多，即CU膨胀严重。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数
  collection_layer: db-interactive-cmd
  collection_method_quote: `分析计划主要耗时在Cstore Scan。Cstore Scan的详细信息中，每个DN扫描出2w左右的数据，但是扫描了有数据的CU（CUSome）155079个，没有数据的CU（CUNone）156375个`
  abnormal_pattern_quote: `说明当前小CU、未命中数据的CU极多，即CU膨胀严重。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `对列存表（尤其是分区表）进行高频小批量导入会造成CU膨胀。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `列存表的数据入库方式修改为攒批入库，单分区单批次入库数据量需大于DN个数*6W。如果因业务原因无法攒批入库，则需定期VACUUM FULL此类高频小批量导入的列存表。`

```

## case_id: gaussdb-dws-disk-io-saturation-dirty-data-bloat-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 表脏数据过多导致 I/O 高、查询慢
- **source_heading**: 场景2：脏数据&数据清理
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0111.html
- **source_url_lang**: zh-cn

### symptom_description

> 某业务SQL总执行时间2.519s，其中Scan占了2.516s，同时该表的扫描最终只扫描到0条符合条件数据，过滤了20480条数据，即总共扫描了20480+0条数据却消耗了2s+，扫描时间与扫描数据量严重不符，此现象可判断为由于脏数据多从而影响扫描和I/O效率。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数
  collection_layer: db-interactive-cmd
  collection_method_quote: `某业务SQL总执行时间2.519s，其中Scan占了2.516s，同时该表的扫描最终只扫描到0条符合条件数据，过滤了20480条数据`
  abnormal_pattern_quote: `扫描时间与扫描数据量严重不符，此现象可判断为由于脏数据多从而影响扫描和I/O效率。`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: 表脏页率
  collection_layer: db-system-view
  collection_method_quote: `查看表脏页率为99%，VACUUM FULL后性能优化到100ms左右。`
  abnormal_pattern_quote: `查看表脏页率为99%`
  abnormal_pattern_threshold: `= 99%`
  metric_unit: %
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `表频繁执行UPDATE/DELETE导致脏数据过多，且长时间未VACUUM FULL清理。`
  linked_diagnostic_step_no: 2
  mitigation_quote: `对频繁UPDATE/DELETE产生脏数据的表，定期VACUUM FULL，因大表的VACUUM FULL也会消耗大量I/O，因此需要在业务低峰时执行，避免加剧业务高峰期I/O压力。`

```

## case_id: gaussdb-dws-disk-io-saturation-data-skew-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 表存储倾斜导致单 DN I/O 过高、查询慢
- **source_heading**: 场景3：表存储倾斜
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0111.html
- **source_url_lang**: zh-cn

### symptom_description

> 表Scan的A-time中，max time DN执行耗时6554ms，min time DN耗时0s，DN之间扫描差异超过10倍以上，这种集合Scan的详细信息，基本可以确定为表存储倾斜导致。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比
  collection_layer: db-interactive-cmd
  collection_method_quote: `表Scan的A-time中，max time DN执行耗时6554ms，min time DN耗时0s，DN之间扫描差异超过10倍以上`
  abnormal_pattern_quote: `DN之间扫描差异超过10倍以上，这种集合Scan的详细信息，基本可以确定为表存储倾斜导致。`
  abnormal_pattern_threshold: `> 10倍`
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: table_distribution 各DN数据行数
  collection_layer: db-system-view
  collection_method_quote: `通过table_distribution发现所有数据倾斜到了dn_6009单个DN`
  abnormal_pattern_quote: `通过table_distribution发现所有数据倾斜到了dn_6009单个DN`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: `分布式场景，表分布列选择不合理会导致存储倾斜，同时导致DN间压力失衡，单DN I/O压力大，整体I/O效率下降。`
  linked_diagnostic_step_no: 2
  mitigation_quote: `修改分布列使得表存储分布均匀后，max dn time和min dn time基本维持在相同水平400ms左右，Scan时间从6554ms优化到431ms。`

```

## case_id: gaussdb-dws-query-slow-no-index-or-index-miss-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 缺少索引或有索引未走导致全表扫描、I/O 高
- **source_heading**: 场景4：无索引、有索引不走
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0111.html
- **source_url_lang**: zh-cn

### symptom_description

> 某一次点查询，Seq Scan扫描需要3767ms，因涉及从4096000条数据中获取8240条数据，符合索引扫描的场景（海量数据中寻找少量数据），在对过滤条件列增加索引后，计划依然是Seq Scan而没有走Index Scan。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan）
  collection_layer: db-interactive-cmd
  collection_method_quote: `Seq Scan扫描需要3767ms，因涉及从4096000条数据中获取8240条数据，符合索引扫描的场景（海量数据中寻找少量数据），在对过滤条件列增加索引后，计划依然是Seq Scan而没有走Index Scan。`
  abnormal_pattern_quote: `计划依然是Seq Scan而没有走Index Scan。`
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `表中数据因执行DML操作后产生数据变化未及时ANALYZE，导致优化器无法选择索引扫描计划`
  linked_diagnostic_step_no: 1
  mitigation_quote: `对目标表ANALYZE后，计划能够自动选择索引，性能从3s+优化到2ms+，极大降低I/O消耗。`

```

## case_id: gaussdb-dws-disk-io-saturation-no-partition-pruning-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 设计了分区表但查询未走分区剪枝导致I/O极高
- **source_heading**: 场景5：无分区、有分区不剪枝
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0111.html
- **source_url_lang**: zh-cn

### symptom_description

> 某业务表经常使用createtime时间列作为过滤条件获取特定时间数据，对该表设计为分区表后没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms，I/O效率极低。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN 执行计划 · Selected Partitions 数量
  collection_layer: db-interactive-cmd
  collection_method_quote: `对该表设计为分区表后没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms，I/O效率极低。`
  abnormal_pattern_quote: `没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms`
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `设计了分区没使用分区键做过滤条件。分区键做过滤条件时，对列值有函数转换。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `在增加分区键createtime作为过滤条件后，Partitioned scan走分区剪枝（Selected Partitions数量极少），性能从700s优化到10s，I/O效率极大提升。`

```

## case_id: gaussdb-dws-disk-io-saturation-large-index-import-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 大量数据带多个索引导入产生大量XLOG、主备同步慢
- **source_heading**: 场景8：大量数据带索引导入
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0111.html
- **source_url_lang**: zh-cn

### symptom_description

> 某业务场景数据往DWS同步时，延迟严重，集群整体I/O压力大。后台查看等待视图有大量wait wal sync和WALWriteLock状态，均为xlog同步状态。

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_thread_wait_status · wait_status / wait_event
  collection_layer: db-system-view
  collection_method_quote: `SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_status <> 'synchronize quit' AND wait_status <> 'none'  GROUP BY 1,2 ORDER BY 3 DESC limit 50;`
  abnormal_pattern_quote: `后台查看等待视图有大量wait wal sync和WALWriteLock状态，均为xlog同步状态。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `大量数据带索引（一般超过3个）导入（insert/copy/merge into）会产生大量xlog，导致主备同步慢，备机长期Catchup，整体I/O利用率飙高。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `严格控制每张表的索引个数，建议3个以内。大量数据导入前先将索引删除，导入完成后再重新建索引。`

```

## case_id: gaussdb-dws-disk-io-saturation-small-files-iops-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 列存多分区导致小文件过多、IOPS 飙高
- **source_heading**: 场景10：小文件多IOPS高
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0111.html
- **source_url_lang**: zh-cn

### symptom_description

> 某业务执行过程中，整个集群IOPS飙高，另外当出现集群故障后，长期Building不成功，IOPS飙高，相关表信息如下：

### diagnostic_steps

```
[step 1]
  metric_name: pg_partition 各表分区数
  collection_layer: db-system-view
  collection_method_quote: `SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition GROUP BY parentid ) s ON c.oid = s.parentid ORDER BY partcount DESC;`
  abnormal_pattern_quote: `某业务库大量列存多分区（3000+）的表，导致小文件巨多（单DN文件2000w+）`
  abnormal_pattern_threshold: `> 3000分区`
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `某业务库大量列存多分区（3000+）的表，导致小文件巨多（单DN文件2000w+），访问效率低，故障恢复Building极慢`
  linked_diagnostic_step_no: 1
  mitigation_quote: `整改列存分区间隔，减少分区个数来降低文件个数。列存表修改为行存表，行存的存储特征决定其文件个数不会像列存般膨胀严重。`

```

## case_id: gaussdb-dws-memory-pressure-high-mem-query-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 集群内存负载过高或出现memory is temporary unavailable报错
- **source_heading**: 降低内存的处理方案
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0113.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果当前集群内存负载较高，或出现"memory is temporary unavailable"内存报错

### diagnostic_steps

```
[step 1]
  metric_name: pv_total_memory_detail · process_used_memory vs max_process_memory
  collection_layer: db-system-view
  collection_method_quote: `pv_total_memory_detail`
  abnormal_pattern_quote: "可比较process_used_memory和max_process_memory的关系，如前者明显小于后者，则说明占用内存大的语句已经跑完或者被杀掉，当前系统已经恢复，若已经大于或比较接近，则说明当前内存使用已经或即将超限"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "若此时dynamic_used_memory过大，说明动态申请的内存过大，这类问题可能和正在运行的SQL强相关"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对语句中的相关表进行ANALYZE，矫正内存估算情况，避免该语句申请内存过大导致内存超限报错。是否完全下推，参考使排序下推。是否存在对数据量大的表执行broadcast。是否有不合理的join顺序。根据业务场景适当降低作业并发量。"

```

## case_id: gaussdb-dws-query-slow-vacuum-lock-wait-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 存在锁等待导致VACUUM FULL执行慢
- **source_heading**: 场景一：存在锁等待导致VACUUM FULL执行慢
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0124.html
- **source_url_lang**: zh-cn

### symptom_description

> VACUUM FULL执行慢

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_lock_conflicts 锁冲突（8.1.x及以上）
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_lock_conflicts;`
  abnormal_pattern_quote: "在查询结果中查看granted字段为\"f\"，表示VACUUM FULL语句正在等待其他锁。granted字段为\"t\"，表示INSERT语句是持有锁。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前）
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 3]
  metric_name: pgxc_thread_wait_status 锁等待状态
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_thread_wait_status WHERE query_id = {query_id};`
  abnormal_pattern_quote: "查询结果中\"wait_status\"存在\"acquire lock\"表示存在锁等待。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [2]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "存在锁等待导致VACUUM FULL执行慢"
  linked_diagnostic_step_no: 1
  mitigation_quote: "根据语句内容判断是终止持锁语句后继续执行VACUUM FULL还是在业务低峰期选择合适的时间执行VACUUM FULL。如果要终止持锁语句，则执行：execute direct on (cn_5001) 'SELECT PG_TERMINATE_BACKEND(pid)';"

```

## case_id: gaussdb-dws-query-slow-vacuum-pck-sort-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 列存表PCK排序下盘导致VACUUM FULL执行慢
- **source_heading**: 场景四：列存表使用了局部聚簇（PCK）时，VACUUM FULL执行慢
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0124.html
- **source_url_lang**: zh-cn

### symptom_description

> 对列存表执行VACUUM FULL时，如果存在PCK，就会将PARTIAL_CLUSTER_ROWS中多条记录全都加载到内存中再进行排序，如果表较大或GUC参数psort_work_mem设置较小，会导致PCK排序时产生下盘（数据库选择将临时结果暂存到磁盘），进行外部排序；一旦进行外部排序，时间消耗就会增加很多。

### diagnostic_steps

```
[step 1]
  metric_name: 表定义是否存在PCK
  collection_layer: db-shell
  collection_method_quote: `SELECT * FROM pg_get_tabledef('table name');`
  abnormal_pattern_quote: "回显中存在\"PARTIAL CLUSTER KEY\"信息，表示存在PCK。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: psort_work_mem 参数值
  collection_layer: db-shell
  collection_method_quote: `show psort_work_mem;`
  abnormal_pattern_quote: "查看psort_work_mem是否设置过小"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] psort_work_mem
  param_name: psort_work_mem
  abnormal_value_pattern: 设置过小，导致PCK排序时下盘
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: "如果表较大或GUC参数psort_work_mem设置较小，会导致PCK排序时产生下盘（数据库选择将临时结果暂存到磁盘），进行外部排序；一旦进行外部排序，时间消耗就会增加很多。"
  reasoning_quote: "查看psort_work_mem是否设置过小，根据业务情况适当调大psort_work_mem。"
  linked_diagnostic_step_no: 2

```

## case_id: gaussdb-dws-disk-space-columnar-table-bloat-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS列存表多次小批量INSERT后表膨胀、磁盘空间持续增长
- **source_heading**: 列存表多次插入后出现表膨胀
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0125.html
- **source_url_lang**: zh-cn

### symptom_description

> 列存表多次执行INSERT后，发现表膨胀。

### diagnostic_steps

```
[step 1]
  metric_name: 列存表文件大小监控
  collection_layer: db-system-view
  collection_method_quote: "列存表数据按列存储，一列的每60000行存储为一个CU，同一列的CU连续存储在一个文件中，当该文件大于1GB时，切换到新文件中。CU文件数据不能更改只能追加写。"
  abnormal_pattern_quote: "列存表多次执行INSERT后，发现表膨胀。"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] ENABLE_DELTA
  param_name: ENABLE_DELTA
  abnormal_value_pattern: 默认关闭（OFF），小批量INSERT产生大量小CU
  recommended_value: `ON`
  recommendation_quote: "建议开启列存表的delta表功能。开启列存表的delta表功能，在导入单条或者小规模数据进入表中时，能够防止小CU的产生，所以开启delta表能够带来显著的性能提升，例如在3CN、6DN的集群上操作，每次导入100条数据，导入时间能减少25%，存储空间减少97%，所以在需要多次插入小批量数据前应该先开启delta表"
  risk_if_violated_quote: "列存表多次执行INSERT后，发现表膨胀。"
  reasoning_quote: "开启列存表的delta表功能，在导入单条或者小规模数据进入表中时，能够防止小CU的产生，所以开启delta表能够带来显著的性能提升，例如在3CN、6DN的集群上操作，每次导入100条数据，导入时间能减少25%，存储空间减少97%"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "对频繁进行删除和更新的列存表VACUUM后，由于列存表的CU无法更改，即使标识为可用的空间也是无法进行复用的（复用需要更改CU）。因此不建议在DWS中对列存表频繁进行删除和更新。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "建议开启列存表的delta表功能。ALTER TABLE table_name SET (ENABLE_DELTA = ON);"

```

## case_id: gaussdb-dws-lock-contention-concurrent-update-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 并发更新同一行数据导致事务回滚报错
- **source_heading**: 执行SQL时报错：abort transaction due to concurrent update
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0206.html
- **source_url_lang**: zh-cn

### symptom_description

> 执行SQL时出现abort transaction due to concurrent update锁等待超时的错误。

### diagnostic_steps

```
[step 1]
  metric_name: 数据库错误日志 · abort transaction due to concurrent update
  collection_layer: log-grep
  collection_method_quote: NULL
  abnormal_pattern_quote: "并发更新同一条记录发生冲突不会等待锁，直接报错：abort transaction due to concurrent update"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "两个不同的事务对同一个表中的同一行数据进行并发更新/操作，导致后操作的事务发生了回滚。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "调整业务逻辑sql执行顺序，避免update/delete长时间持有锁的sql在事务前面。尽量将大事务拆分成多个小事务来处理，小事务缩短锁定资源的时间，发生冲突的几率也降低。尽可能减少并发会话的数量，以减少冲突的几率。"

```

## case_id: dws-distkey-skew-10pct-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Hash 分布列选择不当导致 DN 数据分布倾斜
- **source_heading**: 查看数据倾斜状态
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/migration-dws/dws_15_0093.html
- **source_url_lang**: zh-cn

### symptom_description

> 数据倾斜会造成查询表性能下降。对于记录数超过千万条的表，建议在执行全量数据导入前，先导入部分数据，以进行数据倾斜检查和调整分布列，避免导入大量数据后发现数据倾斜，调整成本高。

### diagnostic_steps

```
[step 1]
  metric_name: 各 DN 数据条数分布
  collection_layer: db-interactive-cmd
  collection_method_quote: `SELECT a.count,b.node_name FROM (SELECT count(*) AS count,xc_node_id FROM table_name GROUP BY xc_node_id) a, pgxc_node b WHERE a.xc_node_id=b.node_id ORDER BY a.count desc;`
  abnormal_pattern_quote: 若各DN上数据分布差大于等于10%，表明数据分布倾斜
  abnormal_pattern_threshold: `>= 10%`
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: PGXC_GET_TABLE_SKEWNESS 视图
  collection_layer: db-system-view
  collection_method_quote: 分布差可以通过视图[PGXC_GET_TABLE_SKEWNESS]查看。
  abnormal_pattern_quote: 此处的数据分布差表示实际查询到DN上的数据量与DN平均数据量的差异。
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: 对于Hash分布策略，如果分布列选择不当，可能导致数据倾斜。因此在采用Hash分布策略之后会对用户表的数据进行数据倾斜性检查，以确保数据在各个DN上是均匀分布的。一般情况下分布列都是选择键值重复度小，数据分布比较均匀的列。
  linked_diagnostic_step_no: 1
  mitigation_quote: 分析数据源特征，选择若干个键值重复度小，数据分布比较均匀的备选分布列。

[non_parameter_causes · cause 2] data-distribution
  cause_type: data-distribution
  description_quote: 如果上述步骤不能选出适合的分布列，需要从备选分布列选择多个列的组合作为分布列来完成数据迁移。
  linked_diagnostic_step_no: 1
  mitigation_quote: 尝试选择staff_ID、FIRST_NAME和LAST_NAME的组合作为分布列

```

## case_id: gaussdb-dws-disk-high-dirty-pages-15

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 集群所有/过半磁盘使用率 ≥ 70% — 脏页率过高
- **source_heading**: 场景一：磁盘使用率过高
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0031.html
- **source_url_lang**: zh-cn

### symptom_description

> 场景一：磁盘使用率过高，当前集群所有磁盘或超过半数以上的磁盘使用率>=70%。

### diagnostic_steps

```
[step 1]
  metric_name: DMS 监控 · 节点磁盘使用率
  collection_layer: db-system-view
  collection_method_quote: `选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。`
  abnormal_pattern_quote: `当前集群所有磁盘或超过半数以上的磁盘使用率>=70%`
  abnormal_pattern_threshold: `>= 70%`
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: PGXC_GET_STAT_ALL_TABLES.dirty_page_rate
  collection_layer: db-system-view
  abnormal_pattern_quote: `脏页率超过30%的较大表`
  abnormal_pattern_threshold: `dirty_page_rate > 30`
  metric_unit: %
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `根据数据表的查询结果，定期进行脏数据 清理`
  linked_diagnostic_step_no: 2
  mitigation_quote: `8.1.3及以上版本：通过管理控制台“智能运维”功能进行自动清理`

```

## case_id: gaussdb-dws-agg-plan-tuning-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 优化器代价估算偏差导致 Agg 计划选择次优，通过 best_agg_plan 参数干预
- **source_heading**: 案例：调整GUC参数best_agg_plan
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0485.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常优化器总会选择最优的执行计划，但是众所周知代价估算，尤其是中间结果集的代价估算一般会有比较大的偏差，这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · Agg 计划形态（hashagg+gather vs redistribute+hashagg）
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain select b,count(1) from t1 group by b`
  abnormal_pattern_quote: "通常优化器总会选择最优的执行计划，但是众所周知代价估算，尤其是中间结果集的代价估算一般会有比较大的偏差，这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] best_agg_plan
  param_name: best_agg_plan
  abnormal_value_pattern: 默认 0（优化器自动选择），中间结果集估算偏差大时可能选择次优计划
  recommended_value: `2` （收敛度小时选择 redistribute+hashagg）或 `3`（hashagg+redistribute+hashagg）
  recommendation_quote: "DWS提供了guc参数best_agg_plan来干预执行计划，强制其生成上述对应的执行计划，此参数取值范围为0，1，2，3"
  risk_if_violated_quote: "这种比较大的偏差就可能会导致agg的计算方式出现比较大的偏差，这时候就需要通过best_agg_plan进行agg计算模型的干预"
  reasoning_quote: "当agg汇聚的收敛度很小时，即结果集的个数在agg之后并没有明显变少时（经验上以5倍为临界点），选择redistribute+hashagg执行方式，否则选择hashagg+redistribute+hashagg执行方式"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-cost-param-anti-join-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Anti Join 行数估算不准导致执行计划差，通过 cost_param bit0 修正
- **source_heading**: 案例：设置cost_param对查询性能优化 · 场景一
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0479.html
- **source_url_lang**: zh-cn

### symptom_description

> 以上查询为lineitem表自连接的Anti Join，当使用cost_param的bit0为0时，估算Anti Join的行数与实际行数相差很大，导致查询性能下降。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE · Anti Join 执行计划及行数估算
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain verbose select count(*) as numwait from lineitem l1, orders where o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and not exists (select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) order by numwait desc`
  abnormal_pattern_quote: "估算Anti Join的行数与实际行数相差很大，导致查询性能下降"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] cost_param
  param_name: cost_param
  abnormal_value_pattern: bit0 = 0（默认），对自连接 Anti Join 的选择率估算不准确
  recommended_value: `1` （bit0 = 1，使用改良的选择率估算方法）
  recommendation_quote: "可以通过设置cost_param的bit0为1时，使Anti Join的行数估算更准确，从而提高查询性能"
  risk_if_violated_quote: "估算Anti Join的行数与实际行数相差很大，导致查询性能下降"
  reasoning_quote: "以上查询为lineitem表自连接的Anti Join，当使用cost_param的bit0为0时，估算Anti Join的行数与实际行数相差很大，导致查询性能下降"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-cost-param-filter-selectivity-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 多个过滤条件列强相关时选择率估算不准，通过 cost_param bit1 改善
- **source_heading**: 案例：设置cost_param对查询性能优化 · 场景二
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0479.html
- **source_url_lang**: zh-cn

### symptom_description

> 在以上查询中，supplier、lineitem、partsupp三表做hashjoin的条件为(lineitem.l_suppkey = supplier.s_suppkey) AND (lineitem.l_partkey = partsupp.ps_partkey)，此hashjoin条件中存在两个过滤条件，这前一个过滤条件中的lineitem.l_suppkey和后一个过滤条件中的lineitem.l_partkey同为lineitem表的两列，这两列存在强相关的关联关系。这种情况下，估算hashjoin条件的选择率时，如果使用cost_param的bit1为0时，实际是将AND的两个过滤条件分别计算的2个选择率的值相乘来得到hashjoin条件的选择率，导致行数估算不准确，查询性能较差。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE · HashJoin 行数估算偏差
  collection_layer: db-interactive-cmd
  collection_method_quote: `set cost_param=2; explain verbose select nation, sum(amount) as sum_profit from (...) as profit group by nation order by nation`
  abnormal_pattern_quote: "导致行数估算不准确，查询性能较差"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] cost_param
  param_name: cost_param
  abnormal_value_pattern: bit1 = 0（默认），多过滤条件列强相关时选择率计算方式不准确
  recommended_value: `2` （bit1 = 1，过滤条件强相关时选最小选择率）
  recommendation_quote: "所以需要将cost_param的bit1为1时，选择最小的选择率作为总的选择率估算行数比较准确，查询性能较好"
  risk_if_violated_quote: "导致行数估算不准确，查询性能较差"
  reasoning_quote: "此hashjoin条件中存在两个过滤条件，这前一个过滤条件中的lineitem.l_suppkey和后一个过滤条件中的lineitem.l_partkey同为lineitem表的两列，这两列存在强相关的关联关系"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-data-skew-storage-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 存储层数据倾斜导致部分 DN 成为查询瓶颈
- **source_heading**: 存储层数据倾斜
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0451.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果数据分布存在倾斜，则会导致分布式执行某些DN成为瓶颈，影响查询性能。

### diagnostic_steps

```
[step 1]
  metric_name: 磁盘利用率各 DN 差异
  collection_layer: db-shell
  collection_method_quote: `SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc`
  abnormal_pattern_quote: "各个数据磁盘的利用率，会有不均衡的现象。正常情况下，利用率最高和利用率最低的磁盘空间相差不大，如果磁盘利用率相差超过了5%就要注意是不是有资源倾斜的情况。"
  abnormal_pattern_threshold: `> 5% 差值`
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: EXPLAIN PERFORMANCE 各 DN 基表 scan 行数及时间分布
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain performance select avg(ss_wholesale_cost) from store_sales`
  abnormal_pattern_quote: "基表scan的时间：最快的DN耗时5ms，最慢的DN耗时1173ms。数据分布情况：某些DN有22831616行，其他DN都是0行，数据有严重倾斜。"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

[step 3]
  metric_name: table_skewness / table_distribution · 表数据倾斜率
  collection_layer: db-shell
  collection_method_quote: `SELECT table_skewness('store_sales')`
  abnormal_pattern_quote: "某些DN有22831616行，其他DN都是0行，数据有严重倾斜"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [2]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "通常是由于分布列选择不合理，可以通过调整分布列的方式解决。"
  linked_diagnostic_step_no: 3
  mitigation_quote: "ALTER TABLE t2 DISTRIBUTE BY HASH (b)"

```

## case_id: gaussdb-dws-data-skew-compute-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 计算层数据倾斜：重分布列上的倾斜值导致运行时 DN 数据不均衡
- **source_heading**: 计算层数据倾斜
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0451.html
- **source_url_lang**: zh-cn

### symptom_description

> 在执行查询的过程中，仍然可能出现数据倾斜的问题。在运算过程中某个算子在DN上输出的结果集出现倾斜，从而导致此算子上层的运算出现计算倾斜。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · Stream 算子各 DN 行数分布
  collection_layer: db-interactive-cmd
  collection_method_quote: `select * from skew s,test t where s.x = t.x order by s.a limit 1`
  abnormal_pattern_quote: "6 --Streaming(type: REDISTRIBUTE) datanode1 (rows=5050368) datanode2 (rows=15276032) datanode3 (rows=5174272) datanode4 (rows=5219328)"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] skew_option
  param_name: skew_option
  abnormal_value_pattern: 未启用或设置为 lazy 时，优化器不对已知倾斜做额外优化
  recommended_value: `normal`
  recommendation_quote: "DWS提出了RLBT(Runtime Load Balance Technology)方案，用于解决运行时的计算倾斜问题，该特性由参数skew_option控制"
  risk_if_violated_quote: "倾斜节点需要处理更多的数据，导致倾斜节点的计算性能远低于其他节点"
  reasoning_quote: "当skew_option为normal时，这里认为倾斜数据依旧存在，仍然会对基表中识别到的倾斜进行优化"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: "当重分布列上的数据存在倾斜时，就会导致运行时的数据倾斜，即重分布后部分节点的数据远大于其他"
  linked_diagnostic_step_no: 1
  mitigation_quote: "通过用户手动指定的方式，给定倾斜信息。优化器根据用户给定的倾斜信息，来对查询进行优化。详细hint使用语法参见运行倾斜的hint"

```

## case_id: gaussdb-dws-disk-skew-16

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 磁盘倾斜:使用率最高与最低磁盘相差 ≥ 10%
- **source_heading**: 场景二：磁盘倾斜
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0031.html
- **source_url_lang**: zh-cn

### symptom_description

> 场景二：磁盘倾斜，使用率最高的磁盘和最低的磁盘使用率之差>=10%。

### diagnostic_steps

```
[step 1]
  metric_name: DMS · 节点磁盘使用率排序 (max - min)
  collection_layer: db-system-view
  collection_method_quote: `选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。`
  abnormal_pattern_quote: `使用率最高的磁盘和最低的磁盘使用率之差>=10%`
  abnormal_pattern_threshold: `max - min >= 10%`
  metric_unit: %
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: `场景二：磁盘倾斜，使用率最高的磁盘和最低的磁盘使用率之差>=10%。`
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-distribution-key-redistribution-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 分布列与 JOIN 条件不匹配导致 Redistribute Stream，查询耗时增加
- **source_heading**: 案例：选择合适的分布列
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0475.html
- **source_url_lang**: zh-cn

### symptom_description

> 则执行计划存在"Streaming(type: REDISTRIBUTE)"，即DN根据选定的列把数据重分布到所有的DN，这将导致DN之间存在较大通信数据量

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · Streaming(type: REDISTRIBUTE) 算子是否出现
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN SELECT * FROM t1, t2 WHERE t1.a = t2.b`
  abnormal_pattern_quote: "执行计划存在\"Streaming(type: REDISTRIBUTE)\"，即DN根据选定的列把数据重分布到所有的DN，这将导致DN之间存在较大通信数据量"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "在进行关联查询时，尽量选择查询中的关联条件作为分布键。当关联条件作为分布键时，相关数据都分布在DN本地，将减少DN之间的数据流动代价，提升查询速度。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "将表t2的分布列改为b列之后，执行计划将不再包含\"Streaming(type: REDISTRIBUTE)\"，减少了DN之间存在的通信数据量的同时，执行时间也从8.7毫秒降低至2.7毫秒"

```

## case_id: gaussdb-dws-high-cpu-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 高 CPU 系统性能调优方案
- **source_heading**: 高CPU系统性能调优方案
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0112.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果当前集群CPU负载较高，可参考如下步骤进行优化

### diagnostic_steps

```
[step 1]
  metric_name: 节点 CPU 使用率 (1/3/12/24 小时)
  collection_layer: os
  collection_method_quote: 选择“监控 > 节点监控 > 概览”可查看当前集群各节点CPU使用率的具体情况，单击最右的监控按钮，查看最近1/3/12/24小时的CPU性能指标
  abnormal_pattern_quote: 判断是否有CPU使用率突然增大的情况。
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: []

[step 2]
  metric_name: 资源池 CPU 限额 / 配额配置
  collection_layer: db-system-view
  collection_method_quote: 设置资源池CPU限额与配额。
  abnormal_pattern_quote: 防止极端场景下某个语句占用CPU资源过多
  abnormal_pattern_threshold: NULL
  metric_unit: %
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] resource_pool.cpu_dedicated_quota
  param_name: resource_pool.cpu_dedicated_quota
  abnormal_value_pattern: 未配置专属限额，导致复杂作业争抢 CPU
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: 防止极端场景下某个语句占用CPU资源过多，导致数据库内其他语句因争抢CPU而变得缓慢迟钝的情况
  reasoning_quote: 专属限额其实就是绑核，按照百分比的方式分配CPU核给资源池使用，该资源池上运行的复杂作业只能在分配的CPU上运行。
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 根据业务场景适当降低作业并发量。
  linked_diagnostic_step_no: 1
  mitigation_quote: 根据业务场景适当降低作业并发量。

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: 设置异常规则及时终止高CPU语句。
  linked_diagnostic_step_no: 1
  mitigation_quote: 可创建与CPU资源相关的异常规则。具体操作可参考异常规则，对超过异常规则阈值的SQL及时终止拦截，保持集群稳定。

```

## case_id: gaussdb-dws-idle-in-transaction-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: connection-storm
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: DWS 语句处于 idle in transaction 状态常见场景
- **source_heading**: DWS语句处于idle in transaction状态常见场景
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2109.html
- **source_url_lang**: zh-cn

### symptom_description

> 此状态下的语句已经执行完成，不占用CPU和IO等资源，会占用连接数，并发数等连接资源。

### diagnostic_steps

```
[step 1]
  metric_name: pgxc_stat_activity state 字段
  collection_layer: db-system-view
  collection_method_quote: `SELECT state, query, query_id FROM pgxc_stat_activity;`
  abnormal_pattern_quote: 查看结果显示：该语句状态为idle in transaction。
  abnormal_pattern_threshold: `state = 'idle in transaction'`
  metric_unit: enum
  prerequisite_steps: []

[step 2]
  metric_name: 各 CN 上 SAVEPOINT/RELEASE 语句分布
  collection_layer: db-system-view
  collection_method_quote: `SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';`
  abnormal_pattern_quote: 结果显示SAVEPOINT/RELEASE语句处于idle in transaction。
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 手动BEGIN/START TRANSACTION开启事务，执行某语句后，不执行COMMIT/ROLLBACK
  linked_diagnostic_step_no: 1
  mitigation_quote: 这种场景下需要手动对开启的事务执行COMMIT/ROLLBACK即可。

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: 存储过程中有DDL语句，该存储过程结束前，其他节点上DDL语句执行完后的状态是idle in transaction
  linked_diagnostic_step_no: 1
  mitigation_quote: 此类场景是由于存储过程执行慢导致，等存储过程执行完成即可，也可考虑优化存储过程中执行时间较长的语句。

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: SAVEPOINT和RELEASE语句是带EXCEPTION的存储过程执行时系统自动生成的（8.1.0之后的集群版本不再向CN下发SAVEPOINT），DWS带EXCEPTION的存储过程在实现上基于子事务实现
  linked_diagnostic_step_no: 2
  mitigation_quote: 当此类存储过程较多且有嵌套时容易出现，与场景二类似，等整个存储过程执行完即可。

```

## case_id: gaussdb-dws-in-clause-nestloop-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: any-clause 不等值 JOIN 条件导致 NestLoop，超时超 1 小时
- **source_heading**: 案例：改写SQL消除in-clause
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0489.html
- **source_url_lang**: zh-cn

### symptom_description

> 测试发现由于两表结果集过大，导致nestloop耗时过长，超过一小时未返回结果

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · JOIN 算子类型 (NestLoop vs HashJoin)
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN SELECT ls_pid_cusr1,COALESCE(max(round((current_date-bthdate)/365)),0) FROM calc_empfyc_c1_result_tmp_t1 t1,p10_md_tmp_t2 t2 WHERE t1.ls_pid_cusr1 = any(values(id),(id15)) GROUP BY ls_pid_cusr1`
  abnormal_pattern_quote: "因此join-condition实质上是一个不等式，这种不等值的join操作必须走nestloop"
  abnormal_pattern_threshold: NULL
  metric_unit: s
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "性能优化的关键是消除nestloop，让join走更高效的hashjoin。从语义等价的角度消除any-clause"
  linked_diagnostic_step_no: 1
  mitigation_quote: "优化后，从超过1个小时未返回结果优化到7s返回结果。"

```

## case_id: gaussdb-dws-index-missing-slow-query-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: WHERE 过滤列缺少索引，列存分区表点查耗时 48ms，建索引后降至 18ms
- **source_heading**: 案例：建立合适的索引
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0476.html
- **source_url_lang**: zh-cn

### symptom_description

> 执行SQL语句查询没有建立索引情况下的执行计划，发现执行时间为48毫秒

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · 基表扫描方式及执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE SELECT * FROM orders WHERE o_custkey = '1106459'`
  abnormal_pattern_quote: "发现执行时间为48毫秒"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "where子句过滤条件的字段是o_custkey，在o_custkey字段上添加一个索引"
  linked_diagnostic_step_no: 1
  mitigation_quote: "CREATE INDEX idx_o_custkey ON orders (o_custkey) LOCAL；执行SQL语句查询建立索引后的执行计划，发现执行时间为18毫秒"

```

## case_id: gaussdb-dws-inlist2join-large-constants-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: "in 常量" 大量常量未转 join 导致执行不收
- **source_heading**: 语句中存在"in 常量"导致SQL执行无结果
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0080.html
- **source_url_lang**: zh-cn

### symptom_description

> 简单的大表过滤的SQL语句中有一个"in 常量"的过滤条件，常量的个数非常多(约有2000多个)，基表数据量比较大，SQL语句执行无结果。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · in 条件是否转为 join
  collection_layer: db-interactive-cmd
  collection_method_quote: "打印语句的执行计划"
  abnormal_pattern_quote: "执行计划中，in条件还是作为普通的过滤条件存在。这种场景下，join操作的性能优于in条件，最优的执行计划应该是将"in 常量"转化为join操作。"
  abnormal_pattern_threshold: `执行计划中 in 仍作为 Filter 而非 Hash Join`
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] qrw_inlist2join_optmode
  param_name: qrw_inlist2join_optmode
  abnormal_value_pattern: 默认 cost_base 时优化器估算不准导致未做转化
  recommended_value: `rule_base`
  recommendation_quote: "这种情况下可以通过设置qrw_inlist2join_optmode为rule_base来规避解决。"
  risk_if_violated_quote: "如果优化器估算不准，可能会出现需要转化的场景没有做转化，导致性能较差。"
  reasoning_quote: "GUC参数qrw_inlist2join_optmode可以控制把"in 常量"转join的行为，默认是cost_base的。"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-join-null-values-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: JOIN 列存在大量 NULL 值导致扫描阶段耗时过长
- **source_heading**: 案例：增加JOIN列非空条件
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0477.html
- **source_url_lang**: zh-cn

### symptom_description

> 若Join列上的NULL值较多，可以加上is not null过滤条件，以实现数据的提前过滤，提高Join效率。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · 执行计划顺序扫描阶段耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN` 查看多表 JOIN 执行计划
  abnormal_pattern_quote: "分析执行计划可知，在顺序扫描阶段耗时较多"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "多表JOIN中，由于表PS.SDR_WEB_BSCRNC_1DAY的JOIN列\"BSCRNC_ID\"存在大量空值，JOIN性能差。建议在语句中手动添加JOIN列的非空判断"
  linked_diagnostic_step_no: 1
  mitigation_quote: "and SDR.BSCRNC_ID is not null"

```

## case_id: gaussdb-dws-not-in-nestloop-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: NOT IN 语句使用 NestLoop Anti Join，改写为 NOT EXISTS 可使用 Hash Anti Join
- **source_heading**: 案例：NOT IN转NOT EXISTS
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_1000.html
- **source_url_lang**: zh-cn

### symptom_description

> NOT IN语句需要使用nestloop anti join来实现，而NOT EXISTS则可以通过hash anti join来实现

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN VERBOSE · NOT IN 执行计划算子类型
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN VERBOSE SELECT * FROM t1 WHERE t1.c NOT IN (SELECT t2.c FROM t2)`
  abnormal_pattern_quote: "从返回结果可知执行计划走NestLoop"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: EXPLAIN VERBOSE · NOT EXISTS 执行计划算子类型验证
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN VERBOSE SELECT * FROM t1 WHERE NOT EXISTS (SELECT 1 FROM t2 WHERE t2.c = t1.c)`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "NOT IN语句需要使用nestloop anti join来实现，而NOT EXISTS则可以通过hash anti join来实现。在join列不存在null值的情况下，not exists和not in等价。因此在确保没有null值时，可以通过将not in转换为not exists，通过生成hash join来提升查询效率。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "SELECT * FROM t1 WHERE NOT EXISTS (SELECT * FROM t2 WHERE t2.c = t1.c)"

```

## case_id: gaussdb-dws-operator-spill-23

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 中间数据量超出内存,算子下盘(spill) 导致查询响应剧烈劣化
- **source_heading**: 算子下盘的概念 / 如何判断语句是否发生了下盘
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 4
- **source_url**: https://support.huaweicloud.com/dws_faq/dws_03_2103.html
- **source_url_lang**: zh-cn

### symptom_description

> 发生算子下盘时，算子运算数据将写入磁盘，由于磁盘操作相对内存访问缓慢导致性能下降，查询响应时间出现极大劣化

### diagnostic_steps

```
[step 1]
  metric_name: base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件
  collection_layer: os
  collection_method_quote: `下盘文件位于实例目录的base/pgsql_tmp路径下，下盘文件以 pgsql_tmp$queryid_$pid 命名`
  abnormal_pattern_quote: `下盘文件位于实例目录的base/pgsql_tmp路径下`
  abnormal_pattern_threshold: NULL
  metric_unit: files
  prerequisite_steps: []

[step 2]
  metric_name: pgxc_thread_wait_status · wait_status='write file'
  collection_layer: db-system-view
  collection_method_quote: `等待视图中，当出现write file时，表示发生了中间结果下盘`
  abnormal_pattern_quote: `当出现write file时，表示发生了中间结果下盘`
  abnormal_pattern_threshold: `wait_status = 'write file'`
  metric_unit: NULL
  prerequisite_steps: []

[step 3]
  metric_name: EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字
  collection_layer: db-interactive-cmd
  collection_method_quote: `performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。`
  abnormal_pattern_quote: `performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 4]
  metric_name: TopSQL.spill_info
  collection_layer: db-system-view
  collection_method_quote: `实时TopSQL语句或历史TopSQL语句中，spill_info字段中会包含下盘信息，如果该字段不为空，说明有DN实例出现了下盘。`
  abnormal_pattern_quote: `如果该字段不为空，说明有DN实例出现了下盘`
  abnormal_pattern_threshold: `spill_info IS NOT NULL`
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] work_mem
  param_name: work_mem
  abnormal_value_pattern: 非自适应场景下设置过小,导致 hash/agg/sort 等可下盘算子触发下盘
  recommended_value: `适当调大 (依据 Explain Performance 输出)`
  recommendation_quote: `非内存自适应场景下，当中间结果集无法减少时，应根据实际情况适当调大work_mem参数。`
  risk_if_violated_quote: `当内存使用超过该参数后将触发算子下盘`
  reasoning_quote: `work_mem：可以判断执行作业可下盘算子是否触发已使用内存量下盘点，当内存使用超过该参数后将触发算子下盘。该参数仅在非内存自适应场景（enable_dynamic_workload=off）时生效。`
  linked_diagnostic_step_no: 3

[parameter_causes · cause 2] temp_file_limit
  param_name: temp_file_limit
  abnormal_value_pattern: 默认或过大,可能导致下盘填满磁盘
  recommended_value: `根据实际磁盘可用空间设置上限`
  recommendation_quote: `temp_file_limit：可以限制落盘算子的落盘文件大小，一般建议根据实际情况设置，防止下盘文件将磁盘空间占满，超过该值将报错退出。`
  risk_if_violated_quote: `防止下盘文件将磁盘空间占满，超过该值将报错退出`
  reasoning_quote: `temp_file_limit：可以限制落盘算子的落盘文件大小，一般建议根据实际情况设置，防止下盘文件将磁盘空间占满，超过该值将报错退出。`
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: `避免数据倾斜：数据倾斜严重时会导致单DN上数据量过大，引起单DN下盘。`
  linked_diagnostic_step_no: 4
  mitigation_quote: `避免数据倾斜`

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: `及时analyze：当统计信息不准时，行数估算可能偏小，导致计划选择非最优，从而出现下盘。`
  linked_diagnostic_step_no: 3
  mitigation_quote: `及时analyze`

```

## case_id: gaussdb-dws-seqscan-vs-indexscan-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 点查/范围扫描场景 SeqScan 全表扫描耗时过长，应改为 IndexScan
- **source_heading**: 算子级调优示例 · 示例1
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0450.html
- **source_url_lang**: zh-cn

### symptom_description

> 基表扫描时，对于点查或者范围扫描等过滤大量数据的查询，如果使用SeqScan全表扫描会比较耗时

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE · 基表扫描算子类型及执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain (analyze on, costs off) select * from store_sales where ss_sold_date_sk = 2450944`
  abnormal_pattern_quote: "Seq Scan on store_sales [3594.611,3594.611] 3360 Rows Removed by Filter: 4968936"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "可以在条件列上建立索引选择IndexScan进行索引扫描提升扫描效率"
  linked_diagnostic_step_no: 1
  mitigation_quote: "create index idx on store_sales_row(ss_sold_date_sk)；建立索引后，使用IndexScan扫描效率显著提高，从3.6秒提升到13毫秒"

```

## case_id: gaussdb-dws-nestloop-to-hashjoin-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 大表 JOIN 使用 NestLoop 导致执行时间过长，应改为 HashJoin
- **source_heading**: 算子级调优示例 · 示例2
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0450.html
- **source_url_lang**: zh-cn

### symptom_description

> 两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE · JOIN 算子类型及执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE` 查看两表 JOIN 的算子类型
  abnormal_pattern_quote: "NestLoop耗时181秒"
  abnormal_pattern_threshold: NULL
  metric_unit: s
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_nestloop
  param_name: enable_nestloop
  abnormal_value_pattern: on（默认），大表 JOIN 时优化器错误选择 NestLoop
  recommended_value: `off`
  recommendation_quote: "设置参数enable_mergejoin=off关掉Merge Join，同时设置参数enable_nestloop=off关掉NestLoop，让优化器选择HashJoin，则Join耗时提升至200多毫秒"
  risk_if_violated_quote: "NestLoop耗时181秒"
  reasoning_quote: "两表join选择了NestLoop，而实际行数比较大时，NestLoop Join可能执行比较慢"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-groupagg-to-hashagg-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 大结果集 Agg 选择 Sort+GroupAgg 导致性能差，应改为 HashAgg
- **source_heading**: 算子级调优示例 · 示例3
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0450.html
- **source_url_lang**: zh-cn

### symptom_description

> 通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE · Agg 算子类型及执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN ANALYZE` 查看聚合操作算子选择
  abnormal_pattern_quote: "如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时明显优于Sort+GroupAgg"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_sort
  param_name: enable_sort
  abnormal_value_pattern: on（默认），导致优化器在大结果集场景错误选择 Sort+GroupAgg
  recommended_value: `off`
  recommendation_quote: "如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off，HashAgg耗时明显优于Sort+GroupAgg"
  risk_if_violated_quote: NULL
  reasoning_quote: "通常情况下Agg选择HashAgg性能较好，如果大结果集选择了Sort+GroupAgg，则需要设置enable_sort=off"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-partition-pruning-failure-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 分区键包含表达式导致分区剪枝失效，全分区扫描耗时长达 10s
- **source_heading**: 案例：改写SQL排除剪枝干扰
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0488.html
- **source_url_lang**: zh-cn

### symptom_description

> 测试结果显示此SQL的表Scan耗时长达10s

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN ANALYZE VERBOSE · SQL 自诊断信息 + Partition Iterator 扫描分区数
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN (ANALYZE ON, VERBOSE ON) SELECT count(1) FROM t_ddw_f10_op_cust_asset_mon b1 WHERE b1.year_mth < substr('20200722',1 ,6 ) AND b1.year_mth + 1 >= cast(substr('20200722',1 ,6 ) AS int)`
  abnormal_pattern_quote: "Partitioned table unprunable Qual table public.t_ddw_f10_op_cust_asset_mon b1: left side of expression \"((year_mth + 1) > 202008)\" invokes function-call/type-conversion"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: EXPLAIN ANALYZE VERBOSE · 改写后 Partition Iterator Iterations
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN (analyze ON, verbose ON) SELECT count(1) FROM t_ddw_f10_op_cust_asset_mon b1 WHERE b1.year_mth < substr('20200722',1 ,6 ) AND b1.year_mth >= cast(substr('20200722',1 ,6 ) AS int) - 1`
  abnormal_pattern_quote: "不剪枝告警已经消除，剪枝后需要扫描分区数为1，执行时间从10s提升至3s"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Filter条件中存在表达式(year_mth + 1) > 202008，这种表达式一侧不是单纯的分区键、而是包含分区键的表达式的Filter条件是不能用来剪枝的，因而导致查询语句扫描了几乎整个分区表的数据。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "跟原始SQL语句对比，可以确定表达式 '(year_mth + 1) > 202008' 是从表达式 'b1.year_mth + 1 > substr('20200822',1 ,6 )' 衍生而来，按照诊断信息把修改SQL语句为如下方式：WHERE b1.year_mth <= substr('20200822',1 ,6 ) AND b1.year_mth > cast(substr('20200822',1 ,6 ) AS int) - 1"

```

## case_id: gaussdb-dws-partition-table-scan-optimization-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 大表无分区策略导致全表扫描耗时长，改建分区表后利用分区剪枝提升性能
- **source_heading**: 案例：改建分区表
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0484.html
- **source_url_lang**: zh-cn

### symptom_description

> 执行以下SQL语句查询非分区表的执行计划：由下图可知执行时间为73毫秒，其中全表扫描的时间为44~45毫秒。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · 全表扫描时间及 Partition Iterator Iterations
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE SELECT count(*) FROM orders_no_part WHERE o_orderdate >= '1996-01-01 00:00:00'::timestamp(0)`
  abnormal_pattern_quote: "执行时间为73毫秒，其中全表扫描的时间为44~45毫秒"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "在查询时，可通过分区剪枝技术尽可能减少底层数据扫描，即缩小表的扫描范围。分区剪枝是指对于分区表或分区索引来说，优化器可以自动从FROM和WHERE子句里根据分区键提取出需要扫描的分区，从而避免全表扫描，减少扫描的数据块，提高性能。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "执行时间为40毫秒，其中表扫描时间仅为13毫秒。另外Iterations越小，分区剪枝效果越好。"

```

## case_id: gaussdb-dws-pck-point-query-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 列存大表无 PCK 导致点查扫描全部 CU，执行时间 48ms，设置 PCK 后降至 5ms
- **source_heading**: 案例：调整局部聚簇键
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0481.html
- **source_url_lang**: zh-cn

### symptom_description

> 执行时间为48毫秒，查看Datanode Information发现filter时间为19毫秒，CUNone比例为0。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · CUNone 比例及 filter 耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE SELECT * FROM orders_no_pck WHERE o_orderkey = '13095143' ORDER BY o_orderdate`
  abnormal_pattern_quote: "执行时间为48毫秒，查看Datanode Information发现filter时间为19毫秒，CUNone比例为0。"
  abnormal_pattern_threshold: `CUNone比例 = 0`
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "使用ALTER TABLE将字段o_orderkey设置为PCK；由下图可知执行时间为5毫秒，查看Datanode Information发现filter时间为0.5毫秒，CUNone比例为82。CUNone比例越高，PCK的性能收益越明显。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "ALTER TABLE将字段o_orderkey设置为PCK；执行时间为5毫秒，CUNone比例为82"

```

## case_id: gaussdb-dws-pck-scan-acceleration-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 列存表未设置 Partial Cluster Key 导致 CStore Scan 大量加载 CU
- **source_heading**: 案例：使用partial cluster key
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0490.html
- **source_url_lang**: zh-cn

### symptom_description

> 使用partial cluster key后，5-- CStore Scan on public.lineitem的时间减少了1.2s，得益于有84个CU被过滤掉了

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · CStore Scan CU 加载数量
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE SELECT sum(l_extendedprice * l_discount) as revenue FROM lineitem WHERE l_shipdate >= '1994-01-01'::date and l_shipdate < '1994-01-01'::date + interval '1 year' and l_discount between 0.06 - 0.01 and 0.06 + 0.01 and l_quantity < 24`
  abnormal_pattern_quote: "使用partial cluster key后，5-- CStore Scan on public.lineitem的时间减少了1.2s，得益于有84个CU被过滤掉了"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] psort_work_mem
  param_name: psort_work_mem
  abnormal_value_pattern: 设值过小，导致 PCK 排序下盘写临时文件，影响导入性能
  recommended_value: NULL
  recommendation_quote: "排序使用的内存通过GUC参数psort_work_mem来设置，可以设置较大的值来使用更大的内存进行排序"
  risk_if_violated_quote: "如果无法在内存中完成排序时，会下盘写临时文件，这时就会产生较大的影响"
  reasoning_quote: "排序使用的内存通过GUC参数psort_work_mem来设置，可以设置较大的值来使用更大的内存进行排序"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "where条件中l_shipdate和l_quantity的distinct值数量较少且可以做min max过滤，将字段l_shipdate、l_quantity设置为PCK修改表定义"
  linked_diagnostic_step_no: 1
  mitigation_quote: "partial cluster key(l_shipdate, l_quantity)"

```

## case_id: gaussdb-dws-plan-hint-leading-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Join 顺序 hint (leading) 调优 store_sales / date_dim join 顺序
- **source_heading**: Join 顺序的hint
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://segmentfault.com/a/1190000038975701
- **source_url_lang**: zh-cn

### symptom_description

> store_sales和item表join后未过滤掉任何数据，所以这两个表join并生成hash表的时间都比较长。

### diagnostic_steps

```
[step 1]
  metric_name: explain performance 执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: explain performance select a.ca_state state, count(*) cnt from customer_address a ,customer c ,store_sales s ,date_dim d ,item i where a.ca_address_sk = c.c_current_addr_sk ...
  abnormal_pattern_quote: store_sales和item表join后未过滤掉任何数据，所以这两个表join并生成hash表的时间都比较长。
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: 加 leading hint 后执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: select /*+ leading((s d)) */ a.ca_state state, count(*) cnt ...
  abnormal_pattern_quote: 执行时间由34268.322ms降为11095.046ms。
  abnormal_pattern_threshold: `34268.322ms → 11095.046ms`
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 根据对tpcds各表中数据分布的了解，我们知道，store_sales表和date_dim进行join，可以过滤掉较多数据，所以，可以使用hint来提示优化器优将store_sales表和date_dim表先进行join
  linked_diagnostic_step_no: 2
  mitigation_quote: 通过调整join顺序，使得之后各join的中间结果集都大幅减少

```

## case_id: gaussdb-dws-plan-hint-nojoin-method-02

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: no nestloop hint 改 hashjoin 避免低效 NestLoop
- **source_heading**: Scan/Join方法的hint
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://segmentfault.com/a/1190000038975701
- **source_url_lang**: zh-cn

### symptom_description

> 由于store_sales表的行数估算不准，store_sales和date_dim采用了效率不好的nestloop方式进行join。

### diagnostic_steps

```
[step 1]
  metric_name: 加 leading + no nestloop hint 后执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: select /*+ leading((s d)) no nestloop(s d) */ a.ca_state state, count(*) cnt ...
  abnormal_pattern_quote: 优化器对store_sales和date_dim表之间的join方法已经由nestloop改为了hashjoin，且这条语句的执行时间也由11095.046ms降为4644.409ms。
  abnormal_pattern_threshold: `11095.046ms → 4644.409ms`
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 通过本节的hint方法来指示优化器不使用nestloop方式进行join。
  linked_diagnostic_step_no: 1
  mitigation_quote: no nestloop(table_list)

```

## case_id: gaussdb-dws-plan-hint-rows-03

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 行数 hint 指明 store_sales 准确行数
- **source_heading**: 行数hint
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://segmentfault.com/a/1190000038975701
- **source_url_lang**: zh-cn

### symptom_description

> 由于store_sales表没有统计信息，所以在上面的各个计划中可以看到，store_sales表的估计行数和实际行数相差非常大，这就会导致生成了最初的效率比较低的计划。

### diagnostic_steps

```
[step 1]
  metric_name: rows hint 后执行时间
  collection_layer: db-interactive-cmd
  collection_method_quote: select /*+ rows(s #2880404) */ a.ca_state state, count(*) cnt ...
  abnormal_pattern_quote: 指定了store_sales表的准确行数后，优化器生成的计划执行时间直接从最初的34268.322ms将为1991.843ms，提升了17倍。
  abnormal_pattern_threshold: `34268.322ms → 1991.843ms (17x)`
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 这也充分的说明了优化器对统计信息准确性的强烈依赖。
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-plan-hint-skew-04

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 倾斜值 hint 优化 HashAgg 重分布倾斜
- **source_heading**: 倾斜值hint
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://segmentfault.com/a/1190000038975701
- **source_url_lang**: zh-cn

### symptom_description

> with表达式中group by在做HashAgg中进行重分布时存在倾斜

### diagnostic_steps

```
[step 1]
  metric_name: skew hint 后双层 Agg 计划
  collection_layer: db-interactive-cmd
  collection_method_quote: select /*+ skew(store_returns(sr_store_sk sr_customer_sk)) */sr_customer_sk as ctr_customer_sk ...
  abnormal_pattern_quote: 对于HashAgg，由于其重分布存在倾斜，所以优化为双层Agg。
  abnormal_pattern_threshold: NULL
  metric_unit: plan-shape
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: 用于指明查询运行时重分布过程中存在倾斜的重分布键和倾斜值，针对Join和HashAgg运算中的重分布进行优化。
  linked_diagnostic_step_no: 1
  mitigation_quote: skew(table (column) [(value)])

```

## case_id: gaussdb-dws-planhint-rows-estimate-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 多列关联统计信息缺失导致 HashJoin 行数严重低估，使用 rows hint 干预后结合 join 顺序优化从 110s 降至 94s
- **source_heading**: Plan Hint实际调优案例
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0465.html
- **source_url_lang**: zh-cn

### symptom_description

> 该计划中，第10层算子使用broadcast性能较差，由于第11层算子估算行数为2140，比实际行数严重低估。错误行数估算主要来源于第13层算子的行数低估，根因是第13层hashjoin中，使用store_sales的(ss_ticket_number, ss_item_sk)列和store_returns的(sr_ticket_number, sr_item_sk)列进行关联，由于缺少多列相关性的估算导致行数严重低估。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows）
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE` 查看 TPC-DS Q24 部分语句执行计划
  abnormal_pattern_quote: "第11层算子估算行数为2140，比实际行数严重低估"
  abnormal_pattern_threshold: NULL
  metric_unit: s
  prerequisite_steps: []

[step 2]
  metric_name: EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时
  collection_layer: db-interactive-cmd
  collection_method_quote: `select avg(netpaid) from (select /*+rows(store_sales store_returns * 11270)*/ c_last_name ...`
  abnormal_pattern_quote: "最终计划如下图所示，运行时间94s，完成调优"
  abnormal_pattern_threshold: NULL
  metric_unit: s
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "根因是第13层hashjoin中，使用store_sales的(ss_ticket_number, ss_item_sk)列和store_returns的(sr_ticket_number, sr_item_sk)列进行关联，由于缺少多列相关性的估算导致行数严重低估。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "发现最后一层使用单层Agg，但行数缩减较多。使用相同的hint，同时结合参数best_agg_plan=3进行双层Agg调优，最终计划如下图所示，运行时间94s，完成调优。"

```

## case_id: gaussdb-dws-pushdown-data-node-scan-12

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: SQL 语句不能下推,执行计划中出现 Data Node Scan / RemoteQuery 节点
- **source_heading**: 语句下推调优 · 查看执行计划是否下推
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/devg-dws/dws_04_0447.html
- **source_url_lang**: zh-cn

### symptom_description

> 在“发送语句的分布式执行计划”策略中，要将大量中间结果从DN发送到CN，并且要在CN运行不能下推的部分语句，会导致CN成为性能瓶颈（带宽、存储、计算等）。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN · 是否含 Data Node Scan 节点
  collection_layer: db-interactive-cmd
  collection_method_quote: `如果执行计划中有Data Node Scan节点，那么此执行计划为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。`
  abnormal_pattern_quote: `Data Node Scan on store_sales "_REMOTE_TABLE_QUERY_"`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_fast_query_shipping
  param_name: enable_fast_query_shipping
  abnormal_value_pattern: 默认开启 + 不下推 SQL 仍走 fast-shipping 屏蔽真实计划
  recommended_value: `off (诊断时)`
  recommendation_quote: `将GUC参数“enable_fast_query_shipping”设置为off，使查询优化器使用分布式框架策略。`
  risk_if_violated_quote: NULL
  reasoning_quote: `将GUC参数“enable_fast_query_shipping”设置为off，使查询优化器使用分布式框架策略。`
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `执行语句不能下推是因为语句中含有不支持下推的函数或者不支持下推的语法。一般都可以通过等价改写规避执行计划不能下推的问题。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `一般都可以通过等价改写规避执行计划不能下推的问题。`

```

## case_id: gaussdb-dws-row-vs-column-store-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 中间表使用行存导致整体计划走行执行引擎，性能远差于列执行引擎
- **source_heading**: 案例：调整中间表存储方式
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0482.html
- **source_url_lang**: zh-cn

### symptom_description

> 某局点测试过程遇到如下的执行计划，客户希望将性能提升至3s内返回结果。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE` 查看是否有 Vector 前缀算子
  abnormal_pattern_quote: "经过分析发现计划走了行引擎。根本原因是：临时计划表input_acct_id_tbl和中间结果转储表row_unlogged_table使用了行存表。"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "修改这两个表为列存表之后，性能提升至1.6s。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "修改这两个表为列存表之后，性能提升至1.6s。"

```

## case_id: gaussdb-dws-copy-cdm-sequence-cache-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: CDM 数据同步 COPY 入库导入速率不达预期
- **source_heading**: sequence相关的典型优化场景
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0113.html
- **source_url_lang**: zh-cn

### symptom_description

> 某业务场景中使用CDM数据同步工具进行数据迁移，从源端入库目标端DWS。导入速率与经验值相差较大，业务将CDM并发从1调整为5，同步速率仍无法提升。

### diagnostic_steps

```
[step 1]
  metric_name: COPY 语句等待视图 · 轻量级锁等待
  collection_layer: db-system-view
  collection_method_quote: "根据这5个COPY语句对应的query_id查看等待视图情况"
  abnormal_pattern_quote: "查看到这5个COPY中，同一时刻，仅有1个COPY在向GTM申请序列值，其余的COPY在等待轻量级锁"
  abnormal_pattern_threshold: `同时只有 1 个 COPY 向 GTM 申请序列值，其余在等待轻量级锁`
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] sequence.cache
  param_name: sequence.cache
  abnormal_value_pattern: default 为 1, 并发 COPY 入库时 CN 频繁与 GTM 建连
  recommended_value: `10000 (按业务每次同步量评估)`
  recommendation_quote: "根据业务评估，将cache值修改为10000（实际使用时应根据业务设置合理的cache值，既能保证快速访问，又不会造成序列号浪费）"
  risk_if_violated_quote: "默认创建的sequence的cache为1，导致在并发COPY入库时，CN频繁与GTM建连，且多个并发之间存在轻量锁争抢，导致数据同步效率低"
  reasoning_quote: "COPY场景中，由CN负责向GTM申请序列值，因此，当sequence的cache值较小，CN会频繁和GTM建联并申请nextval，出现性能瓶颈"
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-sort-pushdown-cn-bottleneck-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: CN 端 Window Agg + Sort 未下推导致查询耗时严重
- **source_heading**: 案例：使排序下推
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0130.html
- **source_url_lang**: zh-cn

### symptom_description

> 在做场景性能测试时，发现某场景大部分时间是CN端在做window agg，占到总执行时间95%以上，系统资源不能充分利用。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE 执行计划 · Vector WindowAgg 耗时及位置
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE SELECT COUNT(1) over() AS DATACNT, IMSI AS IMSI_IMSI, CAST(TRUNC(((SUM(L4_UL_THROUGHPUT) + SUM(L4_DW_THROUGHPUT))), 0) AS DECIMAL(20)) AS TOTAL_VOLUME_KPIID FROM public.test AS test GROUP BY IMSI ORDER BY TOTAL_VOLUME_KPIID DESC LIMIT 10`
  abnormal_pattern_quote: "window agg和sort全部在CN端执行，耗时非常严重"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: []

[step 2]
  metric_name: EXPLAIN PERFORMANCE 改写后执行计划 · 排序下推验证
  collection_layer: db-interactive-cmd
  collection_method_quote: `EXPLAIN PERFORMANCE SELECT COUNT(1) over() AS DATACNT, IMSI_IMSI, TOTAL_VOLUME_KPIID FROM (SELECT IMSI AS IMSI_IMSI, CAST(TRUNC(((SUM(L4_UL_THROUGHPUT) + SUM(L4_DW_THROUGHPUT))), 0) AS DECIMAL(20)) AS TOTAL_VOLUME_KPIID FROM public.test AS test GROUP BY IMSI ORDER BY TOTAL_VOLUME_KPIID DESC LIMIT 10)`
  abnormal_pattern_quote: "经过SQL改写，性能由2.862s提升0.955s，优化效果明显"
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "研究发现该场景的特点是：将两列分别求sum作为一个子查询，外层对两列的和再求和后做trunc，然后排序。可以尝试将语句改写为子查询，使排序下推。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "尝试将语句改写为子查询：SELECT COUNT(1) over() AS DATACNT, IMSI_IMSI, TOTAL_VOLUME_KPIID FROM (SELECT IMSI AS IMSI_IMSI, CAST(TRUNC(((SUM(L4_UL_THROUGHPUT) + SUM(L4_DW_THROUGHPUT))), 0) AS DECIMAL(20)) AS TOTAL_VOLUME_KPIID FROM public.test AS test GROUP BY IMSI ORDER BY TOTAL_VOLUME_KPIID DESC LIMIT 10)"

```

## case_id: gaussdb-dws-hashjoin-large-inner-table-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: HashJoin 大表做内表导致内存和性能问题
- **source_heading**: HashJoin中大表做内表
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0446.html
- **source_url_lang**: zh-cn

### symptom_description

> 在表连接过程中使用了Hashjoin（可通过GS_WLM_SESSION_HISTORY的"query_plan"字段查看），且连接的内表行数是外表行数的10倍或以上；同时内表在每个DN上的平均行数大于10万行，且发生了下盘

### diagnostic_steps

```
[step 1]
  metric_name: GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息
  collection_layer: db-system-view
  collection_method_quote: `SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC`
  abnormal_pattern_quote: "PlanNode[7] Large Table is INNER in HashJoin \"Vector Hash Aggregate\""
  abnormal_pattern_threshold: `内表行数 ≥ 外表行数 × 10 且内表每DN平均行数 > 10万行且发生下盘`
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "针对这种场景，需要调整HashJoin内外表顺序，具体调优方法参考Join顺序的Hint"
  linked_diagnostic_step_no: 1
  mitigation_quote: "针对这种场景，需要调整HashJoin内外表顺序，具体调优方法参考Join顺序的Hint"

```

## case_id: gaussdb-dws-large-table-broadcast-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 大表 Broadcast 导致 DN 间大量数据传输
- **source_heading**: 大表Broadcast
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0446.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果在Broadcast算子中，平均每DN的行数大于10万行，则告警大表Broadcast

### diagnostic_steps

```
[step 1]
  metric_name: GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息
  collection_layer: db-system-view
  collection_method_quote: `SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC`
  abnormal_pattern_quote: "PlanNode[5] Large Table in Broadcast \"Streaming(type: BROADCAST dop: 1/2)\""
  abnormal_pattern_threshold: `平均每DN行数 > 10万行`
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "针对这种场景，需要禁止Broadcast下层算子做Broadcast动作，具体调优方法参考Stream方式的Hint"
  linked_diagnostic_step_no: 1
  mitigation_quote: "针对这种场景，需要禁止Broadcast下层算子做Broadcast动作，具体调优方法参考Stream方式的Hint"

```

## case_id: gaussdb-dws-stats-not-collected-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 统计信息未收集导致优化器估算不准，查询性能下降
- **source_heading**: 多列/单列统计信息未收集
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/devg-911-dws/dws_04_0446.html
- **source_url_lang**: zh-cn

### symptom_description

> 如果存在单列或者多列统计信息未收集，则上报相关告警

### diagnostic_steps

```
[step 1]
  metric_name: GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警
  collection_layer: db-system-view
  collection_method_quote: `SELECT query,warning FROM GS_WLM_SESSION_STATISTICS ORDER BY start_time DESC`
  abnormal_pattern_quote: "Statistic Not Collect schema_test.t1"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "对于这种告警，建议的优化方案是对相关表进行ANALYZE"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对于这种告警，建议的优化方案是对相关表进行ANALYZE，可参考更新统计信息和统计信息调优"

```

## case_id: gaussdb-dws-system-level-tuning-24

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 集群吞吐受限,系统级 GUC 未按 CPU/IO/内存/网络资源充分使用调优
- **source_heading**: 系统级调优项
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 6
- **source_url**: https://www.modb.pro/db/40297
- **source_url_lang**: zh-cn

### symptom_description

> 系统级调优又细分为操作系统参数调优和数据库全局参数调优，通常涉及到的是系统CPU、IO、内存、网络资源的充分使用，避免资源冲突，提升整个系统查询的吞吐量。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络)
  collection_layer: db-interactive-cmd
  collection_method_quote: `通过执行态信息，我们可以分析出算子为单位的性能，也可以分析出算子内部各步骤的性能，进一步为诊断性能的瓶颈打下了基础。`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] query_dop
  param_name: query_dop
  abnormal_value_pattern: 未配置或为 0,未按系统资源动态获取并行度
  recommended_value: `0 (动态) — 需开启 use_workload_manager=on`
  recommendation_quote: `通过query_dop设置语句的执行并行度（注：query_dop为0时根据系统资源情况动态获取并行度，需要开启资源管理模块use_workload_manager=on）`
  risk_if_violated_quote: NULL
  reasoning_quote: `通过query_dop设置语句的执行并行度（注：query_dop为0时根据系统资源情况动态获取并行度，需要开启资源管理模块use_workload_manager=on）`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] shared_buffers
  param_name: shared_buffers
  abnormal_value_pattern: 设置过小,数据页面频繁从磁盘加载
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: NULL
  reasoning_quote: `通过shared_buffers和cstore_buffers设置缓存大小，用于缓存数据页面，减少IO使用。`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] cstore_buffers
  param_name: cstore_buffers
  abnormal_value_pattern: 设置过小,列存表场景下扫描频繁触发 IO
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: NULL
  reasoning_quote: `通过shared_buffers和cstore_buffers设置缓存大小，用于缓存数据页面，减少IO使用。`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 4] max_process_memory
  param_name: max_process_memory
  abnormal_value_pattern: 内存自适应场景下设置过小,算子无法获得足够内存
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: NULL
  reasoning_quote: `内存自适应模式会自动根据系统可用内存为计划中各个算子分配内存，因此需要设置max_process_memory参数`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 5] work_mem
  param_name: work_mem
  abnormal_value_pattern: 非内存自适应场景下未设置,算子越过阈值即下盘
  recommended_value: NULL
  recommendation_quote: NULL
  risk_if_violated_quote: `超过阈值则下盘`
  reasoning_quote: `非内存自适应需要通过work_mem参数指定算子使用内存，超过阈值则下盘。`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 6] comm_max_stream
  param_name: comm_max_stream
  abnormal_value_pattern: 并发/并行度提升后,Stream 算子不足
  recommended_value: `调大但不可过大(过大占内存)`
  recommendation_quote: `通过comm_max_stream参数指定并发时最大的Stream算子个数。当并行度和并发度增大时，需要将该参数调大，否则Stream个数不够，但该参数过大也会占用更多内存。`
  risk_if_violated_quote: `否则Stream个数不够`
  reasoning_quote: `通过comm_max_stream参数指定并发时最大的Stream算子个数。当并行度和并发度增大时，需要将该参数调大，否则Stream个数不够，但该参数过大也会占用更多内存。`
  linked_diagnostic_step_no: 1

```

## case_id: gaussdb-dws-vacuum-full-long-tx-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: VACUUM FULL 后表文件大小无变化(长事务干扰)
- **source_heading**: VACUUM FULL一张表后，表文件大小无变化
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0033.html
- **source_url_lang**: zh-cn

### symptom_description

> 使用VACUUM FULL命令对一张表进行清理，清理完成后表大小和清理前一样大。

### diagnostic_steps

```
[step 1]
  metric_name: 当前事务 XID
  collection_layer: db-system-view
  collection_method_quote: `SELECT txid_current();`
  abnormal_pattern_quote: "执行以下命令查询当前的事务XID。"
  abnormal_pattern_threshold: NULL
  metric_unit: xid
  prerequisite_steps: []

[step 2]
  metric_name: 活跃事务列表
  collection_layer: db-system-view
  collection_method_quote: `SELECT txid_current_snapshot(); `
  abnormal_pattern_quote: "如果发现活跃事务列表中有XID比当前的事务XID小时"
  abnormal_pattern_threshold: `活跃事务列表中有 XID < 当前事务 XID`
  metric_unit: xid
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "在执行VACUUM FULL table_name时有长事务存在，可能会导致VACUUM FULL跳过清理最近删除的数据，导致清理不完全。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "如果在VACUUM FULL时有并发的事务存在，此时需要等待所有事务结束，再次执行VACUUM FULL命令对该表进行清理。"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "表本身没有delete或update过数据，使用VACUUM FULL table_name后无需清理delete的数据，因此表大小清理前后一样大。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-dws-vacuum-defer-cleanup-age-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: VACUUM 后存储空间未释放 (vacuum_defer_cleanup_age 非 0)
- **source_heading**: 删除表数据后执行了VACUUM，但存储空间并没有释放
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0047.html
- **source_url_lang**: zh-cn

### symptom_description

> 删除表数据后执行了VACUUM，但是存储空间并没有释放。

### diagnostic_steps

```
[step 1]
  metric_name: vacuum_defer_cleanup_age 参数值
  collection_layer: db-shell
  collection_method_quote: "参数vacuum_defer_cleanup_age不是0，该参数在老版本默认为8000，表示最近8000个事务产生的脏数据不进行回收。"
  abnormal_pattern_quote: "参数vacuum_defer_cleanup_age不是0"
  abnormal_pattern_threshold: `vacuum_defer_cleanup_age != 0`
  metric_unit: xacts
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] vacuum_defer_cleanup_age
  param_name: vacuum_defer_cleanup_age
  abnormal_value_pattern: 非 0 (老版本默认 8000) 导致延迟清理
  recommended_value: `0`
  recommendation_quote: "对于vacuum_defer_cleanup_age不是0的场景，可以将此参数改为0，取消VACUUM的事务延迟。"
  risk_if_violated_quote: "表示最近8000个事务产生的脏数据不进行回收"
  reasoning_quote: "参数vacuum_defer_cleanup_age不是0，该参数在老版本默认为8000"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "为了保证事务可见性，产生脏数据的事务号，如果大于当前活跃的老事务号，则这部分脏数据也不会清理。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "对于存在老事务的场景，重启集群再重新执行VACUUM FULL可以保证空间一定回收，否则只能等老事务结束再执行VACUUM FULL。"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "执行VACUUM，默认清理当前用户在数据库中拥有权限的每一个表，没有权限的表则直接跳过回收操作。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "如果您对表没有权限，请联系数据库管理员或表的所有者进行处理。"

```

## case_id: gaussdb-dws-cant-fit-xid-old-tx-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Can't fit xid into page 报错(老事务导致 freeze 失效)
- **source_heading**: 执行业务报错"Can't fit xid into page"
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0102.html
- **source_url_lang**: zh-cn

### symptom_description

> 场景一：执行VACUUM FULL时报错"Can't fit xid into page, now xid is 34181619720, base is 29832807366, min is 3, max is 3."。

### diagnostic_steps

```
[step 1]
  metric_name: GTM snapshot · oldestxmin 与 xid 差值
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_gtm_snapshot_status();`
  abnormal_pattern_quote: "如果查询结果中oldestxmin小于base+min，且小很多，说明系统中存在老事务，且导致vacuum freeze执行未产生作用"
  abnormal_pattern_threshold: `oldestxmin << base+min`
  metric_unit: xid
  prerequisite_steps: []

[step 2]
  metric_name: 老事务列表 (pgxc_running_xacts)
  collection_layer: db-system-view
  collection_method_quote: `SELECT * FROM pgxc_running_xacts where xmin::text::bigint < $base+$min and xmin::text::bigint > 0;`
  abnormal_pattern_quote: "使用如下命令查询集群中老事务信息"
  abnormal_pattern_threshold: `存在 xmin < base+min 的活跃事务`
  metric_unit: xid
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "系统中存在老事务导致上述报错。"
  linked_diagnostic_step_no: 2
  mitigation_quote: "通过pgxc_stat_activity视图查询步骤2中的业务，确认后执行如下命令终止对应的线程。"

```

## case_id: gaussdb-import-skew-warning-07

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: 导入(INSERT/COPY)时 DN 间数据倾斜超过阈值需即时告警
- **source_heading**: 导入过程存储倾斜即时检测
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 4
- **source_url**: https://support.huaweicloud.com/bestpractice-dws/dws_05_0004.html
- **source_url_lang**: zh-cn

### symptom_description

> 导入过程中对DN导入行数进行统计，导入完成后计算倾斜率，超过一定阈值时，立即进行告警。倾斜率通过（DN导入行数最大值-DN导入行数最小值）/导入总行数计算。

### diagnostic_steps

```
[step 1]
  metric_name: DN 间导入行数倾斜率(WARNING)
  collection_layer: log-grep
  collection_method_quote: `WARNING:  Skewness occurs, table name: xxx, min value: xxx, max value: xxx, sum value: xxx, avg value: xxx, skew ratio: xxx`
  abnormal_pattern_quote: `超过一定阈值时，立即进行告警`
  abnormal_pattern_threshold: `skew ratio > table_skewness_warning_threshold`
  metric_unit: ratio
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] enable_stream_operator
  param_name: enable_stream_operator
  abnormal_value_pattern: 关闭(off) 状态下,DN 一次性返回导入行数受影响,无法在 CN 计算倾斜率
  recommended_value: `on`
  recommendation_quote: `必须设置enable_stream_operator=on，确保计划下发到DN，DN一次性返回导入行数，从而可以在CN计算倾斜率。`
  risk_if_violated_quote: NULL
  reasoning_quote: `必须设置enable_stream_operator=on，确保计划下发到DN，DN一次性返回导入行数，从而可以在CN计算倾斜率。`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] table_skewness_warning_threshold
  param_name: table_skewness_warning_threshold
  abnormal_value_pattern: 默认值 1(关闭状态),不会触发告警
  recommended_value: `0~1 (设为 <1 即开启)`
  recommendation_quote: `表倾斜告警阈值取值范围0~1，默认值为1，即关闭状态，取其他值时为开启状态。`
  risk_if_violated_quote: NULL
  reasoning_quote: `设置参数（表倾斜告警阈值table_skewness_warning_threshold和表倾斜告警最小行数table_skewness_warning_rows）`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 3] table_skewness_warning_rows
  param_name: table_skewness_warning_rows
  abnormal_value_pattern: 设过小会在小数据量导入时无意义告警
  recommended_value: `default 100000 (设为业务可接受最小行数)`
  recommendation_quote: `表倾斜告警最小行数取值范围0~2147483647，默认值为100,000。当导入总行数超过该值与导入DN数之积时，才可能触发告警，从而不会在小数据量导入的场景进行无意义的告警。`
  risk_if_violated_quote: NULL
  reasoning_quote: `表倾斜告警最小行数取值范围0~2147483647，默认值为100,000。当导入总行数超过该值与导入DN数之积时，才可能触发告警，从而不会在小数据量导入的场景进行无意义的告警。`
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] data-distribution
  cause_type: data-distribution
  description_quote: `Please check data distribution or modify warning threshold`
  linked_diagnostic_step_no: 1
  mitigation_quote: `检查数据分布或者修改参数`

```

## case_id: gaussdb-too-many-clients-21

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: connection-storm
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: Too many clients already — non-active 空闲连接积压
- **source_heading**: 连接DWS数据库时，提示客户端连接数太多
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://support.huaweicloud.com/trouble-dws/dws_09_0038.html
- **source_url_lang**: zh-cn

### symptom_description

> FATAL: Already too many clients, active/non-active/reserved: 5/508/3.

### diagnostic_steps

```
[step 1]
  metric_name: pg_stat_activity · idle 连接数
  collection_layer: db-system-view
  collection_method_quote: `SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';`
  abnormal_pattern_quote: `non-active的个数表示空闲连接数，例如，non-active为508，说明当前有大量的空闲连接。`
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] session_timeout
  param_name: session_timeout
  abnormal_value_pattern: 默认 600s,在空闲连接积压场景下可调小
  recommended_value: `> 0 (不建议设为 0)`
  recommendation_quote: `session_timeout默认值为600秒，设置为0表示关闭超时限制，一般不建议设置为0。`
  risk_if_violated_quote: `non-active的个数表示空闲连接数，例如，non-active为508，说明当前有大量的空闲连接。`
  reasoning_quote: `在DWS控制台设置会话闲置超时时长session_timeout，在闲置会话超过所设定的时间后服务端将主动关闭连接。`
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] max_connections
  param_name: max_connections
  abnormal_value_pattern: 默认 800(CN) / 5000(DN),已达上限
  recommended_value: `> default · 由 DBA 根据并发评估`
  recommendation_quote: `查看CN上的连接来自哪里，总数量以及是否超过当前max_connections（默认值CN节点为800，DN节点为5000）。`
  risk_if_violated_quote: `当前数据库连接已经超过了最大连接数`
  reasoning_quote: `查看CN上的连接来自哪里，总数量以及是否超过当前max_connections（默认值CN节点为800，DN节点为5000）。`
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: gaussdb-windowagg-single-dn-04

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
- **title**: row_number() over() + count() over() 窗口函数全集中在单 DN 执行
- **source_heading**: 1、【问题描述】+ 3、性能分析
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://bbs.huaweicloud.com/blogs/906ef9eaf32e4254a9eefb2babdbd53a
- **source_url_lang**: zh-cn

### symptom_description

> row_number() over(), count() over()慢，执行计划中出现sort、WindowAgg，窗口函数集中在一个DN上运行。

### diagnostic_steps

```
[step 1]
  metric_name: EXPLAIN PERFORMANCE · 算子分布
  collection_layer: db-interactive-cmd
  collection_method_quote: `explain performance`
  abnormal_pattern_quote: `执行计划中出现Sort和WindowAgg，第3~6步集中在一个DN上进行，使SQL非常缓慢`
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

[step 2]
  metric_name: 算子 A-time(在单 DN 上的运行耗时)
  collection_layer: db-interactive-cmd
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: ms
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: `为了消除对大量数据的WindowAgg，需要对SQL进行改写，目的是通过等价逻辑改写，消除窗口函数。`
  linked_diagnostic_step_no: 1
  mitigation_quote: `改写逻辑：把t2写成with子查询以在join时使用其别名，使用left join (select count() from t2)代替count() over()，使用limit offset代替row_number() over()和对rn的过滤。`

```
