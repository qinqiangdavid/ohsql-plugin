<!-- ============ Diagnostic-Flow (gaussdb/centralized, 8 cases) ============ -->

## case_id: gaussdb-lock-contention-x12

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
- **title**: GaussDB中长事务及阻塞排查诊断
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 3
- **source_url_lang**: zh-cn

### symptom_description

> 出现长事务：大量会话等锁超时、执行时间长，引发主备复制时延升高、回滚耗时长、undo 记录无法回收。

### diagnostic_steps

```
[step 1]
  metric_name: pg_stat_activity长事务执行时长
  collection_layer: db-system-view
  collection_method_quote: `select current_timestamp - query_start as runtime,datname,usename,sessionid,substr(query,0,100) from pg_stat_activity where state != 'idle' and datname in('$database') and usename in ('$user') and extract(epoch from current_timestamp-xact_start)/60 > 1 order by 1 desc;`
  abnormal_pattern_quote: extract(epoch from current_timestamp-xact_start)/60 > 1
  abnormal_pattern_threshold: > 1 (分钟)
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: pg_thread_wait_status等待事件
  collection_layer: db-system-view
  collection_method_quote: `select * from pg_thread_wait_status where sessionid in (select sessionid from pg_stat_activity where state != 'idle' and datname in('$database') and usename in ('$user') and extract(epoch from current_timestamp-xact_start)/60 > 1);`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: pg_thread_wait_status阻塞源会话
  collection_layer: db-system-view
  collection_method_quote: `select * from pg_thread_wait_status where sessionid in (select block_sessionid from pg_thread_wait_status where sessionid in (select sessionid from pg_stat_activity where state != 'idle' and datname in('$database') and usename in ('$user') and extract(epoch from current_timestamp-xact_start)/60 > 1));`
  abnormal_pattern_quote: NULL
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 4]
  metric_name: gs_asp历史长事务采样记录
  collection_layer: db-system-view
  collection_method_quote: `SELECT DISTINCT a.xact_start_time, (a.sample_time - a.xact_start_time) as xact_run_time, a.thread_id, a.sessionid, d.datname AS database_name, u.usename AS username, a.application_name,a.client_addr, a.client_hostname FROM gs_asp a JOIN pg_database d ON a.databaseid = d.oid JOIN pg_user u ON a.userid = u.usesysid WHERE a.xact_start_time is not null AND username not in ('rdsAdmin') AND sample_time between '<日期> 某时刻' and '<日期> 某时刻' AND extract(epoch from xact_run_time)/60 > 1 --自定义执行时长，表示执行时间超过1min的事务 ORDER BY xact_run_time DESC;`
  abnormal_pattern_quote: extract(epoch from xact_run_time)/60 > 1 --自定义执行时长，表示执行时间超过1min的事务
  abnormal_pattern_threshold: > 1 (分钟)
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 应用逻辑存在问题，没有及时提交事务
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 2] other
  cause_type: other
  description_quote: SQL执行时间过长，需要SQL优化
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

[non_parameter_causes · cause 3] other
  cause_type: other
  description_quote: 锁竞争严重
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-plan-suboptimal-x17

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: plan-suboptimal
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
- **title**: GaussDB统计信息不准导致查询变慢
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 2
- **source_url_lang**: zh-cn

### symptom_description

> 某些查询执行明显变慢，且查看执行计划（EXPLAIN/EXPLAIN ANALYZE）时，发现估算行数与实际处理行数差距很大。

### diagnostic_steps

```
[step 1]
  metric_name: last_analyze_time
  collection_layer: db-system-view
  collection_method_quote: `select * from PG_STAT_ALL_TABLES where relname='tablename';`
  abnormal_pattern_quote: 确定系统/手动上一次 ANALYZE 是否过久。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: autovacuum_settings
  collection_layer: db-system-view
  collection_method_quote: `select * from pg_settings where name like '%vacuum%';`
  abnormal_pattern_quote: 如果 autovacuum 被关闭或配置阈值过高，则表更新后可能长期没有触发自动分析。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: autoanalyze_threshold
  collection_layer: db-interactive-cmd
  collection_method_quote: `select * from pg_stat_get_tuples_changed('table_name'::REGCLASS); select pg_autovac_status('table_name'::REGCLASS);`
  abnormal_pattern_quote: 确认是否达到触发autoanalyze阈值
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[parameter_causes · cause 1] autovacuum相关参数
  param_name: autovacuum相关参数
  abnormal_value_pattern: 被关闭或配置阈值过高
  recommended_value: NULL
  recommendation_quote: 如果 autovacuum 被关闭或配置阈值过高，则表更新后可能长期没有触发自动分析。
  risk_if_violated_quote: NULL
  reasoning_quote: NULL
  linked_diagnostic_step_no: NULL

[non_parameter_causes · cause 1] other
  cause_type: other
  description_quote: 发生过主备切换，pg_stats 视图重置 / 不会对 pg_statistic 系统表进行 analyze / 分布式表上存在gsi: 统计信息缺失导致insert慢 / gsstat线程未收到统计信息 / 是否有大表进行vacuum阻塞了analyze : CPU 冲高 / analyze/autoanalyze未生效
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-other-tps-x19

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
- **title**: GaussDB主备切换后TPS性能劣化16%
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> 业务压测（600 并发）中主动触发主备切换，切主后 TPS 劣化约 16%。

### diagnostic_steps

```
[step 1]
  metric_name: CPU、IO、内存使用率
  collection_layer: os
  collection_method_quote: `通过htop查看CPU、IO、内存使用情况`
  abnormal_pattern_quote: CPU还没有压满，内存充足。未发现异常
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: wait cmd计数
  collection_layer: db-system-view
  collection_method_quote: `select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;`
  abnormal_pattern_quote: 发现wait cmd计数很多，属于异常现象。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: TPLworker数量 / CPU idle空闲
  collection_layer: flamegraph
  collection_method_quote: `NULL`
  abnormal_pattern_quote: 正常节点的TPLworker数量达到690个，但是异常节点的TPLworker数量只有380个
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 业务方业务代码连接的一个接口IP地址写死了，每次都是先连第一个，再连第二个，再连第三个这样轮询，业务压测流量没有集中到新的主节点上导致的。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

## case_id: gaussdb-memory-pressure-other-x28

- **entry_kind**: diagnostic-flow
- **db**: gaussdb
- **platform**: bare
- **engine**: gaussdb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **topology**: centralized-only
- **title**: GaussDB other内存持续缓慢增长导致主备切换诊断
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url_lang**: zh-cn

### symptom_description

> other内存持续增长，达到150GB，操作系统内存使用率100%，可用内存为0。CMA连续三次无法ping通其他所有备机，触发主备切换。七天内的监控数据看动态内存和共享内存使用情况正常，只有other内存持续上涨，增长到了150G（正常情况下应该20G左右）。

### diagnostic_steps

```
[step 1]
  metric_name: other内存增长趋势
  collection_layer: db-system-view
  collection_method_quote: `select * from pg_total_memory_detail;`
  abnormal_pattern_quote: jemalloc调优对于业务场景没有生效，other内存依然稳定斜率上涨。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 2]
  metric_name: 内存泄漏信息
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] memcheck，1:1展开复现业务，打印如下泄露信息`
  abnormal_pattern_quote: 确认到是使用CRYPTO_zalloc存在未释放现象。
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

[step 3]
  metric_name: 代码调用栈/未释放函数
  collection_layer: manual-code
  collection_method_quote: `[需确认代码] 进一步排查代码发现在pymysql驱动建连时，RSA鉴权过程中存在内存未及时释放的情况`
  abnormal_pattern_quote: 调用了 EVP_PKEY_CTX_new，但未调用对应的 EVP_PKEY_CTX_free
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: NULL

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: 由于业务方业务脚本频繁使用短连接，导致RSA鉴权阶段申请的内存无法归还给操作系统，堆积在gaussdb进程，这部分内存也会被统计在 other 内存中。
  linked_diagnostic_step_no: NULL
  mitigation_quote: NULL

```

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
