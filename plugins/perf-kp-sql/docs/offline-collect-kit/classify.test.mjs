// classify.mjs 单测 · test-first
// 覆盖: (A)只读安全 写/破坏性→manual (B)gsql -c 解包 (C)畸形SHOW修复 (D)JDBC→manual
//      (E)集成: 跑真 checklist.ndjson 的分类 · auto 集 0 破坏性 / 0 gsql 外壳 / 0 畸形 SHOW
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { normalize, matchedRule, unwrapGsqlC, repairCommand, isDestructive } from './classify.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const isManual = (m) => matchedRule(m) !== null;
const isAuto = (m) => matchedRule(m) === null;

test('A · 写/破坏性命令一律 manual (严格只读)', () => {
  const DESTRUCTIVE = [
    "SELECT PG_TERMINATE_BACKEND(pid) from pg_stat_activity WHERE state='idle';",
    'gsql -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity;"',
    'SELECT pg_cancel_backend(123);',
    'DROP TABLE foo;',
    'TRUNCATE bar;',
    'DELETE FROM t WHERE 1=1;',
    'UPDATE t SET x=1;',
    'INSERT INTO t VALUES (1);',
    'ALTER SYSTEM SET work_mem=1;',
    'VACUUM FULL bigtable;',
    'REINDEX TABLE t;',
    'CHECKPOINT;',
    'CREATE INDEX idx ON t(a);',
  ];
  for (const cmd of DESTRUCTIVE) {
    assert.ok(isManual(normalize(cmd)), `应判 manual(只读护栏): ${cmd}`);
  }
});

test('A2 · 只读 SELECT/SHOW 不被误伤 (analyze/vacuum/create 作为子串不算)', () => {
  const READONLY = [
    'SHOW work_mem;',
    'SHOW autovacuum;',                                  // 含 vacuum 子串 · 但 \bvacuum\b 不匹配
    'SHOW autovacuum_vacuum_cost_delay;',
    'SELECT relname, last_analyze, last_autoanalyze FROM pg_stat_user_tables LIMIT 20;',  // last_analyze 子串
    'SELECT * FROM pg_stat_activity LIMIT 50;',
    'SELECT * FROM pgxc_get_table_skewness ORDER BY totalsize DESC;',
  ];
  for (const cmd of READONLY) {
    assert.ok(isAuto(normalize(cmd)), `应保持 auto(只读): ${cmd}`);
  }
});

test('B · gsql -c "<SQL>" 解包成裸 SQL', () => {
  assert.equal(unwrapGsqlC('gsql -d postgres -c "SHOW work_mem;"'), 'SHOW work_mem;');
  assert.equal(unwrapGsqlC("gsql -d postgres -c 'SHOW work_mem'"), 'SHOW work_mem;');
  assert.equal(unwrapGsqlC('gsql -c "SELECT 1"'), 'SELECT 1;');
  // 不干净的不解包 (管道/多 -c) → 原样
  assert.equal(unwrapGsqlC('gsql -c "SHOW a" | grep x'), 'gsql -c "SHOW a" | grep x');
  assert.equal(unwrapGsqlC('gsql -c "SHOW a" -c "SHOW b"'), 'gsql -c "SHOW a" -c "SHOW b"');
  // 闭合引号后的 distill 注释残留 ( -- 或 SELECT ...) 要砍掉再解包 (真实 ndjson 普遍如此)
  assert.equal(unwrapGsqlC('gsql -d postgres -c "SHOW shared_buffers;"  -- 或 SELECT name,setting FROM pg_settings'), 'SHOW shared_buffers;');
  assert.ok(isAuto(normalize('gsql -d postgres -c "SHOW work_mem;"  -- 或 SELECT name,setting WHERE x > y')), 'GUC 带注释残留也应 auto');
  // 非 gsql 原样
  assert.equal(unwrapGsqlC('SHOW work_mem;'), 'SHOW work_mem;');
  // 解包后 collector 会走 SQL 路径: 首词是 SHOW
  assert.match(normalize('gsql -d postgres -c "SHOW shared_buffers;"'), /^SHOW shared_buffers;/i);
});

test('C · 畸形 SHOW 能修成有效只读 auto', () => {
  // a) 文件路径 → cat
  assert.equal(repairCommand('SHOW /sys/kernel/debug/sched_features;'), 'cat /sys/kernel/debug/sched_features');
  // b) OS sysctl → sysctl
  assert.equal(repairCommand('SHOW net.core.netdev_max_backlog;'), 'sysctl net.core.netdev_max_backlog');
  // c) 斜杠拼多 GUC → 拆多条 SHOW
  assert.equal(repairCommand('SHOW recovery_max_workers/recovery_parse_workers/recovery_redo_workers;'),
    'SHOW recovery_max_workers;\nSHOW recovery_parse_workers;\nSHOW recovery_redo_workers;');
  assert.equal(repairCommand('SHOW client_encoding / server_encoding;'),
    'SHOW client_encoding;\nSHOW server_encoding;');
  // d) 空格切碎 → 下划线
  assert.equal(repairCommand('SHOW wal file init num;'), 'SHOW wal_file_init_num;');
  // 修完都应是 auto (经 gsql -c 外壳进来也一样) · 注: debugfs 例外见下方 r22
  for (const cmd of [
    'gsql -d postgres -c "SHOW net.core.netdev_max_backlog;"',
    'gsql -d postgres -c "SHOW recovery_parse_workers / recovery_redo_workers;"',
    'gsql -d postgres -c "SHOW wal file init num;"',
  ]) {
    assert.ok(isAuto(normalize(cmd)), `修完应 auto: ${cmd}`);
  }
  // debugfs (/sys/kernel/debug/*) 只 root 可读 · DB 用户采集器跑不了 → manual (r22) · 不留 auto
  assert.ok(isManual(normalize('gsql -d postgres -c "SHOW /sys/kernel/debug/sched_features;"')), 'debugfs 应 manual(需 root)');
  assert.equal(matchedRule(normalize('SHOW /sys/kernel/debug/sched_features;')), 'r22-needs-root');
  // resource_pool. / sequence. 是 GUC 命名空间 · 不是 OS sysctl · 不被 sysctl 误伤 · 保持 SHOW(auto)
  assert.equal(repairCommand('SHOW resource_pool.cpu_dedicated_quota;'), 'SHOW resource_pool.cpu_dedicated_quota;');
  assert.ok(isAuto(normalize('gsql -d postgres -c "SHOW resource_pool.cpu_dedicated_quota;"')));
});

test('D · JDBC 客户端驱动参数 → manual (非服务端 GUC · 修不成 auto)', () => {
  for (const cmd of [
    'gsql -d postgres -c "SHOW fetchSize;"',
    'gsql -d postgres -c "SHOW loginTimeout;"',
    'gsql -d postgres -c "SHOW connectionTimeOut;"',
  ]) {
    assert.ok(isManual(normalize(cmd)), `JDBC 参数应 manual: ${cmd}`);
  }
  // snake_case 版本特异 GUC 保持 auto (靠运行时标 unsupported · 不强行 manual)
  for (const cmd of [
    'gsql -d postgres -c "SHOW disk_cache_max_size;"',
    'gsql -d postgres -c "SHOW min_batch_rows;"',
    'gsql -d postgres -c "SHOW enable_delta;"',
  ]) {
    assert.ok(isAuto(normalize(cmd)), `版本特异 GUC 应保持 auto: ${cmd}`);
  }
});

test('E · 集成: 真 checklist.ndjson 分类后 auto 集 0 破坏性 / 0 gsql 外壳 / 0 畸形 SHOW', () => {
  const checks = readFileSync(join(HERE, 'checklist.ndjson'), 'utf8')
    .trim().split('\n').map(l => JSON.parse(l));
  const auto = [];
  for (const c of checks) {
    const m = normalize(c.collection_method || '');
    if (!m || m.toLowerCase() === 'null') continue;
    if (matchedRule(m) === null) auto.push({ id: c.check_id, m });
  }
  assert.ok(auto.length > 0, 'auto 不应为空');

  const destructive = auto.filter(a => isDestructive(a.m));
  assert.deepEqual(destructive.map(a => a.id), [], `auto 集出现破坏性命令: ${JSON.stringify(destructive, null, 2)}`);

  const gsqlWrap = auto.filter(a => /^gsql\b/i.test(a.m.trim()));
  assert.deepEqual(gsqlWrap.map(a => a.id), [], `auto 集仍有 gsql -c 外壳(未解包): ${JSON.stringify(gsqlWrap, null, 2)}`);

  // 畸形 SHOW: SHOW 后不是 (多行拆分 / 干净点分标识符)
  const malformed = auto.filter(a => {
    const mm = a.m.match(/^show\s+(.+?)\s*;?\s*$/i);  // 单行 SHOW
    if (!mm) return false;
    return !/^[a-z_][a-z0-9_.]*$/i.test(mm[1].trim());  // 含 / 或空格 → 畸形
  });
  assert.deepEqual(malformed.map(a => a.id), [], `auto 集仍有畸形 SHOW: ${JSON.stringify(malformed, null, 2)}`);
});
