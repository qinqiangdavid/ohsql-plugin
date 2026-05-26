#!/usr/bin/env node
// 从 perf-kp-sql by-check-item/CASES.md 过滤出 gaussdb 系 (gaussdb + gaussdb-dws)
// case 关联的 check-items,整理成 GaussDB 离线采集清单。
//
// 离线形态用途: user 在内网/无 SSH 直连环境跑 GaussDB,不能让 perf-kp-sql skill
// 远程实时采集。需要拿一份"要抓哪些指标 + 怎么抓"清单,手工跑完拿结果反喂 skill 诊断。
//
// 用法: node extract-offline-checklist.mjs  (脚本自包含 · 相对自身位置定位 · 无硬编码路径)
//
// 数据流位置 (本脚本是 perf-kp-sql 离线采集 kit 的【源头】· 不是蒸馏引擎):
//   data/cases/indices/by-check-item/CASES.md  (蒸馏产物 · 655 check)
//        │ ← 本脚本: 筛 gaussdb 系 + A3 剔文档示例 SQL
//        ▼
//   docs/gaussdb-offline-checklist.ndjson      (290 真采集)
//        │ ← cp 到 offline-collect-kit/checklist.ndjson + node _build-precompiled.mjs
//        ▼
//   offline-collect-kit/collect-precompiled.{sh,py}  (部署到 GaussDB 服务器跑)
//
// 收编自 db-distill-engine (crawler) 的 runs/gaussdb-tuning-kunpeng/scripts/ · 2026-05-25
// 收编理由: 它逻辑上属 perf-kp-sql 离线套件 (读 perf-kp-sql case 库 · 写 perf-kp-sql docs)
//           而非蒸馏引擎 (distill-v2) · 留 crawler 仓 runs/* 被 gitignore 改动不可追溯。

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));   // .../perf-kp-sql/docs/offline-collect-kit
const OHSQL = join(HERE, '..', '..');                   // .../perf-kp-sql (上溯两级)
const OUT = join(HERE, '..', 'gaussdb-offline-checklist.md');  // 写到 docs/ 下 (跟收编前一致)

// ── 1. 抽 gaussdb 系 case_id set ─────────────────────────────────────────
const gaussCaseIds = new Set();
for (const db of ['gaussdb', 'gaussdb-dws']) {
  const text = readFileSync(`${OHSQL}/data/cases/${db}/CASES.md`, 'utf8');
  for (const m of text.matchAll(/^## case_id:\s*(\S+)/gm)) {
    gaussCaseIds.add(m[1]);
  }
}
console.log(`gaussdb 系 case_id total: ${gaussCaseIds.size}`);

// ── 2. parse by-check-item/CASES.md 全部 check ───────────────────────────
const chText = readFileSync(`${OHSQL}/data/cases/indices/by-check-item/CASES.md`, 'utf8');
const blocks = chText.split(/(?=^## check_id:\s*)/gm).filter(b => b.startsWith('## check_id:'));
console.log(`by-check-item total: ${blocks.length} check`);

const checks = [];
for (const b of blocks) {
  const id = (b.match(/^## check_id:\s*(\S+)/) || [])[1];
  if (!id) continue;
  const c = { check_id: id };

  for (const k of ['type', 'metric_name', 'param_name', 'collection_layer', 'collection_method',
                   'recommended_value', 'recommendation_layer', 'risk_severity',
                   'source_url', 'source_authority', 'scope']) {
    const m = b.match(new RegExp(`^- \\*\\*${k}\\*\\*:\\s*(.+)$`, 'm'));
    if (m) c[k] = m[1].trim();
  }

  // arrays
  const apM = b.match(/^- \*\*abnormal_patterns\*\*:\s*\[([^\]]*)\]/m);
  if (apM) c.abnormal_patterns = apM[1];
  const vpM = b.match(/^- \*\*violation_patterns\*\*:\s*\[([^\]]*)\]/m);
  if (vpM) c.violation_patterns = vpM[1];
  const rM = b.match(/^- \*\*rationales\*\*:\s*\[([^\]]*)\]/m);
  if (rM) c.rationales = rM[1];
  const lkM = b.match(/^- \*\*linked_case_ids\*\*:\s*\[([^\]]*)\]/m);
  if (lkM) {
    c.linked_case_ids = lkM[1].split(',').map(s => s.trim().replace(/^["']|["']$/g, '')).filter(Boolean);
  } else {
    c.linked_case_ids = [];
  }
  checks.push(c);
}

// ── 3. 过滤: linked_case_ids ∩ gaussdb 系 case_id set 非空 ─────────────────
let gaussChecks = checks.filter(c => c.linked_case_ids.some(cid => gaussCaseIds.has(cid)));
console.log(`gaussdb 关联 check: ${gaussChecks.length} (${(100*gaussChecks.length/checks.length).toFixed(1)}%)`);

// ── 3.1 剔除文档示例 SQL (EXPLAIN ... FROM <案例示例表>) ──────────────────
// distill 把 GaussDB 文档里 EXPLAIN 案例代码块当 method 抓进了 check.collection_method,
// 实际跑生产 db 会 "relation does not exist" (t1 / customer / lineitem / store_sales /
// bmsql_customer / public.test 等 TPC-H/TPC-DS/BMSQL/文档示例表 · 客户库没有).
// 这些不是真采集动作,是 distill 漏过滤的文档案例展示 · 标 is_example 不入 ndjson.
const TRUSTED_VIEW_PREFIXES = ['pg_', 'pgxc_', 'gs_', 'dbe_perf.', 'PGXC_', 'GS_', 'DBE_PERF.'];
// information_schema 是 SQL 标准系统视图 · statement_history/table_distribution 是 GaussDB 内置
const TRUSTED_VIEW_EXACT = new Set(['statement_history', 'table_distribution']);
function isTrustedView(v) {
  const lo = v.toLowerCase();
  if (TRUSTED_VIEW_EXACT.has(lo)) return true;
  if (lo.startsWith('information_schema.')) return true;
  return TRUSTED_VIEW_PREFIXES.some(p => v.startsWith(p) || lo.startsWith(p.toLowerCase()));
}
// 写操作起始词 → 采集是只读动作 · 任何 DDL/DML 都不是采集 (建索引 / 改表 / 删数据)
const WRITE_FIRST = /^(CREATE|ALTER|DROP|TRUNCATE|INSERT|UPDATE|DELETE|REINDEX|GRANT|REVOKE|COMMENT|CLUSTER|REFRESH)\b/i;
// 只读查询起始词 → 仅这些才走 FROM 表名规则 (避免中文描述里 "Nest Loop Join Filter" 误匹配)
const READ_FIRST = /^(SELECT|EXPLAIN|WITH|VALUES|TABLE)\b/i;
function normalizeForCheck(method) {
  let m = (method || '').trim();
  if (!m) return '';
  // 跟 _build-precompiled.mjs normalize 一致: strip 反引号/引号/code-fence 包裹
  m = m.replace(/^[`"']+/, '').replace(/[`"']+$/, '').trim();
  m = m.replace(/^```\w*\s*/, '').replace(/\s*```$/, '').trim();
  // strip gsql session prompt 残留 (gaussdb=# / yshen=# / [a-z_]+=[#>]) — 行内 + 行首都去
  m = m.replace(/(^|\s)[a-zA-Z_][a-zA-Z0-9_]*=[#>]\s*/g, '$1').trim();
  // 砍前置 SET / `set rewrite_rule='none';` (案例查询常带前置 SET 配 GUC) + 前置 EXPLAIN 修饰
  m = m.replace(/^(?:SET\s+[^;]*;\s*)+/i, '').trim();
  return m;
}
function isDocExample(method) {
  const m = normalizeForCheck(method);
  if (!m) return false;
  // 规则1: 写操作 (DDL/DML) → 采集只读 · 绝不是采集动作 (例: CREATE INDEX ON test_range_pt)
  if (WRITE_FIRST.test(m)) return true;
  // 规则2: 只读查询 (SELECT/EXPLAIN/WITH) 且 FROM/JOIN 跟非 trusted 表 → 文档示例
  //   前提必须是 SQL 起始 — 否则中文描述里 "Nest Loop Join Filter" 的 Join 会被误当子句 (踩过)
  if (!READ_FIRST.test(m)) return false;
  //   真采集只查 pg_/pgxc_/gs_/dbe_perf/information_schema 系统视图 · 不 JOIN 业务/示例表
  //   (t1 / customer / lineitem / skew / tablename / store_sales 等 TPC-H/DS/BMSQL/占位表)
  const tables = [];
  // FROM/JOIN 后跟标识符 · 但排除函数调用 / 子查询 FROM xxx( (踩过 get_last_changed_table())
  const re = /\b(?:FROM|JOIN)\s+([a-zA-Z_][a-zA-Z0-9_.]*)\s*(\()?/gi;
  let mm;
  while ((mm = re.exec(m))) {
    if (mm[2] === '(') continue;  // 函数调用 / 后接子查询 · 不当表名
    tables.push(mm[1]);
  }
  if (tables.length > 0 && tables.some(t => !isTrustedView(t))) return true;
  return false;
}
const docExamples = gaussChecks.filter(c => isDocExample(c.collection_method));
gaussChecks = gaussChecks.filter(c => !isDocExample(c.collection_method));
console.log(`剔除文档示例 SQL: ${docExamples.length} 条 (写操作 DDL/DML + 只读查询 FROM 跟非 trusted 表)`);
console.log(`  示例: ${docExamples.slice(0, 3).map(c => c.check_id).join(', ')}${docExamples.length > 3 ? ' ...' : ''}`);
console.log(`剔除后真采集 check: ${gaussChecks.length}`);

// ── 3.5 给空 slug chk- (中文 metric_name slug 化失败) 加序号 ──────────────
// build-runtime 不修这个 bug,我们在下游侧补救:同名 chk- 全部加 -<n> 后缀让 unique
let nullSlugIdx = 1;
for (const c of gaussChecks) {
  if (c.check_id === 'chk-' || c.check_id === 'chk') {
    c.check_id = `chk-null-${String(nullSlugIdx++).padStart(3, '0')}`;
  }
}

// ── 3.6 GUC 参数审计 layer 推断 ───────────────────────────────────────────
// type=parameter-current-value + collection_layer 空 → 全是 GUC 参数 (bp absorbed
// 时 distill-v2 蒸馏 PROMPT 没要求填 collection_layer,因为采参数现值统一走
// pg_settings / SHOW,不需要每条特化)。下游补 layer + collection_method。
for (const c of gaussChecks) {
  if (c.type === 'parameter-current-value' && (!c.collection_layer || c.collection_layer === '')) {
    const pname = c.param_name || c.metric_name || '';
    c.collection_layer = 'gaussdb-guc-param';
    // 同时给一个 collection_method 兜底
    if (!c.collection_method) {
      c.collection_method = `gsql -d postgres -c "SHOW ${pname};"  -- 或 SELECT name,setting,unit,context FROM pg_settings WHERE name='${pname}';`;
    }
  }
}

// ── 4. 按 type + collection_layer 分组渲染 ────────────────────────────────
const byLayer = {};
for (const c of gaussChecks) {
  const layer = c.collection_layer || '(unknown)';
  if (!byLayer[layer]) byLayer[layer] = { metric: [], paramCV: [] };
  if (c.type === 'metric') byLayer[layer].metric.push(c);
  else byLayer[layer].paramCV.push(c);
}

// 统计
const stats = {
  total: gaussChecks.length,
  metric: gaussChecks.filter(c => c.type === 'metric').length,
  paramCV: gaussChecks.filter(c => c.type === 'parameter-current-value').length,
  byLayer: Object.fromEntries(Object.entries(byLayer).map(
    ([k, v]) => [k, v.metric.length + v.paramCV.length])),
};

// ── 5. 渲染 markdown ─────────────────────────────────────────────────────
const lines = [];
lines.push('# GaussDB 离线采集清单(指标 + 抓取方法)');
lines.push('');
lines.push(`- 生成: ${new Date().toISOString()}`);
lines.push(`- 关联 case 范围: \`cases/gaussdb/\` (77 case) + \`cases/gaussdb-dws/\` (120 case) · 共 ${gaussCaseIds.size} case_id`);
lines.push(`- 数据源: \`plugins/perf-kp-sql/data/cases/indices/by-check-item/CASES.md\` (655 check 总,本清单是 gaussdb 关联子集)`);
lines.push('');
lines.push('## 用途');
lines.push('');
lines.push('GaussDB 在内网/无 SSH 直连场景 perf-kp-sql skill 不能远程采集,把这份清单拿到目标机手工跑,');
lines.push('结果撞 `cases/<db>/CASES.md` 每条 case 的 `abnormal_pattern` 字段 → 命中即对应 case_id 候选。');
lines.push('');
lines.push('- `type: metric` → 单纯采指标值跟阈值比');
lines.push('- `type: parameter-current-value` → 采参数现值跟 `recommended_value` 比');
lines.push('');
lines.push('## 总览');
lines.push('');
lines.push(`| | 数 |`);
lines.push(`|---|---:|`);
lines.push(`| **GaussDB 关联 check 合计** | **${stats.total}** |`);
lines.push(`| 其中 type=metric | ${stats.metric} |`);
lines.push(`| 其中 type=parameter-current-value | ${stats.paramCV} |`);
lines.push('');
lines.push('### 按 collection_layer 分布');
lines.push('');
lines.push(`| collection_layer | check 数 |`);
lines.push(`|---|---:|`);
for (const [layer, n] of Object.entries(stats.byLayer).sort((a, b) => b[1] - a[1])) {
  lines.push(`| \`${layer}\` | ${n} |`);
}
lines.push('');
lines.push('---');
lines.push('');

// 各 layer 详情
const layerOrder = Object.entries(stats.byLayer).sort((a, b) => b[1] - a[1]).map(x => x[0]);
for (const layer of layerOrder) {
  const grp = byLayer[layer];
  const total = grp.metric.length + grp.paramCV.length;
  lines.push(`## collection_layer = \`${layer}\` (${total} check)`);
  lines.push('');

  if (layer === 'gaussdb-guc-param') {
    lines.push('> 全部是 GaussDB GUC 配置参数(autovacuum / enable_* / work_mem / comm_max_stream 等)。');
    lines.push('> **统一采集方式**:');
    lines.push('>');
    lines.push('> ```sql');
    lines.push('> -- 单条:');
    lines.push('> SHOW <param_name>;');
    lines.push('>');
    lines.push('> -- 一次抓全 54 个 (推荐):');
    lines.push('> SELECT name, setting, unit, context, source');
    lines.push('> FROM pg_settings');
    lines.push("> WHERE name IN ('autovacuum','enable_hashjoin','work_mem',...);  -- 列表见下表 param_name 列");
    lines.push('> ```');
    lines.push('>');
    lines.push('> 拿到现值后跟 `recommended_value` (蒸馏里有的) 或 `rationales` 描述比对 → 越界即可疑。');
    lines.push('');
  }

  if (grp.metric.length) {
    lines.push(`### type=metric (${grp.metric.length} 个)`);
    lines.push('');
    lines.push(`| check_id | metric_name | collection_method | abnormal_patterns | 关联 case 数 |`);
    lines.push(`|---|---|---|---|---:|`);
    for (const c of grp.metric.sort((a, b) => a.check_id.localeCompare(b.check_id))) {
      const cm = (c.collection_method || '').replace(/\|/g, '\\|').slice(0, 160);
      const ap = (c.abnormal_patterns || '').replace(/\|/g, '\\|').slice(0, 160);
      const linkedN = c.linked_case_ids.filter(cid => gaussCaseIds.has(cid)).length;
      lines.push(`| \`${c.check_id}\` | ${(c.metric_name || '').replace(/\|/g, '\\|').slice(0, 120)} | ${cm} | ${ap} | ${linkedN} |`);
    }
    lines.push('');
  }

  if (grp.paramCV.length) {
    lines.push(`### type=parameter-current-value (${grp.paramCV.length} 个)`);
    lines.push('');
    lines.push(`| check_id | param_name | recommended_value | rationales (摘) | 关联 case 数 |`);
    lines.push(`|---|---|---|---|---:|`);
    for (const c of grp.paramCV.sort((a, b) => a.check_id.localeCompare(b.check_id))) {
      const rv = (c.recommended_value || '').replace(/\|/g, '\\|').slice(0, 120);
      const ra = (c.rationales || '').replace(/\|/g, '\\|').slice(0, 160);
      const linkedN = c.linked_case_ids.filter(cid => gaussCaseIds.has(cid)).length;
      lines.push(`| \`${c.check_id}\` | ${(c.param_name || c.metric_name || '').replace(/\|/g, '\\|').slice(0, 120)} | ${rv} | ${ra} | ${linkedN} |`);
    }
    lines.push('');
  }
  lines.push('---');
  lines.push('');
}

writeFileSync(OUT, lines.join('\n'));
console.log(`\nwrote: ${OUT}`);
console.log(`size: ${(lines.join('\n').length / 1024).toFixed(1)} KB · ${lines.length} 行`);

// ── 6. 同时输出 NDJSON (机器可读 · 给 collector 吃) ───────────────────────
const NDJSON_OUT = OUT.replace(/\.md$/, '.ndjson');
const ndjson = gaussChecks.map(c => JSON.stringify({
  check_id: c.check_id,
  type: c.type || '',
  collection_layer: c.collection_layer || '',
  metric_name: c.metric_name || '',
  param_name: c.param_name || '',
  collection_method: c.collection_method || '',
  abnormal_patterns: c.abnormal_patterns || '',
  recommended_value: c.recommended_value || '',
  rationales: c.rationales || '',
  linked_case_ids: c.linked_case_ids.filter(cid => gaussCaseIds.has(cid)),
})).join('\n') + '\n';
writeFileSync(NDJSON_OUT, ndjson);
console.log(`wrote: ${NDJSON_OUT}`);
console.log(`size: ${(ndjson.length / 1024).toFixed(1)} KB · ${gaussChecks.length} entries`);
