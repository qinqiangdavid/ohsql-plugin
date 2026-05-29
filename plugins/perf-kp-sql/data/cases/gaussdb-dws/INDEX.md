# Cases Index

> 生成时间: 2026-05-29T09:18:14.076Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 120 cases
> 配套: gaussdb-dws/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| gaussdb-dws-plan-suboptimal-broadcast-skew-redistribute-01 | plan-suboptimal | DWS统计信息不准导致小表被误判为大表走Broadcast，应改用Redistribute | 3 |
| gaussdb-dws-plan-suboptimal-nestloop-seqscan-cost-02 | plan-suboptimal | DWS索引扫描关闭后Seq Scan触发NestLoop但Hash Join启动代价更高 | 48 |
| gaussdb-dws-plan-suboptimal-nestloop-perf-jump-hint-01 | plan-suboptimal | 实时场景执行时间跳变至 3600s 超时，NestLoop 选择错误，通过 enable_index_nestloop hint 修复 | 93 |
| gaussdb-dws-query-slow-topsql-queue-wait-01 | query-slow | SQL作业block_time大但duration无明显变化——受其他作业排队影响 | 141 |
| gaussdb-dws-query-slow-data-skew-dn-time-01 | data-skew | DN执行时间倾斜导致SQL作业整体执行慢 | 195 |
| gaussdb-dws-query-slow-dn-io-contention-01 | disk-io-saturation | DN的IO指标偏低反映作业受IO抢占影响 | 240 |
| gaussdb-dws-query-slow-windowagg-single-dn-01 | query-slow | row_number() over / count() over 窗口函数集中在单DN运行导致查询慢 | 291 |
| gaussdb-dws-data-skew-row-number-partition-null-01 | data-skew | row_number() PARTITION BY 列存在大量 NULL 值导致计算倾斜、SQL 性能慢 | 336 |
| gaussdb-dws-plan-suboptimal-data-skew-01 | data-skew | DWS数据倾斜——DN间数据分布不均导致性能瓶颈 | 390 |
| gaussdb-dws-plan-suboptimal-large-table-broadcast-02 | query-slow | DWS大表Broadcast导致网络传输量大、查询慢 | 435 |
| gaussdb-dws-plan-suboptimal-spill-overflow-03 | memory-pressure | DWS SQL执行落盘量过大或过早落盘导致性能低下 | 480 |
| gaussdb-dws-plan-suboptimal-nestloop-large-table-04 | query-slow | DWS大表等值连接使用NestLoop导致查询慢 | 525 |
| gaussdb-dws-data-skew-query-slow-01 | data-skew | 数据倾斜导致SQL执行不出结果 | 570 |
| gaussdb-dws-statistics-not-collected-plan-poor-01 | plan-suboptimal | 统计信息未收集导致优化器估算偏差、执行计划差 | 642 |
| gaussdb-dws-statement-not-pushed-down-slow-01 | cpu-high | 语句不下推导致CN成为性能瓶颈 | 687 |
| gaussdb-dws-notin-nestloop-slow-01 | query-slow | NOT IN语义导致NestLoop，SQL执行慢 | 741 |
| gaussdb-dws-no-partition-pruning-slow-01 | query-slow | 查询条件未包含分区键导致未分区剪枝、全表扫描 | 786 |
| gaussdb-dws-row-estimate-small-nestloop-slow-01 | query-slow | 行数估算过小导致优化器选择NestLoop，查询卡住 | 831 |
| gaussdb-dws-table-bloat-vacuum-slow-01 | query-slow | 表数据膨胀未清理脏数据导致性能时快时慢 | 894 |
| gaussdb-dws-in-constant-no-join-slow-01 | query-slow | in常量数量过多未转为join导致查询慢 | 984 |
| dws-case-when-redundant-rewrite-01 | query-slow | 大量冗余 CASE WHEN 导致查询性能下降 | 1032 |
| dws-data-bloat-disk-shortage-perf-low-01 | disk-space-pressure | 数据膨胀磁盘空间不足，导致性能降低 | 1083 |
| dws-data-skew-distribute-column-01 | data-skew | Hash 分布列选择不当导致数据倾斜，部分 DN I/O 短板 | 1140 |
| dws-dirty-page-high-vacuum-full-01 | disk-space-pressure | DWS的脏页过高导致磁盘空间膨胀 | 1185 |
| dws-gds-failed-disk-not-released-01 | disk-space-pressure | GDS导入失败后，磁盘占用空间增大 | 1236 |
| dws-jdbc-processresult-slow-01 | query-slow | 在processResult阶段耗时 | 1281 |
| dws-jdbc-modifyjdbccall-slow-01 | query-slow | 在modifyJdbcCall和createParameterizedQuery阶段耗时 | 1344 |
| dws-partition-auto-period-ttl-01 | other | 普通分区表无法自动创建/清理分区导致运维成本高 | 1389 |
| dws-query-efficiency-degraded-01 | query-slow | 分析查询效率异常降低的问题 | 1446 |
| dws-3-0-disk-cache-size-low-hit-01 | disk-io-saturation | 存算分离场景下 Disk Cache 命中率低导致 OBS 直读多 | 1536 |
| dws-3-0-disk-usage-readonly-01 | disk-space-pressure | 存算分离场景下 EVS 磁盘空间占用过高触发集群只读 | 1593 |
| dws-3-0-batching-import-memory-01 | memory-pressure | 存算分离 3.0 表多分区入库攒批内存消耗过大 | 1641 |
| gaussdb-dws-table-bloat-autovacuum-01 | disk-space-pressure | DWS表膨胀：autovacuum未开启或回收不及时导致存储增长和性能下降 | 1695 |
| gaussdb-dws-plan-suboptimal-index-large-result-01 | plan-suboptimal | DWS返回结果集过大时索引失效导致查询走全表扫描 | 1782 |
| gaussdb-dws-plan-suboptimal-index-no-analyze-02 | plan-suboptimal | DWS表未及时ANALYZE导致索引未被使用 | 1827 |
| gaussdb-dws-plan-suboptimal-index-func-03 | plan-suboptimal | DWS过滤条件使用函数或隐式类型转换导致索引失效 | 1872 |
| gaussdb-dws-query-slow-max-active-statements-01 | query-slow | DWS普通用户查询慢——受max_active_statements资源管控排队 | 1917 |
| gaussdb-dws-query-slow-permission-or-filter-02 | query-slow | DWS普通用户查询慢——系统视图权限OR条件逐一判断耗时 | 1965 |
| gaussdb-dws-data-skew-bad-dist-key-01 | data-skew | 分布列选择不当导致数据倾斜，影响查询性能和磁盘空间 | 2010 |
| gaussdb-dws-statement-not-pushed-down-volatile-func-01 | cpu-high | 自定义函数provolatile属性定义错误导致语句不下推，CN成为性能瓶颈 | 2055 |
| gaussdb-dws-with-recursive-not-pushed-slow-01 | query-slow | WITH RECURSIVE查询不下推场景导致性能差 | 2109 |
| gaussdb-dws-plan-suboptimal-missing-analyze-01 | plan-suboptimal | DWS未收集统计信息导致查询执行计划不优（查询性能差） | 2154 |
| gaussdb-dws-query-slow-hstore-delta-bloat-01 | disk-space-pressure | HStore Delta表膨胀导致入库性能劣化 | 2199 |
| gaussdb-dws-query-slow-realtime-numa-codegen-01 | cpu-high | 实时数仓enable_codegen/enable_numa_bind参数未优化导致性能差 | 2256 |
| gaussdb-dws-cpu-high-stream-count-01 | cpu-high | CPU 持续飙高 · TopSQL 识别 Stream 算子数超阈值的语句 | 2322 |
| gaussdb-dws-query-slow-plan-jump-stale-stats-01 | plan-suboptimal | SQL 性能突然下降：统计信息不准导致执行计划跳变 | 2376 |
| gaussdb-dws-query-slow-long-running-operator-01 | query-slow | 作业长时间运行不结束：通过算子级 TopSQL 定位瓶颈算子 | 2421 |
| gaussdb-dws-lock-contention-pgxc-stat-activity-01 | lock-contention | 使用 PGXC_STAT_ACTIVITY 视图定位 DWS 慢 SQL、连接积压与业务阻塞 | 2469 |
| gaussdb-dws-query-slow-flink-connection-timeout-01 | query-slow | Flink 写入 DWS 时报 canceling statement due to statement timeout，connectionTimeOut 默认值过小 | 2543 |
| gaussdb-dws-lock-contention-wait-timeout-01 | lock-contention | 执行SQL时出现LOCK_WAIT_TIMEOUT锁等待超时 | 2591 |
| gaussdb-dws-write-slow-single-insert-01 | disk-io-saturation | 往DWS写数据慢，客户端数据积压：单条INSERT低并发场景吞吐不足 | 2653 |
| gaussdb-dws-query-slow-blocked-or-stale-stats-01 | query-slow | SQL 执行慢：阻塞或统计信息失效导致性能低 | 2698 |
| gaussdb-dws-memory-pressure-oom-query-01 | memory-pressure | DWS 集群内存临时不可用 (memory is temporarily unavailable) | 2743 |
| gaussdb-dws-disk-space-column-table-bloat-01 | disk-space-pressure | 列存表多次UPDATE后出现表膨胀 | 2797 |
| gaussdb-dws-data-skew-hash-dist-01 | data-skew | Hash 分布表数据倾斜导致 SQL 执行慢或无结果 | 2842 |
| gaussdb-dws-query-slow-missing-statistics-01 | plan-suboptimal | 未收集统计信息导致查询性能差 | 2923 |
| gaussdb-dws-query-slow-function-not-shipped-01 | query-slow | DWS自定义函数属性定义错误导致SQL不下推，性能极差 | 2977 |
| gaussdb-dws-nestloop-not-in-query-slow-01 | query-slow | 执行计划中有NestLoop导致SQL语句执行慢 | 3031 |
| gaussdb-dws-query-slow-partition-pruning-miss-01 | query-slow | 查询条件未涉及分区键导致全表扫描，SQL 执行慢 | 3076 |
| gaussdb-dws-plan-nestloop-row-underestimate-01 | plan-suboptimal | 行数估算过小导致优化器选择 NestLoop 执行计划，查询性能下降 | 3121 |
| gaussdb-dws-query-slow-table-bloat-01 | query-slow | 表数据膨胀导致SQL查询慢，用户前台页面数据加载不出 | 3187 |
| gaussdb-dws-query-slow-concurrent-index-01 | query-slow | 大量并发CREATE INDEX操作导致SQL查询慢 | 3286 |
| gaussdb-dws-point-query-cstore-scan-slow-01 | query-slow | 单表点查性能差：列存表用于点查场景导致耗时超预期 | 3340 |
| gaussdb-dws-query-slow-ccn-queue-memory-01 | memory-pressure | 动态负载管理下语句估算内存过大导致 CCN 排队、业务整体缓慢 | 3385 |
| gaussdb-dws-cstore-small-cu-io-slow-01 | disk-io-saturation | 列存小CU过多导致I/O飙升和查询偶发性变慢 | 3430 |
| gaussdb-dws-disk-io-saturation-column-cu-bloat-01 | disk-io-saturation | 列存表小CU膨胀导致I/O高、查询慢 | 3483 |
| gaussdb-dws-disk-io-saturation-dirty-data-bloat-01 | disk-io-saturation | 表脏数据过多导致 I/O 高、查询慢 | 3528 |
| gaussdb-dws-disk-io-saturation-data-skew-01 | data-skew | 表存储倾斜导致单 DN I/O 过高、查询慢 | 3582 |
| gaussdb-dws-query-slow-no-index-or-index-miss-01 | query-slow | 缺少索引或有索引未走导致全表扫描、I/O 高 | 3636 |
| gaussdb-dws-disk-io-saturation-no-partition-pruning-01 | disk-io-saturation | 设计了分区表但查询未走分区剪枝导致I/O极高 | 3681 |
| gaussdb-dws-disk-io-saturation-large-index-import-01 | disk-io-saturation | 大量数据带多个索引导入产生大量XLOG、主备同步慢 | 3726 |
| gaussdb-dws-disk-io-saturation-small-files-iops-01 | disk-io-saturation | 列存多分区导致小文件过多、IOPS 飙高 | 3771 |
| gaussdb-dws-memory-pressure-high-mem-query-01 | memory-pressure | 集群内存负载过高或出现memory is temporary unavailable报错 | 3816 |
| gaussdb-dws-query-slow-vacuum-lock-wait-01 | lock-contention | 存在锁等待导致VACUUM FULL执行慢 | 3861 |
| gaussdb-dws-query-slow-vacuum-pck-sort-01 | disk-io-saturation | 列存表PCK排序下盘导致VACUUM FULL执行慢 | 3924 |
| gaussdb-dws-disk-space-columnar-table-bloat-01 | disk-space-pressure | DWS列存表多次小批量INSERT后表膨胀、磁盘空间持续增长 | 3981 |
| gaussdb-dws-lock-contention-concurrent-update-01 | lock-contention | 并发更新同一行数据导致事务回滚报错 | 4035 |
| dws-distkey-skew-10pct-01 | data-skew | Hash 分布列选择不当导致 DN 数据分布倾斜 | 4080 |
| gaussdb-dws-disk-high-dirty-pages-15 | disk-space-pressure | 集群所有/过半磁盘使用率 ≥ 70% — 脏页率过高 | 4140 |
| gaussdb-dws-agg-plan-tuning-01 | query-slow | 优化器代价估算偏差导致 Agg 计划选择次优，通过 best_agg_plan 参数干预 | 4193 |
| gaussdb-dws-cost-param-anti-join-01 | query-slow | Anti Join 行数估算不准导致执行计划差，通过 cost_param bit0 修正 | 4241 |
| gaussdb-dws-cost-param-filter-selectivity-01 | query-slow | 多个过滤条件列强相关时选择率估算不准，通过 cost_param bit1 改善 | 4289 |
| gaussdb-dws-data-skew-storage-01 | data-skew | 存储层数据倾斜导致部分 DN 成为查询瓶颈 | 4337 |
| gaussdb-dws-data-skew-compute-01 | data-skew | 计算层数据倾斜：重分布列上的倾斜值导致运行时 DN 数据不均衡 | 4400 |
| gaussdb-dws-disk-skew-16 | data-skew | 磁盘倾斜:使用率最高与最低磁盘相差 ≥ 10% | 4454 |
| gaussdb-dws-distribution-key-redistribution-01 | query-slow | 分布列与 JOIN 条件不匹配导致 Redistribute Stream，查询耗时增加 | 4499 |
| gaussdb-dws-high-cpu-01 | cpu-high | 高 CPU 系统性能调优方案 | 4544 |
| gaussdb-dws-idle-in-transaction-01 | connection-storm | DWS 语句处于 idle in transaction 状态常见场景 | 4613 |
| gaussdb-dws-in-clause-nestloop-01 | query-slow | any-clause 不等值 JOIN 条件导致 NestLoop，超时超 1 小时 | 4679 |
| gaussdb-dws-index-missing-slow-query-01 | query-slow | WHERE 过滤列缺少索引，列存分区表点查耗时 48ms，建索引后降至 18ms | 4724 |
| gaussdb-dws-inlist2join-large-constants-01 | query-slow | "in 常量" 大量常量未转 join 导致执行不收 | 4769 |
| gaussdb-dws-join-null-values-01 | query-slow | JOIN 列存在大量 NULL 值导致扫描阶段耗时过长 | 4817 |
| gaussdb-dws-not-in-nestloop-01 | query-slow | NOT IN 语句使用 NestLoop Anti Join，改写为 NOT EXISTS 可使用 Hash Anti Join | 4862 |
| gaussdb-dws-operator-spill-23 | memory-pressure | 中间数据量超出内存,算子下盘(spill) 导致查询响应剧烈劣化 | 4916 |
| gaussdb-dws-seqscan-vs-indexscan-01 | query-slow | 点查/范围扫描场景 SeqScan 全表扫描耗时过长，应改为 IndexScan | 5012 |
| gaussdb-dws-nestloop-to-hashjoin-01 | query-slow | 大表 JOIN 使用 NestLoop 导致执行时间过长，应改为 HashJoin | 5057 |
| gaussdb-dws-groupagg-to-hashagg-01 | query-slow | 大结果集 Agg 选择 Sort+GroupAgg 导致性能差，应改为 HashAgg | 5105 |
| gaussdb-dws-partition-pruning-failure-01 | query-slow | 分区键包含表达式导致分区剪枝失效，全分区扫描耗时长达 10s | 5153 |
| gaussdb-dws-partition-table-scan-optimization-01 | query-slow | 大表无分区策略导致全表扫描耗时长，改建分区表后利用分区剪枝提升性能 | 5207 |
| gaussdb-dws-pck-point-query-01 | query-slow | 列存大表无 PCK 导致点查扫描全部 CU，执行时间 48ms，设置 PCK 后降至 5ms | 5252 |
| gaussdb-dws-pck-scan-acceleration-01 | query-slow | 列存表未设置 Partial Cluster Key 导致 CStore Scan 大量加载 CU | 5297 |
| gaussdb-dws-plan-hint-leading-01 | plan-suboptimal | Join 顺序 hint (leading) 调优 store_sales / date_dim join 顺序 | 5351 |
| gaussdb-dws-plan-hint-nojoin-method-02 | plan-suboptimal | no nestloop hint 改 hashjoin 避免低效 NestLoop | 5405 |
| gaussdb-dws-plan-hint-rows-03 | plan-suboptimal | 行数 hint 指明 store_sales 准确行数 | 5450 |
| gaussdb-dws-plan-hint-skew-04 | data-skew | 倾斜值 hint 优化 HashAgg 重分布倾斜 | 5494 |
| gaussdb-dws-planhint-rows-estimate-01 | query-slow | 多列关联统计信息缺失导致 HashJoin 行数严重低估，使用 rows hint 干预后结合 join 顺序优化从 110s 降至 94s | 5539 |
| gaussdb-dws-pushdown-data-node-scan-12 | plan-suboptimal | SQL 语句不能下推,执行计划中出现 Data Node Scan / RemoteQuery 节点 | 5593 |
| gaussdb-dws-row-vs-column-store-01 | query-slow | 中间表使用行存导致整体计划走行执行引擎，性能远差于列执行引擎 | 5647 |
| gaussdb-dws-copy-cdm-sequence-cache-01 | query-slow | CDM 数据同步 COPY 入库导入速率不达预期 | 5692 |
| gaussdb-dws-sort-pushdown-cn-bottleneck-01 | query-slow | CN 端 Window Agg + Sort 未下推导致查询耗时严重 | 5740 |
| gaussdb-dws-hashjoin-large-inner-table-01 | query-slow | HashJoin 大表做内表导致内存和性能问题 | 5794 |
| gaussdb-dws-large-table-broadcast-01 | query-slow | 大表 Broadcast 导致 DN 间大量数据传输 | 5839 |
| gaussdb-dws-stats-not-collected-slow-01 | query-slow | 统计信息未收集导致优化器估算不准，查询性能下降 | 5884 |
| gaussdb-dws-system-level-tuning-24 | other | 集群吞吐受限,系统级 GUC 未按 CPU/IO/内存/网络资源充分使用调优 | 5929 |
| gaussdb-dws-vacuum-full-long-tx-01 | disk-space-pressure | VACUUM FULL 后表文件大小无变化(长事务干扰) | 6022 |
| gaussdb-dws-vacuum-defer-cleanup-age-01 | disk-space-pressure | VACUUM 后存储空间未释放 (vacuum_defer_cleanup_age 非 0) | 6082 |
| gaussdb-dws-cant-fit-xid-old-tx-01 | other | Can't fit xid into page 报错(老事务导致 freeze 失效) | 6142 |
| gaussdb-import-skew-warning-07 | data-skew | 导入(INSERT/COPY)时 DN 间数据倾斜超过阈值需即时告警 | 6196 |
| gaussdb-too-many-clients-21 | connection-storm | Too many clients already — non-active 空闲连接积压 | 6268 |
| gaussdb-windowagg-single-dn-04 | plan-suboptimal | row_number() over() + count() over() 窗口函数全集中在单 DN 执行 | 6330 |
