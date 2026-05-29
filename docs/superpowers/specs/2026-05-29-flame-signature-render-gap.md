# flame-signature 处理 · 修复方案(flame INDEX 懒查)

- 日期: 2026-05-29
- 状态: ✅ **已落地(2026-05-29)** · 见文末「落地记录」
- 性质: **既有缺陷 + 设计未收口**,非 gaussdb topology 改动引入(git 对比确认重生前同样缺失)
- 发现于: gaussdb topology 计划 2 修活久红的 case-integrity 测试时暴露
- 优先级: 低(与 gaussdb 集中式/离线采集正交)

> **落地时的设计简化**:原 §2 设想"DF step 存引用键 → 按键查 flame INDEX"。实现时按 SKILL.md
> 火焰图路径的真实语义(用 perf 热点**全局撞** flame INDEX 的 pattern_regex)简化为:**不在 DF step
> 存 per-step 引用键**,flame INDEX 作为全局反向索引,命中需读火焰图时整体懒查、用 pattern_regex
> 撞热点。少一层 per-step 引用维护,且匹配语义与 SKILL 描述一致。

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

## 落地记录(2026-05-29)

- **distill**(`db-distill-engine-dev` `feat/flame-index`):
  - `parseDistillFlameMd` 补抽 `source_authority` + `pattern_quote`/`mechanism_quote`/`workload_implication_quote`。
  - `build-runtime` 加 `splitFlame` + `renderFlameIndex*`:flame 不进 per-db DF,归
    `cases/indices/by-flame-signature/{INDEX,CASES}.md`(INDEX 带 pattern_regex)。13 signatures。
- **ohsql**(`ohsql-plugin-dev` `feat/flame-index`):
  - 重生数据:per-db 桶无 flame(残留 0);新增 `by-flame-signature/`。
  - `field-integrity.test.ts` 撤掉 flame KNOWN-GAP 隔离(桶里已无 flame · 全过)。
  - `index-integrity.test.ts` 加 flame INDEX 完整性(INDEX↔CASES 行号 + 每条非空 pattern_regex)。
  - `golden-validity.test.ts` `loadIndexCaseIds` 并入 by-flame-signature 的 case_id(golden flame 桶引用它们)。
  - `SKILL.md`:数据布局加 flame 索引两行;Phase 2 火焰图路径改懒查(命中需读火焰图才 Read flame INDEX)。
- 测试:case 三测 33/33、离线 kit 17/17,全绿,无 skip。

## 仍遗留(另起 · 与本 flame 修复无关)

gaussdb 在线 Phase 2 路由仍按 `data/cases/gaussdb/INDEX.md` 单文件读,但 topology 拆分后已是
`gaussdb/{common,centralized,distributed}/`。**在线 gaussdb 路由对新布局失配**(plan 2 明确"先不动在线"
所致)· 需单独更新 Phase 2.0/2.1 让在线也按部署形态选 topology 子桶。
