# GaussDB 集中式 · 性能问题构造场景集(手动复现用)

> 在 **主机(primary)** 上以 DB 用户跑(statement_history 是 unlogged 表,仅主机可读)。
> 测试环境约定:`source ~/gauss_env_file; export PGPORT=37000`(gauss_new 集中式)。
> 慢 SQL 阈值由 `log_min_duration_statement`(=3s)/ `track_stmt_stat_level`(L1,L1)控制。
> 全部用 UNLOGGED / 临时表,跑完见末尾「清理」。

## 0. 看采集结果(慢 SQL 通用查询)

每跑完一个场景,等 ~3s 刷盘,用这条看它落到 statement_history 的根因信号:

```sql
-- 最近 5 分钟、内核标记的慢 SQL,带 plan + 解码等待事件
SELECT substr(query,1,60) AS q, round(execution_time/1e6,2) AS exec_s, round(cpu_time/1e6,2) AS cpu_s,
       round(data_io_time/1000.0,1) AS io_ms, round(lock_wait_time/1000.0,1) AS lockwait_ms,
       (n_blocks_fetched-n_blocks_hit) AS phys_read,
       statement_detail_decode(details,'plaintext',true) AS wait_events, query_plan
FROM statement_history
WHERE is_slow_sql AND start_time > now() - interval '5 min'
ORDER BY start_time DESC LIMIT 10;
```
> `gsql -x -d postgres -c "..."` 宽行展开看更清楚。

## 1. 基表(一次建好,后续场景复用)

```sql
DROP TABLE IF EXISTS t_big; DROP TABLE IF EXISTS t_dim;
CREATE UNLOGGED TABLE t_big AS SELECT g AS id,(g%1000) AS grp, md5(g::text) AS val FROM generate_series(1,10000000) g;
CREATE UNLOGGED TABLE t_dim AS SELECT g AS id, md5(g::text) AS d FROM generate_series(1,40000) g;
ANALYZE t_big; ANALYZE t_dim;
-- 分区表(整数范围分区,避开 A 兼容日期格式问题)
DROP TABLE IF EXISTS t_part;
CREATE TABLE t_part (id int, grp int, val text)
PARTITION BY RANGE (id) (PARTITION p1 VALUES LESS THAN (3000000), PARTITION p2 VALUES LESS THAN (6000000),
                        PARTITION p3 VALUES LESS THAN (9000000), PARTITION p4 VALUES LESS THAN (MAXVALUE));
INSERT INTO t_part SELECT g, g%500, md5(g::text) FROM generate_series(1,12000000) g; ANALYZE t_part;
-- 大行表(> shared_buffers,用于物理读)
DROP TABLE IF EXISTS t_io;
CREATE UNLOGGED TABLE t_io AS SELECT g id, repeat(md5(g::text),3) AS pad FROM generate_series(1,15000000) g;
```

## 2. 慢 SQL 类场景(gsql 跑完看第 0 节)

```sql
SET statement_timeout='120s';   -- 防跑飞

-- [1] 全表扫无索引(SeqScan)→ gaussdb-query-slow-seqscan-no-index-01
SELECT count(*) FROM t_big WHERE md5(val) LIKE '%zz%';
-- 期望: plan=Seq Scan; wait=wait seq scan; cpu≈exec

-- [2] Sort+GroupAgg 落盘 → gaussdb-query-slow-groupagg-sort-03
SET enable_hashagg=off; SELECT grp,count(*) FROM t_big GROUP BY grp; RESET enable_hashagg;
-- 期望: plan=GroupAggregate→Sort→Seq Scan; wait=Sort - write file

-- [3] work_mem 过小排序落盘 → gaussdb-memory-work-mem-spill-01
SET work_mem='128kB'; SELECT val FROM t_big ORDER BY val OFFSET 9999000 LIMIT 5; RESET work_mem;
-- 期望: io_ms 高; wait=Sort - write file + buffile_write/read

-- [4] 强制 NestLoop → gaussdb-query-slow-nestloop-hashjoin-02
SET enable_hashjoin=off; SET enable_mergejoin=off;
SELECT count(*) FROM t_dim a JOIN (SELECT * FROM t_dim LIMIT 4000) b ON a.d=b.d;
RESET enable_hashjoin; RESET enable_mergejoin;
-- 期望: plan=Nested Loop; cpu≈exec

-- [5] 大表 Hash Join 建大哈希 → gaussdb-query-slow-complex-join-intermediate-rows-01
SELECT count(*) FROM t_big a JOIN t_big b ON a.id=b.id;
-- 期望: plan=Hash Join→Hash(build 10M); wait=HashJoin - build hash + buffile_write

-- [6] count(distinct) 大聚合 → gaussdb-query-slow-sort-groupagg-large-result-01
SELECT grp,count(distinct val) FROM t_big GROUP BY grp;

-- [7] NOT IN 反连接 → gaussdb-not-in-to-not-exists-rewrite-01
SELECT count(*) FROM t_big WHERE val NOT IN (SELECT d FROM t_dim);
-- 期望: plan=Seq Scan · Filter: NOT (hashed SubPlan 1)

-- [8] 笛卡尔积/不等值 NestLoop → gaussdb-query-slow-nestloop-any-clause-01
SELECT count(*) FROM (SELECT * FROM t_dim LIMIT 25000) a,(SELECT * FROM t_dim LIMIT 25000) b WHERE a.id<>b.id;
-- 期望: plan=Nested Loop · Join Filter id<>id · 估算行数巨大

-- [9] 深分页 OFFSET → 深分页反模式
SELECT id FROM t_big ORDER BY id OFFSET 9999900 LIMIT 10;
-- 期望: plan=Limit→Sort→Seq Scan(排序全表丢弃前千万行)

-- [10] UNION 去重 → 建议 UNION ALL
SELECT count(*) FROM (SELECT val FROM t_big UNION SELECT d FROM t_dim) u;
-- 期望: plan=HashAggregate Group By val→Append; wait=HashAgg build hash

-- [11] GROUP BY 表达式 → 无法走索引,全表 HashAgg
SELECT substr(val,1,2) k,count(*) FROM t_big GROUP BY substr(val,1,2);

-- [12] 分区剪枝失效(分区键套函数)→ gaussdb-query-slow-partition-pruning-disabled-function-01
EXPLAIN (costs off) SELECT count(*) FROM t_part WHERE abs(id)=5000000;  -- 看 Iterations:4 / Selected Partitions:1..4
SELECT count(*) FROM t_part WHERE abs(id)=5000000;

-- [13] 分区 Max/Min 全分区扫 → gaussdb-partition-maxmin-fullscan-01
SELECT max(md5(val)),min(md5(val)) FROM t_part;
-- 期望: plan=Partition Iterator Iterations:4 Selected Partitions:1..4

-- [14] Anti Join 自连接 → gaussdb-plan-suboptimal-anti-join-row-estimate-01
SELECT count(*) FROM t_big a WHERE NOT EXISTS (SELECT 1 FROM t_big b WHERE b.grp=a.grp AND b.id>a.id);
-- 期望: plan=Hash Anti Join; 估算 rows 偏差

-- [15] 缺统计 + NULL 列 join → missing-analyze + join-null-values
DROP TABLE IF EXISTS t_null;
CREATE UNLOGGED TABLE t_null AS SELECT g id, CASE WHEN g%100=0 THEN md5(g::text) ELSE NULL END jk FROM generate_series(1,10000000) g;
SELECT count(*) FROM t_null a LEFT JOIN t_dim b ON a.jk=b.d;   -- 不 analyze: plan 估算 rows 偏差 + jk 大量 NULL
```

## 3. 编排类场景(shell · 需 root/并发/多会话)

```bash
# --- [16] 物理读高 / IO await(disk-io-high / overall-slow-io-await-high)---
# 后台 dd 打满 vdb 写 IO + drop_caches 逼 DB 走盘 + 并发物理读;跑完删文件恢复
sync; echo 3 > /proc/sys/vm/drop_caches
dd if=/dev/zero of=/data/iostress_1 bs=1M count=4000 oflag=direct status=none &
dd if=/dev/zero of=/data/iostress_2 bs=1M count=4000 oflag=direct status=none &
su - Ruby -c 'source ~/gauss_env_file; export PGPORT=37000; gsql -d postgres -c "SELECT count(*) FROM t_io WHERE id=-2;"'
wait; rm -f /data/iostress_1 /data/iostress_2
# 期望(第0节看): data_io_ms 高 + wait=DataFileRead + phys_read 高(命中率低)

# --- [17] 整体 CPU 打满(overall-slow-cpu-high / cpu-saturated-by-slowsql / cpu-high-topsql)---
echo "SELECT count(*) FROM t_big WHERE md5(val) LIKE '%zz%';" > /tmp/burner.sql
su - Ruby -c 'source ~/gauss_env_file; export PGPORT=37000; cp /tmp/burner.sql ~/
  for i in $(seq 1 8); do gsql -d postgres -f ~/burner.sql >/dev/null 2>&1 & done
  sleep 3; top -bn1 | grep -E "%Cpu|gaussdb" | head -5
  gsql -d postgres -c "SELECT substr(query,1,42) q,n_calls,round(cpu_time/1e6,2) cpu_s FROM dbe_perf.statement ORDER BY cpu_time DESC LIMIT 5;"
  wait'
# 期望: top %Cpu us 接近满 + gaussdb 进程 CPU 几百%; dbe_perf.statement 按 cpu_time 排出元凶

# --- [18] 行锁等待(lock-contention)---
su - Ruby -c 'source ~/gauss_env_file; export PGPORT=37000
  gsql -d postgres -c "DROP TABLE IF EXISTS t_lock; CREATE UNLOGGED TABLE t_lock(id int primary key,v int); INSERT INTO t_lock VALUES (1,0);"
  nohup gsql -d postgres -c "BEGIN; UPDATE t_lock SET v=v+1 WHERE id=1; SELECT pg_sleep(12); COMMIT;" >/dev/null 2>&1 &
  sleep 2; gsql -d postgres -c "UPDATE t_lock SET v=v+1 WHERE id=1;"   # 阻塞 ~10s
  wait'
# 期望(第0节看): lockwait_ms≈10000 + cpu=0 + wait=LOCK_EVENT transactionid

# --- [19] PL 存储过程频繁异常(procedure-exception-frequent-perf-degrade)---
su - Ruby -c 'source ~/gauss_env_file; export PGPORT=37000; gsql -d postgres <<SQL
CREATE OR REPLACE FUNCTION f_exc() RETURNS int AS \$\$ DECLARE n int:=0;
BEGIN FOR i IN 1..300000 LOOP BEGIN PERFORM 1/0; EXCEPTION WHEN division_by_zero THEN n:=n+1; END; END LOOP; RETURN n; END; \$\$ LANGUAGE plpgsql;
SELECT f_exc();
SQL'
# 期望: pl_execution_time≈exec_time + plan 仅 Result(瓶颈在过程逻辑非算子)

# --- [20] 复制延迟(replica-lag-redo-workers)· 主备 HA ---
# 在某 standby 暂停回放 + 主机灌 WAL,看 replay_lag 涨,再 resume 归零
ssh <standby-host> 'su - Ruby -c "source ~/gauss_env_file; export PGPORT=37000; gsql -d postgres -tc \"SELECT pg_xlog_replay_pause();\""'
su - Ruby -c 'source ~/gauss_env_file; export PGPORT=37000
  gsql -d postgres -c "DROP TABLE IF EXISTS t_wal; CREATE TABLE t_wal(id int,pad text); INSERT INTO t_wal SELECT g,repeat(md5(g::text),5) FROM generate_series(1,3000000) g;"
  gsql -d postgres -c "SELECT client_addr,pg_xlog_location_diff(sender_sent_location,receiver_replay_location) AS replay_lag FROM pg_stat_replication ORDER BY client_addr;"'
ssh <standby-host> 'su - Ruby -c "source ~/gauss_env_file; export PGPORT=37000; gsql -d postgres -tc \"SELECT pg_xlog_replay_resume();\""'
# 期望: 暂停的 standby replay_lag 涨到几百 MB,resume 后归 ~0
```

## 4. 非慢-SQL 类(参数/指标审计 · 直接采当前值比对)

```sql
-- 内存/配置审计 → shared-buffer-miss / config-shared-buffers
SELECT round(sum(blks_hit)*100.0/nullif(sum(blks_hit)+sum(blks_read),0),2) AS buffer_hit_pct FROM pg_stat_database; -- <99% 即内存压力
SHOW shared_buffers; SHOW work_mem; SHOW effective_cache_size;  -- 对比机器内存判是否偏小
-- 连接/会话
SELECT state,count(*) FROM pg_stat_activity GROUP BY state;
-- 复制健康
SELECT client_addr,state,sync_state,pg_xlog_location_diff(sender_sent_location,receiver_replay_location) AS replay_lag FROM pg_stat_replication;
```

## 5. 清理

```sql
DROP TABLE IF EXISTS t_big; DROP TABLE IF EXISTS t_dim; DROP TABLE IF EXISTS t_part;
DROP TABLE IF EXISTS t_io; DROP TABLE IF EXISTS t_null; DROP TABLE IF EXISTS t_lock; DROP TABLE IF EXISTS t_wal;
DROP FUNCTION IF EXISTS f_exc();
```
```bash
rm -f /data/iostress_* /tmp/burner.sql ~Ruby/burner.sql
```

## 备注
- **优化器躲得掉的**:相关子查询逐行 SubPlan(`correlated-subquery-target-list` / `intargetlist` 系列)—— 试过 4 种写法 GaussDB 都上拉成 join 或跑 <3s,合成环境难自然触发,需真实业务里不可上拉的函数/语法。
- **难合成的**:SAVEPOINT 循环泄漏(客户端循环建同名 savepoint)、PACKAGE 变量内存占用、COPY Level2 容错 —— 信号非"单条慢 SQL",需专门手法。
- 家族变体(更多 seqscan/nestloop/groupagg/缺统计的细分 case)机制同上,改下过滤/数据量即可复现。
