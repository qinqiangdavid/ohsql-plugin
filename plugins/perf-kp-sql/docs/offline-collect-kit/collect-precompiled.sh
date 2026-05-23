#!/usr/bin/env bash
# GaussDB 离线采集 · 预编译版 · 完全自包含
# 所有 180 个 auto 命令已 inline 为 heredoc (不解析 ndjson · 不需 jq).
#
# 生成时间: 2026-05-23T09:08:35.405Z
# 数据: auto=180 · manual=153 · skip=8 · total=341
#
# 用法:
#   source ~/gauss_env_file              # 先 source gsql env (如需要)
#   ./collect-precompiled.sh             # 默认输出到 ./collect-results-<ts>/
#   ./collect-precompiled.sh /tmp/out    # 自定义 outdir
#
# 环境变量:
#   COLLECT_TIMEOUT  单命令超时秒 (default: 5)
#
# 依赖: bash 3+ · mktemp · (可选) GNU timeout / gtimeout

set -uo pipefail
OUTDIR="${1:-./collect-results-$(date +%Y%m%d-%H%M%S)}"
TIMEOUT="${COLLECT_TIMEOUT:-5}"
T_BIN=$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || echo "")
# top / sar / vmstat 等 tty 工具在非交互 shell 会抱怨 TERM unset · 给个 dumb 兜底
export TERM="${TERM:-dumb}"
mkdir -p "$OUTDIR/stdout" "$OUTDIR/stderr"

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

# 写到 report 头部元数据 (注释行 · 也 dump 到 deploy.txt 便于程序解析)
{
  printf '# deploy_form\t%s\n' "$DEPLOY_FORM"
  printf '# detected_at\t%s\n' "$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '# host\t%s\n' "$(hostname 2>/dev/null || echo unknown)"
  printf '# user\t%s\n' "$(whoami)"
  printf 'check_id\texit_code\tstatus\n'
} > "$OUTDIR/report.tsv"
printf '%s\n' "$DEPLOY_FORM" > "$OUTDIR/deploy.txt"

run_check() {
  # 用法: run_check <check_id> <<'EOF_XXX'
  #         <真命令>
  #       EOF_XXX
  # 自动 dispatch: 起始词是 SQL 关键字 → gsql -f, 否则 bash.
  local cid="$1"
  local tmpf
  tmpf=$(mktemp)
  cat > "$tmpf"
  # 取第一个非空 token (大写化 · 砍标点)
  local first
  first=$(awk 'NF{for(i=1;i<=NF;i++)if($i!~/^--/){print toupper($i);exit}}' "$tmpf" | tr -d '[:punct:]')
  local cmd_kind="shell"
  case "$first" in
    SELECT|EXPLAIN|SHOW|WITH|SET|VACUUM|ANALYZE|CREATE|ALTER|DROP|TRUNCATE|UPDATE|INSERT|DELETE|COPY|REINDEX|CHECKPOINT|GRANT|REVOKE|RESET|BEGIN|COMMIT|ROLLBACK|CALL|VALUES)
      cmd_kind="sql" ;;
  esac
  set +e
  if [ "$cmd_kind" = "sql" ]; then
    if [ -n "$T_BIN" ]; then
      "$T_BIN" "$TIMEOUT" gsql -d postgres -f "$tmpf" > "$OUTDIR/stdout/$cid.txt" 2> "$OUTDIR/stderr/$cid.txt"
    else
      gsql -d postgres -f "$tmpf" > "$OUTDIR/stdout/$cid.txt" 2> "$OUTDIR/stderr/$cid.txt"
    fi
  else
    if [ -n "$T_BIN" ]; then
      "$T_BIN" "$TIMEOUT" bash "$tmpf" > "$OUTDIR/stdout/$cid.txt" 2> "$OUTDIR/stderr/$cid.txt"
    else
      bash "$tmpf" > "$OUTDIR/stdout/$cid.txt" 2> "$OUTDIR/stderr/$cid.txt"
    fi
  fi
  local rc=$?
  set -e
  rm -f "$tmpf"
  local s
  case $rc in 0) s=ok;; 124) s=timeout;; *) s="error-rc$rc";; esac
  printf '%s\t%s\t%s\n' "$cid" "$rc" "$s" >> "$OUTDIR/report.tsv"
}

i=0
TOTAL=180
echo "开始: $TOTAL 个 auto 命令 · timeout ${TIMEOUT}s · outdir $OUTDIR"
echo ""

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dbe-perf-statement-cpu-time · dbe_perf.statement.cpu_time · layer=db-system-view
run_check "chk-dbe-perf-statement-cpu-time" <<'EOF_CHK_DBE_PERF_STATEMENT_CPU_TIME'
select unique_sql_id,substr(query,1,50) as query ,n_calls,round(total_elapse_time/n_calls/1000,2) avg_time,round(total_elapse_time/1000,2) as total_time,round(cpu_time/1000,2) as cup_time from dbe_perf.statement t where  n_calls>10 and avg_time>3  and user_name='root'  order by cpu_time desc limit 5;
EOF_CHK_DBE_PERF_STATEMENT_CPU_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze · explain analyze 执行计划分析 · layer=db-interactive-cmd
run_check "chk-explain-analyze" <<'EOF_CHK_EXPLAIN_ANALYZE'
explain analyze SELECT c_id FROM bmsql_customer WHERE c_w_id = 1 AND c_d_id = 1 AND c_last = 'ABLEABLEABLE' ORDER BY c_first;
EOF_CHK_EXPLAIN_ANALYZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-remotequery · explain verbose · RemoteQuery 计划 · layer=db-interactive-cmd
run_check "chk-explain-verbose-remotequery" <<'EOF_CHK_EXPLAIN_VERBOSE_REMOTEQUERY'
set rewrite_rule='none'; SET explain (verbose on, costs off)  select two_sum(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);
EOF_CHK_EXPLAIN_VERBOSE_REMOTEQUERY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-subplan · explain verbose · SubPlan 执行方式 · layer=db-interactive-cmd
run_check "chk-explain-verbose-subplan" <<'EOF_CHK_EXPLAIN_VERBOSE_SUBPLAN'
set rewrite_rule='none'; SET explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;
EOF_CHK_EXPLAIN_VERBOSE_SUBPLAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-null-001 · 执行计划下推标识 · layer=db-interactive-cmd
run_check "chk-null-001" <<'EOF_CHK_NULL_001'
explain select * from t where c1 > 1;
EOF_CHK_NULL_001

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-hashjoin · enable_hashjoin 关闭后执行计划 · layer=db-interactive-cmd
run_check "chk-enable-hashjoin" <<'EOF_CHK_ENABLE_HASHJOIN'
SET enable_hashjoin = off;
EOF_CHK_ENABLE_HASHJOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-a-time-rows-removed-by-filter · explain analyze · A-time / Rows Removed by Filter · layer=db-interactive-cmd
run_check "chk-explain-analyze-a-time-rows-removed-by-filter" <<'EOF_CHK_EXPLAIN_ANALYZE_A_TIME_ROWS_REMOVED_BY_FILTER'
explain (analyze on,costs off) select * from t1 where c2=10004;
EOF_CHK_EXPLAIN_ANALYZE_A_TIME_ROWS_REMOVED_BY_FILTER

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-nested-loop-a-time · explain analyze · Nested Loop A-time · layer=db-interactive-cmd
run_check "chk-explain-analyze-nested-loop-a-time" <<'EOF_CHK_EXPLAIN_ANALYZE_NESTED_LOOP_A_TIME'
explain analyze select count(*) from t2,t1 where t1.c1=t2.c2;
EOF_CHK_EXPLAIN_ANALYZE_NESTED_LOOP_A_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-groupaggregate-a-time-vs-hashaggregate · explain analyze · GroupAggregate A-time vs HashAggregate · layer=db-interactive-cmd
run_check "chk-explain-analyze-groupaggregate-a-time-vs-hashaggregate" <<'EOF_CHK_EXPLAIN_ANALYZE_GROUPAGGREGATE_A_TIME_VS_HASHAGGREGATE'
explain analyze select count(*) from t1 group by c2;
EOF_CHK_EXPLAIN_ANALYZE_GROUPAGGREGATE_A_TIME_VS_HASHAGGREGATE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-a-time · EXPLAIN ANALYZE A-time 瓶颈算子识别 · layer=db-interactive-cmd
run_check "chk-explain-analyze-a-time" <<'EOF_CHK_EXPLAIN_ANALYZE_A_TIME'
explain analyze select avg(netpaid) from (select c_last_name,c_first_name,s_store_name,ca_state,s_state,i_color,i_current_price,i_manager_id,i_units,i_size,sum(ss_sales_price) netpaid from store_sales,store_returns,store,item,customer,customer_address where ss_ticket_number = sr_ticket_number and ss_item_sk = sr_item_sk and ss_customer_sk = c_customer_sk and ss_item_sk = i_item_sk and ss_store_sk = s_store_sk and c_birth_country = upper(ca_country) and s_zip = ca_zip ...
EOF_CHK_EXPLAIN_ANALYZE_A_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-streaming-vs-data-node-scan · EXPLAIN VERBOSE · 执行计划是否含 Streaming 节点 vs Data Node Scan · layer=db-interactive-cmd
run_check "chk-explain-verbose-streaming-vs-data-node-scan" <<'EOF_CHK_EXPLAIN_VERBOSE_STREAMING_VS_DATA_NODE_SCAN'
set rewrite_rule='none'; SET explain (verbose on, costs off)  select group_concat(tt.c1, tt.c2) from (select t1.c1,t2.c2 from t1,t2 where t1.c1=t2.c2) tt(c1,c2);
EOF_CHK_EXPLAIN_VERBOSE_STREAMING_VS_DATA_NODE_SCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-subplan · EXPLAIN VERBOSE · SubPlan 算子出现在目标列 · layer=db-interactive-cmd
run_check "chk-explain-verbose-subplan" <<'EOF_CHK_EXPLAIN_VERBOSE_SUBPLAN'
set rewrite_rule='none'; SET explain (verbose on, costs off) select c1,(select avg(c2) from t2 where t2.c2=t1.c2) from t1 where t1.c1<100 order by t1.c2;
EOF_CHK_EXPLAIN_VERBOSE_SUBPLAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-get-last-data-changed-time · 近期数据变更表列表（pg_stat_get_last_data_changed_time） · layer=db-system-view
run_check "chk-pg-stat-get-last-data-changed-time" <<'EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME'
SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();
EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-get-table-skewness · PGXC_GET_TABLE_SKEWNESS · layer=db-system-view
run_check "chk-pgxc-get-table-skewness" <<'EOF_CHK_PGXC_GET_TABLE_SKEWNESS'
SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;
EOF_CHK_PGXC_GET_TABLE_SKEWNESS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-distribution-dn-1w · table_distribution() 各DN空间（大表个数超1W场景） · layer=db-system-view
run_check "chk-table-distribution-dn-1w" <<'EOF_CHK_TABLE_DISTRIBUTION_DN_1W'
SELECT schemaname,tablename,max(dnsize) AS maxsize, min(dnsize) AS minsize FROM pg_catalog.pg_class c INNER JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace INNER JOIN pg_catalog.table_distribution() s ON s.schemaname = n.nspname AND s.tablename = c.relname INNER JOIN pg_catalog.pgxc_class x ON c.oid = x.pcrelid AND x.pclocatortype = 'H' GROUP BY schemaname,tablename;
EOF_CHK_TABLE_DISTRIBUTION_DN_1W

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-seq-scan-a-time-total-runtime · EXPLAIN ANALYZE Seq Scan A-time / Total runtime · layer=db-interactive-cmd
run_check "chk-explain-analyze-seq-scan-a-time-total-runtime" <<'EOF_CHK_EXPLAIN_ANALYZE_SEQ_SCAN_A_TIME_TOTAL_RUNTIME'
EXPLAIN ANALYZE SELECT * FROM test_table WHERE email = 'user_500000@example.com';
EOF_CHK_EXPLAIN_ANALYZE_SEQ_SCAN_A_TIME_TOTAL_RUNTIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-warning · EXPLAIN VERBOSE 执行计划 Warning · layer=db-interactive-cmd
run_check "chk-explain-verbose-warning" <<'EOF_CHK_EXPLAIN_VERBOSE_WARNING'
explain verbose
EOF_CHK_EXPLAIN_VERBOSE_WARNING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-a-time-seqscan-vs-indexscan · EXPLAIN ANALYZE A-time · SeqScan vs IndexScan · layer=db-interactive-cmd
run_check "chk-explain-analyze-a-time-seqscan-vs-indexscan" <<'EOF_CHK_EXPLAIN_ANALYZE_A_TIME_SEQSCAN_VS_INDEXSCAN'
explain (analyze on, costs off) select * from t1 where c1=10004;
EOF_CHK_EXPLAIN_ANALYZE_A_TIME_SEQSCAN_VS_INDEXSCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-a-time-nestloop · EXPLAIN ANALYZE A-time · NestLoop算子耗时 · layer=db-interactive-cmd
run_check "chk-explain-analyze-a-time-nestloop" <<'EOF_CHK_EXPLAIN_ANALYZE_A_TIME_NESTLOOP'
explain analyze select count(*) from t1,t2 where t1.c1=t2.c2;
EOF_CHK_EXPLAIN_ANALYZE_A_TIME_NESTLOOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-a-time-sort-groupagg-vs-hashagg · EXPLAIN ANALYZE A-time · Sort+GroupAgg vs HashAgg · layer=db-interactive-cmd
run_check "chk-explain-analyze-a-time-sort-groupagg-vs-hashagg" <<'EOF_CHK_EXPLAIN_ANALYZE_A_TIME_SORT_GROUPAGG_VS_HASHAGG'
explain analyze select count(*) from t1 group by c1;
EOF_CHK_EXPLAIN_ANALYZE_A_TIME_SORT_GROUPAGG_VS_HASHAGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze · EXPLAIN ANALYZE 执行计划 · 算子耗时 · layer=db-interactive-cmd
run_check "chk-explain-analyze" <<'EOF_CHK_EXPLAIN_ANALYZE'
explain (analyze on, costs off) select * from t1 where c1=10004;
EOF_CHK_EXPLAIN_ANALYZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-nestloop · EXPLAIN ANALYZE · NestLoop 算子耗时 · layer=db-interactive-cmd
run_check "chk-explain-analyze-nestloop" <<'EOF_CHK_EXPLAIN_ANALYZE_NESTLOOP'
explain analyze select count(*) from t1,t2 where t1.c1=t2.c2;
EOF_CHK_EXPLAIN_ANALYZE_NESTLOOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-sort-groupagg · EXPLAIN ANALYZE · Sort+GroupAgg 算子耗时 · layer=db-interactive-cmd
run_check "chk-explain-analyze-sort-groupagg" <<'EOF_CHK_EXPLAIN_ANALYZE_SORT_GROUPAGG'
explain analyze select count(*) from t1 group by c1;
EOF_CHK_EXPLAIN_ANALYZE_SORT_GROUPAGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-hashaggregate · 执行计划中双层HashAggregate · layer=db-interactive-cmd
run_check "chk-hashaggregate" <<'EOF_CHK_HASHAGGREGATE'
EXPLAIN (costs off) SELECT t.c2, sum(cc) FROM (SELECT c2, sum(c3) AS cc FROM t1 GROUP BY c2) s1, t WHERE s1.c2=t.c2 GROUP BY t.c2 ORDER BY 1,2;
EOF_CHK_HASHAGGREGATE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-null-002 · 执行计划子查询关联方式 · layer=db-interactive-cmd
run_check "chk-null-002" <<'EOF_CHK_NULL_002'
EXPLAIN (costs off) SELECT t1 FROM t1 WHERE t1.c2 = 10 AND t1.c3 < (SELECT sum(c3) FROM t2 WHERE t1.c1 = t2.c1);
EOF_CHK_NULL_002

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-subplan · 执行计划中SubPlan节点 · layer=db-interactive-cmd
run_check "chk-subplan" <<'EOF_CHK_SUBPLAN'
EXPLAIN (verbose on, costs off) SELECT c1,(SELECT avg(c2) FROM t2 WHERE t2.c2=t1.c2) FROM t1 WHERE t1.c1<100 ORDER BY t1.c2;
EOF_CHK_SUBPLAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-total-runtime-partitionscan · EXPLAIN ANALYZE Total runtime / 是否走 PartitionScan · layer=db-interactive-cmd
run_check "chk-explain-analyze-total-runtime-partitionscan" <<'EOF_CHK_EXPLAIN_ANALYZE_TOTAL_RUNTIME_PARTITIONSCAN'
EXPLAIN ANALYZE SELECT min(b) FROM test_range_pt;
EOF_CHK_EXPLAIN_ANALYZE_TOTAL_RUNTIME_PARTITIONSCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-local-explain-analyze-total-runtime · 创建 LOCAL 索引后 EXPLAIN ANALYZE Total runtime · layer=db-interactive-cmd
run_check "chk-local-explain-analyze-total-runtime" <<'EOF_CHK_LOCAL_EXPLAIN_ANALYZE_TOTAL_RUNTIME'
CREATE INDEX idx_range_b ON test_range_pt(b) LOCAL;
EOF_CHK_LOCAL_EXPLAIN_ANALYZE_TOTAL_RUNTIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-agg · EXPLAIN 执行计划 Agg 算子模式 · layer=db-interactive-cmd
run_check "chk-explain-agg" <<'EOF_CHK_EXPLAIN_AGG'
explain select b,count(1) from t1 group by b;
EOF_CHK_EXPLAIN_AGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-copy · COPY 导入是否存在约束冲突类容错需求 · layer=db-shell
run_check "chk-copy" <<'EOF_CHK_COPY'
SET a_format_load_with_constraints_violation = 's2';
EOF_CHK_COPY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-anti-join · EXPLAIN VERBOSE Anti Join 行数估算 · layer=db-interactive-cmd
run_check "chk-explain-verbose-anti-join" <<'EOF_CHK_EXPLAIN_VERBOSE_ANTI_JOIN'
explain verbose
EOF_CHK_EXPLAIN_VERBOSE_ANTI_JOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-hashjoin · EXPLAIN VERBOSE hashjoin 行数估算 · layer=db-interactive-cmd
run_check "chk-explain-verbose-hashjoin" <<'EOF_CHK_EXPLAIN_VERBOSE_HASHJOIN'
set cost_param=2; explain verbose
EOF_CHK_EXPLAIN_VERBOSE_HASHJOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-dn · explain performance 各 DN 实际行数 · layer=db-interactive-cmd
run_check "chk-explain-performance-dn" <<'EOF_CHK_EXPLAIN_PERFORMANCE_DN'
explain performance select count(*) from inventory;
EOF_CHK_EXPLAIN_PERFORMANCE_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-dn · table_skewness() 各 DN 数据分布比例 · layer=db-system-view
run_check "chk-table-skewness-dn" <<'EOF_CHK_TABLE_SKEWNESS_DN'
select table_skewness('inventory');
EOF_CHK_TABLE_SKEWNESS_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-streaming-redistribute-dn · EXPLAIN ANALYZE Streaming(REDISTRIBUTE) 各 DN 输出行数 · layer=db-interactive-cmd
run_check "chk-explain-analyze-streaming-redistribute-dn" <<'EOF_CHK_EXPLAIN_ANALYZE_STREAMING_REDISTRIBUTE_DN'
explain select * from skew s,test t where s.x = t.x order by s.a limit 1;
EOF_CHK_EXPLAIN_ANALYZE_STREAMING_REDISTRIBUTE_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-get-last-data-changed-time · pg_stat_get_last_data_changed_time 最近变更的表 · layer=db-system-view
run_check "chk-pg-stat-get-last-data-changed-time" <<'EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME'
SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();
EOF_CHK_PG_STAT_GET_LAST_DATA_CHANGED_TIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-distribution-dn · table_distribution() 各 DN 存储空间分布 · layer=db-system-view
run_check "chk-table-distribution-dn" <<'EOF_CHK_TABLE_DISTRIBUTION_DN'
SELECT table_distribution(schemaname,relname) FROM get_last_changed_table();
EOF_CHK_TABLE_DISTRIBUTION_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-xc-node-id · 按 xc_node_id 分组的表数据行数 · layer=db-system-view
run_check "chk-xc-node-id" <<'EOF_CHK_XC_NODE_ID'
SELECT a.count,b.node_name         FROM             (SELECT count(*) AS count,xc_node_id FROM tablename GROUP BY xc_node_id) a,               pgxc_node b         WHERE a.xc_node_id=b.node_id ORDER BY a.count DESC;
EOF_CHK_XC_NODE_ID

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-streaming · EXPLAIN 计划是否含 Streaming · layer=db-interactive-cmd
run_check "chk-explain-streaming" <<'EOF_CHK_EXPLAIN_STREAMING'
CREATE TABLE t1 (a int, b int) DISTRIBUTE BY HASH (a); CREATE TABLE t2 (a int, b int) DISTRIBUTE BY HASH (a);
EOF_CHK_EXPLAIN_STREAMING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-streaming · 调整后 EXPLAIN 是否消除 Streaming · layer=db-interactive-cmd
run_check "chk-explain-streaming" <<'EOF_CHK_EXPLAIN_STREAMING'
CREATE TABLE t1 (a int, b int) DISTRIBUTE BY HASH (a); CREATE TABLE t2 (a int, b int) DISTRIBUTE BY HASH (b);
EOF_CHK_EXPLAIN_STREAMING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-hashjoin-dn · EXPLAIN ANALYZE HashJoin 各 DN 执行时间范围 · layer=db-interactive-cmd
run_check "chk-explain-analyze-hashjoin-dn" <<'EOF_CHK_EXPLAIN_ANALYZE_HASHJOIN_DN'
EXPLAIN ANALYZE
EOF_CHK_EXPLAIN_ANALYZE_HASHJOIN_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-memory-information-dn · Memory Information 各 DN 内存消耗分布 · layer=db-interactive-cmd
run_check "chk-memory-information-dn" <<'EOF_CHK_MEMORY_INFORMATION_DN'
EXPLAIN ANALYZE` (Memory Information 段)
EOF_CHK_MEMORY_INFORMATION_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-seq-scan-dn · Seq Scan 各 DN 扫描时间 · layer=db-interactive-cmd
run_check "chk-seq-scan-dn" <<'EOF_CHK_SEQ_SCAN_DN'
EXPLAIN ANALYZE
EOF_CHK_SEQ_SCAN_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze · EXPLAIN ANALYZE 执行计划耗时与过滤行数 · layer=db-interactive-cmd
run_check "chk-explain-analyze" <<'EOF_CHK_EXPLAIN_ANALYZE'
explain (analyze on, costs off) select * from store_sales where ss_sold_date_sk = 2450944;
EOF_CHK_EXPLAIN_ANALYZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-join · EXPLAIN ANALYZE Join 算子类型与耗时 · layer=db-interactive-cmd
run_check "chk-explain-analyze-join" <<'EOF_CHK_EXPLAIN_ANALYZE_JOIN'
EXPLAIN ANALYZE
EOF_CHK_EXPLAIN_ANALYZE_JOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-agg · EXPLAIN ANALYZE Agg 算子类型 · layer=db-interactive-cmd
run_check "chk-explain-analyze-agg" <<'EOF_CHK_EXPLAIN_ANALYZE_AGG'
EXPLAIN ANALYZE
EOF_CHK_EXPLAIN_ANALYZE_AGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-iostat-util-r-await-w-await · iostat 中 %util / r_await / w_await · layer=os
run_check "chk-iostat-util-r-await-w-await" <<'EOF_CHK_IOSTAT_UTIL_R_AWAIT_W_AWAIT'
iostat
EOF_CHK_IOSTAT_UTIL_R_AWAIT_W_AWAIT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-top-sar-gaussdb-cpu · top / sar 中 gaussdb 进程 CPU 占用 · layer=os
run_check "chk-top-sar-gaussdb-cpu" <<'EOF_CHK_TOP_SAR_GAUSSDB_CPU'
top -b -n 1
EOF_CHK_TOP_SAR_GAUSSDB_CPU

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance · EXPLAIN PERFORMANCE 算子耗时 · layer=db-interactive-cmd
run_check "chk-explain-performance" <<'EOF_CHK_EXPLAIN_PERFORMANCE'
EXPLAIN PERFORMANCE
EOF_CHK_EXPLAIN_PERFORMANCE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-scan-filter · Scan filter 条件分析 · layer=db-interactive-cmd
run_check "chk-scan-filter" <<'EOF_CHK_SCAN_FILTER'
EXPLAIN PERFORMANCE
EOF_CHK_SCAN_FILTER

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-not-in · 含 NOT IN 子查询的执行计划 · layer=db-interactive-cmd
run_check "chk-not-in" <<'EOF_CHK_NOT_IN'
EXPLAIN SELECT * FROM t1 WHERE c1 NOT IN (SELECT d2 FROM t2);
EOF_CHK_NOT_IN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-null-005 · 执行计划子查询处理方式 · layer=db-interactive-cmd
run_check "chk-null-005" <<'EOF_CHK_NULL_005'
explain verbose select t1.c1 from t1 where t1.c1 = (select t2.c1 from t2 where t1.c1=t2.c1);
EOF_CHK_NULL_005

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-windowagg-sort · EXPLAIN PERFORMANCE 执行计划 · WindowAgg/Sort 算子耗时 · layer=db-interactive-cmd
run_check "chk-explain-performance-windowagg-sort" <<'EOF_CHK_EXPLAIN_PERFORMANCE_WINDOWAGG_SORT'
explain performance
EOF_CHK_EXPLAIN_PERFORMANCE_WINDOWAGG_SORT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status-wait-status · pgxc_thread_wait_status.wait_status · layer=db-system-view
run_check "chk-pgxc-thread-wait-status-wait-status" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS'
Select wait_status, count(*) cnt from pgxc_thread_wait_status where wait_status not like '%cmd%' and wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;
EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-table-distribution · table_skewness / table_distribution · layer=db-system-view
run_check "chk-table-skewness-table-distribution" <<'EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION'
select table_skewness('store_sales');
EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-null-006 · 线程等待状态 · layer=db-system-view
run_check "chk-null-006" <<'EOF_CHK_NULL_006'
select * from pg_thread_wait_status where query_id='149181737656737395';
EOF_CHK_NULL_006

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-sql-create-index · 活跃SQL及CREATE INDEX语句 · layer=db-system-view
run_check "chk-sql-create-index" <<'EOF_CHK_SQL_CREATE_INDEX'
select * from pg_stat_activity where state !='idle' and usename !='omm';
EOF_CHK_SQL_CREATE_INDEX

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-null-007 · 表数据倾斜 · layer=db-system-view
run_check "chk-null-007" <<'EOF_CHK_NULL_007'
select table_skewness('ioc_dm.m_ss_index_event');
EOF_CHK_NULL_007

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dn-xc-node-id · 各 DN 数据量分布 (xc_node_id 分组) · layer=db-system-view
run_check "chk-dn-xc-node-id" <<'EOF_CHK_DN_XC_NODE_ID'
SELECT a.count,b.node_name FROM (SELECT count(*) AS count,xc_node_id FROM table_name GROUP BY xc_node_id) a, pgxc_node b WHERE a.xc_node_id=b.node_id ORDER BY a.count desc;
EOF_CHK_DN_XC_NODE_ID

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-period-ttl · 分区表 period / ttl 参数设置 · layer=db-shell
run_check "chk-period-ttl" <<'EOF_CHK_PERIOD_TTL'
CREATE TABLE CPU1(...) with (TTL='7 days',PERIOD='1 day', TIME_FORMAT='YYYYMMDD')
EOF_CHK_PERIOD_TTL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-get-stat-all-tables-dirty-page-rate · PGXC_GET_STAT_ALL_TABLES.dirty_page_rate · layer=db-system-view
run_check "chk-pgxc-get-stat-all-tables-dirty-page-rate" <<'EOF_CHK_PGXC_GET_STAT_ALL_TABLES_DIRTY_PAGE_RATE'
SELECT schemaname AS schema, relname AS table_name, n_live_tup AS analyze_count, pg_size_pretty(pg_table_size(relid)) as table_size, dirty_page_rate FROM PGXC_GET_STAT_ALL_TABLES WHERE schemaName NOT IN ('pg_toast', 'pg_catalog', 'information_schema', 'cstore', 'pmk') AND dirty_page_rate > 30 ORDER BY table_size DESC, dirty_page_rate DESC;
EOF_CHK_PGXC_GET_STAT_ALL_TABLES_DIRTY_PAGE_RATE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-index-scan · EXPLAIN 执行计划 · 是否使用Index Scan · layer=db-interactive-cmd
run_check "chk-explain-index-scan" <<'EOF_CHK_EXPLAIN_INDEX_SCAN'
explain verbose select * from test where a = 101;
EOF_CHK_EXPLAIN_INDEX_SCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-index-scan-vs-seq-scan · EXPLAIN VERBOSE · Index Scan vs Seq Scan · layer=db-interactive-cmd
run_check "chk-explain-verbose-index-scan-vs-seq-scan" <<'EOF_CHK_EXPLAIN_VERBOSE_INDEX_SCAN_VS_SEQ_SCAN'
explain verbose select * from test where a  = 101;
EOF_CHK_EXPLAIN_VERBOSE_INDEX_SCAN_VS_SEQ_SCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dn · 各DN数据量分布 · layer=db-shell
run_check "chk-dn" <<'EOF_CHK_DN'
SELECT pg_get_tabledef('customer_t1');
EOF_CHK_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-codegen · enable_codegen 参数状态 · layer=db-shell
run_check "chk-enable-codegen" <<'EOF_CHK_ENABLE_CODEGEN'
SHOW turbo_engine_version;
EOF_CHK_ENABLE_CODEGEN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-wlm-session-info-streaming-stream-count · pgxc_wlm_session_info · Streaming 算子数（stream_count） · layer=db-system-view
run_check "chk-pgxc-wlm-session-info-streaming-stream-count" <<'EOF_CHK_PGXC_WLM_SESSION_INFO_STREAMING_STREAM_COUNT'
SELECT *,(length(query_plan) - length(replace(query_plan, 'Streaming', ''))) / length('Streaming') AS stream_count FROM pgxc_wlm_session_info ORDER BY stream_count DESC limit 100;
EOF_CHK_PGXC_WLM_SESSION_INFO_STREAMING_STREAM_COUNT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-wlm-session-info-max-cpu-time-cpu · pgxc_wlm_session_info · max_cpu_time（高CPU语句） · layer=db-system-view
run_check "chk-pgxc-wlm-session-info-max-cpu-time-cpu" <<'EOF_CHK_PGXC_WLM_SESSION_INFO_MAX_CPU_TIME_CPU'
SELECT * FROM pgxc_wlm_session_info WHERE start_time > 'xxxx-xx-xx' AND start_time < 'xxxx-xx-xx' ORDER BY max_cpu_time desc;
EOF_CHK_PGXC_WLM_SESSION_INFO_MAX_CPU_TIME_CPU

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-resource-track-level-operator-realtime · resource_track_level · operator_realtime 级别实时算子监控 · layer=db-system-view
run_check "chk-resource-track-level-operator-realtime" <<'EOF_CHK_RESOURCE_TRACK_LEVEL_OPERATOR_REALTIME'
SET resource_track_level = 'operator_realtime';
EOF_CHK_RESOURCE_TRACK_LEVEL_OPERATOR_REALTIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-runtime-current-timestamp-query-start · PGXC_STAT_ACTIVITY · runtime (current_timestamp - query_start) · layer=db-system-view
run_check "chk-pgxc-stat-activity-runtime-current-timestamp-query-start" <<'EOF_CHK_PGXC_STAT_ACTIVITY_RUNTIME_CURRENT_TIMESTAMP_QUERY_START'
SELECT current_timestamp - query_start as runtime, datname, usename, query FROM PGXC_STAT_ACTIVITY WHERE state != 'idle' order by 1 desc;
EOF_CHK_PGXC_STAT_ACTIVITY_RUNTIME_CURRENT_TIMESTAMP_QUERY_START

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-waiting-true · PGXC_STAT_ACTIVITY · waiting=true 阻塞查询 · layer=db-system-view
run_check "chk-pgxc-stat-activity-waiting-true" <<'EOF_CHK_PGXC_STAT_ACTIVITY_WAITING_TRUE'
SELECT coorname, pid, datname, usename, state, query FROM PGXC_STAT_ACTIVITY WHERE state <> 'idle' and waiting=true;
EOF_CHK_PGXC_STAT_ACTIVITY_WAITING_TRUE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-lock-conflicts · pgxc_lock_conflicts 锁冲突视图 · layer=db-system-view
run_check "chk-pgxc-lock-conflicts" <<'EOF_CHK_PGXC_LOCK_CONFLICTS'
SELECT * FROM pgxc_lock_conflicts;
EOF_CHK_PGXC_LOCK_CONFLICTS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-state-waiting-query · pgxc_stat_activity · state / waiting / query · layer=db-system-view
run_check "chk-pgxc-stat-activity-state-waiting-query" <<'EOF_CHK_PGXC_STAT_ACTIVITY_STATE_WAITING_QUERY'
SELECT coorname, pid,datname,usename,state,waiting,query FROM pgxc_stat_activity WHERE state <> 'idle';
EOF_CHK_PGXC_STAT_ACTIVITY_STATE_WAITING_QUERY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic- · pgxc_total_memory_detail · dynamic_used_memory vs max_dynamic_memory · layer=db-system-view
run_check "chk-pgxc-total-memory-detail-dynamic-used-memory-vs-max-dynamic-" <<'EOF_CHK_PGXC_TOTAL_MEMORY_DETAIL_DYNAMIC_USED_MEMORY_VS_MAX_DYNAMIC_'
SELECT * FROM pgxc_total_memory_detail;
EOF_CHK_PGXC_TOTAL_MEMORY_DETAIL_DYNAMIC_USED_MEMORY_VS_MAX_DYNAMIC_

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc · pgxc_wlm_session_statistics · max_peak_memory / memory_skew_percent · layer=db-system-view
run_check "chk-pgxc-wlm-session-statistics-max-peak-memory-memory-skew-perc" <<'EOF_CHK_PGXC_WLM_SESSION_STATISTICS_MAX_PEAK_MEMORY_MEMORY_SKEW_PERC'
SELECT nodename,pid,dbname,username,application_name,min_peak_memory,max_peak_memory,average_peak_memory,memory_skew_percent,substr(query,0,50) as query FROM pgxc_wlm_session_statistics;
EOF_CHK_PGXC_WLM_SESSION_STATISTICS_MAX_PEAK_MEMORY_MEMORY_SKEW_PERC

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status-dn · pgxc_thread_wait_status · 作业等待 DN 分布 · layer=db-system-view
run_check "chk-pgxc-thread-wait-status-dn" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS_DN'
SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc;
EOF_CHK_PGXC_THREAD_WAIT_STATUS_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-dn · explain performance · DN 行数与耗时分布 · layer=db-interactive-cmd
run_check "chk-explain-performance-dn" <<'EOF_CHK_EXPLAIN_PERFORMANCE_DN'
explain performance select avg(ss_wholesale_cost) from store_sales;
EOF_CHK_EXPLAIN_PERFORMANCE_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness · table_skewness · 数据倾斜率 · layer=db-system-view
run_check "chk-table-skewness" <<'EOF_CHK_TABLE_SKEWNESS'
SELECT table_skewness('store_sales');
EOF_CHK_TABLE_SKEWNESS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-get-table-skewness · pgxc_get_table_skewness · 全库倾斜视图 · layer=db-system-view
run_check "chk-pgxc-get-table-skewness" <<'EOF_CHK_PGXC_GET_TABLE_SKEWNESS'
SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;
EOF_CHK_PGXC_GET_TABLE_SKEWNESS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-thread-wait-status · pg_thread_wait_status · 线程等待状态 · layer=db-system-view
run_check "chk-pg-thread-wait-status" <<'EOF_CHK_PG_THREAD_WAIT_STATUS'
SELECT * FROM pg_thread_wait_status WHERE query_id='149181737656737395';
EOF_CHK_PG_THREAD_WAIT_STATUS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-activity-sql · pg_stat_activity 活跃SQL · layer=db-system-view
run_check "chk-pg-stat-activity-sql" <<'EOF_CHK_PG_STAT_ACTIVITY_SQL'
SELECT * from pg_stat_activity where state !='idle' and usename !='Ruby';
EOF_CHK_PG_STAT_ACTIVITY_SQL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-null-014 · 表倾斜情况 · layer=db-shell
run_check "chk-null-014" <<'EOF_CHK_NULL_014'
SELECT table_skewness('table name');
EOF_CHK_NULL_014

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-session-wlmstat-status-statement-mem · pg_session_wlmstat · status / statement_mem · layer=db-system-view
run_check "chk-pg-session-wlmstat-status-statement-mem" <<'EOF_CHK_PG_SESSION_WLMSTAT_STATUS_STATEMENT_MEM'
SELECT usename,substr(query,0,20),threadid,status,statement_mem FROM pg_session_wlmstat where usename not in ('omm','Ruby') order by statement_mem,status desc;
EOF_CHK_PG_SESSION_WLMSTAT_STATUS_STATEMENT_MEM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status-wait-status-wait-event · pgxc_thread_wait_status · wait_status / wait_event · layer=db-system-view
run_check "chk-pgxc-thread-wait-status-wait-status-wait-event" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS_WAIT_EVENT'
SELECT wait_status,wait_event,count(*) AS cnt FROM pgxc_thread_wait_status WHERE wait_status <> 'wait cmd' AND wait_status <> 'synchronize quit' AND wait_status <> 'none'  GROUP BY 1,2 ORDER BY 3 DESC limit 50;
EOF_CHK_PGXC_THREAD_WAIT_STATUS_WAIT_STATUS_WAIT_EVENT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-partition · pg_partition 各表分区数 · layer=db-system-view
run_check "chk-pg-partition" <<'EOF_CHK_PG_PARTITION'
SELECT relname,reloptions,partcount FROM pg_class c INNER JOIN ( SELECT parentid,count(*) AS partcount FROM pg_partition GROUP BY parentid ) s ON c.oid = s.parentid ORDER BY partcount DESC;
EOF_CHK_PG_PARTITION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-lock-conflicts-8-1-x · pgxc_lock_conflicts 锁冲突（8.1.x及以上） · layer=db-system-view
run_check "chk-pgxc-lock-conflicts-8-1-x" <<'EOF_CHK_PGXC_LOCK_CONFLICTS_8_1_X'
SELECT * FROM pgxc_lock_conflicts;
EOF_CHK_PGXC_LOCK_CONFLICTS_8_1_X

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-vacuum-full-8-0-x · pgxc_stat_activity 中 VACUUM FULL 等待状态（8.0.x及之前） · layer=db-system-view
run_check "chk-pgxc-stat-activity-vacuum-full-8-0-x" <<'EOF_CHK_PGXC_STAT_ACTIVITY_VACUUM_FULL_8_0_X'
SELECT * FROM pgxc_stat_activity WHERE query LIKE '%vacuum%'AND waiting = 't';
EOF_CHK_PGXC_STAT_ACTIVITY_VACUUM_FULL_8_0_X

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-thread-wait-status · pgxc_thread_wait_status 锁等待状态 · layer=db-system-view
run_check "chk-pgxc-thread-wait-status" <<'EOF_CHK_PGXC_THREAD_WAIT_STATUS'
SELECT * FROM pgxc_thread_wait_status WHERE query_id = {query_id};
EOF_CHK_PGXC_THREAD_WAIT_STATUS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pck · 表定义是否存在PCK · layer=db-shell
run_check "chk-pck" <<'EOF_CHK_PCK'
SELECT * FROM pg_get_tabledef('table name');
EOF_CHK_PCK

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-psort-work-mem · psort_work_mem 参数值 · layer=db-shell
run_check "chk-psort-work-mem" <<'EOF_CHK_PSORT_WORK_MEM'
show psort_work_mem;
EOF_CHK_PSORT_WORK_MEM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dn · 各 DN 数据条数分布 · layer=db-interactive-cmd
run_check "chk-dn" <<'EOF_CHK_DN'
SELECT a.count,b.node_name FROM (SELECT count(*) AS count,xc_node_id FROM table_name GROUP BY xc_node_id) a, pgxc_node b WHERE a.xc_node_id=b.node_id ORDER BY a.count desc;
EOF_CHK_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-agg-hashagg-gather-vs-redistribute-hashagg · EXPLAIN · Agg 计划形态（hashagg+gather vs redistribute+hashagg） · layer=db-interactive-cmd
run_check "chk-explain-agg-hashagg-gather-vs-redistribute-hashagg" <<'EOF_CHK_EXPLAIN_AGG_HASHAGG_GATHER_VS_REDISTRIBUTE_HASHAGG'
explain select b,count(1) from t1 group by b
EOF_CHK_EXPLAIN_AGG_HASHAGG_GATHER_VS_REDISTRIBUTE_HASHAGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-anti-join · EXPLAIN VERBOSE · Anti Join 执行计划及行数估算 · layer=db-interactive-cmd
run_check "chk-explain-verbose-anti-join" <<'EOF_CHK_EXPLAIN_VERBOSE_ANTI_JOIN'
explain verbose select count(*) as numwait from lineitem l1, orders where o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and not exists (select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) order by numwait desc
EOF_CHK_EXPLAIN_VERBOSE_ANTI_JOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-hashjoin · EXPLAIN VERBOSE · HashJoin 行数估算偏差 · layer=db-interactive-cmd
run_check "chk-explain-verbose-hashjoin" <<'EOF_CHK_EXPLAIN_VERBOSE_HASHJOIN'
set cost_param=2; explain verbose select nation, sum(amount) as sum_profit from (...) as profit group by nation order by nation
EOF_CHK_EXPLAIN_VERBOSE_HASHJOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-dn · 磁盘利用率各 DN 差异 · layer=db-shell
run_check "chk-dn" <<'EOF_CHK_DN'
SELECT wait_status, count(*) as cnt FROM pgxc_thread_wait_status WHERE wait_status not like '%cmd%' AND wait_status not like '%none%' and wait_status not like '%quit%' group by 1 order by 2 desc
EOF_CHK_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-dn-scan · EXPLAIN PERFORMANCE 各 DN 基表 scan 行数及时间分布 · layer=db-interactive-cmd
run_check "chk-explain-performance-dn-scan" <<'EOF_CHK_EXPLAIN_PERFORMANCE_DN_SCAN'
explain performance select avg(ss_wholesale_cost) from store_sales
EOF_CHK_EXPLAIN_PERFORMANCE_DN_SCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-table-distribution · table_skewness / table_distribution · 表数据倾斜率 · layer=db-shell
run_check "chk-table-skewness-table-distribution" <<'EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION'
SELECT table_skewness('store_sales')
EOF_CHK_TABLE_SKEWNESS_TABLE_DISTRIBUTION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-stream-dn · EXPLAIN PERFORMANCE · Stream 算子各 DN 行数分布 · layer=db-interactive-cmd
run_check "chk-explain-performance-stream-dn" <<'EOF_CHK_EXPLAIN_PERFORMANCE_STREAM_DN'
select * from skew s,test t where s.x = t.x order by s.a limit 1
EOF_CHK_EXPLAIN_PERFORMANCE_STREAM_DN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-streaming-type-redistribute · EXPLAIN · Streaming(type: REDISTRIBUTE) 算子是否出现 · layer=db-interactive-cmd
run_check "chk-explain-streaming-type-redistribute" <<'EOF_CHK_EXPLAIN_STREAMING_TYPE_REDISTRIBUTE'
EXPLAIN SELECT * FROM t1, t2 WHERE t1.a = t2.b
EOF_CHK_EXPLAIN_STREAMING_TYPE_REDISTRIBUTE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-stat-activity-state · pgxc_stat_activity state 字段 · layer=db-system-view
run_check "chk-pgxc-stat-activity-state" <<'EOF_CHK_PGXC_STAT_ACTIVITY_STATE'
SELECT state, query, query_id FROM pgxc_stat_activity;
EOF_CHK_PGXC_STAT_ACTIVITY_STATE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-cn-savepoint-release · 各 CN 上 SAVEPOINT/RELEASE 语句分布 · layer=db-system-view
run_check "chk-cn-savepoint-release" <<'EOF_CHK_CN_SAVEPOINT_RELEASE'
SELECT coorname,pid,query_id,state,query,usename FROM pgxc_stat_activity WHERE usename='jack';
EOF_CHK_CN_SAVEPOINT_RELEASE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-join-nestloop-vs-hashjoin · EXPLAIN · JOIN 算子类型 (NestLoop vs HashJoin) · layer=db-interactive-cmd
run_check "chk-explain-join-nestloop-vs-hashjoin" <<'EOF_CHK_EXPLAIN_JOIN_NESTLOOP_VS_HASHJOIN'
EXPLAIN SELECT ls_pid_cusr1,COALESCE(max(round((current_date-bthdate)/365)),0) FROM calc_empfyc_c1_result_tmp_t1 t1,p10_md_tmp_t2 t2 WHERE t1.ls_pid_cusr1 = any(values(id),(id15)) GROUP BY ls_pid_cusr1
EOF_CHK_EXPLAIN_JOIN_NESTLOOP_VS_HASHJOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance · EXPLAIN PERFORMANCE · 基表扫描方式及执行时间 · layer=db-interactive-cmd
run_check "chk-explain-performance" <<'EOF_CHK_EXPLAIN_PERFORMANCE'
EXPLAIN PERFORMANCE SELECT * FROM orders WHERE o_custkey = '1106459
EOF_CHK_EXPLAIN_PERFORMANCE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-not-in · EXPLAIN VERBOSE · NOT IN 执行计划算子类型 · layer=db-interactive-cmd
run_check "chk-explain-verbose-not-in" <<'EOF_CHK_EXPLAIN_VERBOSE_NOT_IN'
EXPLAIN VERBOSE SELECT * FROM t1 WHERE t1.c NOT IN (SELECT t2.c FROM t2)
EOF_CHK_EXPLAIN_VERBOSE_NOT_IN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-verbose-not-exists · EXPLAIN VERBOSE · NOT EXISTS 执行计划算子类型验证 · layer=db-interactive-cmd
run_check "chk-explain-verbose-not-exists" <<'EOF_CHK_EXPLAIN_VERBOSE_NOT_EXISTS'
EXPLAIN VERBOSE SELECT * FROM t1 WHERE NOT EXISTS (SELECT 1 FROM t2 WHERE t2.c = t1.c)
EOF_CHK_EXPLAIN_VERBOSE_NOT_EXISTS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze · EXPLAIN ANALYZE · 基表扫描算子类型及执行时间 · layer=db-interactive-cmd
run_check "chk-explain-analyze" <<'EOF_CHK_EXPLAIN_ANALYZE'
explain (analyze on, costs off) select * from store_sales where ss_sold_date_sk = 2450944
EOF_CHK_EXPLAIN_ANALYZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-verbose-sql-partition-iterator · EXPLAIN ANALYZE VERBOSE · SQL 自诊断信息 + Partition Iterator 扫描分区数 · layer=db-interactive-cmd
run_check "chk-explain-analyze-verbose-sql-partition-iterator" <<'EOF_CHK_EXPLAIN_ANALYZE_VERBOSE_SQL_PARTITION_ITERATOR'
EXPLAIN (ANALYZE ON, VERBOSE ON) SELECT count(1) FROM t_ddw_f10_op_cust_asset_mon b1 WHERE b1.year_mth < substr('20200722',1 ,6 ) AND b1.year_mth + 1 >= cast(substr('20200722',1 ,6 ) AS int)
EOF_CHK_EXPLAIN_ANALYZE_VERBOSE_SQL_PARTITION_ITERATOR

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-analyze-verbose-partition-iterator-iterations · EXPLAIN ANALYZE VERBOSE · 改写后 Partition Iterator Iterations · layer=db-interactive-cmd
run_check "chk-explain-analyze-verbose-partition-iterator-iterations" <<'EOF_CHK_EXPLAIN_ANALYZE_VERBOSE_PARTITION_ITERATOR_ITERATIONS'
EXPLAIN (analyze ON, verbose ON) SELECT count(1) FROM t_ddw_f10_op_cust_asset_mon b1 WHERE b1.year_mth < substr('20200722',1 ,6 ) AND b1.year_mth >= cast(substr('20200722',1 ,6 ) AS int) - 1
EOF_CHK_EXPLAIN_ANALYZE_VERBOSE_PARTITION_ITERATOR_ITERATIONS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-partition-iterator-iterations · EXPLAIN PERFORMANCE · 全表扫描时间及 Partition Iterator Iterations · layer=db-interactive-cmd
run_check "chk-explain-performance-partition-iterator-iterations" <<'EOF_CHK_EXPLAIN_PERFORMANCE_PARTITION_ITERATOR_ITERATIONS'
EXPLAIN PERFORMANCE SELECT count(*) FROM orders_no_part WHERE o_orderdate >= '1996-01-01 00:00:00'::timestamp(0)
EOF_CHK_EXPLAIN_PERFORMANCE_PARTITION_ITERATOR_ITERATIONS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-cunone-filter · EXPLAIN PERFORMANCE · CUNone 比例及 filter 耗时 · layer=db-interactive-cmd
run_check "chk-explain-performance-cunone-filter" <<'EOF_CHK_EXPLAIN_PERFORMANCE_CUNONE_FILTER'
EXPLAIN PERFORMANCE SELECT * FROM orders_no_pck WHERE o_orderkey = '13095143' ORDER BY o_orderdate
EOF_CHK_EXPLAIN_PERFORMANCE_CUNONE_FILTER

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-cstore-scan-cu · EXPLAIN PERFORMANCE · CStore Scan CU 加载数量 · layer=db-interactive-cmd
run_check "chk-explain-performance-cstore-scan-cu" <<'EOF_CHK_EXPLAIN_PERFORMANCE_CSTORE_SCAN_CU'
EXPLAIN PERFORMANCE SELECT sum(l_extendedprice * l_discount) as revenue FROM lineitem WHERE l_shipdate >= '1994-01-01'::date and l_shipdate < '1994-01-01'::date + interval '1 year' and l_discount between 0.06 - 0.01 and 0.06 + 0.01 and l_quantity < 24
EOF_CHK_EXPLAIN_PERFORMANCE_CSTORE_SCAN_CU

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance · explain performance 执行时间 · layer=db-interactive-cmd
run_check "chk-explain-performance" <<'EOF_CHK_EXPLAIN_PERFORMANCE'
explain performance select a.ca_state state, count(*) cnt from customer_address a ,customer c ,store_sales s ,date_dim d ,item i where a.ca_address_sk = c.c_current_addr_sk ...
EOF_CHK_EXPLAIN_PERFORMANCE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-leading-hint · 加 leading hint 后执行时间 · layer=db-interactive-cmd
run_check "chk-leading-hint" <<'EOF_CHK_LEADING_HINT'
select /*+ leading((s d)) */ a.ca_state state, count(*) cnt ...
EOF_CHK_LEADING_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-leading-no-nestloop-hint · 加 leading + no nestloop hint 后执行时间 · layer=db-interactive-cmd
run_check "chk-leading-no-nestloop-hint" <<'EOF_CHK_LEADING_NO_NESTLOOP_HINT'
select /*+ leading((s d)) no nestloop(s d) */ a.ca_state state, count(*) cnt ...
EOF_CHK_LEADING_NO_NESTLOOP_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-rows-hint · rows hint 后执行时间 · layer=db-interactive-cmd
run_check "chk-rows-hint" <<'EOF_CHK_ROWS_HINT'
select /*+ rows(s #2880404) */ a.ca_state state, count(*) cnt ...
EOF_CHK_ROWS_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-skew-hint-agg · skew hint 后双层 Agg 计划 · layer=db-interactive-cmd
run_check "chk-skew-hint-agg" <<'EOF_CHK_SKEW_HINT_AGG'
select /*+ skew(store_returns(sr_store_sk sr_customer_sk)) */sr_customer_sk as ctr_customer_sk ...
EOF_CHK_SKEW_HINT_AGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-rows-hint · EXPLAIN PERFORMANCE · rows hint 修正后各算子行数及整体耗时 · layer=db-interactive-cmd
run_check "chk-explain-performance-rows-hint" <<'EOF_CHK_EXPLAIN_PERFORMANCE_ROWS_HINT'
select avg(netpaid) from (select /*+rows(store_sales store_returns * 11270)*/ c_last_name ...
EOF_CHK_EXPLAIN_PERFORMANCE_ROWS_HINT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance-vector-windowagg · EXPLAIN PERFORMANCE 执行计划 · Vector WindowAgg 耗时及位置 · layer=db-interactive-cmd
run_check "chk-explain-performance-vector-windowagg" <<'EOF_CHK_EXPLAIN_PERFORMANCE_VECTOR_WINDOWAGG'
EXPLAIN PERFORMANCE SELECT COUNT(1) over() AS DATACNT, IMSI AS IMSI_IMSI, CAST(TRUNC(((SUM(L4_UL_THROUGHPUT) + SUM(L4_DW_THROUGHPUT))), 0) AS DECIMAL(20)) AS TOTAL_VOLUME_KPIID FROM public.test AS test GROUP BY IMSI ORDER BY TOTAL_VOLUME_KPIID DESC LIMIT 10
EOF_CHK_EXPLAIN_PERFORMANCE_VECTOR_WINDOWAGG

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance · EXPLAIN PERFORMANCE 改写后执行计划 · 排序下推验证 · layer=db-interactive-cmd
run_check "chk-explain-performance" <<'EOF_CHK_EXPLAIN_PERFORMANCE'
EXPLAIN PERFORMANCE SELECT COUNT(1) over() AS DATACNT, IMSI_IMSI, TOTAL_VOLUME_KPIID FROM (SELECT IMSI AS IMSI_IMSI, CAST(TRUNC(((SUM(L4_UL_THROUGHPUT) + SUM(L4_DW_THROUGHPUT))), 0) AS DECIMAL(20)) AS TOTAL_VOLUME_KPIID FROM public.test AS test GROUP BY IMSI ORDER BY TOTAL_VOLUME_KPIID DESC LIMIT 10)
EOF_CHK_EXPLAIN_PERFORMANCE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-gs-wlm-session-history-warning-sql · GS_WLM_SESSION_HISTORY.warning · SQL 自诊断信息 · layer=db-system-view
run_check "chk-gs-wlm-session-history-warning-sql" <<'EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING_SQL'
SELECT query,warning FROM GS_WLM_SESSION_HISTORY ORDER BY start_time DESC
EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING_SQL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-gs-wlm-session-history-warning · GS_WLM_SESSION_HISTORY.warning · 统计信息未收集告警 · layer=db-system-view
run_check "chk-gs-wlm-session-history-warning" <<'EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING'
SELECT query,warning FROM GS_WLM_SESSION_STATISTICS ORDER BY start_time DESC
EOF_CHK_GS_WLM_SESSION_HISTORY_WARNING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-xid · 当前事务 XID · layer=db-system-view
run_check "chk-xid" <<'EOF_CHK_XID'
SELECT txid_current();
EOF_CHK_XID

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-null-017 · 活跃事务列表 · layer=db-system-view
run_check "chk-null-017" <<'EOF_CHK_NULL_017'
SELECT txid_current_snapshot();
EOF_CHK_NULL_017

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-gtm-snapshot-oldestxmin-xid · GTM snapshot · oldestxmin 与 xid 差值 · layer=db-system-view
run_check "chk-gtm-snapshot-oldestxmin-xid" <<'EOF_CHK_GTM_SNAPSHOT_OLDESTXMIN_XID'
SELECT * FROM pgxc_gtm_snapshot_status();
EOF_CHK_GTM_SNAPSHOT_OLDESTXMIN_XID

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pgxc-running-xacts · 老事务列表 (pgxc_running_xacts) · layer=db-system-view
run_check "chk-pgxc-running-xacts" <<'EOF_CHK_PGXC_RUNNING_XACTS'
SELECT * FROM pgxc_running_xacts where xmin::text::bigint < $base+$min and xmin::text::bigint > 0;
EOF_CHK_PGXC_RUNNING_XACTS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-pg-stat-activity-idle · pg_stat_activity · idle 连接数 · layer=db-system-view
run_check "chk-pg-stat-activity-idle" <<'EOF_CHK_PG_STAT_ACTIVITY_IDLE'
SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';
EOF_CHK_PG_STAT_ACTIVITY_IDLE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-explain-performance · EXPLAIN PERFORMANCE · 算子分布 · layer=db-interactive-cmd
run_check "chk-explain-performance" <<'EOF_CHK_EXPLAIN_PERFORMANCE'
explain performance
EOF_CHK_EXPLAIN_PERFORMANCE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-shared-buffers · shared_buffers · layer=gaussdb-guc-param
run_check "chk-shared-buffers" <<'EOF_CHK_SHARED_BUFFERS'
gsql -d postgres -c "SHOW shared_buffers;"
EOF_CHK_SHARED_BUFFERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-work-mem · work_mem · layer=gaussdb-guc-param
run_check "chk-work-mem" <<'EOF_CHK_WORK_MEM'
gsql -d postgres -c "SHOW work_mem;"
EOF_CHK_WORK_MEM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-rewrite-rule · rewrite_rule · layer=gaussdb-guc-param
run_check "chk-rewrite-rule" <<'EOF_CHK_REWRITE_RULE'
gsql -d postgres -c "SHOW rewrite_rule;"
EOF_CHK_REWRITE_RULE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-hashjoin · enable_hashjoin · layer=gaussdb-guc-param
run_check "chk-enable-hashjoin" <<'EOF_CHK_ENABLE_HASHJOIN'
gsql -d postgres -c "SHOW enable_hashjoin;"
EOF_CHK_ENABLE_HASHJOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-nestloop · enable_nestloop · layer=gaussdb-guc-param
run_check "chk-enable-nestloop" <<'EOF_CHK_ENABLE_NESTLOOP'
gsql -d postgres -c "SHOW enable_nestloop;"
EOF_CHK_ENABLE_NESTLOOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-mergejoin · enable_mergejoin · layer=gaussdb-guc-param
run_check "chk-enable-mergejoin" <<'EOF_CHK_ENABLE_MERGEJOIN'
gsql -d postgres -c "SHOW enable_mergejoin;"
EOF_CHK_ENABLE_MERGEJOIN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-sort · enable_sort · layer=gaussdb-guc-param
run_check "chk-enable-sort" <<'EOF_CHK_ENABLE_SORT'
gsql -d postgres -c "SHOW enable_sort;"
EOF_CHK_ENABLE_SORT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-best-agg-plan · best_agg_plan · layer=gaussdb-guc-param
run_check "chk-best-agg-plan" <<'EOF_CHK_BEST_AGG_PLAN'
gsql -d postgres -c "SHOW best_agg_plan;"
EOF_CHK_BEST_AGG_PLAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-a-format-load-with-constraints-violation · a_format_load_with_constraints_violation · layer=gaussdb-guc-param
run_check "chk-a-format-load-with-constraints-violation" <<'EOF_CHK_A_FORMAT_LOAD_WITH_CONSTRAINTS_VIOLATION'
gsql -d postgres -c "SHOW a_format_load_with_constraints_violation;"
EOF_CHK_A_FORMAT_LOAD_WITH_CONSTRAINTS_VIOLATION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-cost-param · cost_param · layer=gaussdb-guc-param
run_check "chk-cost-param" <<'EOF_CHK_COST_PARAM'
gsql -d postgres -c "SHOW cost_param;"
EOF_CHK_COST_PARAM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-skew-option · skew_option · layer=gaussdb-guc-param
run_check "chk-skew-option" <<'EOF_CHK_SKEW_OPTION'
gsql -d postgres -c "SHOW skew_option;"
EOF_CHK_SKEW_OPTION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-thread-pool-attr · thread_pool_attr · layer=gaussdb-guc-param
run_check "chk-thread-pool-attr" <<'EOF_CHK_THREAD_POOL_ATTR'
gsql -d postgres -c "SHOW thread_pool_attr;"
EOF_CHK_THREAD_POOL_ATTR

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-default-statistics-target · default_statistics_target · layer=gaussdb-guc-param
run_check "chk-default-statistics-target" <<'EOF_CHK_DEFAULT_STATISTICS_TARGET'
gsql -d postgres -c "SHOW default_statistics_target;"
EOF_CHK_DEFAULT_STATISTICS_TARGET

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-behavior-compat-options · behavior_compat_options · layer=gaussdb-guc-param
run_check "chk-behavior-compat-options" <<'EOF_CHK_BEHAVIOR_COMPAT_OPTIONS'
gsql -d postgres -c "SHOW behavior_compat_options;"
EOF_CHK_BEHAVIOR_COMPAT_OPTIONS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-fast-query-shipping · enable_fast_query_shipping · layer=gaussdb-guc-param
run_check "chk-enable-fast-query-shipping" <<'EOF_CHK_ENABLE_FAST_QUERY_SHIPPING'
gsql -d postgres -c "SHOW enable_fast_query_shipping;"
EOF_CHK_ENABLE_FAST_QUERY_SHIPPING

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-recovery-parse-workers · recovery_parse_workers · layer=gaussdb-guc-param
run_check "chk-recovery-parse-workers" <<'EOF_CHK_RECOVERY_PARSE_WORKERS'
gsql -d postgres -c "SHOW recovery_parse_workers;"
EOF_CHK_RECOVERY_PARSE_WORKERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-recovery-redo-workers · recovery_redo_workers · layer=gaussdb-guc-param
run_check "chk-recovery-redo-workers" <<'EOF_CHK_RECOVERY_REDO_WORKERS'
gsql -d postgres -c "SHOW recovery_redo_workers;"
EOF_CHK_RECOVERY_REDO_WORKERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-index-nestloop · enable_index_nestloop · layer=gaussdb-guc-param
run_check "chk-enable-index-nestloop" <<'EOF_CHK_ENABLE_INDEX_NESTLOOP'
gsql -d postgres -c "SHOW enable_index_nestloop;"
EOF_CHK_ENABLE_INDEX_NESTLOOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-indexscan · enable_indexscan · layer=gaussdb-guc-param
run_check "chk-enable-indexscan" <<'EOF_CHK_ENABLE_INDEXSCAN'
gsql -d postgres -c "SHOW enable_indexscan;"
EOF_CHK_ENABLE_INDEXSCAN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-max-process-memory · max_process_memory · layer=gaussdb-guc-param
run_check "chk-max-process-memory" <<'EOF_CHK_MAX_PROCESS_MEMORY'
gsql -d postgres -c "SHOW max_process_memory;"
EOF_CHK_MAX_PROCESS_MEMORY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-qrw-inlist2join-optmode · qrw_inlist2join_optmode · layer=gaussdb-guc-param
run_check "chk-qrw-inlist2join-optmode" <<'EOF_CHK_QRW_INLIST2JOIN_OPTMODE'
gsql -d postgres -c "SHOW qrw_inlist2join_optmode;"
EOF_CHK_QRW_INLIST2JOIN_OPTMODE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-fetchsize · fetchSize · layer=gaussdb-guc-param
run_check "chk-fetchsize" <<'EOF_CHK_FETCHSIZE'
gsql -d postgres -c "SHOW fetchSize;"
EOF_CHK_FETCHSIZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-period · period · layer=gaussdb-guc-param
run_check "chk-period" <<'EOF_CHK_PERIOD'
gsql -d postgres -c "SHOW period;"
EOF_CHK_PERIOD

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-ttl · ttl · layer=gaussdb-guc-param
run_check "chk-ttl" <<'EOF_CHK_TTL'
gsql -d postgres -c "SHOW ttl;"
EOF_CHK_TTL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-disk-cache-max-size · disk_cache_max_size · layer=gaussdb-guc-param
run_check "chk-disk-cache-max-size" <<'EOF_CHK_DISK_CACHE_MAX_SIZE'
gsql -d postgres -c "SHOW disk_cache_max_size;"
EOF_CHK_DISK_CACHE_MAX_SIZE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-disk-cache-dual-write-option · disk_cache_dual_write_option · layer=gaussdb-guc-param
run_check "chk-disk-cache-dual-write-option" <<'EOF_CHK_DISK_CACHE_DUAL_WRITE_OPTION'
gsql -d postgres -c "SHOW disk_cache_dual_write_option;"
EOF_CHK_DISK_CACHE_DUAL_WRITE_OPTION

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-min-batch-rows · min_batch_rows · layer=gaussdb-guc-param
run_check "chk-min-batch-rows" <<'EOF_CHK_MIN_BATCH_ROWS'
gsql -d postgres -c "SHOW min_batch_rows;"
EOF_CHK_MIN_BATCH_ROWS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum · autovacuum · layer=gaussdb-guc-param
run_check "chk-autovacuum" <<'EOF_CHK_AUTOVACUUM'
gsql -d postgres -c "SHOW autovacuum;"
EOF_CHK_AUTOVACUUM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-vacuum-cost-delay · autovacuum_vacuum_cost_delay · layer=gaussdb-guc-param
run_check "chk-autovacuum-vacuum-cost-delay" <<'EOF_CHK_AUTOVACUUM_VACUUM_COST_DELAY'
gsql -d postgres -c "SHOW autovacuum_vacuum_cost_delay;"
EOF_CHK_AUTOVACUUM_VACUUM_COST_DELAY

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-max-workers · autovacuum_max_workers · layer=gaussdb-guc-param
run_check "chk-autovacuum-max-workers" <<'EOF_CHK_AUTOVACUUM_MAX_WORKERS'
gsql -d postgres -c "SHOW autovacuum_max_workers;"
EOF_CHK_AUTOVACUUM_MAX_WORKERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-naptime · autovacuum_naptime · layer=gaussdb-guc-param
run_check "chk-autovacuum-naptime" <<'EOF_CHK_AUTOVACUUM_NAPTIME'
gsql -d postgres -c "SHOW autovacuum_naptime;"
EOF_CHK_AUTOVACUUM_NAPTIME

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-max-active-statements · max_active_statements · layer=gaussdb-guc-param
run_check "chk-max-active-statements" <<'EOF_CHK_MAX_ACTIVE_STATEMENTS'
gsql -d postgres -c "SHOW max_active_statements;"
EOF_CHK_MAX_ACTIVE_STATEMENTS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-autovacuum-max-workers-hstore · autovacuum_max_workers_hstore · layer=gaussdb-guc-param
run_check "chk-autovacuum-max-workers-hstore" <<'EOF_CHK_AUTOVACUUM_MAX_WORKERS_HSTORE'
gsql -d postgres -c "SHOW autovacuum_max_workers_hstore;"
EOF_CHK_AUTOVACUUM_MAX_WORKERS_HSTORE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-codegen · enable_codegen · layer=gaussdb-guc-param
run_check "chk-enable-codegen" <<'EOF_CHK_ENABLE_CODEGEN'
gsql -d postgres -c "SHOW enable_codegen;"
EOF_CHK_ENABLE_CODEGEN

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-numa-bind · enable_numa_bind · layer=gaussdb-guc-param
run_check "chk-enable-numa-bind" <<'EOF_CHK_ENABLE_NUMA_BIND'
gsql -d postgres -c "SHOW enable_numa_bind;"
EOF_CHK_ENABLE_NUMA_BIND

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-abnormal-check-general-task · abnormal_check_general_task · layer=gaussdb-guc-param
run_check "chk-abnormal-check-general-task" <<'EOF_CHK_ABNORMAL_CHECK_GENERAL_TASK'
gsql -d postgres -c "SHOW abnormal_check_general_task;"
EOF_CHK_ABNORMAL_CHECK_GENERAL_TASK

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-resource-track-level · resource_track_level · layer=gaussdb-guc-param
run_check "chk-resource-track-level" <<'EOF_CHK_RESOURCE_TRACK_LEVEL'
gsql -d postgres -c "SHOW resource_track_level;"
EOF_CHK_RESOURCE_TRACK_LEVEL

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-track-activities · track_activities · layer=gaussdb-guc-param
run_check "chk-track-activities" <<'EOF_CHK_TRACK_ACTIVITIES'
gsql -d postgres -c "SHOW track_activities;"
EOF_CHK_TRACK_ACTIVITIES

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-connectiontimeout · connectionTimeOut · layer=gaussdb-guc-param
run_check "chk-connectiontimeout" <<'EOF_CHK_CONNECTIONTIMEOUT'
gsql -d postgres -c "SHOW connectionTimeOut;"
EOF_CHK_CONNECTIONTIMEOUT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-lockwait-timeout · lockwait_timeout · layer=gaussdb-guc-param
run_check "chk-lockwait-timeout" <<'EOF_CHK_LOCKWAIT_TIMEOUT'
gsql -d postgres -c "SHOW lockwait_timeout;"
EOF_CHK_LOCKWAIT_TIMEOUT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-psort-work-mem · psort_work_mem · layer=gaussdb-guc-param
run_check "chk-psort-work-mem" <<'EOF_CHK_PSORT_WORK_MEM'
gsql -d postgres -c "SHOW psort_work_mem;"
EOF_CHK_PSORT_WORK_MEM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-delta · ENABLE_DELTA · layer=gaussdb-guc-param
run_check "chk-enable-delta" <<'EOF_CHK_ENABLE_DELTA'
gsql -d postgres -c "SHOW ENABLE_DELTA;"
EOF_CHK_ENABLE_DELTA

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-resource-pool-cpu-dedicated-quota · resource_pool.cpu_dedicated_quota · layer=gaussdb-guc-param
run_check "chk-resource-pool-cpu-dedicated-quota" <<'EOF_CHK_RESOURCE_POOL_CPU_DEDICATED_QUOTA'
gsql -d postgres -c "SHOW resource_pool.cpu_dedicated_quota;"
EOF_CHK_RESOURCE_POOL_CPU_DEDICATED_QUOTA

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-temp-file-limit · temp_file_limit · layer=gaussdb-guc-param
run_check "chk-temp-file-limit" <<'EOF_CHK_TEMP_FILE_LIMIT'
gsql -d postgres -c "SHOW temp_file_limit;"
EOF_CHK_TEMP_FILE_LIMIT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-sequence-cache · sequence.cache · layer=gaussdb-guc-param
run_check "chk-sequence-cache" <<'EOF_CHK_SEQUENCE_CACHE'
gsql -d postgres -c "SHOW sequence.cache;"
EOF_CHK_SEQUENCE_CACHE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-query-dop · query_dop · layer=gaussdb-guc-param
run_check "chk-query-dop" <<'EOF_CHK_QUERY_DOP'
gsql -d postgres -c "SHOW query_dop;"
EOF_CHK_QUERY_DOP

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-cstore-buffers · cstore_buffers · layer=gaussdb-guc-param
run_check "chk-cstore-buffers" <<'EOF_CHK_CSTORE_BUFFERS'
gsql -d postgres -c "SHOW cstore_buffers;"
EOF_CHK_CSTORE_BUFFERS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-comm-max-stream · comm_max_stream · layer=gaussdb-guc-param
run_check "chk-comm-max-stream" <<'EOF_CHK_COMM_MAX_STREAM'
gsql -d postgres -c "SHOW comm_max_stream;"
EOF_CHK_COMM_MAX_STREAM

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-vacuum-defer-cleanup-age · vacuum_defer_cleanup_age · layer=gaussdb-guc-param
run_check "chk-vacuum-defer-cleanup-age" <<'EOF_CHK_VACUUM_DEFER_CLEANUP_AGE'
gsql -d postgres -c "SHOW vacuum_defer_cleanup_age;"
EOF_CHK_VACUUM_DEFER_CLEANUP_AGE

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-enable-stream-operator · enable_stream_operator · layer=gaussdb-guc-param
run_check "chk-enable-stream-operator" <<'EOF_CHK_ENABLE_STREAM_OPERATOR'
gsql -d postgres -c "SHOW enable_stream_operator;"
EOF_CHK_ENABLE_STREAM_OPERATOR

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-warning-threshold · table_skewness_warning_threshold · layer=gaussdb-guc-param
run_check "chk-table-skewness-warning-threshold" <<'EOF_CHK_TABLE_SKEWNESS_WARNING_THRESHOLD'
gsql -d postgres -c "SHOW table_skewness_warning_threshold;"
EOF_CHK_TABLE_SKEWNESS_WARNING_THRESHOLD

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-table-skewness-warning-rows · table_skewness_warning_rows · layer=gaussdb-guc-param
run_check "chk-table-skewness-warning-rows" <<'EOF_CHK_TABLE_SKEWNESS_WARNING_ROWS'
gsql -d postgres -c "SHOW table_skewness_warning_rows;"
EOF_CHK_TABLE_SKEWNESS_WARNING_ROWS

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-session-timeout · session_timeout · layer=gaussdb-guc-param
run_check "chk-session-timeout" <<'EOF_CHK_SESSION_TIMEOUT'
gsql -d postgres -c "SHOW session_timeout;"
EOF_CHK_SESSION_TIMEOUT

i=$((i+1))
[ $((i % 30)) -eq 0 ] && echo "[$i/$TOTAL]" >&2
# chk-max-connections · max_connections · layer=gaussdb-guc-param
run_check "chk-max-connections" <<'EOF_CHK_MAX_CONNECTIONS'
gsql -d postgres -c "SHOW max_connections;"
EOF_CHK_MAX_CONNECTIONS


# ── 153 个描述性 method (蒸馏不可执行 · 写 manual.md) ──────────
cat > "$OUTDIR/manual.md" <<'MANUAL_DOC_END'
# 需人审 method (描述性中文 · 不自动跑 · 共 153 项)

> distill-v2 蒸馏出来的描述性文本 (含 8+ 汉字 OR "查看/判断/通常/建议..." 等关键词),
> 不能直接当 shell 命令跑。请人工解读后手工执行,把结果跟 case abnormal_pattern 比对。

## chk-gaussdb · GaussDB内置火焰图 · 时区加载线程占比
- layer: `flamegraph` · type: `metric`
- method:
  ```
  GaussDB在内核505版本中内置了火焰图工具，默认每5分钟会自动采集一次，保存在$GAUSSLOG/gs_flamegraph/{datanode}路径下，详细信息可参考GaussDB产品文档《内置perf工具》章节。
  ```

## chk-buffer-wdr · buffer命中率 (WDR报告或管控平台)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  可以借助GaussDB的管控平台或者WDR报告。通常情况下，TP数据库的buffer命中率应该在99%以上。
  ```

## chk-explain-analyze · EXPLAIN ANALYZE 算子落盘标志
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  为了优化性能，可以查看SQL的执行计划，如果算子存在落盘的情况，可适当调整work_mem参数值。
  ```

## chk-dbe-perf-statement-cpu-time-cpu · dbe_perf.statement.cpu_time (持续CPU高)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  dbe_perf.statement`：可查询分布式本CN发起的历史语句信息。`dbe_perf.summary_statement`：可查询分布式所有CN发起的历史语句信息。（对cpu_time字段进行逆序排序即可识别）
  ```

## chk-pg-stat-activity-query-id-pg-thread-wait-status-lwtid-cpu · pg_stat_activity.query_id + pg_thread_wait_status.lwtid (当前CPU高)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  查询pg_stat_activity 获取正在运行的SQL的query_id。使用上一步的query_id，查询pg_thread_wait_status 获取正在运行的SQL的lwtid。使用操作系统命令top -Hp <gaussdb进程号>，查看相应lwtid(PID)的CPU使用率。
  ```

## chk-statement-history-cpu-time-vs-db-time · statement_history.cpu_time vs db_time
- layer: `db-system-view` · type: `metric`
- method:
  ```
  登录至各CN/DN节点查询相应时间段的statement_history 表。使用全局接口dbe_perf.get_global_full_sql_by_timestamp('开始时间','结束时间')。注意：需要切换至postgres库。
  ```

## chk-dbe-perf-statement-n-blocks-fetched-n-blocks-hit-io · dbe_perf.statement.n_blocks_fetched / n_blocks_hit (持续IO高)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  如果持续IO高，可查询dbe_perf.statement/dbe_perf.summary_statement内n_blocks_fetched/n_blocks_hit字段，通常导致IO读高的情况，两个字段的差值会比较高，两者差值表示物理读的次数。
  ```

## chk-pg-thread-wait-status-wait-status-wait-event-io · pg_thread_wait_status.wait_status / wait_event (当前IO高)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  如果当前IO高，可查询pg_thread_wait_status视图，查询wait_status/wait_event字段，通常Query两者状态为IO_EVENT/DataFileRead表示有物理读产生。
  ```

## chk-statement-history-data-io-time-sql-io · statement_history.data_io_time (慢SQL IO分析)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  查询statement_history表，慢SQL n_blocks_fetched/n_blocks_hit字段差值较高 记录，或者查询data_io_time较高 记录
  ```

## chk-dbe-perf-memory-node-detail-dynamic-used-memory-vs-max-dynam · dbe_perf.memory_node_detail.dynamic_used_memory vs max_dynamic_memory
- layer: `db-system-view` · type: `metric`
- method:
  ```
  查询dbe_perf.memory_node_detail视图，明确内存占用点。•max_dynamic_memory：最大可使用动态内存 •dynamic_used_memory：已使用动态内存
  ```

## chk-dbe-perf-session-memory-detail-dynamic-used-shrctx · dbe_perf.session_memory_detail (dynamic_used_shrctx较小时)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  dynamic_used_shrctx较小，查询dbe_perf.session_memory_detail可获取到不同Session的内存消耗，通常来讲：用户会话数和用户每个session上内存占用都会导致动态内存异常问题。
  ```

## chk-dbe-perf-shared-memory-detail-dynamic-used-shrctx · dbe_perf.shared_memory_detail (dynamic_used_shrctx较大时)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  dynamic_used_shrctx较大，查询dbe_perf.shared_memory_detail可获取到异常内存消耗的context，通常此处有过多的异常消耗，多数情况下为用户session上的内存异常消耗。
  ```

## chk-dbe-perf-local-active-session · dbe_perf.local_active_session (秒级抖动)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  对于短时间秒级性能抖动，分析相应时间点的dbe_perf.local_active_session，可排查点如下：•异常等待事件，当时SQL的异常等待事件，可参考整体性能慢-等待事件分析。•异常SQL，分析某些SQL出现的频率变化，以及执行速度，如多次采样均被采集到，即可反向分析到SQL执行时间。•异常连接数变化，比如业务突然连接增加。
  ```

## chk-gs-asp · gs_asp (两天内秒级抖动)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  对于两天内秒级性能抖动，分析相应时间点的gs_asp表
  ```

## chk-data-node-scan · 执行计划下推标识（Data Node Scan）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  将GUC参数enable_fast_query_shipping设置为off，使查询优化器使用分布式框架策略。查看执行计划。如果执行计划中有Data Node Scan节点，那么此执行计划是发送语句的分布式执行计划，为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。
  ```

## chk-pg-proc-provolatile-proshippable · pg_proc.provolatile / proshippable
- layer: `db-system-view` · type: `metric`
- method:
  ```
  函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE。另外，在pg_proc中的proshippable字段，取值范围为t/f/NULL，这个字段与provolatile字段一起用于描述函数是否下推。
  ```

## chk-pg-proc-provolatile · pg_proc.provolatile
- layer: `db-system-view` · type: `metric`
- method:
  ```
  函数易变性可以查询pg_proc的provolatile字段获得，i代表IMMUTABLE，s代表STABLE，v代表VOLATILE
  ```

## chk-explain-verbose-warning · explain verbose WARNING · 统计信息缺失提示
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, ...) are not collected. HINT:Do analyze for them in order to generate optimized plan.
  ```

## chk-explain-nest-loop-join · EXPLAIN 执行计划 · Nest Loop Join 耗时
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。
  ```

## chk-explain-verbose-warning · EXPLAIN VERBOSE WARNING · 未收集统计信息的表/列列表
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan.
  ```

## chk-pg-log-statistics-not-collected · pg_log 日志 · Statistics not collected 日志行
- layer: `log-grep` · type: `metric`
- method:
  ```
  可以通过在pg_log目录下的日志文件中查找以下信息来确认当前执行的query是否由于没有收集统计信息导致查询性能变差。
  ```

## chk-explain-join · EXPLAIN 执行计划 · Join 算子类型及耗时
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  分析该执行计划发现，扫描节点已使用Index Scan，耗时主要在最外层Nest Loop Join的Join Filter计算中，且该计算执行了字符串的加减法和不等值比较。
  ```

## chk-savepoint · 存储过程中 SAVEPOINT 的创建/释放配对
- layer: `db-shell` · type: `metric`
- method:
  ```
  在使用完SAVEPOINT后，应及时使用RELEASE SAVEPOINT来释放资源。
  ```

## chk-commit-rollback-i-o · COMMIT/ROLLBACK 频率与 I/O 开销
- layer: `db-shell` · type: `metric`
- method:
  ```
  事务的COMMIT和ROLLBACK操作需要同步数据库的元数据和日志，频繁执行可能增加I/O开销，从而影响性能。
  ```

## chk-b-tree-explain-analyze · 创建 B-tree 索引后再次 EXPLAIN ANALYZE
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  添加索引后，通过与无索引时执行计划的对比，查询时间从原来的382.624ms缩短到0.293 ms。
  ```

## chk-rds001-cpu-util · rds001_cpu_util
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  CPU使用率
  ```

## chk-rds002-mem-util · rds002_mem_util
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  内存使用率
  ```

## chk-io-bandwidth-usage · io_bandwidth_usage
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  磁盘io带宽占用率
  ```

## chk-iops-usage · iops_usage
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  IOPS使用率
  ```

## chk-rds007-instance-disk-usage · rds007_instance_disk_usage
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  实例数据磁盘已使用百分比
  ```

## chk-rds020-avg-disk-ms-per-write · rds020_avg_disk_ms_per_write
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  数据磁盘单次写入花费的时间
  ```

## chk-rds021-avg-disk-ms-per-read · rds021_avg_disk_ms_per_read
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  数据磁盘单次读取花费的时间
  ```

## chk-rds036-deadlocks · rds036_deadlocks
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  死锁次数
  ```

## chk-rds048-p80 · rds048_P80
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  80% SQL的响应时间
  ```

## chk-rds049-p95 · rds049_P95
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  95% SQL的响应时间
  ```

## chk-rds060-long-running-transaction-exectime · rds060_long_running_transaction_exectime
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  数据库最长事务的执行时长
  ```

## chk-rds063-slowquery-user · rds063_slowquery_user
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  用户库慢SQL数量
  ```

## chk-rds065-dynamic-used-memory-usage · rds065_dynamic_used_memory_usage
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  动态内存使用率
  ```

## chk-rds066-replication-slot-wal-log-size · rds066_replication_slot_wal_log_size
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  复制槽保留的WAL日志大小
  ```

## chk-rds070-thread-pool · rds070_thread_pool
- layer: `db-internal-counter` · type: `metric`
- method:
  ```
  线程池使用率
  ```

## chk-top-gsql-cpu · top · gsql 进程 CPU 占用
- layer: `os` · type: `metric`
- method:
  ```
  top 命令显示 gsql 进程占用率高
  ```

## chk-pg-stat-statements-total-time-calls · pg_stat_statements · total_time + calls (慢查询统计)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  - **abnormal_patterns**: ["total_time > 1000 AND calls > 10"]
  ```

## chk-explain-groupagg-sort · EXPLAIN · 算子(GroupAgg+Sort)
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  计划中包含GroupAgg+Sort算子
  ```

## chk-explain-analyze · EXPLAIN ANALYZE 顺序扫描耗时
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN
  ```

## chk-explain-seqscan-vs-indexscan · EXPLAIN · 算子(seqscan vs indexscan)
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  在优化前，没有创建places.place_id和states.state_id索引，执行计划如下
  ```

## chk-explain-join · EXPLAIN 执行计划 Join 类型
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN
  ```

## chk-pidstat-iotop-i-o · pidstat / iotop 显示线程 I/O 消耗
- layer: `os` · type: `metric`
- method:
  ```
  pidstat -dt -p gaussdb进程号
  ```

## chk-pg-thread-wait-status-pg-stat-activity-i-o-sql · pg_thread_wait_status + pg_stat_activity 中 I/O 高的 SQL
- layer: `db-system-view` · type: `metric`
- method:
  ```
  通过查询pg_thread_wait_status视图的lwtid为上一步内的TID，获取对应的tid和sessionid。
  ```

## chk-wdr-top-sql-order-by-cpu-time · WDR 报告 Top SQL order by CPU Time
- layer: `db-system-view` · type: `metric`
- method:
  ```
  可直接使用WDR报告中SQL ordered by CPU Time部分，尝试优化分析相关语句
  ```

## chk-null-003 · 内核代码热点函数火焰图
- layer: `flamegraph` · type: `metric`
- method:
  ```
  如果仍然无法分析出CPU消耗原因，可以生成异常时间段内的火焰图，找到内核代码函数的瓶颈点
  ```

## chk-guc-shared-buffers-work-mem-thread-pool-attr · GUC 参数 shared_buffers / work_mem / thread_pool_attr 当前值
- layer: `db-system-view` · type: `metric`
- method:
  ```
  常见的可能情况有：1. shared_buffers配置过小，导致buffer淘汰频繁。
  ```

## chk-session-package · SESSION 中 PACKAGE 变量数量与内存占用
- layer: `db-shell` · type: `metric`
- method:
  ```
  PACKAGE变量是在PACKAGE内定义的全局变量，其生命周期覆盖整个数据库会话（SESSION）。
  ```

## chk-explain-filter · EXPLAIN 执行计划 Filter 条件分析
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN
  ```

## chk-pg-proc-volatility · pg_proc 函数 volatility 类型查询
- layer: `db-system-view` · type: `metric`
- method:
  ```
  查询pg_proc
  ```

## chk-explain · EXPLAIN 执行计划算子估算行数
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN
  ```

## chk-explain-stream · EXPLAIN 执行计划 Stream 算子类型
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN
  ```

## chk-exception · 存储过程 EXCEPTION 块使用频率与上下文创建/销毁开销
- layer: `db-shell` · type: `metric`
- method:
  ```
  每次异常处理都涉及上下文的创建和销毁，这会消耗额外的内存和资源。
  ```

## chk-null-004 · 存储过程默认权限模式
- layer: `db-shell` · type: `metric`
- method:
  ```
  存储过程默认具有SECURITYINVOKER权限。
  ```

## chk-explain-remotequery-data-node-scan · EXPLAIN · 是否含 RemoteQuery / Data Node Scan
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  - **abnormal_patterns**: ["`Data Node Scan on t1 \"_REMOTE_TABLE_QUERY_\"`"]
  ```

## chk-explain-cn-vs-dn · EXPLAIN 执行计划算子位置（CN vs DN）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN
  ```

## chk-group-by-groupagg-sort · GROUP BY 查询计划中是否包含 GroupAgg+Sort
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  查询语句中如果存在GROUP BY条件则生成的计划（Plan）中可能存在排序操作，即计划中包含GroupAgg+Sort算子，导致性能较差。
  ```

## chk-explain · EXPLAIN · 计划与实际行数比对
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  导致执行计划选择不优
  ```

## chk-explain-data-node-scan-on · EXPLAIN 输出中 "Data Node Scan on" 是否在第一行
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通常而言explain语句后没有显示具体的执行计划算子，执行计划中关键字\"Data Node Scan on\"出现在第一行（不包含计划格式）则说明语句已下推给DN去执行。
  ```

## chk-explain-subplan · EXPLAIN 执行计划 SubPlan 存在
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN
  ```

## chk-dn-cpu · 备DN CPU使用率 · 回放线程资源
- layer: `os` · type: `metric`
- method:
  ```
  极致RTO采用了多个page redo线程并行加速回放进度。当备DN回放追平主DN，空载的情况下，单个page redo线程的CPU消耗大约在15%左右（实际值与具体硬件和参数配置相关），备DN回放的总CPU消耗值 = 单个page redo线程的CPU消耗值 x page redo线程数。
  ```

## chk-explain-verbose · EXPLAIN VERBOSE 统计信息警告
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过explain verbose执行query分析执行计划时会提示WARNING信息，如下所示：WARNING:Statistics in some tables or columns(public.lineitem.l_receiptdate, public.lineitem.l_commitdate, public.lineitem.l_orderkey, public.lineitem.l_suppkey, public.orders.o_orderstatus, public.orders.o_orderkey) are not collected. HINT:Do analyze for them in order to generate optimized plan.
  ```

## chk-pg-log · pg_log 统计信息缺失日志
- layer: `log-grep` · type: `metric`
- method:
  ```
  可以通过在pg_log目录下的日志文件中查找以下信息来确认是当前执行的query是否由于没有收集统计信息导致查询性能变差。
  ```

## chk-explain-analyze-stream · EXPLAIN ANALYZE · Stream算子类型
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  GaussDB计划中常见的主要Stream算子包括Redistribute、Broadcast和Gather。
  ```

## chk-explain-analyze-startup-vs-total · EXPLAIN ANALYZE · 路径代价 (Startup vs Total)
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  把explain_perf_mode设置为normal，查看原Nest Loop的启动代价
  ```

## chk-nestloop · 语句执行时间 / 执行计划中 NestLoop 算子
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  该问题发生在实时场景下，语句执行时间因为达到了 3600s而自动终止运行
  ```

## chk-pgxc-wlm-session-history-block-time-duration · pgxc_wlm_session_history · block_time / duration
- layer: `db-system-view` · type: `metric`
- method:
  ```
  pgxc_wlm_session_history
  ```

## chk-pgxc-wlm-session-history · pgxc_wlm_session_history · 同期并发作业数
- layer: `db-system-view` · type: `metric`
- method:
  ```
  pgxc_wlm_session_history
  ```

## chk-pgxc-wlm-session-history-min-dn-time-max-dn-time-average-dn- · pgxc_wlm_session_history · min_dn_time / max_dn_time / average_dn_time / dntime_skew_percent
- layer: `db-system-view` · type: `metric`
- method:
  ```
  pgxc_wlm_session_history
  ```

## chk-gs-wlm-instance-history-io-await-io-util-disk-read-disk-writ · GS_WLM_INSTANCE_HISTORY · io_await / io_util / disk_read / disk_write / process_read / process_write
- layer: `db-system-view` · type: `metric`
- method:
  ```
  GS_WLM_INSTANCE_HISTORY
  ```

## chk-explain-performance-sql-streaming-redistribute · EXPLAIN PERFORMANCE · SQL自诊断信息（Streaming REDISTRIBUTE 计算倾斜）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  SQL自诊断信息显示在做row_number()函数计算前的PARTITION BY T.ORDER_LINE_ID引入的重分布算子(Streaming(type: REDISTRIBUTE))有计算倾斜
  ```

## chk-order-line-id-null · 列统计信息 · ORDER_LINE_ID NULL 比例
- layer: `db-system-view` · type: `metric`
- method:
  ```
  查看对应T表的统计信息发现表fin_dwb_isc.dwb_isc_so_delivery_dtl_f的列ORDER_LINE_ID上87.6^%左右都是NULL值
  ```

## chk-pgxc-wlm-session-history-dataskew-warning · pgxc_wlm_session_history · DataSkew warning
- layer: `db-system-view` · type: `metric`
- method:
  ```
  GaussDB 在执行 SQL 语句时，会对其性能表现进行分析和记录，通过视图和函数等手段呈现给用户。执行完一条代价大于resource_track_cost后，诊断信息会存放在内存hash表中，可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。
  ```

## chk-pgxc-wlm-session-history-large-table-in-broadcast-warning · pgxc_wlm_session_history · Large Table in Broadcast warning
- layer: `db-system-view` · type: `metric`
- method:
  ```
  可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。
  ```

## chk-pgxc-wlm-session-history-spill · pgxc_wlm_session_history · Spill告警
- layer: `db-system-view` · type: `metric`
- method:
  ```
  可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。
  ```

## chk-pgxc-wlm-session-history-nestloop · pgxc_wlm_session_history · NestLoop大表告警
- layer: `db-system-view` · type: `metric`
- method:
  ```
  可通过pgxc_wlm_session_history或gs_wlm_session_history视图查看。
  ```

## chk-dn · 各DN磁盘利用率
- layer: `os` · type: `metric`
- method:
  ```
  gs_ssh -c "df -h
  ```

## chk-warning · 执行计划统计信息Warning
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过explain verbose/explain performance打印语句的执行计划
  ```

## chk-remote · 执行计划下推标识（__REMOTE关键字）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过explain verbose打印语句执行计划
  ```

## chk-nestloop · 执行计划算子类型（NestLoop）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  首先观察SQL语句中有not in 语法；执行计划中有NestLoop
  ```

## chk-partitioned-cstore-scan · 执行计划：Partitioned CStore Scan分区扫描范围
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  和客户收集几个典型的慢sql，分别打印执行计划。
  ```

## chk-vecnestloopruntime · 进程堆栈（VecNestLoopRuntime）
- layer: `os` · type: `metric`
- method:
  ```
  gstack 14104
  ```

## chk-max-process-memory-shared-buffers · 内存参数：max_process_memory, shared_buffers
- layer: `db-shell` · type: `metric`
- method:
  ```
  检查内存相关参数，设置不合理
  ```

## chk-in · 执行计划in条件处理方式
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  打印语句的执行计划
  ```

## chk-sql-case-when · SQL 中 CASE WHEN 分支数量与执行次数
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  在业务查询中，CASE WHEN语句常用来进行条件判断，但如果在SQL查询中存在大量冗余的CASE WHEN
  ```

## chk-null-008 · 系统表/用户表膨胀情况
- layer: `db-system-view` · type: `metric`
- method:
  ```
  用户可在管控面执行全库Vacuum/Vacuum Full，以定期进行空间回收
  ```

## chk-pgxc-stat-table-dirty · 表脏页率 (PGXC_STAT_TABLE_DIRTY)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  DWS提供了查询脏页率的系统视图，具体使用请参见PGXC_STAT_TABLE_DIRTY。
  ```

## chk-gds · GDS导入作业日志
- layer: `log-grep` · type: `metric`
- method:
  ```
  检测GDS导入作业的日志，查看是否有执行失败的现象。
  ```

## chk-fe-sync-be-parsecomplete · FE=>Sync 与 <=BE ParseComplete 日志时间间隔
- layer: `log-grep` · type: `metric`
- method:
  ```
  用户可查看FE=> Syncr日志和<=BE ParseComplete日志之间的时间间隔
  ```

## chk-be-datarow-select-count · <=BE DataRow 日志出现次数 / SELECT count(*) 结果集大小
- layer: `log-grep` · type: `metric`
- method:
  ```
  查看日志，如果<=BE DataRow日志出现次数过多，或直接执行SELECT count(*);
  ```

## chk-modifyjdbccall-createparameterizedquery · modifyJdbcCall / createParameterizedQuery 阶段耗时
- layer: `log-grep` · type: `metric`
- method:
  ```
  如果主要耗时在modifyJdbcCall阶段（校验传入的SQL是否符合规范）和createParameterizedQuery阶段（将传入的SQL解析为preparedQuery，以获取由simplequery组成的subqueries），则需要确认是否传入的SQL过长导致。
  ```

## chk-analyze · ANALYZE 后的查询性能
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  使用ANALYZE命令分析数据库。
  ```

## chk-null-009 · 查询返回行数
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  检查查询语句是否返回了多余的数据信息。
  ```

## chk-null-010 · 主机负载下查询单独运行时延
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  尝试在数据库没有其他查询或查询较少的时候运行查询语句，并观察运行效率。
  ```

## chk-null-011 · 重复执行同一查询语句的执行时间
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  重复执行相同的查询语句，如果后续执行的查询语句效率提升，则可能是由于上述原因导致。
  ```

## chk-disk-cache-pgxc-disk-cache-all-stats · Disk Cache 命中率与磁盘使用大小 (pgxc_disk_cache_all_stats)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  通过查询视图pgxc_disk_cache_all_stats可以查看当前缓存的命中率以及各个DN磁盘的使用大小情况
  ```

## chk-evs · EVS 磁盘空间占用百分比
- layer: `log-grep` · type: `metric`
- method:
  ```
  日志中会出现\"Disk usage on the node %u has reached the read-only threshold 90%\
  ```

## chk-bucket · 入库分区数 / Bucket 数 / 攒批内存消耗
- layer: `db-shell` · type: `metric`
- method:
  ```
  单并发攒批消耗： #Np * #Nb * #Nr 单并发攒批内存消耗： partition_max_cache_size， 默认2GB
  ```

## chk-explain-indexscan · EXPLAIN 执行计划 · 是否选择IndexScan
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  对表执行ANALYZE更新统计信息。
  ```

## chk-waiting-in-queue · 查询等待状态 · waiting in queue
- layer: `db-system-view` · type: `metric`
- method:
  ```
  普通用户主要在waiting in queue/waiting in global queue时。当前的活跃语句数超过max_active_statements限制导致的普通用户排队，由于管理员用户不受管控所以无需排队。
  ```

## chk-explain-or-filter · EXPLAIN 执行计划 · 系统视图权限OR filter
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过执行计划可以看到系统视图中的权限判断中多用or条件判断：pg_has_role(c.relowner, 'USAGE'::text) OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text)
  ```

## chk-cn · CN日志中不下推原因
- layer: `log-grep` · type: `metric`
- method:
  ```
  不下推语句在pg_log中会打印不下推的原因。LOG: SQL can't be shipped, reason: ...
  ```

## chk-explain-verbose-warning · EXPLAIN VERBOSE WARNING信息 · 统计信息缺失
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过EXPLAIN VERBOSE执行query分析执行计划时会提示WARNING信息
  ```

## chk-pgxc-wlm-session-info-duration-block-time-query-plan-sql-has · pgxc_wlm_session_info · duration / block_time / query_plan（按 sql_hash 比对历史）
- layer: `db-system-view` · type: `metric`
- method:
  ```
  SELECT start_time, block_time, duration, sql_hash, warning, max_peak_memory, max_spill_size, query_plan FROM pgxc_wlm_session_info were start_time > 'xxxx-xx-xx xx:xx' and sql_hash = 'xxx' ORDER BY start_time desc limit 10;
  ```

## chk-pgxc-stat-activity-state-waiting-enqueue · PGXC_STAT_ACTIVITY · state / waiting / enqueue
- layer: `db-system-view` · type: `metric`
- method:
  ```
  SELECT coorname, usename,client_addr,application_name,state,waiting,enqueue,pid FROM PGXC_STAT_ACTIVITY WHERE DATNAME='数据库名称';
  ```

## chk-pg-locks · pg_locks · 阻塞会话与持锁会话关联
- layer: `db-system-view` · type: `metric`
- method:
  ```
  - **abnormal_patterns**: ["`该查询返回会话ID、CN名称、用户信息、查询状态，以及导致阻塞的表、模式信息。`"]
  ```

## chk-dws-connector-connectiontimeout · DWS-Connector connectionTimeOut 默认值
- layer: `db-shell` · type: `metric`
- method:
  ```
  DWS-Connector默认超时时间connectionTimeOut为5min，可调大该值。
  ```

## chk-pg-stat-activity-pg-locks-sql-8-0-x · pg_stat_activity / pg_locks 阻塞SQL（8.0.x及之前版本）
- layer: `db-system-view` · type: `metric`
- method:
  ```
  - **abnormal_patterns**: ["NULL"]
  ```

## chk-null-012 · 写入方式
- layer: `db-shell` · type: `metric`
- method:
  ```
  如果通过单条INSERT INTO语句的方式单并发写数据入库，客户端很可能会出现瓶颈
  ```

## chk-null-013 · 各节点磁盘使用率均衡性
- layer: `db-system-view` · type: `metric`
- method:
  ```
  登录DWS控制台。在"集群列表"页面，找到需要查看监控的集群。在指定集群所在行的"操作"列，单击"监控面板"。选择"监控 > 节点监控 > 磁盘"，查看磁盘使用率。
  ```

## chk-explain-verbose-remote · EXPLAIN VERBOSE · __REMOTE 关键字
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过EXPLAIN VERBOSE打印语句执行计划。上述执行计划中出现__REMOTE关键字，表示当前的语句为不下推执行。
  ```

## chk-cn · CN日志 · 不下推原因
- layer: `log-grep` · type: `metric`
- method:
  ```
  不下推语句在pg_log中会打印不下推的原因，上述语句在CN的日志中会找到类似以下的日志。
  ```

## chk-nestloop · 执行计划算子类型（NestLoop出现）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过EXPLAIN VERBOSE打印语句执行计划，查看执行计划发现SQL语句中存在not in语句
  ```

## chk-explain-partitioned-cstore-scan-selected-partitions · EXPLAIN 执行计划 · Partitioned CStore Scan Selected Partitions 数量
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  收集几个典型的慢SQL语句，分别打印执行计划。从执行计划中可以看出来，两条SQL的耗时都集中在Partitioned CStore Scan on public.tb_motor_vehicle列存表的分区扫描上。
  ```

## chk-i-o-cpu · 系统资源 I/O / 内存 / CPU 使用情况
- layer: `os` · type: `metric`
- method:
  ```
  排查当前的I/O、内存、CPU使用情况，没有发现资源占用高的情况。
  ```

## chk-gstack-vecnestloopruntime · gstack · 进程堆栈中 VecNestLoopRuntime
- layer: `os` · type: `metric`
- method:
  ```
  联系运维人员登录到相应的实例节点上，打印等待状态为none的线程堆栈信息
  ```

## chk-cstore-scan · 执行计划算子：CStore Scan耗时占比
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过抓取问题SQL的执行信息，发现大部分的耗时都在\"CStore Scan\
  ```

## chk-cudesc-cu-row-count · cudesc表中CU的row_count分布
- layer: `db-system-view` · type: `metric`
- method:
  ```
  - **abnormal_patterns**: ["row_count << 60000"]
  ```

## chk-cu · 执行计划中CU扫描数量
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  查看偶发慢业务慢时的执行计划信息，慢在cstore scan，且扫描数据量不大但扫描CU个数较多
  ```

## chk-explain-cstore-scan-cusome-cunone · EXPLAIN 执行计划 · Cstore Scan CUSome / CUNone 计数
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  分析计划主要耗时在Cstore Scan。Cstore Scan的详细信息中，每个DN扫描出2w左右的数据，但是扫描了有数据的CU（CUSome）155079个，没有数据的CU（CUNone）156375个
  ```

## chk-explain-scan-vs · EXPLAIN 执行计划 · Scan 实际过滤行数 vs 符合行数
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  某业务SQL总执行时间2.519s，其中Scan占了2.516s，同时该表的扫描最终只扫描到0条符合条件数据，过滤了20480条数据
  ```

## chk-null-015 · 表脏页率
- layer: `db-system-view` · type: `metric`
- method:
  ```
  查看表脏页率为99%，VACUUM FULL后性能优化到100ms左右。
  ```

## chk-explain-scan-a-time-max-min-dn · EXPLAIN 执行计划 · Scan A-time max/min DN 耗时比
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  表Scan的A-time中，max time DN执行耗时6554ms，min time DN耗时0s，DN之间扫描差异超过10倍以上
  ```

## chk-table-distribution-dn · table_distribution 各DN数据行数
- layer: `db-system-view` · type: `metric`
- method:
  ```
  通过table_distribution发现所有数据倾斜到了dn_6009单个DN
  ```

## chk-explain-seq-scan-vs-index-scan · EXPLAIN 执行计划 · 扫描算子类型（Seq Scan vs Index Scan）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  Seq Scan扫描需要3767ms，因涉及从4096000条数据中获取8240条数据，符合索引扫描的场景（海量数据中寻找少量数据），在对过滤条件列增加索引后，计划依然是Seq Scan而没有走Index Scan。
  ```

## chk-explain-selected-partitions · EXPLAIN 执行计划 · Selected Partitions 数量
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  对该表设计为分区表后没有走分区剪枝（Selected Partitions数量多），Scan花了701785ms，I/O效率极低。
  ```

## chk-pv-total-memory-detail-process-used-memory-vs-max-process-me · pv_total_memory_detail · process_used_memory vs max_process_memory
- layer: `db-system-view` · type: `metric`
- method:
  ```
  pv_total_memory_detail
  ```

## chk-null-016 · 列存表文件大小监控
- layer: `db-system-view` · type: `metric`
- method:
  ```
  列存表数据按列存储，一列的每60000行存储为一个CU，同一列的CU连续存储在一个文件中，当该文件大于1GB时，切换到新文件中。CU文件数据不能更改只能追加写。
  ```

## chk-pgxc-get-table-skewness · PGXC_GET_TABLE_SKEWNESS 视图
- layer: `db-system-view` · type: `metric`
- method:
  ```
  分布差可以通过视图[PGXC_GET_TABLE_SKEWNESS]查看。
  ```

## chk-dms · DMS 监控 · 节点磁盘使用率
- layer: `db-system-view` · type: `metric`
- method:
  ```
  选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。
  ```

## chk-dms-max-min · DMS · 节点磁盘使用率排序 (max - min)
- layer: `db-system-view` · type: `metric`
- method:
  ```
  选择“监控 > 节点监控 > 磁盘”，单击“磁盘使用率”右侧的![](https://support.huaweicloud.com/trouble-dws/figure/zh-cn_image_0000001393399197.png)进行排序，可查看当前集群各个节点的磁盘使用率。
  ```

## chk-cpu-1-3-12-24 · 节点 CPU 使用率 (1/3/12/24 小时)
- layer: `os` · type: `metric`
- method:
  ```
  选择“监控 > 节点监控 > 概览”可查看当前集群各节点CPU使用率的具体情况，单击最右的监控按钮，查看最近1/3/12/24小时的CPU性能指标
  ```

## chk-cpu · 资源池 CPU 限额 / 配额配置
- layer: `db-system-view` · type: `metric`
- method:
  ```
  设置资源池CPU限额与配额。
  ```

## chk-explain-in-join · EXPLAIN · in 条件是否转为 join
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  打印语句的执行计划
  ```

## chk-explain · EXPLAIN · 执行计划顺序扫描阶段耗时
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN` 查看多表 JOIN 执行计划
  ```

## chk-base-pgsql-tmp-pgsql-tmp-queryid-pid · base/pgsql_tmp 目录下 pgsql_tmp$queryid_$pid 文件
- layer: `os` · type: `metric`
- method:
  ```
  下盘文件位于实例目录的base/pgsql_tmp路径下，下盘文件以 pgsql_tmp$queryid_$pid 命名
  ```

## chk-pgxc-thread-wait-status-wait-status-write-file · pgxc_thread_wait_status · wait_status='write file'
- layer: `db-system-view` · type: `metric`
- method:
  ```
  等待视图中，当出现write file时，表示发生了中间结果下盘
  ```

## chk-explain-performance-spill-written-disk-temp-file-num · EXPLAIN PERFORMANCE · spill / written disk / temp file num 关键字
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  performance中出现spill、written disk、temp file num等关键字时，说明对应的算子出现了下盘。
  ```

## chk-topsql-spill-info · TopSQL.spill_info
- layer: `db-system-view` · type: `metric`
- method:
  ```
  实时TopSQL语句或历史TopSQL语句中，spill_info字段中会包含下盘信息，如果该字段不为空，说明有DN实例出现了下盘。
  ```

## chk-explain-analyze-join · EXPLAIN ANALYZE · JOIN 算子类型及执行时间
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN ANALYZE` 查看两表 JOIN 的算子类型
  ```

## chk-explain-analyze-agg · EXPLAIN ANALYZE · Agg 算子类型及执行时间
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN ANALYZE` 查看聚合操作算子选择
  ```

## chk-explain-performance-vs-a-rows-vs-e-rows · EXPLAIN PERFORMANCE · 各算子行数估算 vs 实际行数（A-rows vs E-rows）
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN PERFORMANCE` 查看 TPC-DS Q24 部分语句执行计划
  ```

## chk-explain-data-node-scan · EXPLAIN · 是否含 Data Node Scan 节点
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  如果执行计划中有Data Node Scan节点，那么此执行计划为不可下推的执行计划；如果执行计划中有Streaming节点，那么计划是可以下推的。
  ```

## chk-explain-performance · EXPLAIN PERFORMANCE · 执行计划是否走向量化（列执行引擎）算子
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  EXPLAIN PERFORMANCE` 查看是否有 Vector 前缀算子
  ```

## chk-copy · COPY 语句等待视图 · 轻量级锁等待
- layer: `db-system-view` · type: `metric`
- method:
  ```
  根据这5个COPY语句对应的query_id查看等待视图情况
  ```

## chk-explain-performance-cpu-io · EXPLAIN PERFORMANCE · 算子瓶颈维度判别(CPU/IO/内存/网络)
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  通过执行态信息，我们可以分析出算子为单位的性能，也可以分析出算子内部各步骤的性能，进一步为诊断性能的瓶颈打下了基础。
  ```

## chk-vacuum-defer-cleanup-age · vacuum_defer_cleanup_age 参数值
- layer: `db-shell` · type: `metric`
- method:
  ```
  参数vacuum_defer_cleanup_age不是0，该参数在老版本默认为8000，表示最近8000个事务产生的脏数据不进行回收。
  ```

## chk-dn-warning · DN 间导入行数倾斜率(WARNING)
- layer: `log-grep` · type: `metric`
- method:
  ```
  WARNING:  Skewness occurs, table name: xxx, min value: xxx, max value: xxx, sum value: xxx, avg value: xxx, skew ratio: xxx
  ```

## chk-a-time-dn · 算子 A-time(在单 DN 上的运行耗时)
- layer: `db-interactive-cmd` · type: `metric`
- method:
  ```
  - **abnormal_patterns**: ["NULL"]
  ```

MANUAL_DOC_END

# ── 8 个 NULL/空 method (蒸馏没抽到抓法 · 仅记录) ─────────────
cat > "$OUTDIR/skip.md" <<'SKIP_DOC_END'
# Skip-empty method (蒸馏没抽到 collection_method · 共 8 项)

- `chk-pg-log-statistics-warning` · pg_log 日志中的 Statistics WARNING (layer=`log-grep`)
- `chk-hstore-delta-vs-cu` · HStore Delta表大小 vs 主表CU数据 (layer=`db-system-view`)
- `chk-vs` · 列存表物理大小 vs 有效数据量 (layer=`db-shell`)
- `chk-cn-pg-log-warning` · CN pg_log 日志中 Warning 信息 (layer=`log-grep`)
- `chk-max-process-memory-shared-buffers-work-mem` · max_process_memory / shared_buffers / work_mem 内存参数 (layer=`db-system-view`)
- `chk-vs` · 脏数据膨胀率 / 表实际大小 vs 有效数据量 (layer=`db-system-view`)
- `chk-explain` · EXPLAIN执行计划耗时分布 (layer=`db-interactive-cmd`)
- `chk-abort-transaction-due-to-concurrent-update` · 数据库错误日志 · abort transaction due to concurrent update (layer=`log-grep`)
SKIP_DOC_END

echo ""
echo "─────────────────────────────────────────────"
echo "完成 · TOTAL=341 · auto=180 · manual=153 · skip=8"
echo "  报告:        $OUTDIR/report.tsv"
echo "  stdout 目录: $OUTDIR/stdout/"
echo "  stderr 目录: $OUTDIR/stderr/"
echo "  人审 (153): $OUTDIR/manual.md"
echo "  空 method (8): $OUTDIR/skip.md"
