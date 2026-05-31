#!/usr/bin/env node
// match-collect-to-cases.mjs · 把离线采集结果撞案例库 → 出候选(不出诊断报告)
//
// 设计:check 在 checklist.ndjson 里已带 topology + linked_case_ids + abnormal_patterns。
// 按 deploy.txt 的部署形态只认相关 topology 的 check;两段输出:
//   auto-hit    · 有阈值且采集值越界 → 机械命中候选(带"实测值 vs 阈值"证据)
//   needs-judge · 阈值 NULL/不可机械比 → 原样转交(附 stdout)· 交后续 skill 的 LLM/人判
// 诊断报告仍由 perf-kp-sql skill 的 Phase 4/5 出(本工具只出候选)。
//
// 用法: node match-collect-to-cases.mjs --collect <out-dir> [--checklist <checklist.ndjson>] [--cases <data/cases>]
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const IS_MAIN = import.meta.url === `file://${process.argv[1]}`;

// 部署形态 → 允许的 topology 集(与 collector 跳过逻辑、spec §5 一致)
export function allowedTopologies(form) {
  if (form === 'centralized' || form === 'single-node') return ['common', 'centralized-only'];
  if (form === 'distributed') return ['common', 'distributed-only'];
  return ['common', 'centralized-only', 'distributed-only']; // unknown-* → 全认
}

// 从案例桶建 caseId → topology 映射(gaussdb 三套子目录 + gaussdb-dws 整桶 distributed-only)
// 用于二次过滤:common check 可能 link 到 distributed case,集中式下这些 case 不该进候选
export function loadCaseTopology(dataCasesDir) {
  const map = new Map();
  const buckets = [
    ['gaussdb/common', 'common'],
    ['gaussdb/centralized', 'centralized-only'],
    ['gaussdb/distributed', 'distributed-only'],
    ['gaussdb-dws', 'distributed-only'],
  ];
  for (const [sub, topo] of buckets) {
    const p = join(dataCasesDir, sub, 'CASES.md');
    if (!existsSync(p)) continue;
    for (const m of readFileSync(p, 'utf8').matchAll(/^## case_id:\s*(\S+)/gm)) map.set(m[1], topo);
  }
  return map;
}

// 采集值 vs 阈值: 返回 true/false(命中/不命中) 或 null(阈值不可机械比 · B 类)
// 阈值形如 "> 40" / "avg_time > 3ms" / "< 90%" / ">= 3"
export function compareThreshold(value, threshold) {
  const t = String(threshold || '').replace(/^["'`]|["'`]$/g, '').trim();
  if (!t || t.toUpperCase() === 'NULL') return null;
  const m = t.match(/(>=|<=|>|<|=)\s*([0-9]+(?:\.[0-9]+)?)/);
  if (!m) return null;
  const vm = String(value).match(/-?[0-9]+(?:\.[0-9]+)?/);
  if (!vm) return null;
  const num = parseFloat(vm[0]);
  const rhs = parseFloat(m[2]);
  switch (m[1]) {
    case '>': return num > rhs;
    case '<': return num < rhs;
    case '>=': return num >= rhs;
    case '<=': return num <= rhs;
    case '=': return num === rhs;
    default: return null;
  }
}

// 从 abnormal_patterns 字符串取第一个候选阈值(checklist.ndjson 里是 JSON 数组内容串)
export function firstThreshold(abnormalPatterns) {
  const s = String(abnormalPatterns || '');
  // 形如  "avg_time > 3ms","..."  或  > 40,< 90
  const parts = s.split(',');
  for (const p of parts) {
    const t = p.replace(/^["'`\s]+|["'`\s]+$/g, '');
    if (/(>=|<=|>|<|=)\s*[0-9]/.test(t)) return t;
  }
  return parts.length ? parts[0].replace(/^["'`\s]+|["'`\s]+$/g, '') : '';
}

if (IS_MAIN) {
  const argv = process.argv.slice(2);
  const get = (n) => { const i = argv.indexOf(`--${n}`); return i >= 0 ? argv[i + 1] : null; };
  const collectDir = resolve(get('collect'));
  const HERE = dirname(fileURLToPath(import.meta.url));
  const checklistPath = resolve(get('checklist') || join(HERE, 'checklist.ndjson'));
  const casesDir = resolve(get('cases') || join(HERE, '..', '..', 'data', 'cases'));

  const deployForm = existsSync(join(collectDir, 'deploy.txt'))
    ? readFileSync(join(collectDir, 'deploy.txt'), 'utf8').trim() : 'unknown-no-deploy-txt';
  const allowed = new Set(allowedTopologies(deployForm));
  const caseTopo = loadCaseTopology(casesDir);
  // 按 case 级 topology 过滤 linked_case_ids:common check 可能 link 到 distributed case,
  // 集中式下这些 case 必须剔除(未知 case 缺省 common · 保守保留)
  const allowedCases = (ids) => (ids || []).filter(id => allowed.has(caseTopo.get(id) || 'common'));

  const checks = readFileSync(checklistPath, 'utf8').trim().split('\n').filter(Boolean).map(l => JSON.parse(l));

  const autoHit = [], needsJudge = [];
  for (const c of checks) {
    const topo = c.topology || 'common';
    if (!allowed.has(topo)) continue;                 // 形态不相关的 check 不撞(集中式不撞 distributed-only)
    const stdoutPath = join(collectDir, `${c.check_id}.txt`);
    if (!existsSync(stdoutPath)) continue;             // 未采集到(被跳/未跑)
    const linkedCases = allowedCases(c.linked_case_ids);
    if (linkedCases.length === 0) continue;            // 该 check 的相关 case 在本形态下全被剔 → 不出候选
    const value = readFileSync(stdoutPath, 'utf8').trim();
    const threshold = firstThreshold(c.abnormal_patterns);
    const cmp = compareThreshold(value, threshold);
    const base = { check_id: c.check_id, topology: topo, linked_case_ids: linkedCases };
    if (cmp === true) {
      autoHit.push({ ...base, value: value.slice(0, 120), threshold });
    } else if (cmp === null) {
      needsJudge.push({ ...base, threshold: threshold || 'NULL', stdout_excerpt: value.slice(0, 200) });
    }
    // cmp === false → 采到了但未越界 · 不进候选
  }

  const ndjson = [
    ...autoHit.map(x => JSON.stringify({ segment: 'auto-hit', ...x })),
    ...needsJudge.map(x => JSON.stringify({ segment: 'needs-judge', ...x })),
  ].join('\n') + '\n';
  writeFileSync(join(collectDir, 'match-candidates.ndjson'), ndjson);

  const md = [
    `# 反喂候选 · deploy_form=${deployForm}`, '',
    `允许 topology: ${[...allowed].join(', ')} · 撞 check ${checks.filter(c => allowed.has(c.topology || 'common')).length}/${checks.length}`, '',
    `## 自动命中候选 (${autoHit.length} · 有阈值机械命中)`,
    ...autoHit.map(x => `- \`${x.check_id}\` 实测 \`${x.value}\` 越界 \`${x.threshold}\` → case: ${x.linked_case_ids.join(', ')}`),
    '',
    `## 待判候选 (${needsJudge.length} · 阈值 NULL · 附 stdout · 交后续 skill 判)`,
    ...needsJudge.map(x => `- \`${x.check_id}\` → case: ${x.linked_case_ids.join(', ')}\n  stdout: ${x.stdout_excerpt.replace(/\n/g, ' ')}`),
  ].join('\n') + '\n';
  writeFileSync(join(collectDir, 'match-candidates.md'), md);

  console.log(`deploy_form=${deployForm} · 允许 ${[...allowed].join('/')} · auto-hit=${autoHit.length} needs-judge=${needsJudge.length}`);
}
