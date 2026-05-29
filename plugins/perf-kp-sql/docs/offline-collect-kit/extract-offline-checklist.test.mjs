import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { checkTopology, CURATED_CHECKS } from './extract-offline-checklist.mjs';

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

describe('CURATED_CHECKS · 慢 SQL 采集', () => {
  const slow = CURATED_CHECKS.find(c => c.check_id === 'chk-slow-sql-statement-history');
  it('存在慢 SQL check', () => assert.ok(slow, '应有 chk-slow-sql-statement-history'));
  it('查 statement_history · 可执行(非描述性)', () => {
    assert.match(slow.collection_method, /^gsql .*-c /);
    assert.match(slow.collection_method, /statement_history/);
  });
  it('用内核 is_slow_sql 标记 · 不写死 execution_time 阈值', () => {
    assert.match(slow.collection_method, /WHERE is_slow_sql/);
    assert.doesNotMatch(slow.collection_method, /execution_time\s*>\s*3000000/);
  });
  it('解析 details 看等待事件', () => {
    assert.match(slow.collection_method, /statement_detail_decode\(details/);
  });
  it('LIMIT 是可选入参 SLOW_SQL_LIMIT(默认 20)', () => {
    assert.match(slow.collection_method, /LIMIT \$\{SLOW_SQL_LIMIT:-20\}/);
  });
  it('linked 到慢 SQL 相关 common case → topology=common(集中式主机可跑)', () => {
    assert.equal(checkTopology(slow.linked_case_ids.map(() => 'common')), 'common');
  });
});
