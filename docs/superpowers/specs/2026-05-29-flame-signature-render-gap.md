# flame-signature 处理 · 修复方案(DF 内嵌引用 + flame INDEX 懒查)

- 日期: 2026-05-29
- 性质: **既有缺陷 + 设计未收口**,非 gaussdb topology 改动引入(git 对比确认重生前同样缺失)
- 发现于: gaussdb topology 计划 2 修活久红的 case-integrity 测试时暴露
- 优先级: **低**(与 gaussdb 集中式/离线采集正交;火焰图匹配路径本就未接通,无回归风险)

## 1. 现状(摸清)

- `field-integrity.test.ts` 的 flame-signature 硬校验:13 个独立 flame-signature case(都在 `_common`)
  缺 `scope/signature_type/match_layer/pattern_regex/source_authority` + 段
  `pattern_quote/mechanism_quote/workload_implication_quote`。
- 根因不止"字段没渲染",更根本的是**整条火焰图路径没接通**:
  - `build-runtime` 的 `renderRuntimeCase()` 只渲染 diagnostic-flow 字段,不渲染 flame 字段;
    `renderCasesIndex()` 只产一张 DF 表,**INDEX 里没有 flame-signature 段、没有 `pattern_regex`**。
  - 但 SKILL.md §Phase 2.2(906 行)描述的火焰图路径是"读 INDEX 里的 `pattern_regex` 撞热点函数"
    —— **数据源不存在,这条路径是死的**。
- 已有进展:DF case 的 step 里已内嵌 14 处非空 `flame_pattern`(_common/mongodb/gaussdb/common);
  `reverse-map-helper.mjs` 明确设计意图——独立 flame 是过渡态,"将来内嵌为 DF case 的 flame_pattern",
  产 `MIGRATION.md` 供人审归属。distill 源里 flame 字段齐全,丢失纯在 render 环节。

## 2. 决定的方案 · DF 内嵌引用 + flame INDEX 懒查

**不补全独立 flame 案例(否决)**:那是加固一个本要废弃的过渡态,且让"独立案例 / DF 内嵌"两种表示长期并存(乱源)。

**采用**:flame 细节移出主路由,做成专门反向索引,DF 步骤按引用懒查。

数据模型:
- **flame-signature 不再是独立 case**(不再有 `entry_kind: flame-signature` 的 runtime case)。
  其完整字段(`pattern_regex / scope / signature_type / match_layer` + quote 段)归到一个**专门的
  火焰图反向索引** `cases/indices/by-flame-signature/{INDEX,CASES}.md`(与 `by-check-item` 平级 · 全局跨 db)。
- **DF case 需要看火焰图的 step**,`flame_pattern` 里只存**引用键**(指向 flame INDEX 的 signature id)
  + `collection_layer: flamegraph` 标记;不铺开正则细节。
- **Phase 2 火焰图路径改懒查**:正常走 DF 路由;仅当命中的 DF case 的 step 标了"需读火焰图"时,
  才按引用键去 `by-flame-signature/INDEX.md` 拉 `pattern_regex` 撞用户 perf 热点。

## 3. 落地顺序

1. **distill 渲染**:
   - `parseDistillFlameMd` 补抽 `source_authority` + 3 个 quote 段(pattern/mechanism/workload_implication)。
   - `build-runtime` 新增 `renderFlameIndex()`:把所有 flame-signature 渲成
     `cases/indices/by-flame-signature/{INDEX,CASES}.md`(INDEX 带 `signature_id + pattern_regex + scope` 列)。
   - flame-signature **不再**进 per-db `cases/<db>/` 的 DF 渲染流。
2. **内嵌引用**:跑 reverse-map / 过 `MIGRATION.md`,把 13 个 flame 的归属定下来,
   在对应 DF case 的 step.`flame_pattern` 写入引用键(指向 flame INDEX 的 signature_id)。
3. **SKILL.md 对齐**:Phase 2.2 火焰图路径描述改为"DF step 命中需读火焰图 → 按 flame_pattern 引用键
   去 `by-flame-signature/INDEX.md` 查 pattern_regex"(懒查),与 build 产出一致。
4. **测试**:
   - `field-integrity.test.ts` 删掉 flame-signature 的 case 级 schema + 移除本轮加的 KNOWN-GAP 隔离
     (`it.skip` + `failed.filter(...!=='flame-signature')`)—— 因为运行库不再有独立 flame case。
   - 新增 flame INDEX 完整性测试:INDEX↔CASES 行号对应 + 每条 signature 有非空 pattern_regex/scope。
   - 校验 DF step 的 flame_pattern 引用键都能在 flame INDEX 里查到(无悬空引用)。

## 4. 验收

- 运行库无 `entry_kind: flame-signature` 的独立 case;flame 细节全在 `by-flame-signature/`。
- 每个 DF 的 flamegraph step 的引用键在 flame INDEX 命中(无悬空)。
- `field-integrity` 不再隔离 flame、全绿;新增 flame INDEX 测试绿。
- SKILL.md 描述与 build 产出一致(火焰图路径真正可用)。
