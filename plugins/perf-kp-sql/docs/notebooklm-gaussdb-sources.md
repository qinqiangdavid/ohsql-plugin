# GaussDB 性能诊断 · NotebookLM 源清单(PDF 优先)

> 仿 mongodb 的 NLM 喂料思路(官方文档 + 厂商调优 + 通用性能方法论),但 GaussDB 官方文档
> **整本有 PDF 下载版** —— 喂 NotebookLM 用几本 PDF 比贴几十上百个 HTML 页干净得多
> (NLM 单 source 容量大、去重好、引用更稳)。
>
> 用法:在 NotebookLM 笔记本里 **Add source → 上传 PDF 或贴 URL**。Huawei 文档中心每个
> docset 落地页右上角有「PDF」下载;下载后整本传进 NLM。下面给的是**真实 docset 落地页**
> (案例库 source_url 的路径前缀派生),不编造具体 .pdf 直链。

## 1. GaussDB 官方文档(PDF 直链 · 主力 · 集中式优先)

PDF 直链格式(已验真 · HTTP 200 + `content-type: application/pdf` + `%PDF` magic):
`https://support.huaweicloud.com/<docset>/<docset>-pdf.pdf`

下方 7 本已下载到本地 `~/gaussdb-nlm-pdfs/`(共 ~88MB),可直接上传 NotebookLM。集中式诊断**优先前 5 本**。

| PDF 直链 | 内容 | 大小 | 集中式 |
|---|---|---|---|
| https://support.huaweicloud.com/centralized-devg-v8-gaussdb/centralized-devg-v8-gaussdb-pdf.pdf | 集中式 开发指南 V2.0-8.x(SQL 调优/执行计划/索引/统计信息) | 27M | ★主力 |
| https://support.huaweicloud.com/centralized-devg-v3-gaussdb/centralized-devg-v3-gaussdb-pdf.pdf | 集中式 开发指南 v3 | 17M | ★ |
| https://support.huaweicloud.com/centralized-devg-v2-gaussdb/centralized-devg-v2-gaussdb-pdf.pdf | 集中式 开发指南 v2 | 12M | ★ |
| https://support.huaweicloud.com/bestpractice-gaussdb/bestpractice-gaussdb-pdf.pdf | GaussDB 最佳实践(性能/参数/容量) | 2.9M | ★ |
| https://support.huaweicloud.com/fg-gaussdb-cent-v8/fg-gaussdb-cent-v8-pdf.pdf | 集中式 v8 功能/工具指南(含内置火焰图) | 2.0M | ★ |
| https://support.huaweicloud.com/gaussdb_faq/gaussdb_faq-pdf.pdf | GaussDB 常见问题 | 968K | ○ |
| https://support.huaweicloud.com/distributed-devg-v8-gaussdb/distributed-devg-v8-gaussdb-pdf.pdf | 分布式 开发指南 v8(SQL 调优章节与集中式复用) | 27M | ○补充 |

> 其它分布式开发指南(v3/v2)同理可按格式拼链下载,集中式诊断非必需。
> 一键重下:`for ds in centralized-devg-v8-gaussdb bestpractice-gaussdb fg-gaussdb-cent-v8 ...; do curl -sL -o $ds.pdf https://support.huaweicloud.com/$ds/$ds-pdf.pdf; done`

## 2. Kunpeng 系统调优(PDF · 鲲鹏底层)

GaussDB 跑在鲲鹏 ARM64 上时的 OS/硬件层调优(NUMA/网卡中断/内存分配器等)。
hikunpeng 文档中心同样有 PDF 下载。

| 落地页 | 内容 |
|---|---|
| https://www.hikunpeng.com/document/detail/zh/kunpengdbs/systuningguide/ | 鲲鹏 数据库系统调优指南(DB 无关,GaussDB 适用) |

> 注:案例库里 `hikunpeng.com/.../kunpengdbs/ecosystemEnable/MongoDB/...` 那批是 **MongoDB 专属**,
> 不要进 GaussDB 笔记本;GaussDB 用上面的 `systuningguide`(系统级,跨 DB 通用)。

## 3. 通用性能方法论(网页 · 少量保留)

火焰图/Off-CPU 分析方法论,被 flame-signature 案例引用,通用,无 PDF 保持网页:
- https://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html
- https://www.brendangregg.com/FlameGraphs/memoryflamegraphs.html
- https://www.brendangregg.com/FlameGraphs/offcpuflamegraphs.html

## 与 mongodb 喂料的对应关系

| 维度 | mongodb 笔记本 | GaussDB 笔记本(本清单) |
|---|---|---|
| 官方文档 | www.mongodb.com/docs(网页) | **Huawei docset PDF**(整本,少而全) |
| 厂商/生态调优 | percona/ampere/hikunpeng-MongoDB | **hikunpeng 系统调优 PDF** |
| 社区/JIRA | jira.mongodb.org / mongoing / mydbops | (GaussDB 侧暂以官方 + csdn/modb 补充,可选) |
| 通用方法论 | brendangregg 火焰图 | brendangregg 火焰图(共用) |

## 备注
- 优先级:**第 1 节前 5 本 PDF + 第 2 节 1 本 + 第 3 节 3 页** 即覆盖集中式诊断主要知识面。
- NLM 笔记本建议**单独建 GaussDB 笔记本**(与 mongodb 笔记本分开),`perf-kp-sql` 按 db 路由到对应笔记本查询。
- 这些 URL 均来自案例库 `data/cases/indices/by-source-url.json` 的真实 source_url 路径派生,未编造。
