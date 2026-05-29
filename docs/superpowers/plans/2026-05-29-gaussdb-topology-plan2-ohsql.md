# GaussDB topology 分桶 · 计划 2(ohsql 离线 kit 侧)实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用计划 1 折进后的 build 重生 ohsql 案例库(gaussdb 按 topology 三拆),修复因 per-db 布局失效的 case-integrity 测试,并让离线 kit 端到端区分集中式/分布式:采集器按 `deploy_form` 跳无关 check + 反喂 `match-collect-to-cases` 按形态只撞相关案例桶。

**Architecture:** 案例库由计划 1 的 `build-runtime-cases-from-md.mjs` 重生(`cases/gaussdb/{common,centralized,distributed}/`)。离线 `extract-offline-checklist.mjs` 读三套子目录 + 从子目录路径反推每个 case 的 topology → 传到 check(`checklist.ndjson` 加 topology 字段)。`_build-precompiled.mjs` 把 topology inline 进 collector,collector 按 `gs_deployment()` 写出的 `deploy.txt` 跳过冲突 topology 的 check(标 `skip-topology`)。新增 `match-collect-to-cases.mjs` 按 `deploy.txt` 只读相关案例桶,出"自动命中 / 待判"两段候选。

**Tech Stack:** Node.js (纯内建, ESM .mjs),`node --test` + `tsx`,bash + python3 (collector)。仓库 `/Users/david/code/ohsql-plugin-dev`,分支 `feat/gaussdb-offline-topology-routing`。

**前置:** 计划 1 已落地(distill 仓 `feat/topology-split`:topology 字段 + 折进 build)。

**关联 spec:** `docs/superpowers/specs/2026-05-28-gaussdb-offline-topology-routing-design.md` §3-§7。

**约定:** commit 用 `qinqiangdavid <qinqiangdavid@users.noreply.github.com>` 签名;只 push origin,**绝不推 upstream**。

---

## 文件结构

| 文件 | 职责 | 动作 |
|---|---|---|
| `plugins/perf-kp-sql/data/cases/**` | 部署态案例库 | 重生:gaussdb 变 `{common,centralized,distributed}/` 子目录 |
| `plugins/perf-kp-sql/tests/cases/lib-walk-cases.mjs` | 枚举所有 per-db/topology 的 CASES/INDEX 对 | 建(共享 helper) |
| `plugins/perf-kp-sql/tests/cases/index-integrity.test.ts` | INDEX↔CASES 行号 + 全局 unique | 重写(走新布局 · 去 stale 计数 + 死 best-practice) |
| `plugins/perf-kp-sql/tests/cases/field-integrity.test.ts` | 必填字段非空 | 改:枚举改用 helper |
| `plugins/perf-kp-sql/tests/cases/golden-validity.test.ts` | golden 校验 | 改:枚举改用 helper(若引用 flat 路径) |
| `docs/offline-collect-kit/extract-offline-checklist.mjs` | 产 checklist.ndjson | 改:读三套子目录 + topology 传到 check |
| `docs/offline-collect-kit/extract-offline-checklist.test.mjs` | extract 单测 | 建:topology 继承规则 |
| `docs/offline-collect-kit/_build-precompiled.mjs` | 编译 collector | 改:inline topology + 跳过逻辑模板 |
| `docs/offline-collect-kit/collect-precompiled.{sh,py}` | 部署采集脚本 | 重生(由 _build-precompiled 产) |
| `docs/offline-collect-kit/match-collect-to-cases.mjs` | 反喂候选 | 建 |
| `docs/offline-collect-kit/match-collect-to-cases.test.mjs` | match 单测 | 建 |
| `docs/offline-collect-kit/README.md`、`HANDOFF.md` | 文档 | 改:去"(待实现)" + 加 topology 说明 |

---

## Task 1: case-integrity 测试重写为走 per-db/topology 布局

> 现状:`index-integrity` / `field-integrity` / `golden-validity` 读扁平 `data/cases/CASES.md` + `best-practice/CASES.md`(均已不存在),且硬编码 stale 计数(109/96/13/93/202)。本 task 先重写测试(此刻仍红:数据尚未重生为 topology 子目录),Task 2 重生数据后转绿。

**Files:**
- Create: `plugins/perf-kp-sql/tests/cases/lib-walk-cases.mjs`
- Modify: `plugins/perf-kp-sql/tests/cases/index-integrity.test.ts`
- Test: 自身

- [ ] **Step 1: 写共享枚举 helper**

新建 `plugins/perf-kp-sql/tests/cases/lib-walk-cases.mjs`:

```javascript
// 枚举 data/cases 下所有 (INDEX.md, CASES.md) 对 · 跨 per-db + gaussdb topology 子目录
// 排除 indices/(by-check-item 等全局反向索引 · 非 case 库)
import { readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export function walkCasePairs(dataCasesDir) {
  const pairs = [];
  function rec(dir) {
    const entries = readdirSync(dir, { withFileTypes: true });
    if (existsSync(join(dir, 'CASES.md')) && existsSync(join(dir, 'INDEX.md'))) {
      pairs.push({ dir, casesPath: join(dir, 'CASES.md'), indexPath: join(dir, 'INDEX.md') });
    }
    for (const e of entries) {
      if (e.isDirectory() && e.name !== 'indices') rec(join(dir, e.name));
    }
  }
  rec(dataCasesDir);
  return pairs;
}
```

- [ ] **Step 2: 重写 index-integrity.test.ts(去 stale 计数/死 best-practice,改走 helper)**

把 `index-integrity.test.ts` 第 78 行起的三个 describe(`案例数据完整性 · cases/`、`· best-practice/`、`· 总数对齐设计书`)整体替换为:

```typescript
import { walkCasePairs } from "./lib-walk-cases.mjs";

describe("案例数据完整性 · 全部 per-db/topology 桶", () => {
  const pairs = walkCasePairs(resolve(DATA_DIR, "cases"));

  it("至少枚举到 gaussdb 三套 topology 桶", () => {
    const dirs = pairs.map((p) => p.dir.replace(/.*\/data\/cases\//, ""));
    for (const sub of ["gaussdb/common", "gaussdb/centralized", "gaussdb/distributed"]) {
      assert.ok(dirs.includes(sub), `缺 ${sub} 桶 · 实际枚举到 ${dirs.join(", ")}`);
    }
  });

  for (const { dir, casesPath, indexPath } of walkCasePairs(resolve(DATA_DIR, "cases"))) {
    const rel = dir.replace(/.*\/data\/cases\//, "");
    it(`${rel}: INDEX 每行 case_id + 行号精确对应 CASES.md 真实 ## 头`, () => {
      const headers = parseCaseHeaders(casesPath);
      const rows = parseIndexTable(indexPath);
      for (const row of rows) {
        const caseLine = headers.get(row.case_id);
        assert.ok(caseLine !== undefined, `${rel}: case_id ${row.case_id} 在 CASES.md 无对应 ## 头`);
        assert.equal(caseLine, row.line, `${rel}: ${row.case_id} INDEX line=${row.line} 实际=${caseLine}`);
      }
    });
  }

  it("case_id 跨所有桶全局 unique", () => {
    const seen = new Map<string, string>();
    for (const { dir, casesPath } of pairs) {
      const rel = dir.replace(/.*\/data\/cases\//, "");
      for (const id of parseCaseHeaders(casesPath).keys()) {
        assert.ok(!seen.has(id), `case_id ${id} 重复出现于 ${seen.get(id)} 和 ${rel}`);
        seen.set(id, rel);
      }
    }
  });
});
```

> 注意:`parseIndexTable(indexPath)` 原签名带第二参 section 名("diagnostic-flow"/"flame-signature")。新布局每个 INDEX 是单表(per-db/topology),调用不传 section → 需确认 `parseIndexTable` 不传 section 时解析全表。若原实现强依赖 section,改 `parseIndexTable` 让第二参可选(无 section 时解析所有 `| <id> | ... | <line> |` 行)。Step 3 处理。

- [ ] **Step 3: 确保 `parseIndexTable` 支持无 section 调用**

读 `index-integrity.test.ts` 顶部 `parseIndexTable` 实现(约 line 33-65)。若它按 section header 切表,改成:第二参 `section` 为 `undefined` 时,解析文件中所有形如 `| <case_id> | ... | <line_no> |` 的数据行(跳过表头 `|---|` 与非 case 行)。保持带 section 调用的旧行为不变(向后兼容)。

- [ ] **Step 4: field-integrity.test.ts + golden-validity.test.ts 改用 helper**

`field-integrity.test.ts` 第 220-221 行:
```typescript
  ...parseCases(resolve(DATA_DIR, "cases/CASES.md")).map((c) => ({ c, src: "data/cases/CASES.md" })),
  ...parseCases(resolve(DATA_DIR, "best-practice/CASES.md")).map((c) => ({ c, src: "data/best-practice/CASES.md" })),
```
替换为(顶部加 `import { walkCasePairs } from "./lib-walk-cases.mjs";`):
```typescript
  ...walkCasePairs(resolve(DATA_DIR, "cases")).flatMap(({ casesPath, dir }) =>
    parseCases(casesPath).map((c) => ({ c, src: dir.replace(/.*\/plugins\//, "plugins/") }))),
```
`golden-validity.test.ts`:读其顶部加载逻辑,若引用 `cases/CASES.md` 或 `best-practice/`,同样改用 `walkCasePairs`;若它只读 `tests/golden/` 固定夹具(不依赖 data/cases 布局)则无需改 —— 先跑确认。

- [ ] **Step 5: 跑测试(此刻应失败 —— 数据尚未重生为 topology 子目录)**

Run: `cd /Users/david/code/ohsql-plugin-dev && npx tsx --test plugins/perf-kp-sql/tests/cases/index-integrity.test.ts 2>&1 | tail -15`
Expected: FAIL —— "缺 gaussdb/common 桶"(当前 gaussdb 还是扁平 `cases/gaussdb/CASES.md`,无 topology 子目录)。这证明测试在校验新布局,留 Task 2 转绿。

- [ ] **Step 6: commit(测试先行 · 红)**

```bash
git add plugins/perf-kp-sql/tests/cases/lib-walk-cases.mjs plugins/perf-kp-sql/tests/cases/index-integrity.test.ts plugins/perf-kp-sql/tests/cases/field-integrity.test.ts plugins/perf-kp-sql/tests/cases/golden-validity.test.ts
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "test(perf-kp-sql): case-integrity 重写为走 per-db/topology 布局(暂红 · 待数据重生)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: 用计划 1 的 build 重生 ohsql 案例库 → 测试转绿

**Files:**
- Modify(重生产物): `plugins/perf-kp-sql/data/cases/**`

- [ ] **Step 1: 跑折进后的 build(非 dry-run · 写进 ohsql)**

Run:
```bash
cd /Users/david/code/db-distill-engine-clone && \
node distill-v2/scripts/build-runtime-cases-from-md.mjs \
  --distill distill-v2/cases \
  --runtime /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql
```
Expected: stdout 末 `per-db/topology groups: _common=31 gaussdb/common=51 gaussdb/distributed=22 gaussdb/centralized=4 gaussdb-dws=120 mongodb=71` + `done. 299 cases ...`。

- [ ] **Step 2: 核对产物布局 + 旧扁平 gaussdb 文件已被替换**

Run: `find /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql/data/cases -name CASES.md | sed 's#.*/data/cases/##' | sort`
Expected: 含 `gaussdb/common/CASES.md`、`gaussdb/centralized/CASES.md`、`gaussdb/distributed/CASES.md`、`gaussdb-dws/CASES.md`、`mongodb/CASES.md`、`_common/CASES.md`、`indices/by-check-item/CASES.md`。
Run: `ls /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql/data/cases/gaussdb/CASES.md 2>&1`
Expected: No such file(旧扁平已被 topology 子目录取代)。若仍存在(build 不删旧文件),手工 `rm` 掉 `cases/gaussdb/CASES.md` `cases/gaussdb/INDEX.md`。

- [ ] **Step 3: 跑 Task 1 的测试 → 转绿**

Run: `cd /Users/david/code/ohsql-plugin-dev && npx tsx --test plugins/perf-kp-sql/tests/cases/index-integrity.test.ts plugins/perf-kp-sql/tests/cases/field-integrity.test.ts plugins/perf-kp-sql/tests/cases/golden-validity.test.ts 2>&1 | grep -E "pass |fail "`
Expected: `fail 0`。

- [ ] **Step 4: 跑全量 perf-kp-sql 测试套确认无回归**

Run: `npm run test:perf-kp-sql 2>&1 | tail -8`
Expected: 全绿(cli-ssh / cli-history 不受影响)。

- [ ] **Step 5: commit(数据重生 · 转绿)**

```bash
cd /Users/david/code/ohsql-plugin-dev
git add plugins/perf-kp-sql/data/cases
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "data(perf-kp-sql): 重生案例库 · gaussdb 按 topology 三拆(common51/dist22/cent4)

由折进后的 build-runtime 产 · 退役丢失的 split-runtime-by-db.py · case-integrity 测试转绿。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: extract-offline-checklist 读三套子目录 + topology 传到 check

**Files:**
- Modify: `docs/offline-collect-kit/extract-offline-checklist.mjs`(line 31-39 case_id set;line 274-290 ndjson 输出)
- Test: `docs/offline-collect-kit/extract-offline-checklist.test.mjs`(新建)

- [ ] **Step 1: 写失败测试(topology 继承纯函数)**

把 check 的 topology 继承逻辑抽成可测纯函数 `checkTopology(linkedTopologies)`。新建 `docs/offline-collect-kit/extract-offline-checklist.test.mjs`:

```javascript
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { checkTopology } from './extract-offline-checklist.mjs';

describe('checkTopology · 多 case 取最宽松', () => {
  it('任一 common → common', () => {
    assert.equal(checkTopology(['distributed-only', 'common']), 'common');
  });
  it('全 distributed-only → distributed-only', () => {
    assert.equal(checkTopology(['distributed-only', 'distributed-only']), 'distributed-only');
  });
  it('全 centralized-only → centralized-only', () => {
    assert.equal(checkTopology(['centralized-only']), 'centralized-only');
  });
  it('cent + dist 同现(无 common)→ common(安全默认)', () => {
    assert.equal(checkTopology(['centralized-only', 'distributed-only']), 'common');
  });
  it('空 → common', () => {
    assert.equal(checkTopology([]), 'common');
  });
});
```

- [ ] **Step 2: 跑确认失败**

Run: `cd /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql/docs/offline-collect-kit && node --test extract-offline-checklist.test.mjs`
Expected: FAIL —— `checkTopology` 未导出(注意:import 会触发 extract 主流程跑;若主流程在 import 时执行,需同 build-runtime 一样加 `IS_MAIN` guard。Step 3 一并处理)。

- [ ] **Step 3: 改 extract —— IS_MAIN guard + 读三套子目录 + case→topology 映射 + checkTopology + ndjson 加 topology**

3a. 文件顶部(import 之后)加:
```javascript
const IS_MAIN = import.meta.url === `file://${process.argv[1]}`;

export function checkTopology(linked) {
  if (!linked || linked.length === 0) return 'common';
  if (linked.includes('common')) return 'common';
  const hasCent = linked.includes('centralized-only');
  const hasDist = linked.includes('distributed-only');
  if (hasCent && hasDist) return 'common';
  if (hasDist) return 'distributed-only';
  if (hasCent) return 'centralized-only';
  return 'common';
}
```

3b. 把第 31-39 行的 case_id set 收集,改成同时建 `caseId → topology` 映射(topology 由子目录路径反推)。替换 line 31-39:
```javascript
// ── 1. 抽 gaussdb 系 case_id + 每个 case 的 topology ──────────────────────
import { readdirSync } from 'node:fs';
const gaussCaseIds = new Set();
const caseTopology = new Map();   // case_id → topology
// gaussdb 三套子目录(topology 由目录名定)
const GAUSS_SUBS = [
  ['gaussdb/common', 'common'],
  ['gaussdb/centralized', 'centralized-only'],
  ['gaussdb/distributed', 'distributed-only'],
];
for (const [sub, topo] of GAUSS_SUBS) {
  const p = `${OHSQL}/data/cases/${sub}/CASES.md`;
  const text = readFileSync(p, 'utf8');
  for (const m of text.matchAll(/^## case_id:\s*(\S+)/gm)) {
    gaussCaseIds.add(m[1]); caseTopology.set(m[1], topo);
  }
}
// gaussdb-dws 整桶 distributed-only
{
  const text = readFileSync(`${OHSQL}/data/cases/gaussdb-dws/CASES.md`, 'utf8');
  for (const m of text.matchAll(/^## case_id:\s*(\S+)/gm)) {
    gaussCaseIds.add(m[1]); caseTopology.set(m[1], 'distributed-only');
  }
}
console.log(`gaussdb 系 case_id total: ${gaussCaseIds.size}`);
```
(删除原 `import { readdirSync }` 若重复 —— 合并到顶部 import。)

3c. ndjson 输出(line 276-287)给每条 check 加 topology:
```javascript
const ndjson = gaussChecks.map(c => {
  const linkedTopos = c.linked_case_ids
    .filter(cid => gaussCaseIds.has(cid))
    .map(cid => caseTopology.get(cid) || 'common');
  return JSON.stringify({
    check_id: c.check_id,
    type: c.type || '',
    collection_layer: c.collection_layer || '',
    metric_name: c.metric_name || '',
    param_name: c.param_name || '',
    collection_method: c.collection_method || '',
    abnormal_patterns: c.abnormal_patterns || '',
    recommended_value: c.recommended_value || '',
    rationales: c.rationales || '',
    topology: checkTopology(linkedTopos),
    linked_case_ids: c.linked_case_ids.filter(cid => gaussCaseIds.has(cid)),
  });
}).join('\n') + '\n';
```

3d. 把主流程(从 `console.log(\`gaussdb 系 case_id total\`)` 之后的所有顶层执行,即 line 39 之后到文件末的渲染/写盘)用 `if (IS_MAIN) { ... }` 包住。纯函数 `checkTopology`、`isDocExample`、`normalizeForCheck` 留顶层导出/可见。
> 简化:若 guard 整段太碎,可只把"读文件 + 写文件"的执行体包进 `if (IS_MAIN)`;`checkTopology` 已在 3a 顶层导出,测试 import 时只要不触发 readFileSync 即可。

- [ ] **Step 4: 跑单测确认通过**

Run: `node --test extract-offline-checklist.test.mjs`
Expected: PASS（5 个 it 绿)。

- [ ] **Step 5: 实跑 extract 重生 checklist**

Run: `cd /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql/docs/offline-collect-kit && node extract-offline-checklist.mjs 2>&1 | tail -5`
Expected: 正常产出 `docs/gaussdb-offline-checklist.{md,ndjson}`,无 ENOENT。
Run: `head -1 ../gaussdb-offline-checklist.ndjson | node -e 'process.stdin.on("data",d=>console.log(JSON.parse(d).topology))'`
Expected: 打印一个 topology 值(common/centralized-only/distributed-only 之一)。

- [ ] **Step 6: cp 到 kit checklist.ndjson**

Run: `cp ../gaussdb-offline-checklist.ndjson checklist.ndjson`
Run: `grep -o '"topology":"[^"]*"' checklist.ndjson | sort | uniq -c`
Expected: 三类 topology 都有计数。

- [ ] **Step 7: commit**

```bash
cd /Users/david/code/ohsql-plugin-dev
git add plugins/perf-kp-sql/docs/offline-collect-kit/extract-offline-checklist.mjs plugins/perf-kp-sql/docs/offline-collect-kit/extract-offline-checklist.test.mjs plugins/perf-kp-sql/docs/gaussdb-offline-checklist.md plugins/perf-kp-sql/docs/gaussdb-offline-checklist.ndjson plugins/perf-kp-sql/docs/offline-collect-kit/checklist.ndjson
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "feat(offline-kit): extract 读三套 topology 子目录 + 每 check 继承 topology

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: _build-precompiled inline topology + collector 按 deploy_form 跳 check

**Files:**
- Modify: `docs/offline-collect-kit/_build-precompiled.mjs`(bash run_check 模板 ~line 449-520;bash 每 check emit ~line 573-577;python head ~line 624-720;python tuple emit ~line 682-687)
- Modify(重生): `docs/offline-collect-kit/collect-precompiled.{sh,py}`

- [ ] **Step 1: 改 bash run_check 模板 —— 收 topology 参数 + 跳过逻辑**

`_build-precompiled.mjs` 里 bash 模板的 `run_check()` 定义(对应 collect-precompiled.sh line 60 `local cid="$1"`)。在 `local cid="$1"` 之后插入:
```bash
  local topo="${2:-common}"
  # topology 过滤: 部署形态与 check 适用范围冲突 → 跳过(不跑 · 标 skip-topology · 可审计)
  case "$DEPLOY_FORM" in
    centralized|single-node)
      if [ "$topo" = "distributed-only" ]; then
        printf '%s\t%s\t%s\n' "$cid" "-" "skip-topology" >> "$OUTDIR/report.tsv"; cat >/dev/null; return
      fi ;;
    distributed)
      if [ "$topo" = "centralized-only" ]; then
        printf '%s\t%s\t%s\n' "$cid" "-" "skip-topology" >> "$OUTDIR/report.tsv"; cat >/dev/null; return
      fi ;;
    *) : ;;  # unknown-* → 不跳(全采 · 安全侧)
  esac
```
(`cat >/dev/null` 消费 heredoc stdin 避免管道阻塞。)

- [ ] **Step 2: 改 bash 每 check 的 run_check 调用传 topology**

`_build-precompiled.mjs` 里 bash emit(对应 collect-precompiled.sh line 577 `run_check "${c.check_id}" <<'${term}'`)。找到生成该行的模板字符串,把:
```javascript
run_check "${c.check_id}" <<'${term}'
```
改为:
```javascript
run_check "${c.check_id}" "${c.topology || 'common'}" <<'${term}'
```

- [ ] **Step 3: bash 头部加 `⚠️ topology-filter-disabled` 提示(unknown 形态)**

在 bash 模板里 `DEPLOY_FORM=$(detect_deploy_form)` 之后(collect-precompiled.sh ~line 48)加:
```bash
case "$DEPLOY_FORM" in
  unknown*) echo "⚠️ topology-filter-disabled: deploy_form=$DEPLOY_FORM · 全采(不按 topology 跳过)" >&2 ;;
esac
```

- [ ] **Step 4: 改 python —— CHECKS tuple 加 topology + 循环跳过**

4a. python tuple emit(`_build-precompiled.mjs` ~line 687):
```javascript
pyBody += `    (${JSON.stringify(c.check_id)}, ${JSON.stringify(c.name)}, ${JSON.stringify(c.collection_layer)}, ${JSON.stringify(c.method)}, ${JSON.stringify(c.topology || 'common')}),\n`;
```
4b. python 主循环(`_build-precompiled.mjs` python 模板里 `for i, (cid, name, layer, method) in enumerate(CHECKS, 1):`)改解包 + 跳过:
```python
    for i, (cid, name, layer, method, topo) in enumerate(CHECKS, 1):
        if (DEPLOY_FORM in ('centralized', 'single-node') and topo == 'distributed-only') or \
           (DEPLOY_FORM == 'distributed' and topo == 'centralized-only'):
            with open(os.path.join(OUTDIR, 'report.tsv'), 'a') as rf:
                rf.write(f'{cid}\t-\tskip-topology\n')
            continue
```
4c. python detect_deploy_form 后加 unknown 提示(对齐 bash Step 3)。

- [ ] **Step 5: 重生 collector**

Run: `cd /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql/docs/offline-collect-kit && node _build-precompiled.mjs 2>&1 | tail -3`
Expected: 重写 `collect-precompiled.sh` + `.py`,打印 auto/manual/skip 计数。

- [ ] **Step 6: 校验生成的 collector 含 topology 逻辑**

Run: `grep -c 'skip-topology' collect-precompiled.sh collect-precompiled.py`
Expected: 两文件都 ≥1。
Run: `grep -m1 'run_check' collect-precompiled.sh | grep -q '"common"\|"distributed-only"\|"centralized-only"' && echo "bash 传 topology OK"`
Expected: `bash 传 topology OK`。
Run: `COLLECT_DRYRUN=1 bash collect-precompiled.sh /tmp/dryrun-topo 2>&1 | tail -3 || true`
Expected: dry-run 跑通(无 gsql 时 detect 返回 unknown-no-gsql → 全采,不报错)。

- [ ] **Step 7: commit**

```bash
cd /Users/david/code/ohsql-plugin-dev
git add plugins/perf-kp-sql/docs/offline-collect-kit/_build-precompiled.mjs plugins/perf-kp-sql/docs/offline-collect-kit/collect-precompiled.sh plugins/perf-kp-sql/docs/offline-collect-kit/collect-precompiled.py
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "feat(offline-kit): collector 按 deploy_form 跳 topology 冲突 check(标 skip-topology)

centralized/single-node 跳 distributed-only · distributed 跳 centralized-only · unknown 全采。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: match-collect-to-cases.mjs — 反喂候选(两段输出)

**Files:**
- Create: `docs/offline-collect-kit/match-collect-to-cases.mjs`
- Test: `docs/offline-collect-kit/match-collect-to-cases.test.mjs`

- [ ] **Step 1: 写失败测试(桶选择 + 阈值比对纯函数)**

新建 `docs/offline-collect-kit/match-collect-to-cases.test.mjs`:

```javascript
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { bucketsForDeployForm, compareThreshold } from './match-collect-to-cases.mjs';

describe('bucketsForDeployForm', () => {
  it('centralized → common + centralized(不含 distributed)', () => {
    assert.deepEqual(bucketsForDeployForm('centralized').sort(),
      ['cases/gaussdb/centralized', 'cases/gaussdb/common']);
  });
  it('distributed → common + distributed', () => {
    assert.deepEqual(bucketsForDeployForm('distributed').sort(),
      ['cases/gaussdb/common', 'cases/gaussdb/distributed']);
  });
  it('unknown-detect-fail → 全部三套', () => {
    assert.equal(bucketsForDeployForm('unknown-detect-fail').length, 3);
  });
});

describe('compareThreshold · 有阈值才机械判', () => {
  it('47 > 40 → 命中', () => {
    assert.equal(compareThreshold('47', '> 40'), true);
  });
  it('30 > 40 → 不命中', () => {
    assert.equal(compareThreshold('30', '> 40'), false);
  });
  it('阈值 NULL/空 → null(不可机械判 · B 类)', () => {
    assert.equal(compareThreshold('123', 'NULL'), null);
    assert.equal(compareThreshold('123', ''), null);
  });
});
```

- [ ] **Step 2: 跑确认失败**

Run: `cd /Users/david/code/ohsql-plugin-dev/plugins/perf-kp-sql/docs/offline-collect-kit && node --test match-collect-to-cases.test.mjs`
Expected: FAIL —— 模块/函数不存在。

- [ ] **Step 3: 实现 match-collect-to-cases.mjs**

```javascript
#!/usr/bin/env node
// match-collect-to-cases.mjs · 把离线采集结果撞案例库 → 出候选(不出诊断报告)
// 按 deploy.txt 只读相关 topology 桶; 两段输出: auto-hit(有阈值机械命中) / needs-judge(阈值 NULL · 附 stdout)
// 用法: node match-collect-to-cases.mjs --collect <out-dir> --cases <data/cases/gaussdb dir>
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const IS_MAIN = import.meta.url === `file://${process.argv[1]}`;

export function bucketsForDeployForm(form) {
  if (form === 'centralized' || form === 'single-node')
    return ['cases/gaussdb/common', 'cases/gaussdb/centralized'];
  if (form === 'distributed')
    return ['cases/gaussdb/common', 'cases/gaussdb/distributed'];
  // unknown-* → 全采全撞
  return ['cases/gaussdb/common', 'cases/gaussdb/centralized', 'cases/gaussdb/distributed'];
}

// 解析阈值如 "> 40" / "< 90" / ">= 3" ; value 取 stdout 里第一个数字
// 返回 true/false(命中/不命中) 或 null(阈值不可机械比对 · B 类)
export function compareThreshold(value, threshold) {
  const t = String(threshold || '').replace(/^["'`]|["'`]$/g, '').trim();
  if (!t || t.toUpperCase() === 'NULL') return null;
  const m = t.match(/(>=|<=|>|<|=)\s*([0-9]+(?:\.[0-9]+)?)/);
  if (!m) return null;
  const num = parseFloat(String(value).match(/-?[0-9]+(?:\.[0-9]+)?/)?.[0] ?? '');
  if (Number.isNaN(num)) return null;
  const rhs = parseFloat(m[2]);
  switch (m[1]) {
    case '>': return num > rhs;  case '<': return num < rhs;
    case '>=': return num >= rhs; case '<=': return num <= rhs;
    case '=': return num === rhs; default: return null;
  }
}

if (IS_MAIN) {
  const argv = process.argv.slice(2);
  const get = (n) => { const i = argv.indexOf(`--${n}`); return i >= 0 ? argv[i + 1] : null; };
  const collectDir = resolve(get('collect'));
  const casesRoot = resolve(get('cases'));   // 指向 .../data/cases (gaussdb 在其下)
  const deployForm = existsSync(join(collectDir, 'deploy.txt'))
    ? readFileSync(join(collectDir, 'deploy.txt'), 'utf8').trim() : 'unknown-no-deploy-txt';

  const buckets = bucketsForDeployForm(deployForm);
  const autoHit = [], needsJudge = [];
  for (const rel of buckets) {
    const casesPath = join(casesRoot, rel.replace(/^cases\//, ''), 'CASES.md');
    if (!existsSync(casesPath)) continue;
    const text = readFileSync(casesPath, 'utf8');
    const blocks = text.split(/(?=^## case_id:\s*)/gm).filter(b => b.startsWith('## case_id:'));
    for (const b of blocks) {
      const caseId = (b.match(/^## case_id:\s*(\S+)/) || [])[1];
      const srcUrl = (b.match(/^- \*\*source_url\*\*:\s*(.+)$/m) || [])[1] || '';
      // 抽 step 的 abnormal_pattern_threshold + abnormal_pattern_quote
      for (const sm of b.matchAll(/abnormal_pattern_threshold:\s*(.+)/g)) {
        const threshold = sm[1].trim();
        // 找该 case 关联的采集 stdout(按 linked check → 这里简化: 用 case_id 不直接对应 stdout,
        // 真实落地按 linked_case_ids 反查 check_id 再读 stdout/<cid>.txt; 见 Step 4 集成)
        // 占位逻辑见集成测试
        if (!threshold || threshold.toUpperCase() === 'NULL') {
          needsJudge.push({ caseId, srcUrl, reason: 'threshold-null' });
        }
      }
    }
  }
  // 输出两段
  const out = { deploy_form: deployForm, buckets, auto_hit: autoHit, needs_judge: needsJudge };
  writeFileSync(join(collectDir, 'match-candidates.ndjson'),
    [...autoHit.map(x => JSON.stringify({ segment: 'auto-hit', ...x })),
     ...needsJudge.map(x => JSON.stringify({ segment: 'needs-judge', ...x }))].join('\n') + '\n');
  const md = [`# 反喂候选 · deploy_form=${deployForm}`, '',
    `撞库桶: ${buckets.join(', ')}`, '',
    `## 自动命中候选 (${autoHit.length})`, ...autoHit.map(x => `- \`${x.caseId}\` · 实测 ${x.value} ${x.op} · ${x.srcUrl}`),
    '', `## 待判候选 (${needsJudge.length} · 阈值 NULL · 附 stdout 交后续 skill 判)`,
    ...needsJudge.map(x => `- \`${x.caseId}\` · ${x.srcUrl}`)].join('\n');
  writeFileSync(join(collectDir, 'match-candidates.md'), md + '\n');
  console.log(`deploy_form=${deployForm} · 撞 ${buckets.length} 桶 · auto-hit=${autoHit.length} needs-judge=${needsJudge.length}`);
}
```
> 注:Step 3 的 IS_MAIN 块里 stdout↔case 的精确关联(按 `linked_case_ids` 反查 check_id → 读 `stdout/<cid>.txt` → 比对阈值)在 Step 4 集成测试里补全;纯函数 `bucketsForDeployForm` / `compareThreshold` 是本 task 的可测核心,先让它们绿。

- [ ] **Step 4: 跑纯函数单测确认通过**

Run: `node --test match-collect-to-cases.test.mjs`
Expected: PASS（6 个 it 绿)。

- [ ] **Step 5: 集成自测(造一个 mini out-dir + mini 案例桶,端到端撞一次)**

在 test 文件追加一个集成 it:造临时 `collect/deploy.txt=centralized` + `cases/gaussdb/{common,centralized,distributed}/CASES.md`(distributed 桶放一个含阈值的 case),跑 IS_MAIN 逻辑(用 `child_process.execFileSync('node', ['match-collect-to-cases.mjs', ...])`),断言:
  - `match-candidates.ndjson` 生成;
  - distributed 桶的 case **未**出现在候选(集中式不撞 distributed);
  - common/centralized 桶的 case 才可能出现。
Run: `node --test match-collect-to-cases.test.mjs`
Expected: PASS。

- [ ] **Step 6: commit**

```bash
cd /Users/david/code/ohsql-plugin-dev
git add plugins/perf-kp-sql/docs/offline-collect-kit/match-collect-to-cases.mjs plugins/perf-kp-sql/docs/offline-collect-kit/match-collect-to-cases.test.mjs
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "feat(offline-kit): match-collect-to-cases 反喂候选 · 按 deploy_form 只撞相关桶 · 两段输出

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: README + HANDOFF 更新

**Files:**
- Modify: `docs/offline-collect-kit/README.md`、`docs/offline-collect-kit/HANDOFF.md`

- [ ] **Step 1: README "拿回结果之后" 段去掉"(待实现)"**

把 README.md line 116-125 那段 `# (待实现) 反喂工具` 改成真实用法:
```markdown
## 拿回结果之后

把 `out-*/` 整个目录拷回本地,跑反喂(按 deploy.txt 自动只撞相关 topology 桶):

​```bash
node match-collect-to-cases.mjs \
    --collect out-<host>-<date>/ \
    --cases plugins/perf-kp-sql/data/cases
​```

产出 `out-*/match-candidates.{md,ndjson}` 两段:`自动命中候选`(有阈值机械命中)+ `待判候选`
(阈值 NULL · 附 stdout)。诊断报告仍由 perf-kp-sql skill 的 Phase 4/5 出。
```

- [ ] **Step 2: README 加 topology 过滤说明**

在 README "行为" 表(method 判定)后加一段:
```markdown
## 部署形态过滤(topology)

collector 用 `gs_deployment()` 自识别部署形态写 `deploy.txt`,并据此跳过无关 check:
- `centralized` / `single-node`:跳 `distributed-only`(CN/DN/redistribute/DWS 等)· 采 common + centralized-only
- `distributed`:跳 `centralized-only` · 采 common + distributed-only
- `unknown-*`:不跳(全采)· 报告头标 `⚠️ topology-filter-disabled`

被跳的 check 在 `report.tsv` 标 `status=skip-topology`(可审计 · 不悄悄消失)。
```

- [ ] **Step 3: HANDOFF.md 更新 §6.3「真做 deploy form 分桶」为已落地**

把 HANDOFF.md §6.3(标"status 层面无差异 · 需对比 stdout")改为:已落地 case 级 topology 分桶(distill 加字段 + collector 按 deploy_form 跳 + match 按桶撞),引用 spec/计划路径。

- [ ] **Step 4: commit**

```bash
cd /Users/david/code/ohsql-plugin-dev
git add plugins/perf-kp-sql/docs/offline-collect-kit/README.md plugins/perf-kp-sql/docs/offline-collect-kit/HANDOFF.md
git -c user.name=qinqiangdavid -c user.email=qinqiangdavid@users.noreply.github.com commit -m "docs(offline-kit): README/HANDOFF 去'(待实现)' + 加 topology 过滤说明

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## 收尾验证(全 Task 完成后)

- [ ] 全量测试绿:
  ```bash
  cd /Users/david/code/ohsql-plugin-dev && npm run test:perf-kp-sql 2>&1 | tail -5
  node --test plugins/perf-kp-sql/docs/offline-collect-kit/*.test.mjs 2>&1 | grep -E "pass |fail "
  ```
- [ ] 端到端(可选 · 在 `gauss_new` 507 集中式):scp `collect-precompiled.sh` → `source env` → 跑 → 看 `report.tsv` 有 `skip-topology` 行(distributed-only 被跳)+ `deploy.txt=centralized` → 拷回跑 `match-collect-to-cases.mjs` → `match-candidates.md` 不含 distributed-only case。
- [ ] `git log --oneline` 确认计划 2 各 commit 都在;`git remote -v` 确认 upstream 推 URL 是 `no_push_to_upstream_use_origin`。

## 评审(交付前 · 异模型)

按用户 CLAUDE.md:计划 1+2 代码完成后走异模型 code review(Opus 写 → Sonnet/Codex 审):
`superpowers:code-reviewer` 子代理(语义/架构) + `codex:rescue`(安全/边界)双路交叉,问题全修复后复跑方算交付。
