#!/usr/bin/env python3
"""GaussDB 离线采集 · 预编译版 · 自包含 · python 纯 stdlib.

所有 130 个 auto 命令已 inline 在 CHECKS list 里 (不解析 ndjson).

生成时间: 2026-05-29T10:30:38.256Z
数据: auto=130 · manual=153 · skip=8 · total=291

用法:
  source ~/gauss_env_file
  python3 collect-precompiled.py [outdir]

环境变量:
  COLLECT_TIMEOUT  单命令超时秒 (default: 5)

依赖: python3 3.6+ · bash (用来跑 method)
"""
import os, subprocess, sys
from pathlib import Path
from datetime import datetime

OUTDIR = Path(sys.argv[1] if len(sys.argv) > 1 else f'./collect-results-{datetime.now().strftime("%Y%m%d-%H%M%S")}')
TIMEOUT = int(os.environ.get('COLLECT_TIMEOUT', '5'))
os.environ.setdefault('TERM', 'dumb')  # top/sar 等 tty 工具非交互需 TERM
(OUTDIR / 'stdout').mkdir(parents=True, exist_ok=True)
(OUTDIR / 'stderr').mkdir(parents=True, exist_ok=True)

# ── 部署形态自识别 (集中式 / 分布式 / 单节点) ──────────────────────────────
# 用 GaussDB 内置函数 pg_catalog.gs_deployment() (C immutable · 返回 text).
# 实测返回值: BusinessCentralized → 集中式 · Distribute → 分布式 · SingleNode → 单节点
def detect_deploy_form():
    import shutil as _sh
    if not _sh.which('gsql'):
        return 'unknown-no-gsql'
    try:
        r = subprocess.run(
            ['gsql', '-d', 'postgres', '-t', '-A', '-c',
             "SELECT pg_catalog.gs_deployment()"],
            capture_output=True, timeout=5, text=True,
        )
        if r.returncode != 0:
            return 'unknown-detect-fail'
        v = r.stdout.strip()
        lo = v.lower()
        if not v: return 'unknown-detect-fail'
        if 'centralized' in lo:                       return 'centralized'
        if 'distribut' in lo:                         return 'distributed'
        if 'singlenode' in lo or 'single_node' in lo: return 'single-node'
        return f'unknown-{v}'
    except Exception:
        return 'unknown-detect-fail'

DEPLOY_FORM = detect_deploy_form()
print(f'部署形态自识别: {DEPLOY_FORM}', file=sys.stderr, flush=True)
if DEPLOY_FORM.startswith('unknown'):
    print(f'⚠️ topology-filter-disabled: deploy_form={DEPLOY_FORM} · 全采(不按 topology 跳过)', file=sys.stderr, flush=True)
(OUTDIR / 'deploy.txt').write_text(DEPLOY_FORM + '\n')

# (check_id, name, layer, method, topology) · 130 条 auto · 直接跑
CHECKS = [
    ("chk-dbe-perf-statement-cpu-time", "dbe_perf.statement.cpu_time", "db-system-view", "select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_elapse_time/1000,2) as total_time,round(cpu_time/1000,2) as cup_time from dbe_perf.statement t where  n_calls>10 and avg_time>3  and user_name='root'  order by cpu_time desc limit 5;", "common"),
    ("chk-explain-verbose-remotequery", "explain verbose · RemoteQuery 计划", "db-interactive-cmd", "set rewrite_rule='none'; SET explain (verbose on, costs off)  select two_sum(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);", "distributed-only"),
    ("chk-explain-verbose-subplan", "explain verbose · SubPlan 执行方式", "db-interactive-cmd", "set rewrite_rule='none'; SET explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;", "common"),
    ("chk-enable-hashjoin", "enable_hashjoin 关闭后执行计划", "db-interactive-cmd", "SET enable_hashjoin = off;", "common"),
    ("chk-explain-verbose-streaming-vs-data-node-scan", "EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan", "db-interactive-cmd", "set rewrite_rule='none'; SET explain (verbose on, costs off)  select group_concat(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);", "distributed-only"),
    ("chk-explain-verbose-subplan", "EXPLAIN VERBOSE · SubPlan 算子出现在目标列", "db-interactive-cmd", "set rewrite_rule='none'; SET explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;", "common"),
    ("chk-pg-stat-get-last-data-changed-time", "近期数据变更表列表（pg_stat_get_last_data_changed_time）", "db-system-view", "SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();", "distributed-only"),
    ("chk-pgxc-get-table-skewness", "PGXC_GET_TABLE_SKEWNESS", "db-system-view", "SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;", "distributed-only"),
    ("chk-table-distribution-dn-1w", "table_distribution() 各DN空间（大表个数超1W场景）", "db-system-view", "SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace INNER JOIN pg_catalog.table_distribution() s ON s.schemaname = n.nspname AND s.tablename = c.relname INNER JOIN pg_catalog.pgxc_class x ON c.oid = x.pcrelid AND x.pclocatortype = 'H' GROUP BY schemaname,tablename;", "distributed-only"),
    ("chk-explain-verbose-warning", "EXPLAIN VERBOSE 执行计划 Warning", "db-interactive-cmd", "explain verbose", "common"),
    ("chk-copy", "COPY 导入是否存在约束冲突类容错需求", "db-shell", "SET a_format_load_with_constraints_violation = 's2';", "centralized-only"),
    ("chk-explain-verbose-anti-join", "EXPLAIN VERBOSE Anti Join 行数估算", "db-interactive-cmd", "explain verbose", "common"),
    ("chk-explain-verbose-hashjoin", "EXPLAIN VERBOSE hashjoin 行数估算", "db-interactive-cmd", "set cost_param=2; explain verbose", "common"),
    ("chk-table-skewness-dn", "table_skewness() 各 DN 数据分布比例", "db-system-view", "select table_skewness('inventory');", "distributed-only"),
    ("chk-pg-stat-get-last-data-changed-time", "pg_stat_get_last_data_changed_time 最近变更的表", "db-system-view", "SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();", "distributed-only"),
    ("chk-table-distribution-dn", "table_distribution() 各 DN 存储空间分布", "db-system-view", "SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();", "distributed-only"),
    ("chk-explain-analyze-hashjoin-dn", "EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围", "db-interactive-cmd", "EXPLAIN ANALYZE", "distributed-only"),
    ("chk-memory-information-dn", "Memory Information 各 DN 内存消耗分布", "db-interactive-cmd", "EXPLAIN ANALYZE` (Memory Information 段)", "distributed-only"),
    ("chk-seq-scan-dn", "Seq Scan 各 DN 扫描时间", "db-interactive-cmd", "EXPLAIN ANALYZE", "distributed-only"),
    ("chk-explain-analyze-join", "EXPLAIN ANALYZE Join 算子类型与耗时", "db-interactive-cmd", "EXPLAIN ANALYZE", "common"),
    ("chk-explain-analyze-agg", "EXPLAIN ANALYZE Agg 算子类型", "db-interactive-cmd", "EXPLAIN ANALYZE", "common"),
    ("chk-iostat-util-r-await-w-await", "iostat 中 %util / r_await / w_await", "os", "iostat", "common"),
    ("chk-top-sar-gaussdb-cpu", "top / sar 中 gaussdb 进程 CPU 占用", "os", "top -b -n 1", "common"),
    ("chk-explain-performance", "EXPLAIN PERFORMANCE 算子耗时", "db-interactive-cmd", "EXPLAIN PERFORMANCE", "common"),
    ("chk-scan-filter", "Scan filter 条件分析", "db-interactive-cmd", "EXPLAIN PERFORMANCE", "common"),
    ("chk-explain-performance-windowagg-sort", "EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时", "db-interactive-cmd", "explain performance", "distributed-only"),
    ("chk-pgxc-thread-wait-status-wait-status", "pgxc_thread_wait_status.wait_status", "db-system-view", "Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;", "distributed-only"),
    ("chk-table-skewness-table-distribution", "table_skewness / table_distribution", "db-system-view", "select table_skewness('store_sales');", "distributed-only"),
    ("chk-null-003", "线程等待状态", "db-system-view", "select * from pg_thread_wait_status where query_id='149181737656737395';", "distributed-only"),
    ("chk-sql-create-index", "活跃SQL及CREATE INDEX语句", "db-system-view", "select * from pg_stat_activity where state !='idle' and usename !='omm';", "distributed-only"),
    ("chk-null-004", "表数据倾斜", "db-system-view", "select table_skewness('ioc_dm.m_ss_index_event');", "distributed-only"),
    ("chk-pgxc-get-stat-all-tables-dirty-page-rate", "PGXC_GET_STAT_ALL_TABLES.dirty_page_rate", "db-system-view", "SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_GET_STAT_ALL_TABLES WHERE schemaName NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'cstore', 'pmk') AND dirty_page_rate > 30 ORDER BY table_size DESC, dirty_page_rate DESC;", "distributed-only"),
    ("chk-dn", "各DN数据量分布", "db-shell", "SELECT pg_get_tabledef('customer_t1');", "distributed-only"),
    ("chk-enable-codegen", "enable_codegen 参数状态", "db-shell", "SHOW turbo_engine_version;", "distributed-only"),
    ("chk-pgxc-wlm-session-info-streaming-stream-count", "pgxc_wlm_session_info · Streaming 算子数（stream_count）", "db-system-view", "SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM pgxc_wlm_session_info ORDER BY stream_count DESC limit 100;", "distributed-only"),
    ("chk-pgxc-wlm-session-info-max-cpu-time-cpu", "pgxc_wlm_session_info · max_cpu_time（高CPU语句）", "db-system-view", "SELECT * FROM pgxc_wlm_session_info WHERE start_time > 'xxxx-xx-xx' AND start_time < 'xxxx-xx-xx' ORDER BY max_cpu_time desc;", "distributed-only"),
    ("chk-resource-track-level-operator-realtime", "resource_track_level · operator_realtime 级别实时算子监控", "db-system-view", "SET resource_track_level = 'operator_realtime';", "distributed-only"),
    ("chk-pgxc-stat-activity-runtime-current-timestamp-query-start", "PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start)", "db-system-view", "SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle' order by 1 desc;", "distributed-only"),
    ("chk-pgxc-stat-activity-waiting-true", "PGXC_STAT_ACTIVITY · waiting=true 阻塞查询", "db-system-view", "SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;", "distributed-only"),
    ("chk-pgxc-lock-conflicts", "pgxc_lock_conflicts 锁冲突视图", "db-system-view", "SELECT * FROM pgxc_lock_conflicts;", "distributed-only"),
    ("chk-pgxc-stat-activity-state-waiting-query", "pgxc_stat_activity · state / waiting / query", "db-system-view", "SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';", "distributed-only"),
    ("chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic-", "pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory", "db-system-view", "SELECT * FROM pgxc_total_memory_detail;", "distributed-only"),
    ("chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc", "pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent", "db-system-view", "SELECT nodename,pid,dbname,username,application_name,min_peak_memory,max_peak_memory,average_peak_memory,memory_skew_percent,substr(query,0,50) as query FROM pgxc_wlm_session_statistics;", "distributed-only"),
    ("chk-pgxc-thread-wait-status-dn", "pgxc_thread_wait_status · 作业等待 DN 分布", "db-system-view", "SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;", "distributed-only"),
    ("chk-table-skewness", "table_skewness · 数据倾斜率", "db-system-view", "SELECT table_skewness('store_sales');", "distributed-only"),
    ("chk-pgxc-get-table-skewness", "pgxc_get_table_skewness · 全库倾斜视图", "db-system-view", "SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;", "distributed-only"),
    ("chk-pg-thread-wait-status", "pg_thread_wait_status · 线程等待状态", "db-system-view", "SELECT * FROM pg_thread_wait_status WHERE query_id='149181737656737395';", "distributed-only"),
    ("chk-pg-stat-activity-sql", "pg_stat_activity 活跃SQL", "db-system-view", "SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';", "distributed-only"),
    ("chk-null-011", "表倾斜情况", "db-shell", "SELECT table_skewness('table name');", "distributed-only"),
    ("chk-pg-session-wlmstat-status-statement-mem", "pg_session_wlmstat · status / statement_mem", "db-system-view", "SELECT usename,substr(query,0,20),threadid,status,statement_mem FROM pg_session_wlmstat where usename not in ('omm','Ruby') order by statement_mem,status desc;", "distributed-only"),
    ("chk-pgxc-thread-wait-status-wait-status-wait-event", "pgxc_thread_wait_status · wait_status / wait_event", "db-system-view", "SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_status <> 'synchronize quit' AND wait_status <> 'none'  GROUP BY 1,2 ORDER BY 3 DESC limit 50;", "distributed-only"),
    ("chk-pg-partition", "pg_partition 各表分区数", "db-system-view", "SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition GROUP BY parentid ) s ON c.oid = s.parentid ORDER BY partcount DESC;", "distributed-only"),
    ("chk-pgxc-lock-conflicts-8-1-x", "pgxc_lock_conflicts 锁冲突（8.1.x及以上）", "db-system-view", "SELECT * FROM pgxc_lock_conflicts;", "distributed-only"),
    ("chk-pgxc-stat-activity-vacuum-full-8-0-x", "pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前）", "db-system-view", "SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';", "distributed-only"),
    ("chk-pgxc-thread-wait-status", "pgxc_thread_wait_status 锁等待状态", "db-system-view", "SELECT * FROM pgxc_thread_wait_status WHERE query_id = {query_id};", "distributed-only"),
    ("chk-pck", "表定义是否存在PCK", "db-shell", "SELECT * FROM pg_get_tabledef('table name');", "distributed-only"),
    ("chk-psort-work-mem", "psort_work_mem 参数值", "db-shell", "show psort_work_mem;", "distributed-only"),
    ("chk-explain-verbose-hashjoin", "EXPLAIN VERBOSE · HashJoin 行数估算偏差", "db-interactive-cmd", "set cost_param=2; explain verbose select nation, sum(amount) as sum_profit from (...) as profit group by nation order by nation", "distributed-only"),
    ("chk-dn", "磁盘利用率各 DN 差异", "db-shell", "SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc", "distributed-only"),
    ("chk-table-skewness-table-distribution", "table_skewness / table_distribution · 表数据倾斜率", "db-shell", "SELECT table_skewness('store_sales')", "distributed-only"),
    ("chk-pgxc-stat-activity-state", "pgxc_stat_activity state 字段", "db-system-view", "SELECT state, query, query_id FROM pgxc_stat_activity;", "distributed-only"),
    ("chk-cn-savepoint-release", "各 CN 上 SAVEPOINT/RELEASE 语句分布", "db-system-view", "SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';", "distributed-only"),
    ("chk-leading-hint", "加 leading hint 后执行时间", "db-interactive-cmd", "select /*+ leading((s d)) */ a.ca_state state, count(*) cnt ...", "distributed-only"),
    ("chk-leading-no-nestloop-hint", "加 leading + no nestloop hint 后执行时间", "db-interactive-cmd", "select /*+ leading((s d)) no nestloop(s d) */ a.ca_state state, count(*) cnt ...", "distributed-only"),
    ("chk-rows-hint", "rows hint 后执行时间", "db-interactive-cmd", "select /*+ rows(s #2880404) */ a.ca_state state, count(*) cnt ...", "distributed-only"),
    ("chk-skew-hint-agg", "skew hint 后双层 Agg 计划", "db-interactive-cmd", "select /*+ skew(store_returns(sr_store_sk sr_customer_sk)) */sr_customer_sk as ctr_customer_sk ...", "distributed-only"),
    ("chk-explain-performance-rows-hint", "EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时", "db-interactive-cmd", "select avg(netpaid) from (select /*+rows(store_sales store_returns * 11270)*/ c_last_name ...", "distributed-only"),
    ("chk-gs-wlm-session-history-warning-sql", "GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息", "db-system-view", "SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC", "distributed-only"),
    ("chk-gs-wlm-session-history-warning", "GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警", "db-system-view", "SELECT query,warning FROM GS_WLM_SESSION_STATISTICS ORDER BY start_time DESC", "distributed-only"),
    ("chk-xid", "当前事务 XID", "db-system-view", "SELECT txid_current();", "distributed-only"),
    ("chk-null-014", "活跃事务列表", "db-system-view", "SELECT txid_current_snapshot();", "distributed-only"),
    ("chk-gtm-snapshot-oldestxmin-xid", "GTM snapshot · oldestxmin 与 xid 差值", "db-system-view", "SELECT * FROM pgxc_gtm_snapshot_status();", "distributed-only"),
    ("chk-pgxc-running-xacts", "老事务列表 (pgxc_running_xacts)", "db-system-view", "SELECT * FROM pgxc_running_xacts where xmin::text::bigint < $base+$min and xmin::text::bigint > 0;", "distributed-only"),
    ("chk-pg-stat-activity-idle", "pg_stat_activity · idle 连接数", "db-system-view", "SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';", "distributed-only"),
    ("chk-explain-performance", "EXPLAIN PERFORMANCE · 算子分布", "db-interactive-cmd", "explain performance", "distributed-only"),
    ("chk-shared-buffers", "shared_buffers", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW shared_buffers;\"", "common"),
    ("chk-work-mem", "work_mem", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW work_mem;\"", "common"),
    ("chk-rewrite-rule", "rewrite_rule", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW rewrite_rule;\"", "common"),
    ("chk-enable-hashjoin", "enable_hashjoin", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_hashjoin;\"", "common"),
    ("chk-enable-nestloop", "enable_nestloop", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_nestloop;\"", "common"),
    ("chk-enable-mergejoin", "enable_mergejoin", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_mergejoin;\"", "common"),
    ("chk-enable-sort", "enable_sort", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_sort;\"", "common"),
    ("chk-best-agg-plan", "best_agg_plan", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW best_agg_plan;\"", "distributed-only"),
    ("chk-a-format-load-with-constraints-violation", "a_format_load_with_constraints_violation", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW a_format_load_with_constraints_violation;\"", "centralized-only"),
    ("chk-cost-param", "cost_param", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW cost_param;\"", "common"),
    ("chk-skew-option", "skew_option", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW skew_option;\"", "distributed-only"),
    ("chk-thread-pool-attr", "thread_pool_attr", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW thread_pool_attr;\"", "common"),
    ("chk-default-statistics-target", "default_statistics_target", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW default_statistics_target;\"", "distributed-only"),
    ("chk-behavior-compat-options", "behavior_compat_options", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW behavior_compat_options;\"", "common"),
    ("chk-enable-fast-query-shipping", "enable_fast_query_shipping", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_fast_query_shipping;\"", "distributed-only"),
    ("chk-recovery-parse-workers", "recovery_parse_workers", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW recovery_parse_workers;\"", "common"),
    ("chk-recovery-redo-workers", "recovery_redo_workers", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW recovery_redo_workers;\"", "common"),
    ("chk-enable-index-nestloop", "enable_index_nestloop", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_index_nestloop;\"", "distributed-only"),
    ("chk-enable-indexscan", "enable_indexscan", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_indexscan;\"", "distributed-only"),
    ("chk-max-process-memory", "max_process_memory", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW max_process_memory;\"", "distributed-only"),
    ("chk-qrw-inlist2join-optmode", "qrw_inlist2join_optmode", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW qrw_inlist2join_optmode;\"", "distributed-only"),
    ("chk-fetchsize", "fetchSize", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW fetchSize;\"", "distributed-only"),
    ("chk-period", "period", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW period;\"", "distributed-only"),
    ("chk-ttl", "ttl", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW ttl;\"", "distributed-only"),
    ("chk-disk-cache-max-size", "disk_cache_max_size", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW disk_cache_max_size;\"", "distributed-only"),
    ("chk-disk-cache-dual-write-option", "disk_cache_dual_write_option", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW disk_cache_dual_write_option;\"", "distributed-only"),
    ("chk-min-batch-rows", "min_batch_rows", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW min_batch_rows;\"", "distributed-only"),
    ("chk-autovacuum", "autovacuum", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW autovacuum;\"", "distributed-only"),
    ("chk-autovacuum-vacuum-cost-delay", "autovacuum_vacuum_cost_delay", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW autovacuum_vacuum_cost_delay;\"", "distributed-only"),
    ("chk-autovacuum-max-workers", "autovacuum_max_workers", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW autovacuum_max_workers;\"", "distributed-only"),
    ("chk-autovacuum-naptime", "autovacuum_naptime", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW autovacuum_naptime;\"", "distributed-only"),
    ("chk-max-active-statements", "max_active_statements", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW max_active_statements;\"", "distributed-only"),
    ("chk-autovacuum-max-workers-hstore", "autovacuum_max_workers_hstore", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW autovacuum_max_workers_hstore;\"", "distributed-only"),
    ("chk-enable-codegen", "enable_codegen", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_codegen;\"", "distributed-only"),
    ("chk-enable-numa-bind", "enable_numa_bind", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_numa_bind;\"", "distributed-only"),
    ("chk-abnormal-check-general-task", "abnormal_check_general_task", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW abnormal_check_general_task;\"", "distributed-only"),
    ("chk-resource-track-level", "resource_track_level", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW resource_track_level;\"", "distributed-only"),
    ("chk-track-activities", "track_activities", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW track_activities;\"", "distributed-only"),
    ("chk-connectiontimeout", "connectionTimeOut", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW connectionTimeOut;\"", "distributed-only"),
    ("chk-lockwait-timeout", "lockwait_timeout", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW lockwait_timeout;\"", "distributed-only"),
    ("chk-psort-work-mem", "psort_work_mem", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW psort_work_mem;\"", "distributed-only"),
    ("chk-enable-delta", "ENABLE_DELTA", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW ENABLE_DELTA;\"", "distributed-only"),
    ("chk-resource-pool-cpu-dedicated-quota", "resource_pool.cpu_dedicated_quota", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW resource_pool.cpu_dedicated_quota;\"", "distributed-only"),
    ("chk-temp-file-limit", "temp_file_limit", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW temp_file_limit;\"", "distributed-only"),
    ("chk-sequence-cache", "sequence.cache", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW sequence.cache;\"", "distributed-only"),
    ("chk-query-dop", "query_dop", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW query_dop;\"", "distributed-only"),
    ("chk-cstore-buffers", "cstore_buffers", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW cstore_buffers;\"", "distributed-only"),
    ("chk-comm-max-stream", "comm_max_stream", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW comm_max_stream;\"", "distributed-only"),
    ("chk-vacuum-defer-cleanup-age", "vacuum_defer_cleanup_age", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW vacuum_defer_cleanup_age;\"", "distributed-only"),
    ("chk-enable-stream-operator", "enable_stream_operator", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW enable_stream_operator;\"", "distributed-only"),
    ("chk-table-skewness-warning-threshold", "table_skewness_warning_threshold", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW table_skewness_warning_threshold;\"", "distributed-only"),
    ("chk-table-skewness-warning-rows", "table_skewness_warning_rows", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW table_skewness_warning_rows;\"", "distributed-only"),
    ("chk-session-timeout", "session_timeout", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW session_timeout;\"", "distributed-only"),
    ("chk-max-connections", "max_connections", "gaussdb-guc-param", "gsql -d postgres -c \"SHOW max_connections;\"", "distributed-only"),
    ("chk-slow-sql-statement-history", "statement_history 慢 SQL (execution_time 超阈值语句明细)", "db-system-view", "SELECT substr(query,1,60) AS q, round(execution_time/1000000.0,2) AS exec_s, round(db_time/1000000.0,2) AS db_s, (n_blocks_fetched-n_blocks_hit) AS phys_read, start_time FROM statement_history WHERE execution_time > 3000000 ORDER BY execution_time DESC LIMIT 20;", "common"),
]

# (check_id, name, layer, method) · 153 条 manual · 描述性 · 不自动跑
MANUAL = [
    ("chk-gaussdb", "GaussDB内置火焰图 · 时区加载线程占比", "flamegraph", "GaussDB在内核505版本中内置了火焰图工具，默认每5分钟会自动采集一次，保存在$GAUSSLOG/gs_flamegraph/{datanode}路径下，详细信息可参考GaussDB产品文档《内置perf工具》章节。"),
    ("chk-buffer-wdr", "buffer命中率 (WDR报告或管控平台)", "db-system-view", "可以借助GaussDB的管控平台或者WDR报告。通常情况下，TP数据库的buffer命中率应该在99%以上。"),
    ("chk-explain-analyze", "EXPLAIN ANALYZE 算子落盘标志", "db-interactive-cmd", "为了优化性能，可以查看SQL的执行计划，如果算子存在落盘的情况，可适当调整work_mem参数值。"),
    ("chk-dbe-perf-statement-cpu-time-cpu", "dbe_perf.statement.cpu_time (持续CPU高)", "db-system-view", "dbe_perf.statement`：可查询分布式本CN发起的历史语句信息。`dbe_perf.summary_statement`：可查询分布式所有CN发起的历史语句信息。（对cpu_time字段进行逆序排序即可识别）"),
    ("chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu", "pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高)", "db-system-view", "查询pg_stat_activity 获取正在运行的SQL的query_id。使用上一步的query_id，查询pg_thread_wait_status 获取正在运行的SQL的lwtid。使用操作系统命令top -Hp <gaussdb进程号>，查看相应lwtid(PID)的CPU使用率。"),
    ("chk-statement-history-cpu-time-vs-db-time", "statement_history.cpu_time vs db_time", "db-system-view", "登录至各CN/DN节点查询相应时间段的statement_history 表。使用全局接口dbe_perf.get_global_full_sql_by_timestamp('开始时间','结束时间')。注意：需要切换至postgres库。"),
    ("chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io", "dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高)", "db-system-view", "如果持续IO高，可查询dbe_perf.statement/dbe_perf.summary_statement内n_blocks_fetched/n_blocks_hit字段，通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。"),
    ("chk-pg-thread-wait-status-wait-status-wait-event-io", "pg_thread_wait_status.wait_status / wait_event (当前IO高)", "db-system-view", "如果当前IO高，可查询pg_thread_wait_status视图，查询wait_status/wait_event字段，通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。"),
    ("chk-statement-history-data-io-time-sql-io", "statement_history.data_io_time (慢SQL IO分析)", "db-system-view", "查询statement_history表，慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录"),
    ("chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam", "dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory", "db-system-view", "查询dbe_perf.memory_node_detail视图，明确内存占用点。•max_dynamic_memory：最大可使用动态内存 •dynamic_used_memory：已使用动态内存"),
    ("chk-dbe-perf-session-memory-detail-dynamic-used-shrctx", "dbe_perf.session_memory_detail (dynamic_used_shrctx较小时)", "db-system-view", "dynamic_used_shrctx较小，查询dbe_perf.session_memory_detail可获取到不同Session的内存消耗，通常来讲：用户会话数和用户每个session上内存占用都会导致动态内存异常问题。"),
    ("chk-dbe-perf-shared-memory-detail-dynamic-used-shrctx", "dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时)", "db-system-view", "dynamic_used_shrctx较大，查询dbe_perf.shared_memory_detail可获取到异常内存消耗的context，通常此处有过多的异常消耗，多数情况下为用户session上的内存异常消耗。"),
    ("chk-dbe-perf-local-active-session", "dbe_perf.local_active_session (秒级抖动)", "db-system-view", "对于短时间秒级性能抖动，分析相应时间点的dbe_perf.local_active_session，可排查点如下：•异常等待事件，当时SQL的异常等待事件，可参考整体性能慢-等待事件分析。•异常SQL，分析某些SQL出现的频率变化，以及执行速度，如多次采样均被采集到，即可反向分析到SQL执行时间。•异常连接数变化，比如业务突然连接增加。"),
    ("chk-gs-asp", "gs_asp (两天内秒级抖动)", "db-system-view", "对于两天内秒级性能抖动，分析相应时间点的gs_asp表"),
    ("chk-data-node-scan", "执行计划下推标识（Data Node Scan）", "db-interactive-cmd", "将GUC参数enable_fast_query_shipping设置为off，使查询优化器使用分布式框架策略。查看执行计划。如果执行计划中有Data Node Scan节点，那么此执行计划是发送语句的分布式执行计划，为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。"),
    ("chk-pg-proc-provolatile-proshippable", "pg_proc.provolatile / proshippable", "db-system-view", "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE。另外，在pg_proc中的proshippable字段，取值范围为t/f/NULL，这个字段与provolatile字段一起用于描述函数是否下推。"),
    ("chk-pg-proc-provolatile", "pg_proc.provolatile", "db-system-view", "函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE"),
    ("chk-explain-verbose-warning", "explain verbose WARNING · 统计信息缺失提示", "db-interactive-cmd", "通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, ...) are not collected. HINT:Do analyze for them in order to generate optimized plan."),
    ("chk-explain-nest-loop-join", "EXPLAIN 执行计划 · Nest Loop Join 耗时", "db-interactive-cmd", "分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。"),
    ("chk-explain-verbose-warning", "EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表", "db-interactive-cmd", "通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan."),
    ("chk-pg-log-statistics-not-collected", "pg_log 日志 · Statistics not collected 日志行", "log-grep", "可以通过在pg_log目录下的日志文件中查找以下信息来确认当前执行的query是否由于没有收集统计信息导致查询性能变差。"),
    ("chk-explain-join", "EXPLAIN 执行计划 · Join 算子类型及耗时", "db-interactive-cmd", "分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。"),
    ("chk-savepoint", "存储过程中 SAVEPOINT 的创建/释放配对", "db-shell", "在使用完SAVEPOINT后，应及时使用RELEASE SAVEPOINT来释放资源。"),
    ("chk-commit-rollback-i-o", "COMMIT/ROLLBACK 频率与 I/O 开销", "db-shell", "事务的COMMIT和ROLLBACK操作需要同步数据库的元数据和日志，频繁执行可能增加I/O开销，从而影响性能。"),
    ("chk-b-tree-explain-analyze", "创建 B-tree 索引后再次 EXPLAIN ANALYZE", "db-interactive-cmd", "添加索引后，通过与无索引时执行计划的对比，查询时间从原来的382.624ms缩短到0.293 ms。"),
    ("chk-rds001-cpu-util", "rds001_cpu_util", "db-internal-counter", "CPU使用率"),
    ("chk-rds002-mem-util", "rds002_mem_util", "db-internal-counter", "内存使用率"),
    ("chk-io-bandwidth-usage", "io_bandwidth_usage", "db-internal-counter", "磁盘io带宽占用率"),
    ("chk-iops-usage", "iops_usage", "db-internal-counter", "IOPS使用率"),
    ("chk-rds007-instance-disk-usage", "rds007_instance_disk_usage", "db-internal-counter", "实例数据磁盘已使用百分比"),
    ("chk-rds020-avg-disk-ms-per-write", "rds020_avg_disk_ms_per_write", "db-internal-counter", "数据磁盘单次写入花费的时间"),
    ("chk-rds021-avg-disk-ms-per-read", "rds021_avg_disk_ms_per_read", "db-internal-counter", "数据磁盘单次读取花费的时间"),
    ("chk-rds036-deadlocks", "rds036_deadlocks", "db-internal-counter", "死锁次数"),
    ("chk-rds048-p80", "rds048_P80", "db-internal-counter", "80% SQL的响应时间"),
    ("chk-rds049-p95", "rds049_P95", "db-internal-counter", "95% SQL的响应时间"),
    ("chk-rds060-long-running-transaction-exectime", "rds060_long_running_transaction_exectime", "db-internal-counter", "数据库最长事务的执行时长"),
    ("chk-rds063-slowquery-user", "rds063_slowquery_user", "db-internal-counter", "用户库慢SQL数量"),
    ("chk-rds065-dynamic-used-memory-usage", "rds065_dynamic_used_memory_usage", "db-internal-counter", "动态内存使用率"),
    ("chk-rds066-replication-slot-wal-log-size", "rds066_replication_slot_wal_log_size", "db-internal-counter", "复制槽保留的WAL日志大小"),
    ("chk-rds070-thread-pool", "rds070_thread_pool", "db-internal-counter", "线程池使用率"),
    ("chk-top-gsql-cpu", "top · gsql 进程 CPU 占用", "os", "top 命令显示 gsql 进程占用率高"),
    ("chk-pg-stat-statements-total-time-calls", "pg_stat_statements · total_time + calls (慢查询统计)", "db-system-view", "- **abnormal_patterns**: [\"total_time > 1000 AND calls > 10\"]"),
    ("chk-explain-groupagg-sort", "EXPLAIN · 算子(GroupAgg+Sort)", "db-interactive-cmd", "计划中包含GroupAgg+Sort算子"),
    ("chk-explain-analyze", "EXPLAIN ANALYZE 顺序扫描耗时", "db-interactive-cmd", "EXPLAIN"),
    ("chk-explain-seqscan-vs-indexscan", "EXPLAIN · 算子(seqscan vs indexscan)", "db-interactive-cmd", "在优化前，没有创建places.place_id和states.state_id索引，执行计划如下"),
    ("chk-explain-join", "EXPLAIN 执行计划 Join 类型", "db-interactive-cmd", "EXPLAIN"),
    ("chk-pidstat-iotop-i-o", "pidstat / iotop 显示线程 I/O 消耗", "os", "pidstat -dt -p gaussdb进程号"),
    ("chk-pg-thread-wait-status-pg-stat-activity-i-o-sql", "pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL", "db-system-view", "通过查询pg_thread_wait_status视图的lwtid为上一步内的TID，获取对应的tid和sessionid。"),
    ("chk-wdr-top-sql-order-by-cpu-time", "WDR 报告 Top SQL order by CPU Time", "db-system-view", "可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句"),
    ("chk-null-001", "内核代码热点函数火焰图", "flamegraph", "如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点"),
    ("chk-guc-shared-buffers-work-mem-thread-pool-attr", "GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值", "db-system-view", "常见的可能情况有：1. shared_buffers配置过小，导致buffer淘汰频繁。"),
    ("chk-session-package", "SESSION 中 PACKAGE 变量数量与内存占用", "db-shell", "PACKAGE变量是在PACKAGE内定义的全局变量，其生命周期覆盖整个数据库会话（SESSION）。"),
    ("chk-explain-filter", "EXPLAIN 执行计划 Filter 条件分析", "db-interactive-cmd", "EXPLAIN"),
    ("chk-pg-proc-volatility", "pg_proc 函数 volatility 类型查询", "db-system-view", "查询pg_proc"),
    ("chk-explain", "EXPLAIN 执行计划算子估算行数", "db-interactive-cmd", "EXPLAIN"),
    ("chk-explain-stream", "EXPLAIN 执行计划 Stream 算子类型", "db-interactive-cmd", "EXPLAIN"),
    ("chk-exception", "存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销", "db-shell", "每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。"),
    ("chk-null-002", "存储过程默认权限模式", "db-shell", "存储过程默认具有SECURITYINVOKER权限。"),
    ("chk-explain-remotequery-data-node-scan", "EXPLAIN · 是否含 RemoteQuery / Data Node Scan", "db-interactive-cmd", "- **abnormal_patterns**: [\"`Data Node Scan on t1 \\\"_REMOTE_TABLE_QUERY_\\\"`\"]"),
    ("chk-explain-cn-vs-dn", "EXPLAIN 执行计划算子位置（CN vs DN）", "db-interactive-cmd", "EXPLAIN"),
    ("chk-group-by-groupagg-sort", "GROUP BY 查询计划中是否包含 GroupAgg+Sort", "db-interactive-cmd", "查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。"),
    ("chk-explain", "EXPLAIN · 计划与实际行数比对", "db-interactive-cmd", "导致执行计划选择不优"),
    ("chk-explain-data-node-scan-on", "EXPLAIN 输出中 \"Data Node Scan on\" 是否在第一行", "db-interactive-cmd", "通常而言explain语句后没有显示具体的执行计划算子，执行计划中关键字\\\"Data Node Scan on\\\"出现在第一行（不包含计划格式）则说明语句已下推给DN去执行。"),
    ("chk-explain-subplan", "EXPLAIN 执行计划 SubPlan 存在", "db-interactive-cmd", "EXPLAIN"),
    ("chk-dn-cpu", "备DN CPU使用率 · 回放线程资源", "os", "极致RTO采用了多个page redo线程并行加速回放进度。当备DN回放追平主DN，空载的情况下，单个page redo线程的CPU消耗大约在15%左右（实际值与具体硬件和参数配置相关），备DN回放的总CPU消耗值 = 单个page redo线程的CPU消耗值 x page redo线程数。"),
    ("chk-explain-verbose", "EXPLAIN VERBOSE 统计信息警告", "db-interactive-cmd", "通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan."),
    ("chk-pg-log", "pg_log 统计信息缺失日志", "log-grep", "可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。"),
    ("chk-explain-analyze-stream", "EXPLAIN ANALYZE · Stream算子类型", "db-interactive-cmd", "GaussDB计划中常见的主要Stream算子包括Redistribute、Broadcast和Gather。"),
    ("chk-explain-analyze-startup-vs-total", "EXPLAIN ANALYZE · 路径代价 (Startup vs Total)", "db-interactive-cmd", "把explain_perf_mode设置为normal，查看原Nest Loop的启动代价"),
    ("chk-nestloop", "语句执行时间 / 执行计划中 NestLoop 算子", "db-interactive-cmd", "该问题发生在实时场景下，语句执行时间因为达到了 3600s而自动终止运行"),
    ("chk-pgxc-wlm-session-history-block-time-duration", "pgxc_wlm_session_history · block_time / duration", "db-system-view", "pgxc_wlm_session_history"),
    ("chk-pgxc-wlm-session-history", "pgxc_wlm_session_history · 同期并发作业数", "db-system-view", "pgxc_wlm_session_history"),
    ("chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn-", "pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent", "db-system-view", "pgxc_wlm_session_history"),
    ("chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ", "GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write", "db-system-view", "GS_WLM_INSTANCE_HISTORY"),
    ("chk-explain-performance-sql-streaming-redistribute", "EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜）", "db-interactive-cmd", "SQL自诊断信息显示在做row_number()函数计算前的PARTITION BY T.ORDER_LINE_ID引入的重分布算子(Streaming(type: REDISTRIBUTE))有计算倾斜"),
    ("chk-order-line-id-null", "列统计信息 · ORDER_LINE_ID NULL 比例", "db-system-view", "查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值"),
    ("chk-pgxc-wlm-session-history-dataskew-warning", "pgxc_wlm_session_history · DataSkew warning", "db-system-view", "GaussDB 在执行 SQL 语句时，会对其性能表现进行分析和记录，通过视图和函数等手段呈现给用户。执行完一条代价大于resource_track_cost后，诊断信息会存放在内存hash表中，可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"),
    ("chk-pgxc-wlm-session-history-large-table-in-broadcast-warning", "pgxc_wlm_session_history · Large Table in Broadcast warning", "db-system-view", "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"),
    ("chk-pgxc-wlm-session-history-spill", "pgxc_wlm_session_history · Spill告警", "db-system-view", "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"),
    ("chk-pgxc-wlm-session-history-nestloop", "pgxc_wlm_session_history · NestLoop大表告警", "db-system-view", "可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。"),
    ("chk-dn", "各DN磁盘利用率", "os", "gs_ssh -c \"df -h"),
    ("chk-warning", "执行计划统计信息Warning", "db-interactive-cmd", "通过explain verbose/explain performance打印语句的执行计划"),
    ("chk-remote", "执行计划下推标识（__REMOTE关键字）", "db-interactive-cmd", "通过explain verbose打印语句执行计划"),
    ("chk-nestloop", "执行计划算子类型（NestLoop）", "db-interactive-cmd", "首先观察SQL语句中有not in 语法；执行计划中有NestLoop"),
    ("chk-partitioned-cstore-scan", "执行计划：Partitioned CStore Scan分区扫描范围", "db-interactive-cmd", "和客户收集几个典型的慢sql，分别打印执行计划。"),
    ("chk-vecnestloopruntime", "进程堆栈（VecNestLoopRuntime）", "os", "gstack 14104"),
    ("chk-max-process-memory-shared-buffers", "内存参数：max_process_memory, shared_buffers", "db-shell", "检查内存相关参数，设置不合理"),
    ("chk-in", "执行计划in条件处理方式", "db-interactive-cmd", "打印语句的执行计划"),
    ("chk-sql-case-when", "SQL 中 CASE WHEN 分支数量与执行次数", "db-interactive-cmd", "在业务查询中，CASE WHEN语句常用来进行条件判断，但如果在SQL查询中存在大量冗余的CASE WHEN"),
    ("chk-null-005", "系统表/用户表膨胀情况", "db-system-view", "用户可在管控面执行全库Vacuum/Vacuum Full，以定期进行空间回收"),
    ("chk-pgxc-stat-table-dirty", "表脏页率 (PGXC_STAT_TABLE_DIRTY)", "db-system-view", "DWS提供了查询脏页率的系统视图，具体使用请参见PGXC_STAT_TABLE_DIRTY。"),
    ("chk-gds", "GDS导入作业日志", "log-grep", "检测GDS导入作业的日志，查看是否有执行失败的现象。"),
    ("chk-fe-sync-be-parsecomplete", "FE=>Sync 与 <=BE ParseComplete 日志时间间隔", "log-grep", "用户可查看FE=> Syncr日志和<=BE ParseComplete日志之间的时间间隔"),
    ("chk-be-datarow-select-count", "<=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小", "log-grep", "查看日志，如果<=BE DataRow日志出现次数过多，或直接执行SELECT count(*);"),
    ("chk-modifyjdbccall-createparameterizedquery", "modifyJdbcCall / createParameterizedQuery 阶段耗时", "log-grep", "如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。"),
    ("chk-analyze", "ANALYZE 后的查询性能", "db-interactive-cmd", "使用ANALYZE命令分析数据库。"),
    ("chk-null-006", "查询返回行数", "db-interactive-cmd", "检查查询语句是否返回了多余的数据信息。"),
    ("chk-null-007", "主机负载下查询单独运行时延", "db-interactive-cmd", "尝试在数据库没有其他查询或查询较少的时候运行查询语句，并观察运行效率。"),
    ("chk-null-008", "重复执行同一查询语句的执行时间", "db-interactive-cmd", "重复执行相同的查询语句，如果后续执行的查询语句效率提升，则可能是由于上述原因导致。"),
    ("chk-disk-cache-pgxc-disk-cache-all-stats", "Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats)", "db-system-view", "通过查询视图pgxc_disk_cache_all_stats可以查看当前缓存的命中率以及各个DN磁盘的使用大小情况"),
    ("chk-evs", "EVS 磁盘空间占用百分比", "log-grep", "日志中会出现\\\"Disk usage on the node %u has reached the read-only threshold 90%\\"),
    ("chk-bucket", "入库分区数 / Bucket 数 / 攒批内存消耗", "db-shell", "单并发攒批消耗： #Np * #Nb * #Nr 单并发攒批内存消耗： partition_max_cache_size， 默认2GB"),
    ("chk-explain-indexscan", "EXPLAIN 执行计划 · 是否选择IndexScan", "db-interactive-cmd", "对表执行ANALYZE更新统计信息。"),
    ("chk-waiting-in-queue", "查询等待状态 · waiting in queue", "db-system-view", "普通用户主要在waiting in queue/waiting in global queue时。当前的活跃语句数超过max_active_statements限制导致的普通用户排队，由于管理员用户不受管控所以无需排队。"),
    ("chk-explain-or-filter", "EXPLAIN 执行计划 · 系统视图权限OR filter", "db-interactive-cmd", "通过执行计划可以看到系统视图中的权限判断中多用or条件判断：pg_has_role(c.relowner, 'USAGE'::text) OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text)"),
    ("chk-cn", "CN日志中不下推原因", "log-grep", "不下推语句在pg_log中会打印不下推的原因。LOG: SQL can't be shipped, reason: ..."),
    ("chk-explain-verbose-warning", "EXPLAIN VERBOSE WARNING信息 · 统计信息缺失", "db-interactive-cmd", "通过EXPLAIN VERBOSE执行query分析执行计划时会提示WARNING信息"),
    ("chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has", "pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史）", "db-system-view", "SELECT start_time, block_time, duration, sql_hash, warning, max_peak_memory, max_spill_size, query_plan FROM pgxc_wlm_session_info were start_time > 'xxxx-xx-xx xx:xx' and sql_hash = 'xxx' ORDER BY start_time desc limit 10;"),
    ("chk-pgxc-stat-activity-state-waiting-enqueue", "PGXC_STAT_ACTIVITY · state / waiting / enqueue", "db-system-view", "SELECT coorname, usename,client_addr,application_name,state,waiting,enqueue,pid FROM PGXC_STAT_ACTIVITY WHERE DATNAME='数据库名称';"),
    ("chk-pg-locks", "pg_locks · 阻塞会话与持锁会话关联", "db-system-view", "- **abnormal_patterns**: [\"`该查询返回会话ID、CN名称、用户信息、查询状态，以及导致阻塞的表、模式信息。`\"]"),
    ("chk-dws-connector-connectiontimeout", "DWS-Connector connectionTimeOut 默认值", "db-shell", "DWS-Connector默认超时时间connectionTimeOut为5min，可调大该值。"),
    ("chk-pg-stat-activity-pg-locks-sql-8-0-x", "pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本）", "db-system-view", "- **abnormal_patterns**: [\"NULL\"]"),
    ("chk-null-009", "写入方式", "db-shell", "如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈"),
    ("chk-null-010", "各节点磁盘使用率均衡性", "db-system-view", "登录DWS控制台。在\"集群列表\"页面，找到需要查看监控的集群。在指定集群所在行的\"操作\"列，单击\"监控面板\"。选择\"监控 > 节点监控 > 磁盘\"，查看磁盘使用率。"),
    ("chk-explain-verbose-remote", "EXPLAIN VERBOSE · __REMOTE 关键字", "db-interactive-cmd", "通过EXPLAIN VERBOSE打印语句执行计划。上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。"),
    ("chk-cn", "CN日志 · 不下推原因", "log-grep", "不下推语句在pg_log中会打印不下推的原因，上述语句在CN的日志中会找到类似以下的日志。"),
    ("chk-nestloop", "执行计划算子类型（NestLoop出现）", "db-interactive-cmd", "通过EXPLAIN VERBOSE打印语句执行计划，查看执行计划发现SQL语句中存在not in语句"),
    ("chk-explain-partitioned-cstore-scan-selected-partitions", "EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量", "db-interactive-cmd", "收集几个典型的慢SQL语句，分别打印执行计划。从执行计划中可以看出来，两条SQL的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分区扫描上。"),
    ("chk-i-o-cpu", "系统资源 I/O / 内存 / CPU 使用情况", "os", "排查当前的I/O、内存、CPU使用情况，没有发现资源占用高的情况。"),
    ("chk-gstack-vecnestloopruntime", "gstack · 进程堆栈中 VecNestLoopRuntime", "os", "联系运维人员登录到相应的实例节点上，打印等待状态为none的线程堆栈信息"),
    ("chk-cstore-scan", "执行计划算子：CStore Scan耗时占比", "db-interactive-cmd", "通过抓取问题SQL的执行信息，发现大部分的耗时都在\\\"CStore Scan\\"),
    ("chk-cudesc-cu-row-count", "cudesc表中CU的row_count分布", "db-system-view", "- **abnormal_patterns**: [\"row_count << 60000\"]"),
    ("chk-cu", "执行计划中CU扫描数量", "db-interactive-cmd", "查看偶发慢业务慢时的执行计划信息，慢在cstore scan，且扫描数据量不大但扫描CU个数较多"),
    ("chk-explain-cstore-scan-cusome-cunone", "EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数", "db-interactive-cmd", "分析计划主要耗时在Cstore Scan。Cstore Scan的详细信息中，每个DN扫描出2w左右的数据，但是扫描了有数据的CU（CUSome）155079个，没有数据的CU（CUNone）156375个"),
    ("chk-explain-scan-vs", "EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数", "db-interactive-cmd", "某业务SQL总执行时间2.519s，其中Scan占了2.516s，同时该表的扫描最终只扫描到0条符合条件数据，过滤了20480条数据"),
    ("chk-null-012", "表脏页率", "db-system-view", "查看表脏页率为99%，VACUUM FULL后性能优化到100ms左右。"),
    ("chk-explain-scan-a-time-max-min-dn", "EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比", "db-interactive-cmd", "表Scan的A-time中，max time DN执行耗时6554ms，min time DN耗时0s，DN之间扫描差异超过10倍以上"),
    ("chk-table-distribution-dn", "table_distribution 各DN数据行数", "db-system-view", "通过table_distribution发现所有数据倾斜到了dn_6009单个DN"),
    ("chk-explain-seq-scan-vs-index-scan", "EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan）", "db-interactive-cmd", "Seq Scan扫描需要3767ms，因涉及从4096000条数据中获取8240条数据，符合索引扫描的场景（海量数据中寻找少量数据），在对过滤条件列增加索引后，计划依然是Seq Scan而没有走Index Scan。"),
    ("chk-explain-selected-partitions", "EXPLAIN 执行计划 · Selected Partitions 数量", "db-interactive-cmd", "对该表设计为分区表后没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms，I/O效率极低。"),
    ("chk-pv-total-memory-detail-process-used-memory-vs-max-process-me", "pv_total_memory_detail · process_used_memory vs max_process_memory", "db-system-view", "pv_total_memory_detail"),
    ("chk-null-013", "列存表文件大小监控", "db-system-view", "列存表数据按列存储，一列的每60000行存储为一个CU，同一列的CU连续存储在一个文件中，当该文件大于1GB时，切换到新文件中。CU文件数据不能更改只能追加写。"),
    ("chk-pgxc-get-table-skewness", "PGXC_GET_TABLE_SKEWNESS 视图", "db-system-view", "分布差可以通过视图[PGXC_GET_TABLE_SKEWNESS]查看。"),
    ("chk-dms", "DMS 监控 · 节点磁盘使用率", "db-system-view", "选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。"),
    ("chk-dms-max-min", "DMS · 节点磁盘使用率排序 (max - min)", "db-system-view", "选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。"),
    ("chk-cpu-1-3-12-24", "节点 CPU 使用率 (1/3/12/24 小时)", "os", "选择“监控 > 节点监控 > 概览”可查看当前集群各节点CPU使用率的具体情况，单击最右的监控按钮，查看最近1/3/12/24小时的CPU性能指标"),
    ("chk-cpu", "资源池 CPU 限额 / 配额配置", "db-system-view", "设置资源池CPU限额与配额。"),
    ("chk-explain-in-join", "EXPLAIN · in 条件是否转为 join", "db-interactive-cmd", "打印语句的执行计划"),
    ("chk-explain", "EXPLAIN · 执行计划顺序扫描阶段耗时", "db-interactive-cmd", "EXPLAIN` 查看多表 JOIN 执行计划"),
    ("chk-base-pgsql-tmp-pgsql-tmp-queryid-pid", "base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件", "os", "下盘文件位于实例目录的base/pgsql_tmp路径下，下盘文件以 pgsql_tmp$queryid_$pid 命名"),
    ("chk-pgxc-thread-wait-status-wait-status-write-file", "pgxc_thread_wait_status · wait_status='write file'", "db-system-view", "等待视图中，当出现write file时，表示发生了中间结果下盘"),
    ("chk-explain-performance-spill-written-disk-temp-file-num", "EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字", "db-interactive-cmd", "performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。"),
    ("chk-topsql-spill-info", "TopSQL.spill_info", "db-system-view", "实时TopSQL语句或历史TopSQL语句中，spill_info字段中会包含下盘信息，如果该字段不为空，说明有DN实例出现了下盘。"),
    ("chk-explain-analyze-join", "EXPLAIN ANALYZE · JOIN 算子类型及执行时间", "db-interactive-cmd", "EXPLAIN ANALYZE` 查看两表 JOIN 的算子类型"),
    ("chk-explain-analyze-agg", "EXPLAIN ANALYZE · Agg 算子类型及执行时间", "db-interactive-cmd", "EXPLAIN ANALYZE` 查看聚合操作算子选择"),
    ("chk-explain-performance-vs-a-rows-vs-e-rows", "EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows）", "db-interactive-cmd", "EXPLAIN PERFORMANCE` 查看 TPC-DS Q24 部分语句执行计划"),
    ("chk-explain-data-node-scan", "EXPLAIN · 是否含 Data Node Scan 节点", "db-interactive-cmd", "如果执行计划中有Data Node Scan节点，那么此执行计划为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。"),
    ("chk-explain-performance", "EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子", "db-interactive-cmd", "EXPLAIN PERFORMANCE` 查看是否有 Vector 前缀算子"),
    ("chk-copy", "COPY 语句等待视图 · 轻量级锁等待", "db-system-view", "根据这5个COPY语句对应的query_id查看等待视图情况"),
    ("chk-explain-performance-cpu-io", "EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络)", "db-interactive-cmd", "通过执行态信息，我们可以分析出算子为单位的性能，也可以分析出算子内部各步骤的性能，进一步为诊断性能的瓶颈打下了基础。"),
    ("chk-vacuum-defer-cleanup-age", "vacuum_defer_cleanup_age 参数值", "db-shell", "参数vacuum_defer_cleanup_age不是0，该参数在老版本默认为8000，表示最近8000个事务产生的脏数据不进行回收。"),
    ("chk-dn-warning", "DN 间导入行数倾斜率(WARNING)", "log-grep", "WARNING:  Skewness occurs, table name: xxx, min value: xxx, max value: xxx, sum value: xxx, avg value: xxx, skew ratio: xxx"),
    ("chk-a-time-dn", "算子 A-time(在单 DN 上的运行耗时)", "db-interactive-cmd", "- **abnormal_patterns**: [\"NULL\"]"),
]

# (check_id, name, layer) · 8 条 skip · 蒸馏没抽到 method
SKIP = [
    ("chk-pg-log-statistics-warning", "pg_log 日志中的 Statistics WARNING", "log-grep"),
    ("chk-hstore-delta-vs-cu", "HStore Delta表大小 vs 主表CU数据", "db-system-view"),
    ("chk-vs", "列存表物理大小 vs 有效数据量", "db-shell"),
    ("chk-cn-pg-log-warning", "CN pg_log 日志中 Warning 信息", "log-grep"),
    ("chk-max-process-memory-shared-buffers-work-mem", "max_process_memory / shared_buffers / work_mem 内存参数", "db-system-view"),
    ("chk-vs", "脏数据膨胀率 / 表实际大小 vs 有效数据量", "db-system-view"),
    ("chk-explain", "EXPLAIN执行计划耗时分布", "db-interactive-cmd"),
    ("chk-abort-transaction-due-to-concurrent-update", "数据库错误日志 · abort transaction due to concurrent update", "log-grep"),
]

# ── 主循环 ────────────────────────────────────────────────────────────────
print(f'开始: {len(CHECKS)} 个 auto 命令 · timeout {TIMEOUT}s · outdir {OUTDIR}', flush=True)
report = OUTDIR / 'report.tsv'
with open(report, 'w', encoding='utf-8') as rf:
    import socket as _sk
    rf.write(f'# deploy_form\t{DEPLOY_FORM}\n')
    rf.write(f'# detected_at\t{datetime.now().astimezone().isoformat(timespec="seconds")}\n')
    rf.write(f'# host\t{_sk.gethostname()}\n')
    rf.write(f'# user\t{os.environ.get("USER", "unknown")}\n')
    rf.write('check_id\texit_code\tstatus\n')
    # 自动 dispatch: SQL 起始词走 gsql -f, 其他走 bash -c
    SQL_FIRST = {'SELECT','EXPLAIN','SHOW','WITH','SET','VACUUM','ANALYZE','CREATE',
                 'ALTER','DROP','TRUNCATE','UPDATE','INSERT','DELETE','COPY','REINDEX',
                 'CHECKPOINT','GRANT','REVOKE','RESET','BEGIN','COMMIT','ROLLBACK','CALL','VALUES'}
    import tempfile, re as _re
    for i, (cid, name, layer, method, topo) in enumerate(CHECKS, 1):
        # topology 过滤: 部署形态与 check 适用范围冲突 → 跳过(标 skip-topology · 可审计)
        if (DEPLOY_FORM in ('centralized', 'single-node') and topo == 'distributed-only') or \
           (DEPLOY_FORM == 'distributed' and topo == 'centralized-only'):
            rf.write(f'{cid}\t-\tskip-topology\n')
            continue
        # 取第一个非注释 token 大写化
        first = ''
        for tok in _re.split(r'\s+', method.strip()):
            if tok and not tok.startswith('--'):
                first = _re.sub(r'[^A-Z0-9_]', '', tok.upper())
                break
        is_sql = first in SQL_FIRST
        try:
            if is_sql:
                with tempfile.NamedTemporaryFile('w', suffix='.sql', delete=False) as tf:
                    tf.write(method)
                    sqlf = tf.name
                r = subprocess.run(['gsql','-d','postgres','-f',sqlf],
                                   capture_output=True, timeout=TIMEOUT)
                os.unlink(sqlf)
            else:
                r = subprocess.run(['bash','-c', method], capture_output=True, timeout=TIMEOUT)
            rc = r.returncode
            (OUTDIR / 'stdout' / f'{cid}.txt').write_bytes(r.stdout)
            (OUTDIR / 'stderr' / f'{cid}.txt').write_bytes(r.stderr)
            # ghost-ok detector: gsql -f 默认 batch · SQL 报错也 exit 0
            # rc=0 且 sql 类时 grep stderr 含 ERROR/FATAL/PANIC → ghost-ok-sql-error
            if rc == 0 and is_sql and r.stderr:
                import re as _re2
                if _re2.search(rb'(?m)^(gsql:.+:\s*)?(ERROR|FATAL|PANIC):', r.stderr):
                    # 二级判定: 部署形态特异 (集中式跑分布式专用视图/函数) · 拉分布式会 ok
                    # pgxc_* 在集中式报 'Relation "pgxc_xxx" does not exist' · 也算 (只认 pgxc_ 前缀)
                    if _re2.search(rb'Unsupported view in single node mode|Unsupported function|Function [a-z_]+\([^)]*\) does not exist|does not support|not supported in (single|centralized)|[Rr]elation "(pgxc_|pg_catalog\.pgxc_)[a-z0-9_]+" does not exist', r.stderr, _re2.I):
                        status = 'unsupported-deploy-form'
                    else:
                        status = 'ghost-ok-sql-error'
                else:
                    status = 'ok'
            elif rc == 0:
                status = 'ok'
            else:
                status = f'error-rc{rc}'
        except subprocess.TimeoutExpired as e:
            rc = 124
            status = 'timeout'
            (OUTDIR / 'stdout' / f'{cid}.txt').write_bytes(e.stdout or b'')
            (OUTDIR / 'stderr' / f'{cid}.txt').write_bytes((e.stderr or b'') + f'\n[TIMEOUT {TIMEOUT}s]'.encode())
        rf.write(f'{cid}\t{rc}\t{status}\n')
        if i % 30 == 0 or i == len(CHECKS):
            print(f'  [{i}/{len(CHECKS)}] {cid}', file=sys.stderr, flush=True)

# manual.md
manual_lines = [f'# 需人审 method (描述性中文 · 不自动跑 · 共 {len(MANUAL)} 项)', '',
                '> distill-v2 蒸馏的描述性文本 · 不能直接 shell 跑 · 请人工解读后手工执行', '']
for cid, name, layer, method in MANUAL:
    manual_lines += [f'## {cid} · {name}', f'- layer: `{layer}`',
                     '- method:', '  ```', f'  {method}', '  ```', '']
(OUTDIR / 'manual.md').write_text('\n'.join(manual_lines), encoding='utf-8')

# skip.md
skip_lines = [f'# Skip-empty method (蒸馏没抽到 · 共 {len(SKIP)} 项)', '']
for cid, name, layer in SKIP:
    skip_lines.append(f'- `{cid}` · {name} (layer=`{layer}`)')
(OUTDIR / 'skip.md').write_text('\n'.join(skip_lines), encoding='utf-8')

print()
print('─────────────────────────────────────────────')
print(f'完成 · TOTAL={len(CHECKS)+len(MANUAL)+len(SKIP)} · auto={len(CHECKS)} · manual={len(MANUAL)} · skip={len(SKIP)}')
print(f'  报告:         {report}')
print(f'  stdout 目录:  {OUTDIR}/stdout/')
print(f'  stderr 目录:  {OUTDIR}/stderr/')
print(f'  人审 ({len(MANUAL)}): {OUTDIR}/manual.md')
print(f'  空 method ({len(SKIP)}): {OUTDIR}/skip.md')
