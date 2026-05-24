#!/usr/bin/env node
// 从 checklist.ndjson 编译出"自包含"采集脚本 collect-precompiled.{sh,py}.
// 跟 collect.{sh,py} 的区别:那俩"现场解析" ndjson · 这俩"预编译" 命令直接 inline.
//
// 部署到 db 服务器后:不需要 jq / python3 解析 ndjson / 现场 heuristic.
//
// 用法 (本地一次性跑):
//   node _build-precompiled.mjs
// 改 checklist.ndjson 后重跑即可重新生成 .sh / .py.

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const NDJSON = join(HERE, 'checklist.ndjson');
const OUT_SH = join(HERE, 'collect-precompiled.sh');
const OUT_PY = join(HERE, 'collect-precompiled.py');
const OUT_AUDIT = join(HERE, 'manual-audit.md');

const DESC_KEYWORDS = [
  '查看', '判断是否', '如果发现', '通常', '示例为', '排查', '建议', '观察', '尝试',
  '可参考', '例如', '可借助', '需要联系', '以下', '应该', '可在', '可以查',
  '可执行', '建议保留', '建议设置', '日志中', '日志中会', '建议保持', '请联系',
];
// 规则代号 + 一句说明 · 写到 manual-audit.md 给人审看
const RULE_DESC = {
  'r0-null':            'method 为 NULL / 空 · 蒸馏没抽到抓法',
  'r1-cjk-ge-4':        '含 ≥4 个汉字 · 描述性中文 · 不是命令',
  'r2-desc-kw':         '含描述关键词 (查看 / 判断 / 通常 / 建议 / 排查 ...)',
  'r3-distill-leak':    'distill 字段残留 (- **field**: ...) · 不是命令',
  'r4-cjk-only':        '纯中文 metric 名 · ASCII alphanumeric 太少',
  'r5-single-ident':    '单 token 视图 / 表名 · 没 SELECT FROM · 不能直跑',
  'r6-cjk-placeholder': '含占位符 (进程号 / 实例号 / xxx / <var>) · 需人填值',
  'r7-log-kw-start':    '日志关键词开头 (WARNING / ERROR ...) · 是 log 内容片段',
  'r8-cjk-verb-start':  '起始中文动词 (查询 / 查看 / 检测 ...) · 非 ready-to-run',
  'r9-pid-literal':     '含真 PID/OID 数字占位 · 需替换实际 PID 才能跑',
  'r10-cluster-tool':   'GaussDB 集群工具 (gs_ssh / gs_om / cm_ctl ...) · 需集群拓扑',
};
function matchedRule(m) {
  if (!m || m.toLowerCase() === 'null') return 'r0-null';
  const hans = (m.match(/[一-鿿]/g) || []).length;
  const ascii = (m.match(/[a-zA-Z0-9]/g) || []).length;

  if (hans >= 4) return 'r1-cjk-ge-4';
  const hitKw = DESC_KEYWORDS.find(kw => m.includes(kw));
  if (hitKw) return `r2-desc-kw:${hitKw}`;
  if (/^\s*-\s+\*\*[a-z_]+\*\*\s*:/i.test(m)) return 'r3-distill-leak';
  if (hans >= 1 && ascii < 5) return 'r4-cjk-only';
  if (/^[a-z_][a-z0-9_.]+$/i.test(m) && m.length > 6 && !/^(top|sar|free|vmstat|iostat|netstat|pidstat|gstack|gsql|perf|jstack|jmap|strace|tcpdump|dmesg)$/i.test(m)) return 'r5-single-ident';
  if (/进程号|实例号|查询.{0,2}号|<\w+>|\bxxx\b|\bXXX\b/.test(m)) return 'r6-cjk-placeholder';
  if (/^(WARNING|ERROR|FATAL|PANIC|NOTICE|HINT)[:\s]/.test(m)) return 'r7-log-kw-start';
  if (/^(查询|查看|检测|分析|定位|确认|计算|获取|读取|检查|执行)/.test(m)) return 'r8-cjk-verb-start';
  if (/^(gstack|strace|jstack|jmap|pstack|pmap)\s+\d{4,}/.test(m)) return 'r9-pid-literal';
  if (/^(gs_ssh|gs_om|cm_ctl|gs_check|gs_collector|gs_dump)\b/.test(m)) return 'r10-cluster-tool';

  return null;
}
function isManual(m) { return matchedRule(m) !== null; }

// 已知 GaussDB GUC 参数白名单 (做 SHOW 用)
const KNOWN_GUCS = [
  'work_mem','shared_buffers','maintenance_work_mem','effective_cache_size',
  'max_connections','max_process_memory','log_min_duration_statement','log_temp_files',
  'log_lock_waits','autovacuum','autovacuum_naptime','autovacuum_vacuum_scale_factor',
  'wal_level','max_wal_senders','wal_keep_segments','checkpoint_timeout',
  'checkpoint_completion_target','random_page_cost','seq_page_cost','cpu_tuple_cost',
  'effective_io_concurrency','deadlock_timeout','statement_timeout','lock_timeout',
  'idle_in_transaction_session_timeout','track_activities','track_counts','track_io_timing',
  'update_process_title','query_dop','sql_use_spacelimit','temp_file_limit','cstore_buffers',
  'temp_buffers','enable_fast_query_shipping','enable_stream_operator','enable_seqscan',
  'enable_indexscan','enable_indexonlyscan','enable_bitmapscan','enable_hashjoin',
  'enable_mergejoin','enable_nestloop','enable_material','enable_sort','enable_hashagg',
  'enable_stream_recursive','enable_dynamic_workload','enable_partition_iterator_elimination',
  'enable_pbe_optimization','plan_cache_mode','default_statistics_target',
  'enable_global_stats','min_dynamic_func_mgr','max_dynamic_memory','memorypool_size',
  'cstore_buffers','udf_memory_limit','enable_thread_pool','thread_pool_attr',
  'comm_max_stream','comm_quota_size','wait_dummy_time','vacuum_cost_limit',
];
const KNOWN_VIEWS_SINGLE = [
  'pg_stat_activity','pg_thread_wait_status','pg_proc','pg_settings','pg_class','pg_locks',
  'pg_stat_user_tables','pg_stat_user_indexes','pg_stat_database','pg_stat_replication',
  'pg_stat_bgwriter','pg_stat_xact_user_tables','pg_indexes','pg_index','pg_attribute',
  'pg_namespace','pg_database','pg_tables','pg_views','pg_stat_get_activity',
  'pg_replication_slots','pg_stat_replication_slots',
  'statement_history','gs_asp','gs_session_memory_context','gs_thread_memory_context',
  'gs_total_memory_detail','gs_view_invalid','gs_index_invalid','gs_table_skewness',
  'gs_total_nodegroup_memory_detail','gs_session_stat_activity','gs_sql_count',
  'gs_workload_sql_count','gs_session_cpu_statistics','gs_wlm_session_history',
  'gs_wlm_session_statistics','gs_stat_session_cu','gs_stat_session_file',
  'gs_wlm_instance_history','GS_WLM_INSTANCE_HISTORY',
  'pgxc_wlm_session_history','pgxc_stat_table_dirty','pgxc_disk_cache_all_stats',
  'pgxc_get_table_skewness','pgxc_total_memory_detail','pgxc_node',
  'pgxc_wlm_session_info','pgxc_thread_wait_status','pgxc_stat_activity',
  'PGXC_WLM_SESSION_HISTORY','PGXC_STAT_TABLE_DIRTY','PGXC_DISK_CACHE_ALL_STATS',
  'PGXC_WLM_SESSION_INFO','PGXC_THREAD_WAIT_STATUS','PGXC_STAT_ACTIVITY',
  'table_distribution',
];
const KNOWN_VIEWS_DOTTED_PREFIX = [
  'dbe_perf','pg_catalog','pg_stat','pg_internal','gs_',
];

// RDS 云监控 metric id 前缀 → 标准采集命令 (华为云 GaussDB RDS 监控对照表)
// 注: id 可能没匹配上特定列表,会落到 RDS_NAME_KEYWORDS 通用兜底
const RDS_METRIC_MAP = {
  'cpu_util':                       ['os', 'top -b -n 1 | head -20', 'CPU 使用率'],
  'mem_util':                       ['sql', 'SHOW max_dynamic_memory; SELECT * FROM dbe_perf.memory_node_detail;', '内存使用率 (GUC + 动态内存视图)'],
  'mem_usage':                      ['sql', 'SELECT * FROM dbe_perf.memory_node_detail;', '内存详情视图'],
  'dynamic_used_memory_usage':      ['sql', 'SELECT * FROM dbe_perf.memory_node_detail;', '动态已用内存'],
  'instance_disk_usage':            ['os', 'df -h $PGDATA $GAUSSDATA 2>/dev/null', '实例磁盘使用率'],
  'instance_data_disk_size':        ['os', 'df -h $PGDATA $GAUSSDATA 2>/dev/null', '实例数据盘大小'],
  'io_bandwidth_usage':             ['os', 'iostat -x 1 1', 'IO 带宽'],
  'iops_usage':                     ['os', 'iostat -x 1 1', 'IOPS'],
  'avg_disk_ms_per_write':          ['os', 'iostat -x 1 1', '平均写延迟'],
  'avg_disk_ms_per_read':           ['os', 'iostat -x 1 1', '平均读延迟'],
  'deadlocks':                      ['sql', 'SELECT datname, deadlocks FROM pg_stat_database ORDER BY deadlocks DESC LIMIT 10;', '死锁数'],
  'long_running_transaction':       ['sql', "SELECT pid, usename, state, xact_start, query FROM pg_stat_activity WHERE state='active' AND xact_start < now() - interval '5 min' ORDER BY xact_start;", '长事务'],
  'replication_slot_wal_log_size':  ['sql', 'SELECT slot_name, restart_lsn, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS lag FROM pg_replication_slots;', '复制槽 WAL 滞后'],
  'slowquery_user':                 ['sql', 'SHOW log_min_duration_statement; SELECT user_name, count(*) FROM statement_history WHERE duration > 1000 GROUP BY user_name ORDER BY count DESC LIMIT 20;', '慢查询用户分布'],
  'p80':                            ['sql', "SELECT percentile_cont(0.8) WITHIN GROUP (ORDER BY duration) AS p80 FROM statement_history WHERE start_time > now() - interval '5 min';", 'P80 响应时间'],
  'p95':                            ['sql', "SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY duration) AS p95 FROM statement_history WHERE start_time > now() - interval '5 min';", 'P95 响应时间'],
  'p99':                            ['sql', "SELECT percentile_cont(0.99) WITHIN GROUP (ORDER BY duration) AS p99 FROM statement_history WHERE start_time > now() - interval '5 min';", 'P99 响应时间'],
};
// 中文 → SQL/OS 命令兜底 (蒸馏出来全是中文指标名时用)
const CJK_KEYWORDS_MAP = [
  // [中文关键词, kind, command, note]
  [/CPU.{0,3}使用率|CPU.{0,3}利用率/, 'os', 'top -b -n 1 | head -20', 'CPU 使用率'],
  [/内存.{0,3}使用率|内存.{0,3}利用率|内存占用/, 'sql', 'SELECT * FROM dbe_perf.memory_node_detail;', '内存使用'],
  [/动态内存|max_dynamic_memory/, 'sql', 'SHOW max_dynamic_memory; SELECT * FROM dbe_perf.memory_node_detail;', '动态内存'],
  [/磁盘.{0,4}使用率|磁盘.{0,4}空间|disk.{0,3}usage/i, 'os', 'df -h $PGDATA $GAUSSDATA 2>/dev/null', '磁盘'],
  [/IOPS|每秒.{0,3}IO|IO.{0,3}吞吐/, 'os', 'iostat -x 1 1', 'IOPS'],
  [/复制槽|replication.{0,3}slot/i, 'sql', 'SELECT * FROM pg_replication_slots;', '复制槽'],
  [/WAL.{0,3}日志|wal.{0,3}log/i, 'sql', "SELECT pg_current_wal_lsn(), pg_size_pretty(sum(size)) FROM pg_ls_waldir() GROUP BY ();", 'WAL 日志'],
  [/死锁/, 'sql', 'SELECT datname, deadlocks FROM pg_stat_database ORDER BY deadlocks DESC LIMIT 10;', '死锁'],
  [/长事务|long.{0,3}running.{0,3}trans/i, 'sql', "SELECT pid, usename, state, xact_start, query FROM pg_stat_activity WHERE state='active' AND xact_start < now() - interval '5 min';", '长事务'],
  [/连接数/, 'sql', 'SELECT count(*) FROM pg_stat_activity; SHOW max_connections;', '连接数'],
  [/活跃会话/, 'sql', "SELECT count(*) FROM pg_stat_activity WHERE state='active';", '活跃会话数'],
  [/会话数/, 'sql', 'SELECT state, count(*) FROM pg_stat_activity GROUP BY state;', '会话状态分布'],
  [/buffer.{0,3}命中率|缓冲.{0,3}命中率/i, 'sql', 'SELECT datname, blks_hit::numeric/NULLIF(blks_hit+blks_read,0) AS hit_ratio FROM pg_stat_database WHERE blks_hit+blks_read > 0 ORDER BY hit_ratio LIMIT 10;', 'buffer 命中率'],
  [/慢SQL|慢查询|slow.{0,3}query/i, 'sql', "SHOW log_min_duration_statement; SELECT * FROM statement_history WHERE duration > 1000 ORDER BY duration DESC LIMIT 20;", '慢查询'],
  [/事务.{0,3}提交|commit.{0,3}rate/i, 'sql', 'SELECT datname, xact_commit, xact_rollback FROM pg_stat_database;', '事务提交/回滚'],
  [/索引.{0,3}使用率|index.{0,3}usage/i, 'sql', 'SELECT relname, idx_scan, seq_scan FROM pg_stat_user_tables ORDER BY seq_scan DESC LIMIT 20;', '索引使用'],
  [/锁.{0,3}等待|lock.{0,3}wait/i, 'sql', 'SELECT * FROM pg_locks WHERE NOT granted;', '锁等待'],
  [/checkpoint|检查点/i, 'sql', 'SELECT * FROM pg_stat_bgwriter; SHOW checkpoint_timeout;', 'checkpoint'],
  [/统计信息|statistics/i, 'sql', 'ANALYZE <schema.table>;  -- 把 <schema.table> 换成实际表', '收集统计信息'],
  [/SAVEPOINT|保存点/i, 'os', "grep -E 'SAVEPOINT|RELEASE' $GAUSSLOG/pg_log/*.log | tail -50", '保存点 (走 pg_log grep)'],
  [/火焰图|flamegraph/i, 'os', 'ls -la $GAUSSLOG/gs_flamegraph/', 'GaussDB 内置火焰图'],
  [/perf.{0,3}top|cpu.{0,3}火焰图/i, 'os', "perf top -p $(pgrep -f gaussdb | head -1) || gstack $(pgrep -f gaussdb | head -1)", 'perf top / gstack'],
  [/线程池/i, 'sql', 'SHOW enable_thread_pool; SHOW thread_pool_attr;', '线程池配置'],
  [/VACUUM|空间.{0,3}回收|表.{0,3}膨胀|脏页/i, 'sql', 'VACUUM (VERBOSE, ANALYZE) <schema.table>;  -- 把 <schema.table> 换成实际表名', 'VACUUM (谨慎: 影响业务)'],
  [/COMMIT.{0,3}ROLLBACK|事务.{0,3}COMMIT|事务.{0,3}回滚/i, 'sql', 'SELECT datname, xact_commit, xact_rollback FROM pg_stat_database;', 'COMMIT/ROLLBACK 频率'],
  [/pidstat|iotop/i, 'os', 'pidstat -dt -p $(pgrep -f gaussdb | head -1) 1 1', '进程 IO (按 PID)'],
  [/top\s*命令|gsql.{0,3}进程|gaussdb.{0,3}进程/i, 'os', "top -b -n 1 -p $(pgrep -f gaussdb | head -1) -H", 'gaussdb 进程线程级 top'],
  [/WDR|wdr.{0,3}报告|workload.{0,3}diagnosis/i, 'sql', "SELECT generate_wdr_report(<begin_snap_id>, <end_snap_id>, 1, 'all', 'all');", 'WDR 报告生成 (需 snap id)'],
  [/活跃.{0,3}session|active.{0,3}session/i, 'sql', "SELECT * FROM dbe_perf.local_active_session ORDER BY sample_time DESC LIMIT 50;", 'active session'],
  [/SQL.{0,3}IO|SQL.{0,3}的.{0,3}IO/, 'sql', 'SELECT query_id, n_blocks_fetched, n_blocks_hit, data_io_time FROM statement_history WHERE data_io_time > 0 ORDER BY data_io_time DESC LIMIT 20;', 'SQL 级 IO'],
  [/会话.{0,3}内存|session.{0,3}memory/i, 'sql', 'SELECT * FROM dbe_perf.session_memory_detail ORDER BY total_size DESC LIMIT 20;', 'session 级内存'],
  [/共享.{0,3}内存|shared.{0,3}memory/i, 'sql', 'SELECT * FROM dbe_perf.shared_memory_detail ORDER BY total_size DESC LIMIT 20;', '共享内存'],
  [/异常.{0,3}等待|等待事件/i, 'sql', 'SELECT wait_status, wait_event, count(*) FROM pg_thread_wait_status GROUP BY 1,2 ORDER BY 3 DESC;', '等待事件聚合'],
  [/GDS|gds.{0,3}导入/i, 'os', "find $GAUSSLOG -name 'gds_*.log' -mtime -1 | xargs grep -E 'ERROR|FAIL'", 'GDS 导入日志'],
  [/SAVEPOINT|存储过程.{0,3}EXCEPTION/i, 'os', "grep -E 'SAVEPOINT|RELEASE|EXCEPTION' $GAUSSLOG/pg_log/*.log | tail -100", 'SAVEPOINT / EXCEPTION 日志'],
  [/FE=>Sync|BE.{0,3}ParseComplete|JDBC.{0,3}日志/i, 'os', "grep -E 'FE=>|<=BE' $GAUSSLOG/pg_log/*.log | tail -200", '协议交互日志 (FE/BE)'],
  [/统计信息.{0,3}缺失|未收集.{0,3}统计/i, 'sql', "SELECT relname, n_live_tup, last_analyze, last_autoanalyze FROM pg_stat_user_tables WHERE last_analyze IS NULL ORDER BY n_live_tup DESC LIMIT 20;", '统计信息缺失检测'],
  [/EXCEPTION.{0,3}块|异常.{0,3}处理/i, 'os', "grep -E 'EXCEPTION|SQLERRM' $GAUSSLOG/pg_log/*.log | tail -50", 'EXCEPTION 块日志'],
  [/NestLoop|嵌套循环/i, 'sql-stub', 'EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 Nested Loop 算子', '嵌套循环排查'],
  [/HashAgg|hash.{0,3}agg|GroupAgg/i, 'sql-stub', 'EXPLAIN ANALYZE <你的 SQL>;  -- 看是否含 HashAgg / GroupAgg 算子', 'Agg 算子'],
  [/CStore.{0,3}Scan|列存.{0,3}扫描/i, 'sql', "SELECT relname, relkind FROM pg_class WHERE relkind='r' AND oid IN (SELECT relid FROM pg_stat_user_tables);  -- 列存表清单需结合 reloptions", '列存扫描算子'],
  [/Bucket|bucket数|分区数/i, 'sql', "SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 20;", '分区/bucket'],
  [/CU.{0,3}row_count|CU扫描|cudesc/i, 'sql', "SELECT * FROM pg_class WHERE relname LIKE 'cudesc_%' LIMIT 20;", 'CU 描述表'],
  [/table_distribution|各DN.{0,3}数据/i, 'sql', "SELECT * FROM table_distribution('<schema>', '<table>');  -- 替换 schema/table", '表分布'],
  [/列存表.{0,3}文件|列存.{0,3}大小/i, 'os', "find $PGDATA -name 'cu_*' -size +100M 2>/dev/null | head -20", '列存文件大小'],
  [/资源池|workload.{0,3}group|cgroup/i, 'sql', "SELECT * FROM pg_settings WHERE name LIKE 'cgroup%' OR name LIKE 'workload%';", '资源池配置'],
  [/spill|spill_info|落盘/i, 'sql', "SELECT * FROM gs_wlm_session_history WHERE warning LIKE '%spill%' ORDER BY start_time DESC LIMIT 20;", '算子落盘'],
  [/倾斜|skew/i, 'sql', "SELECT * FROM gs_table_skewness LIMIT 50;", '数据倾斜'],
  [/写入方式|insert.{0,3}方式|COPY|批量插入/i, 'sql', "SELECT n_tup_ins, n_tup_upd, n_tup_del, last_vacuum FROM pg_stat_user_tables ORDER BY n_tup_ins DESC LIMIT 20;", '写入操作分布'],
  [/A-time|算子.{0,3}耗时|operator.{0,3}time/i, 'sql-stub', 'EXPLAIN ANALYZE <你的 SQL>;  -- 看每个算子 A-time 列', '算子耗时'],
  [/CASE\s+WHEN/i, 'sql-stub', 'EXPLAIN <你的含 CASE WHEN 的 SQL>;', 'CASE WHEN 执行计划'],
  [/DataRow|协议日志|Sync.*BE/i, 'os', "grep -E '<=BE DataRow|FE=>Sync' $GAUSSLOG/pg_log/*.log | tail -100", 'JDBC 协议日志'],
  [/modifyJdbc|createParameterized/, 'os', "find $GAUSSLOG -name 'pg_log' -type d | head -1 | xargs -I{} grep -E 'modifyJdbc|createParameterized' {}/*.log 2>/dev/null | tail -50", 'JDBC 阶段耗时'],
  [/connectionTimeOut|连接超时/i, 'sql', "SHOW connect_timeout; SELECT setting FROM pg_settings WHERE name LIKE '%timeout%';", '连接超时'],
  [/查询.{0,3}等待|等待.{0,3}queue|waiting.{0,3}in.{0,3}queue/i, 'sql', "SELECT * FROM pg_stat_activity WHERE state='active' AND waiting=true;", '查询等待 queue'],
  [/查询返回.{0,3}行数|结果集大小/i, 'sql', "SELECT query_id, n_tuples_returned FROM statement_history ORDER BY n_tuples_returned DESC NULLS LAST LIMIT 20;", '返回行数'],
  [/pgsql_tmp|临时文件|temp.{0,3}file/i, 'os', "find $PGDATA -name 'pgsql_tmp*' -mmin -60 -ls 2>/dev/null | head -20", '临时文件'],
  [/in.{0,3}条件|IN列表/i, 'sql-stub', 'EXPLAIN <含 IN 子句的 SQL>;', 'IN 条件处理'],
  [/默认权限|SECURITY.{0,3}INVOKER|SECURITY.{0,3}DEFINER/i, 'sql', "SELECT proname, prosecdef FROM pg_proc WHERE prosecdef=true LIMIT 50;", '存储过程权限模式'],
  [/ANALYZE.{0,3}命令|使用ANALYZE/i, 'sql-stub', 'ANALYZE <schema.table>;  -- 或 ANALYZE; 收集全库统计', 'ANALYZE 命令'],
  [/排查.*[IO内存CPU]|资源.{0,3}占用|系统.{0,3}资源/i, 'os', "echo '=== top ===' && top -b -n 1 | head -20 && echo '=== iostat ===' && iostat -x 1 1 && echo '=== free ===' && free -h", 'I/O + 内存 + CPU 一把抓'],
  [/^gs_ssh.{0,5}df/, 'os', 'df -h $PGDATA $GAUSSDATA 2>/dev/null', '集群命令本机化 (df -h 走本地)'],
];

// 启发式: 从描述里挖出 0..N 个可派生命令 · 给人审作参考起点
function deriveCommands(method, type, name) {
  const m = method || '';
  const nameLower = (name || '').toLowerCase();
  const out = [];
  const seen = new Set();
  const add = (kind, sql, note) => {
    const k = `${kind}:${sql}`;
    if (seen.has(k)) return;
    seen.add(k);
    out.push({ kind, sql, note: note || '' });
  };

  // 1. 视图/表 — dotted (dbe_perf.X.Y / pg_stat.X 等)
  for (const re of [/\b(dbe_perf|pg_stat|pg_catalog|pg_internal)\.[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)?/g]) {
    let mm;
    while ((mm = re.exec(m))) {
      const full = mm[0].replace(/\.+$/, '');
      const parts = full.split('.');
      const tbl = parts.length >= 2 ? `${parts[0]}.${parts[1]}` : full;
      add('view', `SELECT * FROM ${tbl} LIMIT 50;`, parts.length >= 3 ? `提到字段 ${parts[2]} · 查表样本` : '');
      if (parts.length >= 3) {
        add('view', `SELECT ${parts[2]} FROM ${tbl} ORDER BY ${parts[2]} DESC LIMIT 20;`, `按 ${parts[2]} 降序取头 20`);
      }
    }
  }

  // 2. 单表名 (已知 GaussDB 表/视图)
  for (const v of KNOWN_VIEWS_SINGLE) {
    const re = new RegExp(`\\b${v}\\b`, 'g');
    if (re.test(m)) {
      add('view', `SELECT * FROM ${v} LIMIT 50;`, '');
    }
  }

  // 3. dotted 不在显式 prefix 列表但形如 gs_xxx.yyy
  for (const re of [/\bgs_[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*/g]) {
    let mm;
    while ((mm = re.exec(m))) {
      const full = mm[0].replace(/\.+$/, '');
      add('view', `SELECT * FROM ${full} LIMIT 50;`, '');
    }
  }

  // 4. GUC 参数
  for (const g of KNOWN_GUCS) {
    const re = new RegExp(`\\b${g}\\b`);
    if (re.test(m)) {
      add('guc', `SHOW ${g};`, '');
    }
  }
  // enable_xxx 类通配 (没在白名单里的)
  for (const re of [/\benable_[a-z_]+\b/g]) {
    let mm;
    while ((mm = re.exec(m))) {
      if (!KNOWN_GUCS.includes(mm[0])) {
        add('guc', `SHOW ${mm[0]};`, '通配 enable_* GUC');
      }
    }
  }

  // 5. OS 命令直接引用
  for (const re of [/\btop\s+-Hp\b[^\s,。;]*/g, /\btop\s+-b\s+-n\s+\d+/g,
                     /\bsar\s+-[a-z]\s+\d+\s+\d+/g, /\bvmstat\s+\d+\s+\d+/g,
                     /\biostat\b[^\s,。;]*/g, /\bnetstat\b[^\s,。;]*/g,
                     /\bfree\s+-[a-z]+\b/g, /\bperf\s+(top|record|stat)\b[^\s,。;]*/g,
                     /\bgstack\s+\d+/g, /\bjstack\s+\d+/g]) {
    let mm;
    while ((mm = re.exec(m))) {
      add('os', mm[0], '');
    }
  }

  // 6. EXPLAIN / ANALYZE 类
  if (/\bexplain\s+verbose\b/i.test(m)) {
    add('sql-stub', 'EXPLAIN VERBOSE <你的 SQL>;', '把 <你的 SQL> 换成实际慢 SQL');
  } else if (/\bexplain\s+analyze\b/i.test(m)) {
    add('sql-stub', 'EXPLAIN ANALYZE <你的 SQL>;', '把 <你的 SQL> 换成实际慢 SQL');
  } else if (/\bexplain\b/i.test(m) && type === 'metric') {
    add('sql-stub', 'EXPLAIN <你的 SQL>;', '把 <你的 SQL> 换成实际 SQL');
  }

  // 7. ANALYZE 表收集统计信息
  if (/\bANALYZE\b/.test(m) && /统计信息|statistics/i.test(m)) {
    add('sql-stub', 'ANALYZE <schema.table>;', '把 <schema.table> 换成实际表名');
  }

  // 8. pg_log 日志 grep
  if (/pg_log/.test(m)) {
    add('os', "find $GAUSSLOG/pg_log -name '*.log' -mtime -1 | xargs grep -E '<keyword>'",
        '把 <keyword> 换成实际想抓的字符串');
  }

  // 9. RDS 云监控 metric · 用 metric name (而不是 method) 匹配
  for (const [suffix, [kind, cmd, note]] of Object.entries(RDS_METRIC_MAP)) {
    if (nameLower.includes(suffix)) {
      const k = (kind === 'sql' || kind === 'os') ? kind : kind;
      add(k, cmd, `RDS metric: ${note}`);
    }
  }

  // 10. 中文兜底 — 蒸馏出来全是中文指标名时,按描述关键词派生
  for (const [pat, kind, cmd, note] of CJK_KEYWORDS_MAP) {
    if (pat.test(m) || pat.test(name || '')) {
      add(kind, cmd, `按"${note}"派生`);
    }
  }

  // 11. name 兜底 — name 里出现 EXPLAIN / ANALYZE / GUC 参数名 / 视图名 但 method 是纯描述
  const n = name || '';
  if (out.length === 0) {
    if (/EXPLAIN\s+ANALYZE/i.test(n)) {
      add('sql-stub', 'EXPLAIN ANALYZE <你的 SQL>;', '从 name 提取 · 需填实际 SQL');
    } else if (/EXPLAIN\s+VERBOSE/i.test(n)) {
      add('sql-stub', 'EXPLAIN VERBOSE <你的 SQL>;', '从 name 提取 · 需填实际 SQL');
    } else if (/\bEXPLAIN\b/i.test(n)) {
      add('sql-stub', 'EXPLAIN <你的 SQL>;', '从 name 提取 · 需填实际 SQL');
    }
  }
  // name 视图名兜底 (大写/小写都试)
  for (const v of KNOWN_VIEWS_SINGLE) {
    const re = new RegExp(`\\b${v}\\b`, 'i');
    if (re.test(n)) {
      add('view', `SELECT * FROM ${v.toLowerCase()} LIMIT 50;`, `从 name 提取视图 ${v}`);
    }
  }
  // name GUC 兜底 (max_process_memory / shared_buffers 等组合 name)
  for (const g of KNOWN_GUCS) {
    const re = new RegExp(`\\b${g}\\b`, 'i');
    if (re.test(n)) add('guc', `SHOW ${g};`, `从 name 提取 GUC ${g}`);
  }
  // name 出现 dbe_perf.X
  if (/\bdbe_perf\./i.test(n)) {
    const mm = n.match(/\bdbe_perf\.[a-zA-Z_][a-zA-Z0-9_]*/);
    if (mm) add('view', `SELECT * FROM ${mm[0]} LIMIT 50;`, `从 name 提取 ${mm[0]}`);
  }

  return out;
}
function normalize(m) {
  let s = (m || '').trim();
  // 1. strip backtick / quote / code-fence 包裹
  s = s.replace(/^[`"']+/, '').replace(/[`"']+$/, '').trim();
  s = s.replace(/^```\w*\s*/, '').replace(/\s*```$/, '').trim();
  // 2. unicode dash → ASCII dash (en-dash – / em-dash — / minus − 都换 -)
  //    distill 蒸 HTML 时被 typographic 替换 · bash / 工具命令不识别非 ASCII dash
  s = s.replace(/[–—−]/g, '-');
  // 3. strip gsql session prompt 残留 (gaussdb=# / yshen=# / 任意 [a-z_]+=# / =>)
  //    distill 阶段从网页文本扒出来的 method 里很常见 · 不去会让 bash 当变量赋值跑
  s = s.replace(/(^|\s)[a-zA-Z_][a-zA-Z0-9_]*=[#>]\s*/g, '$1').trim();
  // 4. 砍 ' -- ' 行内 SQL 注释 (含中文 / 含 "或" 之后的) · 跨多行不动 · 单行就丢
  //    distill 把多语句串在一行 method 里 · -- 后的"或 SELECT ..."注释会污染
  s = s.replace(/\s+--\s+[^\n]*$/g, '').trim();
  // 5. strip leading prompt-like "$ " / "# " / "gaussdb> "
  s = s.replace(/^[#$]\s+/, '').trim();
  // 6. top 单跑要 -b -n 1 (非交互 tty 跑) · 否则 'top: failed tty get'
  if (/^top\s*$/.test(s)) return 'top -b -n 1';
  // 7. sar 同理需要 -n / -u / count interval · 单 'sar' 报错 · 给个轻量兜底
  if (/^sar\s*$/.test(s)) return 'sar -u 1 1';
  return s;
}

// 起始词在这些 SQL 关键字里 · collector 跑时自动走 gsql -f 而非 bash
const SQL_FIRST_WORDS = ['SELECT','EXPLAIN','SHOW','WITH','SET','VACUUM','ANALYZE',
  'CREATE','ALTER','DROP','TRUNCATE','UPDATE','INSERT','DELETE','COPY','REINDEX',
  'CHECKPOINT','GRANT','REVOKE','RESET','BEGIN','COMMIT','ROLLBACK','CALL','VALUES'];

// 分类
const checks = readFileSync(NDJSON, 'utf8').trim().split('\n').map(l => JSON.parse(l));
const auto = [], manual = [], skip = [];
for (const c of checks) {
  const m = normalize(c.collection_method || '');
  const name = c.metric_name || c.param_name || '';
  const rule = matchedRule(m);
  const derived = (rule && rule !== 'r0-null') ? deriveCommands(m, c.type, name) : [];
  const e = { ...c, name, method: m, matched_rule: rule, derived_commands: derived };
  if (!m || m.toLowerCase() === 'null') skip.push(e);
  else if (rule) manual.push(e);
  else auto.push(e);
}
console.log(`auto=${auto.length} · manual=${manual.length} · skip=${skip.length} · total=${checks.length}`);

// ── manual-audit.md (本地工程文件 · 每条 manual 带 matched_rule + derived_commands) ─
{
  // 统计每条规则切了多少条 · 每个 derive kind 命中多少条
  const ruleCount = {};
  let withDerived = 0;
  const kindCount = {};
  for (const c of manual) {
    const r = c.matched_rule.split(':')[0];
    ruleCount[r] = (ruleCount[r] || 0) + 1;
    if (c.derived_commands.length > 0) withDerived++;
    for (const d of c.derived_commands) kindCount[d.kind] = (kindCount[d.kind] || 0) + 1;
  }
  const ruleRows = Object.entries(ruleCount).sort((a, b) => b[1] - a[1])
    .map(([r, n]) => `| \`${r}\` | ${n} | ${RULE_DESC[r] || '(未命中规则集)'} |`).join('\n');
  const kindRows = Object.entries(kindCount).sort((a, b) => b[1] - a[1])
    .map(([k, n]) => `| \`${k}\` | ${n} |`).join('\n');

  let audit = `# Manual 人审清单 + 派生命令 (manual-audit.md)

> 本地工程文件 (跟 collect-precompiled.sh 一样属 offline-collect-kit 目录),build 时由 \`_build-precompiled.mjs\` 自动生成。
> 跟 collector 部署到 db 服务器后生成的 \`outdir/manual.md\` 不同:
> - \`outdir/manual.md\` 给运维当场看 · 只有蒸馏原文
> - \`manual-audit.md\` 给离线人审 · 多了:**matched_rule**(为什么被切人审) + **derived_commands**(从描述挖出的候选可执行命令)
>
> 派生命令是启发式抓的"看起来能跑"的命令 · **不保证语义正确** · 是人审起点 · 不是 ground truth.

## 总览

- 总 manual 数: **${manual.length}**
- 有派生命令的: **${withDerived}** / ${manual.length} (${(withDerived / manual.length * 100).toFixed(1)}%)
- 完全靠人脑解读的: **${manual.length - withDerived}**

### 切人审规则分布

| 规则 | 数量 | 含义 |
|---|---:|---|
${ruleRows}

### 派生命令类型分布

| 类型 | 命中条数 |
|---|---:|
${kindRows}

派生命令 kind 含义:

- \`view\` — 已知 GaussDB 视图/表 · 派生 \`SELECT * FROM view LIMIT 50\`
- \`guc\` — 已知 GUC 参数 · 派生 \`SHOW guc_name\`
- \`os\` — 描述里直接出现的 OS 命令 (top -Hp / sar / vmstat / iostat ...)
- \`sql-stub\` — 描述提到 EXPLAIN / ANALYZE · 派生模板需人填实际 SQL

---

`;
  for (const c of manual) {
    const ruleShort = c.matched_rule.split(':')[0];
    const ruleHit = c.matched_rule.includes(':') ? ` (命中: \`${c.matched_rule.split(':')[1]}\`)` : '';
    const ruleHuman = RULE_DESC[ruleShort] || '(未命中规则集)';
    audit += `## ${c.check_id} · ${c.name}\n`;
    audit += `- layer: \`${c.collection_layer}\` · type: \`${c.type}\`\n`;
    audit += `- matched_rule: \`${ruleShort}\`${ruleHit} · ${ruleHuman}\n`;
    audit += `- 蒸馏原文:\n  \`\`\`\n  ${c.method.replace(/\n/g, '\n  ')}\n  \`\`\`\n`;
    if (c.derived_commands.length === 0) {
      audit += `- 派生命令: **(无 · 描述里没识别出已知视图/GUC/OS 命令 · 需人审从零写)**\n\n`;
    } else {
      audit += `- 派生命令 (启发式 · 仅作参考起点):\n`;
      for (const d of c.derived_commands) {
        audit += `  - \`[${d.kind}]\` \`${d.sql}\`${d.note ? `  — ${d.note}` : ''}\n`;
      }
      audit += '\n';
    }
  }
  writeFileSync(OUT_AUDIT, audit);
  console.log(`wrote: ${OUT_AUDIT} (${(audit.length / 1024).toFixed(1)} KB · ${manual.length} manual · ${withDerived} 有派生)`);
}

// ── bash 预编译版 (heredoc 风格 · 不需 jq / python3) ───────────────────────
const shHead = `#!/usr/bin/env bash
# GaussDB 离线采集 · 预编译版 · 完全自包含
# 所有 ${auto.length} 个 auto 命令已 inline 为 heredoc (不解析 ndjson · 不需 jq).
#
# 生成时间: ${new Date().toISOString()}
# 数据: auto=${auto.length} · manual=${manual.length} · skip=${skip.length} · total=${checks.length}
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
OUTDIR="\${1:-./collect-results-\$(date +%Y%m%d-%H%M%S)}"
TIMEOUT="\${COLLECT_TIMEOUT:-5}"
T_BIN=\$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || echo "")
# top / sar / vmstat 等 tty 工具在非交互 shell 会抱怨 TERM unset · 给个 dumb 兜底
export TERM="\${TERM:-dumb}"
mkdir -p "\$OUTDIR/stdout" "\$OUTDIR/stderr"

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
  v=\$(gsql -d postgres -t -A -c "SELECT pg_catalog.gs_deployment()" 2>/dev/null | tr -d '[:space:]')
  local lower
  lower=\$(echo "\$v" | tr '[:upper:]' '[:lower:]')
  case "\$lower" in
    *centralized*) echo "centralized" ;;
    *distribut*)   echo "distributed" ;;
    *single*node*|*singlenode*) echo "single-node" ;;
    "") echo "unknown-detect-fail" ;;
    *)  echo "unknown-\$v" ;;
  esac
}
DEPLOY_FORM=\$(detect_deploy_form)
echo "部署形态自识别: \$DEPLOY_FORM" >&2

# 写到 report 头部元数据 (注释行 · 也 dump 到 deploy.txt 便于程序解析)
{
  printf '# deploy_form\\t%s\\n' "\$DEPLOY_FORM"
  printf '# detected_at\\t%s\\n' "\$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '# host\\t%s\\n' "\$(hostname 2>/dev/null || echo unknown)"
  printf '# user\\t%s\\n' "\$(whoami)"
  printf 'check_id\\texit_code\\tstatus\\n'
} > "\$OUTDIR/report.tsv"
printf '%s\\n' "\$DEPLOY_FORM" > "\$OUTDIR/deploy.txt"

run_check() {
  # 用法: run_check <check_id> <<'EOF_XXX'
  #         <真命令>
  #       EOF_XXX
  # 自动 dispatch: 起始词是 SQL 关键字 → gsql -f, 否则 bash.
  local cid="\$1"
  local tmpf
  tmpf=\$(mktemp)
  cat > "\$tmpf"
  # 取第一个非空 token (大写化 · 砍标点)
  local first
  first=\$(awk 'NF{for(i=1;i<=NF;i++)if(\$i!~/^--/){print toupper(\$i);exit}}' "\$tmpf" | tr -d '[:punct:]')
  local cmd_kind="shell"
  case "\$first" in
    SELECT|EXPLAIN|SHOW|WITH|SET|VACUUM|ANALYZE|CREATE|ALTER|DROP|TRUNCATE|UPDATE|INSERT|DELETE|COPY|REINDEX|CHECKPOINT|GRANT|REVOKE|RESET|BEGIN|COMMIT|ROLLBACK|CALL|VALUES)
      cmd_kind="sql" ;;
  esac
  set +e
  if [ "\$cmd_kind" = "sql" ]; then
    if [ -n "\$T_BIN" ]; then
      "\$T_BIN" "\$TIMEOUT" gsql -d postgres -f "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    else
      gsql -d postgres -f "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    fi
  else
    if [ -n "\$T_BIN" ]; then
      "\$T_BIN" "\$TIMEOUT" bash "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    else
      bash "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    fi
  fi
  local rc=\$?
  set -e
  rm -f "\$tmpf"
  local s
  case \$rc in 0) s=ok;; 124) s=timeout;; *) s="error-rc\$rc";; esac
  # ghost-ok detector: gsql -f 默认 batch · SQL 报错也 exit 0
  # rc=0 时 grep stderr 含 ERROR/FATAL/PANIC → 标 ghost-ok-sql-error 而非 ok
  # 只在 sql 类生效 (shell 类 stderr 含 ERROR 是正常输出 · 不算 ghost-ok)
  if [ "\$s" = "ok" ] && [ "\$cmd_kind" = "sql" ] && [ -s "\$OUTDIR/stderr/\$cid.txt" ]; then
    if LC_ALL=C grep -qE '^(gsql:.+:[[:space:]]*)?(ERROR|FATAL|PANIC):' "\$OUTDIR/stderr/\$cid.txt" 2>/dev/null; then
      s=ghost-ok-sql-error
    fi
  fi
  printf '%s\\t%s\\t%s\\n' "\$cid" "\$rc" "\$s" >> "\$OUTDIR/report.tsv"
}

i=0
TOTAL=${auto.length}
echo "开始: \$TOTAL 个 auto 命令 · timeout \${TIMEOUT}s · outdir \$OUTDIR"
echo ""

`;

let shBody = '';
for (const c of auto) {
  const term = `EOF_${c.check_id.replace(/[^a-zA-Z0-9]/g, '_').toUpperCase()}`;
  shBody += `i=\$((i+1))
[ \$((i % 30)) -eq 0 ] && echo "[\$i/\$TOTAL]" >&2
# ${c.check_id} · ${c.name.replace(/\n/g, ' ').slice(0, 80)} · layer=${c.collection_layer}
run_check "${c.check_id}" <<'${term}'
${c.method}
${term}

`;
}

let shTail = `
# ── ${manual.length} 个描述性 method (蒸馏不可执行 · 写 manual.md) ──────────
cat > "\$OUTDIR/manual.md" <<'MANUAL_DOC_END'
# 需人审 method (描述性中文 · 不自动跑 · 共 ${manual.length} 项)

> distill-v2 蒸馏出来的描述性文本 (含 8+ 汉字 OR "查看/判断/通常/建议..." 等关键词),
> 不能直接当 shell 命令跑。请人工解读后手工执行,把结果跟 case abnormal_pattern 比对。

`;
for (const c of manual) {
  const cleanMethod = c.method.replace(/\n/g, '\n  ');
  shTail += `## ${c.check_id} · ${c.name}\n- layer: \`${c.collection_layer}\` · type: \`${c.type}\`\n- method:\n  \`\`\`\n  ${cleanMethod}\n  \`\`\`\n\n`;
}

shTail += `MANUAL_DOC_END

# ── ${skip.length} 个 NULL/空 method (蒸馏没抽到抓法 · 仅记录) ─────────────
cat > "\$OUTDIR/skip.md" <<'SKIP_DOC_END'
# Skip-empty method (蒸馏没抽到 collection_method · 共 ${skip.length} 项)

`;
for (const c of skip) {
  shTail += `- \`${c.check_id}\` · ${c.name} (layer=\`${c.collection_layer}\`)\n`;
}

shTail += `SKIP_DOC_END

echo ""
echo "─────────────────────────────────────────────"
echo "完成 · TOTAL=${checks.length} · auto=${auto.length} · manual=${manual.length} · skip=${skip.length}"
echo "  报告:        \$OUTDIR/report.tsv"
echo "  stdout 目录: \$OUTDIR/stdout/"
echo "  stderr 目录: \$OUTDIR/stderr/"
echo "  人审 (${manual.length}): \$OUTDIR/manual.md"
echo "  空 method (${skip.length}): \$OUTDIR/skip.md"
`;

writeFileSync(OUT_SH, shHead + shBody + shTail);
console.log(`wrote: ${OUT_SH} (${((shHead+shBody+shTail).length/1024).toFixed(1)} KB)`);

// ── python 预编译版 (CHECKS list · 全 inline) ─────────────────────────────
const pyHead = `#!/usr/bin/env python3
"""GaussDB 离线采集 · 预编译版 · 自包含 · python 纯 stdlib.

所有 ${auto.length} 个 auto 命令已 inline 在 CHECKS list 里 (不解析 ndjson).

生成时间: ${new Date().toISOString()}
数据: auto=${auto.length} · manual=${manual.length} · skip=${skip.length} · total=${checks.length}

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
(OUTDIR / 'deploy.txt').write_text(DEPLOY_FORM + '\\n')

# (check_id, name, layer, method) · ${auto.length} 条 auto · 直接跑
CHECKS = [
`;

let pyBody = '';
for (const c of auto) {
  pyBody += `    (${JSON.stringify(c.check_id)}, ${JSON.stringify(c.name)}, ${JSON.stringify(c.collection_layer)}, ${JSON.stringify(c.method)}),\n`;
}

let pyMid = `]

# (check_id, name, layer, method) · ${manual.length} 条 manual · 描述性 · 不自动跑
MANUAL = [
`;
for (const c of manual) {
  pyMid += `    (${JSON.stringify(c.check_id)}, ${JSON.stringify(c.name)}, ${JSON.stringify(c.collection_layer)}, ${JSON.stringify(c.method)}),\n`;
}

let pyTail = `]

# (check_id, name, layer) · ${skip.length} 条 skip · 蒸馏没抽到 method
SKIP = [
`;
for (const c of skip) {
  pyTail += `    (${JSON.stringify(c.check_id)}, ${JSON.stringify(c.name)}, ${JSON.stringify(c.collection_layer)}),\n`;
}

pyTail += `]

# ── 主循环 ────────────────────────────────────────────────────────────────
print(f'开始: {len(CHECKS)} 个 auto 命令 · timeout {TIMEOUT}s · outdir {OUTDIR}', flush=True)
report = OUTDIR / 'report.tsv'
with open(report, 'w', encoding='utf-8') as rf:
    import socket as _sk
    rf.write(f'# deploy_form\\t{DEPLOY_FORM}\\n')
    rf.write(f'# detected_at\\t{datetime.now().astimezone().isoformat(timespec="seconds")}\\n')
    rf.write(f'# host\\t{_sk.gethostname()}\\n')
    rf.write(f'# user\\t{os.environ.get("USER", "unknown")}\\n')
    rf.write('check_id\\texit_code\\tstatus\\n')
    # 自动 dispatch: SQL 起始词走 gsql -f, 其他走 bash -c
    SQL_FIRST = {'SELECT','EXPLAIN','SHOW','WITH','SET','VACUUM','ANALYZE','CREATE',
                 'ALTER','DROP','TRUNCATE','UPDATE','INSERT','DELETE','COPY','REINDEX',
                 'CHECKPOINT','GRANT','REVOKE','RESET','BEGIN','COMMIT','ROLLBACK','CALL','VALUES'}
    import tempfile, re as _re
    for i, (cid, name, layer, method) in enumerate(CHECKS, 1):
        # 取第一个非注释 token 大写化
        first = ''
        for tok in _re.split(r'\\s+', method.strip()):
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
                if _re2.search(rb'(?m)^(gsql:.+:\\s*)?(ERROR|FATAL|PANIC):', r.stderr):
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
            (OUTDIR / 'stderr' / f'{cid}.txt').write_bytes((e.stderr or b'') + f'\\n[TIMEOUT {TIMEOUT}s]'.encode())
        rf.write(f'{cid}\\t{rc}\\t{status}\\n')
        if i % 30 == 0 or i == len(CHECKS):
            print(f'  [{i}/{len(CHECKS)}] {cid}', file=sys.stderr, flush=True)

# manual.md
manual_lines = [f'# 需人审 method (描述性中文 · 不自动跑 · 共 {len(MANUAL)} 项)', '',
                '> distill-v2 蒸馏的描述性文本 · 不能直接 shell 跑 · 请人工解读后手工执行', '']
for cid, name, layer, method in MANUAL:
    manual_lines += [f'## {cid} · {name}', f'- layer: \`{layer}\`',
                     '- method:', '  \`\`\`', f'  {method}', '  \`\`\`', '']
(OUTDIR / 'manual.md').write_text('\\n'.join(manual_lines), encoding='utf-8')

# skip.md
skip_lines = [f'# Skip-empty method (蒸馏没抽到 · 共 {len(SKIP)} 项)', '']
for cid, name, layer in SKIP:
    skip_lines.append(f'- \`{cid}\` · {name} (layer=\`{layer}\`)')
(OUTDIR / 'skip.md').write_text('\\n'.join(skip_lines), encoding='utf-8')

print()
print('─────────────────────────────────────────────')
print(f'完成 · TOTAL={len(CHECKS)+len(MANUAL)+len(SKIP)} · auto={len(CHECKS)} · manual={len(MANUAL)} · skip={len(SKIP)}')
print(f'  报告:         {report}')
print(f'  stdout 目录:  {OUTDIR}/stdout/')
print(f'  stderr 目录:  {OUTDIR}/stderr/')
print(f'  人审 ({len(MANUAL)}): {OUTDIR}/manual.md')
print(f'  空 method ({len(SKIP)}): {OUTDIR}/skip.md')
`;

writeFileSync(OUT_PY, pyHead + pyBody + pyMid + pyTail);
console.log(`wrote: ${OUT_PY} (${((pyHead+pyBody+pyMid+pyTail).length/1024).toFixed(1)} KB)`);
