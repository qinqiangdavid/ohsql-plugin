# GaussDB 主线 77 case 端到端复现现象清单

> 生成: 2026-05-21T12:00:00+08:00
> 用法: 每条用作"用户提问"输入给 perf-kp-sql skill (Phase 1 现象描述输入),
>      看 LLM Phase 2 能否路由到"期待命中"的 case_id。
> 数据源: plugins/perf-kp-sql/data/cases/gaussdb/CASES.md (77 case_id)

## 按 symptom_category 分组

---

### cpu-high (7 个)

#### 1. case_id: `gaussdb-cpu-high-topsql-01`
- title: GaussDB CPU使用率高——通过dbe_perf.statement定位高CPU SQL
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/143844792/
- **复现现象** (拷给 skill):
  > 我的 GaussDB 数据库 CPU 使用率持续偏高，业务侧反馈接口响应变慢。查 `dbe_perf.statement` 发现有几条 SQL 的 `avg_time` 超过 3ms 且 `cpu_time` 排名靠前，对其中一条做 `EXPLAIN ANALYZE` 发现走了全表扫描。不知道怎么找到哪条 SQL 是元凶。
- 关键技术信号: dbe_perf.statement.cpu_time / avg_time > 3ms / EXPLAIN ANALYZE SeqScan
- 期待 LLM 命中: gaussdb-cpu-high-topsql-01

#### 2. case_id: `gaussdb-cpu-high-connection-timezone-01`
- title: GaussDB CPU SYS高——高并发短连接重复加载时区文件
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/143844792/
- **复现现象** (拷给 skill):
  > 压测期间 GaussDB 服务器 CPU SYS 占用超过 70%，抓火焰图发现时区文件加载相关的栈帧占比超 40%。应用使用的是短连接，每次建连都会重新读取时区文件。CPU user 不高，主要是 SYS 升高，普通 SQL 执行正常但整体吞吐骤降。
- 关键技术信号: 火焰图时区加载线程占比 > 40% / CPU SYS 高 / 短连接高并发
- 期待 LLM 命中: gaussdb-cpu-high-connection-timezone-01

#### 3. case_id: `gaussdb-cpu-high-statement-view-01`
- title: GaussDB整体CPU高——通过性能视图定位高CPU SQL
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://www.modb.pro/db/1881247803599499264/
- **复现现象** (拷给 skill):
  > GaussDB 整体 CPU 居高不下，业务 P95 响应时间上升，慢 SQL 告警频繁触发。我查了 `dbe_perf.statement` 和 `dbe_perf.summary_statement`，想按 `cpu_time` 逆序找出高消耗 SQL，但不确定用哪个视图更合适，以及如果是瞬时 CPU 飙高应该看哪里。
- 关键技术信号: dbe_perf.statement.cpu_time / statement_history.cpu_time vs db_time / pg_stat_activity
- 期待 LLM 命中: gaussdb-cpu-high-statement-view-01

#### 4. case_id: `gaussdb-dist-volatile-func-not-pushed-slow-01`
- title: 自定义函数VOLATILE属性导致分布式语句不下推
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0186.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式集群里有一个自定义函数，包含在 SQL 里执行时特别慢，但单独调用函数本身很快。用 `EXPLAIN` 看到计划中有 `Data Node Scan`，说明语句没有下推到 DN 执行，而是把大量数据拉到 CN 上做计算。查 `pg_proc.provolatile` 发现函数属性是 `v`（VOLATILE）。
- 关键技术信号: EXPLAIN Data Node Scan / pg_proc.provolatile = 'v' / CN 性能瓶颈
- 期待 LLM 命中: gaussdb-dist-volatile-func-not-pushed-slow-01

#### 5. case_id: `gaussdb-dist-v3-volatile-func-not-pushed-slow-01`
- title: 分布式v3：自定义函数VOLATILE属性导致语句不下推、CN性能瓶颈
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0265.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v3 环境，含自定义函数的 SQL 跑起来 CN 节点 CPU 很高，DN 却空闲。`EXPLAIN` 输出里没有 Streaming 节点，只有 `Data Node Scan`，说明整条语句没能下推。检查 `pg_proc` 的 `proshippable` 字段是 `f`，函数 volatility 是 VOLATILE。
- 关键技术信号: EXPLAIN 无 Streaming 节点 / pg_proc.proshippable = 'f' / CN 瓶颈
- 期待 LLM 命中: gaussdb-dist-v3-volatile-func-not-pushed-slow-01

#### 6. case_id: `gaussdb-cpu-saturated-by-slowsql-06`
- title: DB 节点 CPU 持续满载,gsql 进程占用率高
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/146009597
- **复现现象** (拷给 skill):
  > 数据库节点 `top` 命令显示 `gaussdb` 进程 CPU 占用率很高，持续满载。查 `pg_stat_statements`，发现某个聚合查询的 `total_time > 1000ms` 且 `calls > 10`，该查询没有命中索引。整体业务响应明显变慢。
- 关键技术信号: top gsql CPU 高 / pg_stat_statements.total_time > 1000 / 聚合查询未命中索引
- 期待 LLM 命中: gaussdb-cpu-saturated-by-slowsql-06

#### 7. case_id: `gaussdb-overall-slow-cpu-high-01`
- title: gaussdb 进程 CPU 占用高导致整体性能慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/131321486
- **复现现象** (拷给 skill):
  > GaussDB 整体变慢，用 `top` 确认是 `gaussdb` 进程本身吃满了 CPU，其他进程正常。想用 WDR 报告的 "SQL ordered by CPU Time" 找到高消耗 SQL，但不知道如果 WDR 也排查不出来，应该用火焰图的哪个工具去抓内核函数热点。
- 关键技术信号: top gaussdb CPU > 90% / WDR Top SQL by CPU Time / 火焰图内核函数热点
- 期待 LLM 命中: gaussdb-overall-slow-cpu-high-01

---

### memory-pressure (5 个)

#### 8. case_id: `gaussdb-memory-shared-buffer-miss-01`
- title: GaussDB内存不足——shared_buffers过小导致buffer命中率低
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/143844792/
- **复现现象** (拷给 skill):
  > GaussDB 数据库的 buffer 命中率下降到 95% 以下，WDR 报告里能看到这个指标。正常 TP 数据库应该在 99% 以上。怀疑是 `shared_buffers` 配置太小导致缓冲区频繁被淘汰，SQL 需要大量物理读。
- 关键技术信号: buffer命中率 < 99% (WDR) / shared_buffers 过小
- 期待 LLM 命中: gaussdb-memory-shared-buffer-miss-01

#### 9. case_id: `gaussdb-memory-work-mem-spill-01`
- title: GaussDB内存不足——work_mem过小导致Hash/Sort算子落盘
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/143844792/
- **复现现象** (拷给 skill):
  > 某些 SQL 跑得特别慢，`EXPLAIN ANALYZE` 执行计划里 Hash Join 或 Sort 算子出现了落盘标志，速度比正常慢了好几倍。怀疑是 `work_mem` 设太小，算子内存不够用就写临时表空间了，带来 5-10 倍性能下降。
- 关键技术信号: EXPLAIN ANALYZE 算子落盘 / work_mem 不足 / Hash/Sort 写临时表空间
- 期待 LLM 命中: gaussdb-memory-work-mem-spill-01

#### 10. case_id: `gaussdb-memory-pressure-node-detail-01`
- title: GaussDB内存高——通过dbe_perf.memory_node_detail定位内存占用点
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://www.modb.pro/db/1881247803599499264/
- **复现现象** (拷给 skill):
  > GaussDB 内存使用率告警，`dbe_perf.memory_node_detail` 显示 `dynamic_used_memory` 接近 `max_dynamic_memory`，有用户查询开始报内存不足错误。不清楚是 session 级内存消耗大还是内核共享内存（如 Global Sys Cache）异常，不知道该查哪个视图继续定位。
- 关键技术信号: dbe_perf.memory_node_detail / dynamic_used_memory 接近上限 / dbe_perf.session_memory_detail
- 期待 LLM 命中: gaussdb-memory-pressure-node-detail-01

#### 11. case_id: `gaussdb-savepoint-in-loop-resource-leak-01`
- title: 循环内重复创建同名 SAVEPOINT 引发资源累积
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0058.html
- **复现现象** (拷给 skill):
  > 存储过程在循环中反复创建同名 SAVEPOINT，但没有配对的 `RELEASE SAVEPOINT`。运行一段时间后内存使用异常攀升，性能也明显下降。同名 SAVEPOINT 不会覆盖旧的而是重新创建，导致资源持续累积。
- 关键技术信号: 循环内同名 SAVEPOINT 不覆盖 / 缺少 RELEASE SAVEPOINT / 资源累积
- 期待 LLM 命中: gaussdb-savepoint-in-loop-resource-leak-01

#### 12. case_id: `gaussdb-package-variable-session-memory-01`
- title: PACKAGE变量大量缓存可能占用大量内存
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0053.html
- **复现现象** (拷给 skill):
  > GaussDB 中使用了大量 PACKAGE 变量，这些变量生命周期是整个 SESSION，长时间运行的连接里内存消耗持续增长。怀疑是 PACKAGE 变量在 SESSION 中缓存积累导致内存占用过高，应该怎么排查和规避？
- 关键技术信号: PACKAGE 变量 SESSION 级缓存 / 长连接内存持续增长
- 期待 LLM 命中: gaussdb-package-variable-session-memory-01

---

### disk-io-saturation (2 个)

#### 13. case_id: `gaussdb-disk-io-high-statement-view-01`
- title: GaussDB整体IO高——通过性能视图定位高物理读SQL
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://www.modb.pro/db/1881247803599499264/
- **复现现象** (拷给 skill):
  > GaussDB 整体 IO 居高不下，查 `dbe_perf.statement` 发现 `n_blocks_fetched` 和 `n_blocks_hit` 差值很大，说明有大量物理读。同时 `pg_thread_wait_status` 里看到 `wait_event = DataFileRead`，IO_EVENT 状态的连接很多。想找出是哪条 SQL 导致的高 IO。
- 关键技术信号: dbe_perf.statement n_blocks_fetched-n_blocks_hit 差值大 / wait_event=DataFileRead
- 期待 LLM 命中: gaussdb-disk-io-high-statement-view-01

#### 14. case_id: `gaussdb-overall-slow-io-await-high-01`
- title: I/O 满或 await 高导致整体性能慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/131321486
- **复现现象** (拷给 skill):
  > GaussDB 整体性能慢，`iostat` 显示磁盘 `%util` 接近 100%，`r_await` 或 `w_await` 超过 3ms。用 `pidstat` 看到某些线程 IO 读写量很大，怀疑是用户 SQL 导致的，但不知道怎么从系统线程 TID 映射到具体的 GaussDB SQL 会话。
- 关键技术信号: iostat %util 满 / r_await > 3ms / pidstat TPLworker 线程 IO 高
- 期待 LLM 命中: gaussdb-overall-slow-io-await-high-01

---

### disk-space-pressure (2 个)

#### 15. case_id: `gaussdb-dist-disk-full-storage-skew-01`
- title: 磁盘满后快速定位存储倾斜表
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0016.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式集群某个 DN 磁盘快满了，但其他 DN 还有大量空间，怀疑是存储倾斜导致。想用 `pg_stat_get_last_data_changed_time` 找最近发生变化的表，再用 `table_distribution()` 看各 DN 占用情况，快速定位是哪张表的数据分布不均。
- 关键技术信号: DN 磁盘满 / get_last_changed_table / table_distribution() 各 DN 空间差异大
- 期待 LLM 命中: gaussdb-dist-disk-full-storage-skew-01

#### 16. case_id: `gaussdb-disk-space-pressure-storage-skew-locate-01`
- title: 磁盘满后快速定位存储倾斜的表
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0470.html
- **复现现象** (拷给 skill):
  > 分布式 GaussDB 某个节点磁盘快满，需要迅速找出是哪张表最近写入数据最多且在各 DN 分布不均。打算用 `get_last_changed_table()` 结合 `table_distribution(schemaname, relname)` 来定位，但不清楚这两个函数怎么配合使用。
- 关键技术信号: get_last_changed_table / table_distribution / 各 DN 存储空间不均
- 期待 LLM 命中: gaussdb-disk-space-pressure-storage-skew-locate-01

---

### data-skew (5 个)

#### 17. case_id: `gaussdb-dist-routine-skew-inspection-01`
- title: 常规数据倾斜巡检：表个数少于1W时使用PGXC_GET_TABLE_SKEWNESS视图
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0016.html
- **复现现象** (拷给 skill):
  > 想对 GaussDB 分布式集群做数据倾斜巡检，库里表的数量不超过 1 万张，需要批量查出所有表各 DN 的数据分布情况，确认哪些表存在倾斜。听说可以直接用 `PGXC_GET_TABLE_SKEWNESS` 视图，但不清楚它和 `table_distribution()` 函数分别适用什么场景。
- 关键技术信号: PGXC_GET_TABLE_SKEWNESS / 表数量 < 1W / table_distribution()
- 期待 LLM 命中: gaussdb-dist-routine-skew-inspection-01

#### 18. case_id: `gaussdb-data-skew-storage-distribution-01`
- title: 分布列选择不合理导致存储倾斜影响查询性能
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0190.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询某张表时特别慢，用 `EXPLAIN PERFORMANCE` 看各 DN 实际扫描行数发现最大是最小的 4 倍，存在明显存储倾斜。表的当前分布列是时间字段，不同时间段数据量差异大，想确认倾斜并改分布列。
- 关键技术信号: explain performance 各 DN 行数差 > 4x / table_skewness() / 分布列选择不合理
- 期待 LLM 命中: gaussdb-data-skew-storage-distribution-01

#### 19. case_id: `gaussdb-data-skew-compute-redistribute-01`
- title: 重分布列存在倾斜值导致计算倾斜，部分 DN 处理数据量远大于其他节点
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0190.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询虽然存储均匀，但 `EXPLAIN ANALYZE` 里 `Streaming(type: REDISTRIBUTE)` 显示各 DN 输出行数严重不均（最大是最小的 3 倍），某些 DN 的 Hash Join 耗时远高于其他。怀疑 Join 键有大量重复值（如 0）导致计算倾斜，应该开 `skew_option` 参数优化。
- 关键技术信号: Streaming REDISTRIBUTE 各 DN 行数不均 / skew_option / 倾斜值 0
- 期待 LLM 命中: gaussdb-data-skew-compute-redistribute-01

#### 20. case_id: `gaussdb-distribution-key-skew-xc-node-id-25`
- title: 分布键选择不当致 DN 间数据量差 >10%,木桶效应拖慢整体
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://xie.infoq.cn/article/86d06ac0a01fbd403397523b7
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询整体很慢，怀疑是木桶效应——某个 DN 数据量明显比其他节点多。用 `xc_node_id` 分组统计各 DN 行数，发现 DN 间数据量差异超过 10%。现在的分布列 distinct 值少，导致分布不均，想换合适的分布列。
- 关键技术信号: xc_node_id 分组统计各 DN 行数 / DN 间差异 >= 10% / 分布列 distinct 值少
- 期待 LLM 命中: gaussdb-distribution-key-skew-xc-node-id-25

#### 21. case_id: `gaussdb-data-skew-hashjoin-dn-compute-skew-01`
- title: 表数据分布倾斜导致 HashJoin DN 计算时间严重偏斜
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0217.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询耗时很长，`EXPLAIN ANALYZE` 显示 HashJoin 在不同 DN 上的执行时间范围是 [2657ms, 93339ms]，偏斜极其严重，Memory Information 各节点内存消耗也极不均匀。进一步看下层 Seq Scan 也有 [38ms, 2940ms] 的倾斜，基本确定是底表存储分布有问题。
- 关键技术信号: EXPLAIN ANALYZE HashJoin DN 时间范围偏斜 / Memory Information 内存偏斜 / Seq Scan DN 倾斜
- 期待 LLM 命中: gaussdb-data-skew-hashjoin-dn-compute-skew-01

---

### plan-suboptimal (17 个)

#### 22. case_id: `gaussdb-plan-suboptimal-rewrite-rule-partialpush-01`
- title: 自定义函数无法下推导致 CN 上全量 HASH JOIN，partialpush 参数可提升性能
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0224.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询中含有自定义函数，`EXPLAIN VERBOSE` 显示整个语句走了 RemoteQuery 而非 Streaming，大量数据被拉到 CN 上做 Hash Join，网络传输很多，查询极慢。听说可以用 `rewrite_rule` 的 `partialpush` 参数让部分逻辑下推，但不清楚怎么配置。
- 关键技术信号: EXPLAIN RemoteQuery / CN 上 HASH JOIN / rewrite_rule=partialpush
- 期待 LLM 命中: gaussdb-plan-suboptimal-rewrite-rule-partialpush-01

#### 23. case_id: `gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01`
- title: 目标列相关子查询无法提升，逐行触发子查询导致性能低下，intargetlist 参数转为 JOIN 提升性能
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0224.html
- **复现现象** (拷给 skill):
  > GaussDB SQL 的 SELECT 目标列里有相关子查询（如 `(SELECT avg(c2) FROM t2 WHERE t2.c2=t1.c2)`），`EXPLAIN VERBOSE` 看到 SubPlan 节点，每扫描外表一行就触发一次子查询执行，大表场景下慢得难以接受。想用 `rewrite_rule` 的 `intargetlist` 参数把子查询提升为 JOIN。
- 关键技术信号: EXPLAIN SubPlan 在目标列 / 逐行触发子查询 / rewrite_rule=intargetlist
- 期待 LLM 命中: gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01

#### 24. case_id: `gaussdb-plan-suboptimal-missing-analyze-dist-v8-01`
- title: 未收集统计信息导致 GaussDB 分布式查询性能差（v8）
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0266.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v8 环境，一条多表关联查询跑得很慢。对它做 `EXPLAIN VERBOSE` 时看到 WARNING 提示：`Statistics in some tables or columns(...) are not collected. HINT: Do analyze for them`。这些表从未执行过 ANALYZE，导致执行计划选择不优。
- 关键技术信号: EXPLAIN VERBOSE WARNING Statistics not collected / 未执行 ANALYZE
- 期待 LLM 命中: gaussdb-plan-suboptimal-missing-analyze-dist-v8-01

#### 25. case_id: `gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01`
- title: 多表 JOIN 中间结果估算不准，NestLoop 耗时 12s，改用 unlogged table + 禁 hashjoin 降至 3s
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0266.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v8，一个多表复杂查询实际耗时约 12 秒。`EXPLAIN` 显示扫描已用 Index Scan，瓶颈在最外层 Nest Loop Join 的 Join Filter 里有字符串运算和不等值比较。默认优化器在小表和大表 JOIN 时建了大 Hash Table，性能差，关闭 `enable_hashjoin` 改 NestLoop 反而更快。
- 关键技术信号: EXPLAIN NestLoop > 12s / enable_hashjoin=off / 大表建 Hash Table
- 期待 LLM 命中: gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01

#### 26. case_id: `gaussdb-query-slow-missing-analyze-01`
- title: 未收集统计信息（analyze）导致查询性能差、执行计划选错
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0267.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v3 多表 JOIN 查询突然变慢，用 `EXPLAIN VERBOSE` 看到警告信息：`Statistics in some tables or columns are not collected`，同时 pg_log 里也有对应日志。表上没有做过 ANALYZE，导致优化器选了错误的执行计划。
- 关键技术信号: EXPLAIN VERBOSE WARNING Statistics not collected / pg_log Statistics 日志 / 未 ANALYZE
- 期待 LLM 命中: gaussdb-query-slow-missing-analyze-01

#### 27. case_id: `gaussdb-plan-suboptimal-seqscan-vs-indexscan-01`
- title: SeqScan 扫描过滤大量数据，点查场景应走 IndexScan
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0268.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式环境，一个等值点查语句跑得很慢，`EXPLAIN ANALYZE` 显示走了 Seq Scan 全表扫描，过滤掉了大量数据（`Rows Removed by Filter` 很大），只返回少量行，从 20ms 降到 3ms 只需建个索引，但优化器没有自动选择 IndexScan。
- 关键技术信号: EXPLAIN ANALYZE SeqScan / Rows Removed by Filter 大 / 点查场景缺索引
- 期待 LLM 命中: gaussdb-plan-suboptimal-seqscan-vs-indexscan-01

#### 28. case_id: `gaussdb-plan-suboptimal-nestloop-large-outer-01`
- title: 两表 JOIN 外表行数大时 NestLoop 耗时 5s，关闭 NestLoop+MergeJoin 改 HashJoin 降至 86ms
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0268.html
- **复现现象** (拷给 skill):
  > GaussDB 两表 JOIN，`EXPLAIN ANALYZE` 显示走了 NestLoop，外表行数很大，实际耗时 5 秒。设 `enable_nestloop=off` 和 `enable_mergejoin=off` 后优化器选了 HashJoin，耗时降到 86ms。想确认是不是应该长期关闭这两个参数。
- 关键技术信号: EXPLAIN Nested Loop A-time > 5000ms / enable_nestloop=off / enable_mergejoin=off
- 期待 LLM 命中: gaussdb-plan-suboptimal-nestloop-large-outer-01

#### 29. case_id: `gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01`
- title: 大结果集 Agg 走 Sort+GroupAgg 耗时长，关闭 Sort 改 HashAgg 性能提升
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0268.html
- **复现现象** (拷给 skill):
  > GaussDB GROUP BY 聚合查询很慢，`EXPLAIN ANALYZE` 显示计划走了 Sort + GroupAggregate，而不是 HashAgg。大结果集场景 HashAgg 应该更优，尝试 `SET enable_sort=off` 后计划切到 HashAgg，性能明显提升。
- 关键技术信号: EXPLAIN GroupAggregate + Sort / enable_sort=off / HashAgg 更优
- 期待 LLM 命中: gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01

#### 30. case_id: `gaussdb-dws-plan-suboptimal-planhint-01`
- title: TPC-DS Q24查询执行计划不优——使用Plan Hint调优
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0284.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v8 跑 TPC-DS Q24 之类的复杂多表关联查询，`EXPLAIN ANALYZE` 发现有某个算子耗时特别长成为瓶颈，整体 SQL 性能达不到预期。其他调参方式都试了，想尝试用 Plan Hint 来固定或干预瓶颈算子的执行方式。
- 关键技术信号: EXPLAIN ANALYZE 瓶颈算子 / Plan Hint 干预执行计划
- 期待 LLM 命中: gaussdb-dws-plan-suboptimal-planhint-01

#### 31. case_id: `gaussdb-plan-suboptimal-anti-join-row-estimate-01`
- title: Anti Join 自连接行数估算不准导致查询性能下降
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0216.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式有个 NOT IN / Anti Join 的自连接查询，`EXPLAIN VERBOSE` 显示 Anti Join 的估算行数和实际行数相差很大，导致后续计划选择不优，查询性能下降。想通过调整 `cost_param` 的 bit0 让不等式连接的行数估算更准确。
- 关键技术信号: EXPLAIN VERBOSE Anti Join 行数估算严重偏差 / cost_param bit0=1
- 期待 LLM 命中: gaussdb-plan-suboptimal-anti-join-row-estimate-01

#### 32. case_id: `gaussdb-plan-suboptimal-correlated-filter-selectivity-01`
- title: 多列强相关过滤条件选择率用乘积估算导致行数不准
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0216.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询，WHERE 子句里有两个强相关列的 AND 过滤条件，优化器把两列选择率相乘来估算，导致行数严重低估，Hash Join 后续计划很差。设置 `cost_param=2`（bit1=1）后选用最小选择率，行数估算更准，查询性能明显改善。
- 关键技术信号: EXPLAIN VERBOSE HashJoin 行数低估 / 强相关列 AND 过滤 / cost_param bit1=1
- 期待 LLM 命中: gaussdb-plan-suboptimal-correlated-filter-selectivity-01

#### 33. case_id: `gaussdb-dws-distkey-choice-01`
- title: 选择合适的分布列避免不必要 Streaming
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/134704421
- **复现现象** (拷给 skill):
  > GaussDB 分布式两张表做 JOIN，执行计划里出现了 Streaming 节点，DN 之间有大量数据重分布传输，导致查询变慢。检查建表语句发现两张表的分布列不是 JOIN 列，导致优化器不得不加 Streaming。想调整分布列避免不必要的 DN 间通信。
- 关键技术信号: EXPLAIN 含 Streaming 节点 / 两表 JOIN 列不是分布列 / 调整分布列消除 Streaming
- 期待 LLM 命中: gaussdb-dws-distkey-choice-01

#### 34. case_id: `gaussdb-groupagg-sort-vs-hashagg-08`
- title: GROUP BY 计划走 GroupAgg+Sort 而非 HashAgg 导致性能差
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0013.html
- **复现现象** (拷给 skill):
  > GaussDB GROUP BY 查询执行计划包含 GroupAgg+Sort 算子组合，导致性能差。正常应该走 HashAgg 更快。看文档说可以通过调大 `work_mem` 让优化器有足够内存建 hash table 从而选择 HashAgg，但不确定调多大合适。
- 关键技术信号: EXPLAIN GroupAgg+Sort / work_mem 过小无法用 HashAgg / 调大 work_mem 切换 HashAgg
- 期待 LLM 命中: gaussdb-groupagg-sort-vs-hashagg-08

#### 35. case_id: `gaussdb-plan-suboptimal-row-estimate-broadcast-01`
- title: 多列关联估算行数严重低估导致广播代价高
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0204.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询计划里，某个 HashJoin 算子用了多列联合键（如 ticket_number + item_sk）做关联，但优化器估算的行数（2140行）与实际相差悬殊，导致上层算子选了 Broadcast 广播策略，代价很高。缺少多列相关性统计导致估算不准，需要用 rows hint 修正。
- 关键技术信号: EXPLAIN 多列关联行数严重低估 / Broadcast 代价高 / rows hint 修正
- 期待 LLM 命中: gaussdb-plan-suboptimal-row-estimate-broadcast-01

#### 36. case_id: `gaussdb-plan-suboptimal-statistics-change-plan-regression-01`
- title: 统计信息变更导致 Join 流方式从 Broadcast 切换为 Redistribute 引发计划劣化
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0204.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式在把 `default_statistics_target` 调整为 -2 重新收集统计信息后，同一个查询的执行计划发生了劣化——原来 JOIN 用的是 BroadCast，现在变成了 Redistribute，性能明显下降。想用 Plan Hint 固定回之前的计划。
- 关键技术信号: EXPLAIN Stream 算子从 Broadcast 切到 Redistribute / default_statistics_target=-2 / Plan Hint 固定计划
- 期待 LLM 命中: gaussdb-plan-suboptimal-statistics-change-plan-regression-01

#### 37. case_id: `gaussdb-rewrite-rule-partialpush-13`
- title: 不下推函数(如 group_concat) 导致 RemoteQuery 拉全表回 CN
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0315.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v3 查询里用了 `group_concat` 这类不可下推的函数，`EXPLAIN` 输出里出现了 `Data Node Scan on t1 "_REMOTE_TABLE_QUERY_"` 的 RemoteQuery，把整个表拉到 CN 再做 Hash Join，网络传输量很大，查询极慢。想通过 `rewrite_rule=partialpush` 解决。
- 关键技术信号: EXPLAIN Data Node Scan "_REMOTE_TABLE_QUERY_" / group_concat 不下推 / rewrite_rule=partialpush
- 期待 LLM 命中: gaussdb-rewrite-rule-partialpush-13

#### 38. case_id: `gaussdb-stale-stats-hint-fix-09`
- title: 高频数据变化表统计信息滞后导致计划选择不优
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0013.html
- **复现现象** (拷给 skill):
  > GaussDB 有张表数据写入非常频繁，自动 ANALYZE 还没触发时统计信息就已经过期了，导致查询执行计划估算的行数和实际差异大，计划不优，性能抖动。不想频繁手动 ANALYZE，想通过给 SQL 加 Hint 固定执行计划来规避统计信息滞后的问题。
- 关键技术信号: 统计信息滞后 / 高频数据变化表 / Plan Hint 固定执行计划
- 期待 LLM 命中: gaussdb-stale-stats-hint-fix-09

#### 39. case_id: `gaussdb-plan-suboptimal-missing-analyze-01`
- title: 未收集统计信息导致查询性能差（集中式GaussDB）
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v2-gaussdb/gaussdb_42_0238.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式部署，有个查询跑得比预期慢很多。`EXPLAIN VERBOSE` 输出了 WARNING：`Statistics in some tables or columns(...) are not collected.`，pg_log 里也有同样的日志。这些表上从来没跑过 ANALYZE，执行计划选错了。
- 关键技术信号: EXPLAIN VERBOSE WARNING Statistics not collected / pg_log 日志 / 集中式 GaussDB 未 ANALYZE
- 期待 LLM 命中: gaussdb-plan-suboptimal-missing-analyze-01

#### 40. case_id: `gaussdb-query-slow-missing-statistics-explain-verbose-01`
- title: 未收集统计信息导致查询性能差（集中式v3）
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0288.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v3 环境，多表关联查询很慢。做 `EXPLAIN VERBOSE` 发现有 WARNING 提示某些列没有统计信息。pg_log 日志里也出现了 `Statistics in some tables or columns are not collected` 的日志条目，需要对相关表做 ANALYZE。
- 关键技术信号: explain verbose WARNING Statistics not collected / pg_log Statistics 日志 / 集中式 v3
- 期待 LLM 命中: gaussdb-query-slow-missing-statistics-explain-verbose-01

---

### query-slow (43 个)

#### 41. case_id: `gaussdb-query-slow-complex-join-intermediate-rows-01`
- title: 多表 join 中间结果估算不准导致 Hash Join 建大 Hash Table、查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v3-gaussdb/gaussdb-12-0267.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式一个查询：查找某人在前后 15 分钟内同一网吧上网的人员，实际耗时约 12 秒。`EXPLAIN` 显示对大表建了 Hash Table，因为中间结果行数估算不准，导致选了在大表上建 Hash Table 的 Hash Join。关闭 `enable_hashjoin` 改为 NestLoop + Index Scan 后性能提升。
- 关键技术信号: EXPLAIN Hash Join 大表建 Hash Table / enable_hashjoin=off / NestLoop + Index Scan
- 期待 LLM 命中: gaussdb-query-slow-complex-join-intermediate-rows-01

#### 42. case_id: `gaussdb-query-slow-no-partial-pushdown-01`
- title: 含不可下推函数的查询未使用 partialpush 导致大量数据在 CN 上做 Hash Join、查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0318.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v8 查询里包含 `group_concat` 这类不可下推函数，整个语句无法生成 Stream 计划在 DN 分布式执行，`EXPLAIN VERBOSE` 显示走了 Data Node Scan，大量数据拉到 CN 做 Hash Join。需要用 `rewrite_rule=partialpush` 做部分下推优化。
- 关键技术信号: EXPLAIN VERBOSE Data Node Scan / CN 上 Hash Join / rewrite_rule=partialpush
- 期待 LLM 命中: gaussdb-query-slow-no-partial-pushdown-01

#### 43. case_id: `gaussdb-query-slow-correlated-subquery-target-list-01`
- title: 目标列相关子查询未提升导致每行触发子查询、查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0318.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v8，SELECT 列表里有关联子查询，`EXPLAIN VERBOSE` 看到 SubPlan 节点，扫描外表每一行都会触发子查询执行一次，大表场景极慢。设 `rewrite_rule=intargetlist` 后子查询被提升转为 JOIN，性能显著提升。
- 关键技术信号: EXPLAIN SubPlan 在 SELECT 列表 / 每行触发子查询 / rewrite_rule=intargetlist
- 期待 LLM 命中: gaussdb-query-slow-correlated-subquery-target-list-01

#### 44. case_id: `gaussdb-seqscan-without-index-slow-01`
- title: 等值过滤无索引导致全表 Seq Scan 慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0150.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式，一个按 email 字段做等值过滤的查询，`EXPLAIN ANALYZE` 显示走了 Seq Scan，Total runtime 约 382ms。email 列没有索引，全表扫描后过滤。建立 B-tree 索引后降到 0.3ms 以内。
- 关键技术信号: EXPLAIN ANALYZE Seq Scan 382ms / 等值过滤无索引 / Total runtime
- 期待 LLM 命中: gaussdb-seqscan-without-index-slow-01

#### 45. case_id: `gaussdb-query-slow-seqscan-index-missing-01`
- title: 点查/范围扫描使用SeqScan全表扫描导致查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0289.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v3，点查语句（等值条件过滤）用了 Seq Scan 全表扫描，`EXPLAIN ANALYZE` 显示 `Rows Removed by Filter` 超过 11 万行，实际返回只有 7 行，A-time 超过 2 秒。在过滤列上建索引后切换到 IndexScan，降到 0.2ms。
- 关键技术信号: EXPLAIN ANALYZE SeqScan A-time > 2000ms / Rows Removed by Filter 很大 / 缺索引
- 期待 LLM 命中: gaussdb-query-slow-seqscan-index-missing-01

#### 46. case_id: `gaussdb-query-slow-nestloop-hashjoin-02`
- title: 两表Join选择NestLoop导致查询执行慢（大数据量场景）
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0289.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v3，两表 JOIN 查询，`EXPLAIN ANALYZE` 显示 Nested Loop 耗时 27 秒。两表行数都不小，NestLoop 在这种场景下很慢。设 `enable_nestloop=off` 和 `enable_mergejoin=off` 后优化器选了 HashJoin，耗时降到 2 秒。
- 关键技术信号: EXPLAIN ANALYZE NestLoop A-time 27s / enable_nestloop=off / enable_mergejoin=off
- 期待 LLM 命中: gaussdb-query-slow-nestloop-hashjoin-02

#### 47. case_id: `gaussdb-query-slow-groupagg-sort-03`
- title: 大结果集聚合选择Sort+GroupAgg导致性能差
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0289.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v3 GROUP BY 聚合查询，`EXPLAIN ANALYZE` 显示 GroupAggregate 耗时约 2417ms，Sort 耗时约 2304ms，峰值内存 26MB。大结果集场景走了 Sort+GroupAgg 组合，想通过 `enable_sort=off` 让优化器切到 HashAgg 提升性能。
- 关键技术信号: EXPLAIN ANALYZE GroupAggregate 2417ms + Sort 2304ms / enable_sort=off
- 期待 LLM 命中: gaussdb-query-slow-groupagg-sort-03

#### 48. case_id: `gaussdb-query-slow-seqscan-no-index-01`
- title: 点查或范围扫描选择SeqScan全表扫描导致查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0290.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v8，点查或范围扫描 SQL 走了 SeqScan 全表扫描，`EXPLAIN ANALYZE` 显示大量行被 Filter 过滤，实际返回行很少，A-time 很高。缺少过滤列上的索引，建索引后切换到 IndexScan 效率大幅提升。
- 关键技术信号: EXPLAIN ANALYZE SeqScan 全表扫描 / 大量行 Filter / 缺索引 / 集中式 v8
- 期待 LLM 命中: gaussdb-query-slow-seqscan-no-index-01

#### 49. case_id: `gaussdb-query-slow-nestloop-large-rowset-01`
- title: 两表Join选择NestLoop但实际行数大导致查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0290.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v8 两表 JOIN 查询，`EXPLAIN ANALYZE` 显示 NestLoop 耗时 27 秒，两张表的实际行数都不小。优化器选了 NestLoop 但行数估算偏小导致。设 `enable_nestloop=off` 和 `enable_mergejoin=off` 后切换到 HashJoin，耗时降到 2 秒。
- 关键技术信号: EXPLAIN ANALYZE NestLoop 27s / enable_nestloop=off / 集中式 v8
- 期待 LLM 命中: gaussdb-query-slow-nestloop-large-rowset-01

#### 50. case_id: `gaussdb-query-slow-sort-groupagg-large-result-01`
- title: 大结果集Agg选择Sort+GroupAgg导致查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0290.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v8，GROUP BY 聚合查询走了 Sort+GroupAgg 组合导致性能差。`EXPLAIN ANALYZE` 可以看到 Sort 和 GroupAggregate 算子。正常情况下 HashAgg 性能更好，需要设 `enable_sort=off` 让优化器改用 HashAgg。
- 关键技术信号: EXPLAIN ANALYZE Sort + GroupAggregate / enable_sort=off / 集中式 v8
- 期待 LLM 命中: gaussdb-query-slow-sort-groupagg-large-result-01

#### 51. case_id: `gaussdb-rewrite-lazyagg-double-aggregate-slow-01`
- title: 子查询与外层有相同GROUP BY时双层聚集运算效率低下
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0318.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v3，外层查询和子查询都对同一列做 GROUP BY + 聚合，`EXPLAIN` 显示两层 HashAggregate 嵌套（子查询有一个 HashAgg，外层又有一个 HashAgg），效率低。开启 `rewrite_rule=lazyagg` 参数可以消除子查询中的冗余聚合运算，提升性能。
- 关键技术信号: EXPLAIN 双层 HashAggregate / 相同 GROUP BY 两层聚合 / rewrite_rule=lazyagg
- 期待 LLM 命中: gaussdb-rewrite-lazyagg-double-aggregate-slow-01

#### 52. case_id: `gaussdb-rewrite-magicset-correlated-subquery-slow-01`
- title: 带聚集算子的相关子查询重复扫描导致性能差
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v3-gaussdb/gaussdb-42-0318.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v3，WHERE 子句里有带聚合函数的相关子查询（如 `t1.c3 < (SELECT sum(c3) FROM t2 WHERE t1.c1=t2.c1)`），执行计划中子查询被重复扫描，性能很差。开启 `rewrite_rule=magicset` 后优化器先对子查询关联字段分组聚合，减少重复扫描。
- 关键技术信号: EXPLAIN 带聚合的相关子查询重复扫描 / rewrite_rule=magicset
- 期待 LLM 命中: gaussdb-rewrite-magicset-correlated-subquery-slow-01

#### 53. case_id: `gaussdb-rewrite-v8-intargetlist-subplan-slow-01`
- title: 集中式v8：目标列相关子查询无法提升（intargetlist）
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v8-gaussdb/gaussdb-42-0321.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v8，SELECT 目标列里有相关子查询，`EXPLAIN VERBOSE` 看到 SubPlan 节点，外表每扫描一行就触发一次子查询执行，效率极低。开启 `rewrite_rule=intargetlist` 后子查询被转化为 JOIN，性能大幅提升。
- 关键技术信号: EXPLAIN VERBOSE SubPlan -> Aggregate -> Seq Scan on t2 / rewrite_rule=intargetlist / 集中式 v8
- 期待 LLM 命中: gaussdb-rewrite-v8-intargetlist-subplan-slow-01

#### 54. case_id: `gaussdb-partition-maxmin-fullscan-01`
- title: 分区表 Max/Min 全分区扫描 + Sort 慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/fg-gaussdb-cent-v8/gaussdb-48-0084.html
- **复现现象** (拷给 skill):
  > GaussDB 分区表做 `SELECT MIN(b) FROM test_range_pt`，`EXPLAIN ANALYZE` 显示走了 Partitioned Seq Scan 全部分区，然后再做 Sort + Limit，性能很差。分区表如果有 LOCAL 索引，理论上可以每个分区只取 Min 再汇总，大幅减少 Sort 开销。
- 关键技术信号: EXPLAIN ANALYZE Partitioned Seq Scan 所有分区 / Sort + Limit / 缺少 LOCAL 索引
- 期待 LLM 命中: gaussdb-partition-maxmin-fullscan-01

#### 55. case_id: `gaussdb-query-slow-agg-plan-mode-01`
- title: 优化器代价估算偏差导致 Agg 计算方式选择不优
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0220.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询里有聚合计算，`EXPLAIN` 显示 Agg 走的执行方式不是最优的，因为中间结果集代价估算误差大，导致 Agg 计算方式的选择偏差。想通过 `best_agg_plan` 参数强制指定更优的 Agg 执行模式（如 `3` 表示 hashagg+redistribute+hashagg）。
- 关键技术信号: EXPLAIN Agg 计算方式不优 / best_agg_plan 参数 / 中间结果代价估算偏差
- 期待 LLM 命中: gaussdb-query-slow-agg-plan-mode-01

#### 56. case_id: `gaussdb-copy-constraint-violation-tolerance-01`
- title: COPY 导入数据存在约束冲突时开启 Level2 容错降低性能
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0074.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式用 COPY 批量导入数据时，由于数据存在主键或唯一约束冲突，需要开启容错。但设置了 `a_format_load_with_constraints_violation='s2'` 后，导入速度明显变慢，因为内部从批量插入退化为逐行插入了。
- 关键技术信号: COPY 导入 / a_format_load_with_constraints_violation='s2' / 批量插入退化为单行插入
- 期待 LLM 命中: gaussdb-copy-constraint-violation-tolerance-01

#### 57. case_id: `gaussdb-query-slow-join-null-values-01`
- title: JOIN 列存在大量 NULL 值导致顺序扫描耗时过长
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0214.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式多表 JOIN 查询，`EXPLAIN ANALYZE` 显示顺序扫描阶段耗时很多。分析发现 JOIN 列 `BSCRNC_ID` 存在大量 NULL 值，这些 NULL 无法参与 JOIN 匹配但仍需扫描，性能差。在 WHERE 子句里手动加 `BSCRNC_ID IS NOT NULL` 条件能有效过滤。
- 关键技术信号: EXPLAIN SeqScan 耗时多 / JOIN 列大量 NULL / 手动加 IS NOT NULL 条件
- 期待 LLM 命中: gaussdb-query-slow-join-null-values-01

#### 58. case_id: `gaussdb-missing-index-multi-join-05`
- title: 多表 JOIN 中缺少连接列索引导致点查询走 seqscan
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/136251205
- **复现现象** (拷给 skill):
  > GaussDB 多表关联查询，`EXPLAIN` 显示连接列（如 `place_id`、`state_id`）上走了 SeqScan 全表扫描，而非 IndexScan。这些列没有建索引，大数据量下点查很慢。在这些 JOIN 列上建索引后，执行计划切换到 IndexScan 性能大幅提升。
- 关键技术信号: EXPLAIN JOIN 列走 SeqScan / 连接列缺索引 / 多表 JOIN
- 期待 LLM 命中: gaussdb-missing-index-multi-join-05

#### 59. case_id: `gaussdb-query-slow-nestloop-any-clause-01`
- title: any-clause 导致不等值 Join 走 NestLoop，大数据量超 1 小时未返回
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0223.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询里用了 `= ANY(...)` 语法，实际上 JOIN 条件是不等式，`EXPLAIN` 显示必须走 NestLoop，两表数据量都很大，查询超过 1 小时都没返回结果。需要改写 SQL 消除 any-clause，让 JOIN 走更高效的 HashJoin。
- 关键技术信号: EXPLAIN NestLoop 不等值 JOIN / any-clause / 超时未返回 / 改写为 HashJoin
- 期待 LLM 命中: gaussdb-query-slow-nestloop-any-clause-01

#### 60. case_id: `gaussdb-plan-suboptimal-seqscan-no-index-01`
- title: 全表顺序扫描过滤大量数据导致查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0189.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式，一个带过滤条件的查询走了 SeqScan，`EXPLAIN ANALYZE` 显示 `Rows Removed by Filter` 接近 500 万行，实际返回行很少，从 3.6 秒降到 13ms 只需在过滤列上加索引。优化器没有自动选 IndexScan。
- 关键技术信号: EXPLAIN ANALYZE SeqScan / Rows Removed by Filter 约 500 万 / 分布式缺索引
- 期待 LLM 命中: gaussdb-plan-suboptimal-seqscan-no-index-01

#### 61. case_id: `gaussdb-plan-suboptimal-nestloop-large-table-01`
- title: 大表 Join 使用 NestLoop 导致查询极慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0189.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式大表之间的 JOIN 走了 NestLoop，`EXPLAIN ANALYZE` 显示耗时 181 秒。关闭 `enable_nestloop=off` 和 `enable_mergejoin=off` 后优化器选择了 HashJoin，耗时降到 200 多毫秒。大表场景 NestLoop 性能极差。
- 关键技术信号: EXPLAIN ANALYZE NestLoop 181s / enable_nestloop=off / enable_mergejoin=off
- 期待 LLM 命中: gaussdb-plan-suboptimal-nestloop-large-table-01

#### 62. case_id: `gaussdb-plan-suboptimal-groupagg-sort-01`
- title: GROUP BY 生成 Sort+GroupAgg 导致查询慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0189.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 GROUP BY 聚合查询，`EXPLAIN ANALYZE` 显示生成了 Sort+GroupAgg 组合，大结果集场景性能很差。通常 HashAgg 性能更好，设 `enable_sort=off` 后优化器改用 HashAgg，性能明显优于 Sort+GroupAgg。
- 关键技术信号: EXPLAIN ANALYZE Sort + GroupAgg / enable_sort=off / 分布式 GROUP BY
- 期待 LLM 命中: gaussdb-plan-suboptimal-groupagg-sort-01

#### 63. case_id: `gaussdb-overall-slow-config-shared-buffers-01`
- title: 数据库配置不优 (shared_buffers / work_mem / thread_pool_attr) 导致整体性能慢
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://blog.csdn.net/GaussDB/article/details/131321486
- **复现现象** (拷给 skill):
  > GaussDB 整体性能慢，但单条 SQL 看起来执行计划没问题。怀疑是 GUC 参数配置不优：`shared_buffers` 过小导致 buffer 淘汰频繁，`work_mem` 太小算子频繁落盘，或者 `thread_pool_attr` 线程数设太小业务在排队。
- 关键技术信号: shared_buffers / work_mem / thread_pool_attr / buffer 淘汰频繁 / 算子落盘
- 期待 LLM 命中: gaussdb-overall-slow-config-shared-buffers-01

#### 64. case_id: `gaussdb-query-slow-partition-pruning-disabled-function-01`
- title: 分区表过滤条件含非常量表达式，分区剪枝失效，全表扫描耗时 135s
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0222.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式分区表查询，耗时达 135 秒。`EXPLAIN` 显示 Filter 条件里包含 `to_char(add_months(to_date(...), -11), 'yyyymm')` 这类非常量表达式，`pg_proc` 显示这两个函数是 STABLE 类型，不能在预处理阶段转为常量，导致分区剪枝失效，全量扫描所有分区。
- 关键技术信号: EXPLAIN Filter 非常量表达式 / 分区剪枝失效 / stable 函数 / 全部分区扫描 135s
- 期待 LLM 命中: gaussdb-query-slow-partition-pruning-disabled-function-01

#### 65. case_id: `gaussdb-procedure-exception-frequent-perf-degrade-01`
- title: 存储过程频繁捕获和处理异常导致性能下降
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0058.html
- **复现现象** (拷给 skill):
  > GaussDB 存储过程里大量使用 EXCEPTION 块来容错，每次捕获异常都涉及上下文的创建和销毁。业务高峰期频繁触发异常时存储过程性能明显下降，内存和资源消耗也增加，且异常被捕获后日志里不会记录错误，定位困难。
- 关键技术信号: 存储过程 EXCEPTION 块频繁触发 / 上下文创建销毁开销 / 性能下降
- 期待 LLM 命中: gaussdb-procedure-exception-frequent-perf-degrade-01

#### 66. case_id: `gaussdb-query-slow-scan-no-local-cluster-key-01`
- title: 表 Scan 为性能瓶颈，过滤列无局部聚簇键
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0218.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式用 `EXPLAIN PERFORMANCE` 分析某查询，发现两个性能瓶颈点都在表 Scan 算子，Filter 条件是 `acct_id = 'A012709548'` 这样的列过滤。这两个表的 `acct_id` 列没有局部聚簇键，数据物理上不聚集，导致 Scan 过滤效率很低。
- 关键技术信号: EXPLAIN PERFORMANCE Scan 是瓶颈 / filter 列无局部聚簇键 / VACUUM FULL 生效
- 期待 LLM 命中: gaussdb-query-slow-scan-no-local-cluster-key-01

#### 67. case_id: `gaussdb-query-slow-windowagg-sort-on-cn-01`
- title: WindowAgg 与 Sort 全在 CN 端执行，占总执行时间 95% 以上
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0215.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式查询里有窗口函数（Window Agg），`EXPLAIN` 显示 WindowAgg 和 Sort 算子全部在 CN 端执行，占总执行时间 95% 以上，DN 节点几乎空闲，系统资源没被充分利用，查询性能很差。需要改写 SQL 让 Sort 能下推到 DN。
- 关键技术信号: EXPLAIN WindowAgg + Sort 在 CN 端 / 占总执行时间 95% / Sort 无法下推
- 期待 LLM 命中: gaussdb-query-slow-windowagg-sort-on-cn-01

#### 68. case_id: `gaussdb-group-by-sort-perf-work-mem-01`
- title: GROUP BY 产生 Sort 算子时通过增大 work_mem 生成 HashAgg 提升性能
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0013.html
- **复现现象** (拷给 skill):
  > GaussDB GROUP BY 聚合查询执行计划包含 GroupAgg+Sort，性能较差。尝试通过增大 `work_mem` 让优化器有足够内存建 HashAgg 的 hash table，从而避免排序操作。但不确定要设到多大，以及增大 work_mem 会不会影响其他查询。
- 关键技术信号: EXPLAIN GroupAgg+Sort / work_mem 不足 / HashAgg 需要更大内存
- 期待 LLM 命中: gaussdb-group-by-sort-perf-work-mem-01

#### 69. case_id: `gaussdb-not-in-to-not-exists-rewrite-01`
- title: NOT IN 转换为 NOT EXISTS 通过 Hash Anti Join 提升查询效率
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-23-0013.html
- **复现现象** (拷给 skill):
  > GaussDB 查询里用了 `NOT IN (SELECT ...)` 子查询，`EXPLAIN` 显示走了 NESTLOOP ANTI JOIN 性能很差。子查询目标列没有 NULL 值（声明了 NOT NULL），在这种情况下 NOT IN 和 NOT EXISTS 语义等价，改成 NOT EXISTS 后计划切换到 HASH ANTI JOIN，性能明显提升。
- 关键技术信号: EXPLAIN NESTLOOP ANTI JOIN / NOT IN 子查询 / 改为 NOT EXISTS + HASH ANTI JOIN
- 期待 LLM 命中: gaussdb-not-in-to-not-exists-rewrite-01

#### 70. case_id: `gaussdb-statement-not-shippable-cn-bottleneck-01`
- title: 含不可下推函数/语法的查询导致 CN 成为性能瓶颈
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v8-gaussdb/gaussdb-12-0264.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 v8 查询里包含了不可下推的函数或语法，`EXPLAIN` 显示 `Data Node Scan on` 在第一行，语句没有下推给 DN 执行，大量中间结果从 DN 发到 CN 再计算，CN 成了带宽和计算瓶颈。检查 `enable_fast_query_shipping` 参数是否开启，以及是否能改写 SQL 规避不可下推语法。
- 关键技术信号: EXPLAIN Data Node Scan 在第一行 / enable_fast_query_shipping / CN 成瓶颈
- 期待 LLM 命中: gaussdb-statement-not-shippable-cn-bottleneck-01

#### 71. case_id: `gaussdb-query-slow-subplan-correlated-subquery-01`
- title: 执行计划中存在 SubPlan+Broadcast，相关子查询性能差
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/distributed-devg-v2-gaussdb/gaussdb-12-0221.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式 SQL 性能很差，`EXPLAIN` 显示执行计划里存在 SubPlan 节点。分析发现子查询使用 `ca_address_sk` 关联，而 `ca_address_sk` 实际上不为 null，可以等价改写 SQL 消除子查询，转为 JOIN 来大幅提升性能。
- 关键技术信号: EXPLAIN SubPlan 节点 / 相关子查询 / 改写消除子查询转为 JOIN
- 期待 LLM 命中: gaussdb-query-slow-subplan-correlated-subquery-01

#### 72. case_id: `gaussdb-rewrite-intargetlist-subplan-slow-01`
- title: 目标列相关子查询无法提升导致每行触发SubPlan执行，查询性能低下
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v2-gaussdb/gaussdb_42_0258.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v2，SELECT 目标列里包含相关子查询，`EXPLAIN VERBOSE` 显示 `SubPlan 1 -> Aggregate -> Seq Scan on t2 Filter: (t2.c2 = t1.c2)`，每扫描 t1 的一行就触发一次子查询，效率低。开启 `rewrite_rule=intargetlist` 后子查询提升转为 JOIN，性能明显改善。
- 关键技术信号: EXPLAIN SubPlan -> Aggregate -> Seq Scan Filter t2.c2=t1.c2 / rewrite_rule=intargetlist
- 期待 LLM 命中: gaussdb-rewrite-intargetlist-subplan-slow-01

#### 73. case_id: `gaussdb-rewrite-uniquecheck-subquery-join-01`
- title: 无agg子查询无法自动提升导致子链接重复执行
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/centralized-devg-v2-gaussdb/gaussdb_42_0258.html
- **复现现象** (拷给 skill):
  > GaussDB 集中式 v2，WHERE 条件里有无聚合函数的相关子查询（如 `t1.c1 = (SELECT t2.c1 FROM t2 WHERE t1.c1=t2.c1)`），`EXPLAIN VERBOSE` 显示计划里有 `Unique Check Required`，子链接重复执行性能差。开启 `rewrite_rule=uniquecheck` 可以把子查询提升为 JOIN。
- 关键技术信号: EXPLAIN Unique Check Required / 无 agg 相关子查询 / rewrite_rule=uniquecheck
- 期待 LLM 命中: gaussdb-rewrite-uniquecheck-subquery-join-01

---

### replica-lag (1 个)

#### 74. case_id: `gaussdb-replica-lag-redo-workers-01`
- title: GaussDB业务压力大时备DN回放速度跟不上主DN，日志累积影响RTO
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/gaussdb_faq/gaussdb_01_401.html
- **复现现象** (拷给 skill):
  > GaussDB 分布式业务压力大时，备 DN 的 redo 回放速度跟不上主 DN 的写入速度，日志持续累积，RTO（恢复时间目标）变长，主 DN 故障时切换需要等待很长时间。备 DN 的 CPU 和 I/O 利用率超过 70%。想通过 `recovery_parse_workers` 和 `recovery_redo_workers` 参数开启极致 RTO 提升回放并行度。
- 关键技术信号: 备 DN 回放速度慢 / recovery_parse_workers / recovery_redo_workers / 极致 RTO
- 期待 LLM 命中: gaussdb-replica-lag-redo-workers-01

---

### other (3 个)

#### 75. case_id: `gaussdb-perf-jitter-asp-analysis-01`
- title: GaussDB性能抖动——通过ASP/WDR定位抖动根因
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://www.modb.pro/db/1881247803599499264/
- **复现现象** (拷给 skill):
  > GaussDB 数据库出现秒级性能抖动，P95 响应时间偶发性飙高，但持续时间短，事后看 WDR 报告很难定位。想查 `dbe_perf.local_active_session`（ASP 内存视图）分析抖动时间点的异常等待事件和高频 SQL，或者查 `gs_asp` 物理表追溯两天内的历史。
- 关键技术信号: 秒级性能抖动 / dbe_perf.local_active_session / gs_asp / 等待事件分析
- 期待 LLM 命中: gaussdb-perf-jitter-asp-analysis-01

#### 77. case_id: `gaussdb-alert-thresholds-01`
- title: GaussDB 指标告警配置建议 (CES 阈值基线)
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb_practice_0071.html
- **复现现象** (拷给 skill):
  > 想给 GaussDB 在云监控（CES）上配置合理的告警阈值基线，目前不确定 CPU 使用率、内存使用率、磁盘 IO 带宽、IOPS、P80/P95 响应时间、慢 SQL 数量、动态内存使用率等指标各应该设什么阈值，以及应该连续几个周期超标才触发告警。
- 关键技术信号: CES 告警阈值 / rds001_cpu_util > 80% / rds002_mem_util > 90% / rds048_P80 / rds049_P95
- 期待 LLM 命中: gaussdb-alert-thresholds-01

#### 76. case_id: `gaussdb-procedure-security-definer-permission-01`
- title: 存储过程权限模式选择不当导致越权或被拒访问
- entry_kind / case_pattern: diagnostic-flow / core-perf-diagnosis
- source_url: https://support.huaweicloud.com/bestpractice-gaussdb/gaussdb-22-0051.html
- **复现现象** (拷给 skill):
  > GaussDB 存储过程默认使用 SECURITY INVOKER 权限（调用者权限），另一个用户执行时报错"对表没有权限"。想改为 SECURITY DEFINER 模式（创建者权限），但担心有越权风险。想了解 `behavior_compat_options='plsql_security_definer'` 这个参数的使用场景和风险。
- 关键技术信号: 存储过程 SECURITY INVOKER vs SECURITY DEFINER / behavior_compat_options=plsql_security_definer
- 期待 LLM 命中: gaussdb-procedure-security-definer-permission-01

---

## 索引 (按 case_id 字母序)

| # | case_id | symptom_category | 期待命中 (= case_id 本身) |
|---|---|---|---|
| 1 | gaussdb-alert-thresholds-01 | other | ✓ |
| 2 | gaussdb-copy-constraint-violation-tolerance-01 | query-slow | ✓ |
| 3 | gaussdb-cpu-high-connection-timezone-01 | cpu-high | ✓ |
| 4 | gaussdb-cpu-high-statement-view-01 | cpu-high | ✓ |
| 5 | gaussdb-cpu-high-topsql-01 | cpu-high | ✓ |
| 6 | gaussdb-cpu-saturated-by-slowsql-06 | cpu-high | ✓ |
| 7 | gaussdb-data-skew-compute-redistribute-01 | data-skew | ✓ |
| 8 | gaussdb-data-skew-hashjoin-dn-compute-skew-01 | data-skew | ✓ |
| 9 | gaussdb-data-skew-storage-distribution-01 | data-skew | ✓ |
| 10 | gaussdb-disk-io-high-statement-view-01 | disk-io-saturation | ✓ |
| 11 | gaussdb-disk-space-pressure-storage-skew-locate-01 | disk-space-pressure | ✓ |
| 12 | gaussdb-dist-disk-full-storage-skew-01 | disk-space-pressure | ✓ |
| 13 | gaussdb-dist-routine-skew-inspection-01 | data-skew | ✓ |
| 14 | gaussdb-dist-v3-volatile-func-not-pushed-slow-01 | cpu-high | ✓ |
| 15 | gaussdb-dist-volatile-func-not-pushed-slow-01 | cpu-high | ✓ |
| 16 | gaussdb-distribution-key-skew-xc-node-id-25 | data-skew | ✓ |
| 17 | gaussdb-dws-distkey-choice-01 | plan-suboptimal | ✓ |
| 18 | gaussdb-dws-plan-suboptimal-planhint-01 | plan-suboptimal | ✓ |
| 19 | gaussdb-group-by-sort-perf-work-mem-01 | query-slow | ✓ |
| 20 | gaussdb-groupagg-sort-vs-hashagg-08 | plan-suboptimal | ✓ |
| 21 | gaussdb-memory-pressure-node-detail-01 | memory-pressure | ✓ |
| 22 | gaussdb-memory-shared-buffer-miss-01 | memory-pressure | ✓ |
| 23 | gaussdb-memory-work-mem-spill-01 | memory-pressure | ✓ |
| 24 | gaussdb-missing-index-multi-join-05 | query-slow | ✓ |
| 25 | gaussdb-not-in-to-not-exists-rewrite-01 | query-slow | ✓ |
| 26 | gaussdb-overall-slow-config-shared-buffers-01 | query-slow | ✓ |
| 27 | gaussdb-overall-slow-cpu-high-01 | cpu-high | ✓ |
| 28 | gaussdb-overall-slow-io-await-high-01 | disk-io-saturation | ✓ |
| 29 | gaussdb-package-variable-session-memory-01 | memory-pressure | ✓ |
| 30 | gaussdb-partition-maxmin-fullscan-01 | query-slow | ✓ |
| 31 | gaussdb-perf-jitter-asp-analysis-01 | other | ✓ |
| 32 | gaussdb-plan-suboptimal-anti-join-row-estimate-01 | plan-suboptimal | ✓ |
| 33 | gaussdb-plan-suboptimal-correlated-filter-selectivity-01 | plan-suboptimal | ✓ |
| 34 | gaussdb-plan-suboptimal-groupagg-sort-01 | query-slow | ✓ |
| 35 | gaussdb-plan-suboptimal-missing-analyze-01 | plan-suboptimal | ✓ |
| 36 | gaussdb-plan-suboptimal-missing-analyze-dist-v8-01 | plan-suboptimal | ✓ |
| 37 | gaussdb-plan-suboptimal-nestloop-large-outer-01 | plan-suboptimal | ✓ |
| 38 | gaussdb-plan-suboptimal-nestloop-large-table-01 | query-slow | ✓ |
| 39 | gaussdb-plan-suboptimal-nestloop-large-table-unlogged-01 | plan-suboptimal | ✓ |
| 40 | gaussdb-plan-suboptimal-row-estimate-broadcast-01 | query-slow | ✓ |
| 41 | gaussdb-plan-suboptimal-seqscan-no-index-01 | query-slow | ✓ |
| 42 | gaussdb-plan-suboptimal-seqscan-vs-indexscan-01 | plan-suboptimal | ✓ |
| 43 | gaussdb-plan-suboptimal-sort-groupagg-vs-hashagg-01 | plan-suboptimal | ✓ |
| 44 | gaussdb-plan-suboptimal-statistics-change-plan-regression-01 | plan-suboptimal | ✓ |
| 45 | gaussdb-procedure-exception-frequent-perf-degrade-01 | query-slow | ✓ |
| 46 | gaussdb-procedure-security-definer-permission-01 | other | ✓ |
| 47 | gaussdb-query-slow-agg-plan-mode-01 | query-slow | ✓ |
| 48 | gaussdb-query-slow-complex-join-intermediate-rows-01 | query-slow | ✓ |
| 49 | gaussdb-query-slow-correlated-subquery-target-list-01 | query-slow | ✓ |
| 50 | gaussdb-query-slow-groupagg-sort-03 | query-slow | ✓ |
| 51 | gaussdb-query-slow-join-null-values-01 | query-slow | ✓ |
| 52 | gaussdb-query-slow-missing-analyze-01 | plan-suboptimal | ✓ |
| 53 | gaussdb-query-slow-missing-statistics-explain-verbose-01 | plan-suboptimal | ✓ |
| 54 | gaussdb-query-slow-nestloop-any-clause-01 | query-slow | ✓ |
| 55 | gaussdb-query-slow-nestloop-hashjoin-02 | query-slow | ✓ |
| 56 | gaussdb-query-slow-nestloop-large-rowset-01 | query-slow | ✓ |
| 57 | gaussdb-query-slow-no-partial-pushdown-01 | query-slow | ✓ |
| 58 | gaussdb-query-slow-partition-pruning-disabled-function-01 | query-slow | ✓ |
| 59 | gaussdb-query-slow-scan-no-local-cluster-key-01 | query-slow | ✓ |
| 60 | gaussdb-query-slow-seqscan-index-missing-01 | query-slow | ✓ |
| 61 | gaussdb-query-slow-seqscan-no-index-01 | query-slow | ✓ |
| 62 | gaussdb-query-slow-sort-groupagg-large-result-01 | query-slow | ✓ |
| 63 | gaussdb-query-slow-subplan-correlated-subquery-01 | query-slow | ✓ |
| 64 | gaussdb-query-slow-windowagg-sort-on-cn-01 | query-slow | ✓ |
| 65 | gaussdb-replica-lag-redo-workers-01 | replica-lag | ✓ |
| 66 | gaussdb-rewrite-intargetlist-subplan-slow-01 | query-slow | ✓ |
| 67 | gaussdb-rewrite-lazyagg-double-aggregate-slow-01 | query-slow | ✓ |
| 68 | gaussdb-rewrite-magicset-correlated-subquery-slow-01 | query-slow | ✓ |
| 69 | gaussdb-rewrite-rule-partialpush-13 | plan-suboptimal | ✓ |
| 70 | gaussdb-rewrite-uniquecheck-subquery-join-01 | query-slow | ✓ |
| 71 | gaussdb-rewrite-v8-intargetlist-subplan-slow-01 | query-slow | ✓ |
| 72 | gaussdb-savepoint-in-loop-resource-leak-01 | memory-pressure | ✓ |
| 73 | gaussdb-seqscan-without-index-slow-01 | query-slow | ✓ |
| 74 | gaussdb-stale-stats-hint-fix-09 | plan-suboptimal | ✓ |
| 75 | gaussdb-statement-not-shippable-cn-bottleneck-01 | query-slow | ✓ |
| 76 | gaussdb-plan-suboptimal-rewrite-rule-intargetlist-01 | plan-suboptimal | ✓ |
| 77 | gaussdb-plan-suboptimal-rewrite-rule-partialpush-01 | plan-suboptimal | ✓ |
