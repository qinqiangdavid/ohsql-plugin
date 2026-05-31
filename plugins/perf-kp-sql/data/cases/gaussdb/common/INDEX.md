# Cases Index

> 生成时间: 2026-05-31T04:10:00.008Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 96 cases
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
| gaussdb-plan-suboptimal-sql-x01 | plan-suboptimal | GaussDB迁移慢SQL执行计划算子特征筛查 | 386 |
| gaussdb-cpu-high-cpu-x02 | cpu-high | GaussDB高并发压测场景CPU使用率100%诊断 | 453 |
| gaussdb-plan-suboptimal-sql-x03 | plan-suboptimal | GaussDB SQL执行疑似hang因未Analyze导致Nestloop计划不准 | 523 |
| gaussdb-other-x05 | other | GaussDB回放模式参数配置不合理导致回放慢 | 584 |
| gaussdb-other-ddl-x07 | other | GaussDB DDL等特定日志类型导致回放慢 | 630 |
| gaussdb-disk-io-saturation-x08 | disk-io-saturation | GaussDB备机IO时延高或缓存命中率低导致回放慢 | 691 |
| gaussdb-data-skew-x09 | data-skew | GaussDB并行回放业务数据倾斜导致回放慢 | 752 |
| gaussdb-other-key-x10 | other | GaussDB高并发插入相同key值导致global索引空间膨胀 | 804 |
| gaussdb-lock-contention-sql-x11 | lock-contention | GaussDB大数据分批入库SQL执行超时等待log file switch事件 | 856 |
| gaussdb-disk-io-saturation-bm25-x13 | disk-io-saturation | GaussDB BM25索引创建性能瓶颈（磁盘IO过高） | 899 |
| gaussdb-lock-contention-x14 | lock-contention | GaussDB锁冲突导致响应慢 | 942 |
| gaussdb-memory-pressure-x16 | memory-pressure | GaussDB动态内存使用率高应急处理 | 1003 |
| gaussdb-plan-suboptimal-x18 | plan-suboptimal | GaussDB索引失效导致查询变慢 | 1061 |
| gaussdb-other-tpcc-x20 | other | GaussDB TPCC性能波动大及CPU利用率低诊断 | 1104 |
| gaussdb-other-tpcc-x21 | other | GaussDB TPCC备机日志预扩阻塞导致性能波动 | 1150 |
| gaussdb-other-astore-x22 | other | GaussDB astore表索引查询n_tuples_fetched统计值异常翻倍 | 1196 |
| gaussdb-memory-pressure-other-x23 | memory-pressure | 大量子事务导致other内存上涨 | 1248 |
| gaussdb-query-slow-autosave-x24 | query-slow | GaussDB开启autosave语句级回滚性能劣化诊断与优化 | 1291 |
| gaussdb-cpu-high-cpu-x25 | cpu-high | 索引缺少过滤性好的字段导致CPU冲高 | 1352 |
| gaussdb-cpu-high-index-x26 | cpu-high | 不支持index skip scan导致扫描所有页面CPU冲高 | 1404 |
| gaussdb-lock-contention-ddl-x27 | lock-contention | 业务高峰期大量DDL导致LockMgrLock热点引发线程池打满 | 1456 |
| gaussdb-plan-suboptimal-exists-x29 | plan-suboptimal | EXISTS子连接包含union导致无法提升引发慢SQL | 1499 |
| gaussdb-plan-suboptimal-not-x30 | plan-suboptimal | Not In子连接产生null值过滤导致无法走索引 | 1542 |
| gaussdb-plan-suboptimal-x31 | plan-suboptimal | OR表达式不支持索引导致全表扫描 | 1585 |
| gaussdb-plan-suboptimal-seqscan-x33 | plan-suboptimal | SeqScan+Stream算子效率低下未利用SMP并行 | 1628 |
| gaussdb-disk-io-saturation-tps-x34 | disk-io-saturation | GaussDB长稳测试TPS抖动性能修复 | 1680 |
| gaussdb-cpu-high-cpu-x36 | cpu-high | 核心系统 CPU 打满问题分析 | 1768 |
| gaussdb-query-slow-dataarts-x37 | query-slow | Dataarts 业务中的ustore表死元组堆积导致查询变慢 | 1853 |
| gaussdb-other-tpcc-x38 | other | GaussDB某版本tpcc性能调优-绑核参数 | 1923 |
| gaussdb-other-rpo-x39 | other | GaussDB异地容灾集群RPO达8000+秒 | 1969 |
| gaussdb-other-rto-x40 | other | GaussDB压测过程中备机RTO持续增高 | 2030 |
| gaussdb-query-slow-sql-x42 | query-slow | GaussDB统计信息缺失与并发更新同一行导致主键更新慢SQL | 2115 |
| gaussdb-disk-io-saturation-wal-x43 | disk-io-saturation | GaussDB IO高及WAL日志生成量异常诊断 | 2182 |
| gaussdb-other-autovacuum-x44 | other | GaussDB AutoVacuum清理Ustore分区表缓慢诊断 | 2252 |
| gaussdb-other-ustore-x45 | other | Ustore开启闪回特性下集中删除后SeqScan触发大事务查杀 | 2313 |
| gaussdb-plan-suboptimal-x47 | plan-suboptimal | 打开文件句柄过多导致核心业务压测出现抖动 | 2389 |
| gaussdb-cpu-high-jdbc-x48 | cpu-high | GaussDB应用JDBC建连超时及客户端CPU冲高诊断 | 2465 |
| gaussdb-other-x49 | other | GaussDB容器化环境下lo网卡丢包告警 | 2532 |
| gaussdb-other-rto-x50 | other | GaussDB 8C小规格备机并行回放与读冲突导致业务超时及极致RTO配置验证 | 2602 |
| gaussdb-other-ustore-x51 | other | GaussDB Ustore单事务内多次更新Toast字段导致表膨胀 | 2654 |
| gaussdb-lock-contention-commit-x52 | lock-contention | GaussDB事务Commit存在波动诊断 | 2715 |
| gaussdb-query-slow-x53 | query-slow | GaussDB千万笔交易偶现几十笔毛刺诊断 | 2767 |
| gaussdb-lock-contention-x54 | lock-contention | GaussDB轻量级锁防饿死机制误判导致性能抖动 | 2828 |
| gaussdb-plan-suboptimal-x57 | plan-suboptimal | 子查询内存在无用的窗口函数导致过滤条件无法触发索引扫描 | 2925 |
| gaussdb-plan-suboptimal-union-x58 | plan-suboptimal | union all下cte无法自动内联导致恒为false的分支未被提前过滤 | 2977 |
| gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01 | plan-suboptimal | 目标列相关子查询无法提升，逐行触发子查询导致性能低下，intargetlist 参数转为 JOIN 提升性能 | 3029 |
| gaussdb-plan-suboptimal-missing-analyze-dist-v8-01 | plan-suboptimal | 未收集统计信息导致 GaussDB 分布式查询性能差（v8） | 3077 |
| gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01 | plan-suboptimal | 多表 JOIN 中间结果估算不准，NestLoop 耗时 12s，改用 unlogged table + 禁 hashjoin 降至 3s | 3122 |
| gaussdb-query-slow-missing-analyze-01 | plan-suboptimal | 未收集统计信息（analyze）导致查询性能差、执行计划选错 | 3179 |
| gaussdb-query-slow-complex-join-intermediate-rows-01 | query-slow | 多表 join 中间结果估算不准导致 Hash Join 建大 Hash Table、查询慢 | 3233 |
| gaussdb-plan-suboptimal-seqscan-vs-indexscan-01 | plan-suboptimal | SeqScan 扫描过滤大量数据，点查场景应走 IndexScan | 3281 |
| gaussdb-plan-suboptimal-nestloop-large-outer-01 | plan-suboptimal | 两表 JOIN 外表行数大时 NestLoop 耗时 5s，关闭 NestLoop+MergeJoin 改 HashJoin 降至 86ms | 3326 |
| gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01 | plan-suboptimal | 大结果集 Agg 走 Sort+GroupAgg 耗时长，关闭 Sort 改 HashAgg 性能提升 | 3383 |
| gaussdb-query-slow-correlated-subquery-target-list-01 | query-slow | 目标列相关子查询未提升导致每行触发子查询、查询慢 | 3431 |
| gaussdb-savepoint-in-loop-resource-leak-01 | memory-pressure | 循环内重复创建同名 SAVEPOINT 引发资源累积 | 3479 |
| gaussdb-seqscan-without-index-slow-01 | query-slow | 等值过滤无索引导致全表 Seq Scan 慢 | 3533 |
| gaussdb-query-slow-seqscan-index-missing-01 | query-slow | 点查/范围扫描使用SeqScan全表扫描导致查询慢 | 3586 |
| gaussdb-query-slow-nestloop-hashjoin-02 | query-slow | 两表Join选择NestLoop导致查询执行慢（大数据量场景） | 3631 |
| gaussdb-query-slow-groupagg-sort-03 | query-slow | 大结果集聚合选择Sort+GroupAgg导致性能差 | 3679 |
| gaussdb-query-slow-seqscan-no-index-01 | query-slow | 点查或范围扫描选择SeqScan全表扫描导致查询慢 | 3727 |
| gaussdb-query-slow-nestloop-large-rowset-01 | query-slow | 两表Join选择NestLoop但实际行数大导致查询慢 | 3772 |
| gaussdb-query-slow-sort-groupagg-large-result-01 | query-slow | 大结果集Agg选择Sort+GroupAgg导致查询慢 | 3820 |
| gaussdb-rewrite-lazyagg-double-aggregate-slow-01 | query-slow | 子查询与外层有相同GROUP BY时双层聚集运算效率低下 | 3868 |
| gaussdb-partition-maxmin-fullscan-01 | query-slow | 分区表 Max/Min 全分区扫描 + Sort 慢 | 3916 |
| gaussdb-alert-thresholds-01 | other | GaussDB 指标告警配置建议 (CES 阈值基线) | 3970 |
| gaussdb-plan-suboptimal-anti-join-row-estimate-01 | plan-suboptimal | Anti Join 自连接行数估算不准导致查询性能下降 | 4141 |
| gaussdb-plan-suboptimal-correlated-filter-selectivity-01 | plan-suboptimal | 多列强相关过滤条件选择率用乘积估算导致行数不准 | 4189 |
| gaussdb-cpu-saturated-by-slowsql-06 | cpu-high | DB 节点 CPU 持续满载,gsql 进程占用率高 | 4237 |
| gaussdb-groupagg-sort-vs-hashagg-08 | plan-suboptimal | GROUP BY 计划走 GroupAgg+Sort 而非 HashAgg 导致性能差 | 4290 |
| gaussdb-query-slow-join-null-values-01 | query-slow | JOIN 列存在大量 NULL 值导致顺序扫描耗时过长 | 4338 |
| gaussdb-missing-index-multi-join-05 | query-slow | 多表 JOIN 中缺少连接列索引导致点查询走 seqscan | 4383 |
| gaussdb-query-slow-nestloop-any-clause-01 | query-slow | any-clause 导致不等值 Join 走 NestLoop，大数据量超 1 小时未返回 | 4428 |
| gaussdb-plan-suboptimal-seqscan-no-index-01 | query-slow | 全表顺序扫描过滤大量数据导致查询慢 | 4473 |
| gaussdb-plan-suboptimal-nestloop-large-table-01 | query-slow | 大表 Join 使用 NestLoop 导致查询极慢 | 4518 |
| gaussdb-plan-suboptimal-groupagg-sort-01 | query-slow | GROUP BY 生成 Sort+GroupAgg 导致查询慢 | 4575 |
| gaussdb-overall-slow-io-await-high-01 | disk-io-saturation | I/O 满或 await 高导致整体性能慢 | 4623 |
| gaussdb-overall-slow-cpu-high-01 | cpu-high | gaussdb 进程 CPU 占用高导致整体性能慢 | 4698 |
| gaussdb-overall-slow-config-shared-buffers-01 | query-slow | 数据库配置不优 (shared_buffers / work_mem / thread_pool_attr) 导致整体性能慢 | 4761 |
| gaussdb-package-variable-session-memory-01 | memory-pressure | PACKAGE变量大量缓存可能占用大量内存 | 4827 |
| gaussdb-query-slow-partition-pruning-disabled-function-01 | query-slow | 分区表过滤条件含非常量表达式，分区剪枝失效，全表扫描耗时 135s | 4872 |
| gaussdb-procedure-exception-frequent-perf-degrade-01 | query-slow | 存储过程频繁捕获和处理异常导致性能下降 | 4926 |
| gaussdb-procedure-security-definer-permission-01 | other | 存储过程权限模式选择不当导致越权或被拒访问 | 4971 |
| gaussdb-query-slow-scan-no-local-cluster-key-01 | query-slow | 表 Scan 为性能瓶颈，过滤列无局部聚簇键 | 5025 |
| gaussdb-group-by-sort-perf-work-mem-01 | query-slow | GROUP BY 产生 Sort 算子时通过增大 work_mem 生成 HashAgg 提升性能 | 5079 |
| gaussdb-not-in-to-not-exists-rewrite-01 | query-slow | NOT IN 转换为 NOT EXISTS 通过 Hash Anti Join 提升查询效率 | 5127 |
| gaussdb-stale-stats-hint-fix-09 | plan-suboptimal | 高频数据变化表统计信息滞后导致计划选择不优 | 5172 |
| gaussdb-replica-lag-redo-workers-01 | replica-lag | GaussDB业务压力大时备DN回放速度跟不上主DN，日志累积影响RTO | 5217 |
| gaussdb-rewrite-intargetlist-subplan-slow-01 | query-slow | 目标列相关子查询无法提升导致每行触发SubPlan执行，查询性能低下 | 5280 |
| gaussdb-rewrite-uniquecheck-subquery-join-01 | query-slow | 无agg子查询无法自动提升导致子链接重复执行 | 5328 |
