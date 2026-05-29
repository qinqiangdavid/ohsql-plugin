# GaussDB topology 分桶 · 计划 1(distill 侧)实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 distill 仓给每个 case 加 `topology` 字段(权威源),并把 db 拆分 + gaussdb topology 三拆折进 committed `build-runtime-cases-from-md.mjs`,使案例库可从入库代码端到端复现。

**Architecture:** `topology` 字段在 distill `.md` 字段表里(LLM 蒸馏时填,存量用确定性 backfill 脚本回填)。`lib-distill-parse.mjs` 解析该字段。`build-runtime-cases-from-md.mjs` 按 `c.db` 写 `cases/<db>/`,gaussdb 内按 `c.topology` 写 `common/centralized/distributed/` 子目录;退役已丢失的 `split-runtime-by-db.py`。

**Tech Stack:** Node.js (纯内建模块, ESM .mjs),`node --test` 测试。仓库 `/Users/david/code/db-distill-engine-clone`。

**关联 spec:** `ohsql-plugin-dev/docs/superpowers/specs/2026-05-28-gaussdb-offline-topology-routing-design.md` §2、§3、§7。

**约定:** 所有 commit 用 `qinqiangdavid <qinqiangdavid@users.noreply.github.com>` 签名,message 中文。本仓 origin=`db-distill-engine-dev`,只 push origin。

---

## 文件结构

| 文件 | 职责 | 动作 |
|---|---|---|
| `distill-v2/scripts/lib-distill-parse.mjs` | distill .md 解析 + 共享纯函数 | 改:解析 `topology` 字段 + 加 `classifyTopology()` 纯函数 |
| `distill-v2/scripts/lib-distill-parse.test.mjs` | 共享库单测 | 建:`classifyTopology` + 解析测试 |
| `distill-v2/scripts/build-runtime-cases-from-md.mjs` | distill → runtime 案例库 build | 改:渲染 topology 字段 + 折进 per-db / gaussdb topology 三拆 |
| `distill-v2/scripts/build-runtime.test.mjs` | build 渲染/拆分单测 | 建:per-db 分流 + topology 子拆 + 并集完整性 |
| `distill-v2/scripts/backfill-topology.mjs` | 给存量 distill .md 回填 topology 行 | 建 |
| `distill-v2/PROMPT-cases.md` | 蒸馏 PROMPT(字段 schema) | 改:加 topology 字段定义 + 分类规则 |
| `distill-v2/cases/gaussdb/diagnostic-flow/*.md`、`gaussdb-dws/diagnostic-flow/*.md` | 存量 case | 改:backfill 脚本插入 topology 行 |

---

## Task 1: `classifyTopology()` 纯函数 + 解析 topology 字段

**Files:**
- Modify: `distill-v2/scripts/lib-distill-parse.mjs`(line 65 字段正则;line 56-63 case 对象)
- Test: `distill-v2/scripts/lib-distill-parse.test.mjs`(新建)

- [ ] **Step 1: 写失败测试**

新建 `distill-v2/scripts/lib-distill-parse.test.mjs`:

```javascript
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { classifyTopology } from './lib-distill-parse.mjs';

describe('classifyTopology', () => {
  it('gaussdb-dws 桶恒 distributed-only', () => {
    assert.equal(classifyTopology('任意文本', 'gaussdb-dws'), 'distributed-only');
  });
  it('命中分布式信号且无集中式信号 → distributed-only', () => {
    assert.equal(classifyTopology('自定义函数 VOLATILE 不下推,CN 上做 HASH JOIN', 'gaussdb'), 'distributed-only');
    assert.equal(classifyTopology('分布键选择不当致 DN 间数据倾斜', 'gaussdb'), 'distributed-only');
  });
  it('命中集中式信号且无分布式信号 → centralized-only', () => {
    assert.equal(classifyTopology('集中式部署主备 redo 回放跟不上', 'gaussdb'), 'centralized-only');
  });
  it('无任一信号(引擎无关) → common', () => {
    assert.equal(classifyTopology('work_mem 过小导致 Hash/Sort 算子落盘', 'gaussdb'), 'common');
    assert.equal(classifyTopology('未收集统计信息导致执行计划选错', 'gaussdb'), 'common');
  });
  it('集中式+分布式信号同现(MIXED)→ common(安全默认)', () => {
    assert.equal(classifyTopology('集中式场景下 CN/DN 重分布', 'gaussdb'), 'common');
  });
  it('非 gaussdb 引擎(mongodb)→ common', () => {
    assert.equal(classifyTopology('WiredTiger cache 不足', 'mongodb'), 'common');
  });
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd /Users/david/code/db-distill-engine-clone && node --test distill-v2/scripts/lib-distill-parse.test.mjs`
Expected: FAIL —— `classifyTopology` 未导出(SyntaxError / undefined）。

- [ ] **Step 3: 实现 `classifyTopology`**

在 `lib-distill-parse.mjs` 末尾(`checkChainCompleteness` 之后)追加:

```javascript
// ── topology 分类 ─────────────────────────────────────────────────────────
// 三值: common | centralized-only | distributed-only
// 规则(与 spec §2.1 一致):
//   1. db === 'gaussdb-dws' → distributed-only (MPP 本质分布式)
//   2. 仅 gaussdb 桶做信号判定; 其它 db 一律 common
//   3. 命中分布式信号 && 无集中式信号 → distributed-only
//   4. 命中集中式信号 && 无分布式信号 → centralized-only
//   5. 其余(含两信号同现的 MIXED 边界)→ common (安全默认)
const DIST_SIGNALS = /\bCN\b|\bDN\b|REDISTRIBUTE|[Rr]edistribut|[Bb]roadcast|[Ss]treaming|分布列|分布键|倾斜|\bskew\b|下推|partialpush|shippable|PGXC|pgxc|gs_om|cm_ctl|\bDWS\b|\bdws\b|广播|重分布|木桶/;
const CENT_SIGNALS = /集中式|单节点|single.?node|主备/;

export function classifyTopology(text, db) {
  if (db === 'gaussdb-dws') return 'distributed-only';
  if (db !== 'gaussdb') return 'common';
  const s = String(text || '');
  const hasDist = DIST_SIGNALS.test(s);
  const hasCent = CENT_SIGNALS.test(s);
  if (hasDist && !hasCent) return 'distributed-only';
  if (hasCent && !hasDist) return 'centralized-only';
  return 'common';
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `node --test distill-v2/scripts/lib-distill-parse.test.mjs`
Expected: PASS（6 个 it 全绿)。

- [ ] **Step 5: 让 `parseDistillMd` 解析 topology 字段(存量字段表已 backfill 后能读到)**

`lib-distill-parse.mjs` line 65 的字段正则当前为:
```javascript
    for (const m of b.matchAll(/^\|\s*(title|engine|symptom_category|case_pattern|source_anchor|source_heading)\s*\|\s*([^|\n]+?)\s*\|$/gm)) {
```
改成在 group 里加 `topology`:
```javascript
    for (const m of b.matchAll(/^\|\s*(title|engine|symptom_category|case_pattern|topology|source_anchor|source_heading)\s*\|\s*([^|\n]+?)\s*\|$/gm)) {
```
并在 case 对象构造处(line 56-63 的 `const c = {...}` 之后、`for (const m of b.matchAll...` 之前)加 topology 默认值兜底。在 line 63 `};` 之后插入:
```javascript
    c.topology = 'common';   // 默认; 下方字段表若有 topology 行会覆盖
```

- [ ] **Step 6: 给解析加测试(追加到 lib-distill-parse.test.mjs)**

```javascript
import { parseDistillMd } from './lib-distill-parse.mjs';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

describe('parseDistillMd · topology', () => {
  it('字段表含 topology 行 → 读出该值', () => {
    const dir = mkdtempSync(join(tmpdir(), 'distill-test-'));
    const f = join(dir, 'gaussdb', 'diagnostic-flow', 't.md');
    mkdirSync(join(dir, 'gaussdb', 'diagnostic-flow'), { recursive: true });
    writeFileSync(f, [
      '---', 'source_url: http://x', '---', '',
      '## case_id: `gaussdb-x-01`', '',
      '| 字段 | 值 |', '|---|---|',
      '| title | t |', '| engine | gaussdb |',
      '| symptom_category | cpu-high |', '| case_pattern | core-perf-diagnosis |',
      '| topology | distributed-only |', '| source_heading | h |', '',
      '#### description (逐字)', '> sym', '',
      '#### step_no 1', '| 字段 | 值 |', '|---|---|', '| metric_name | m |', '',
      '#### non_parameter_causes', '##### cause 1', '| 字段 | 值 |', '|---|---|', '| cause_type | x |',
    ].join('\n'));
    const cases = parseDistillMd(f);
    assert.equal(cases[0].topology, 'distributed-only');
  });
  it('字段表无 topology 行 → 默认 common', () => {
    const dir = mkdtempSync(join(tmpdir(), 'distill-test-'));
    const f = join(dir, 'gaussdb', 'diagnostic-flow', 't.md');
    mkdirSync(join(dir, 'gaussdb', 'diagnostic-flow'), { recursive: true });
    writeFileSync(f, [
      '---', 'source_url: http://x', '---', '',
      '## case_id: `gaussdb-y-01`', '',
      '| 字段 | 值 |', '|---|---|', '| title | t |', '| engine | gaussdb |', '',
    ].join('\n'));
    assert.equal(parseDistillMd(f)[0].topology, 'common');
  });
});
```
顶部补 import:`import { mkdirSync } from 'node:fs';`(与已有 import 合并)。

- [ ] **Step 7: 跑测试确认通过**

Run: `node --test distill-v2/scripts/lib-distill-parse.test.mjs`
Expected: PASS（全部 it 绿)。

- [ ] **Step 8: commit**

```bash
cd /Users/david/code/db-distill-engine-clone
git add distill-v2/scripts/lib-distill-parse.mjs distill-v2/scripts/lib-distill-parse.test.mjs
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "feat(distill): lib 加 classifyTopology + 解析 topology 字段

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: backfill 脚本 — 给存量 distill .md 回填 topology 行

**Files:**
- Create: `distill-v2/scripts/backfill-topology.mjs`
- Modify(运行产物): `distill-v2/cases/gaussdb/diagnostic-flow/*.md`、`distill-v2/cases/gaussdb-dws/diagnostic-flow/*.md`

- [ ] **Step 1: 写脚本**

新建 `distill-v2/scripts/backfill-topology.mjs`:

```javascript
#!/usr/bin/env node
// backfill-topology.mjs · 给存量 distill .md 的每个 case 字段表插入 topology 行
// 用 classifyTopology(blockText, db) 确定性判定; 已有 topology 行则按 --force 决定是否覆盖
// 用法: node distill-v2/scripts/backfill-topology.mjs [--dry-run] [--force]
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { walkMd, classifyTopology } from './lib-distill-parse.mjs';

const argv = process.argv.slice(2);
const DRY = argv.includes('--dry-run');
const FORCE = argv.includes('--force');
const ROOT = resolve('distill-v2/cases');

// 只处理 gaussdb + gaussdb-dws 的 diagnostic-flow(其它 db topology 恒 common,字段表不写也由解析兜底)
const files = walkMd(ROOT, p =>
  p.includes('/diagnostic-flow/') &&
  (p.includes('/gaussdb/') || p.includes('/gaussdb-dws/')));

let touched = 0, blocks = 0;
for (const f of files) {
  const db = f.includes('/gaussdb-dws/') ? 'gaussdb-dws' : 'gaussdb';
  const text = readFileSync(f, 'utf8');
  // 按 case 块切(保留分隔)
  const parts = text.split(/(?=^## case_id:\s*`)/gm);
  let changed = false;
  const out = parts.map(block => {
    if (!block.startsWith('## case_id:')) return block;
    blocks++;
    const topo = classifyTopology(block, db);
    const hasTopo = /^\|\s*topology\s*\|/m.test(block);
    if (hasTopo && !FORCE) return block;
    if (hasTopo && FORCE) {
      changed = true;
      return block.replace(/^\|\s*topology\s*\|[^\n]*\|$/m, `| topology | ${topo} |`);
    }
    // 无 topology 行: 插在 case_pattern 行之后(没有则插在 symptom_category 之后)
    const anchor = /^(\|\s*case_pattern\s*\|[^\n]*\|)$/m.test(block) ? /^(\|\s*case_pattern\s*\|[^\n]*\|)$/m
                 : /^(\|\s*symptom_category\s*\|[^\n]*\|)$/m;
    if (!anchor.test(block)) return block;  // 无锚点(异常)跳过
    changed = true;
    return block.replace(anchor, `$1\n| topology | ${topo} |`);
  }).join('');
  if (changed) {
    touched++;
    if (!DRY) writeFileSync(f, out);
    console.log(`${DRY ? '[dry] ' : ''}${f}`);
  }
}
console.log(`\n${touched} files touched · ${blocks} case blocks scanned${DRY ? ' (dry-run)' : ''}`);
```

- [ ] **Step 2: dry-run 看分类分布**

Run: `cd /Users/david/code/db-distill-engine-clone && node distill-v2/scripts/backfill-topology.mjs --dry-run`
Expected: 列出将改的文件 + 末行 `N files touched · ~120 case blocks scanned (dry-run)`。无写盘。

- [ ] **Step 3: 实跑 backfill**

Run: `node distill-v2/scripts/backfill-topology.mjs`
Expected: 写盘,列出被改文件。

- [ ] **Step 4: 抽查分类正确性**

Run: `grep -A1 'volatile-func-not-pushed\|data-skew\|distribution-key' distill-v2/cases/gaussdb/diagnostic-flow/*.md | grep -B1 topology | head`
Expected: 这些分布式 case 的 topology 行为 `distributed-only`。
Run: `grep -l 'work-mem-spill\|missing-analyze' distill-v2/cases/gaussdb/diagnostic-flow/*.md | head -1 | xargs grep topology`
Expected: `| topology | common |`。
Run: `grep -h topology distill-v2/cases/gaussdb-dws/diagnostic-flow/*.md | sort -u`
Expected: 只有 `| topology | distributed-only |`。

- [ ] **Step 5: commit**

```bash
git add distill-v2/scripts/backfill-topology.mjs distill-v2/cases/gaussdb distill-v2/cases/gaussdb-dws
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "feat(distill): backfill 脚本 + 回填存量 gaussdb/dws case 的 topology 字段

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: build-runtime 渲染 topology + 折进 per-db / gaussdb topology 三拆

**Files:**
- Modify: `distill-v2/scripts/build-runtime-cases-from-md.mjs`
  - line 164-177 `topFields`(加 topology 渲染)
  - line 261-267 `renderCasesFile`(头部带 db 名)
  - line 269-296 `renderCasesIndex`(配套路径参数化)
  - line 532-533、557-568(分流写盘)
- Test: `distill-v2/scripts/build-runtime.test.mjs`(新建)

- [ ] **Step 1: 写失败测试(分流逻辑抽成纯函数 `groupCasesForOutput` 后可测)**

新建 `distill-v2/scripts/build-runtime.test.mjs`:

```javascript
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { groupCasesForOutput } from './build-runtime-cases-from-md.mjs';

const sample = [
  { case_id: 'gaussdb-a', db: 'gaussdb', topology: 'common' },
  { case_id: 'gaussdb-b', db: 'gaussdb', topology: 'distributed-only' },
  { case_id: 'gaussdb-c', db: 'gaussdb', topology: 'centralized-only' },
  { case_id: 'mongo-a', db: 'mongodb', topology: 'common' },
  { case_id: 'dws-a', db: 'gaussdb-dws', topology: 'distributed-only' },
];

describe('groupCasesForOutput', () => {
  const groups = groupCasesForOutput(sample);
  const byPath = Object.fromEntries(groups.map(g => [g.relPath, g]));

  it('gaussdb 按 topology 拆三套子目录', () => {
    assert.deepEqual(byPath['cases/gaussdb/common'].cases.map(c => c.case_id), ['gaussdb-a']);
    assert.deepEqual(byPath['cases/gaussdb/distributed'].cases.map(c => c.case_id), ['gaussdb-b']);
    assert.deepEqual(byPath['cases/gaussdb/centralized'].cases.map(c => c.case_id), ['gaussdb-c']);
  });
  it('mongodb / gaussdb-dws 扁平(无 topology 子目录)', () => {
    assert.deepEqual(byPath['cases/mongodb'].cases.map(c => c.case_id), ['mongo-a']);
    assert.deepEqual(byPath['cases/gaussdb-dws'].cases.map(c => c.case_id), ['dws-a']);
  });
  it('每组带 db 名 label(渲染头部用)', () => {
    assert.equal(byPath['cases/gaussdb/common'].label, 'gaussdb/common');
    assert.equal(byPath['cases/mongodb'].label, 'mongodb');
  });
  it('并集 = 原全集 · 无丢失无重复', () => {
    const all = groups.flatMap(g => g.cases.map(c => c.case_id)).sort();
    assert.deepEqual(all, sample.map(c => c.case_id).sort());
  });
});
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd /Users/david/code/db-distill-engine-clone && node --test distill-v2/scripts/build-runtime.test.mjs`
Expected: FAIL —— 现 `build-runtime-cases-from-md.mjs` 顶层即执行(import 即跑主流程),且未导出 `groupCasesForOutput`。实际表现为:import 触发主流程 → `--runtime 必填` 检查 `process.exit(2)`,测试进程异常退出 / 报 `groupCasesForOutput is not a function`。两者都说明需要 Step 3d 的 `IS_MAIN` guard + 导出纯函数。

> ⚠️ 注意:`build-runtime-cases-from-md.mjs` 现为顶层即执行的脚本(import 即跑主流程,且 `--runtime` 必填会 `process.exit(2)`)。为可测,必须把主流程用 `import.meta.url === \`file://${process.argv[1]}\`` guard 包住,只导出纯函数。Step 3d 处理。

- [ ] **Step 3: 实现 `groupCasesForOutput` + 改渲染 + guard 主流程**

3a. 在 `topFields`(line 164-177)中 `case_pattern` 之后插入 topology 渲染。把:
```javascript
    ['case_pattern', c.case_pattern || 'core-perf-diagnosis'],
```
改为(其后加一行):
```javascript
    ['case_pattern', c.case_pattern || 'core-perf-diagnosis'],
    ['topology', c.topology || 'common'],
```

3b. `renderCasesFile`(line 261)+ `renderCasesIndex`(line 269)加 `label` 参数。改签名与头部:
```javascript
function renderCasesFile(cases, label) {
  const head = label ? `${label}, ${cases.length} cases` : `${cases.length} cases`;
  const lines = ['<!-- ============ Diagnostic-Flow (' + head + ') ============ -->', ''];
  for (const c of cases) lines.push(renderRuntimeCase(c));
  return lines.join('\n');
}
```
`renderCasesIndex(cases, casesText)` → `renderCasesIndex(cases, casesText, label)`,把 line 284 `> 配套: cases/CASES.md` 改为 `> 配套: ${label || 'cases'}/CASES.md`,line 282 数据源行保持。

3c. 在 `mergeByCaseId` 之后(line 77 后)加纯函数:
```javascript
// ── 输出分组: per-db; gaussdb 内按 topology 三拆 ──────────────────────────
export function groupCasesForOutput(cases) {
  const byKey = new Map();   // relPath → { relPath, label, cases }
  const TOPO_DIR = { 'common': 'common', 'centralized-only': 'centralized', 'distributed-only': 'distributed' };
  for (const c of cases) {
    const db = c.db || c.database || '_common';
    let relPath, label;
    if (db === 'gaussdb') {
      const sub = TOPO_DIR[c.topology] || 'common';
      relPath = `cases/gaussdb/${sub}`;
      label = `gaussdb/${sub}`;
    } else {
      relPath = `cases/${db}`;
      label = db;
    }
    if (!byKey.has(relPath)) byKey.set(relPath, { relPath, label, cases: [] });
    byKey.get(relPath).cases.push(c);
  }
  return [...byKey.values()];
}
```

3d. 把主流程(从 line ~360 `console.log(\`distill: ...\`)` 到文件末)用 guard 包住,使 import 不触发执行。在主流程前加:
```javascript
const IS_MAIN = import.meta.url === `file://${process.argv[1]}`;
if (IS_MAIN) {
  // ... 原 Step 1~6 主流程 ...
}
```
(把原 line 360-555 整体缩进进 `if (IS_MAIN) {}` 块。)

3e. 把原 Step 6 写盘段(line 532-568)替换为分流写盘:
```javascript
  // Step 6: 渲染 + 分流写盘
  const groups = groupCasesForOutput(merged);
  for (const g of groups) {
    const casesText = renderCasesFile(g.cases, g.label);
    const indexText = renderCasesIndex(g.cases, casesText, g.relPath.replace(/^cases\//, ''));
    writeOut(`${g.relPath}/CASES.md`, casesText);
    writeOut(`${g.relPath}/INDEX.md`, indexText);
  }
  console.log(`per-db/topology groups: ${groups.map(g => `${g.label}=${g.cases.length}`).join(' ')}`);

  // 全局跨 db 索引(不分流)
  const checkItemsText = renderCheckItemsFile(metricChecks, paramChecks);
  const checkItemsIndexText = renderCheckItemsIndex(metricChecks, paramChecks, checkItemsText);
  writeOut('cases/indices/by-check-item/CASES.md', checkItemsText);
  writeOut('cases/indices/by-check-item/INDEX.md', checkItemsIndexText);
  writeOut('cases/indices/by-source-url.json', nlmJson);
```
(删除原 line 532-533 的 `casesFileText`/`casesIndexText` 顶层赋值 —— 它们已移进分流循环;`checkItemsText` 等保留。)

- [ ] **Step 4: 跑单测确认通过**

Run: `node --test distill-v2/scripts/build-runtime.test.mjs`
Expected: PASS（4 个 it 绿)。

- [ ] **Step 5: dry-run 跑整个 build,核对产物布局**

Run: `node distill-v2/scripts/build-runtime-cases-from-md.mjs --distill distill-v2/cases --runtime /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql --dry-run`
Expected: stdout 含 `per-db/topology groups: gaussdb/common=N gaussdb/distributed=M gaussdb/centralized=K mongodb=... gaussdb-dws=... _common=...`;产物落 `os.tmpdir()/build-runtime-out/`。
Run: `find "$(node -e 'console.log(require("os").tmpdir())')/build-runtime-out/cases" -name CASES.md | sort`
Expected: 含 `cases/gaussdb/common/CASES.md`、`cases/gaussdb/centralized/CASES.md`、`cases/gaussdb/distributed/CASES.md`、`cases/mongodb/CASES.md`、`cases/gaussdb-dws/CASES.md`、`cases/_common/CASES.md`。

- [ ] **Step 6: 核对 gaussdb 头部带 db/topology label**

Run: `head -1 "$(node -e 'console.log(require("os").tmpdir())')/build-runtime-out/cases/gaussdb/distributed/CASES.md"`
Expected: `<!-- ============ Diagnostic-Flow (gaussdb/distributed, N cases) ============ -->`。

- [ ] **Step 7: commit**

```bash
git add distill-v2/scripts/build-runtime-cases-from-md.mjs distill-v2/scripts/build-runtime.test.mjs
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "feat(distill): build-runtime 折进 per-db + gaussdb topology 三拆 · 退役 split-runtime-by-db.py

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: PROMPT-cases.md 加 topology 字段定义 + 分类规则(给未来蒸馏)

**Files:**
- Modify: `distill-v2/PROMPT-cases.md`(line 112-126 字段位置段;line 182-187 字段提取表)

- [ ] **Step 1: 在字段表样例(line 119-126)的 `case_pattern` 行后加 topology 行**

把样例块:
```markdown
| case_pattern | core-perf-diagnosis / fault-management |
| source_heading | ... |
```
改为:
```markdown
| case_pattern | core-perf-diagnosis / fault-management |
| topology | common / centralized-only / distributed-only |
| source_heading | ... |
```

- [ ] **Step 2: 在 line 112 `### case_pattern 字段在 .md 中的位置` 段之后,加新章节**

```markdown
### topology 字段 · 部署形态适用范围(仅 gaussdb 需判,其它 db 一律 common)

每条 case 标 `topology`,三值:
- `distributed-only`:仅分布式/MPP 有意义。信号:CN/DN、REDISTRIBUTE/broadcast/streaming、
  分布列/分布键、倾斜/skew、下推/partialpush/shippable、PGXC、gs_om/cm_ctl、DWS。
  **整个 gaussdb-dws 桶恒为 distributed-only**。
- `centralized-only`:仅集中式/单节点有意义。信号:集中式、单节点/single-node、主备。
- `common`:引擎无关(优化器/GUC/OS 层),以及集中式+分布式信号同现的 MIXED 边界。

**安全默认**:边界与歧义一律归 `common`(集中式上多采一条无关指标的成本 < 漏采一条相关指标)。
存量 case 由 `scripts/backfill-topology.mjs` 用 `lib-distill-parse.classifyTopology()` 确定性回填,
规则与本节一致。
```

- [ ] **Step 3: 在字段提取表(line 184-187 附近,`case_pattern` 类字段说明处)补一行**

在 `symptom_category` enum 行(line 187)之后加:
```markdown
| `topology` | enum | `common` / `centralized-only` / `distributed-only`(仅 gaussdb 需判,见上方「topology 字段 · 部署形态适用范围」段;其它 db 恒 common) |
```

- [ ] **Step 4: commit**

```bash
git add distill-v2/PROMPT-cases.md
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "docs(distill): PROMPT-cases 加 topology 字段定义 + 分类规则

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## 收尾验证(全 Task 完成后)

- [ ] 跑全部新测试:`node --test distill-v2/scripts/lib-distill-parse.test.mjs distill-v2/scripts/build-runtime.test.mjs` → 全绿。
- [ ] 实跑 build(非 dry-run)写进 ohsql:
  `node distill-v2/scripts/build-runtime-cases-from-md.mjs --distill distill-v2/cases --runtime /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql`
  —— **这一步会改 ohsql 仓数据,属计划 2 范畴**;计划 1 只在 dry-run 验证,实写留给计划 2(连同 ohsql 侧测试重写一起做,避免 ohsql 仓里数据先于测试改动而红)。
- [ ] `git log --oneline -5` 确认 4 个 commit 都在,且未 push upstream。

## 计划 1 → 计划 2 衔接

计划 1 产出:distill 仓有 topology 字段 + 可复现的 per-db/topology build。
计划 2(另起文档)做 ohsql 侧:重跑 build 写入数据 + 重写 3 个失效的 case-integrity 测试(改为枚举 per-db + gaussdb topology 子目录)+ 离线 kit 的 extract/collector/match 改造。
