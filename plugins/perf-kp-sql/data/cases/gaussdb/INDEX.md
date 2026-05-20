# Cases Index

> 生成时间: 2026-05-20T07:48:43.492Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 38 cases (db=gaussdb)
> 配套: cases/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| gaussdb-cpu-high-topsql-01 | cpu-high | GaussDB CPU使用率高——通过dbe_perf.statement定位高CPU SQL | 4890 |
| gaussdb-cpu-high-connection-timezone-01 | cpu-high | GaussDB CPU SYS高——高并发短连接重复加载时区文件 | 4949 |
| gaussdb-memory-shared-buffer-miss-01 | memory-pressure | GaussDB内存不足——shared_buffers过小导致buffer命中率低 | 4995 |
| gaussdb-memory-work-mem-spill-01 | memory-pressure | GaussDB内存不足——work_mem过小导致Hash/Sort算子落盘 | 5042 |
| gaussdb-cpu-high-statement-view-01 | cpu-high | GaussDB整体CPU高——通过性能视图定位高CPU SQL | 5089 |
| gaussdb-disk-io-high-statement-view-01 | disk-io-saturation | GaussDB整体IO高——通过性能视图定位高物理读SQL | 5151 |
| gaussdb-memory-pressure-node-detail-01 | memory-pressure | GaussDB内存高——通过dbe_perf.memory_node_detail定位内存占用点 | 5213 |
| gaussdb-perf-jitter-asp-analysis-01 | other | GaussDB性能抖动——通过ASP/WDR定位抖动根因 | 5275 |
| gaussdb-dist-volatile-func-not-pushed-slow-01 | cpu-high | 自定义函数VOLATILE属性导致分布式语句不下推 | 5328 |
| gaussdb-plan-suboptimal-rewrite-rule-partialpush-01 | plan-suboptimal | 自定义函数无法下推导致 CN 上全量 HASH JOIN，partialpush 参数可提升性能 | 5381 |
| gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01 | plan-suboptimal | 目标列相关子查询无法提升，逐行触发子查询导致性能低下，intargetlist 参数转为 JOIN 提升性能 | 5428 |
| gaussdb-dist-v3-volatile-func-not-pushed-slow-01 | cpu-high | 分布式v3：自定义函数VOLATILE属性导致语句不下推、CN性能瓶颈 | 5475 |
| gaussdb-plan-suboptimal-missing-analyze-dist-v8-01 | plan-suboptimal | 未收集统计信息导致 GaussDB 分布式查询性能差（v8） | 5528 |
| gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01 | plan-suboptimal | 多表 JOIN 中间结果估算不准，NestLoop 耗时 12s，改用 unlogged table + 禁 hashjoin 降至 3s | 5572 |
| gaussdb-query-slow-missing-analyze-01 | plan-suboptimal | 未收集统计信息（analyze）导致查询性能差、执行计划选错 | 5628 |
| gaussdb-query-slow-complex-join-intermediate-rows-01 | query-slow | 多表 join 中间结果估算不准导致 Hash Join 建大 Hash Table、查询慢 | 5681 |
| gaussdb-plan-suboptimal-seqscan-vs-indexscan-01 | plan-suboptimal | SeqScan 扫描过滤大量数据，点查场景应走 IndexScan | 5728 |
| gaussdb-plan-suboptimal-nestloop-large-outer-01 | plan-suboptimal | 两表 JOIN 外表行数大时 NestLoop 耗时 5s，关闭 NestLoop+MergeJoin 改 HashJoin 降至 86ms | 5772 |
| gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01 | plan-suboptimal | 大结果集 Agg 走 Sort+GroupAgg 耗时长，关闭 Sort 改 HashAgg 性能提升 | 5828 |
| gaussdb-dws-plan-suboptimal-planhint-01 | plan-suboptimal | TPC-DS Q24查询执行计划不优——使用Plan Hint调优 | 5875 |
| gaussdb-query-slow-no-partial-pushdown-01 | query-slow | 含不可下推函数的查询未使用 partialpush 导致大量数据在 CN 上做 Hash Join、查询慢 | 5919 |
| gaussdb-query-slow-correlated-subquery-target-list-01 | query-slow | 目标列相关子查询未提升导致每行触发子查询、查询慢 | 5966 |
| gaussdb-dist-disk-full-storage-skew-01 | disk-space-pressure | 磁盘满后快速定位存储倾斜表 | 6013 |
| gaussdb-dist-routine-skew-inspection-01 | data-skew | 常规数据倾斜巡检：表个数少于1W时使用PGXC_GET_TABLE_SKEWNESS视图 | 6057 |
| gaussdb-query-slow-missing-statistics-explain-verbose-01 | plan-suboptimal | 未收集统计信息导致查询性能差（集中式v3） | 6110 |
| gaussdb-query-slow-seqscan-index-missing-01 | query-slow | 点查/范围扫描使用SeqScan全表扫描导致查询慢 | 6163 |
| gaussdb-query-slow-nestloop-hashjoin-02 | query-slow | 两表Join选择NestLoop导致查询执行慢（大数据量场景） | 6207 |
| gaussdb-query-slow-groupagg-sort-03 | query-slow | 大结果集聚合选择Sort+GroupAgg导致性能差 | 6254 |
| gaussdb-query-slow-seqscan-no-index-01 | query-slow | 点查或范围扫描选择SeqScan全表扫描导致查询慢 | 6301 |
| gaussdb-query-slow-nestloop-large-rowset-01 | query-slow | 两表Join选择NestLoop但实际行数大导致查询慢 | 6345 |
| gaussdb-query-slow-sort-groupagg-large-result-01 | query-slow | 大结果集Agg选择Sort+GroupAgg导致查询慢 | 6392 |
| gaussdb-rewrite-lazyagg-double-aggregate-slow-01 | query-slow | 子查询与外层有相同GROUP BY时双层聚集运算效率低下 | 6439 |
| gaussdb-rewrite-magicset-correlated-subquery-slow-01 | query-slow | 带聚集算子的相关子查询重复扫描导致性能差 | 6486 |
| gaussdb-rewrite-v8-intargetlist-subplan-slow-01 | query-slow | 集中式v8：目标列相关子查询无法提升（intargetlist） | 6533 |
| gaussdb-replica-lag-redo-workers-01 | replica-lag | GaussDB业务压力大时备DN回放速度跟不上主DN，日志累积影响RTO | 6580 |
| gaussdb-plan-suboptimal-missing-analyze-01 | plan-suboptimal | 未收集统计信息导致查询性能差（集中式GaussDB） | 6642 |
| gaussdb-rewrite-intargetlist-subplan-slow-01 | query-slow | 目标列相关子查询无法提升导致每行触发SubPlan执行，查询性能低下 | 6695 |
| gaussdb-rewrite-uniquecheck-subquery-join-01 | query-slow | 无agg子查询无法自动提升导致子链接重复执行 | 6742 |
