# GaussDB 离线采集 · 部署形态(topology)分桶与路由 · 设计

- 日期: 2026-05-28
- 范围: **仅离线**(在线 Phase 2 本轮不动)
- 涉及仓:
  - `db-distill-engine-clone`(distill 权威源 · 加 `topology` 字段)
  - `ohsql-plugin-dev`(perf-kp-sql · case 库三拆 + 离线 kit 消费)

---

## 1. 目标与背景

perf-kp-sql 的 gaussdb 案例桶(79 case)把**集中式**与**分布式**根因混在一起。离线采集 kit
(`docs/offline-collect-kit/`)已能用 `pg_catalog.gs_deployment()` 自识别部署形态写入 `deploy.txt`,
但采集与反喂都不区分形态:集中式机器上会采集/撞库到 `distributed-only` 的无关根因
(CN/DN、redistribute、streaming、分布键、倾斜、下推、DWS)。

**本轮目标**:让 gaussdb 离线采集与回来后的案例路由都能区分集中式/分布式。

- 采集端:集中式机器不采分布式专属 check。
- 反喂端:实现 README 里"(待实现)"的 `match-collect-to-cases`,只撞与部署形态相关的案例桶。

**非目标(本轮不做)**:在线 Phase 2 的 gaussdb 探测 + 形态路由(三套目录结构为其将来铺好,零额外成本)。

---

## 2. topology 字段(权威源在 distill)

新增 case 字段 `topology`,三值:

| 值 | 含义 | 集中式上 |
|---|---|---|
| `common` | 引擎无关(优化器/GUC/OS 层) | ✅ 采 |
| `centralized-only` | 仅集中式/单节点有意义(如主备 redo 回放) | ✅ 采 |
| `distributed-only` | 仅分布式/MPP 有意义(CN/DN、redistribute、streaming、分布键、倾斜、下推、DWS) | ❌ 跳 |

### 2.1 分类规则(写进 `distill-v2/PROMPT-cases.md` · LLM 蒸馏时填 · 有确定性兜底)

按优先级:
1. **整个 `gaussdb-dws` 桶恒为 `distributed-only`**(MPP 数据仓库本质分布式)。
2. 命中分布式专属信号且无集中式信号 → `distributed-only`。
   信号集: `CN`/`DN`、`REDISTRIBUTE`/`broadcast`/`streaming`、`分布列`/`分布键`、`倾斜`/`skew`、
   `下推`/`partialpush`/`shippable`、`PGXC`/`pgxc`、`gs_om`/`cm_ctl`、`DWS`/`dws`。
3. 命中集中式专属信号且无分布式信号 → `centralized-only`。
   信号集: `集中式`、`单节点`/`single-node`、`主备`。
4. 其余(含 MIXED 边界、行数估算偏差/work_mem/统计信息这类) → `common`。

**安全默认**:边界与歧义一律归 `common`。理由:集中式上多采一条无关指标的成本 < 漏采一条相关指标。

预期落桶(按现有 79 case 扫描): `common ~38 / distributed-only ~39 / centralized-only 少量`。

---

## 3. 数据流(物理三拆是 build 产物 · 活过 distill 重生)

```
distill-v2/cases/gaussdb/diagnostic-flow/*.md      ← 每个 case .md 加 topology 字段(权威源,手填一次)
        │  合并 build(改成按 topology 分流)
        ▼
ohsql-plugin-dev/plugins/perf-kp-sql/data/cases/gaussdb/
        ├── common/{INDEX,CASES}.md
        ├── centralized/{INDEX,CASES}.md
        └── distributed/{INDEX,CASES}.md
        │  extract-offline-checklist.mjs 读三套 · 把 topology 传到每个 check
        ▼
docs/offline-collect-kit/checklist.ndjson          ← 每 check 加 topology(继承自 linked case)
        │  _build-precompiled.mjs 把 topology 一起 inline
        ▼
docs/offline-collect-kit/collect-precompiled.{sh,py}  ← 内嵌每条 check 的 topology
```

要点:
- topology 在 distill 源手填一次,后面全脚本派生 → distill 重跑 / case 库重生都不丢。
- 物理拆是 build 确定性产物,不手工搬文件。
- **check topology 继承规则**:一个 check 可 linked 多个 case;多 case topology 不一致时**取最宽松**
  —— 任一 linked case 为 `common` → check 记 `common`;否则取那个具体值;
  同时含 `centralized-only` 与 `distributed-only` → 记 `common`。

---

## 4. 离线采集器按 deploy_form 跳 check

collector 已算出 `DEPLOY_FORM` 写 `deploy.txt`。本段让它据此过滤:

| `DEPLOY_FORM` | 跳过 | 采集 |
|---|---|---|
| `centralized` / `single-node` | `distributed-only` | `common` + `centralized-only` |
| `distributed` | `centralized-only` | `common` + `distributed-only` |
| `unknown-*`(探测失败 / 无 gsql) | **不跳**(全采) | 全部 + 报告头标 `⚠️ topology-filter-disabled` |

设计点:
- 跳过的 check **写进 `report.tsv` 标 `status=skip-topology`**(与 `skip-empty` 同级)·
  报告完整可审计,看得到"这条因形态被跳",不悄悄消失。
- `unknown-*` 降级全采(安全侧):宁可多采,不可因探测失败漏采。
- 过滤在 `run_check` 入口判 · topology 已 inline · 零额外远端往返。
- 同步落 `collect-precompiled.sh` 与 `.py` 两版(行为一致)。

---

## 5. 离线反喂路由 · `match-collect-to-cases.mjs`(本轮落地)

README 标"(待实现)"的反喂工具落地,职责单一:**只出候选 case_id + 证据,不出诊断报告**。
诊断报告仍交给 perf-kp-sql skill 的 Phase 4/5(不重复造报告逻辑)。

```
match-collect-to-cases.mjs
  输入:
    --collect out-<host>-<ts>/   (含 deploy.txt + report.tsv + stdout/)
    --cases   plugins/perf-kp-sql/data/cases/gaussdb/   (三套 INDEX/CASES)
  流程:
    1. 读 deploy.txt → deploy_form
    2. 按映射选案例桶:
         centralized / single-node → [common, centralized]
         distributed               → [common, distributed]
         unknown-*                 → [common, centralized, distributed]  (全采全撞)
    3. 只 Read 选中桶的 CASES.md · 用 abnormal_pattern_threshold / abnormal_pattern_quote
       撞 stdout/<cid>.txt 的采集值 → 命中 case_id 候选(带阈值比对证据)
    4. 输出 match-report(候选 case_id + 证据行 + source_url)
  输出: out-<host>-<ts>/match-candidates.{md,ndjson}
```

设计点:
- 形态判定**复用采集时写的 `deploy.txt`**,不重新探测 —— 采集与反喂同一事实源,
  杜绝"采时集中式、喂时按分布式撞库"的错配。
- 撞库只读选中桶 → 集中式采集结果绝不误命中 `distributed-only` 根因。
- `source_url` 必须 **verbatim** 来自 CASES.md(守 SKILL.md 红线);不命中不强写。

---

## 6. 测试(改核心流程前先写失败测试 · 红→绿)

| 改动 | 失败测试(先红) |
|---|---|
| 分类规则 | 喂已知 case(`gaussdb-dist-volatile-func-not-pushed` → distributed-only;`gaussdb-memory-work-mem-spill` → common;DWS 任一 → distributed-only)断言 topology 落桶正确 |
| 三拆 build | 断言三套 INDEX 并集 = 原 case 全集 · 无丢失 · 无重复 |
| checklist topology 继承 | 多 case check 取最宽松;cent-only ∩ dist-only → common |
| collector 跳过 | `deploy_form=centralized` + 一条 distributed-only check → `status=skip-topology`;`unknown` → 全采 + 报告头 `topology-filter-disabled` |
| match 路由 | 集中式 deploy.txt → 不读 `distributed/` 桶 · 不命中 dist-only case |

收尾:在 `gauss_new`(192.168.1.5 · 507 集中式 · `gs_deployment()=BusinessCentralized`)
跑一次真实端到端(采集 → 跳过 distributed-only → 反喂只撞 common+centralized)。

---

## 7. 改动清单(按仓)

**db-distill-engine-clone**
- `distill-v2/PROMPT-cases.md`: 加 `topology` 字段定义 + 分类规则。
- `distill-v2/cases/gaussdb/diagnostic-flow/*.md` + `gaussdb-dws/diagnostic-flow/*.md`: 回填 topology。

**ohsql-plugin-dev (perf-kp-sql)**
- 合并 build: 产 `data/cases/gaussdb/{common,centralized,distributed}/{INDEX,CASES}.md`。
- `docs/offline-collect-kit/extract-offline-checklist.mjs`: 读三套 + 传 topology 到 check。
- `docs/offline-collect-kit/_build-precompiled.mjs`: inline topology。
- `docs/offline-collect-kit/collect-precompiled.{sh,py}`: deploy_form → skip-topology 过滤。
- `docs/offline-collect-kit/match-collect-to-cases.mjs`: 新增(反喂候选)。
- `docs/offline-collect-kit/README.md` + `HANDOFF.md`: 更新用法 + 去掉"(待实现)"。
- 各项配套测试。

**遵守**: 上游 `db-distill-engine` 只在本地 clone 改,push 走各自 origin;不直接推 upstream 公开仓。
