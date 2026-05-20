<!-- ============ Diagnostic-Flow (gaussdb-dws, 65 cases) ============ -->

## case_id: gaussdb-dws-plan-suboptimal-broadcast-skew-redistribute-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
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

## case_id: gaussdb-dws-table-bloat-autovacuum-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb-dws
- **platform**: bare
- **engine**: gaussdb-dws
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
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
