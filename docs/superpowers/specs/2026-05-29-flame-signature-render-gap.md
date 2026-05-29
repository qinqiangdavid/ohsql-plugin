# flame-signature 字段渲染缺陷 · 待修(另起任务)

- 日期: 2026-05-29
- 性质: **既有缺陷**,非 gaussdb topology 改动引入(git 对比确认重生前同样缺失)
- 发现于: gaussdb topology 计划 2 修活久红的 case-integrity 测试时暴露

## 现象

`field-integrity.test.ts` 的 flame-signature hard 字段检查,13 个 flame-signature case
(都在 `_common` 桶)缺以下 hard 字段:
`scope / signature_type / match_layer / pattern_regex / source_authority`
+ 段 `pattern_quote / mechanism_quote / workload_implication_quote`。

## 根因

1. `db-distill-engine` 的 `build-runtime-cases-from-md.mjs` `renderRuntimeCase()` 只渲染
   diagnostic-flow 顶层字段(entry_kind/db/platform/engine/symptom_category/case_pattern/
   topology/title/...),**不渲染 flame-signature 专属字段**。
2. `lib-distill-parse.mjs` `parseDistillFlameMd()` 抽了 scope/signature_type/match_layer/
   pattern_regex,但**未抽** source_authority 与三个 quote 段。

## 修法(待执行)

- distill 仓 `parseDistillFlameMd`: 补抽 source_authority + 三个 quote 段。
- distill 仓 `renderRuntimeCase`: 按 entry_kind=flame-signature 渲染 flame 字段 + 段。
- 重生数据后,移除 `field-integrity.test.ts` 里 flame-signature 的隔离
  (`it.skip` + `failed.filter(...!== 'flame-signature')`),让 flame 也走 hard 校验。

## 现状(隔离)

`field-integrity.test.ts` 已把 flame-signature 从 hard 校验隔离(非 flame 仍严格),
并留 `it.skip` 文档化本缺陷。topology 分支不混入 flame 渲染改动。

## 备注

build-runtime 注释提到:flame-signature 独立 case 预期最终被 reverse-map 内嵌进 DF case 的
`step.flame_pattern`,届时不再以独立 case_id 存在。修复前需确认这 13 个独立 flame case
是该补全字段、还是该走内嵌路径消解 —— 两条路线二选一,别两头都做一半。
