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
