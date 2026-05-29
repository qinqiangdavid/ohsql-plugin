// 枚举 data/cases 下所有 (INDEX.md, CASES.md) 对 · 跨 per-db + gaussdb topology 子目录
// 排除 indices/(by-check-item 等全局反向索引 · 非 case 库)
import { readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export function walkCasePairs(dataCasesDir) {
  const pairs = [];
  function rec(dir) {
    if (existsSync(join(dir, 'CASES.md')) && existsSync(join(dir, 'INDEX.md'))) {
      pairs.push({ dir, casesPath: join(dir, 'CASES.md'), indexPath: join(dir, 'INDEX.md') });
    }
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.isDirectory() && e.name !== 'indices') rec(join(dir, e.name));
    }
  }
  rec(dataCasesDir);
  return pairs;
}
