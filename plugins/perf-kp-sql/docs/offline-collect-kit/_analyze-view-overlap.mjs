#!/usr/bin/env node
// 扫 collect-precompiled.sh (auto inline 命令) + manual-audit.md (manual 派生命令),
// 按 FROM <view> 聚合,找出"查同一视图 N 次"的 hot view,出合并候选清单。
//
// 思路:不动现有 collector 行为 (完整版保留),只产出"如果合并能省多少 round-trip"
// 的离线分析。后续如果决定合并 → 写一个新的 collector 模式 (一次 SELECT * +
// 本地 filter/agg)。
//
// 用法 (本地一次性):
//   node _analyze-view-overlap.mjs
// 输出:
//   view-overlap-analysis.md

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const AUTO_SH = join(HERE, 'collect-precompiled.sh');
const MANUAL_MD = join(HERE, 'manual-audit.md');
const NDJSON = join(HERE, 'checklist.ndjson');
const OUT = join(HERE, 'view-overlap-analysis.md');

// ── 已知 "可信视图/系统表" 白名单 (排除文档示例表 t1 / public.test / xxx) ─────
// 用 prefix + 显式列表 · 不在这个范围的都不算 (避免 case 文档里 t1/t2/public.test 噪音)
const TRUSTED_PREFIXES = ['pg_', 'pgxc_', 'gs_', 'dbe_perf.', 'PGXC_', 'GS_', 'DBE_PERF.'];
const TRUSTED_EXACT = new Set([
  'statement_history', 'table_distribution',
  // 也保留这些 (lowercase 形式)
]);
function isTrustedView(v) {
  const lo = v.toLowerCase();
  if (TRUSTED_EXACT.has(lo)) return true;
  return TRUSTED_PREFIXES.some(p => v.startsWith(p) || lo.startsWith(p.toLowerCase()));
}
// pg_catalog 是默认 schema · 查 pg_catalog.pg_class 跟 pg_class 实际是同一张表 · 合并 key
function canonView(v) {
  return v.toLowerCase().replace(/^pg_catalog\./, '');
}

// ── 解析 ndjson 拿 check_id → metric_name 映射 (展示用) ──────────────────────
const checks = readFileSync(NDJSON, 'utf8').trim().split('\n').map(l => JSON.parse(l));
const idToName = new Map();
for (const c of checks) {
  idToName.set(c.check_id, c.metric_name || c.param_name || '(unnamed)');
}

// ── parse auto inline commands: 找 run_check "<cid>" <<'EOF_X' ... EOF_X ───
const autoUsage = new Map(); // view → [{cid, snippet}]
const autoGuc  = new Map();  // guc_name → [cid]   (SHOW xxx)
const autoOs   = new Map();  // os_cmd_head → [cid]
const autoExplain = [];      // [{cid, snippet}] EXPLAIN 类
const autoDocTable = [];     // [{cid, table}]  引用文档示例表 (t1 / customer / lineitem 等) 应剔除
const sh = readFileSync(AUTO_SH, 'utf8');
{
  const re = /run_check\s+"([^"]+)"\s+<<'(EOF_[A-Z0-9_]+)'\n([\s\S]*?)\n\2/g;
  let mm;
  while ((mm = re.exec(sh))) {
    const cid = mm[1];
    const body = mm[3];
    // 找所有 FROM/JOIN <view> 出现
    const viewRe = /\b(?:FROM|JOIN)\s+([a-zA-Z_][a-zA-Z0-9_.]*)/gi;
    let vm;
    const seenInThisCmd = new Set();
    while ((vm = viewRe.exec(body))) {
      const view = vm[1];
      const key = canonView(view);
      if (seenInThisCmd.has(key)) continue;
      seenInThisCmd.add(key);
      if (isTrustedView(view)) {
        if (!autoUsage.has(key)) autoUsage.set(key, []);
        autoUsage.get(key).push({ cid, snippet: body.trim().slice(0, 200).replace(/\s+/g, ' ') });
      } else {
        autoDocTable.push({ cid, table: view });
      }
    }
    // SHOW guc 提取
    const gucRe = /\bSHOW\s+([a-zA-Z_][a-zA-Z0-9_]*)\b/gi;
    let gm;
    while ((gm = gucRe.exec(body))) {
      const g = gm[1].toLowerCase();
      if (!autoGuc.has(g)) autoGuc.set(g, []);
      autoGuc.get(g).push(cid);
    }
    // OS 命令头提取 (top/iostat/df/free/vmstat/sar/netstat/perf/gstack/pidstat)
    const firstWord = (body.trim().match(/^(\S+)/) || [])[1] || '';
    const osHead = firstWord.match(/^(top|iostat|df|free|vmstat|sar|netstat|pidstat|perf|gstack|jstack|mpstat|nstat|ss|ps|cat)$/i);
    if (osHead) {
      const k = osHead[1].toLowerCase();
      if (!autoOs.has(k)) autoOs.set(k, []);
      autoOs.get(k).push(cid);
    }
    // EXPLAIN 类
    if (/^\s*EXPLAIN\b/i.test(body.trim())) {
      autoExplain.push({ cid, snippet: body.trim().slice(0, 100).replace(/\s+/g, ' ') });
    }
  }
}

// ── parse manual-audit.md: 每个 "## chk-XXX" 块下的 [sql]/[view]/[guc]/[os] 派生 ──
const manualUsage = new Map(); // view → [{cid, snippet, kind}]
const manualGuc  = new Map();  // guc_name → [cid]
const manualOs   = new Map();  // os_cmd_head → [cid]
const manualStub = [];         // [sql-stub] EXPLAIN 模板 (不可合并)
const md = readFileSync(MANUAL_MD, 'utf8');
{
  const sections = md.split(/^## /m).slice(1);
  for (const sec of sections) {
    const cidMatch = sec.match(/^(chk-[^\s·]+)/);
    if (!cidMatch) continue;
    const cid = cidMatch[1];
    const cmdRe = /^\s*-\s+`\[(sql|view|sql-stub|guc|os)\]`\s+`([^`]+)`/gm;
    let cm;
    const seenInThisCmd = new Set();
    while ((cm = cmdRe.exec(sec))) {
      const kind = cm[1];
      const cmd = cm[2];
      // FROM/JOIN 视图
      if (kind === 'sql' || kind === 'view') {
        const viewRe = /\b(?:FROM|JOIN)\s+([a-zA-Z_][a-zA-Z0-9_.]*)/gi;
        let vm;
        while ((vm = viewRe.exec(cmd))) {
          const view = vm[1];
          if (!isTrustedView(view)) continue;
          const key = canonView(view);
          const dedupKey = `${cid}|${key}`;
          if (seenInThisCmd.has(dedupKey)) continue;
          seenInThisCmd.add(dedupKey);
          if (!manualUsage.has(key)) manualUsage.set(key, []);
          manualUsage.get(key).push({ cid, kind, snippet: cmd });
        }
        // SHOW guc 也算 (混在 sql kind 里的)
        const gucRe = /\bSHOW\s+([a-zA-Z_][a-zA-Z0-9_]*)\b/gi;
        let gm;
        while ((gm = gucRe.exec(cmd))) {
          const g = gm[1].toLowerCase();
          const dedupKey = `${cid}|guc:${g}`;
          if (seenInThisCmd.has(dedupKey)) continue;
          seenInThisCmd.add(dedupKey);
          if (!manualGuc.has(g)) manualGuc.set(g, []);
          manualGuc.get(g).push(cid);
        }
      }
      if (kind === 'guc') {
        const gm = cmd.match(/\bSHOW\s+([a-zA-Z_][a-zA-Z0-9_]*)\b/i);
        if (gm) {
          const g = gm[1].toLowerCase();
          if (!manualGuc.has(g)) manualGuc.set(g, []);
          manualGuc.get(g).push(cid);
        }
      }
      if (kind === 'os') {
        const head = (cmd.trim().match(/^(\S+)/) || [])[1] || '';
        const osHead = head.match(/^(top|iostat|df|free|vmstat|sar|netstat|pidstat|perf|gstack|jstack|mpstat|nstat|ss|ps|cat|find|grep|ls|echo)$/i);
        if (osHead) {
          const k = osHead[1].toLowerCase();
          if (!manualOs.has(k)) manualOs.set(k, []);
          manualOs.get(k).push(cid);
        }
      }
      if (kind === 'sql-stub') {
        manualStub.push({ cid, snippet: cmd });
      }
    }
  }
}

// ── 合并 auto + manual → 全局 hot view 统计 ──────────────────────────────
const allViews = new Set([...autoUsage.keys(), ...manualUsage.keys()]);
const stats = [];
for (const v of allViews) {
  const autoN = (autoUsage.get(v) || []).length;
  const manN = (manualUsage.get(v) || []).length;
  stats.push({ view: v, total: autoN + manN, auto: autoN, manual: manN });
}
stats.sort((a, b) => b.total - a.total || a.view.localeCompare(b.view));

// 总 round-trip 数 (合并前 auto + manual 派生)
const totalRoundtrips = stats.reduce((s, r) => s + r.total, 0);
// 合并后:每个视图只查 1 次 = stats.length 次 round-trip
const afterMerge = stats.length;
const saved = totalRoundtrips - afterMerge;
const savePct = (saved / totalRoundtrips * 100).toFixed(1);

// hot view 阈值
const HOT_THRESHOLD = 3;
const hotViews = stats.filter(s => s.total >= HOT_THRESHOLD);
const coldViews = stats.filter(s => s.total < HOT_THRESHOLD);

// ── GUC + OS 维度统计 ────────────────────────────────────────────────────
const allGucs = new Set([...autoGuc.keys(), ...manualGuc.keys()]);
const gucBefore = [...autoGuc.values(), ...manualGuc.values()].reduce((s, a) => s + a.length, 0);
const gucAfter = 1;  // 合并为 SELECT name, setting FROM pg_settings 一把查
const gucSaved = gucBefore - gucAfter;

const allOs = new Set([...autoOs.keys(), ...manualOs.keys()]);
const osBefore = [...autoOs.values(), ...manualOs.values()].reduce((s, a) => s + a.length, 0);
const osAfter = allOs.size;  // 每个独立 OS 命令头跑 1 次
const osSaved = osBefore - osAfter;

const grandBefore = totalRoundtrips + gucBefore + osBefore + manualStub.length;
const grandAfter = afterMerge + gucAfter + osAfter + manualStub.length;
const grandSaved = grandBefore - grandAfter;

// ── 生成报告 ────────────────────────────────────────────────────────────
let out = `# 命令重叠分析全景版 (view-overlap-analysis.md)

> 本地工程文件 · 由 \`_analyze-view-overlap.mjs\` 扫 \`collect-precompiled.sh\` (auto inline) +
> \`manual-audit.md\` (manual 派生) 出。
>
> **目的**: 找出"重复采集"的合并空间,验证"在环境查一次,本地过滤/聚合"路径的收益。
> **完整版 (precompiled / manual-audit) 不动**,这只是只读分析。

## 总账 (404 命令的去向)

\`\`\`
404 = 180 auto inline + 224 manual 派生

180 auto:
  ${[...autoUsage.values()].reduce((s, a) => s + a.length, 0)} 引用可信视图 (pg/pgxc/gs/dbe_perf)  ← 纳入视图合并
  ${autoDocTable.length} 引用文档示例表 (t1/customer/lineitem 等)  ⚠️ 应从 ndjson 剔除
  ${[...autoGuc.values()].reduce((s, a) => s + a.length, 0)} SHOW guc                                ← 纳入 GUC 合并
  ${autoExplain.length} EXPLAIN (固定 SQL · 跑得通)                        ← 不可合并 · 独立
  其余 ≈ OS shell 杂项 / SET 等

224 manual 派生:
  ${[...manualUsage.values()].reduce((s, a) => s + a.length, 0)} sql/view 含 FROM trusted             ← 纳入视图合并
  ${[...manualGuc.values()].reduce((s, a) => s + a.length, 0)} SHOW guc ([guc] + 混在 [sql] 里)      ← 纳入 GUC 合并
  ${[...manualOs.values()].reduce((s, a) => s + a.length, 0)} OS 命令 [os]                          ← 纳入 OS 去重
  ${manualStub.length} [sql-stub] EXPLAIN <你的 SQL> 模板                ← 不可合并 · 每条独立
\`\`\`

## 三维合并总收益

| 维度 | 合并前 | 合并后 | 省 | 占总省 |
|---|---:|---:|---:|---:|
| **视图查询** (SELECT * FROM v) | ${totalRoundtrips} | ${afterMerge} | ${saved} | ${(saved/grandSaved*100).toFixed(0)}% |
| **GUC 参数** (SHOW x → 1 把查 pg_settings) | ${gucBefore} | ${gucAfter} | ${gucSaved} | ${(gucSaved/grandSaved*100).toFixed(0)}% |
| **OS 命令** (top/iostat/df 按命令头去重) | ${osBefore} | ${osAfter} | ${osSaved} | ${(osSaved/grandSaved*100).toFixed(0)}% |
| **EXPLAIN stub** (每条 SQL 独立) | ${manualStub.length} | ${manualStub.length} | 0 | 0% |
| **合计** | **${grandBefore}** | **${grandAfter}** | **${grandSaved}** | 100% |

合并后总命令数: \`auto 不变 180\` + \`视图 ${afterMerge}\` + \`GUC 1\` + \`OS ${osAfter}\` (去重后) = 大幅压缩。

注: auto 180 里很多命令本身已经是单次执行(不在三维合并范围),仍照跑;合并维度只针对 manual 派生命令重叠 + auto 内部 SHOW/视图重叠。

## 视图维度

### Hot view (≥ ${HOT_THRESHOLD} 次命中) — 强合并候选

| 视图 | 总次数 | auto 内 | manual 派生 | 合并方案 |
|---|---:|---:|---:|---|
${hotViews.map(s => `| \`${s.view}\` | ${s.total} | ${s.auto} | ${s.manual} | 拉 \`SELECT * FROM ${s.view}\` 一次 · 本地起 ${s.total} 个 filter/agg |`).join('\n')}

### Cold view (< ${HOT_THRESHOLD} 次) — 合并收益低,留作单查

| 视图 | 总次数 | auto / manual |
|---|---:|---|
${coldViews.map(s => `| \`${s.view}\` | ${s.total} | ${s.auto} / ${s.manual} |`).join('\n')}

---

## GUC 维度

合并前: **${gucBefore}** 次 \`SHOW xxx\` 散落在 auto + manual 派生中,涉及 **${allGucs.size}** 个独立 GUC。
合并后: **1** 次 \`SELECT name, setting, source, reset_val FROM pg_settings\` 一把拉全量,本地按 GUC 名挑出对应 check。

省 round-trip: **${gucSaved}** 次。

### 命中频次

| GUC | 总次数 | auto | manual |
|---|---:|---:|---:|
${[...allGucs].map(g => {
  const a = (autoGuc.get(g) || []).length;
  const m = (manualGuc.get(g) || []).length;
  return { g, a, m, t: a + m };
}).sort((a, b) => b.t - a.t || a.g.localeCompare(b.g))
  .map(r => `| \`${r.g}\` | ${r.t} | ${r.a} | ${r.m} |`).join('\n')}

---

## OS 命令维度

合并前: **${osBefore}** 次 OS 命令调用,涉及 **${allOs.size}** 个独立命令头。
合并后: 每个独立命令头跑 **1** 次,本地按 cid 引用。

省 round-trip: **${osSaved}** 次。

### 命令头分布

| 命令头 | 总次数 | auto | manual |
|---|---:|---:|---:|
${[...allOs].map(o => {
  const a = (autoOs.get(o) || []).length;
  const m = (manualOs.get(o) || []).length;
  return { o, a, m, t: a + m };
}).sort((a, b) => b.t - a.t || a.o.localeCompare(b.o))
  .map(r => `| \`${r.o}\` | ${r.t} | ${r.a} | ${r.m} |`).join('\n')}

**注意**: 同一命令头(如 \`top\`)在不同 check 里可能用不同参数(\`top -b -n 1\` vs \`top -Hp <pid>\`)。
真合并时需进一步看参数 — 这里只是上限估算。

---

## 副产物 · ⚠️ auto 里 ${autoDocTable.length} 条引用文档示例表 (应从 ndjson 剔除)

distill 阶段把 GaussDB 文档里的 EXPLAIN 案例代码块 (\`SELECT * FROM t1\` / \`SELECT * FROM customer\` 类) 抓进了 check.collection_method,部署到真客户 db 跑会全部 \`relation does not exist\`。

这跟合并无关 — **是源数据问题**,正确做法是从 \`checklist.ndjson\` 源头剔除这些 check(它们不是真采集动作,是文档展示)。

### 引用的示例表

| 表名 | 命中次数 |
|---|---:|
${(() => {
  const cnt = new Map();
  for (const r of autoDocTable) cnt.set(r.table, (cnt.get(r.table) || 0) + 1);
  return [...cnt].sort((a, b) => b[1] - a[1]).map(([t, n]) => `| \`${t}\` | ${n} |`).join('\n');
})()}

### 涉及的 check_id (前 30)

| check_id | 引用表 |
|---|---|
${autoDocTable.slice(0, 30).map(r => `| \`${r.cid}\` | \`${r.table}\` |`).join('\n')}

${autoDocTable.length > 30 ? `... 还有 ${autoDocTable.length - 30} 条 (略)` : ''}

→ TODO: 在 \`extract-offline-checklist.mjs\` 加过滤规则,识别"method 含未知 schema 表 + 起始词 EXPLAIN" 模式,标 \`is_example=true\` 不进 collector。

---

## 合并方案设计 (建议)

新增 collector 模式 \`collect-merged.{sh,py}\`,跟现有 \`collect-precompiled.\` 并列:

\`\`\`
                                          ┌── auto 180 条 (不变 · 多数已是单次)
collect-precompiled.{sh,py} (完整版) ──────┤
                                          └── manual 153 → 派生 224 (跨视图重叠多)
                                                      ↓
                                       提取 hot view ${hotViews.length} 个
                                                      ↓
collect-merged.{sh,py} (优化版) ─── 1. 服务器端: SELECT * FROM <hot view> 跑 ${hotViews.length} 次,落 raw/
                                  2. 本地: post-process.{mjs,py} 读 raw/,
                                           按 check_id 的 filter/agg 派生
                                           出 ${hotViews.reduce((s, r) => s + r.total, 0)} 个 check 的结果
\`\`\`

### 收益 vs 成本

| 维度 | 完整版 (当前) | 合并版 |
|---|---|---|
| 服务器端 gsql 调用 | ${totalRoundtrips}+180 ≈ ${totalRoundtrips + 180} 次 | ${hotViews.length} (hot SELECT *) + 180 (auto) + ${coldViews.reduce((s, r) => s + r.total, 0)} (cold 派生) = ${hotViews.length + 180 + coldViews.reduce((s, r) => s + r.total, 0)} 次 |
| 拉回数据量 | 每次窄查 · 小 | 每 hot 视图全表 · 大 (但每个视图只 1 份) |
| 现场延迟 | gsql 启动 ×N | gsql 启动 ×${hotViews.length + 180 + coldViews.reduce((s, r) => s + r.total, 0)} |
| 本地处理 | 无 (现场出结果) | 需 post-process 脚本读 raw/ + 派生 check 结果 |
| 数据一致性 | 跨视图非快照一致 | hot 视图内一致 (一次 SELECT *) · 跨视图仍非快照 |

**适用场景**:

1. **现场 round-trip 慢** (跨网延迟 / gsql 启动重) → 合并版省启动
2. **想要多个 check 在同一时刻数据快照** (例如 \`pg_stat_activity\` 多 check 应基于同一秒) → 合并版强一致
3. **数据回传到本地做 ad-hoc 二次分析** → 合并版的 raw/ 比派生结果更原始,二次分析友好

**不适用**:

1. 视图量大 (\`statement_history\` 单次 SELECT * 可能 GB 级) → 仍需 LIMIT / WHERE
2. 客户内网 SCP 慢 → 拉小派生结果 < 拉全表 raw

---

## Hot view 详细命中清单

下面对每个 hot view 列出所有命中的 check_id + 各自怎么用 (snippet),便于设计 post-process 派生逻辑.

`;

for (const s of hotViews) {
  out += `### \`${s.view}\` · ${s.total} 次\n\n`;
  const auto = autoUsage.get(s.view) || [];
  const man = manualUsage.get(s.view) || [];
  if (auto.length) {
    out += `**auto inline (${auto.length})**:\n\n`;
    for (const u of auto) {
      out += `- \`${u.cid}\` · ${idToName.get(u.cid) || ''}\n`;
      out += `  - snippet: \`${u.snippet.slice(0, 120)}${u.snippet.length > 120 ? '…' : ''}\`\n`;
    }
    out += '\n';
  }
  if (man.length) {
    out += `**manual 派生 (${man.length})**:\n\n`;
    for (const u of man) {
      out += `- \`${u.cid}\` · ${idToName.get(u.cid) || ''}\n`;
      out += `  - [${u.kind}] \`${u.snippet}\`\n`;
    }
    out += '\n';
  }
  out += '---\n\n';
}

out += `## 下一步 (建议 · 不在本次范围)

1. 设计 \`raw-snapshot\` 模式: 给 collector 加 \`COLLECT_MODE=raw\` env,跑时只对上面 ${hotViews.length} 个 hot view 做 \`SELECT * FROM v\` 落 \`raw/<view>.tsv\`
2. 写 \`post-process.mjs\`: 读 \`raw/\` · 按 check_id 的 filter/agg 规则 (\`hot-view-recipes.json\`,可手写或从 manual-audit 派生命令反推) 派生 ${hotViews.reduce((s, r) => s + r.total, 0)} 个 check 结果
3. 现有 \`collect-precompiled\` 保留 (单查模式 · 完整版),两套并存
4. 在 README 里加 "什么时候用哪个" 决策矩阵
`;

writeFileSync(OUT, out);
console.log(`wrote: ${OUT}`);
console.log(`  视图: ${stats.length} · hot (≥${HOT_THRESHOLD}): ${hotViews.length} · cold: ${coldViews.length}`);
console.log(`  合并前 round-trip: ${totalRoundtrips} · 合并后: ${afterMerge} · 可省 ${saved} (${savePct}%)`);
