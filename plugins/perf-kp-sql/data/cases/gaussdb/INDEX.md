# Cases Index

> 生成时间: 2026-05-21T02:55:21.894Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 299 cases
> 配套: cases/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| gaussdb-cpu-high-topsql-01 | cpu-high | GaussDB CPU使用率高——通过dbe_perf.statement定位高CPU SQL | 1309 |
| gaussdb-cpu-high-connection-timezone-01 | cpu-high | GaussDB CPU SYS高——高并发短连接重复加载时区文件 | 1368 |
| gaussdb-memory-shared-buffer-miss-01 | memory-pressure | GaussDB内存不足——shared_buffers过小导致buffer命中率低 | 1414 |
| gaussdb-memory-work-mem-spill-01 | memory-pressure | GaussDB内存不足——work_mem过小导致Hash/Sort算子落盘 | 1461 |
| gaussdb-cpu-high-statement-view-01 | cpu-high | GaussDB整体CPU高——通过性能视图定位高CPU SQL | 1508 |
| gaussdb-disk-io-high-statement-view-01 | disk-io-saturation | GaussDB整体IO高——通过性能视图定位高物理读SQL | 1570 |
| gaussdb-memory-pressure-node-detail-01 | memory-pressure | GaussDB内存高——通过dbe_perf.memory_node_detail定位内存占用点 | 1632 |
| gaussdb-perf-jitter-asp-analysis-01 | other | GaussDB性能抖动——通过ASP/WDR定位抖动根因 | 1694 |
| gaussdb-dist-volatile-func-not-pushed-slow-01 | cpu-high | 自定义函数VOLATILE属性导致分布式语句不下推 | 1747 |
| gaussdb-plan-suboptimal-rewrite-rule-partialpush-01 | plan-suboptimal | 自定义函数无法下推导致 CN 上全量 HASH JOIN，partialpush 参数可提升性能 | 1800 |
| gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01 | plan-suboptimal | 目标列相关子查询无法提升，逐行触发子查询导致性能低下，intargetlist 参数转为 JOIN 提升性能 | 1847 |
| gaussdb-dist-v3-volatile-func-not-pushed-slow-01 | cpu-high | 分布式v3：自定义函数VOLATILE属性导致语句不下推、CN性能瓶颈 | 1894 |
| gaussdb-plan-suboptimal-missing-analyze-dist-v8-01 | plan-suboptimal | 未收集统计信息导致 GaussDB 分布式查询性能差（v8） | 1947 |
| gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01 | plan-suboptimal | 多表 JOIN 中间结果估算不准，NestLoop 耗时 12s，改用 unlogged table + 禁 hashjoin 降至 3s | 1991 |
| gaussdb-query-slow-missing-analyze-01 | plan-suboptimal | 未收集统计信息（analyze）导致查询性能差、执行计划选错 | 2047 |
| gaussdb-query-slow-complex-join-intermediate-rows-01 | query-slow | 多表 join 中间结果估算不准导致 Hash Join 建大 Hash Table、查询慢 | 2100 |
| gaussdb-plan-suboptimal-seqscan-vs-indexscan-01 | plan-suboptimal | SeqScan 扫描过滤大量数据，点查场景应走 IndexScan | 2147 |
| gaussdb-plan-suboptimal-nestloop-large-outer-01 | plan-suboptimal | 两表 JOIN 外表行数大时 NestLoop 耗时 5s，关闭 NestLoop+MergeJoin 改 HashJoin 降至 86ms | 2191 |
| gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01 | plan-suboptimal | 大结果集 Agg 走 Sort+GroupAgg 耗时长，关闭 Sort 改 HashAgg 性能提升 | 2247 |
| gaussdb-dws-plan-suboptimal-planhint-01 | plan-suboptimal | TPC-DS Q24查询执行计划不优——使用Plan Hint调优 | 2294 |
| gaussdb-query-slow-no-partial-pushdown-01 | query-slow | 含不可下推函数的查询未使用 partialpush 导致大量数据在 CN 上做 Hash Join、查询慢 | 2338 |
| gaussdb-query-slow-correlated-subquery-target-list-01 | query-slow | 目标列相关子查询未提升导致每行触发子查询、查询慢 | 2385 |
| gaussdb-dist-disk-full-storage-skew-01 | disk-space-pressure | 磁盘满后快速定位存储倾斜表 | 2432 |
| gaussdb-dist-routine-skew-inspection-01 | data-skew | 常规数据倾斜巡检：表个数少于1W时使用PGXC_GET_TABLE_SKEWNESS视图 | 2476 |
| gaussdb-savepoint-in-loop-resource-leak-01 | memory-pressure | 循环内重复创建同名 SAVEPOINT 引发资源累积 | 2529 |
| gaussdb-seqscan-without-index-slow-01 | query-slow | 等值过滤无索引导致全表 Seq Scan 慢 | 2582 |
| gaussdb-query-slow-missing-statistics-explain-verbose-01 | plan-suboptimal | 未收集统计信息导致查询性能差（集中式v3） | 2634 |
| gaussdb-query-slow-seqscan-index-missing-01 | query-slow | 点查/范围扫描使用SeqScan全表扫描导致查询慢 | 2687 |
| gaussdb-query-slow-nestloop-hashjoin-02 | query-slow | 两表Join选择NestLoop导致查询执行慢（大数据量场景） | 2731 |
| gaussdb-query-slow-groupagg-sort-03 | query-slow | 大结果集聚合选择Sort+GroupAgg导致性能差 | 2778 |
| gaussdb-query-slow-seqscan-no-index-01 | query-slow | 点查或范围扫描选择SeqScan全表扫描导致查询慢 | 2825 |
| gaussdb-query-slow-nestloop-large-rowset-01 | query-slow | 两表Join选择NestLoop但实际行数大导致查询慢 | 2869 |
| gaussdb-query-slow-sort-groupagg-large-result-01 | query-slow | 大结果集Agg选择Sort+GroupAgg导致查询慢 | 2916 |
| gaussdb-rewrite-lazyagg-double-aggregate-slow-01 | query-slow | 子查询与外层有相同GROUP BY时双层聚集运算效率低下 | 2963 |
| gaussdb-rewrite-magicset-correlated-subquery-slow-01 | query-slow | 带聚集算子的相关子查询重复扫描导致性能差 | 3010 |
| gaussdb-rewrite-v8-intargetlist-subplan-slow-01 | query-slow | 集中式v8：目标列相关子查询无法提升（intargetlist） | 3057 |
| gaussdb-partition-maxmin-fullscan-01 | query-slow | 分区表 Max/Min 全分区扫描 + Sort 慢 | 3104 |
| gaussdb-alert-thresholds-01 | other | GaussDB 指标告警配置建议 (CES 阈值基线) | 3157 |
| gaussdb-query-slow-agg-plan-mode-01 | query-slow | 优化器代价估算偏差导致 Agg 计算方式选择不优 | 3327 |
| gaussdb-copy-constraint-violation-tolerance-01 | query-slow | COPY 导入数据存在约束冲突时开启 Level2 容错降低性能 | 3374 |
| gaussdb-plan-suboptimal-anti-join-row-estimate-01 | plan-suboptimal | Anti Join 自连接行数估算不准导致查询性能下降 | 3427 |
| gaussdb-plan-suboptimal-correlated-filter-selectivity-01 | plan-suboptimal | 多列强相关过滤条件选择率用乘积估算导致行数不准 | 3474 |
| gaussdb-cpu-saturated-by-slowsql-06 | cpu-high | DB 节点 CPU 持续满载,gsql 进程占用率高 | 3521 |
| gaussdb-data-skew-storage-distribution-01 | data-skew | 分布列选择不合理导致存储倾斜影响查询性能 | 3573 |
| gaussdb-data-skew-compute-redistribute-01 | data-skew | 重分布列存在倾斜值导致计算倾斜，部分 DN 处理数据量远大于其他节点 | 3626 |
| gaussdb-disk-space-pressure-storage-skew-locate-01 | disk-space-pressure | 磁盘满后快速定位存储倾斜的表 | 3679 |
| gaussdb-distribution-key-skew-xc-node-id-25 | data-skew | 分布键选择不当致 DN 间数据量差 >10%,木桶效应拖慢整体 | 3732 |
| gaussdb-dws-distkey-choice-01 | plan-suboptimal | 选择合适的分布列避免不必要 Streaming | 3781 |
| gaussdb-groupagg-sort-vs-hashagg-08 | plan-suboptimal | GROUP BY 计划走 GroupAgg+Sort 而非 HashAgg 导致性能差 | 3834 |
| gaussdb-data-skew-hashjoin-dn-compute-skew-01 | data-skew | 表数据分布倾斜导致 HashJoin DN 计算时间严重偏斜 | 3881 |
| gaussdb-query-slow-join-null-values-01 | query-slow | JOIN 列存在大量 NULL 值导致顺序扫描耗时过长 | 3943 |
| gaussdb-missing-index-multi-join-05 | query-slow | 多表 JOIN 中缺少连接列索引导致点查询走 seqscan | 3987 |
| gaussdb-query-slow-nestloop-any-clause-01 | query-slow | any-clause 导致不等值 Join 走 NestLoop，大数据量超 1 小时未返回 | 4031 |
| gaussdb-plan-suboptimal-seqscan-no-index-01 | query-slow | 全表顺序扫描过滤大量数据导致查询慢 | 4075 |
| gaussdb-plan-suboptimal-nestloop-large-table-01 | query-slow | 大表 Join 使用 NestLoop 导致查询极慢 | 4119 |
| gaussdb-plan-suboptimal-groupagg-sort-01 | query-slow | GROUP BY 生成 Sort+GroupAgg 导致查询慢 | 4175 |
| gaussdb-overall-slow-io-await-high-01 | disk-io-saturation | I/O 满或 await 高导致整体性能慢 | 4222 |
| gaussdb-overall-slow-cpu-high-01 | cpu-high | gaussdb 进程 CPU 占用高导致整体性能慢 | 4296 |
| gaussdb-overall-slow-config-shared-buffers-01 | query-slow | 数据库配置不优 (shared_buffers / work_mem / thread_pool_attr) 导致整体性能慢 | 4358 |
| gaussdb-package-variable-session-memory-01 | memory-pressure | PACKAGE变量大量缓存可能占用大量内存 | 4423 |
| gaussdb-query-slow-partition-pruning-disabled-function-01 | query-slow | 分区表过滤条件含非常量表达式，分区剪枝失效，全表扫描耗时 135s | 4467 |
| gaussdb-plan-suboptimal-row-estimate-broadcast-01 | query-slow | 多列关联估算行数严重低估导致广播代价高 | 4520 |
| gaussdb-plan-suboptimal-statistics-change-plan-regression-01 | plan-suboptimal | 统计信息变更导致 Join 流方式从 Broadcast 切换为 Redistribute 引发计划劣化 | 4564 |
| gaussdb-procedure-exception-frequent-perf-degrade-01 | query-slow | 存储过程频繁捕获和处理异常导致性能下降 | 4611 |
| gaussdb-procedure-security-definer-permission-01 | other | 存储过程权限模式选择不当导致越权或被拒访问 | 4655 |
| gaussdb-rewrite-rule-partialpush-13 | plan-suboptimal | 不下推函数(如 group_concat) 导致 RemoteQuery 拉全表回 CN | 4708 |
| gaussdb-query-slow-scan-no-local-cluster-key-01 | query-slow | 表 Scan 为性能瓶颈，过滤列无局部聚簇键 | 4754 |
| gaussdb-query-slow-windowagg-sort-on-cn-01 | query-slow | WindowAgg 与 Sort 全在 CN 端执行，占总执行时间 95% 以上 | 4807 |
| gaussdb-group-by-sort-perf-work-mem-01 | query-slow | GROUP BY 产生 Sort 算子时通过增大 work_mem 生成 HashAgg 提升性能 | 4851 |
| gaussdb-not-in-to-not-exists-rewrite-01 | query-slow | NOT IN 转换为 NOT EXISTS 通过 Hash Anti Join 提升查询效率 | 4898 |
| gaussdb-stale-stats-hint-fix-09 | plan-suboptimal | 高频数据变化表统计信息滞后导致计划选择不优 | 4942 |
| gaussdb-statement-not-shippable-cn-bottleneck-01 | query-slow | 含不可下推函数/语法的查询导致 CN 成为性能瓶颈 | 4986 |
| gaussdb-query-slow-subplan-correlated-subquery-01 | query-slow | 执行计划中存在 SubPlan+Broadcast，相关子查询性能差 | 5045 |
| gaussdb-replica-lag-redo-workers-01 | replica-lag | GaussDB业务压力大时备DN回放速度跟不上主DN，日志累积影响RTO | 5089 |
| gaussdb-plan-suboptimal-missing-analyze-01 | plan-suboptimal | 未收集统计信息导致查询性能差（集中式GaussDB） | 5151 |
| gaussdb-rewrite-intargetlist-subplan-slow-01 | query-slow | 目标列相关子查询无法提升导致每行触发SubPlan执行，查询性能低下 | 5204 |
| gaussdb-rewrite-uniquecheck-subquery-join-01 | query-slow | 无agg子查询无法自动提升导致子链接重复执行 | 5251 |
