import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { allowedTopologies, compareThreshold, firstThreshold } from './match-collect-to-cases.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));

describe('allowedTopologies', () => {
  it('centralized → common + centralized-only(不含 distributed-only)', () => {
    assert.deepEqual(allowedTopologies('centralized').sort(), ['centralized-only', 'common']);
  });
  it('single-node 同 centralized', () => {
    assert.deepEqual(allowedTopologies('single-node').sort(), ['centralized-only', 'common']);
  });
  it('distributed → common + distributed-only', () => {
    assert.deepEqual(allowedTopologies('distributed').sort(), ['common', 'distributed-only']);
  });
  it('unknown-detect-fail → 全部三套', () => {
    assert.equal(allowedTopologies('unknown-detect-fail').length, 3);
  });
});

describe('compareThreshold', () => {
  it('47 越界 > 40 → 命中', () => assert.equal(compareThreshold('47', '> 40'), true));
  it('30 不越界 > 40 → 不命中', () => assert.equal(compareThreshold('30', '> 40'), false));
  it('avg_time > 3ms · 值 5 → 命中', () => assert.equal(compareThreshold('5', 'avg_time > 3ms'), true));
  it('阈值 NULL/空 → null(B 类)', () => {
    assert.equal(compareThreshold('123', 'NULL'), null);
    assert.equal(compareThreshold('123', ''), null);
  });
  it('值非数字 → null', () => assert.equal(compareThreshold('no-number', '> 40'), null));
});

describe('firstThreshold', () => {
  it('从多段取第一个含比较符的', () => {
    assert.equal(firstThreshold('"avg_time > 3ms","其它描述"'), 'avg_time > 3ms');
  });
  it('无比较符 → 退化取首段', () => {
    assert.equal(firstThreshold('"纯描述"'), '纯描述');
  });
});

describe('集成 · 集中式不撞 distributed-only', () => {
  it('centralized 采集 → distributed-only check 不进候选 · common 越界进 auto-hit', () => {
    const dir = mkdtempSync(join(tmpdir(), 'match-test-'));
    mkdirSync(join(dir, 'stdout'), { recursive: true });
    writeFileSync(join(dir, 'deploy.txt'), 'centralized\n');
    // 两个 check 都有 stdout(模拟 unknown 全采时也采到了),但形态过滤应砍掉 distributed-only
    writeFileSync(join(dir, 'stdout', 'chk-common-hot.txt'), '47\n');
    writeFileSync(join(dir, 'stdout', 'chk-dist-skew.txt'), '99\n');
    const checklist = join(dir, 'checklist.ndjson');
    writeFileSync(checklist, [
      JSON.stringify({ check_id: 'chk-common-hot', topology: 'common', abnormal_patterns: '"> 40"', linked_case_ids: ['gaussdb-cpu-01'] }),
      JSON.stringify({ check_id: 'chk-dist-skew', topology: 'distributed-only', abnormal_patterns: '"> 10"', linked_case_ids: ['gaussdb-dist-skew-01'] }),
    ].join('\n') + '\n');

    execFileSync('node', [join(HERE, 'match-collect-to-cases.mjs'), '--collect', dir, '--checklist', checklist], { encoding: 'utf8' });

    assert.ok(existsSync(join(dir, 'match-candidates.ndjson')), '应生成 match-candidates.ndjson');
    const out = readFileSync(join(dir, 'match-candidates.ndjson'), 'utf8');
    assert.ok(out.includes('chk-common-hot'), 'common check 越界应进 auto-hit');
    assert.ok(out.includes('gaussdb-cpu-01'), 'common check 的 linked case 应在候选');
    assert.ok(!out.includes('chk-dist-skew'), '集中式不应撞 distributed-only check');
    assert.ok(!out.includes('gaussdb-dist-skew-01'), 'distributed-only 的 case 不应出现');
  });
});
