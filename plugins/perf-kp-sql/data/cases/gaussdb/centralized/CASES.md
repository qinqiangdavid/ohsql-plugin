<!-- ============ Diagnostic-Flow (gaussdb/centralized, 4 cases) ============ -->

## case_id: gaussdb-query-slow-missing-statistics-explain-verbose-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
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

## case_id: gaussdb-rewrite-v8-intargetlist-subplan-slow-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
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

## case_id: gaussdb-copy-constraint-violation-tolerance-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
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

## case_id: gaussdb-plan-suboptimal-missing-analyze-01

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
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
