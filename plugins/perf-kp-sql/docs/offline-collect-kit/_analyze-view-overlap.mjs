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
const sh = readFileSync(AUTO_SH, 'utf8');
{
  const re = /run_check\s+"([^"]+)"\s+<<'(EOF_[A-Z0-9_]+)'\n([\s\S]*?)\n\2/g;
  let mm;
  while ((mm = re.exec(sh))) {
    const cid = mm[1];
    const body = mm[3];
    // 找所有 FROM <view> 出现
    const viewRe = /\b(?:FROM|JOIN)\s+([a-zA-Z_][a-zA-Z0-9_.]*)/gi;
    let vm;
    const seenInThisCmd = new Set();
    while ((vm = viewRe.exec(body))) {
      const view = vm[1];
      if (!isTrustedView(view)) continue;
      const key = canonView(view);
      if (seenInThisCmd.has(key)) continue;  // 一条命令多次提到同视图 (alias / self-join) 只算 1
      seenInThisCmd.add(key);
      if (!autoUsage.has(key)) autoUsage.set(key, []);
      autoUsage.get(key).push({ cid, snippet: body.trim().slice(0, 200).replace(/\s+/g, ' ') });
    }
  }
}

// ── parse manual-audit.md: 每个 "## chk-XXX" 块下的 [sql]/[view] 派生命令 ──
const manualUsage = new Map(); // view → [{cid, snippet, kind}]
const md = readFileSync(MANUAL_MD, 'utf8');
{
  // split 成每个 chk 一段
  const sections = md.split(/^## /m).slice(1);  // 第 0 段是总览,跳过
  for (const sec of sections) {
    const cidMatch = sec.match(/^(chk-[^\s·]+)/);
    if (!cidMatch) continue;
    const cid = cidMatch[1];
    // 提 - `[sql]` `xxx` / `[view]` `xxx` 行
    const cmdRe = /^\s*-\s+`\[(sql|view|sql-stub)\]`\s+`([^`]+)`/gm;
    let cm;
    const seenInThisCmd = new Set();
    while ((cm = cmdRe.exec(sec))) {
      const kind = cm[1];
      const cmd = cm[2];
      // 抽 FROM <view>
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

// ── 生成报告 ────────────────────────────────────────────────────────────
let out = `# 视图查询重叠分析 (view-overlap-analysis.md)

> 本地工程文件 · 由 \`_analyze-view-overlap.mjs\` 扫 \`collect-precompiled.sh\` (auto inline) +
> \`manual-audit.md\` (manual 派生) 出。
>
> **目的**: 找出"查同一视图 N 次"的 hot view,验证"在环境查一次,本地过滤/聚合"
> 这条优化路径的收益。**完整版 (precompiled / manual-audit) 不动**,这只是只读分析。

## 总览

- 命中的可信视图 (\`pg_*\` / \`pgxc_*\` / \`gs_*\` / \`dbe_perf.*\` / 已知 GaussDB 表): **${stats.length}** 个
- 合并前总查询次数 (auto + manual 派生): **${totalRoundtrips}** 次
- 合并后理论查询次数 (每视图 1 次): **${afterMerge}** 次
- 可省 round-trip: **${saved}** 次 (${savePct}%)

### Hot view (≥ ${HOT_THRESHOLD} 次命中) — 强合并候选

| 视图 | 总次数 | auto 内 | manual 派生 | 合并方案 |
|---|---:|---:|---:|---|
${hotViews.map(s => `| \`${s.view}\` | ${s.total} | ${s.auto} | ${s.manual} | 拉 \`SELECT * FROM ${s.view}\` 一次 · 本地起 ${s.total} 个 filter/agg |`).join('\n')}

### Cold view (< ${HOT_THRESHOLD} 次) — 合并收益低,留作单查

| 视图 | 总次数 | auto / manual |
|---|---:|---|
${coldViews.map(s => `| \`${s.view}\` | ${s.total} | ${s.auto} / ${s.manual} |`).join('\n')}

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
