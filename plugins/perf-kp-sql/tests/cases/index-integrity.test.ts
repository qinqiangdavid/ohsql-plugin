// 案例数据完整性测试(per-db / gaussdb topology 布局)
//
// 数据布局: data/cases/<db>/{INDEX,CASES}.md,gaussdb 再按 topology 拆
//   gaussdb/{common,centralized,distributed}/{INDEX,CASES}.md。
// 用 walkCasePairs 枚举所有桶,逐桶验证:
//   1. 枚举到 gaussdb 三套 topology 桶
//   2. 每桶 INDEX 每行 case_id + 行号 精确对应 CASES.md 真实 ## 头
//   3. 每桶 INDEX 行数 = CASES.md ## 头数
//   4. case_id 跨所有桶全局 unique
//
// 这些是 SKILL.md Phase 2.3 / Phase 3.B Read offset+limit 的前置 invariant。

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { walkCasePairs } from "./lib-walk-cases.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = resolve(HERE, "../..");
const DATA_DIR = resolve(PLUGIN_ROOT, "data");

interface IndexRow {
  case_id: string;
  line: number;
}

function readLines(path: string): string[] {
  return readFileSync(path, "utf8").split("\n");
}

// 解析 INDEX.md 里 markdown 表格 · 抽 case_id + 行号 列
function parseIndexTable(indexPath: string, expectedSection?: string): IndexRow[] {
  const lines = readLines(indexPath);
  const rows: IndexRow[] = [];
  let inSection = !expectedSection;
  let inTable = false;

  for (const line of lines) {
    if (expectedSection && line.startsWith("## ")) {
      inSection = line.includes(expectedSection);
      inTable = false;
      continue;
    }
    if (!inSection) continue;
    if (line.startsWith("|---")) {
      inTable = true;
      continue;
    }
    if (!inTable) continue;
    if (!line.startsWith("|")) {
      inTable = false;
      continue;
    }
    // 解析 | col1 | col2 | ... | 行号(数字)|
    const cols = line.split("|").map((c) => c.trim()).filter((c) => c.length > 0);
    if (cols.length < 2) continue;
    const lineNum = Number(cols[cols.length - 1]);
    if (!Number.isInteger(lineNum)) continue;
    rows.push({ case_id: cols[0], line: lineNum });
  }
  return rows;
}

// 拿 CASES.md 里所有 ## case_id 头部 · 返回 { case_id → line(1-based) }
function parseCaseHeaders(casesPath: string): Map<string, number> {
  const lines = readLines(casesPath);
  const map = new Map<string, number>();
  const re = /^## case_id:\s*(\S+)\s*$/;
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(re);
    if (m) map.set(m[1], i + 1);
  }
  return map;
}

const CASE_PAIRS = walkCasePairs(resolve(DATA_DIR, "cases"));
const relOf = (dir: string) => dir.replace(/.*\/data\/cases\//, "");

describe("案例数据完整性 · 全部 per-db/topology 桶", () => {
  it("枚举到 gaussdb 三套 topology 桶", () => {
    const dirs = CASE_PAIRS.map((p) => relOf(p.dir));
    for (const sub of ["gaussdb/common", "gaussdb/centralized", "gaussdb/distributed"]) {
      assert.ok(dirs.includes(sub), `缺 ${sub} 桶 · 实际枚举到 ${dirs.join(", ")}`);
    }
  });

  for (const { dir, casesPath, indexPath } of CASE_PAIRS) {
    const rel = relOf(dir);
    describe(`桶 ${rel}`, () => {
      const headers = parseCaseHeaders(casesPath);
      const rows = parseIndexTable(indexPath); // 单表 per-db/topology · 无 section

      it(`INDEX 每行 case_id + 行号精确对应 CASES.md 真实 ## 头`, () => {
        for (const row of rows) {
          const caseLine = headers.get(row.case_id);
          assert.ok(caseLine !== undefined, `${rel}: case_id ${row.case_id} 在 CASES.md 无对应 ## 头`);
          assert.equal(caseLine, row.line, `${rel}: ${row.case_id} INDEX line=${row.line} 实际=${caseLine}`);
        }
      });

      it(`INDEX 行数 = CASES.md ## 头数`, () => {
        assert.equal(rows.length, headers.size, `${rel}: INDEX ${rows.length} 行 vs CASES ${headers.size} 头`);
      });
    });
  }

  it("case_id 跨所有桶全局 unique", () => {
    const seen = new Map<string, string>();
    for (const { dir, casesPath } of CASE_PAIRS) {
      const rel = relOf(dir);
      for (const id of parseCaseHeaders(casesPath).keys()) {
        assert.ok(!seen.has(id), `case_id ${id} 重复出现于 ${seen.get(id)} 和 ${rel}`);
        seen.set(id, rel);
      }
    }
  });
});

describe("Flame-Signature 反向索引完整性 · by-flame-signature/", () => {
  const casesPath = resolve(DATA_DIR, "cases/indices/by-flame-signature/CASES.md");
  const indexPath = resolve(DATA_DIR, "cases/indices/by-flame-signature/INDEX.md");
  const headers = parseCaseHeaders(casesPath);
  const rows = parseIndexTable(indexPath);

  it("至少有若干 flame signature(sanity)", () => {
    assert.ok(headers.size >= 10, `flame signature 数 ${headers.size} 过少`);
  });

  it("INDEX 每行 case_id + 行号精确对应 CASES.md 真实 ## 头", () => {
    for (const row of rows) {
      const caseLine = headers.get(row.case_id);
      assert.ok(caseLine !== undefined, `flame signature ${row.case_id} 在 CASES.md 无对应 ## 头`);
      assert.equal(caseLine, row.line, `${row.case_id} INDEX line=${row.line} 实际=${caseLine}`);
    }
  });

  it("INDEX 行数 = CASES.md ## 头数", () => {
    assert.equal(rows.length, headers.size, `INDEX ${rows.length} 行 vs CASES ${headers.size} 头`);
  });

  it("每条 signature 都有非空 pattern_regex(火焰图路径命根子)", () => {
    const text = readLines(casesPath).join("\n");
    const blocks = text.split(/(?=^## case_id:)/m).filter((b) => b.startsWith("## case_id:"));
    const missing: string[] = [];
    for (const b of blocks) {
      const id = (b.match(/^## case_id:\s*(\S+)/) || [])[1];
      const pr = b.match(/^- \*\*pattern_regex\*\*:\s*(.+)$/m);
      if (!pr || !pr[1].trim()) missing.push(id);
    }
    assert.equal(missing.length, 0, `缺 pattern_regex 的 signature: ${missing.join(", ")}`);
  });
});
