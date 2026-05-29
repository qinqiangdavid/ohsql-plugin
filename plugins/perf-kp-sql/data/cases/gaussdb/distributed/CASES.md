<!-- ============ Diagnostic-Flow (gaussdb/distributed, 22 cases) ============ -->

## case_id: gaussdb-cpu-high-statement-view-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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

## case_id: gaussdb-dist-volatile-func-not-pushed-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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
- **topology**: distributed-only
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

## case_id: gaussdb-dist-v3-volatile-func-not-pushed-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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

## case_id: gaussdb-dws-plan-suboptimal-planhint-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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
- **topology**: distributed-only
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

## case_id: gaussdb-dist-disk-full-storage-skew-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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
- **topology**: distributed-only
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

## case_id: gaussdb-rewrite-magicset-correlated-subquery-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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

## case_id: gaussdb-query-slow-agg-plan-mode-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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

## case_id: gaussdb-data-skew-storage-distribution-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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
- **topology**: distributed-only
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
- **topology**: distributed-only
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
- **topology**: distributed-only
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
- **topology**: distributed-only
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

## case_id: gaussdb-data-skew-hashjoin-dn-compute-skew-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: data-skew
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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

## case_id: gaussdb-plan-suboptimal-row-estimate-broadcast-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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
- **topology**: distributed-only
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

## case_id: gaussdb-rewrite-rule-partialpush-13

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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

## case_id: gaussdb-query-slow-windowagg-sort-on-cn-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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

## case_id: gaussdb-statement-not-shippable-cn-bottleneck-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: distributed-only
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
- **topology**: distributed-only
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
