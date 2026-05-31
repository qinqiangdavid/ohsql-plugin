#!/usr/bin/env python3
"""GaussDB 离线采集 · 预编译版 · 自包含 · python 纯 stdlib.

所有 48 个 auto 命令已 inline 在 CHECKS list 里 (不解析 ndjson).

生成时间: 2026-05-31T12:53:54.429Z
数据: auto=48 · manual=226 · skip=1 · total=342

用法:
  source ~/gauss_env_file
  python3 collect-precompiled.py [outdir]

环境变量:
  COLLECT_TIMEOUT  单命令超时秒 · 默认空=不超时 · IOSTAT_INTERVAL/IOSTAT_COUNT iostat 采样(默认 1/2)

依赖: python3 3.6+ · bash (用来跑 method)
"""
import os, subprocess, sys
from pathlib import Path
from datetime import datetime

OUTDIR = Path(sys.argv[1] if len(sys.argv) > 1 else f'./collect-results-{datetime.now().strftime("%Y%m%d-%H%M%S")}')
# 端口入参(argv[2])优先 · 否则用 PGPORT 环境变量 · 设进 os.environ 后所有 gsql 都用它
if len(sys.argv) > 2 and sys.argv[2].strip():
    os.environ['PGPORT'] = sys.argv[2].strip()
TIMEOUT = int(os.environ['COLLECT_TIMEOUT']) if os.environ.get('COLLECT_TIMEOUT') else None  # 默认 None=不超时
os.environ.setdefault('TERM', 'dumb')  # top/sar 等 tty 工具非交互需 TERM
OUTDIR.mkdir(parents=True, exist_ok=True)

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

# (check_id, name, layer, method, topology) · 48 条 auto · 直接跑
CHECKS = [
    ("chk-dbe-perf-statement-cpu-time", "dbe_perf.statement.cpu_time", "db-system-view", "select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_elapse_time/1000,2) as total_time,round(cpu_time/1000,2) as cup_time from dbe_perf.statement t where  n_calls>10 and avg_time>3  and user_name='root'  order by cpu_time desc limit 5;", "common"),
    ("chk-sql", "慢SQL及调用频次", "db-system-view", "select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;", "common"),
    ("chk--2", "回放日志类型统计", "db-interactive-cmd", "select * from local_xlog_redo_statics()", "common"),
    ("chk-buffer-hit-rate-read-buffer-io", "buffer_hit_rate / read_buffer_io", "db-interactive-cmd", "select * from gs_redo_stat_info()", "common"),
    ("chk-wait-read-data", "WAIT_READ_DATA", "db-system-view", "select * from dbe_perf.GLOBAL_WAIT_EVENTS where wait!=0 order by total_wait_time desc;", "common"),
    ("chk-io", "磁盘IO信息", "os", "iostat -c -x -m ${IOSTAT_INTERVAL:-1} ${IOSTAT_COUNT:-2}", "common"),
    ("chk-wait-event-count", "wait_event_count", "db-system-view", "select wait_status,wait_event,count(*) from pg_thread_wait_status group by wait_status,wait_event order by 3 desc;", "common"),
    ("chk-pg-total-memory-detail", "pg_total_memory_detail", "db-system-view", "select * from pg_total_memory_detail;", "common"),
    ("chk-thread-session-memory-context", "thread_session_memory_context", "db-system-view", "select contextname, sum(totalsize)/1024/1024 totalsize, sum(freesize)/1024/1024 freesize, count(*) sum from gs_thread_memory_context group by contextname order by sum desc limit 10;", "common"),
    ("chk-autovacuum-settings", "autovacuum_settings", "db-system-view", "select * from pg_settings where name like '%vacuum%';", "centralized-only"),
    ("chk-wait-cmd", "wait cmd计数", "db-system-view", "select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;", "common"),
    ("chk-sql-cpu", "SQL CPU消耗", "db-system-view", "select * from gs_asp where sample_time > now() - interval '10 minute' order by sample_time;", "common"),
    ("chk--18", "复制槽推动速度", "db-system-view", "select * from dbe_perf.global_replication_stat;", "common"),
    ("chk-io-io", "磁盘IO性能和IO调度算法", "os", "grep -H . /sys/block/*/queue/scheduler 2>/dev/null", "common"),
    ("chk-pgxc-stat-activity-state", "pgxc_stat_activity state", "db-system-view", "select state, count(*) from pgxc_stat_activity group by state;", "distributed-only"),
    ("chk-cn", "CN节点压力分布", "db-system-view", "select coorname, count(*) from pgxc_stat_activity group by coorname order by 2 desc;", "distributed-only"),
    ("chk-dropped-packets-count", "dropped packets count", "db-shell", "cat /proc/net/dev", "common"),
    ("chk-net-core-netdev-max-backlog", "net.core.netdev_max_backlog", "os", "sysctl net.core.netdev_max_backlog", "common"),
    ("chk-pg-stat-get-last-data-changed-time", "近期数据变更表列表（pg_stat_get_last_data_changed_time）", "db-system-view", "SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();", "distributed-only"),
    ("chk-pgxc-get-table-skewness", "PGXC_GET_TABLE_SKEWNESS", "db-system-view", "SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;", "distributed-only"),
    ("chk-table-distribution-dn-1w", "table_distribution() 各DN空间（大表个数超1W场景）", "db-system-view", "SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace INNER JOIN pg_catalog.table_distribution() s ON s.schemaname = n.nspname AND s.tablename = c.relname INNER JOIN pg_catalog.pgxc_class x ON c.oid = x.pcrelid AND x.pclocatortype = 'H' GROUP BY schemaname,tablename;", "distributed-only"),
    ("chk-top-sar-gaussdb-cpu", "top / sar 中 gaussdb 进程 CPU 占用", "os", "top -b -n 1", "common"),
    ("chk-pgxc-thread-wait-status-wait-status", "pgxc_thread_wait_status.wait_status", "db-system-view", "Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;", "distributed-only"),
    ("chk-sql-create-index", "活跃SQL及CREATE INDEX语句", "db-system-view", "select * from pg_stat_activity where state !='idle' and usename !='omm';", "distributed-only"),
    ("chk-pgxc-get-stat-all-tables-dirty-page-rate", "PGXC_GET_STAT_ALL_TABLES.dirty_page_rate", "db-system-view", "SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_GET_STAT_ALL_TABLES WHERE schemaName NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'cstore', 'pmk') AND dirty_page_rate > 30 ORDER BY table_size DESC, dirty_page_rate DESC;", "distributed-only"),
    ("chk-pgxc-wlm-session-info-streaming-stream-count", "pgxc_wlm_session_info · Streaming 算子数（stream_count）", "db-system-view", "SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM pgxc_wlm_session_info ORDER BY stream_count DESC limit 100;", "distributed-only"),
    ("chk-pgxc-stat-activity-runtime-current-timestamp-query-start", "PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start)", "db-system-view", "SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle' order by 1 desc;", "distributed-only"),
    ("chk-pgxc-stat-activity-waiting-true", "PGXC_STAT_ACTIVITY · waiting=true 阻塞查询", "db-system-view", "SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;", "distributed-only"),
    ("chk-pgxc-lock-conflicts", "pgxc_lock_conflicts 锁冲突视图", "db-system-view", "SELECT * FROM pgxc_lock_conflicts;", "distributed-only"),
    ("chk-pgxc-stat-activity-state-waiting-query", "pgxc_stat_activity · state / waiting / query", "db-system-view", "SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';", "distributed-only"),
    ("chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic-", "pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory", "db-system-view", "SELECT * FROM pgxc_total_memory_detail;", "distributed-only"),
    ("chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc", "pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent", "db-system-view", "SELECT nodename,pid,dbname,username,application_name,min_peak_memory,max_peak_memory,average_peak_memory,memory_skew_percent,substr(query,0,50) as query FROM pgxc_wlm_session_statistics;", "distributed-only"),
    ("chk-pgxc-thread-wait-status-dn", "pgxc_thread_wait_status · 作业等待 DN 分布", "db-system-view", "SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;", "distributed-only"),
    ("chk-pg-stat-activity-sql", "pg_stat_activity 活跃SQL", "db-system-view", "SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';", "distributed-only"),
    ("chk-pg-session-wlmstat-status-statement-mem", "pg_session_wlmstat · status / statement_mem", "db-system-view", "SELECT usename,substr(query,0,20),threadid,status,statement_mem FROM pg_session_wlmstat where usename not in ('omm','Ruby') order by statement_mem,status desc;", "distributed-only"),
    ("chk-pgxc-thread-wait-status-wait-status-wait-event", "pgxc_thread_wait_status · wait_status / wait_event", "db-system-view", "SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_status <> 'synchronize quit' AND wait_status <> 'none'  GROUP BY 1,2 ORDER BY 3 DESC limit 50;", "distributed-only"),
    ("chk-pg-partition", "pg_partition 各表分区数", "db-system-view", "SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition GROUP BY parentid ) s ON c.oid = s.parentid ORDER BY partcount DESC;", "distributed-only"),
    ("chk-pgxc-stat-activity-vacuum-full-8-0-x", "pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前）", "db-system-view", "SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';", "distributed-only"),
    ("chk-dn-4", "磁盘利用率各 DN 差异", "db-shell", "SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc", "distributed-only"),
    ("chk-pgxc-stat-activity-state-2", "pgxc_stat_activity state 字段", "db-system-view", "SELECT state, query, query_id FROM pgxc_stat_activity;", "distributed-only"),
    ("chk-cn-savepoint-release", "各 CN 上 SAVEPOINT/RELEASE 语句分布", "db-system-view", "SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';", "distributed-only"),
    ("chk-gs-wlm-session-history-warning-sql", "GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息", "db-system-view", "SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC", "distributed-only"),
    ("chk-gs-wlm-session-history-warning", "GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警", "db-system-view", "SELECT query,warning FROM GS_WLM_SESSION_STATISTICS ORDER BY start_time DESC", "distributed-only"),
    ("chk-xid", "当前事务 XID", "db-system-view", "SELECT txid_current();", "distributed-only"),
    ("chk--49", "活跃事务列表", "db-system-view", "SELECT txid_current_snapshot();", "distributed-only"),
    ("chk-gtm-snapshot-oldestxmin-xid", "GTM snapshot · oldestxmin 与 xid 差值", "db-system-view", "SELECT * FROM pgxc_gtm_snapshot_status();", "distributed-only"),
    ("chk-slow-sql-statement-history", "statement_history 慢 SQL 明细 (全列 + 等待事件解码)", "db-system-view", "SELECT db_name, user_name, unique_query_id, substr(query,1,200) AS query, start_time, finish_time, db_time, cpu_time, execution_time, n_returned_rows, n_tuples_fetched, n_blocks_fetched, n_blocks_hit, (n_blocks_fetched-n_blocks_hit) AS phys_read, lock_wait_time, lwlock_wait_time, statement_detail_decode(details, 'plaintext', true) AS wait_events, is_slow_sql FROM statement_history WHERE is_slow_sql ORDER BY start_time DESC LIMIT 20;", "common"),
    ("chk-guc-pg-settings-all", "GUC 全量 (pg_settings · 整合自 65 条单独 SHOW)", "db-system-view", "SELECT name, setting, unit, context FROM pg_settings ORDER BY name;", "common"),
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
    rf.write('# 注: 只记异常(skip-topology/skip-write-guard/error/timeout/ghost/unsupported) · ok 的数据在 <check_id>.txt\n')
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
        # 只读护栏 (防御纵深): 拒跑任何写/改/杀命令 · 即使源数据漂移/手改也绝不执行
        # build 时分类器(classify.mjs r18)已保证 auto 严格只读 · 这是最后一道闸.
        WRITE_FIRST = {'INSERT','UPDATE','DELETE','DROP','TRUNCATE','ALTER','CREATE',
                       'VACUUM','ANALYZE','REINDEX','CHECKPOINT','COPY','GRANT','REVOKE','CALL'}
        if first in WRITE_FIRST or _re.search(
                r'\b(pg_terminate_backend|pg_cancel_backend|gs_clean|pg_log_backtrace|gs_signal_thread)\b',
                method, _re.I):
            rf.write(f'{cid}\t-\tskip-write-guard\n')
            with open(OUTDIR / 'errors.log', 'ab') as _ef:
                _ef.write(f'===== {cid} (skip-write-guard) =====\n[只读护栏] 命中写/破坏性模式 · 未执行\n'.encode()
                          + method.encode() + b'\n')
            continue
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
            (OUTDIR / f'{cid}.txt').write_bytes(r.stdout)
            if r.stderr:
                with open(OUTDIR / 'errors.log', 'ab') as _ef:
                    _ef.write(f'===== {cid} =====\n'.encode() + r.stderr + b'\n')
            # ghost-ok detector: gsql -f 默认 batch · SQL 报错也 exit 0
            # rc=0 且 sql 类时 grep stderr 含 ERROR/FATAL/PANIC → ghost-ok-sql-error
            if rc == 0 and is_sql and r.stderr:
                import re as _re2
                if _re2.search(rb'(?m)^(gsql:.+:\s*)?(ERROR|FATAL|PANIC):', r.stderr):
                    # 二级判定: 部署形态特异 (集中式跑分布式专用视图/函数) · 拉分布式会 ok
                    # pgxc_* 在集中式报 'Relation "pgxc_xxx" does not exist' · 也算 (只认 pgxc_ 前缀)
                    if _re2.search(rb'Unsupported view in single node mode|unrecognized configuration parameter|Unsupported function|Function [a-z_]+\([^)]*\) does not exist|does not support|not supported in (single|centralized)|[Rr]elation "(pgxc_|pg_catalog\.pgxc_|gs_|dbe_perf\.)[a-z0-9_]+" does not exist', r.stderr, _re2.I):
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
            (OUTDIR / f'{cid}.txt').write_bytes(e.stdout or b'')
            with open(OUTDIR / 'errors.log', 'ab') as _ef:
                _ef.write(f'===== {cid} =====\n'.encode() + (e.stderr or b'') + f'\n[TIMEOUT {TIMEOUT}s]\n'.encode())
        # report.tsv 只记异常(非 ok) · ok 的数据在 <cid>.txt 不再冗余记一行
        if status != 'ok':
            rf.write(f'{cid}\t{rc}\t{status}\n')
        if i % 30 == 0 or i == len(CHECKS):
            print(f'  [{i}/{len(CHECKS)}] {cid}', file=sys.stderr, flush=True)

print()
print('─────────────────────────────────────────────')
print(f'完成 · auto={len(CHECKS)}(本脚本只跑这些)')
print(f'  异常清单:     {report} (只记非 ok)')
print(f'  数据文件:    {OUTDIR}/<check_id>.txt (每条 check 一个)')
print(f'  报错汇总:    {OUTDIR}/errors.log')
print('  人审清单:     见 kit 内独立文件 manual-audit.md (不在本采集脚本内)')
