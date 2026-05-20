# Cases Index

> 生成时间: 2026-05-20T07:48:43.492Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 65 cases (db=gaussdb-dws)
> 配套: cases/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| gaussdb-dws-plan-suboptimal-broadcast-skew-redistribute-01 | plan-suboptimal | DWS统计信息不准导致小表被误判为大表走Broadcast，应改用Redistribute | 6789 |
| gaussdb-dws-plan-suboptimal-nestloop-seqscan-cost-02 | plan-suboptimal | DWS索引扫描关闭后Seq Scan触发NestLoop但Hash Join启动代价更高 | 6833 |
| gaussdb-dws-plan-suboptimal-nestloop-perf-jump-hint-01 | plan-suboptimal | 实时场景执行时间跳变至 3600s 超时，NestLoop 选择错误，通过 enable_index_nestloop hint 修复 | 6877 |
| gaussdb-dws-query-slow-topsql-queue-wait-01 | query-slow | SQL作业block_time大但duration无明显变化——受其他作业排队影响 | 6924 |
| gaussdb-dws-query-slow-data-skew-dn-time-01 | data-skew | DN执行时间倾斜导致SQL作业整体执行慢 | 6977 |
| gaussdb-dws-query-slow-dn-io-contention-01 | disk-io-saturation | DN的IO指标偏低反映作业受IO抢占影响 | 7021 |
| gaussdb-dws-query-slow-windowagg-single-dn-01 | query-slow | row_number() over / count() over 窗口函数集中在单DN运行导致查询慢 | 7071 |
| gaussdb-dws-data-skew-row-number-partition-null-01 | data-skew | row_number() PARTITION BY 列存在大量 NULL 值导致计算倾斜、SQL 性能慢 | 7115 |
| gaussdb-dws-plan-suboptimal-data-skew-01 | data-skew | DWS数据倾斜——DN间数据分布不均导致性能瓶颈 | 7168 |
| gaussdb-dws-plan-suboptimal-large-table-broadcast-02 | query-slow | DWS大表Broadcast导致网络传输量大、查询慢 | 7212 |
| gaussdb-dws-plan-suboptimal-spill-overflow-03 | memory-pressure | DWS SQL执行落盘量过大或过早落盘导致性能低下 | 7256 |
| gaussdb-dws-plan-suboptimal-nestloop-large-table-04 | query-slow | DWS大表等值连接使用NestLoop导致查询慢 | 7300 |
| gaussdb-dws-data-skew-query-slow-01 | data-skew | 数据倾斜导致SQL执行不出结果 | 7344 |
| gaussdb-dws-statistics-not-collected-plan-poor-01 | plan-suboptimal | 统计信息未收集导致优化器估算偏差、执行计划差 | 7415 |
| gaussdb-dws-statement-not-pushed-down-slow-01 | cpu-high | 语句不下推导致CN成为性能瓶颈 | 7459 |
| gaussdb-dws-notin-nestloop-slow-01 | query-slow | NOT IN语义导致NestLoop，SQL执行慢 | 7512 |
| gaussdb-dws-no-partition-pruning-slow-01 | query-slow | 查询条件未包含分区键导致未分区剪枝、全表扫描 | 7556 |
| gaussdb-dws-row-estimate-small-nestloop-slow-01 | query-slow | 行数估算过小导致优化器选择NestLoop，查询卡住 | 7600 |
| gaussdb-dws-table-bloat-vacuum-slow-01 | query-slow | 表数据膨胀未清理脏数据导致性能时快时慢 | 7662 |
| gaussdb-dws-in-constant-no-join-slow-01 | query-slow | in常量数量过多未转为join导致查询慢 | 7751 |
| gaussdb-dws-table-bloat-autovacuum-01 | disk-space-pressure | DWS表膨胀：autovacuum未开启或回收不及时导致存储增长和性能下降 | 7798 |
| gaussdb-dws-plan-suboptimal-index-large-result-01 | plan-suboptimal | DWS返回结果集过大时索引失效导致查询走全表扫描 | 7884 |
| gaussdb-dws-plan-suboptimal-index-no-analyze-02 | plan-suboptimal | DWS表未及时ANALYZE导致索引未被使用 | 7928 |
| gaussdb-dws-plan-suboptimal-index-func-03 | plan-suboptimal | DWS过滤条件使用函数或隐式类型转换导致索引失效 | 7972 |
| gaussdb-dws-query-slow-max-active-statements-01 | query-slow | DWS普通用户查询慢——受max_active_statements资源管控排队 | 8016 |
| gaussdb-dws-query-slow-permission-or-filter-02 | query-slow | DWS普通用户查询慢——系统视图权限OR条件逐一判断耗时 | 8063 |
| gaussdb-dws-data-skew-bad-dist-key-01 | data-skew | 分布列选择不当导致数据倾斜，影响查询性能和磁盘空间 | 8107 |
| gaussdb-dws-statement-not-pushed-down-volatile-func-01 | cpu-high | 自定义函数provolatile属性定义错误导致语句不下推，CN成为性能瓶颈 | 8151 |
| gaussdb-dws-with-recursive-not-pushed-slow-01 | query-slow | WITH RECURSIVE查询不下推场景导致性能差 | 8204 |
| gaussdb-dws-plan-suboptimal-missing-analyze-01 | plan-suboptimal | DWS未收集统计信息导致查询执行计划不优（查询性能差） | 8248 |
| gaussdb-dws-query-slow-hstore-delta-bloat-01 | disk-space-pressure | HStore Delta表膨胀导致入库性能劣化 | 8292 |
| gaussdb-dws-query-slow-realtime-numa-codegen-01 | cpu-high | 实时数仓enable_codegen/enable_numa_bind参数未优化导致性能差 | 8348 |
| gaussdb-dws-cpu-high-stream-count-01 | cpu-high | CPU 持续飙高 · TopSQL 识别 Stream 算子数超阈值的语句 | 8413 |
| gaussdb-dws-query-slow-plan-jump-stale-stats-01 | plan-suboptimal | SQL 性能突然下降：统计信息不准导致执行计划跳变 | 8466 |
| gaussdb-dws-query-slow-long-running-operator-01 | query-slow | 作业长时间运行不结束：通过算子级 TopSQL 定位瓶颈算子 | 8510 |
| gaussdb-dws-lock-contention-pgxc-stat-activity-01 | lock-contention | 使用 PGXC_STAT_ACTIVITY 视图定位 DWS 慢 SQL、连接积压与业务阻塞 | 8557 |
| gaussdb-dws-query-slow-flink-connection-timeout-01 | query-slow | Flink 写入 DWS 时报 canceling statement due to statement timeout，connectionTimeOut 默认值过小 | 8630 |
| gaussdb-dws-lock-contention-wait-timeout-01 | lock-contention | 执行SQL时出现LOCK_WAIT_TIMEOUT锁等待超时 | 8677 |
| gaussdb-dws-write-slow-single-insert-01 | disk-io-saturation | 往DWS写数据慢，客户端数据积压：单条INSERT低并发场景吞吐不足 | 8738 |
| gaussdb-dws-query-slow-blocked-or-stale-stats-01 | query-slow | SQL 执行慢：阻塞或统计信息失效导致性能低 | 8782 |
| gaussdb-dws-memory-pressure-oom-query-01 | memory-pressure | DWS 集群内存临时不可用 (memory is temporarily unavailable) | 8826 |
| gaussdb-dws-disk-space-column-table-bloat-01 | disk-space-pressure | 列存表多次UPDATE后出现表膨胀 | 8879 |
| gaussdb-dws-data-skew-hash-dist-01 | data-skew | Hash 分布表数据倾斜导致 SQL 执行慢或无结果 | 8923 |
| gaussdb-dws-query-slow-missing-statistics-01 | plan-suboptimal | 未收集统计信息导致查询性能差 | 9003 |
| gaussdb-dws-query-slow-function-not-shipped-01 | query-slow | DWS自定义函数属性定义错误导致SQL不下推，性能极差 | 9056 |
| gaussdb-dws-nestloop-not-in-query-slow-01 | query-slow | 执行计划中有NestLoop导致SQL语句执行慢 | 9109 |
| gaussdb-dws-query-slow-partition-pruning-miss-01 | query-slow | 查询条件未涉及分区键导致全表扫描，SQL 执行慢 | 9153 |
| gaussdb-dws-plan-nestloop-row-underestimate-01 | plan-suboptimal | 行数估算过小导致优化器选择 NestLoop 执行计划，查询性能下降 | 9197 |
| gaussdb-dws-query-slow-table-bloat-01 | query-slow | 表数据膨胀导致SQL查询慢，用户前台页面数据加载不出 | 9262 |
| gaussdb-dws-query-slow-concurrent-index-01 | query-slow | 大量并发CREATE INDEX操作导致SQL查询慢 | 9360 |
| gaussdb-dws-point-query-cstore-scan-slow-01 | query-slow | 单表点查性能差：列存表用于点查场景导致耗时超预期 | 9413 |
| gaussdb-dws-query-slow-ccn-queue-memory-01 | memory-pressure | 动态负载管理下语句估算内存过大导致 CCN 排队、业务整体缓慢 | 9457 |
| gaussdb-dws-cstore-small-cu-io-slow-01 | disk-io-saturation | 列存小CU过多导致I/O飙升和查询偶发性变慢 | 9501 |
| gaussdb-dws-disk-io-saturation-column-cu-bloat-01 | disk-io-saturation | 列存表小CU膨胀导致I/O高、查询慢 | 9553 |
| gaussdb-dws-disk-io-saturation-dirty-data-bloat-01 | disk-io-saturation | 表脏数据过多导致 I/O 高、查询慢 | 9597 |
| gaussdb-dws-disk-io-saturation-data-skew-01 | data-skew | 表存储倾斜导致单 DN I/O 过高、查询慢 | 9650 |
| gaussdb-dws-query-slow-no-index-or-index-miss-01 | query-slow | 缺少索引或有索引未走导致全表扫描、I/O 高 | 9703 |
| gaussdb-dws-disk-io-saturation-no-partition-pruning-01 | disk-io-saturation | 设计了分区表但查询未走分区剪枝导致I/O极高 | 9747 |
| gaussdb-dws-disk-io-saturation-large-index-import-01 | disk-io-saturation | 大量数据带多个索引导入产生大量XLOG、主备同步慢 | 9791 |
| gaussdb-dws-disk-io-saturation-small-files-iops-01 | disk-io-saturation | 列存多分区导致小文件过多、IOPS 飙高 | 9835 |
| gaussdb-dws-memory-pressure-high-mem-query-01 | memory-pressure | 集群内存负载过高或出现memory is temporary unavailable报错 | 9879 |
| gaussdb-dws-query-slow-vacuum-lock-wait-01 | lock-contention | 存在锁等待导致VACUUM FULL执行慢 | 9923 |
| gaussdb-dws-query-slow-vacuum-pck-sort-01 | disk-io-saturation | 列存表PCK排序下盘导致VACUUM FULL执行慢 | 9985 |
| gaussdb-dws-disk-space-columnar-table-bloat-01 | disk-space-pressure | DWS列存表多次小批量INSERT后表膨胀、磁盘空间持续增长 | 10041 |
| gaussdb-dws-lock-contention-concurrent-update-01 | lock-contention | 并发更新同一行数据导致事务回滚报错 | 10094 |
