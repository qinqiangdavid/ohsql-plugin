#!/usr/bin/env bash
# GaussDB 离线采集 · 预编译版 · 完全自包含
# 所有 142 个 auto 命令已 inline 为 heredoc (不解析 ndjson · 不需 jq).
#
# 生成时间: 2026-05-31T03:36:10.892Z
# 数据: auto=142 · manual=199 · skip=1 · total=342
#
# 用法:
#   source ~/gauss_env_file                      # 先 source gsql env (如需要)
#   ./collect-precompiled.sh [outdir] [port]     # port 作为入参 · 不传则用 PGPORT 环境变量
#   ./collect-precompiled.sh /tmp/out 37000      # 端口 37000 (env 没设 PGPORT 时必传)
#
# 环境变量:
#   COLLECT_TIMEOUT  单命令超时秒 · 默认空=不杀(去掉超时杀进程逻辑)· 设了才兜底
#   IOSTAT_INTERVAL / IOSTAT_COUNT  iostat 采样间隔秒/次数 (default 1 / 2)
#   PGPORT           gsql 端口 · 命令行第 2 入参优先于此
#
# 依赖: bash 3+ · mktemp · (可选) GNU timeout / gtimeout

set -uo pipefail
OUTDIR="${1:-./collect-results-$(date +%Y%m%d-%H%M%S)}"
# 端口入参($2)优先 · 否则用 PGPORT 环境变量 · export 后所有 gsql(含字面 gsql 命令)都用它
PORT="${2:-${PGPORT:-}}"
[ -n "$PORT" ] && export PGPORT="$PORT"
TIMEOUT="${COLLECT_TIMEOUT:-}"   # 默认空=不杀进程 · 设了才启用单命令超时
T_BIN=$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || echo "")
# top / sar / vmstat 等 tty 工具在非交互 shell 会抱怨 TERM unset · 给个 dumb 兜底
export TERM="${TERM:-dumb}"
mkdir -p "$OUTDIR"

# ── 部署形态自识别 (集中式 / 分布式 / 单节点) ──────────────────────────────
# 用 GaussDB 内置函数 pg_catalog.gs_deployment() (C immutable · 返回 text).
# 实测返回值:
#   BusinessCentralized   → 集中式 (商用版)
#   Distribute            → 分布式 (含 CN/DN 拓扑)
#   SingleNode 类         → 单节点 (兜底匹配)
# 这函数 GaussDB 内核保证一致 · 不依赖 GUC 注册时机 / catalog schema 残留.
detect_deploy_form() {
  command -v gsql >/dev/null 2>&1 || { echo "unknown-no-gsql"; return; }
  local v
  v=$(gsql -d postgres -t -A -c "SELECT pg_catalog.gs_deployment()" 2>/dev/null | tr -d '[:space:]')
  local lower
  lower=$(echo "$v" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
    *centralized*) echo "centralized" ;;
    *distribut*)   echo "distributed" ;;
    *single*node*|*singlenode*) echo "single-node" ;;
    "") echo "unknown-detect-fail" ;;
    *)  echo "unknown-$v" ;;
  esac
}
DEPLOY_FORM=$(detect_deploy_form)
echo "部署形态自识别: $DEPLOY_FORM" >&2
case "$DEPLOY_FORM" in
  unknown*) echo "⚠️ topology-filter-disabled: deploy_form=$DEPLOY_FORM · 全采(不按 topology 跳过)" >&2 ;;
esac

# 写到 report 头部元数据 (注释行 · 也 dump 到 deploy.txt 便于程序解析)
{
  printf '# deploy_form\t%s\n' "$DEPLOY_FORM"
  printf '# detected_at\t%s\n' "$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '# host\t%s\n' "$(hostname 2>/dev/null || echo unknown)"
  printf '# user\t%s\n' "$(whoami)"
  printf '# 注: 只记异常(skip-topology/error/timeout/ghost/unsupported) · ok 的数据在 <check_id>.txt\n'
  printf 'check_id\texit_code\tstatus\n'
} > "$OUTDIR/report.tsv"
printf '%s\n' "$DEPLOY_FORM" > "$OUTDIR/deploy.txt"

run_check() {
  # 用法: run_check <check_id> <<'EOF_XXX'
  #         <真命令>
  #       EOF_XXX
  # 自动 dispatch: 起始词是 SQL 关键字 → gsql -f, 否则 bash.
  local cid="$1"
  local topo="${2:-common}"
  # topology 过滤: 部署形态与 check 适用范围冲突 → 跳过(标 skip-topology · 可审计 · 不悄悄消失)
  case "$DEPLOY_FORM" in
    centralized|single-node)
      if [ "$topo" = "distributed-only" ]; then
        printf '%s\t%s\t%s\n' "$cid" "-" "skip-topology" >> "$OUTDIR/report.tsv"; cat >/dev/null; return
      fi ;;
    distributed)
      if [ "$topo" = "centralized-only" ]; then
        printf '%s\t%s\t%s\n' "$cid" "-" "skip-topology" >> "$OUTDIR/report.tsv"; cat >/dev/null; return
      fi ;;
  esac
  local tmpf serr
  tmpf=$(mktemp)
  serr=$(mktemp)
  cat > "$tmpf"
  # 取第一个非空 token (大写化 · 砍标点)
  local first
  first=$(awk 'NF{for(i=1;i<=NF;i++)if($i!~/^--/){print toupper($i);exit}}' "$tmpf" | tr -d '[:punct:]')
  local cmd_kind="shell"
  case "$first" in
    SELECT|EXPLAIN|SHOW|WITH|SET|VACUUM|ANALYZE|CREATE|ALTER|DROP|TRUNCATE|UPDATE|INSERT|DELETE|COPY|REINDEX|CHECKPOINT|GRANT|REVOKE|RESET|BEGIN|COMMIT|ROLLBACK|CALL|VALUES)
      cmd_kind="sql" ;;
  esac
  # 默认不杀进程(TIMEOUT 空)· 仅当显式设了 COLLECT_TIMEOUT 才套 timeout 兜底
  local RUN=""
  [ -n "$TIMEOUT" ] && [ -n "$T_BIN" ] && RUN="$T_BIN $TIMEOUT"
  set +e
  if [ "$cmd_kind" = "sql" ]; then
    $RUN gsql -d postgres -f "$tmpf" > "$OUTDIR/$cid.txt" 2> "$serr"
  else
    $RUN bash "$tmpf" > "$OUTDIR/$cid.txt" 2> "$serr"
  fi
  local rc=$?
  set -e
  rm -f "$tmpf"
  local s
  case $rc in 0) s=ok;; 124) s=timeout;; *) s="error-rc$rc";; esac
  # ghost-ok detector: gsql -f 默认 batch · SQL 报错也 exit 0
  # rc=0 时 grep stderr 含 ERROR/FATAL/PANIC → 标 ghost-ok-sql-error 而非 ok
  # 只在 sql 类生效 (shell 类 stderr 含 ERROR 是正常输出 · 不算 ghost-ok)
  if [ "$s" = "ok" ] && [ "$cmd_kind" = "sql" ] && [ -s "$serr" ]; then
    if LC_ALL=C grep -qE '^(gsql:.+:[[:space:]]*)?(ERROR|FATAL|PANIC):' "$serr" 2>/dev/null; then
      # 二级判定: 部署形态特异 (集中式跑分布式专用视图/函数报错) · 不是真错
      # 这类 SQL 拉到分布式实例跑会 ok · 跟 distill 数据质量问题 (syntax error) 区分开
      # pgxc_* 分布式 catalog 在集中式报 'Relation "pgxc_xxx" does not exist' · 也算部署形态特异
      # (只认 pgxc_/pg_catalog.pgxc_ 前缀 · 不误伤 'Relation "t1" does not exist' 文档示例表)
      if LC_ALL=C grep -qiE 'Unsupported view in single node mode|Unsupported function|Function [a-z_]+\([^)]*\) does not exist|does not support|not supported in (single|centralized)|[Rr]elation "(pgxc_|pg_catalog\.pgxc_)[a-z0-9_]+" does not exist' "$serr" 2>/dev/null; then
        s=unsupported-deploy-form
      else
        s=ghost-ok-sql-error
      fi
    fi
  fi
  # stderr 汇总进单一 errors.log (按 cid 标记) · 不再每条一个 stderr 文件
  if [ -s "$serr" ]; then
    { echo "===== $cid ($s) ====="; cat "$serr"; echo; } >> "$OUTDIR/errors.log"
  fi
  rm -f "$serr"
  # report.tsv 只记异常(非 ok) · ok 的数据在 <cid>.txt 不再冗余记一行
  if [ "$s" != "ok" ]; then
    printf '%s\t%s\t%s\n' "$cid" "$rc" "$s" >> "$OUTDIR/report.tsv"
  fi
}

i=0
TOTAL=142
echo "开始: $TOTAL 个 auto 命令 · timeout ${TIMEOUT}s · outdir $OUTDIR"
echo ""

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dbe-perf-statement-cpu-time · dbe_perf.statement.cpu_time · layer=db-system-view
run_check "chk-dbe-perf-statement-cpu-time" "common" <<'EOF_CHK_DBE_PERF_STATEMENT_CPU_TIME'
select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_elapse_time/1000,2) as total_time,round(cpu_time/1000,2) as cup_time from dbe_perf.statement t where  n_calls>10 and avg_time>3  and user_name='root'  order by cpu_time desc limit 5;
EOF_CHK_DBE_PERF_STATEMENT_CPU_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-sql · 慢SQL及调用频次 · layer=db-system-view
run_check "chk-sql" "common" <<'EOF_CHK_SQL'
select unique_query_id, substr(query,1,80) q, db_time, cpu_time, execution_time from dbe_perf.statement_history order by db_time desc limit 20;
EOF_CHK_SQL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo · recovery_max_workers/recovery_parse_workers/recovery_redo_workers · layer=db-shell
run_check "chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo" "common" <<'EOF_CHK_RECOVERY_MAX_WORKERS_RECOVERY_PARSE_WORKERS_RECOVERY_REDO_WO'
show recovery_max_workers; show recovery_parse_workers; show recovery_redo_workers; show shared_buffers;
EOF_CHK_RECOVERY_MAX_WORKERS_RECOVERY_PARSE_WORKERS_RECOVERY_REDO_WO

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk--2 · 回放日志类型统计 · layer=db-interactive-cmd
run_check "chk--2" "common" <<'EOF_CHK__2'
select * from local_xlog_redo_statics()
EOF_CHK__2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-buffer-hit-rate-read-buffer-io · buffer_hit_rate / read_buffer_io · layer=db-interactive-cmd
run_check "chk-buffer-hit-rate-read-buffer-io" "common" <<'EOF_CHK_BUFFER_HIT_RATE_READ_BUFFER_IO'
select * from gs_redo_stat_info()
EOF_CHK_BUFFER_HIT_RATE_READ_BUFFER_IO

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-wait-read-data · WAIT_READ_DATA · layer=db-system-view
run_check "chk-wait-read-data" "common" <<'EOF_CHK_WAIT_READ_DATA'
select * from dbe_perf.GLOBAL_WAIT_EVENTS where wait!=0 order by total_wait_time desc;
EOF_CHK_WAIT_READ_DATA

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-io · 磁盘IO信息 · layer=os
run_check "chk-io" "common" <<'EOF_CHK_IO'
iostat -c -x -m ${IOSTAT_INTERVAL:-1} ${IOSTAT_COUNT:-2}
EOF_CHK_IO

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-wait-event-count · wait_event_count · layer=db-system-view
run_check "chk-wait-event-count" "common" <<'EOF_CHK_WAIT_EVENT_COUNT'
select wait_status,wait_event,count(*) from pg_thread_wait_status group by wait_status,wait_event order by 3 desc;
EOF_CHK_WAIT_EVENT_COUNT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-blocked-query · blocked_query · layer=db-system-view
run_check "chk-blocked-query" "common" <<'EOF_CHK_BLOCKED_QUERY'
select pid,sessionid,substr(query,0,100) from pg_stat_activity where sessionid in(select sessionid from pg_thread_wait_status where wait_event='wait_event');
EOF_CHK_BLOCKED_QUERY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-blocking-query · blocking_query · layer=db-system-view
run_check "chk-blocking-query" "common" <<'EOF_CHK_BLOCKING_QUERY'
select pid,sessionid,substr(query,0,100) from pg_stat_activity where sessionid in(select block_sessionid from pg_thread_wait_status where wait_event='wait_event');
EOF_CHK_BLOCKING_QUERY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-total-memory-detail · pg_total_memory_detail · layer=db-system-view
run_check "chk-pg-total-memory-detail" "common" <<'EOF_CHK_PG_TOTAL_MEMORY_DETAIL'
select * from pg_total_memory_detail;
EOF_CHK_PG_TOTAL_MEMORY_DETAIL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-thread-session-memory-context · thread_session_memory_context · layer=db-system-view
run_check "chk-thread-session-memory-context" "common" <<'EOF_CHK_THREAD_SESSION_MEMORY_CONTEXT'
select contextname, sum(totalsize)/1024/1024 totalsize, sum(freesize)/1024/1024 freesize, count(*) sum from gs_thread_memory_context group by contextname order by sum desc limit 10;
EOF_CHK_THREAD_SESSION_MEMORY_CONTEXT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-settings · autovacuum_settings · layer=db-system-view
run_check "chk-autovacuum-settings" "centralized-only" <<'EOF_CHK_AUTOVACUUM_SETTINGS'
select * from pg_settings where name like '%vacuum%';
EOF_CHK_AUTOVACUUM_SETTINGS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-wait-cmd · wait cmd计数 · layer=db-system-view
run_check "chk-wait-cmd" "common" <<'EOF_CHK_WAIT_CMD'
select wait_status, wait_event, count(*) from pg_thread_wait_status group by 1,2 order by 3 desc;
EOF_CHK_WAIT_CMD

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-sql-cpu · SQL CPU消耗 · layer=db-system-view
run_check "chk-sql-cpu" "common" <<'EOF_CHK_SQL_CPU'
select * from gs_asp where sample_time > now() - interval '10 minute' order by sample_time;
EOF_CHK_SQL_CPU

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-thread-pool-attr · thread_pool_attr · layer=db-shell
run_check "chk-thread-pool-attr" "common" <<'EOF_CHK_THREAD_POOL_ATTR'
show thread_pool_attr;
EOF_CHK_THREAD_POOL_ATTR

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk--18 · 复制槽推动速度 · layer=db-system-view
run_check "chk--18" "common" <<'EOF_CHK__18'
select * from dbe_perf.global_replication_stat;
EOF_CHK__18

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-io-io · 磁盘IO性能和IO调度算法 · layer=os
run_check "chk-io-io" "common" <<'EOF_CHK_IO_IO'
grep -H . /sys/block/*/queue/scheduler 2>/dev/null
EOF_CHK_IO_IO

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-state · pgxc_stat_activity state · layer=db-system-view
run_check "chk-pgxc-stat-activity-state" "distributed-only" <<'EOF_CHK_PGXC_STAT_ACTIVITY_STATE'
select state, count(*) from pgxc_stat_activity group by state;
EOF_CHK_PGXC_STAT_ACTIVITY_STATE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-cn · CN节点压力分布 · layer=db-system-view
run_check "chk-cn" "distributed-only" <<'EOF_CHK_CN'
select node_name, count(*) from pgxc_stat_activity group by node_name order by 2 desc;
EOF_CHK_CN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-undo-retention-time · undo_retention_time · layer=db-system-view
run_check "chk-undo-retention-time" "common" <<'EOF_CHK_UNDO_RETENTION_TIME'
show undo_retention_time;
EOF_CHK_UNDO_RETENTION_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dropped-packets-count · dropped packets count · layer=db-shell
run_check "chk-dropped-packets-count" "common" <<'EOF_CHK_DROPPED_PACKETS_COUNT'
cat /proc/net/dev
EOF_CHK_DROPPED_PACKETS_COUNT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-net-core-netdev-max-backlog · net.core.netdev_max_backlog · layer=os
run_check "chk-net-core-netdev-max-backlog" "common" <<'EOF_CHK_NET_CORE_NETDEV_MAX_BACKLOG'
sysctl net.core.netdev_max_backlog
EOF_CHK_NET_CORE_NETDEV_MAX_BACKLOG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-client-encoding-server-encoding · client encoding与server encoding配置 · layer=db-shell
run_check "chk-client-encoding-server-encoding" "distributed-only" <<'EOF_CHK_CLIENT_ENCODING_SERVER_ENCODING'
show client_encoding; show server_encoding;
EOF_CHK_CLIENT_ENCODING_SERVER_ENCODING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-get-last-data-changed-time · 近期数据变更表列表（pg_stat_get_last_data_changed_time） · layer=db-system-view
run_check "chk-pg-stat-get-last-data-changed-time" "distributed-only" <<'EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME'
SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();
EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-get-table-skewness · PGXC_GET_TABLE_SKEWNESS · layer=db-system-view
run_check "chk-pgxc-get-table-skewness" "distributed-only" <<'EOF_CHK_PGXC_GET_TABLE_SKEWNESS'
SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;
EOF_CHK_PGXC_GET_TABLE_SKEWNESS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-distribution-dn-1w · table_distribution() 各DN空间（大表个数超1W场景） · layer=db-system-view
run_check "chk-table-distribution-dn-1w" "distributed-only" <<'EOF_CHK_TABLE_DISTRIBUTION_DN_1W'
SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace INNER JOIN pg_catalog.table_distribution() s ON s.schemaname = n.nspname AND s.tablename = c.relname INNER JOIN pg_catalog.pgxc_class x ON c.oid = x.pcrelid AND x.pclocatortype = 'H' GROUP BY schemaname,tablename;
EOF_CHK_TABLE_DISTRIBUTION_DN_1W

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-dn · table_skewness() 各 DN 数据分布比例 · layer=db-system-view
run_check "chk-table-skewness-dn" "distributed-only" <<'EOF_CHK_TABLE_SKEWNESS_DN'
select table_skewness('inventory');
EOF_CHK_TABLE_SKEWNESS_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-get-last-data-changed-time-2 · pg_stat_get_last_data_changed_time 最近变更的表 · layer=db-system-view
run_check "chk-pg-stat-get-last-data-changed-time-2" "distributed-only" <<'EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME_2'
SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();
EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-top-sar-gaussdb-cpu · top / sar 中 gaussdb 进程 CPU 占用 · layer=os
run_check "chk-top-sar-gaussdb-cpu" "common" <<'EOF_CHK_TOP_SAR_GAUSSDB_CPU'
top -b -n 1
EOF_CHK_TOP_SAR_GAUSSDB_CPU

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status-wait-status · pgxc_thread_wait_status.wait_status · layer=db-system-view
run_check "chk-pgxc-thread-wait-status-wait-status" "distributed-only" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS'
Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;
EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-table-distribution · table_skewness / table_distribution · layer=db-system-view
run_check "chk-table-skewness-table-distribution" "distributed-only" <<'EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION'
select table_skewness('store_sales');
EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk--38 · 线程等待状态 · layer=db-system-view
run_check "chk--38" "distributed-only" <<'EOF_CHK__38'
select * from pg_thread_wait_status where query_id='149181737656737395';
EOF_CHK__38

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-sql-create-index · 活跃SQL及CREATE INDEX语句 · layer=db-system-view
run_check "chk-sql-create-index" "distributed-only" <<'EOF_CHK_SQL_CREATE_INDEX'
select * from pg_stat_activity where state !='idle' and usename !='omm';
EOF_CHK_SQL_CREATE_INDEX

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk--39 · 表数据倾斜 · layer=db-system-view
run_check "chk--39" "distributed-only" <<'EOF_CHK__39'
select table_skewness('ioc_dm.m_ss_index_event');
EOF_CHK__39

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-get-stat-all-tables-dirty-page-rate · PGXC_GET_STAT_ALL_TABLES.dirty_page_rate · layer=db-system-view
run_check "chk-pgxc-get-stat-all-tables-dirty-page-rate" "distributed-only" <<'EOF_CHK_PGXC_GET_STAT_ALL_TABLES_DIRTY_PAGE_RATE'
SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_GET_STAT_ALL_TABLES WHERE schemaName NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'cstore', 'pmk') AND dirty_page_rate > 30 ORDER BY table_size DESC, dirty_page_rate DESC;
EOF_CHK_PGXC_GET_STAT_ALL_TABLES_DIRTY_PAGE_RATE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dn-2 · 各DN数据量分布 · layer=db-shell
run_check "chk-dn-2" "distributed-only" <<'EOF_CHK_DN_2'
SELECT pg_get_tabledef('customer_t1');
EOF_CHK_DN_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-codegen · enable_codegen 参数状态 · layer=db-shell
run_check "chk-enable-codegen" "distributed-only" <<'EOF_CHK_ENABLE_CODEGEN'
SHOW turbo_engine_version;
EOF_CHK_ENABLE_CODEGEN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-wlm-session-info-streaming-stream-count · pgxc_wlm_session_info · Streaming 算子数（stream_count） · layer=db-system-view
run_check "chk-pgxc-wlm-session-info-streaming-stream-count" "distributed-only" <<'EOF_CHK_PGXC_WLM_SESSION_INFO_STREAMING_STREAM_COUNT'
SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM pgxc_wlm_session_info ORDER BY stream_count DESC limit 100;
EOF_CHK_PGXC_WLM_SESSION_INFO_STREAMING_STREAM_COUNT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-wlm-session-info-max-cpu-time-cpu · pgxc_wlm_session_info · max_cpu_time（高CPU语句） · layer=db-system-view
run_check "chk-pgxc-wlm-session-info-max-cpu-time-cpu" "distributed-only" <<'EOF_CHK_PGXC_WLM_SESSION_INFO_MAX_CPU_TIME_CPU'
SELECT * FROM pgxc_wlm_session_info WHERE start_time > 'xxxx-xx-xx' AND start_time < 'xxxx-xx-xx' ORDER BY max_cpu_time desc;
EOF_CHK_PGXC_WLM_SESSION_INFO_MAX_CPU_TIME_CPU

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-runtime-current-timestamp-query-start · PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start) · layer=db-system-view
run_check "chk-pgxc-stat-activity-runtime-current-timestamp-query-start" "distributed-only" <<'EOF_CHK_PGXC_STAT_ACTIVITY_RUNTIME_CURRENT_TIMESTAMP_QUERY_START'
SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle' order by 1 desc;
EOF_CHK_PGXC_STAT_ACTIVITY_RUNTIME_CURRENT_TIMESTAMP_QUERY_START

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-waiting-true · PGXC_STAT_ACTIVITY · waiting=true 阻塞查询 · layer=db-system-view
run_check "chk-pgxc-stat-activity-waiting-true" "distributed-only" <<'EOF_CHK_PGXC_STAT_ACTIVITY_WAITING_TRUE'
SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;
EOF_CHK_PGXC_STAT_ACTIVITY_WAITING_TRUE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-lock-conflicts · pgxc_lock_conflicts 锁冲突视图 · layer=db-system-view
run_check "chk-pgxc-lock-conflicts" "distributed-only" <<'EOF_CHK_PGXC_LOCK_CONFLICTS'
SELECT * FROM pgxc_lock_conflicts;
EOF_CHK_PGXC_LOCK_CONFLICTS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-state-waiting-query · pgxc_stat_activity · state / waiting / query · layer=db-system-view
run_check "chk-pgxc-stat-activity-state-waiting-query" "distributed-only" <<'EOF_CHK_PGXC_STAT_ACTIVITY_STATE_WAITING_QUERY'
SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';
EOF_CHK_PGXC_STAT_ACTIVITY_STATE_WAITING_QUERY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic- · pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory · layer=db-system-view
run_check "chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic-" "distributed-only" <<'EOF_CHK_PGXC_TOTAL_MEMORY_DETAIL_DYNAMIC_USED_MEMORY_VS_MAX_DYNAMIC_'
SELECT * FROM pgxc_total_memory_detail;
EOF_CHK_PGXC_TOTAL_MEMORY_DETAIL_DYNAMIC_USED_MEMORY_VS_MAX_DYNAMIC_

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc · pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent · layer=db-system-view
run_check "chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc" "distributed-only" <<'EOF_CHK_PGXC_WLM_SESSION_STATISTICS_MAX_PEAK_MEMORY_MEMORY_SKEW_PERC'
SELECT nodename,pid,dbname,username,application_name,min_peak_memory,max_peak_memory,average_peak_memory,memory_skew_percent,substr(query,0,50) as query FROM pgxc_wlm_session_statistics;
EOF_CHK_PGXC_WLM_SESSION_STATISTICS_MAX_PEAK_MEMORY_MEMORY_SKEW_PERC

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status-dn · pgxc_thread_wait_status · 作业等待 DN 分布 · layer=db-system-view
run_check "chk-pgxc-thread-wait-status-dn" "distributed-only" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS_DN'
SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;
EOF_CHK_PGXC_THREAD_WAIT_STATUS_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness · table_skewness · 数据倾斜率 · layer=db-system-view
run_check "chk-table-skewness" "distributed-only" <<'EOF_CHK_TABLE_SKEWNESS'
SELECT table_skewness('store_sales');
EOF_CHK_TABLE_SKEWNESS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-get-table-skewness-2 · pgxc_get_table_skewness · 全库倾斜视图 · layer=db-system-view
run_check "chk-pgxc-get-table-skewness-2" "distributed-only" <<'EOF_CHK_PGXC_GET_TABLE_SKEWNESS_2'
SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;
EOF_CHK_PGXC_GET_TABLE_SKEWNESS_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-thread-wait-status-3 · pg_thread_wait_status · 线程等待状态 · layer=db-system-view
run_check "chk-pg-thread-wait-status-3" "distributed-only" <<'EOF_CHK_PG_THREAD_WAIT_STATUS_3'
SELECT * FROM pg_thread_wait_status WHERE query_id='149181737656737395';
EOF_CHK_PG_THREAD_WAIT_STATUS_3

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-activity-sql · pg_stat_activity 活跃SQL · layer=db-system-view
run_check "chk-pg-stat-activity-sql" "distributed-only" <<'EOF_CHK_PG_STAT_ACTIVITY_SQL'
SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';
EOF_CHK_PG_STAT_ACTIVITY_SQL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk--46 · 表倾斜情况 · layer=db-shell
run_check "chk--46" "distributed-only" <<'EOF_CHK__46'
SELECT table_skewness('table name');
EOF_CHK__46

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-session-wlmstat-status-statement-mem · pg_session_wlmstat · status / statement_mem · layer=db-system-view
run_check "chk-pg-session-wlmstat-status-statement-mem" "distributed-only" <<'EOF_CHK_PG_SESSION_WLMSTAT_STATUS_STATEMENT_MEM'
SELECT usename,substr(query,0,20),threadid,status,statement_mem FROM pg_session_wlmstat where usename not in ('omm','Ruby') order by statement_mem,status desc;
EOF_CHK_PG_SESSION_WLMSTAT_STATUS_STATEMENT_MEM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status-wait-status-wait-event · pgxc_thread_wait_status · wait_status / wait_event · layer=db-system-view
run_check "chk-pgxc-thread-wait-status-wait-status-wait-event" "distributed-only" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS_WAIT_EVENT'
SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_status <> 'synchronize quit' AND wait_status <> 'none'  GROUP BY 1,2 ORDER BY 3 DESC limit 50;
EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS_WAIT_EVENT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-partition · pg_partition 各表分区数 · layer=db-system-view
run_check "chk-pg-partition" "distributed-only" <<'EOF_CHK_PG_PARTITION'
SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition GROUP BY parentid ) s ON c.oid = s.parentid ORDER BY partcount DESC;
EOF_CHK_PG_PARTITION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-vacuum-full-8-0-x · pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前） · layer=db-system-view
run_check "chk-pgxc-stat-activity-vacuum-full-8-0-x" "distributed-only" <<'EOF_CHK_PGXC_STAT_ACTIVITY_VACUUM_FULL_8_0_X'
SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';
EOF_CHK_PGXC_STAT_ACTIVITY_VACUUM_FULL_8_0_X

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status · pgxc_thread_wait_status 锁等待状态 · layer=db-system-view
run_check "chk-pgxc-thread-wait-status" "distributed-only" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS'
SELECT * FROM pgxc_thread_wait_status WHERE query_id = {query_id};
EOF_CHK_PGXC_THREAD_WAIT_STATUS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pck · 表定义是否存在PCK · layer=db-shell
run_check "chk-pck" "distributed-only" <<'EOF_CHK_PCK'
SELECT * FROM pg_get_tabledef('table name');
EOF_CHK_PCK

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-psort-work-mem · psort_work_mem 参数值 · layer=db-shell
run_check "chk-psort-work-mem" "distributed-only" <<'EOF_CHK_PSORT_WORK_MEM'
show psort_work_mem;
EOF_CHK_PSORT_WORK_MEM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dn-4 · 磁盘利用率各 DN 差异 · layer=db-shell
run_check "chk-dn-4" "distributed-only" <<'EOF_CHK_DN_4'
SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc
EOF_CHK_DN_4

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-table-distribution-2 · table_skewness / table_distribution · 表数据倾斜率 · layer=db-shell
run_check "chk-table-skewness-table-distribution-2" "distributed-only" <<'EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION_2'
SELECT table_skewness('store_sales')
EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-state-2 · pgxc_stat_activity state 字段 · layer=db-system-view
run_check "chk-pgxc-stat-activity-state-2" "distributed-only" <<'EOF_CHK_PGXC_STAT_ACTIVITY_STATE_2'
SELECT state, query, query_id FROM pgxc_stat_activity;
EOF_CHK_PGXC_STAT_ACTIVITY_STATE_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-cn-savepoint-release · 各 CN 上 SAVEPOINT/RELEASE 语句分布 · layer=db-system-view
run_check "chk-cn-savepoint-release" "distributed-only" <<'EOF_CHK_CN_SAVEPOINT_RELEASE'
SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';
EOF_CHK_CN_SAVEPOINT_RELEASE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-leading-hint · 加 leading hint 后执行时间 · layer=db-interactive-cmd
run_check "chk-leading-hint" "distributed-only" <<'EOF_CHK_LEADING_HINT'
select /*+ leading((s d)) */ a.ca_state state, count(*) cnt ...
EOF_CHK_LEADING_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-leading-no-nestloop-hint · 加 leading + no nestloop hint 后执行时间 · layer=db-interactive-cmd
run_check "chk-leading-no-nestloop-hint" "distributed-only" <<'EOF_CHK_LEADING_NO_NESTLOOP_HINT'
select /*+ leading((s d)) no nestloop(s d) */ a.ca_state state, count(*) cnt ...
EOF_CHK_LEADING_NO_NESTLOOP_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-rows-hint · rows hint 后执行时间 · layer=db-interactive-cmd
run_check "chk-rows-hint" "distributed-only" <<'EOF_CHK_ROWS_HINT'
select /*+ rows(s #2880404) */ a.ca_state state, count(*) cnt ...
EOF_CHK_ROWS_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-skew-hint-agg · skew hint 后双层 Agg 计划 · layer=db-interactive-cmd
run_check "chk-skew-hint-agg" "distributed-only" <<'EOF_CHK_SKEW_HINT_AGG'
select /*+ skew(store_returns(sr_store_sk sr_customer_sk)) */sr_customer_sk as ctr_customer_sk ...
EOF_CHK_SKEW_HINT_AGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-rows-hint · EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时 · layer=db-interactive-cmd
run_check "chk-explain-performance-rows-hint" "distributed-only" <<'EOF_CHK_EXPLAIN_PERFORMANCE_ROWS_HINT'
select avg(netpaid) from (select /*+rows(store_sales store_returns * 11270)*/ c_last_name ...
EOF_CHK_EXPLAIN_PERFORMANCE_ROWS_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-gs-wlm-session-history-warning-sql · GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息 · layer=db-system-view
run_check "chk-gs-wlm-session-history-warning-sql" "distributed-only" <<'EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING_SQL'
SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC
EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING_SQL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-gs-wlm-session-history-warning · GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警 · layer=db-system-view
run_check "chk-gs-wlm-session-history-warning" "distributed-only" <<'EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING'
SELECT query,warning FROM GS_WLM_SESSION_STATISTICS ORDER BY start_time DESC
EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-xid · 当前事务 XID · layer=db-system-view
run_check "chk-xid" "distributed-only" <<'EOF_CHK_XID'
SELECT txid_current();
EOF_CHK_XID

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk--49 · 活跃事务列表 · layer=db-system-view
run_check "chk--49" "distributed-only" <<'EOF_CHK__49'
SELECT txid_current_snapshot();
EOF_CHK__49

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-gtm-snapshot-oldestxmin-xid · GTM snapshot · oldestxmin 与 xid 差值 · layer=db-system-view
run_check "chk-gtm-snapshot-oldestxmin-xid" "distributed-only" <<'EOF_CHK_GTM_SNAPSHOT_OLDESTXMIN_XID'
SELECT * FROM pgxc_gtm_snapshot_status();
EOF_CHK_GTM_SNAPSHOT_OLDESTXMIN_XID

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-running-xacts · 老事务列表 (pgxc_running_xacts) · layer=db-system-view
run_check "chk-pgxc-running-xacts" "distributed-only" <<'EOF_CHK_PGXC_RUNNING_XACTS'
SELECT * FROM pgxc_running_xacts where xmin::text::bigint < $base+$min and xmin::text::bigint > 0;
EOF_CHK_PGXC_RUNNING_XACTS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-activity-idle · pg_stat_activity · idle 连接数 · layer=db-system-view
run_check "chk-pg-stat-activity-idle" "distributed-only" <<'EOF_CHK_PG_STAT_ACTIVITY_IDLE'
SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';
EOF_CHK_PG_STAT_ACTIVITY_IDLE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-net-core-netdev-max-backlog-2 · net.core.netdev_max_backlog · layer=gaussdb-guc-param
run_check "chk-net-core-netdev-max-backlog-2" "common" <<'EOF_CHK_NET_CORE_NETDEV_MAX_BACKLOG_2'
gsql -d postgres -c "SHOW net.core.netdev_max_backlog;"
EOF_CHK_NET_CORE_NETDEV_MAX_BACKLOG_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-shared-buffers · shared_buffers · layer=gaussdb-guc-param
run_check "chk-shared-buffers" "common" <<'EOF_CHK_SHARED_BUFFERS'
gsql -d postgres -c "SHOW shared_buffers;"
EOF_CHK_SHARED_BUFFERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-work-mem · work_mem · layer=gaussdb-guc-param
run_check "chk-work-mem" "common" <<'EOF_CHK_WORK_MEM'
gsql -d postgres -c "SHOW work_mem;"
EOF_CHK_WORK_MEM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo-2 · recovery_max_workers/recovery_parse_workers/recovery_redo_workers · layer=gaussdb-guc-param
run_check "chk-recovery-max-workers-recovery-parse-workers-recovery-redo-wo-2" "common" <<'EOF_CHK_RECOVERY_MAX_WORKERS_RECOVERY_PARSE_WORKERS_RECOVERY_REDO_WO_2'
gsql -d postgres -c "SHOW recovery_max_workers/recovery_parse_workers/recovery_redo_workers;"
EOF_CHK_RECOVERY_MAX_WORKERS_RECOVERY_PARSE_WORKERS_RECOVERY_REDO_WO_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-wal-file-init-num · wal file init num · layer=gaussdb-guc-param
run_check "chk-wal-file-init-num" "common" <<'EOF_CHK_WAL_FILE_INIT_NUM'
gsql -d postgres -c "SHOW wal file init num;"
EOF_CHK_WAL_FILE_INIT_NUM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-advance-xlog-file-num · advance_xlog_file_num · layer=gaussdb-guc-param
run_check "chk-advance-xlog-file-num" "common" <<'EOF_CHK_ADVANCE_XLOG_FILE_NUM'
gsql -d postgres -c "SHOW advance_xlog_file_num;"
EOF_CHK_ADVANCE_XLOG_FILE_NUM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-query-dop · query_dop · layer=gaussdb-guc-param
run_check "chk-query-dop" "common" <<'EOF_CHK_QUERY_DOP'
gsql -d postgres -c "SHOW query_dop;"
EOF_CHK_QUERY_DOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-log-min-duration-statement · log_min_duration_statement · layer=gaussdb-guc-param
run_check "chk-log-min-duration-statement" "common" <<'EOF_CHK_LOG_MIN_DURATION_STATEMENT'
gsql -d postgres -c "SHOW log_min_duration_statement;"
EOF_CHK_LOG_MIN_DURATION_STATEMENT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-walwriter-cpu-bind · walwriter_cpu_bind · layer=gaussdb-guc-param
run_check "chk-walwriter-cpu-bind" "common" <<'EOF_CHK_WALWRITER_CPU_BIND'
gsql -d postgres -c "SHOW walwriter_cpu_bind;"
EOF_CHK_WALWRITER_CPU_BIND

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-thread-pool-attr-2 · thread_pool_attr · layer=gaussdb-guc-param
run_check "chk-thread-pool-attr-2" "common" <<'EOF_CHK_THREAD_POOL_ATTR_2'
gsql -d postgres -c "SHOW thread_pool_attr;"
EOF_CHK_THREAD_POOL_ATTR_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-vacuum-cost-delay · vacuum_cost_delay · layer=gaussdb-guc-param
run_check "chk-vacuum-cost-delay" "distributed-only" <<'EOF_CHK_VACUUM_COST_DELAY'
gsql -d postgres -c "SHOW vacuum_cost_delay;"
EOF_CHK_VACUUM_COST_DELAY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-undo-retention-time-2 · undo_retention_time · layer=gaussdb-guc-param
run_check "chk-undo-retention-time-2" "common" <<'EOF_CHK_UNDO_RETENTION_TIME_2'
gsql -d postgres -c "SHOW undo_retention_time;"
EOF_CHK_UNDO_RETENTION_TIME_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-sys-kernel-debug-sched-features · /sys/kernel/debug/sched_features · layer=gaussdb-guc-param
run_check "chk-sys-kernel-debug-sched-features" "distributed-only" <<'EOF_CHK_SYS_KERNEL_DEBUG_SCHED_FEATURES'
gsql -d postgres -c "SHOW /sys/kernel/debug/sched_features;"
EOF_CHK_SYS_KERNEL_DEBUG_SCHED_FEATURES

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-logintimeout · loginTimeout · layer=gaussdb-guc-param
run_check "chk-logintimeout" "common" <<'EOF_CHK_LOGINTIMEOUT'
gsql -d postgres -c "SHOW loginTimeout;"
EOF_CHK_LOGINTIMEOUT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-recovery-parse-workers-recovery-redo-workers · recovery_parse_workers / recovery_redo_workers · layer=gaussdb-guc-param
run_check "chk-recovery-parse-workers-recovery-redo-workers" "common" <<'EOF_CHK_RECOVERY_PARSE_WORKERS_RECOVERY_REDO_WORKERS'
gsql -d postgres -c "SHOW recovery_parse_workers / recovery_redo_workers;"
EOF_CHK_RECOVERY_PARSE_WORKERS_RECOVERY_REDO_WORKERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-client-encoding-server-encoding-2 · client_encoding / server_encoding · layer=gaussdb-guc-param
run_check "chk-client-encoding-server-encoding-2" "distributed-only" <<'EOF_CHK_CLIENT_ENCODING_SERVER_ENCODING_2'
gsql -d postgres -c "SHOW client_encoding / server_encoding;"
EOF_CHK_CLIENT_ENCODING_SERVER_ENCODING_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-rewrite-rule · rewrite_rule · layer=gaussdb-guc-param
run_check "chk-rewrite-rule" "common" <<'EOF_CHK_REWRITE_RULE'
gsql -d postgres -c "SHOW rewrite_rule;"
EOF_CHK_REWRITE_RULE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-hashjoin-2 · enable_hashjoin · layer=gaussdb-guc-param
run_check "chk-enable-hashjoin-2" "common" <<'EOF_CHK_ENABLE_HASHJOIN_2'
gsql -d postgres -c "SHOW enable_hashjoin;"
EOF_CHK_ENABLE_HASHJOIN_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-nestloop · enable_nestloop · layer=gaussdb-guc-param
run_check "chk-enable-nestloop" "common" <<'EOF_CHK_ENABLE_NESTLOOP'
gsql -d postgres -c "SHOW enable_nestloop;"
EOF_CHK_ENABLE_NESTLOOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-mergejoin · enable_mergejoin · layer=gaussdb-guc-param
run_check "chk-enable-mergejoin" "common" <<'EOF_CHK_ENABLE_MERGEJOIN'
gsql -d postgres -c "SHOW enable_mergejoin;"
EOF_CHK_ENABLE_MERGEJOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-sort · enable_sort · layer=gaussdb-guc-param
run_check "chk-enable-sort" "common" <<'EOF_CHK_ENABLE_SORT'
gsql -d postgres -c "SHOW enable_sort;"
EOF_CHK_ENABLE_SORT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-best-agg-plan · best_agg_plan · layer=gaussdb-guc-param
run_check "chk-best-agg-plan" "distributed-only" <<'EOF_CHK_BEST_AGG_PLAN'
gsql -d postgres -c "SHOW best_agg_plan;"
EOF_CHK_BEST_AGG_PLAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-a-format-load-with-constraints-violation · a_format_load_with_constraints_violation · layer=gaussdb-guc-param
run_check "chk-a-format-load-with-constraints-violation" "centralized-only" <<'EOF_CHK_A_FORMAT_LOAD_WITH_CONSTRAINTS_VIOLATION'
gsql -d postgres -c "SHOW a_format_load_with_constraints_violation;"
EOF_CHK_A_FORMAT_LOAD_WITH_CONSTRAINTS_VIOLATION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-cost-param · cost_param · layer=gaussdb-guc-param
run_check "chk-cost-param" "common" <<'EOF_CHK_COST_PARAM'
gsql -d postgres -c "SHOW cost_param;"
EOF_CHK_COST_PARAM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-skew-option · skew_option · layer=gaussdb-guc-param
run_check "chk-skew-option" "distributed-only" <<'EOF_CHK_SKEW_OPTION'
gsql -d postgres -c "SHOW skew_option;"
EOF_CHK_SKEW_OPTION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-default-statistics-target · default_statistics_target · layer=gaussdb-guc-param
run_check "chk-default-statistics-target" "distributed-only" <<'EOF_CHK_DEFAULT_STATISTICS_TARGET'
gsql -d postgres -c "SHOW default_statistics_target;"
EOF_CHK_DEFAULT_STATISTICS_TARGET

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-behavior-compat-options · behavior_compat_options · layer=gaussdb-guc-param
run_check "chk-behavior-compat-options" "common" <<'EOF_CHK_BEHAVIOR_COMPAT_OPTIONS'
gsql -d postgres -c "SHOW behavior_compat_options;"
EOF_CHK_BEHAVIOR_COMPAT_OPTIONS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-fast-query-shipping · enable_fast_query_shipping · layer=gaussdb-guc-param
run_check "chk-enable-fast-query-shipping" "distributed-only" <<'EOF_CHK_ENABLE_FAST_QUERY_SHIPPING'
gsql -d postgres -c "SHOW enable_fast_query_shipping;"
EOF_CHK_ENABLE_FAST_QUERY_SHIPPING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-recovery-parse-workers · recovery_parse_workers · layer=gaussdb-guc-param
run_check "chk-recovery-parse-workers" "common" <<'EOF_CHK_RECOVERY_PARSE_WORKERS'
gsql -d postgres -c "SHOW recovery_parse_workers;"
EOF_CHK_RECOVERY_PARSE_WORKERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-recovery-redo-workers · recovery_redo_workers · layer=gaussdb-guc-param
run_check "chk-recovery-redo-workers" "common" <<'EOF_CHK_RECOVERY_REDO_WORKERS'
gsql -d postgres -c "SHOW recovery_redo_workers;"
EOF_CHK_RECOVERY_REDO_WORKERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-index-nestloop · enable_index_nestloop · layer=gaussdb-guc-param
run_check "chk-enable-index-nestloop" "distributed-only" <<'EOF_CHK_ENABLE_INDEX_NESTLOOP'
gsql -d postgres -c "SHOW enable_index_nestloop;"
EOF_CHK_ENABLE_INDEX_NESTLOOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-indexscan · enable_indexscan · layer=gaussdb-guc-param
run_check "chk-enable-indexscan" "distributed-only" <<'EOF_CHK_ENABLE_INDEXSCAN'
gsql -d postgres -c "SHOW enable_indexscan;"
EOF_CHK_ENABLE_INDEXSCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-max-process-memory · max_process_memory · layer=gaussdb-guc-param
run_check "chk-max-process-memory" "distributed-only" <<'EOF_CHK_MAX_PROCESS_MEMORY'
gsql -d postgres -c "SHOW max_process_memory;"
EOF_CHK_MAX_PROCESS_MEMORY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-qrw-inlist2join-optmode · qrw_inlist2join_optmode · layer=gaussdb-guc-param
run_check "chk-qrw-inlist2join-optmode" "distributed-only" <<'EOF_CHK_QRW_INLIST2JOIN_OPTMODE'
gsql -d postgres -c "SHOW qrw_inlist2join_optmode;"
EOF_CHK_QRW_INLIST2JOIN_OPTMODE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-fetchsize · fetchSize · layer=gaussdb-guc-param
run_check "chk-fetchsize" "distributed-only" <<'EOF_CHK_FETCHSIZE'
gsql -d postgres -c "SHOW fetchSize;"
EOF_CHK_FETCHSIZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-period · period · layer=gaussdb-guc-param
run_check "chk-period" "distributed-only" <<'EOF_CHK_PERIOD'
gsql -d postgres -c "SHOW period;"
EOF_CHK_PERIOD

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-ttl · ttl · layer=gaussdb-guc-param
run_check "chk-ttl" "distributed-only" <<'EOF_CHK_TTL'
gsql -d postgres -c "SHOW ttl;"
EOF_CHK_TTL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-disk-cache-max-size · disk_cache_max_size · layer=gaussdb-guc-param
run_check "chk-disk-cache-max-size" "distributed-only" <<'EOF_CHK_DISK_CACHE_MAX_SIZE'
gsql -d postgres -c "SHOW disk_cache_max_size;"
EOF_CHK_DISK_CACHE_MAX_SIZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-disk-cache-dual-write-option · disk_cache_dual_write_option · layer=gaussdb-guc-param
run_check "chk-disk-cache-dual-write-option" "distributed-only" <<'EOF_CHK_DISK_CACHE_DUAL_WRITE_OPTION'
gsql -d postgres -c "SHOW disk_cache_dual_write_option;"
EOF_CHK_DISK_CACHE_DUAL_WRITE_OPTION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-min-batch-rows · min_batch_rows · layer=gaussdb-guc-param
run_check "chk-min-batch-rows" "distributed-only" <<'EOF_CHK_MIN_BATCH_ROWS'
gsql -d postgres -c "SHOW min_batch_rows;"
EOF_CHK_MIN_BATCH_ROWS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-2 · autovacuum · layer=gaussdb-guc-param
run_check "chk-autovacuum-2" "distributed-only" <<'EOF_CHK_AUTOVACUUM_2'
gsql -d postgres -c "SHOW autovacuum;"
EOF_CHK_AUTOVACUUM_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-vacuum-cost-delay · autovacuum_vacuum_cost_delay · layer=gaussdb-guc-param
run_check "chk-autovacuum-vacuum-cost-delay" "distributed-only" <<'EOF_CHK_AUTOVACUUM_VACUUM_COST_DELAY'
gsql -d postgres -c "SHOW autovacuum_vacuum_cost_delay;"
EOF_CHK_AUTOVACUUM_VACUUM_COST_DELAY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-max-workers · autovacuum_max_workers · layer=gaussdb-guc-param
run_check "chk-autovacuum-max-workers" "distributed-only" <<'EOF_CHK_AUTOVACUUM_MAX_WORKERS'
gsql -d postgres -c "SHOW autovacuum_max_workers;"
EOF_CHK_AUTOVACUUM_MAX_WORKERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-naptime · autovacuum_naptime · layer=gaussdb-guc-param
run_check "chk-autovacuum-naptime" "distributed-only" <<'EOF_CHK_AUTOVACUUM_NAPTIME'
gsql -d postgres -c "SHOW autovacuum_naptime;"
EOF_CHK_AUTOVACUUM_NAPTIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-max-active-statements · max_active_statements · layer=gaussdb-guc-param
run_check "chk-max-active-statements" "distributed-only" <<'EOF_CHK_MAX_ACTIVE_STATEMENTS'
gsql -d postgres -c "SHOW max_active_statements;"
EOF_CHK_MAX_ACTIVE_STATEMENTS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-max-workers-hstore · autovacuum_max_workers_hstore · layer=gaussdb-guc-param
run_check "chk-autovacuum-max-workers-hstore" "distributed-only" <<'EOF_CHK_AUTOVACUUM_MAX_WORKERS_HSTORE'
gsql -d postgres -c "SHOW autovacuum_max_workers_hstore;"
EOF_CHK_AUTOVACUUM_MAX_WORKERS_HSTORE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-codegen-2 · enable_codegen · layer=gaussdb-guc-param
run_check "chk-enable-codegen-2" "distributed-only" <<'EOF_CHK_ENABLE_CODEGEN_2'
gsql -d postgres -c "SHOW enable_codegen;"
EOF_CHK_ENABLE_CODEGEN_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-numa-bind · enable_numa_bind · layer=gaussdb-guc-param
run_check "chk-enable-numa-bind" "distributed-only" <<'EOF_CHK_ENABLE_NUMA_BIND'
gsql -d postgres -c "SHOW enable_numa_bind;"
EOF_CHK_ENABLE_NUMA_BIND

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-abnormal-check-general-task · abnormal_check_general_task · layer=gaussdb-guc-param
run_check "chk-abnormal-check-general-task" "distributed-only" <<'EOF_CHK_ABNORMAL_CHECK_GENERAL_TASK'
gsql -d postgres -c "SHOW abnormal_check_general_task;"
EOF_CHK_ABNORMAL_CHECK_GENERAL_TASK

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-resource-track-level · resource_track_level · layer=gaussdb-guc-param
run_check "chk-resource-track-level" "distributed-only" <<'EOF_CHK_RESOURCE_TRACK_LEVEL'
gsql -d postgres -c "SHOW resource_track_level;"
EOF_CHK_RESOURCE_TRACK_LEVEL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-track-activities · track_activities · layer=gaussdb-guc-param
run_check "chk-track-activities" "distributed-only" <<'EOF_CHK_TRACK_ACTIVITIES'
gsql -d postgres -c "SHOW track_activities;"
EOF_CHK_TRACK_ACTIVITIES

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-connectiontimeout · connectionTimeOut · layer=gaussdb-guc-param
run_check "chk-connectiontimeout" "distributed-only" <<'EOF_CHK_CONNECTIONTIMEOUT'
gsql -d postgres -c "SHOW connectionTimeOut;"
EOF_CHK_CONNECTIONTIMEOUT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-lockwait-timeout · lockwait_timeout · layer=gaussdb-guc-param
run_check "chk-lockwait-timeout" "distributed-only" <<'EOF_CHK_LOCKWAIT_TIMEOUT'
gsql -d postgres -c "SHOW lockwait_timeout;"
EOF_CHK_LOCKWAIT_TIMEOUT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-psort-work-mem-2 · psort_work_mem · layer=gaussdb-guc-param
run_check "chk-psort-work-mem-2" "distributed-only" <<'EOF_CHK_PSORT_WORK_MEM_2'
gsql -d postgres -c "SHOW psort_work_mem;"
EOF_CHK_PSORT_WORK_MEM_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-delta · ENABLE_DELTA · layer=gaussdb-guc-param
run_check "chk-enable-delta" "distributed-only" <<'EOF_CHK_ENABLE_DELTA'
gsql -d postgres -c "SHOW ENABLE_DELTA;"
EOF_CHK_ENABLE_DELTA

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-resource-pool-cpu-dedicated-quota · resource_pool.cpu_dedicated_quota · layer=gaussdb-guc-param
run_check "chk-resource-pool-cpu-dedicated-quota" "distributed-only" <<'EOF_CHK_RESOURCE_POOL_CPU_DEDICATED_QUOTA'
gsql -d postgres -c "SHOW resource_pool.cpu_dedicated_quota;"
EOF_CHK_RESOURCE_POOL_CPU_DEDICATED_QUOTA

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-temp-file-limit · temp_file_limit · layer=gaussdb-guc-param
run_check "chk-temp-file-limit" "distributed-only" <<'EOF_CHK_TEMP_FILE_LIMIT'
gsql -d postgres -c "SHOW temp_file_limit;"
EOF_CHK_TEMP_FILE_LIMIT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-sequence-cache · sequence.cache · layer=gaussdb-guc-param
run_check "chk-sequence-cache" "distributed-only" <<'EOF_CHK_SEQUENCE_CACHE'
gsql -d postgres -c "SHOW sequence.cache;"
EOF_CHK_SEQUENCE_CACHE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-cstore-buffers · cstore_buffers · layer=gaussdb-guc-param
run_check "chk-cstore-buffers" "distributed-only" <<'EOF_CHK_CSTORE_BUFFERS'
gsql -d postgres -c "SHOW cstore_buffers;"
EOF_CHK_CSTORE_BUFFERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-comm-max-stream · comm_max_stream · layer=gaussdb-guc-param
run_check "chk-comm-max-stream" "distributed-only" <<'EOF_CHK_COMM_MAX_STREAM'
gsql -d postgres -c "SHOW comm_max_stream;"
EOF_CHK_COMM_MAX_STREAM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-vacuum-defer-cleanup-age-2 · vacuum_defer_cleanup_age · layer=gaussdb-guc-param
run_check "chk-vacuum-defer-cleanup-age-2" "distributed-only" <<'EOF_CHK_VACUUM_DEFER_CLEANUP_AGE_2'
gsql -d postgres -c "SHOW vacuum_defer_cleanup_age;"
EOF_CHK_VACUUM_DEFER_CLEANUP_AGE_2

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-stream-operator · enable_stream_operator · layer=gaussdb-guc-param
run_check "chk-enable-stream-operator" "distributed-only" <<'EOF_CHK_ENABLE_STREAM_OPERATOR'
gsql -d postgres -c "SHOW enable_stream_operator;"
EOF_CHK_ENABLE_STREAM_OPERATOR

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-warning-threshold · table_skewness_warning_threshold · layer=gaussdb-guc-param
run_check "chk-table-skewness-warning-threshold" "distributed-only" <<'EOF_CHK_TABLE_SKEWNESS_WARNING_THRESHOLD'
gsql -d postgres -c "SHOW table_skewness_warning_threshold;"
EOF_CHK_TABLE_SKEWNESS_WARNING_THRESHOLD

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-warning-rows · table_skewness_warning_rows · layer=gaussdb-guc-param
run_check "chk-table-skewness-warning-rows" "distributed-only" <<'EOF_CHK_TABLE_SKEWNESS_WARNING_ROWS'
gsql -d postgres -c "SHOW table_skewness_warning_rows;"
EOF_CHK_TABLE_SKEWNESS_WARNING_ROWS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-session-timeout · session_timeout · layer=gaussdb-guc-param
run_check "chk-session-timeout" "distributed-only" <<'EOF_CHK_SESSION_TIMEOUT'
gsql -d postgres -c "SHOW session_timeout;"
EOF_CHK_SESSION_TIMEOUT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-max-connections · max_connections · layer=gaussdb-guc-param
run_check "chk-max-connections" "distributed-only" <<'EOF_CHK_MAX_CONNECTIONS'
gsql -d postgres -c "SHOW max_connections;"
EOF_CHK_MAX_CONNECTIONS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-slow-sql-statement-history · statement_history 慢 SQL 明细 (全列 + 等待事件解码) · layer=db-system-view
run_check "chk-slow-sql-statement-history" "common" <<'EOF_CHK_SLOW_SQL_STATEMENT_HISTORY'
SELECT db_name, schema_name, origin_node, user_name, application_name, client_addr, client_port, unique_query_id, debug_query_id, substr(query,1,200) AS query, start_time, finish_time, slow_sql_threshold, transaction_id, thread_id, session_id, n_soft_parse, n_hard_parse, n_returned_rows, n_tuples_fetched, n_tuples_returned, n_tuples_inserted, n_tuples_updated, n_tuples_deleted, n_blocks_fetched, n_blocks_hit, (n_blocks_fetched-n_blocks_hit) AS phys_read, db_time, cpu_time, execution_time, parse_time, plan_time, rewrite_time, pl_execution_time, pl_compilation_time, data_io_time, net_send_info, net_recv_info, net_stream_send_info, net_stream_recv_info, lock_count, lock_time, lock_wait_count, lock_wait_time, lock_max_count, lwlock_count, lwlock_wait_count, lwlock_time, lwlock_wait_time, statement_detail_decode(details, 'plaintext', true) AS wait_events, is_slow_sql, trace_id, advise, parent_unique_sql_id, finish_status, used_memory, lock_max_local_count, lock_max_fastpath_count, lock_max_global_count, sql_hash, plan_hash, plan_hash_prev, driver_start_time, driver_wait_response, driver_finish_time, driver_info, kernel_info, adaptive_join_states, aplan_count, aplan_parse_time, aplan_execution_time, relids, query_plan FROM statement_history WHERE is_slow_sql ORDER BY start_time DESC LIMIT 20;
EOF_CHK_SLOW_SQL_STATEMENT_HISTORY


echo ""
echo "─────────────────────────────────────────────"
echo "完成 · auto=142(本脚本只跑这些)· manual=199 · skip=1"
echo "  异常清单:    $OUTDIR/report.tsv (只记非 ok · 全 ok 则只有表头)"
echo "  数据文件:   $OUTDIR/<check_id>.txt (每条 check 一个)"
echo "  报错汇总:   $OUTDIR/errors.log"
echo "  人审清单:    见 kit 内独立文件 manual-audit.md (199 项 · 不在本采集脚本内)"
