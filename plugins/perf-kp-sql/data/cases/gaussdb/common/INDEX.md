# Cases Index

> 生成时间: 2026-05-29T07:49:27.621Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 51 cases
> 配套: gaussdb/common/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| gaussdb-cpu-high-topsql-01 | cpu-high | GaussDB CPU使用率高——通过dbe_perf.statement定位高CPU SQL | 3 |
| gaussdb-cpu-high-connection-timezone-01 | cpu-high | GaussDB CPU SYS高——高并发短连接重复加载时区文件 | 63 |
| gaussdb-memory-shared-buffer-miss-01 | memory-pressure | GaussDB内存不足——shared_buffers过小导致buffer命中率低 | 110 |
| gaussdb-memory-work-mem-spill-01 | memory-pressure | GaussDB内存不足——work_mem过小导致Hash/Sort算子落盘 | 158 |
| gaussdb-disk-io-high-statement-view-01 | disk-io-saturation | GaussDB整体IO高——通过性能视图定位高物理读SQL | 206 |
| gaussdb-memory-pressure-node-detail-01 | memory-pressure | GaussDB内存高——通过dbe_perf.memory_node_detail定位内存占用点 | 269 |
| gaussdb-perf-jitter-asp-analysis-01 | other | GaussDB性能抖动——通过ASP/WDR定位抖动根因 | 332 |
| gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01 | plan-suboptimal | 目标列相关子查询无法提升，逐行触发子查询导致性能低下，intargetlist 参数转为 JOIN 提升性能 | 386 |
| gaussdb-plan-suboptimal-missing-analyze-dist-v8-01 | plan-suboptimal | 未收集统计信息导致 GaussDB 分布式查询性能差（v8） | 434 |
| gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01 | plan-suboptimal | 多表 JOIN 中间结果估算不准，NestLoop 耗时 12s，改用 unlogged table + 禁 hashjoin 降至 3s | 479 |
| gaussdb-query-slow-missing-analyze-01 | plan-suboptimal | 未收集统计信息（analyze）导致查询性能差、执行计划选错 | 536 |
| gaussdb-query-slow-complex-join-intermediate-rows-01 | query-slow | 多表 join 中间结果估算不准导致 Hash Join 建大 Hash Table、查询慢 | 590 |
| gaussdb-plan-suboptimal-seqscan-vs-indexscan-01 | plan-suboptimal | SeqScan 扫描过滤大量数据，点查场景应走 IndexScan | 638 |
| gaussdb-plan-suboptimal-nestloop-large-outer-01 | plan-suboptimal | 两表 JOIN 外表行数大时 NestLoop 耗时 5s，关闭 NestLoop+MergeJoin 改 HashJoin 降至 86ms | 683 |
| gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01 | plan-suboptimal | 大结果集 Agg 走 Sort+GroupAgg 耗时长，关闭 Sort 改 HashAgg 性能提升 | 740 |
| gaussdb-query-slow-correlated-subquery-target-list-01 | query-slow | 目标列相关子查询未提升导致每行触发子查询、查询慢 | 788 |
| gaussdb-savepoint-in-loop-resource-leak-01 | memory-pressure | 循环内重复创建同名 SAVEPOINT 引发资源累积 | 836 |
| gaussdb-seqscan-without-index-slow-01 | query-slow | 等值过滤无索引导致全表 Seq Scan 慢 | 890 |
| gaussdb-query-slow-seqscan-index-missing-01 | query-slow | 点查/范围扫描使用SeqScan全表扫描导致查询慢 | 943 |
| gaussdb-query-slow-nestloop-hashjoin-02 | query-slow | 两表Join选择NestLoop导致查询执行慢（大数据量场景） | 988 |
| gaussdb-query-slow-groupagg-sort-03 | query-slow | 大结果集聚合选择Sort+GroupAgg导致性能差 | 1036 |
| gaussdb-query-slow-seqscan-no-index-01 | query-slow | 点查或范围扫描选择SeqScan全表扫描导致查询慢 | 1084 |
| gaussdb-query-slow-nestloop-large-rowset-01 | query-slow | 两表Join选择NestLoop但实际行数大导致查询慢 | 1129 |
| gaussdb-query-slow-sort-groupagg-large-result-01 | query-slow | 大结果集Agg选择Sort+GroupAgg导致查询慢 | 1177 |
| gaussdb-rewrite-lazyagg-double-aggregate-slow-01 | query-slow | 子查询与外层有相同GROUP BY时双层聚集运算效率低下 | 1225 |
| gaussdb-partition-maxmin-fullscan-01 | query-slow | 分区表 Max/Min 全分区扫描 + Sort 慢 | 1273 |
| gaussdb-alert-thresholds-01 | other | GaussDB 指标告警配置建议 (CES 阈值基线) | 1327 |
| gaussdb-plan-suboptimal-anti-join-row-estimate-01 | plan-suboptimal | Anti Join 自连接行数估算不准导致查询性能下降 | 1498 |
| gaussdb-plan-suboptimal-correlated-filter-selectivity-01 | plan-suboptimal | 多列强相关过滤条件选择率用乘积估算导致行数不准 | 1546 |
| gaussdb-cpu-saturated-by-slowsql-06 | cpu-high | DB 节点 CPU 持续满载,gsql 进程占用率高 | 1594 |
| gaussdb-groupagg-sort-vs-hashagg-08 | plan-suboptimal | GROUP BY 计划走 GroupAgg+Sort 而非 HashAgg 导致性能差 | 1647 |
| gaussdb-query-slow-join-null-values-01 | query-slow | JOIN 列存在大量 NULL 值导致顺序扫描耗时过长 | 1695 |
| gaussdb-missing-index-multi-join-05 | query-slow | 多表 JOIN 中缺少连接列索引导致点查询走 seqscan | 1740 |
| gaussdb-query-slow-nestloop-any-clause-01 | query-slow | any-clause 导致不等值 Join 走 NestLoop，大数据量超 1 小时未返回 | 1785 |
| gaussdb-plan-suboptimal-seqscan-no-index-01 | query-slow | 全表顺序扫描过滤大量数据导致查询慢 | 1830 |
| gaussdb-plan-suboptimal-nestloop-large-table-01 | query-slow | 大表 Join 使用 NestLoop 导致查询极慢 | 1875 |
| gaussdb-plan-suboptimal-groupagg-sort-01 | query-slow | GROUP BY 生成 Sort+GroupAgg 导致查询慢 | 1932 |
| gaussdb-overall-slow-io-await-high-01 | disk-io-saturation | I/O 满或 await 高导致整体性能慢 | 1980 |
| gaussdb-overall-slow-cpu-high-01 | cpu-high | gaussdb 进程 CPU 占用高导致整体性能慢 | 2055 |
| gaussdb-overall-slow-config-shared-buffers-01 | query-slow | 数据库配置不优 (shared_buffers / work_mem / thread_pool_attr) 导致整体性能慢 | 2118 |
| gaussdb-package-variable-session-memory-01 | memory-pressure | PACKAGE变量大量缓存可能占用大量内存 | 2184 |
| gaussdb-query-slow-partition-pruning-disabled-function-01 | query-slow | 分区表过滤条件含非常量表达式，分区剪枝失效，全表扫描耗时 135s | 2229 |
| gaussdb-procedure-exception-frequent-perf-degrade-01 | query-slow | 存储过程频繁捕获和处理异常导致性能下降 | 2283 |
| gaussdb-procedure-security-definer-permission-01 | other | 存储过程权限模式选择不当导致越权或被拒访问 | 2328 |
| gaussdb-query-slow-scan-no-local-cluster-key-01 | query-slow | 表 Scan 为性能瓶颈，过滤列无局部聚簇键 | 2382 |
| gaussdb-group-by-sort-perf-work-mem-01 | query-slow | GROUP BY 产生 Sort 算子时通过增大 work_mem 生成 HashAgg 提升性能 | 2436 |
| gaussdb-not-in-to-not-exists-rewrite-01 | query-slow | NOT IN 转换为 NOT EXISTS 通过 Hash Anti Join 提升查询效率 | 2484 |
| gaussdb-stale-stats-hint-fix-09 | plan-suboptimal | 高频数据变化表统计信息滞后导致计划选择不优 | 2529 |
| gaussdb-replica-lag-redo-workers-01 | replica-lag | GaussDB业务压力大时备DN回放速度跟不上主DN，日志累积影响RTO | 2574 |
| gaussdb-rewrite-intargetlist-subplan-slow-01 | query-slow | 目标列相关子查询无法提升导致每行触发SubPlan执行，查询性能低下 | 2637 |
| gaussdb-rewrite-uniquecheck-subquery-join-01 | query-slow | 无agg子查询无法自动提升导致子链接重复执行 | 2685 |
