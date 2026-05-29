# Cases Index

> 生成时间: 2026-05-29T09:18:14.075Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 22 cases
> 配套: gaussdb/distributed/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| gaussdb-cpu-high-statement-view-01 | cpu-high | GaussDB整体CPU高——通过性能视图定位高CPU SQL | 3 |
| gaussdb-dist-volatile-func-not-pushed-slow-01 | cpu-high | 自定义函数VOLATILE属性导致分布式语句不下推 | 66 |
| gaussdb-plan-suboptimal-rewrite-rule-partialpush-01 | plan-suboptimal | 自定义函数无法下推导致 CN 上全量 HASH JOIN，partialpush 参数可提升性能 | 120 |
| gaussdb-dist-v3-volatile-func-not-pushed-slow-01 | cpu-high | 分布式v3：自定义函数VOLATILE属性导致语句不下推、CN性能瓶颈 | 168 |
| gaussdb-dws-plan-suboptimal-planhint-01 | plan-suboptimal | TPC-DS Q24查询执行计划不优——使用Plan Hint调优 | 222 |
| gaussdb-query-slow-no-partial-pushdown-01 | query-slow | 含不可下推函数的查询未使用 partialpush 导致大量数据在 CN 上做 Hash Join、查询慢 | 267 |
| gaussdb-dist-disk-full-storage-skew-01 | disk-space-pressure | 磁盘满后快速定位存储倾斜表 | 315 |
| gaussdb-dist-routine-skew-inspection-01 | data-skew | 常规数据倾斜巡检：表个数少于1W时使用PGXC_GET_TABLE_SKEWNESS视图 | 360 |
| gaussdb-rewrite-magicset-correlated-subquery-slow-01 | query-slow | 带聚集算子的相关子查询重复扫描导致性能差 | 414 |
| gaussdb-query-slow-agg-plan-mode-01 | query-slow | 优化器代价估算偏差导致 Agg 计算方式选择不优 | 462 |
| gaussdb-data-skew-storage-distribution-01 | data-skew | 分布列选择不合理导致存储倾斜影响查询性能 | 510 |
| gaussdb-data-skew-compute-redistribute-01 | data-skew | 重分布列存在倾斜值导致计算倾斜，部分 DN 处理数据量远大于其他节点 | 564 |
| gaussdb-disk-space-pressure-storage-skew-locate-01 | disk-space-pressure | 磁盘满后快速定位存储倾斜的表 | 618 |
| gaussdb-distribution-key-skew-xc-node-id-25 | data-skew | 分布键选择不当致 DN 间数据量差 >10%,木桶效应拖慢整体 | 672 |
| gaussdb-dws-distkey-choice-01 | plan-suboptimal | 选择合适的分布列避免不必要 Streaming | 722 |
| gaussdb-data-skew-hashjoin-dn-compute-skew-01 | data-skew | 表数据分布倾斜导致 HashJoin DN 计算时间严重偏斜 | 776 |
| gaussdb-plan-suboptimal-row-estimate-broadcast-01 | query-slow | 多列关联估算行数严重低估导致广播代价高 | 839 |
| gaussdb-plan-suboptimal-statistics-change-plan-regression-01 | plan-suboptimal | 统计信息变更导致 Join 流方式从 Broadcast 切换为 Redistribute 引发计划劣化 | 884 |
| gaussdb-rewrite-rule-partialpush-13 | plan-suboptimal | 不下推函数(如 group_concat) 导致 RemoteQuery 拉全表回 CN | 932 |
| gaussdb-query-slow-windowagg-sort-on-cn-01 | query-slow | WindowAgg 与 Sort 全在 CN 端执行，占总执行时间 95% 以上 | 979 |
| gaussdb-statement-not-shippable-cn-bottleneck-01 | query-slow | 含不可下推函数/语法的查询导致 CN 成为性能瓶颈 | 1024 |
| gaussdb-query-slow-subplan-correlated-subquery-01 | query-slow | 执行计划中存在 SubPlan+Broadcast，相关子查询性能差 | 1084 |
