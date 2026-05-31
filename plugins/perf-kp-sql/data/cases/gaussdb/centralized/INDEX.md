# Cases Index

> 生成时间: 2026-05-31T02:56:50.456Z
> 数据源: distill-v2/cases/<db>/diagnostic-flow/*.md + runtime baseline 合并
> 总计: 8 cases
> 配套: gaussdb/centralized/CASES.md

| case_id | symptom_category | title | 行号 |
|---|---|---|---:|
| gaussdb-lock-contention-x12 | lock-contention | GaussDB中长事务及阻塞排查诊断 | 3 |
| gaussdb-plan-suboptimal-x17 | plan-suboptimal | GaussDB统计信息不准导致查询变慢 | 85 |
| gaussdb-other-tps-x19 | other | GaussDB主备切换后TPS性能劣化16% | 155 |
| gaussdb-memory-pressure-other-x28 | memory-pressure | GaussDB other内存持续缓慢增长导致主备切换诊断 | 216 |
| gaussdb-query-slow-missing-statistics-explain-verbose-01 | plan-suboptimal | 未收集统计信息导致查询性能差（集中式v3） | 277 |
| gaussdb-rewrite-v8-intargetlist-subplan-slow-01 | query-slow | 集中式v8：目标列相关子查询无法提升（intargetlist） | 331 |
| gaussdb-copy-constraint-violation-tolerance-01 | query-slow | COPY 导入数据存在约束冲突时开启 Level2 容错降低性能 | 379 |
| gaussdb-plan-suboptimal-missing-analyze-01 | plan-suboptimal | 未收集统计信息导致查询性能差（集中式GaussDB） | 433 |
