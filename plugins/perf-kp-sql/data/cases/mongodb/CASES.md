<!-- ============ Diagnostic-Flow (mongodb, 71 cases) ============ -->

## case_id: mongo-cache-spike-replication-lag-cascade-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger Cache 峰值与复制延迟级联失败 (MongoDB 3.0 → 3.4 升级修复)
- **source_heading**: Troubleshooting a MongoDB Performance Issue
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 4
- **source_url**: https://alexbevi.com/blog/2018/05/28/troubleshooting-a-mongodb-performance-issue/
- **source_url_lang**: en

### symptom_description

> This chart (48 hours sampled from 1 week ago) shows Cache Usage spiking and Replication Lag spiking. The cache spikes occur as new writes trigger index activity, which invalidates (dirties) cached memory and causes cache eviction.

### diagnostic_steps

```
[step 1] 观察 Cache Usage 是否在 spike
  metric_name: wiredTiger.cache.bytes_currently_in_the_cache
  collection_layer: mongo-internal-counter
  collection_method_quote: (NULL · 原文未给具体采集命令)
  abnormal_pattern_quote: "Cache Usage spiking"
  abnormal_pattern_threshold: NULL
  metric_unit: bytes
  prerequisite_steps: []

[step 2] 观察 Replication Lag 是否在 spike
  metric_name: replication_lag
  collection_layer: mongo-shell
  collection_method_quote: (NULL · 原文未给具体采集命令)
  abnormal_pattern_quote: "Replication Lag spiking"
  abnormal_pattern_threshold: NULL
  metric_unit: seconds
  prerequisite_steps: []

[step 3] 观察主节点是否需要重启来释放 cache
  metric_name: mongod_process_state
  collection_layer: os
  collection_method_quote: (NULL · 原文未给具体采集命令)
  abnormal_pattern_quote: "cache usage hits a certain point on the primary (left) server after which we have to kill the instance"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "The cache spikes occur as new writes trigger index activity, which invalidates (dirties) cached memory and causes cache eviction."
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "This slows down the speed at which the secondaries can request data from the primary, which spikes the lag."
  linked_diagnostic_step_no: 2
  mitigation_quote: NULL

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "When the secondaries request more data, it would lock up the primary, which in turn affected the primary server's ability to ingest new content and write it to disk. The read/write buffers back up and new write requests are throttled."
  linked_diagnostic_step_no: 2
  mitigation_quote: "As of MongoDB 4.0, non-blocking secondary reads have been added to address these types of latency issues."

[non_parameter_causes · cause 4] os-version-bug
  cause_type: os-version-bug
  description_quote: "the improvements to cache management and checkpoint areas were more likely to have improved my situation"
  linked_diagnostic_step_no: 1
  mitigation_quote: "We completed a significant upgrade on Tuesday that brings our cluster up to mongodb-server 3.4.15 (from 3.0.15)."

```

## case_id: mongo-ulimit-low-defaults-mongod-issues-03

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: linux-os
- **symptom_category**: startup-failure
- **case_pattern**: parameter-audit
- **title**: 系统默认 ulimit 过低导致 mongod 运行异常
- **source_heading**: ulimit(in "Tuning For Performance")
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://amperecomputing.com/tuning-guides/mongoDB-tuning-guide
- **source_url_lang**: en

### symptom_description

> Most UNIX-like operating systems, including Linux and macOS, provide ways to limit and control the usage of system resources such as threads, files, and network connections on a per-process and per-user basis. These "ulimits" prevent single users from using too many system resources. Sometimes, these limits have low default values that can cause a number of issues in the course of normal MongoDB operation.

### diagnostic_steps

```
[step 1] 看 mongod 进程的 ulimit
  metric_name: mongod 进程 nofile / nproc / fsize / memlock 等 ulimit
  collection_layer: os
  collection_method_quote: (Ampere 文档未直接给读法 · 通用方法 `cat /proc/$(pgrep -f mongod)/limits`)
  abnormal_pattern_quote: "these limits have low default values that can cause a number of issues"
  abnormal_pattern_threshold: nofile < 64000 / nproc < 64000(基于 mitigation 给定的推荐值)
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] /etc/security/limits.conf 中各 ulimit 项
  param_name: /etc/security/limits.conf 中各 ulimit 项
  abnormal_value_pattern: 默认偏低(发行版自带)
  reasoning_quote: "To configure ulimit value for these versions, create a file named /etc/security/limits.d/99-mongodb-nproc.conf with new values to increase the process limit."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-shard-chunk-migration-x-lock-timeout-balancer-stuck-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **title**: shard chunk migration 卡死 LockTimeout · balancer 一直 abort
- **source_heading**: MongoDB Chunk Migration Failed Solution: Unable to acquire X lock
- **diagnostic_steps_count**: 5
- **likely_causes_count**: 3
- **source_url**: https://finisky.github.io/en/mongodb-chunk-migration-failed/
- **source_url_lang**: en

### symptom_description

> balancer is not working. sh.status() displays many chunk migration errors

### diagnostic_steps

```
[step 1] 用 sh.status() 看各 shard 的 chunk 分布与 24h migration 结果
  metric_name: sharding.balancer.migration_24h_results · sharding.collection.chunks_per_shard
  collection_layer: mongo-shell
  collection_method_quote: (NULL · 原文给的是 sh.status() 的输出而非显式调用命令的字面 quote)
  abnormal_pattern_quote: "7 : Failed with error 'aborted', from mongo-1 to mongo-3"
  abnormal_pattern_threshold: {"failed_migrations_24h": ">= 7000", "chunk_skew_max_min_ratio": ">= 1.5"}
  metric_unit: count
  prerequisite_steps: []

[step 2] 在 config server 上 grep mongodb.log 的 SHARDING 模块 Migration failed log
  metric_name: log.SHARDING.MigrationFailed.error
  collection_layer: log-grep
  collection_method_quote: (NULL · 原文只说 "debug the issue through mongodb.log on the config server" 未给具体 grep 命令字面)
  abnormal_pattern_quote: "LockTimeout: Unable to acquire X lock on '{13328793763114131834: Collection, 1799578717045662184, X.A}' within 500ms. opId: 669456657, op: MoveChunk, connId: 0."
  abnormal_pattern_threshold: {"error_class": "LockTimeout", "op": "MoveChunk", "lock_timeout_ms": 500}
  metric_unit: log_event
  prerequisite_steps: [1]

[step 3] 手动 sh.moveChunk 验证错误重现
  metric_name: sh.moveChunk.errmsg
  collection_layer: mongo-shell
  collection_method_quote: "sh.moveChunk(\"X.A\", {\"Uuid\": \"XX\"}, \"mongo-3\" )"
  abnormal_pattern_quote: "Unable to acquire X lock on '{13328793763114131834: Collection, 1799578717045662184, X.A}' within 500ms. opId: 719103624, op: MoveChunk, connId: 0."
  abnormal_pattern_threshold: {"errmsg_class": "LockTimeout", "code": 24, "codeName": "LockTimeout"}
  metric_unit: error_message
  prerequisite_steps: [2]

[step 4] 排查 jumbo chunks 是否触发(经典误区)
  metric_name: sharding.collection.jumbo_chunks
  collection_layer: mongo-shell
  collection_method_quote: "sh.status(true)"
  abnormal_pattern_quote: "jumbo chunks might lead to migration failure. So we checked the collection chunks by sh.status(true), NO jumbo chunks found."
  abnormal_pattern_threshold: {"jumbo_chunks_count": "> 0 → suspect; == 0 → 排除"}
  metric_unit: count
  prerequisite_steps: [3]

[step 5] db.currentOp() 看正在持锁的 op
  metric_name: currentOp.locks · currentOp.waitingForLock
  collection_layer: mongo-shell
  collection_method_quote: "db.currentOp()"
  abnormal_pattern_quote: "We also try to check the current operations and locks via db.currentOp() , but not have a clue."
  abnormal_pattern_threshold: {"hint": "线索缺失 · 进入下一步源端切主验证"}
  metric_unit: n/a
  prerequisite_steps: [4]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "the original mongod process has inconsistent states. Restart is just a simple way to force another member to become primary, which bypass the inconsistent states issue of the original mongod."
  linked_diagnostic_step_no: 5
  mitigation_quote: "we restart the source mongod process through MongoDB Ops Manager to change the primary in the shard"

[non_parameter_causes · cause 2] data-distribution
  cause_type: data-distribution
  description_quote: "jumbo chunks might lead to migration failure"
  linked_diagnostic_step_no: 4
  mitigation_quote: (NULL · 原文未给 jumbo chunks 的 split / forceJumbo 命令字面)

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "Google a similar discussion here, which suggests to set maxTransactionLockRequestTimeoutMillis longer."
  linked_diagnostic_step_no: 3
  mitigation_quote: (NULL · 原作者顾虑生产副作用未尝试 · 备择方案)

```

## case_id: mongo-wt-large-page-eviction-fetch-pause-server-16479

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger 大页驱逐导致 fetch 期间多次显著停顿
- **source_heading**: Description (SERVER-16479)
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://jira.mongodb.org/browse/SERVER-16479
- **source_url_lang**: en

### symptom_description

> Test consists of a single thread inserting about 800 MB worth of documents then fetching them back. Under rc1 significant pauses would be observed during the inserts; rc2 has eliminated the pauses during inserts, but at the expense of comparable pauses during the fetches.

### diagnostic_steps

```
[step 1] 监测 wiredTiger.cache.pages written from cache 与 read into cache 同步峰值
  metric_name: wiredTiger.cache.pages written from cache / pages read into cache
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · JIRA 描述未给具体读取命令)
  abnormal_pattern_quote: "First query experiences about half a dozen regularly spaced significant pauses (e.g. D and E), coinciding with page evictions due to the large in-memory pages created by the insertions, as indicated by the coincident peaks in pages written from cache."
  abnormal_pattern_threshold: fetch 期间 pages written from cache 与 pages read into cache 周期性同步出现尖峰
  metric_unit: count
  prerequisite_steps: []

[step 2] gdb 抽样定位驱逐发生在 WiredTigerSession::releaseCursor
  metric_name: mongod 进程栈采样函数命中分布
  collection_layer: flamegraph
  collection_method_quote: "sampling periodically with gdb. The eviction shows up as a pause between the first query and the getmores from the app, coinciding with pages being written"
  abnormal_pattern_quote: "The gdb samples coinciding with this interval show that the eviction is occuring in __wt_btcur_reset called from WiredTigerSession::releaseCursor during the traversal of the collection."
  abnormal_pattern_threshold: gdb 采样栈中重复出现 `__wt_btcur_reset` / `WiredTigerSession::releaseCursor`
  metric_unit: enum
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] wiredTiger.engineConfig.memory_page_max(诊断专用 · 实际生产不应调)
  param_name: wiredTiger.engineConfig.memory_page_max(诊断专用 · 实际生产不应调)
  abnormal_value_pattern: 设到接近 1GB(诊断时为复现单次大停顿设的)
  reasoning_quote: "Profile was obtained by increasing memory_page_max to 1GB to move all the pauses to a single long pause as the 1GB page is evicted"
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] os-version-bug
  cause_type: os-version-bug
  description_quote: "Under rc1 significant pauses would be observed during the inserts; rc2 has eliminated the pauses during inserts, but at the expense of comparable pauses during the fetches."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 该 ticket Resolution=Duplicate · 真正修复在 SERVER-16269 · 升级 mongod 到 ≥ 3.0 GA 含修复)

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "the eviction is occuring in __wt_btcur_reset called from WiredTigerSession::releaseCursor during the traversal of the collection."
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · ticket 描述未给应用侧绕过方法)

```

## case_id: mongo-wt-btree-sweep-eviction-collection-blocked-server-17907

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: sweep server 整 b-tree 驱逐期间集合访问被阻塞数分钟
- **source_heading**: Description (SERVER-17907)
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://jira.mongodb.org/browse/SERVER-17907
- **source_url_lang**: en

### symptom_description

> The sweep server under some conditions will evict entire b-trees, and for a large b-tree this can take an extended time (many minutes in some cases). While this is occurring any attempt to access the b-tree hangs.

### diagnostic_steps

```
[step 1] 用 mongostat 观察 cache 利用率从 80% 跌到 0%
  metric_name: wiredTiger cache used % (mongostat 输出列 used)
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "Start mongostat to monitor the cache statistics while paging in the b-trees using this command:"
  abnormal_pattern_quote: "While this is running you should observe the cache utilization climb to its limit, 80%."
  abnormal_pattern_threshold: cache 利用率从 80% 在数分钟内跌到 0%
  metric_unit: percent
  prerequisite_steps: []

[step 2] 用 db.c.stats() 观察集合大小
  metric_name: db.collection.stats(1024*1024).size + totalIndexSize
  collection_layer: mongo-shell
  collection_method_quote: "s = db.c.stats(1024*1024)"
  abnormal_pattern_quote: "Soon after this (within a minute) the sweep server will begin evicting the test.c collection and _id index b-trees; you will see cache utilization drop from 80% to 0% over the course of some time (a couple minutes, somewhat longer on Windows than Linux). During this time accesses to test.c block."
  abnormal_pattern_threshold: size + totalIndexSize 接近 cacheSize 上限 + 长时间未访问后被 sweep
  metric_unit: MB
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] storage.wiredTiger.engineConfig.cacheSizeGB
  param_name: storage.wiredTiger.engineConfig.cacheSizeGB
  abnormal_value_pattern: cache 容纳了几乎一棵完整 b-tree;sweep 时整树一次性驱逐
  reasoning_quote: "Example: start mongod with --storageEngine wiredTiger --wiredTigerCacheSizeGB 9. Then populate a collection with 8 GB of collection and index data"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] os-version-bug
  cause_type: os-version-bug
  description_quote: "The sweep server under some conditions will evict entire b-trees, and for a large b-tree this can take an extended time (many minutes in some cases). While this is occurring any attempt to access the b-tree hangs."
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · ticket Resolution=Done · Fix Version 3.0.3 / 3.1.2 · 升级 mongod 即可)

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "using small documents as below probably exacerbates the issue because it makes the eviction slower due to the number of buffers that must be freed during the eviction"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 文档大小一般由业务设计,不是诊断侧能改的)

```

## case_id: mongo-tcmalloc-decommit-madvise-lock-stall-server-31417

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: tcmalloc 归还大量 pageheap free memory 时持内部锁数秒 · 全线程延迟尖峰
- **source_heading**: Description (SERVER-31417)
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 2
- **source_url**: https://jira.mongodb.org/browse/SERVER-31417
- **source_url_lang**: en

### symptom_description

> tcmalloc may occasionally release large amounts of pageheap free memory to the kernel by calling madvise. This can take seconds when the amount of memory involved is many GB. A tcmalloc internal lock is held while this happens, so this can potentially stall many threads, causing widespread latency spikes.

### diagnostic_steps

```
[step 1] 同一时刻 tcmalloc.pageheap_free_bytes 跌至接近 0
  metric_name: serverStatus.tcmalloc.tcmalloc.pageheap_free_bytes
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · ticket 描述未给具体读取命令)
  abnormal_pattern_quote: "tcmalloc pageheap free memory decreases to near zero"
  abnormal_pattern_threshold: pageheap_free_bytes 在数秒内由数 GB 跌到接近 0
  metric_unit: bytes
  prerequisite_steps: []

[step 2] 同时 tcmalloc unmapped 内存对应增加
  metric_name: serverStatus.tcmalloc.tcmalloc.pageheap_unmapped_bytes
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 同 ref)
  abnormal_pattern_quote: "tcmalloc unmapped memory increases by a corresponding amount"
  abnormal_pattern_threshold: unmapped_bytes 同时段对称增加
  metric_unit: bytes
  prerequisite_steps: [1]

[step 3] mongod 进程 RSS 同步下降
  metric_name: mongod 进程 RSS
  collection_layer: os
  collection_method_quote: (NULL)
  abnormal_pattern_quote: "resident memory decreases by the same amount"
  abnormal_pattern_threshold: RSS 同时段下降相同量级
  metric_unit: bytes
  prerequisite_steps: [1]

[step 4] 系统 free memory 同步上升
  metric_name: /proc/meminfo MemFree
  collection_layer: os
  collection_method_quote: (NULL · ticket 未给读取命令)
  abnormal_pattern_quote: "system free memory increases by that amount"
  abnormal_pattern_threshold: OS 层 MemFree 同时段对应上升
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "A tcmalloc internal lock is held while this happens, so this can potentially stall many threads, causing widespread latency spikes."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · ticket Resolution=Fixed · Fix Version 8.0.0 · 升级 mongod 到 ≥ 8.0 即可获得改进)

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "There is no direct metric that diagnoses this (SERVER-31380 would provide that), but it can be indirectly inferred to be a likely cause from the following:"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 暂只能用 4 间接指标共发推断;直接指标待 SERVER-31380 上线)

```

## case_id: mongo-tcmalloc-heap-fragmentation-pageheap-free-server-33296

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: mongod 内存远超已分配数据 · pageheap_free_bytes 持续累积
- **source_heading**: Description (SERVER-33296)
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://jira.mongodb.org/browse/SERVER-33296
- **source_url_lang**: en

### symptom_description

> Over time allocated memory never exceeds 8 GB but heap size and resident memory reach nearly 14 GB this is due to an accumulation of pageheap_free_bytes

### diagnostic_steps

```
[step 1] 比较 mongod allocated 与 RSS / 堆大小
  metric_name: mongod tcmalloc.tcmalloc.generic.heap_size / current_allocated_bytes / pageheap_free_bytes
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · ticket 描述未给具体读取命令)
  abnormal_pattern_quote: "allocated memory never exceeds 8 GB but heap size and resident memory reach nearly 14 GB this is due to an accumulation of pageheap_free_bytes"
  abnormal_pattern_threshold: (heap_size - current_allocated_bytes) ≈ pageheap_free_bytes 且持续增长
  metric_unit: bytes
  prerequisite_steps: []

[step 2] 读 mongod 进程 RSS
  metric_name: mongod 进程 RSS
  collection_layer: os
  collection_method_quote: (NULL)
  abnormal_pattern_quote: "but heap size and resident memory reach nearly 14 GB"
  abnormal_pattern_threshold: RSS ≫ allocated_bytes(原文示例 ≈ 14GB vs 8GB)
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] TCMALLOC_AGGRESSIVE_DECOMMIT(环境变量 / 启动参数)
  param_name: TCMALLOC_AGGRESSIVE_DECOMMIT(环境变量 / 启动参数)
  abnormal_value_pattern: 未启用(默认),pageheap_free_bytes 不主动归还 OS
  reasoning_quote: "Setting TCMALLOC_AGGRESSIVE_DECOMMIT can address this issue by causing tcmalloc to aggressively return the free pages to the o/s where they can then be re-used by tcmalloc to satisfy new memory requests. However can have an unacceptable negative performance impact."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "A common cause of this is a shifting distribution of allocated memory sizes, which leaves free pages dedicated to one size of buffer unable to be used for new memory requests because they are for a different size buffer."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · ticket Resolution=Unresolved · 修复路线尚在 backlog;部分情形可启用 AGGRESSIVE_DECOMMIT 但有性能代价)

[non_parameter_causes · cause 2] os-version-bug
  cause_type: os-version-bug
  description_quote: "The changes described in SERVER-20306 eliminated a common source of memory fragmentation, but it can still occur for other reasons."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · ticket 仍未解决)

```

## case_id: mongo-wt-tcmalloc-fragmentation-durable-history-wt-6175

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: 4.4 引入 durable history 后 tcmalloc 碎片化加剧 · mongod VSZ 比 4.2.6 多约 9G
- **source_heading**: Description (WT-6175)
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://jira.mongodb.org/browse/WT-6175
- **source_url_lang**: en

### symptom_description

> The accumulation of many small data structures (typically associated with inserts and updates) in the WiredTiger cache can cause the system's memory allocator to use more space than is requested by WiredTiger.

### diagnostic_steps

```
[step 1] 比较 mongod 进程 VSZ 与配置 cacheSize 的差距
  metric_name: mongod 进程 VSZ
  collection_layer: os
  collection_method_quote: (NULL · ticket 描述未给具体读取命令)
  abnormal_pattern_quote: "For 4.4.0-rc4, VSZ for the mongod process is ~9G larger after create index compared to VSZ for 4.2.6 or 4.4 prior to the durable history merge."
  abnormal_pattern_threshold: mongod VSZ 比 cacheSizeGB + 合理开销大数 GB(原文示例 4.4-rc4 多 9G)
  metric_unit: GB
  prerequisite_steps: []

[step 2] 观察 cache dirty % 是否被新 eviction_updates_target 拖低
  metric_name: wiredTiger cache dirty %
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · ticket 描述未给具体读取命令)
  abnormal_pattern_quote: "If this occurs you will notice that cache dirty % tends more toward the eviction_updates_target of 2.5% rather than the eviction_dirty_target of 5%."
  abnormal_pattern_threshold: cache dirty % 长期接近 2.5% 而非 5%(说明被新 updates trigger 主导)
  metric_unit: percent
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] wiredTiger.cache.eviction_updates_trigger / eviction_updates_target
  param_name: wiredTiger.cache.eviction_updates_trigger / eviction_updates_target
  abnormal_value_pattern: 默认 trigger=10%(eviction_dirty_trigger/2),target=2.5%(eviction_dirty_target/2);若与 workload 不匹配会过早 eviction 或不够 eviction
  reasoning_quote: "Adding a configurable trigger (eviction_updates_trigger) on the amount of small objects in the cache, to prompt eviction of that content. The default value is eviction_dirty_trigger / 2 (10%). Adding a configurable target (eviction_updates_target) to serve as a goal for the eviction process. The default value is eviction_dirty_target / 2 (2.5%)."
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "With the introduction of durable history in MongoDB 4.4, it is more common that small memory allocations associated with these small objects are contributing more to fragmentation than in previous versions."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · ticket Resolution=Fixed · Fix Version 4.4.0-rc10 / 4.7.0 · 升级 mongod 即可)

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "However, some WiredTiger cache pages with many associated small memory allocations can remain in cache after a checkpoint and be marked as clean pages. The clean/dirty distinction helps limit the amount of work done in checkpoints, but is in this way an estimate of memory allocator fragmentation."
  linked_diagnostic_step_no: 1
  mitigation_quote: "Tracking insert and update data structures as a separate attribute of cache usage. Extending the cache eviction process to manage the proportion of cache associated with small allocations, similarly to how it manages clean and dirty content."

```

## case_id: mongo-globallock-current-queue-high-lock-contention-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **title**: globalLock.currentQueue.total 持续高 → 大量请求等锁 → 性能降级
- **source_heading**: 锁性能
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://mongoing.com/archives/39593
- **source_url_lang**: zh-cn

### symptom_description

> MongoDB使用一套锁机制确保数据集的一致性。如果某个操作执行时间较长或是一个队列表单，下一操作请求由于要等待当前操作释放锁而出现性能降级。

### diagnostic_steps

```
[step 1] 用 serverStatus 查 globalLock.currentQueue.total 是否持续高
  metric_name: globalLock.currentQueue.total
  collection_layer: mongo-shell
  collection_method_quote: (NULL · 原文未给字面 db.serverStatus() 命令)
  abnormal_pattern_quote: "如果 globalLock.currentQueue.total 值持续较高，有可能有大量的请求在等待锁释放。说明可能有影响性能的并发问题。"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2] 比较 globalLock.totalTime 与 uptime 看死锁是否长期持续
  metric_name: globalLock.totalTime_vs_uptime
  collection_layer: mongo-shell
  collection_method_quote: (NULL · 同上)
  abnormal_pattern_quote: "如果  globalLock.totalTime  相对于  uptime 较高，说明数据库的死锁已经维持一段时间了。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

[step 3] 计算 locks.timeAcquiringMicros / acquireWaitCount 平均等待时间
  metric_name: locks.avg_acquire_wait_micros
  collection_layer: mongo-shell
  collection_method_quote: (NULL · 原文给指标名未给字面命令)
  abnormal_pattern_quote: "locks.timeAcquiringMicros除以locks.acquireWaitCount能计算出特定锁模式的平均等待时间。"
  abnormal_pattern_threshold: NULL
  metric_unit: micros
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "慢查询可能的原因：索引的无效使用；非最优表设计模式；糟糕的查询结构；系统架构问题；内存不足触发磁盘读取。"
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: mongo-pagination-skip-deep-page-rewrite-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 大翻页 skip 性能塌陷: skip 100 页 12.8s → 改写 $gt 后稳定 10-20ms
- **source_heading**: 分页翻页案例以及执行效率
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://mongoing.com/archives/74118
- **source_url_lang**: zh-cn

### symptom_description

> 分页翻页，尤其是结果集特别多越往后翻页越慢，常规写法

### diagnostic_steps

```
[step 1] explain 翻不同页位置的 skip 查询,看时间随页号增长
  metric_name: explain.executionTimeMillis_per_page
  collection_layer: mongo-shell
  collection_method_quote: "db.test.find({org:\"10000\", signT:{$gte:new Date(1590940800000), $lte: new Date(1591027199999)},signStatus:{$in:[0,1]} }).sort({no:1}).skip(50).limit(50).explain(\"executionStats\")"
  abnormal_pattern_quote: "翻第二页(每页50条)\n\n\"executionStats\" : {\n\"executionSuccess\" : true,\n\"nReturned\" : 50,\n\"executionTimeMillis\" : 29,\n\"totalKeysExamined\" : 876,\n\"totalDocsExamined\" : 100,"
  abnormal_pattern_threshold: {"page2_ms": 29, "page10_ms": 1001, "page100_ms": 12830}
  metric_unit: ms / keys
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "索引:org:1,no:1,signT:1,翻页从第一页到100页，执行时间从29ms到12830ms。其实100页数据才5000条,但是totalKeysExamined检查是108725,此时返回5000条，相当于indexkey:doc=20:1,显然是低效索引的。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "取消skip方式,对排序列增加一个大于上一页最大值来快速获取分页，性能基本上在10-20ms之间。"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "如果id是唯一或者想办法使用唯一列来排序，此时可以将翻页语句修改如下：\n\ndb.test.find({org:\"10000\",staDate:ISODate(\"2020-07-17T00:00:00.000+08:00\"),\nsignStatus:{$in:[0,1]},no{$gt:N}，}).sort({no:1}).limit(50);"
  linked_diagnostic_step_no: 1
  mitigation_quote: "db.test.find({org:\"10000\", staDate: ISODate(\"2020-07-17T00:00:00.000+08:00\"), signStatus:{$in:[ 0, 1 ] } ,no:{$gt:latest.no}}).sort({no:1}).limit(50)"

```

## case_id: mongo-wt-checkpoint-period-tuning-disk-io-spike-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger checkpoint 周期偏长 → 磁盘 IO 短暂 100% 抖动
- **source_heading**: 优化策略3：存储引擎checkpoint优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://mongoing.com/archives/77972
- **source_url_lang**: zh-cn

### symptom_description

> 少部分实例存在如下现象：一会儿磁盘IO几乎空闲0%，一会儿磁盘IO短暂性100%。

### diagnostic_steps

```
[step 1] 监控磁盘 IO 是否周期性 0% ↔ 100% 抖动
  metric_name: disk_io_util
  collection_layer: os
  collection_method_quote: (NULL · 原文未给字面 iostat 命令)
  abnormal_pattern_quote: "一会儿磁盘IO几乎空闲0%，一会儿磁盘IO短暂性100%"
  abnormal_pattern_threshold: {"disk_util_pct_low": 0, "disk_util_pct_high": 100}
  metric_unit: pct
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] wiredTigerEngineRuntimeConfig.checkpoint.wait / log_size
  param_name: wiredTigerEngineRuntimeConfig.checkpoint.wait / log_size
  abnormal_value_pattern: "默认 wait=60s, log_size=2GB"
  reasoning_quote: "该优化总体思路：缩短checkpoint周期，减少checkpoint期间积压的脏数据，缓解磁盘IO高问题。"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "进行如下优化后可以缓解该问题:\ncheckpoint=(wait=30,log_size=1GB)"
  linked_diagnostic_step_no: 1
  mitigation_quote: "checkpoint=(wait=30,log_size=1GB)"

```

## case_id: mongo-system-sessions-update-storm-primary-shard-degradation-03

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
- **title**: mongos 集中更新 system.sessions 拖垮主分片 → 集群瞬间数倍下降
- **source_heading**: 优化策略4：sharding集群system.session优化
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://mongoing.com/archives/77972
- **source_url_lang**: zh-cn

### symptom_description

> 大流量大数据量集群客户端链接众多，大量更新sessions表，最终主分片性能下降引起整个集群性能瞬间数倍下降。

### diagnostic_steps

```
[step 1] 看 mongostat / 慢日志 在 sessions 表更新时的瞬时尖峰
  metric_name: mongostat.qrw_arw_or_slow_log_count
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文该 case 节未给字面采集命令(同篇问答 18 给的是另案命令))
  abnormal_pattern_quote: "该优化后system.sessions表更新引起的瞬间性能数倍降低和大量慢日志问题得到了解决。"
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "之前代理集中式更新单个分片，优化为散列到不同时间点更新多个分片。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "config库的system.sessions表启用分片功能。\n\n\nmongos定期更新优化为散列到不同时间点进行更新。"

```

## case_id: mongo-slow-log-currentop-long-query-kill-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 慢日志 grep + currentOp 定位长时执行操作并 kill
- **source_heading**: 【慢日志分析】
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 1
- **source_url**: https://mongoing.com/archives/78150
- **source_url_lang**: zh-cn

### symptom_description

> 慢日志只有当请求执行完毕才会，如果一个表很大，一个查询扫表，则整个执行过程可能需要数小时，可能还没记录慢日志，则可以通过如下命令获取当前执行时间超过5s的所有请求，查询请求，command请求

### diagnostic_steps

```
[step 1] grep mongod.log 找出 COLLSCAN 慢操作
  metric_name: mongod.log.COLLSCAN_count
  collection_layer: log-grep
  abnormal_pattern_quote: "找出文件末尾1000000行中存在扫表的操作，不包含oplog，getMore"
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: []

[step 2] grep 找出执行时间 1-10s 慢请求
  metric_name: mongod.log.slow_query_1_10s
  collection_layer: log-grep
  abnormal_pattern_quote: "找出文件末尾1000000行中执行时间1-10s的请求，不包含oplog，getMore"
  abnormal_pattern_threshold: {"window_ms_low": 1000, "window_ms_high": 10000}
  metric_unit: ms
  prerequisite_steps: []

[step 3] currentOp 取当前 > 5s 操作
  metric_name: currentOp.secs_running
  collection_layer: mongo-shell
  collection_method_quote: "db.currentOp({“secs_running”:{“$gt”:5}})"
  abnormal_pattern_quote: "可以通过如下命令获取当前执行时间超过5s的所有请求"
  abnormal_pattern_threshold: {"secs_running_gt_seconds": 5}
  metric_unit: seconds
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "如果一个表很大，一个查询扫表，则整个执行过程可能需要数小时，可能还没记录慢日志"
  linked_diagnostic_step_no: 3
  mitigation_quote: "kill查询时间超过5s的所有请求：\ndb.currentOp().inprog.forEach(function(item){if(item.secs_running > 5 )db.killOp(item.opid)})"

```

## case_id: wt-eviction-trigger-app-thread-throttle-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: cache 用量持续接近 eviction_trigger (默认 95%) → application threads 被拉去做 eviction
- **source_heading**: Eviction tuning
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://source.wiredtiger.com/mongodb-6.0/tune_cache.html
- **source_url_lang**: en

### symptom_description

> The eviction_trigger configuration value (default 95%) is the level at which application threads start to perform eviction. This will throttle application operations, increasing operation latency, usually resulting in the cache usage staying at this level when there is more cache pressure than eviction worker threads can handle in the background.

### diagnostic_steps

```
[step 1] 看 page eviction statistics 评估 cache size 效果
  metric_name: wiredTiger.cache.bytes currently in the cache / wiredTiger.cache.maximum bytes configured
  collection_layer: mongo-internal-counter
  collection_method_quote: "The effectiveness of the chosen cache size can be measured by reviewing the page eviction statistics for the database"
  abnormal_pattern_quote: "the cache usage staying at this level when there is more cache pressure than eviction worker threads can handle in the background"
  abnormal_pattern_threshold: bytes_in_cache / maximum_bytes 持续 ≈ 0.95
  metric_unit: bytes / ratio
  prerequisite_steps: []

[step 2] 看 application threads 是否在做 eviction(latency spike)
  metric_name: wiredTiger.cache.eviction worker thread evicting pages / application thread time evicting
  collection_layer: mongo-internal-counter
  collection_method_quote: "Operations will stall when the cache reaches 100% of the cache size"
  abnormal_pattern_quote: "application threads start to perform eviction"(对应 serverStatus.wiredTiger.cache 中 `Application thread time evicting` 计数 · 该字段名为内部启发式)
  abnormal_pattern_threshold: application thread evicting time per sec 显著 > 0
  metric_unit: microseconds/sec
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] eviction_trigger
  param_name: eviction_trigger
  abnormal_value_pattern: 默认 95% · 业务峰值下 worker 来不及消化 → 应调低 trigger 给 worker 更多缓冲
  reasoning_quote: "The eviction_trigger configuration value (default 95%) is the level at which application threads start to perform eviction"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "The size of the cache is the single most important tuning knob for a WiredTiger application. Ideally the cache should be configured to be large enough to hold an application's working set"
  linked_diagnostic_step_no: 1
  mitigation_quote: "Ideally the cache should be configured to be large enough to hold an application's working set"

```

## case_id: mongo-snappy-hotspot-cpu-high-arm64-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **title**: MongoDB Snappy 压缩热点函数在鲲鹏 ARM64 上 CPU 占用偏高
- **source_heading**: 压缩算法调优
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.hikunpeng.com/document/detail/zh/kunpengdbs/ecosystemEnable/MongoDB/kunpengdbstune_05_0030.html
- **source_url_lang**: zh-cn

### symptom_description

> 针对Snappy热点函数CPU占用较高的场景，通过升级Snappy压缩算法版本，可以有效提升服务器性能。

### diagnostic_steps

```
[step 1] 在 mongod 进程上采 perf CPU 火焰图,看 Snappy 函数占比
  metric_name: flamegraph.snappy.cpu_pct
  collection_layer: flamegraph
  collection_method_quote: (NULL · 原文未给采集命令)
  abnormal_pattern_quote: "针对Snappy热点函数CPU占用较高的场景，通过升级Snappy压缩算法版本，可以有效提升服务器性能。"
  abnormal_pattern_threshold: `snappy_*函数 CPU 占比 > 10% on flamegraph (qualitative)`
  metric_unit: percent
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "针对Snappy热点函数CPU占用较高的场景，通过升级Snappy压缩算法版本，可以有效提升服务器性能。"
  linked_diagnostic_step_no: 1
  mitigation_quote: "下载最新版本的Snappy源码。解压下载的Snappy源码，并替换MongoDB源码中的老版本Snappy。"

```

## case_id: app-thread-concurrency-mismatch-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: linux-arm64-kunpeng
- **engine**: mixed
- **symptom_category**: cpu-high
- **case_pattern**: parameter-audit
- **title**: 应用线程并发数过高导致上下文切换/锁竞争开销加大
- **source_heading**: 调整线程并发数
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0013.html
- **source_url_lang**: zh-cn

### symptom_description

> 但是系统的性能并不会随着线程数的增长而线性提升，因为随着线程数量的增加，线程之间的调度、上下文切换、关键资源和锁的竞争也会带来很大开销。当资源的争抢比较严重时，甚至会导致性能明显下降。

### diagnostic_steps

```
[step 1] 读取应用当前并发线程数配置 + 业务 TPS
  metric_name: application thread concurrency setting + business TPS
  collection_layer: mongo-shell
  collection_method_quote: (NULL · 原文未给出"如何采集当前并发数"命令)
  abnormal_pattern_quote: "当资源的争抢比较严重时，甚至会导致性能明显下降。"
  abnormal_pattern_threshold: (定性) thread_count > optimal_concurrency_for_workload ∧ TPS 单调下降
  metric_unit: thread count
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] innodb_thread_concurrency (MySQL) / worker_processes (Nginx) / 应用自有并发参数
  param_name: innodb_thread_concurrency (MySQL) / worker_processes (Nginx) / 应用自有并发参数
  abnormal_value_pattern: 高于"针对不同业务模型多组测试找出的最佳并发数"
  reasoning_quote: "MySQL可以通过innodb_thread_concurrency设置工作线程的最大并发数。"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] worker_processes
  param_name: worker_processes
  abnormal_value_pattern: 超过 CPU core 数或业务最佳并发值
  reasoning_quote: "Nginx可以通过worker_processes参数设置并发的进程个数。"
  linked_diagnostic_step_no: 1

```

## case_id: app-malloc-jemalloc-multithread-audit-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: linux-arm64-kunpeng
- **engine**: mixed
- **symptom_category**: cpu-high
- **case_pattern**: parameter-audit
- **title**: 多线程内存分配场景未启用 jemalloc，glibc 默认分配器锁竞争激烈
- **source_heading**: 使用jemalloc优化内存分配
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.hikunpeng.com/document/detail/zh/perftuning/tuningtip/kunpengtuning_12_0051.html
- **source_url_lang**: zh-cn

### symptom_description

> 在内存分配过程中，锁会造成线程等待，对性能影响巨大。jemalloc采用如下措施避免线程竞争锁的发生：使用线程变量，每个线程有自己的内存管理器，分配在这个线程内完成，就不需要和其它线程竞争锁。

### diagnostic_steps

```
[step 1] 检查应用当前链接的内存分配库
  metric_name: application linked memory allocator library
  collection_layer: os
  collection_method_quote: (NULL · 原文未给"如何检查当前 allocator"命令)
  abnormal_pattern_quote: "推荐业务应用代码使用jemalloc进行内存分配。"
  abnormal_pattern_threshold: 当前 allocator ∈ {glibc-malloc, tcmalloc} ∧ 业务为多线程高分配率
  metric_unit: enum
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] linker flags · -ljemalloc + -L`jemalloc-config --libdir`
  param_name: linker flags · -ljemalloc + -L`jemalloc-config --libdir`
  abnormal_value_pattern: 链接默认 glibc malloc（编译选项中无 -ljemalloc）
  reasoning_quote: "修改应用软件的链接库的方式，在编译选项中添加如下编译选项"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] malloc-lib (my.cnf) 或类似配置
  param_name: malloc-lib (my.cnf) 或类似配置
  abnormal_value_pattern: malloc-lib 未设置 / 设置为非 jemalloc
  reasoning_quote: "部分开源软件可以修改配置参数来指定内存分配库，如MySQL可以配置my.cnf文件：malloc-lib=/usr/local/lib/libjemalloc.so"
  linked_diagnostic_step_no: 1

```

## case_id: mongo-aggregation-unbounded-pipeline-no-early-match-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: seller analytics 看板聚合 8.2s: $match 在 $lookup 之后
- **source_heading**: Fix 2: Aggregation Pipeline Refactoring
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mafiree.com/blog/mongodb-query-optimization-ecommerce-case-study
- **source_url_lang**: en

### symptom_description

> The seller analytics dashboard used a complex aggregation pipeline that processed the entire orders collection before filtering. The fix was straightforward but impactful: move $match and $sort stages to the beginning of the pipeline so MongoDB can leverage indexes before processing downstream stages.

### diagnostic_steps

```
[step 1] 跑慢 pipeline 看 working set 规模
  metric_name: aggregation_pipeline_duration
  collection_layer: mongo-shell
  collection_method_quote: "// BEFORE: Unoptimized pipeline (8.2s)\ndb.orders.aggregate([\n  { $lookup: { from: \"products\", ... } },\n  { $unwind: \"$items\" },\n  { $match: { sellerId: ObjectId(\"...\"), status: \"completed\" } },\n  { $group: { _id: \"$items.category\", revenue: { $sum: \"$total\" } } }\n])"
  abnormal_pattern_quote: "Dashboard load time: 8.2s → 1.8s. Working set reduced from 80M to ~45K documents before $lookup runs."
  abnormal_pattern_threshold: {"before_seconds": 8.2, "before_doc_count": 80000000}
  metric_unit: seconds
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Aggregation stages like $lookup and $unwind that run without an early $match stage force MongoDB to process the entire collection before filtering. This turns what should be a 5ms operation into a 5-second one."
  linked_diagnostic_step_no: 1
  mitigation_quote: "// AFTER: Optimized pipeline (1.8s)\ndb.orders.aggregate([\n  { $match: { sellerId: ObjectId(\"...\"), status: \"completed\" } },\n  { $sort: { orderDate: -1 } },\n  { $lookup: { from: \"products\", ... } },\n  { $unwind: \"$items\" },\n  { $group: { _id: \"$items.category\", revenue: { $sum: \"$total\" } } }\n])"

```

## case_id: mongo-schema-too-many-lookups-should-embed-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: $lookup 用得过多 → 应改为 embed 单集合内
- **source_heading**: Schema Suggestions
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/atlas/performance-advisor/schema-suggestions/
- **source_url_lang**: en

### symptom_description

> You are running too many $lookup operations on your data. Take advantage of MongoDB's rich schema model to embed related data in a single collection.

### diagnostic_steps

```
[step 1] Atlas Advisor / 慢查询 profile 中统计 $lookup 频率
  metric_name: 慢查询中 $lookup pipeline stage 出现频率
  collection_layer: atlas-advisor / mongo-runtime-cmd
  collection_method_quote: "The Performance Advisor monitors slow queries to recognize certain schema issues, namely too many $lookup operations and not utilizing an index for case-sensitive regex queries."
  abnormal_pattern_quote: "You are running too many $lookup operations on your data."
  abnormal_pattern_threshold: (Atlas 内部启发式 · 自管理部署可统计 system.profile 中 $lookup 占比)
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Take advantage of MongoDB's rich schema model to embed related data in a single collection."
  linked_diagnostic_step_no: 1
  mitigation_quote: (使用 Extended Reference Pattern / 嵌入 frequently-read 字段)

```

## case_id: mongo-schema-unused-indexes-bloat-03

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-space-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: 集合上有未使用 index → 占盘 + 拖慢写性能
- **source_heading**: Schema Suggestions
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/atlas/performance-advisor/schema-suggestions/
- **source_url_lang**: en

### symptom_description

> You have unnecessary indexes in your collection, which can consume disk space and degrade write performance.

### diagnostic_steps

```
[step 1] 看每索引的访问计数
  metric_name: $indexStats accesses.ops · 每索引使用次数
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (Atlas 文档未给具体命令 · 自管理标准做法 `db.coll.aggregate([{$indexStats:{}}])`)
  abnormal_pattern_quote: "You have unnecessary indexes in your collection, which can consume disk space and degrade write performance."
  abnormal_pattern_threshold: 索引 accesses.ops 长期为 0 / 极低
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "You have unnecessary indexes in your collection, which can consume disk space and degrade write performance."
  linked_diagnostic_step_no: 1
  mitigation_quote: (确认无业务依赖后 `db.coll.dropIndex(name)`)

```

## case_id: mongo-schema-document-too-large-04

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 文档体积过大 → 频繁查询性能差
- **source_heading**: Schema Suggestions
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/atlas/performance-advisor/schema-suggestions/
- **source_url_lang**: en

### symptom_description

> You have excessively large documents, which can degrade the performance of your most frequent queries.

### diagnostic_steps

```
[step 1] 看集合 avgObjSize 与最大文档大小
  metric_name: collStats.avgObjSize / 文档大小 P99
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "The Performance Advisor analyzes the 20 most active collections based on the output of the top command."
  abnormal_pattern_quote: "You have excessively large documents, which can degrade the performance of your most frequent queries."
  abnormal_pattern_threshold: avgObjSize 显著大(原文未给数字 · 经验值 > 1MB 即应警惕)
  metric_unit: bytes
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: (NULL · 原文未给 cause 描述,仅给 mitigation pattern)
  linked_diagnostic_step_no: 1
  mitigation_quote: "Use The Outlier Pattern to handle a few large documents in an otherwise standard collection."

```

## case_id: mongo-query-targeting-high-scan-ratio-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: Atlas Query Targeting alert: high scanned-to-returned document ratio
- **source_heading**: Query Targeting
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/atlas/reference/alert-resolutions/query-targeting/
- **source_url_lang**: en

### symptom_description

> Ideally, the ratio of scanned documents to returned documents should be

### diagnostic_steps

```
[step 1] 查看 Atlas Query Targeting metrics(Scanned/Returned 与 Scanned Objects/Returned)
  metric_name: Atlas Query Targeting: Scanned/Returned & Scanned Objects/Returned
  collection_layer: atlas-advisor
  collection_method_quote: (NULL · 原文为 Atlas UI 操作而非命令)
  abnormal_pattern_quote: "uses a 1000:1 threshold"
  abnormal_pattern_threshold: {"scanned_objects_to_returned": ">= 1000:1 (default)", "scanned_index_keys_to_returned": "user-defined"}
  metric_unit: ratio
  prerequisite_steps: []

[step 2] 通过 mongod 慢查询日志确认 planSummary / docsExamined / nreturned
  metric_name: mongod slow query log: planSummary / keysExamined / docsExamined / nreturned
  collection_layer: log-grep
  collection_method_quote: (NULL · 原文给的是日志样例而非采集命令)
  abnormal_pattern_quote: "planSummary: COLLSCAN keysExamined:0docsExamined: 10000 cursorExhausted:1 numYields:234nreturned:4  protocol:op_query 358ms"
  abnormal_pattern_threshold: {"planSummary": "COLLSCAN", "keysExamined": 0, "docsExamined_to_nreturned_ratio_observed": 2500}
  metric_unit: log line tokens
  prerequisite_steps: [1]

[step 3] 用 cursor.explain() 查看具体查询执行计划
  metric_name: explain.executionStats
  collection_layer: mongo-shell
  collection_method_quote: "The cursor.explain()\ncommand for mongosh provides performance details for\nall queries."
  abnormal_pattern_quote: "This query scanned 10,000 documents and returned only 4 for a ratio\nof 2500, which is highly inefficient. No index keys were examined"
  abnormal_pattern_threshold: {"docsExamined": 10000, "nreturned": 4, "ratio": 2500}
  metric_unit: documents / ratio
  prerequisite_steps: [2]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "The query targeting alert typically occurs when there is no index to\nsupport a query or queries or when an existing index only partially\nsupports a query or queries."
  linked_diagnostic_step_no: 2
  mitigation_quote: "Add one or more indexes to better serve the inefficient queries."

[non_parameter_causes · cause 2] external-service
  cause_type: external-service
  description_quote: "The change streams cursors that the MongoDB Search\nprocess (mongot) uses to keep MongoDB Search indexes updated can\ncontribute to the query targeting ratio and trigger\nquery targeting alerts if the ratio\nis high."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给针对 mongot 的修复)

```

## case_id: mongo-slow-query-profiler-metric-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: Atlas Query Profiler: identify and interpret slow queries by multiple metrics
- **source_heading**: Find Slow Queries with the Query Profiler
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 5
- **source_url**: https://www.mongodb.com/docs/atlas/tutorial/query-profiler/
- **source_url_lang**: en

### symptom_description

> monitoring can expose slow-running queries

### diagnostic_steps

```
[step 1] 检查 Operation Execution Time + planSummary
  metric_name: Operation Execution Time (ms) + planSummary
  collection_layer: atlas-advisor
  collection_method_quote: (NULL · 原文是 Atlas UI 操作)
  abnormal_pattern_quote: "If you see \"planSummary\": \"COLLSCAN\": in the query log, the query performed a\ncollection scan and did not use an index. This is a strong signal to add an index\nor rewrite the query."
  abnormal_pattern_threshold: {"planSummary": "COLLSCAN", "operation_execution_time_ms": "consistently high"}
  metric_unit: ms / enum
  prerequisite_steps: []

[step 2] 检查 Docs Examined / Keys Examined / Examined:Returned 比
  metric_name: docsExamined / keysExamined / Docs Examined : Returned Ratio
  collection_layer: atlas-advisor
  collection_method_quote: (NULL · 原文是 Atlas UI 字段)
  abnormal_pattern_quote: "If this metric is 0 for a query that includes filter conditions, it's highly likely\nthere is no index and MongoDB scanned the entire collection. This is a primary cause of slowness."
  abnormal_pattern_threshold: {"keysExamined_with_filter": 0, "docsExamined_to_docsReturned": ">> 1 (high)"}
  metric_unit: documents / index keys
  prerequisite_steps: [1]

[step 3] 检查 Num Yields / Has Index Coverage / hasSort
  metric_name: numYields / usedIndex / hasSort
  collection_layer: atlas-advisor
  collection_method_quote: (NULL · 原文是 Atlas UI 字段)
  abnormal_pattern_quote: "Num Yields (numYields): Frequent yields suggest resource contention\nor long-running operations that are pausing, potentially impacting overall throughput."
  abnormal_pattern_threshold: {"numYields": "frequent", "usedIndex": false, "hasSort_unindexed": true}
  metric_unit: count / boolean
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] slowOpThresholdMs (Atlas-managed dynamic / fixed 100ms)
  param_name: slowOpThresholdMs (Atlas-managed dynamic / fixed 100ms)
  abnormal_value_pattern: 阈值过高时漏报慢查询;过低时 Profiler 写入开销大
  reasoning_quote: "This threshold can be changed using the\ndb.setProfilingLevel\nmongosh command."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "If Docs Examined is very high and Keys Examined is 0 or\nvery low compared to Docs Examined, you're likely scanning the collection\nor a very unselective index."
  linked_diagnostic_step_no: 2
  mitigation_quote: "Has Index Coverage (usedIndex): This boolean confirms whether a MongoDB\nindex was used. If set to false for a query that should be indexed, add an index."

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "Num Yields (numYields): Frequent yields suggest resource contention\nor long-running operations that are pausing, potentially impacting overall throughput."
  linked_diagnostic_step_no: 3
  mitigation_quote: (NULL · 原文未给 yield 类直接修复)

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "Unindexed sort() methods can be very resource intensive."
  linked_diagnostic_step_no: 3
  mitigation_quote: "Check your search index configuration and confirm whether it supports the\nsort() method."

[non_parameter_causes · cause 4] application-design
  cause_type: application-design
  description_quote: "Response Length: Unusually large response lengths indicate that queries\nare returning more data than necessary. Consider using projections to limit the fields\nreturned."
  linked_diagnostic_step_no: 3
  mitigation_quote: "Consider using projections to limit the fields\nreturned."

```

## case_id: mongo-locking-queue-buildup-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **title**: 锁等待队列堆积导致请求被阻塞
- **source_heading**: Locking Performance
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/manual/administration/analyzing-mongodb-performance/
- **source_url_lang**: en

### symptom_description

> MongoDB uses a locking system to ensure data set consistency. If certain operations are long-running or a queue forms, performance will degrade as requests and operations wait for the lock.

### diagnostic_steps

```
[step 1] 看 globalLock.currentQueue.total 是否持续高位
  metric_name: globalLock.currentQueue.total
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "globalLock section of the"
  abnormal_pattern_quote: "If globalLock.currentQueue.total is consistently high, then there is a chance that a large number of requests are waiting for a lock."
  abnormal_pattern_threshold: currentQueue.total 持续 > 0(即业务 RPS 远低于 globalLock 排队增量)
  metric_unit: count
  prerequisite_steps: []

[step 2] 看 globalLock.totalTime 与 uptime 比
  metric_name: globalLock.totalTime / uptime
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "globalLock section of the"
  abnormal_pattern_quote: "If globalLock.totalTime is high relative to uptime, the database has existed in a lock state for a significant amount of time."
  abnormal_pattern_threshold: totalTime / uptime ≫ 等同业务持续在 lock 状态
  metric_unit: microseconds / seconds
  prerequisite_steps: [1]

[step 3] 看 deadlock 与等锁均值
  metric_name: locks.<type>.deadlockCount + locks.<type>.timeAcquiringMicros / acquireWaitCount
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "Dividing locks.<type>.timeAcquiringMicros by locks.<type>.acquireWaitCount can give an approximate average wait time for a particular lock mode."
  abnormal_pattern_quote: "locks.<type>.deadlockCount provide the number of times the lock acquisitions encountered deadlocks."
  abnormal_pattern_threshold: 平均等锁时间(微秒)偏离基线 ≫ 1× 或 deadlockCount > 0
  metric_unit: microseconds + count
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Long queries can result from ineffective use of indexes; non-optimal schema design; poor query structure; system architecture issues; or insufficient RAM resulting in disk reads."
  linked_diagnostic_step_no: 3
  mitigation_quote: (NULL · 原文未给具体修复命令)

[non_parameter_causes · cause 2] hardware-memory-physical
  cause_type: hardware-memory-physical
  description_quote: "insufficient RAM resulting in disk reads"
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · 原文未给具体修复 · 同上 ref)

```

## case_id: mongo-connection-storm-driver-error-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: connection-storm
- **case_pattern**: core-perf-diagnosis
- **title**: 连接数飙升 → 服务器吃不下请求
- **source_heading**: Number of Connections
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://www.mongodb.com/docs/manual/administration/analyzing-mongodb-performance/
- **source_url_lang**: en

### symptom_description

> In some cases, the number of connections between the applications and the database can overwhelm the ability of the server to handle requests.

### diagnostic_steps

```
[step 1] 看 connections.current 与 connections.available
  metric_name: connections.current / connections.available
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "The following fields in the serverStatus document can provide insight"
  abnormal_pattern_quote: "If there are numerous concurrent application requests, the database may have trouble keeping up with demand."
  abnormal_pattern_threshold: connections.current 接近 maxIncomingConnections;available → 0
  metric_unit: count
  prerequisite_steps: []

[step 2] 比对 connections.current 与实际 workload
  metric_name: connections.current vs workload (opcounters)
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "the total number of current clients connected to the database instance."
  abnormal_pattern_quote: "An extremely high number of connections, particularly without corresponding workload, is often indicative of a driver or other configuration error."
  abnormal_pattern_threshold: connections.current 高 但 opcounters 平稳 → 驱动 / 配置异常
  metric_unit: count
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] maxIncomingConnections / ulimit -n
  param_name: maxIncomingConnections / ulimit -n
  abnormal_value_pattern: maxIncomingConnections < 业务峰值;ulimit -n < maxIncomingConnections
  reasoning_quote: "Unless constrained by system-wide limits, the maximum number of incoming connections supported by MongoDB is configured with the maxIncomingConnections setting."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Spikes in the number of connections can also be the result of application or driver errors. All of the officially supported MongoDB drivers implement connection pooling, which allows clients to use and reuse connections more efficiently."
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · 原文未给逐字修复命令 · driver-side fix)

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "For write-heavy applications, deploy sharding and add one or more shards to a sharded cluster to distribute load among mongod instances."
  linked_diagnostic_step_no: 1
  mitigation_quote: "deploy sharding and add one or more shards to a sharded cluster to distribute load among mongod instances"

```

## case_id: mongo-wt-tickets-exhausted-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: lock-contention
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger 读写 ticket 持续 < 128 → 并发被限流
- **source_heading**: Run Your Queries at Top Speed → WiredTiger Ticket Number metric
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://www.mongodb.com/docs/manual/administration/performance-tuning/
- **source_url_lang**: en

### symptom_description

> The read and write tickets control the maximum number of concurrent transactions. The WiredTiger ticket number should always be at 128. Sustained values below 128 indicates a server delay and consequential potential issues.

### diagnostic_steps

```
[step 1] 用 serverStatus 看读写 ticket 当前数
  metric_name: wiredTiger.concurrentTransactions.{read,write}.{available,out,totalTickets}
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "You can use the serverStatus command to check the current number of read and write tickets and their usage"
  abnormal_pattern_quote: "Sustained values below 128 indicates a server delay and consequential potential issues"
  abnormal_pattern_threshold: available 持续 < 128(7.0+ 动态阈值;6.x 默认 128)
  metric_unit: count
  prerequisite_steps: []

[step 2] 看 queues.execution 段判负载与 ticket 可用性
  metric_name: queues.execution.read / queues.execution.write
  collection_layer: mongo-internal-counter
  collection_method_quote: "Look at the queues.execution section to understand the current load and ticket availability"
  abnormal_pattern_quote: "any new read or write requests will be queued until a new read or write ticket is available"
  abnormal_pattern_threshold: queues.execution.read 或 .write > 0 持续
  metric_unit: count
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] storageEngineConcurrentReadTransactions / storageEngineConcurrentWriteTransactions
  param_name: storageEngineConcurrentReadTransactions / storageEngineConcurrentWriteTransactions
  abnormal_value_pattern: 7.0+ 已禁用动态调整 或 手动设到 < 业务并发需求
  reasoning_quote: "If you need to manually adjust the maximum number of concurrent transactions, you can modify the storageEngineConcurrentReadTransactions and storageEngineConcurrentWriteTransactions parameters"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] hardware-cpu-physical
  cause_type: hardware-cpu-physical
  description_quote: "Ensure that your cluster has sufficient resources, such as CPU and memory, to handle the workload"
  linked_diagnostic_step_no: 1
  mitigation_quote: "Ensure that your cluster has sufficient resources, such as CPU and memory, to handle the workload"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "Locking performance problems can indicate suboptimal indexes and poor schema design patterns, which can both lead to locks being held longer than necessary"
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · 原文未给单条 fix 命令)

```

## case_id: mongo-replication-lag-multi-cause-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
- **title**: 复制集 secondary 落后 primary(4 类互斥根因)
- **source_heading**: Replication Lag
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 4
- **source_url**: https://www.mongodb.com/docs/manual/administration/performance-tuning/
- **source_url_lang**: en

### symptom_description

> Replication lag occurs when a secondary member of a replica set falls behind the primary.

### diagnostic_steps

```
[step 1] 看 oplog-related metrics 与 replSetGetStatus
  metric_name: replSetGetStatus.members[].optimeDate / oplog window
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "you can examine the oplog-related metrics"
  abnormal_pattern_quote: "the following problems are the most common causes of replication lag"
  abnormal_pattern_threshold: secondary optimeDate 落后 primary > SLA(原文未给具体阈值)
  metric_unit: seconds
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] network-physical-link
  cause_type: network-physical-link
  description_quote: "A networking issue between the primary and secondary"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给修复命令)

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "A secondary node applying data slower than the primary node"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 同上 ref)

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "Insufficient write capacity, in which case you should add more shards"
  linked_diagnostic_step_no: 1
  mitigation_quote: "you should add more shards"

[non_parameter_causes · cause 4] application-design
  cause_type: application-design
  description_quote: "Slow operations on the primary node, blocking replication"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 同 cause 1 ref)

```

## case_id: mongo-open-cursor-rising-no-traffic-03

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: open cursor 持续上升但流量未变
- **source_heading**: Open Cursors
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/performance-tuning/
- **source_url_lang**: en

### symptom_description

> If the number of open cursors is rising without a corresponding growth of traffic, this might be the result of poorly indexed queries, or long-running queries due to large result sets.

### diagnostic_steps

```
[step 1] 跟踪 metrics.cursor.open.total 趋势,与 opcounters 对比
  metric_name: metrics.cursor.open.total / opcounters.{query,getmore}
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未直接给采集命令)
  abnormal_pattern_quote: "the number of open cursors is rising without a corresponding growth of traffic"
  abnormal_pattern_threshold: metrics.cursor.open.total 增速 ≫ opcounters 增速
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "this might be the result of poorly indexed queries, or long-running queries due to large result sets"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给单条 fix)

```

## case_id: mongo-scan-and-order-high-04

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: Scan and Order 数高 → 服务端排序内存压力
- **source_heading**: Query Metrics
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/performance-tuning/
- **source_url_lang**: en

### symptom_description

> A high Scan and Order number, such as 20 or more, indicates that the server is having to sort results, increasing query result time and server memory load.

### diagnostic_steps

```
[step 1] 读 metrics.operation.scanAndOrder
  metric_name: metrics.operation.scanAndOrder
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给逐字采集命令)
  abnormal_pattern_quote: "A high Scan and Order number, such as 20 or more"
  abnormal_pattern_threshold: scanAndOrder 计数(累计或每秒) >= 20
  metric_unit: count
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "indicates that the server is having to sort results, increasing query result time and server memory load"
  linked_diagnostic_step_no: 1
  mitigation_quote: "To fix a high Scan and Order number, sort your indexes according to query requirements, or add any missing indexes"

```

## case_id: mongo-unbound-array-rewrite-pressure-05

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 文档中 array 无上限增长 → 每次更新触发整文档重写
- **source_heading**: Document Structure Antipatterns
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/performance-tuning/
- **source_url_lang**: en

### symptom_description

> Unbound arrays: Arrays in a document that can grow without a size limit cause performance problems, because each time you update the array, MongoDB must rewrite the array into the document.

### diagnostic_steps

```
[step 1] 看慢查询日志中重复出现的 array-update 操作
  metric_name: system.profile / slow query log + collStats.avgObjSize 趋势
  collection_layer: log-grep
  collection_method_quote: "The query plan does not contain any metrics to reveal document structure antipatterns, but you can look for antipatterns when debugging slow queries."
  abnormal_pattern_quote: "each time you update the array, MongoDB must rewrite the array into the document"
  abnormal_pattern_threshold: collStats.avgObjSize 单调增长 + 同一 array $push 慢查询反复出现
  metric_unit: bytes / ms
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Arrays in a document that can grow without a size limit cause performance problems"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文给的是反模式说明 + "see Avoid Unbounded Arrays" 跨文档跳转)

```

## case_id: mongo-driver-pool-size-too-small-vs-concurrent-requests-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: connection-storm
- **case_pattern**: parameter-audit
- **title**: driver 连接池大小 < 1.10×并发请求数 → 池排队
- **source_heading**: Drivers
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-development/
- **source_url_lang**: en

### symptom_description

> Adjust the connection pool size to suit your use case, beginning at 110-115% of the typical number of concurrent database requests.

### diagnostic_steps

```
[step 1] 比对 driver maxPoolSize 与应用层典型并发请求数
  metric_name: driver maxPoolSize · 应用层典型并发请求数
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#mongo-pool-maxpoolsize-readout-from-driver-knowledge)
  abnormal_pattern_quote: "beginning at 110-115% of the typical number of concurrent database requests"
  abnormal_pattern_threshold: maxPoolSize < 1.10 × 应用层典型并发请求数
  metric_unit: connections
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] maxPoolSize
  param_name: maxPoolSize
  abnormal_value_pattern: < 1.10 × 应用层典型并发请求数
  reasoning_quote: "Adjust the connection pool size to suit your use case, beginning at 110-115% of the typical number of concurrent database requests."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-fs-nfs-dbpath-degraded-unstable-perf-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-io-saturation
- **case_pattern**: parameter-audit
- **title**: dbPath 用 NFS 卷 → 性能下降且不稳定
- **source_heading**: Filesystem
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/
- **source_url_lang**: en

### symptom_description

> Using NFS drives can result in degraded and unstable performance.

### diagnostic_steps

```
[step 1] 检查 dbPath 所在挂载点的文件系统类型是否为 NFS
  metric_name: dbPath 挂载点文件系统类型
  collection_layer: os
  collection_method_quote: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#mongo-fs-mount-readout-from-shell-knowledge)
  abnormal_pattern_quote: "Using NFS drives can result in degraded and unstable performance."
  abnormal_pattern_threshold: 文件系统类型 ∈ {nfs, nfs4}
  metric_unit: (枚举)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] (deployment) dbPath 挂载点文件系统
  param_name: (deployment) dbPath 挂载点文件系统
  abnormal_value_pattern: NFS / NFSv4
  reasoning_quote: "Using NFS drives can result in degraded and unstable performance."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-fs-ext4-wiredtiger-perf-issue-should-use-xfs-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-io-saturation
- **case_pattern**: parameter-audit
- **title**: WiredTiger + EXT4 → 已知性能问题 · 应改 XFS
- **source_heading**: Filesystem
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/
- **source_url_lang**: en

### symptom_description

> to avoid performance issues found when using EXT4 with WiredTiger

### diagnostic_steps

```
[step 1] 检查 dbPath 文件系统类型
  metric_name: dbPath 挂载点文件系统类型
  collection_layer: os
  collection_method_quote: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#mongo-fs-mount-readout-from-shell-knowledge)
  abnormal_pattern_quote: "to avoid performance issues found when using EXT4 with WiredTiger"
  abnormal_pattern_threshold: 文件系统 = ext4 且 storage engine = wiredTiger
  metric_unit: (枚举)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] (deployment) dbPath 挂载点文件系统
  param_name: (deployment) dbPath 挂载点文件系统
  abnormal_value_pattern: ext4(配 storage.engine=wiredTiger)
  reasoning_quote: "If possible, use XFS as it generally performs better with MongoDB."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-tuned-profile-default-rhel-perf-impact-05

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: linux-os
- **symptom_category**: other
- **case_pattern**: parameter-audit
- **title**: RHEL/CentOS tuned profile 用默认值 → 对 MongoDB 性能负向影响
- **source_heading**: Linux
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-checklist-operations/
- **source_url_lang**: en

### symptom_description

> RHEL / CentOS can negatively impact performance with their default

### diagnostic_steps

```
[step 1] 读当前 active tuned profile
  metric_name: tuned-adm active 当前 profile 名
  collection_layer: os
  collection_method_quote: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#linux-tuned-profile-readout-from-linux-doc)
  abnormal_pattern_quote: "RHEL / CentOS can negatively impact performance with their default"
  abnormal_pattern_threshold: active profile ∈ 出厂默认 {throughput-performance, balanced, virtual-guest, ...} 且未做 MongoDB 适配
  metric_unit: (枚举)
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] tuned profile
  param_name: tuned profile
  abnormal_value_pattern: 出厂默认未做 MongoDB 适配(THP / readahead / scheduler 等)
  reasoning_quote: "RHEL / CentOS can negatively impact performance with their default"
  linked_diagnostic_step_no: 1

```

## case_id: mongo-startup-kernel-6-19-tcmalloc-incompat-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: startup-failure
- **case_pattern**: parameter-audit
- **title**: MongoDB 8.0+ 在 Linux Kernel 6.19 上启动 crash
- **source_heading**: MongoDB 8.0 Incompatible with Kernel 6.19
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/
- **source_url_lang**: en

### symptom_description

> Due to an incompatibility between a new kernel release and the currently vendored version of TCMalloc, running MongoDB 8.0 or newer with Linux kernel version 6.19 can cause MongoDB to crash on startup. This applies to all MongoDB packages, including those obtained from the MongoDB website, or obtained from package managers or Docker.

### diagnostic_steps

```
[step 1] 同时看 mongod 版本 + kernel 版本
  metric_name: mongod --version + uname -r
  collection_layer: os
  collection_method_quote: (原文未给具体命令 · 通用 `mongod --version` + `uname -r`)
  abnormal_pattern_quote: "running MongoDB 8.0 or newer with Linux kernel version 6.19 can cause MongoDB to crash on startup"
  abnormal_pattern_threshold: mongod major >= 8 AND kernel == 6.19.x
  metric_unit: version
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] os-version-bug
  cause_type: os-version-bug
  description_quote: "Due to an incompatibility between a new kernel release and the currently vendored version of TCMalloc"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文给的是未来通告而非可执行 mitigation)

```

## case_id: mongo-network-tcp-keepalive-too-long-cloud-lb-drops-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: linux-os
- **symptom_category**: network-latency
- **case_pattern**: parameter-audit
- **title**: tcp_keepalive_time 大于云 LB 空闲超时 → 连接被静默切断
- **source_heading**: Adjust tcp_keepalive_time
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/
- **source_url_lang**: en

### symptom_description

> If the TCP keepalive value is greater than the TCP idle timeout on your cloud provider's load balancer, there is a risk that the system might silently drop connections.

### diagnostic_steps

```
[step 1] 看当前 tcp_keepalive_time
  metric_name: net.ipv4.tcp_keepalive_time
  collection_layer: os
  collection_method_quote: "sysctl net.ipv4.tcp_keepalive_time"
  abnormal_pattern_quote: "If the TCP keepalive value is greater than the TCP idle timeout on your cloud provider's load balancer"
  abnormal_pattern_threshold: 当前值 > 云 LB 空闲超时(常见 60-120 秒)
  metric_unit: seconds
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] net.ipv4.tcp_keepalive_time
  param_name: net.ipv4.tcp_keepalive_time
  abnormal_value_pattern: 默认 7200(2 小时),远大于云 LB 空闲超时
  reasoning_quote: "To reduce this risk, set tcp_keepalive_time to 120."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-numa-cross-node-memory-degradation-04

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: cpu-high
- **case_pattern**: core-perf-diagnosis
- **title**: MongoDB 在 NUMA 硬件上跨节点访问导致间歇性慢
- **source_heading**: MongoDB and NUMA Hardware
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/
- **source_url_lang**: en

### symptom_description

> Running MongoDB on a system with Non-Uniform Memory Access (NUMA) can cause a number of operational problems, including slow performance for periods of time and high system process usage.

### diagnostic_steps

```
[step 1] 看 mongod 启动日志中是否有 NUMA warning
  metric_name: mongod startup log · NUMA warning 行
  collection_layer: log-grep
  collection_method_quote: "MongoDB checks NUMA settings on start up when deployed on Linux (since version 2.0) and Windows (since version 2.6) machines. If the NUMA configuration may degrade performance, MongoDB prints a warning."
  abnormal_pattern_quote: "If the NUMA configuration may degrade performance, MongoDB prints a warning."
  abnormal_pattern_threshold: mongod 启动日志含 "NUMA" warning
  metric_unit: bool
  prerequisite_steps: []

[step 2] 看 numad daemon 是否在跑
  metric_name: numad 进程
  collection_layer: os
  collection_method_quote: (通用 `pgrep -f numad`)
  abnormal_pattern_quote: "The numad daemon process can also reduce mongod performance. You should ensure numad is not enabled on MongoDB servers."
  abnormal_pattern_threshold: numad 进程在跑
  metric_unit: bool
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] numactl --interleave=all (启动 mongod 时)
  param_name: numactl --interleave=all (启动 mongod 时)
  abnormal_value_pattern: 直接 `mongod` 启动 · 未走 numactl interleave
  reasoning_quote: "you should configure a memory interleave policy so that the host behaves in a non-NUMA fashion"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "The numad daemon process can also reduce mongod performance."
  linked_diagnostic_step_no: 2
  mitigation_quote: "You should ensure numad is not enabled on MongoDB servers."

```

## case_id: mongo-os-vm-swappiness-default-60-aggressive-swap-05

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: linux-os
- **symptom_category**: memory-pressure
- **case_pattern**: parameter-audit
- **title**: vm.swappiness 默认 60 → MongoDB 频繁 swap 性能下降
- **source_heading**: Set vm.swappiness to 1 or 0
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/
- **source_url_lang**: en

### symptom_description

> "Swappiness" is a Linux kernel setting that influences the behavior of the Virtual Memory manager. The vm.swappiness setting ranges from 0 to 100: the higher the value, the more strongly it prefers swapping memory pages to disk over dropping pages from RAM.

### diagnostic_steps

```
[step 1] 看当前 vm.swappiness
  metric_name: vm.swappiness
  collection_layer: os
  collection_method_quote: (通用 `cat /proc/sys/vm/swappiness` 或 `sysctl vm.swappiness`)
  abnormal_pattern_quote: "A setting of 60 tells the kernel to swap to disk often, and is the default value on many Linux distributions."
  abnormal_pattern_threshold: 当前值 > 1
  metric_unit: int
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] vm.swappiness
  param_name: vm.swappiness
  abnormal_value_pattern: 默认 60
  reasoning_quote: "MongoDB performs best where swapping can be avoided or kept to a minimum. As such you should set vm.swappiness to eithe"(原文截断,完整意为应设 0 或 1)
  linked_diagnostic_step_no: 1

```

## case_id: mongo-aws-ec2-storage-network-tuning-06

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **title**: AWS EC2 上 MongoDB 性能不可重现 / 不达上限
- **source_heading**: AWS EC2
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://www.mongodb.com/docs/manual/administration/production-notes/
- **source_url_lang**: en

### symptom_description

> There are two performance configurations to consider: Reproducible performance for performance testing or benchmarking, and Raw maximum performance

### diagnostic_steps

```
[step 1] 看 EC2 实例类型 + 网络与存储配置
  metric_name: EC2 instance type / Enhanced Networking 状态 / EBS provisioned IOPS
  collection_layer: os
  collection_method_quote: (原文未给读取命令 · AWS 侧通用 `aws ec2 describe-instances` 或 `cat /sys/class/net/<eth>/queues/`)
  abnormal_pattern_quote: "Not all instance types support Enhanced Networking."
  abnormal_pattern_threshold: Enhanced Networking 未启用 / 用 ephemeral SSD 而非 provisioned IOPS
  metric_unit: bool / IOPS
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] net.ipv4.tcp_keepalive_time
  param_name: net.ipv4.tcp_keepalive_time
  abnormal_value_pattern: 默认 7200,EC2 ELB/NLB 切连接
  reasoning_quote: "Set tcp_keepalive_time to 120."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] hardware-network
  cause_type: hardware-network
  description_quote: (NULL · 原文是 mitigation 句而非 cause 描述)
  linked_diagnostic_step_no: 1
  mitigation_quote: (升级到支持 Enhanced Networking 的实例类型)

[non_parameter_causes · cause 2] hardware-disk
  cause_type: hardware-disk
  description_quote: (NULL · 原文是 mitigation 句而非 cause 描述)
  linked_diagnostic_step_no: 1
  mitigation_quote: (改用 provisioned IOPS EBS · journal/data 分独立卷)

```

## case_id: mongo-tcmalloc-percpu-caches-not-enabled-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: linux-arm64-kunpeng
- **engine**: mixed
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: MongoDB 8.0 TCMalloc per-CPU caches 未启用 → 高负载下内存碎片与性能退化
- **source_heading**: TCMalloc Performance Optimization for a Self-Managed Deployment
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 3
- **source_url**: https://www.mongodb.com/docs/manual/administration/tcmalloc-performance/
- **source_url_lang**: en

### symptom_description

> per-CPU caches, instead of per-thread caches, to reduce memory fragmentation and make your database more resilient to high-stress workloads.

### diagnostic_steps

```
[step 1] 读 serverStatus 中 tcmalloc 字段判断 per-CPU caches 是否生效
  metric_name: tcmalloc.usingPerCPUCaches / tcmalloc.tcmalloc.cpu_free
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "To verify that TCMalloc is running with per-CPU caches, ensure that"
  abnormal_pattern_quote: "tcmalloc.usingPerCPUCaches is true"
  abnormal_pattern_threshold: usingPerCPUCaches != true 或 cpu_free <= 0
  metric_unit: bool / count
  prerequisite_steps: []

[step 2] 检查 glibc 是否抢先注册了 rseq
  metric_name: glibc.pthread.rseq tunable / GLIBC_TUNABLES env
  collection_layer: os
  collection_method_quote: (NULL · 原文给的是 mitigation env 设置,未给只读检查命令)
  abnormal_pattern_quote: "If another application, such as the glibc library, registers an rseq structure before TCMalloc, TCMalloc can't use rseq"
  abnormal_pattern_threshold: glibc rseq 已注册而 TCMalloc 启动时拿不到
  metric_unit: flag
  prerequisite_steps: [1]

[step 3] 检查内核版本是否 >= 4.18
  metric_name: kernel version
  collection_layer: os
  collection_method_quote: "uname -r"
  abnormal_pattern_quote: "If you disabled glibc rseq and per-CPU caches are still not enabled, ensure that you're using Linux kernel version 4.18 or later"
  abnormal_pattern_threshold: uname -r 主版本 < 4.18
  metric_unit: version
  prerequisite_steps: [1, 2]

```

### likely_causes

```
[parameter_causes · cause 1] GLIBC_TUNABLES (env)
  param_name: GLIBC_TUNABLES (env)
  abnormal_value_pattern: 未设 glibc.pthread.rseq=0 → glibc 抢先注册 rseq
  reasoning_quote: "To ensure that TCMalloc can use rseq to enable per-CPU caches, you can disable glibc"
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] os-version-bug
  cause_type: os-version-bug
  description_quote: "You're using Linux kernel version 4.18 or later"
  linked_diagnostic_step_no: 3
  mitigation_quote: (NULL · 原文未给具体升级命令)

[non_parameter_causes · cause 2] os-version-bug
  cause_type: os-version-bug
  description_quote: "These operating systems use the legacy TCMalloc version. If you use these operating systems, disable THP."
  linked_diagnostic_step_no: 1
  mitigation_quote: "If you use these operating systems, disable THP."

```

## case_id: mongo-inmemory-cache-full-overflow-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: parameter-audit
- **title**: In-memory storage engine 数据超出 inMemorySizeGB → WT_CACHE_FULL
- **source_heading**: Memory Use
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/core/inmemory/
- **source_url_lang**: en

### symptom_description

> If a write operation would cause the data to exceed the specified memory size, MongoDB returns with the error

### diagnostic_steps

```
[step 1] 看 mongod 日志中是否含 WT_CACHE_FULL 错误
  metric_name: mongod log "WT_CACHE_FULL" 出现频次
  collection_layer: log-grep
  collection_method_quote: (NULL · 原文未给具体 grep 命令)
  abnormal_pattern_quote: "WT_CACHE_FULL: operation would overflow cache"
  abnormal_pattern_threshold: 任意一次出现该错误即异常
  metric_unit: count
  prerequisite_steps: []

[step 2] 比对当前 in-memory 用量与 inMemorySizeGB 配置
  metric_name: dbStats / collStats 总 size vs inMemorySizeGB
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "To specify a new size, use the"
  abnormal_pattern_quote: "If a write operation would cause the data to exceed the specified memory size"
  abnormal_pattern_threshold: sum(dbStats.dataSize) + indexes + oplog 接近 inMemorySizeGB
  metric_unit: bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] storage.inMemory.engineConfig.inMemorySizeGB / --inMemorySizeGB
  param_name: storage.inMemory.engineConfig.inMemorySizeGB / --inMemorySizeGB
  abnormal_value_pattern: inMemorySizeGB < 当前业务总数据(含索引 + oplog)
  reasoning_quote: "By default, the in-memory storage engine uses 50% of physical RAM minus 1 GB"
  linked_diagnostic_step_no: 2

```

## case_id: mongo-psa-majority-writeconcern-perf-degradation-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
- **title**: PSA 架构 + majority write concern · secondary 不可用/落后导致写性能下降与读 stale
- **source_heading**: Performance Issues with PSA replica sets
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 3
- **source_url**: https://www.mongodb.com/docs/manual/core/replica-set-arbiter/
- **source_url_lang**: en

### symptom_description

> performance issues if a secondary is unavailable or lagging

### diagnostic_steps

```
[step 1] 检查副本集拓扑是否为 PSA 三成员架构
  metric_name: replSetGetStatus.members[] 的 stateStr 分布(PRIMARY/SECONDARY/ARBITER)
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给读取拓扑命令 · 见 reference/_pending/agent2.md#mongo-replset-status-readout-from-mongo-doc)
  abnormal_pattern_quote: "three-member primary-secondary-arbiter (PSA) architecture"
  abnormal_pattern_threshold: 拓扑 = 1 PRIMARY + 1 SECONDARY + 1 ARBITER(只有 1 个 data-bearing secondary)
  metric_unit: (枚举)
  prerequisite_steps: []

[step 2] 检查 secondary 是否健康及 lag 情况
  metric_name: secondary 的 health/state · optimeDate 与 primary 的差距
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给具体命令 · 见 reference/_pending/agent2.md#mongo-replset-secondary-health-readout-from-mongo-doc)
  abnormal_pattern_quote: "if a secondary is unavailable or lagging"
  abnormal_pattern_threshold: secondary state ≠ SECONDARY · 或 lag (primary.optimeDate − secondary.optimeDate) 显著 > 0
  metric_unit: seconds
  prerequisite_steps: [1]

[step 3] 读取当前 default write concern / 关注业务侧使用的 write concern
  metric_name: getDefaultRWConcern → defaultWriteConcern.w
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给具体命令 · 见 reference/_pending/agent2.md#mongo-default-rwconcern-readout-from-mongo-doc)
  abnormal_pattern_quote: "and the write concern is less than the size of the majority, your queries may return stale (not fully replicated) data."
  abnormal_pattern_threshold: default write concern w < majority(== 2 in PSA) → 风险:stale read;w == majority → 风险:secondary 异常时写卡
  metric_unit: (枚举)
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] defaultWriteConcern.w(及业务调用侧 write concern)
  param_name: defaultWriteConcern.w(及业务调用侧 write concern)
  abnormal_value_pattern: `"majority"` 同时 secondary 不健康(写卡);或 < majority(读 stale)
  reasoning_quote: "performance issues if a secondary is unavailable or lagging"
  linked_diagnostic_step_no: 3

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "If you are using a three-member primary-secondary-arbiter (PSA) architecture, consider the following:"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给改架构的 mitigation,只链接到外部 mitigation 文档 · 见 reference/_pending/agent2.md#mongo-psa-mitigation-not-explicit)

[non_parameter_causes · cause 2] hardware-disk
  cause_type: hardware-disk
  description_quote: "if a secondary is unavailable or lagging"
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · 本页不展开物理排查 · 见 reference/_pending/agent2.md#mongo-secondary-unavailable-mitigation-not-explicit)

```

## case_id: mongo-wt-cache-size-misconfigured-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: parameter-audit
- **title**: WiredTiger 内部 cache 大小被人工调高 → 与 filesystem cache 抢内存
- **source_heading**: Cache Configuration Settings
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/manual/core/wiredtiger/
- **source_url_lang**: en

### symptom_description

> Avoid increasing the WiredTiger internal cache size above its default value

### diagnostic_steps

```
[step 1] 读 storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct 当前值
  metric_name: storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给具体读取命令)
  abnormal_pattern_quote: "Avoid increasing the WiredTiger internal cache size above its default value"
  abnormal_pattern_threshold: cacheSizeGB > 默认 50%(RAM - 1GB);或 cacheSizePct > 80%
  metric_unit: bytes / percent
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct
  param_name: storage.wiredTiger.engineConfig.cacheSizeGB / cacheSizePct
  abnormal_value_pattern: 超过 "50% of (RAM - 1GB)" 默认基线 · 原文允许上限 80%
  reasoning_quote: "The default WiredTiger internal cache size is the larger of either"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "WiredTiger doesn't reserve a portion of the cache for reads and another for writes"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文给的是机制说明而非 fix)

```

## case_id: mongo-explain-sort-stage-disk-spill-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: $sort 或 SORT 阶段 spill 到磁盘 → 排序内存压力
- **source_heading**: Sort Stage · $sort and $group Stages
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/manual/reference/explain-results/
- **source_url_lang**: en

### symptom_description

> If MongoDB cannot use an index or indexes

### diagnostic_steps

```
[step 1] 看 explain output 中是否含显式 SORT stage
  metric_name: explain.queryPlanner.winningPlan SORT stage 是否存在
  collection_layer: mongo-shell
  collection_method_quote: "If the explain plan does not contain an explicit"
  abnormal_pattern_quote: "in-memory sort operation"
  abnormal_pattern_threshold: winningPlan 树中存在 stage='SORT' 节点(意味没用 index 排序)
  metric_unit: enum
  prerequisite_steps: []

[step 2] 在 executionStats / allPlansExecution mode 看 $sort/$group 的 usedDisk / spills 计数
  metric_name: $sort.usedDisk / $sort.spills / $sort.spilledBytes / $sort.spilledRecords / $sort.spilledDataStorageSize
  collection_layer: mongo-shell
  collection_method_quote: "Whether the stage wrote to disk"
  abnormal_pattern_quote: "The number of times the stage spilled to disk"
  abnormal_pattern_threshold: usedDisk == true · spills > 0 · spilledBytes > 0
  metric_unit: bool / count / bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "If MongoDB cannot use an index or indexes"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给 fix 命令)

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "An estimate of the number of bytes written to disk"
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · 原文是字段定义而非 fix · 同上 ref)

```

## case_id: mongo-pool-connect-timeout-too-large-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: network-latency
- **case_pattern**: parameter-audit
- **title**: connectTimeoutMS 默认或过大 → 应用侧操作时间慢但 DB 侧未见
- **source_heading**: Tuning Your Connection Pool Settings
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/
- **source_url_lang**: en

### symptom_description

> Slow application-side operation times that are not reflected in

### diagnostic_steps

```
[step 1] 读 driver connectTimeoutMS 当前值,与到副本集成员的最长网络延迟对比
  metric_name: driver connectTimeoutMS 当前值 vs 副本集成员最长网络延迟
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文是建议而非读取命令 · 见 reference/_pending/agent2.md#mongo-pool-connecttimeoutms-readout-from-driver-knowledge)
  abnormal_pattern_quote: "Slow application-side operation times that are not reflected in"
  abnormal_pattern_threshold: connectTimeoutMS 小于到副本集任一成员的网络延迟
  metric_unit: milliseconds
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] connectTimeoutMS
  param_name: connectTimeoutMS
  abnormal_value_pattern: < (副本集任一成员到 client 的网络延迟)
  reasoning_quote: "Set connectTimeoutMS to a value greater than the longest network latency you have to a member of the set."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-pool-socket-timeout-firewall-half-close-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: connection-storm
- **case_pattern**: parameter-audit
- **title**: 防火墙错关连接 driver 不感知 → 应通过 socketTimeoutMS 兜底
- **source_heading**: Tuning Your Connection Pool Settings
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/
- **source_url_lang**: en

### symptom_description

> A misconfigured firewall closes a socket connection incorrectly and the driver cannot detect that the connection closed improperly.

### diagnostic_steps

```
[step 1] 读 driver socketTimeoutMS 当前值,与最慢操作耗时对比
  metric_name: driver socketTimeoutMS 当前值 vs 应用最慢合法操作耗时
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文是建议而非读取命令 · 见 reference/_pending/agent2.md#mongo-pool-sockettimeoutms-readout-from-driver-knowledge)
  abnormal_pattern_quote: "A misconfigured firewall closes a socket connection incorrectly and the driver cannot detect that the connection closed improperly."
  abnormal_pattern_threshold: socketTimeoutMS 未设 / 设过大,导致 driver 持有半关连接长时间挂死
  metric_unit: milliseconds
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] socketTimeoutMS
  param_name: socketTimeoutMS
  abnormal_value_pattern: 未设 / 远大于业务最慢操作耗时
  reasoning_quote: "Set socketTimeoutMS to two or three times the length of the slowest operation that the driver runs."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] network-physical-link
  cause_type: network-physical-link
  description_quote: "A misconfigured firewall closes a socket connection incorrectly and the driver cannot detect that the connection closed improperly."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文 mitigation 是 socketTimeoutMS 兜底 · 物理修法是修防火墙 · 见 reference/_pending/agent2.md#mongo-pool-firewall-mitigation-not-explicit)

```

## case_id: mongo-pool-minpoolsize-too-low-startup-creating-conns-03

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: connection-storm
- **case_pattern**: parameter-audit
- **title**: 启动期可用连接不足 → 应用频繁建新连接 → minPoolSize 太小
- **source_heading**: Tuning Your Connection Pool Settings
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/
- **source_url_lang**: en

### symptom_description

> the application spends too much time creating new connections

### diagnostic_steps

```
[step 1] 比较 driver minPoolSize 当前值与"启动期希望可用连接数"
  metric_name: driver minPoolSize · 服务器日志 / real time 面板 connection 创建速率
  collection_layer: log-grep
  collection_method_quote: (NULL · 原文未给具体读取命令,仅说"server logs or real time panel show" · 见 reference/_pending/agent2.md#mongo-pool-conn-create-rate-readout-shell-knowledge)
  abnormal_pattern_quote: "the application spends too much time creating new connections"
  abnormal_pattern_threshold: minPoolSize 远小于启动期峰值并发(导致大量临时建连)
  metric_unit: connections / second
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] minPoolSize
  param_name: minPoolSize
  abnormal_value_pattern: 远小于启动期实际并发数
  reasoning_quote: "Set minPoolSize to the number of connections you want to be available at startup."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-pool-maxpoolsize-too-low-underutilized-04

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: parameter-audit
- **title**: DB 负载低、活跃连接少、应用吞吐低于预期 → maxPoolSize 太小限流了
- **source_heading**: Tuning Your Connection Pool Settings
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/
- **source_url_lang**: en

### symptom_description

> The load on the database is low and there's a small number of active connections at any time.

### diagnostic_steps

```
[step 1] 读 driver maxPoolSize 与应用层活跃线程数
  metric_name: driver maxPoolSize · 应用活跃线程数 / 实际每秒操作数
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给读取命令,实际需读 driver 配置 + 应用线程池配置 · 见 reference/_pending/agent2.md#mongo-pool-maxpoolsize-readout-from-driver-knowledge)
  abnormal_pattern_quote: "The load on the database is low and there's a small number of active connections at any time."
  abnormal_pattern_threshold: maxPoolSize 接近活跃线程数;DB 资源未饱和但吞吐受限
  metric_unit: connections
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] maxPoolSize
  param_name: maxPoolSize
  abnormal_value_pattern: 小于应用层活跃线程数 / 实际并发需求
  reasoning_quote: "Increase maxPoolSize, or increase the number of active threads in your application or the framework you are using."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-pool-maxpoolsize-too-high-cpu-pressure-05

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: cpu-high
- **case_pattern**: parameter-audit
- **title**: DB CPU 比预期高 + 连接尝试比预期多 → maxPoolSize 太大压垮服务端
- **source_heading**: Tuning Your Connection Pool Settings
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 1
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/connection-pool-performance-tuning/
- **source_url_lang**: en

### symptom_description

> Database CPU usage is higher than expected. The server logs or real time panel show more connection attempts than expected.

### diagnostic_steps

```
[step 1] 比较 driver maxPoolSize 与服务端 CPU / connection 接受速率
  metric_name: driver maxPoolSize · 服务端 CPU% · connection accept rate
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给读取命令 · 见 reference/_pending/agent2.md#mongo-pool-server-cpu-readout-from-shell-knowledge)
  abnormal_pattern_quote: "Database CPU usage is higher than expected. The server logs or real time panel show more connection attempts than expected."
  abnormal_pattern_threshold: 服务端 CPU 持续高位 + 连接尝试速率显著上升
  metric_unit: percent / connections per second
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] maxPoolSize
  param_name: maxPoolSize
  abnormal_value_pattern: 远大于服务端可承载并发,或应用线程数远大于实际需要
  reasoning_quote: "Decrease the maxPoolSize or reduce the number of threads in your application."
  linked_diagnostic_step_no: 1

```

## case_id: mongo-slow-query-explain-multi-stage-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 慢查询 explain() 五步排查链路
- **source_heading**: Explain Slow Queries
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/explain-slow-queries/
- **source_url_lang**: en

### symptom_description

> If the execution time is above an acceptable period, further analysis is required to determine why the query takes so long to execute.

### diagnostic_steps

```
[step 1] 看 executionTimeMillis 判定是否超 SLA
  metric_name: explain.executionStats.executionTimeMillis
  collection_layer: mongo-shell
  collection_method_quote: "to see the execution time in milliseconds"
  abnormal_pattern_quote: "If the execution time is above an acceptable period, further analysis is required to determine why the query takes so long to execute"
  abnormal_pattern_threshold: 单条 query executionTimeMillis > 业务 SLA 上限(原文未给数值)
  metric_unit: ms
  prerequisite_steps: []

[step 2] 看 executionStages.inputStage.stage 是否为 COLLSCAN
  metric_name: explain.executionStats.executionStages.inputStage.stage
  collection_layer: mongo-shell
  collection_method_quote: "for each execution stage"
  abnormal_pattern_quote: "Queries that perform filter or sort operations"
  abnormal_pattern_threshold: inputStage.stage == COLLSCAN(应是 IXSCAN)
  metric_unit: enum
  prerequisite_steps: [1]

[step 3] 看 keysExamined vs docsExamined 比
  metric_name: executionStats.totalKeysExamined / executionStats.totalDocsExamined
  collection_layer: mongo-shell
  collection_method_quote: "Compare the number of keys examined to the number of documents examined. If the number of keys is significantly less than the number of documents, it indicates the indexes were ineffective"
  abnormal_pattern_quote: "Queries on collections with indexes may not make effective use of the indexes"
  abnormal_pattern_threshold: totalKeysExamined ≪ totalDocsExamined → 索引未生效
  metric_unit: ratio
  prerequisite_steps: [1]

[step 4] 看 totalDocsExamined / nReturned 比
  metric_name: executionStats.totalDocsExamined / executionStats.nReturned
  collection_layer: mongo-shell
  collection_method_quote: "Queries that use filters to specify the results may have issues"
  abnormal_pattern_quote: "indicates an ineffective index. That is, MongoDB had to scan the collection in order to filter the results"
  abnormal_pattern_threshold: totalDocsExamined / nReturned ≫ 1 → 过滤效率差
  metric_unit: ratio
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "If the query returns a small number of fields and the application is not write intensive on this collection, consider adding indexes to cover the query."
  linked_diagnostic_step_no: 2
  mitigation_quote: "consider adding indexes to cover the query"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "If the number of keys examined is much lower than the number of documents examined"
  linked_diagnostic_step_no: 3
  mitigation_quote: (NULL · 原文该段被 anchor 拍平)

```

## case_id: mongo-profiler-threshold-sampling-audit-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: other
- **case_pattern**: parameter-audit
- **title**: profiler 慢查询阈值 / 抽样率默认配置审计
- **source_heading**: Specify the Threshold for Slow Operations · Profile a Random Sample of Slow Operations
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 3
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/manage-the-database-profiler/
- **source_url_lang**: en

### symptom_description

> By default, the slow operation threshold is 100 milliseconds

### diagnostic_steps

```
[step 1] 用 db.getProfilingStatus() 看当前 slowms 与 sampleRate
  metric_name: profile.slowms / profile.sampleRate / profile.was
  collection_layer: mongo-shell
  collection_method_quote: "db.getProfilingStatus()"
  abnormal_pattern_quote: "By default, the slow operation threshold is 100 milliseconds"
  abnormal_pattern_threshold: slowms != 业务期望(默认 100ms);sampleRate < 1.0 但又依赖完整慢日志
  metric_unit: ms / ratio
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] operationProfiling.slowOpThresholdMs / db.setProfilingLevel slowms
  param_name: operationProfiling.slowOpThresholdMs / db.setProfilingLevel slowms
  abnormal_value_pattern: 默认 100ms · 业务期望更紧或更宽
  reasoning_quote: "To change the slow operation threshold, use one of the following"
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] operationProfiling.slowOpSampleRate / setProfilingLevel sampleRate
  param_name: operationProfiling.slowOpSampleRate / setProfilingLevel sampleRate
  abnormal_value_pattern: sampleRate == 1.0 + profiling level 1 + 高 QPS → 写 system.profile 占比拉升
  reasoning_quote: "By default, sampleRate is set to"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "When enabled, profiling affects database performance, especially at"
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文给出建议是"用 sampleRate 抽样" + "短期开启")

```

## case_id: mongo-8x-thp-disabled-tcmalloc-suboptimal-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: THP 未启用导致 MongoDB 8.0+ 新 TCMalloc 优化失效
- **source_heading**: Enable Transparent Hugepages (THP)
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/transparent-huge-pages/
- **source_url_lang**: en

### symptom_description

> Transparent Hugepages (THP) is a Linux memory management system that reduces the overhead of Translation Lookaside Buffer (TLB) lookups. THP achieves this by combining small pages and making them appear as larger memory pages to the application. In MongoDB 8.0 and later, ensure that THP is enabled before .

### diagnostic_steps

```
[step 1] 读当前 THP / defrag / khugepaged 状态
  metric_name: /sys/kernel/mm/transparent_hugepage/{enabled,defrag,khugepaged/defrag}
  collection_layer: os
  collection_method_quote: "cat /sys/kernel/mm/transparent_hugepage/enabled && cat /sys/kernel/mm/transparent_hugepage/defrag && cat /sys/kernel/mm/transparent_hugepage/khugepaged"
  abnormal_pattern_quote: (启用应为 `[always] madvise never`,即方括号在 always 上;若为 `[never]` 则 THP 未启用)
  abnormal_pattern_threshold: enabled 当前值不是 `always`
  metric_unit: enum
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] kernel transparent_hugepage/enabled(可通过 systemd / init.d / kernel boot param 启用)
  param_name: kernel transparent_hugepage/enabled(可通过 systemd / init.d / kernel boot param 启用)
  abnormal_value_pattern: never 或 madvise(对 MongoDB 8.0+ 新 TCMalloc 不优化)
  reasoning_quote: "In MongoDB 8.0 and later, ensure that THP is enabled before ."
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "tuned and ktune are kernel tuning utilities that can affect the Transparent Hugepages setting on your system."
  linked_diagnostic_step_no: 1
  mitigation_quote: "If you are using tuned or ktune on your RHEL or CentOS system while running mongod, you must create a custom tuned profile to ensure that THP stays enabled."

```

## case_id: mongo-replica-set-replication-lag-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
- **title**: 副本集复制延迟(replication lag)
- **source_heading**: Check the Replication Lag
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 6
- **source_url**: https://www.mongodb.com/docs/manual/tutorial/troubleshoot-replica-sets/
- **source_url_lang**: en

### symptom_description

> Replication lag is a delay between an operation on the primary and the application of that operation from the oplog to the secondary. Replication lag can be a significant issue and can seriously affect MongoDB replica set deployments. Excessive replication lag makes "lagged" members ineligible to quickly become primary and increases the possibility that distributed read operations will be inconsistent.

### diagnostic_steps

```
[step 1] 检查每个 secondary 的同步进度
  metric_name: syncedTo time per secondary
  collection_layer: mongo-shell
  collection_method_quote: `rs.printSecondaryReplicationInfo()`
  abnormal_pattern_quote: `45 secs (0 hrs) behind the primary`(原文 Flow Control 段示例:某成员 syncedTo 落后 45 秒)
  abnormal_pattern_threshold: 落后秒数显著大于 0;持续增长更可疑
  metric_unit: seconds
  prerequisite_steps: []

[step 2] 看是否触发 flow control
  metric_name: flowControl.isLagged
  collection_layer: mongo-runtime-cmd
  collection_method_quote: `db.runCommand( { serverStatus: 1 } ).flowControl.isLagged`
  abnormal_pattern_quote: "If flow control has not engaged, investigate the secondary to determine the cause of the replication lag, such as limitations in the hardware, network, or application."
  abnormal_pattern_threshold: `flowControl.isLagged === true` 表示已触发流控,主在限速等待 secondary
  metric_unit: bool
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] writeConcernMajorityJournalDefault / 应用层 writeConcern
  param_name: writeConcernMajorityJournalDefault / 应用层 writeConcern
  abnormal_value_pattern: unacknowledged / w:1(未要求多数节点确认)
  reasoning_quote: "For best results, configure write concern to require confirmation of replication to secondaries. This prevents write operations from returning if replication cannot keep up with the write load."
  linked_diagnostic_step_no: 1

[parameter_causes · cause 2] flowControlTargetLagSeconds
  param_name: flowControlTargetLagSeconds
  abnormal_value_pattern: 默认值偏宽 / 业务期望更紧的延迟容忍度
  reasoning_quote: "With flow control enabled, as the lag grows close to the flowControlTargetLagSeconds, writes on the primary must obtain tickets before taking locks to apply writes. By limiting the number of tickets issued per second, the flow control mechanism attempts to keep the lag under the target."
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] network-physical-link
  cause_type: network-physical-link
  description_quote: "Check the network routes between the members of your set to ensure that there is no packet loss or network routing issue."
  linked_diagnostic_step_no: 1
  mitigation_quote: "Use tools including ping to test latency between set members and traceroute to expose the routing of packets network endpoints."

[non_parameter_causes · cause 2] hardware-disk
  cause_type: hardware-disk
  description_quote: "If the file system and disk device on the secondary is unable to flush data to disk as quickly as the primary, then the secondary will have difficulty keeping state. Disk-related issues are incredibly prevalent on multi-tenant systems, including virtualized instances, and can be transient if the system accesses disk devices over an IP network (as is the case with Amazon's EBS system.)"
  linked_diagnostic_step_no: 1
  mitigation_quote: "Use system-level tools to assess disk status, including iostat or vmstat."

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "In some cases, long-running operations on the primary can block replication on secondaries."
  linked_diagnostic_step_no: 1
  mitigation_quote: "use the database profiler to see if there are slow queries or long-running operations that correspond to the incidences of lag."

[non_parameter_causes · cause 4] application-design
  cause_type: application-design
  description_quote: "If you are performing a large data ingestion or bulk load operation that requires a large number of writes to the primary, particularly with unacknowledged write concern, the secondaries will not be able to read the oplog fast enough to keep up with changes."
  linked_diagnostic_step_no: 1
  mitigation_quote: "request write acknowledgment write concern after every 100, 1,000, or another interval to provide an opportunity for secondaries to catch up with the primary."

```

## case_id: mongo-replica-lag-secondary-behind-primary-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: replica-lag
- **case_pattern**: core-perf-diagnosis
- **title**: Ops Manager replication lag alert: secondary behind primary
- **source_heading**: Replication Lag
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 3
- **source_url**: https://www.mongodb.com/docs/ops-manager/current/reference/alerts/replication-lag/
- **source_url_lang**: en

### symptom_description

> secondary of replica set ABC was behind the most recent

### diagnostic_steps

```
[step 1] 查看 Replication Lag chart 确认延迟时长与持续时间
  metric_name: Replication Lag (seconds)
  collection_layer: atlas-advisor
  collection_method_quote: "View the following charts to monitor your progress"
  abnormal_pattern_quote: "Adjust the settings for this alert to only trigger if the replication\nlag persists for longer than 2 minutes."
  abnormal_pattern_threshold: {"replication_lag_persistent_seconds": ">= 120"}
  metric_unit: seconds
  prerequisite_steps: []

[step 2] 查看 Replication Headroom 判断 secondary 是否会掉出 oplog 窗口
  metric_name: Replication Headroom
  collection_layer: atlas-advisor
  collection_method_quote: "Monitor replication headroom to determine whether the secondary might fall off the oplog."
  abnormal_pattern_quote: (NULL · 原文未给定量阈值)
  abnormal_pattern_threshold: (NULL)
  metric_unit: seconds
  prerequisite_steps: [1]

[step 3] 查看 Network metrics 判断带宽 / 网络问题
  metric_name: Network metrics
  collection_layer: atlas-advisor
  collection_method_quote: "Monitor network metrics to track network performance."
  abnormal_pattern_quote: (NULL · 原文未给定量阈值)
  abnormal_pattern_threshold: (NULL)
  metric_unit: bytes/sec
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "An idle replica set. The reported replication lag is actually just the\ntime since the last write."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文为 alert 阈值调整建议非 fix 命令)

[non_parameter_causes · cause 2] hardware-cpu-physical
  cause_type: hardware-cpu-physical
  description_quote: "The secondary is under-provisioned, which means it needs more\nallocated resources, and cannot keep up with the primary\n(common if using secondaries for read scaling)."
  linked_diagnostic_step_no: 2
  mitigation_quote: "Move (or upgrade in place) the secondary to a machine that is\nidentically (or better) provisioned to the current primary."

[non_parameter_causes · cause 3] hardware-network
  cause_type: hardware-network
  description_quote: "There is insufficient bandwidth, or some other networking problem,\nbetween the primary and secondary."
  linked_diagnostic_step_no: 3
  mitigation_quote: "Resolve networking issues between the primary and secondary."

```

## case_id: mongo-slow-log-queue-wait-vs-working-time-mongodb8-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: MongoDB 8.0 慢日志: workingMillis 与 durationMillis 分离 → 区分真慢查询 vs queue 等待
- **source_heading**: Practical Diagnosis of Slow Queries
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 3
- **source_url**: https://www.mydbops.com/blog/mongodb-8-slow-query-analysis-working-time-vs-duration-metrics
- **source_url_lang**: en

### symptom_description

> In previous versions of MongoDB, slow queries were flagged based on total duration, which included time spent waiting on locks and flow control. While this was helpful, it often meant that some queries appeared “slow” despite having minimal execution time.

### diagnostic_steps

```
[step 1] 读取 mongod 慢日志,提取 workingMillis / durationMillis / queues.execution.totalTimeQueuedMicros
  metric_name: mongod_slow_log.workingMillis
  collection_layer: log-grep
  collection_method_quote: (NULL · 原文未给读取慢日志的字面命令)
  abnormal_pattern_quote: "workingMillis: 120,\n        \"durationMillis\": 300,\n        \"queues\": {\n            \"execution\": {\n                \"totalTimeQueuedMicros\": 180000\n            }\n        }"
  abnormal_pattern_threshold: {"example_workingMillis": 120, "example_durationMillis": 300, "example_totalTimeQueuedMicros": 180000}
  metric_unit: ms / micros
  prerequisite_steps: []

[step 2] 比较 workingMillis 和 totalTimeQueuedMicros 走判断三分支
  metric_name: workingMillis_vs_totalTimeQueuedMicros
  collection_layer: log-grep
  collection_method_quote: (NULL · 原文未给字面比较命令)
  abnormal_pattern_quote: "High workingMillis, Low totalTimeQueuedMicrosDiagnosis: The query is expensive in terms of actual execution time."
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "High workingMillis, Low totalTimeQueuedMicrosDiagnosis: The query is expensive in terms of actual execution time.Action: Focus on optimizing the query itself by considering indexing improvements, refining query patterns, or reworking the schema."
  linked_diagnostic_step_no: 2
  mitigation_quote: "Focus on optimizing the query itself by considering indexing improvements, refining query patterns, or reworking the schema."

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "Low workingMillis, High totalTimeQueuedMicrosDiagnosis: The query executes quickly but is delayed due to waiting for resources (e.g., lock or flow control).Action: Improve concurrency by tweaking settings like increasing ticket counts or considering horizontal scaling to better handle query load."
  linked_diagnostic_step_no: 2
  mitigation_quote: "Improve concurrency by tweaking settings like increasing ticket counts or considering horizontal scaling to better handle query load."

[non_parameter_causes · cause 3] application-design
  cause_type: application-design
  description_quote: "High workingMillis and High totalTimeQueuedMicrosDiagnosis: The query is both expensive and frequently delayed due to being stuck in the queue.Action: Prioritize query optimization. If the query remains queued, explore resource allocation and concurrency configurations to ensure smoother execution."
  linked_diagnostic_step_no: 2
  mitigation_quote: "Prioritize query optimization. If the query remains queued, explore resource allocation and concurrency configurations to ensure smoother execution."

```

## case_id: mongo-plancache-bloat-sbe-7-0-oom-kills-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: MongoDB 7.0 SBE plan cache 膨胀: 单 query shape 5 万+ plan → OOM kill
- **source_heading**: MongoDB 7.0 High Memory Usage: Environment and Initial Symptoms
- **diagnostic_steps_count**: 5
- **likely_causes_count**: 3
- **source_url**: https://www.mydbops.com/blog/mongodb-plancache-memory-issue-sbe-fix
- **source_url_lang**: en

### symptom_description

> We operate a 5-node MongoDB replica set where everything initially looked normal: CPU was low, cache behavior was healthy, and no slow-query spikes were visible. Over time, however, resident memory kept climbing until the Linux OOM killer started terminating mongod processes.

### diagnostic_steps

```
[step 1] 读 top 看 mongod 进程 RES 是否远超 cache + heap 配置
  metric_name: mongod_resident_memory
  collection_layer: os
  collection_method_quote: "top - 19:14:57 up 80 days,  6:05,  5 users,  load average: 0.93, 0.89, 0.99"
  abnormal_pattern_quote: "704060 mongodb   20   0   73.6g  65.5g  36660 S 236.7  53.1   1746:34 mongod"
  abnormal_pattern_threshold: {"VIRT_GB": 73.6, "RES_GB": 65.5, "RAM_total_GiB": 123}
  metric_unit: GB
  prerequisite_steps: []

[step 2] 启用 heapProfilingEnabled 看内存分配 hot path
  metric_name: heap_profile_alloc_hotspots
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文未给具体启用命令字面)
  abnormal_pattern_quote: "There was a high number of memory allocation logs for the query planner."
  abnormal_pattern_threshold: NULL
  metric_unit: NULL
  prerequisite_steps: [1]

[step 3] 在慢日志中观察同一 query shape 的 queryHash / planCacheKey 是否变化
  metric_name: queryHash_uniqueness_per_shape
  collection_layer: log-grep
  abnormal_pattern_quote: "For the query below, the queryHash and planCacheKey values were changing with each query, even though the query itself remained the same."
  abnormal_pattern_threshold: NULL
  metric_unit: count
  prerequisite_steps: [2]

[step 4] 用 getPlanCache().list() 看单集合 plan 缓存条目数
  metric_name: planCache.entries_count
  collection_layer: mongo-shell
  collection_method_quote: "db.test.getPlanCache().list().length"
  abnormal_pattern_quote: "A single collection had 52,891 query plans for one query shape, causing memory usage to rise with planCache growth."
  abnormal_pattern_threshold: {"plan_cache_entries": 52891}
  metric_unit: entries
  prerequisite_steps: [3]

[step 5] 跨版本对比(6.0 / 7.0 / 8.0) queryFramework + queryHash 行为
  metric_name: queryFramework_per_version
  collection_layer: log-grep
  collection_method_quote: (NULL · 原文展示了 3 版本的日志样例但未给比对命令)
  abnormal_pattern_quote: "The issue occurred in MongoDB 7.0 but not in 6.0 or 8.0. It was identified as a bug in the SBE (Slot-Based Execution) engine introduced in 7.0. The issue is tracked in MongoDB JIRA SERVER-96924."
  abnormal_pattern_threshold: {"affected_versions": ["7.0"], "fixed_in": "8.0", "jira": "SERVER-96924"}
  metric_unit: NULL
  prerequisite_steps: [4]

```

### likely_causes

```
[parameter_causes · cause 1] internalQueryFrameworkControl
  param_name: internalQueryFrameworkControl
  abnormal_value_pattern: (默认 trySbeEngine,在 7.0 上触发 SBE plan cache 不稳定 hash bug)
  reasoning_quote: "Forced the classic query engine:db.adminCommand({ setParameter: 1, internalQueryFrameworkControl: \"forceClassicEngine\" });This server parameter forces MongoDB to use the classic query engine instead of SBE, bypassing the bug entirely."
  linked_diagnostic_step_no: 5

[non_parameter_causes · cause 1] os-version-bug
  cause_type: os-version-bug
  description_quote: "What started as occasional OOM kills turned into a weeks-long investigation that eventually traced back to an unexpected interaction between MongoDB's SBE query engine and the plan cache. This post walks through the full investigation, step by step, and how we finally nailed down the root cause - a bug specific to MongoDB 7.0's SBE implementation."
  linked_diagnostic_step_no: 5
  mitigation_quote: "Both solutions worked. Memory usage stabilized with forceClassicEngine, and the issue was fully resolved in MongoDB 8.0."

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "During Diwali week (low traffic), memory growth slowed significantly. When traffic resumed, memory spiked again—confirming the leak was tied to query execution volume."
  linked_diagnostic_step_no: 1
  mitigation_quote: NULL

```

## case_id: mongo-sharding-jumbo-chunk-uneven-write-load-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **title**: jumbo chunks 无法被 balancer 迁移导致单 shard 写热点
- **source_heading**: What are jumbo chunks? + Ok, I have Jumbo chunks in my shard, but why should I bother
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 3
- **source_url**: https://www.percona.com/blog/2018/04/09/mongodb-sharding-are-chunks-balanced-part-1/
- **source_url_lang**: en

### symptom_description

> If jumbo chunks are created on the shard1, that means the chunks are more than 64MB of size. shard1 fills up faster compared to shard2, even though the number of chunks is balanced. More data to shard1 leads to more queries route to shard1 as compare to shard2. This causes one shard with a higher load compared to the other, and leads to performance issues.

### diagnostic_steps

```
[step 1] 检查 balancer 状态
  metric_name: sh.getBalancerState()
  collection_layer: mongo-shell
  collection_method_quote: "mongos> sh.getBalancerState()"
  abnormal_pattern_quote: "Before we start, please check that the balancer is running:"
  abnormal_pattern_threshold: 返回 false 即异常(本 case 期望 true 才能继续)
  metric_unit: bool
  prerequisite_steps: []

[step 2] 用 sh.status(true) 看 chunk 标记
  metric_name: sh.status verbose 输出中的 jumbo flag
  collection_layer: mongo-shell
  collection_method_quote: "sh.status(true)"
  abnormal_pattern_quote: "Please note, only one chunk is moved to the other shard, while the other is not. The balancer can’t move that, and it is flagged as “jumbo”. So sometimes when moving a chunk is triggered, the mongos will mark a large chunk as “jumbo”."
  abnormal_pattern_threshold: sh.status 输出中含 `jumbo` 标记的 chunk 行
  metric_unit: flag
  prerequisite_steps: [1]

[step 3] config.chunks 查询 jumbo 标记
  metric_name: config.chunks { jumbo: true }
  collection_layer: mongo-shell
  collection_method_quote: "mongos> db.chunks.find({\"shard\" : \"shard0000\"},{\"shard\":1,\"jumbo\":1}).pretty()"
  abnormal_pattern_quote: "Jumbo found! Now at this time, mongos is aware that it has a jumbo chunk."
  abnormal_pattern_threshold: 返回包含 `"jumbo" : true` 的文档
  metric_unit: flag
  prerequisite_steps: [2]

```

### likely_causes

```
[parameter_causes · cause 1] sharding chunk size(默认 64MB)/ 25 万文档上限
  param_name: sharding chunk size(默认 64MB)/ 25 万文档上限
  abnormal_value_pattern: 单 chunk 实际大小或文档数超出此阈值
  reasoning_quote: "MongoDB splits chunks when they increase beyond the configured chunk size (i.e., 64 MB) or exceeds 250000 documents. ... Sometimes chunks cannot be broken up and continue to grow beyond the configured size. The balancer cannot move it."
  linked_diagnostic_step_no: 3

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "The main reason for jumbos is multiple mongos, or restarting mongos regularly. This causes the splitIfShould not to be called enough, and prevents chunks from splitting. The balancer won’t be able to move it."
  linked_diagnostic_step_no: 3
  mitigation_quote: "Each mongos measures how much data it has seen inserted or updated for each chunk. With each write, a call to ShouldSplit is made by sending an internal command “splitVector” to the primary that owns the chunks. If mongos is restarted, it loses this memory."

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "Yes, these can be fixed by performing a manual split, using the “split” command. These chunks can be split into smaller pieces and easily moved by the balancer."
  linked_diagnostic_step_no: 3
  mitigation_quote: "For more specific information on how to manually use the splitAt() and splitFind() commands, please refer this blog post written by Miguel Angel Nieto."

```

## case_id: mongo-sharding-equal-chunks-skewed-data-getshard-distribution-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **title**: chunk 计数均衡但数据/查询全压在一个 shard(getShardDistribution 100%/0%)
- **source_heading**: I cannot see any jumbo chunks, and chunks are distributed evenly in each shard but of different sizes
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 2
- **source_url**: https://www.percona.com/blog/2018/04/09/mongodb-sharding-are-chunks-balanced-part-1/
- **source_url_lang**: en

### symptom_description

> A common misconception about the balancer is that it balances the chunks by data size. This isn’t true. It just balances the number of chunks when a particular shard reaches maximum thershold counts (that’s why you see chunks equally distributed). Hence a chunk with 0 documents in it counts just the same as one with 500k documents.

### diagnostic_steps

```
[step 1] 用 db.col.getShardDistribution() 看每 shard 实际数据/文档数
  metric_name: getShardDistribution: per-shard data / docs / chunks
  collection_layer: mongo-shell
  collection_method_quote: "mongos> db.col.getShardDistribution()"
  abnormal_pattern_quote: "It says two chunks in each shard (shard0000 and shard0001), and shard0001 has no data while shard0000 has all the data, 129MB each chunk. Here the two chunks are on each shard because range-based sharding is being used."
  abnormal_pattern_threshold: 单 shard 占 100% 数据 / 100% docs;其他 shard 0%
  metric_unit: percent
  prerequisite_steps: []

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Here the two chunks are on each shard because range-based sharding is being used. MongoDB allocated two chunks for each shard initially, then documents are allocated to these chunks."
  linked_diagnostic_step_no: 1
  mitigation_quote: "Hashed sharding is considered good for shard keys with fields that change monotonically. If you need the data to be exactly split among shards, then a hashed index must be used."

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "A good shard key enables MongoDB to distribute documents evenly throughout shards. A key that has high cardinality for better horizontal scaling and low frequency to prevent uneven document distribution, and does not increase or decrease monotonically is considered a good shard key."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给"换 shard key"的具体命令 · 仅给方向)

```

## case_id: mongo-k8s-container-wt-cache-fallback-256mb-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: 容器中 WiredTiger 无法识别容器内存限制,回退 256MB 最小 cache
- **source_heading**: Changing the cacheSizeRatio
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://www.percona.com/blog/configure-wiredtiger-cachesize-inside-percona-distribution-for-mongodb-kubernetes-operator/
- **source_url_lang**: en

### symptom_description

> Now login into the shard and check the default memory allocated to the container and to the mongod instance. In below, the memory size available is 15G, but the memory limit to use in this container is 476MB only:

### diagnostic_steps

```
[step 1] 用 db.hostInfo() 查容器 vs 主机内存差异
  metric_name: hostInfo.system.memSizeMB / memLimitMB
  collection_layer: mongo-shell
  collection_method_quote: "rs0:PRIMARY> db.hostInfo()"
  abnormal_pattern_quote: "the memory size available is 15G, but the memory limit to use in this container is 476MB only"
  abnormal_pattern_threshold: memSizeMB ≫ memLimitMB(本例 15006 vs 476)
  metric_unit: MB
  prerequisite_steps: []

[step 2] 读 wiredTiger.cache.maximum bytes configured
  metric_name: wiredTiger.cache."maximum bytes configured"
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "rs0:PRIMARY> db.serverStatus().wiredTiger.cache[\"maximum bytes configured\"]/1024/1024"
  abnormal_pattern_quote: "The cache size of 256MB is too low for the real environment."
  abnormal_pattern_threshold: maximum_bytes_configured = 256MB(回退到最小值)
  metric_unit: MB
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] replsets.storage.wiredTiger.engineConfig.cacheSizeRatio + container resources.limits.memory
  param_name: replsets.storage.wiredTiger.engineConfig.cacheSizeRatio + container resources.limits.memory
  abnormal_value_pattern: cacheSizeRatio=0.5 默认 + memlimit ≤ 1G → 触发 minWiredTigerCacheSizeGB(256MB) 回退
  reasoning_quote: "Here, the memory calculation for WT is done roughly as follows (Memory limit should be more than 1G, else 256MB is allocated by default:(Memory limit – 1G) * cacheSizeRatio"
  linked_diagnostic_step_no: 2

[non_parameter_causes · cause 1] hypervisor-issue
  cause_type: hypervisor-issue
  description_quote: "In normal situations WiredTiger does this default-sizing correctly but under Docker containers WiredTiger fails to detect the memory limit of the Docker container. We explicitly set the WiredTiger cache size to fix this."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文 yaml 配置块在 .txt 中被 jsdom `<pre><code>` 抽取压平)

```

## case_id: mongo-k8s-operator-cachesize-bug-cpu-limit-required-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: PSMDB operator v1.9 / v1.10 已知 bug · cacheSizeRatio 改了但 mongod 仍按默认 cache 启动
- **source_heading**: (Conclusion 段附录 / K8SPSMDB-603)
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 1
- **source_url**: https://www.percona.com/blog/configure-wiredtiger-cachesize-inside-percona-distribution-for-mongodb-kubernetes-operator/
- **source_url_lang**: en

### symptom_description

> Till PSMDB operator v1.10.0, the operator takes the change of cacheSizeRatio only if the resources.limit.cpu is also set. This is a bug and it got fixed in v1.11.0 – refer https://jira.percona.com/browse/K8SPSMDB-603 . So if you’re in an older version, don’t be surprised and you have to make sure the resources.limit.cpu is set as well.

### diagnostic_steps

```
[step 1] 检查 operator 版本 + cr.yaml 中 cpu limit 是否存在
  metric_name: operator version + replsets.resources.limits.cpu
  collection_layer: os
  collection_method_quote: "$ kubectl get pods"
  abnormal_pattern_quote: "Till PSMDB operator v1.10.0, the operator takes the change of cacheSizeRatio only if the resources.limit.cpu is also set."
  abnormal_pattern_threshold: operator ≤ v1.10 且 cr.yaml 中 cpu limit 缺失或为 0
  metric_unit: string
  prerequisite_steps: []

[step 2] 进 mongod pod 验证 wt cache 实际值
  metric_name: wiredTiger.cache.maximum bytes configured
  collection_layer: mongo-runtime-cmd
  collection_method_quote: "rs0:PRIMARY> db.serverStatus().wiredTiger.cache[\"maximum bytes configured\"]/1024/1024"
  abnormal_pattern_quote: "Till PSMDB operator v1.10.0, the operator takes the change of cacheSizeRatio only if the resources.limit.cpu is also set."
  abnormal_pattern_threshold: yaml cacheSizeRatio 已改但 mongod 实际 cache 与 ratio*memlimit 公式不匹配
  metric_unit: MB
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "if limit, ok := resources.Limits[corev1.ResourceCPU]; ok && !limit.IsZero() {<br>args = append(args, fmt.Sprintf(<br>\"--wiredTigerCacheSizeGB=%.2f\",<br>getWiredTigerCacheSizeGB(resources.Limits, replset.Storage.WiredTiger.EngineConfig.CacheSizeRatio, true),<br>))<br>}"
  linked_diagnostic_step_no: 1
  mitigation_quote: "From v1.11.0:" + "if limit, ok := resources.Limits[corev1.ResourceMemory]; ok && !limit.IsZero() {<br>    args = append(args, fmt.Sprintf(<br>       \"--wiredTigerCacheSizeGB=%.2f\",<br>       getWiredTigerCacheSizeGB(resources.Limits, replset.Storage.WiredTiger.EngineConfig.CacheSizeRatio, true),<br>))<br>}"

```

## case_id: mongo-8-0-tcmalloc-percpu-prerequisite-not-met-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: memory-pressure
- **case_pattern**: core-perf-diagnosis
- **title**: MongoDB 8.0 升级后未拿到预期性能提升 · TCMalloc 实际未启用 per-CPU caches
- **source_heading**: Important change for Transparent Huge Pages (THP)
- **diagnostic_steps_count**: 4
- **likely_causes_count**: 3
- **source_url**: https://www.percona.com/blog/memory-management-in-mongodb-8-0-testing-the-new-tcmalloc/
- **source_url_lang**: en

### symptom_description

> MongoDB has used TCMalloc as its default allocator, but version 8.0 includes a major upgrade to a newer implementation aligned with upstream Google TCMalloc changes that uses per-CPU caches, instead of per-thread caches. This brings improved multithreaded scalability, better memory release behavior to the OS, more predictable RSS (Resident Set Size) under heavy workloads.

### diagnostic_steps

```
[step 1] 检查 serverStatus.tcmalloc.usingPerCpuCaches
  metric_name: serverStatus.tcmalloc.usingPerCpuCaches
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文给的是判定值"is true / is greater than 0",未给具体读取命令)
  abnormal_pattern_quote: "tcmalloc.usingPerCpuCaches is true"
  abnormal_pattern_threshold: usingPerCpuCaches != true → 异常(说明回退到 legacy per-thread 实现)
  metric_unit: bool
  prerequisite_steps: []

[step 2] 检查 serverStatus.tcmalloc.tcmalloc.cpu_free
  metric_name: serverStatus.tcmalloc.tcmalloc.cpu_free
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文给的是判定值"is greater than 0",未给具体读取命令 · 同 ref)
  abnormal_pattern_quote: "tcmalloc.tcmalloc.cpu_free is greater than 0"
  abnormal_pattern_threshold: cpu_free 不大于 0 → 异常(per-CPU 缓存未真正建立)
  metric_unit: count
  prerequisite_steps: [1]

[step 3] 检查内核版本
  metric_name: uname -r kernel version
  collection_layer: os
  collection_method_quote: (NULL · 原文未给具体读取命令)
  abnormal_pattern_quote: "Kernel version 4.18 or later"
  abnormal_pattern_threshold: 内核版本 < 4.18
  metric_unit: version
  prerequisite_steps: []

[step 4] 检查 THP 是否启用
  metric_name: /sys/kernel/mm/transparent_hugepage/enabled
  collection_layer: os
  collection_method_quote: (NULL · 同 ref)
  abnormal_pattern_quote: "THP enabled"
  abnormal_pattern_threshold: (MongoDB 8.0 视角)THP 当前为 `never` → 异常(与 7.0 时代相反!)
  metric_unit: enum
  prerequisite_steps: []

```

### likely_causes

```
[parameter_causes · cause 1] kernel.transparent_hugepage
  param_name: kernel.transparent_hugepage
  abnormal_value_pattern: never · 但 mongod 是 8.0+
  reasoning_quote: "If you are a long time user of MongoDB, you probably know that one of the more common best practices for OS tuning was to disable THP. Starting from MongoDB 8.0 the best practice is exactly the opposite: in order to benefit from the new TCMalloc, THP now must be enabled."
  linked_diagnostic_step_no: 4

[non_parameter_causes · cause 1] os-version-bug
  cause_type: os-version-bug
  description_quote: "Kernel version 4.18 or later"
  linked_diagnostic_step_no: 3
  mitigation_quote: (NULL · 原文未给升级命令,只列前置条件)

[non_parameter_causes · cause 2] os-version-bug
  cause_type: os-version-bug
  description_quote: "glibc rseq disabled: if another application, such as the glibc library, registers an rseq structure before TCMalloc, TCMalloc can’t use rseq. Without rseq, TCMalloc uses per-thread caches, which are used by the legacy TCMalloc version."
  linked_diagnostic_step_no: 1
  mitigation_quote: (NULL · 原文未给禁用 glibc rseq 的具体命令)

```

## case_id: mongo-query-ixscan-poor-selectivity-extra-sort-02

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: 索引存在但 totalDocsExamined ≫ nReturned + 出现独立 SORT stage
- **source_heading**: Example 3
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 2
- **source_url**: https://www.percona.com/blog/mongodb-investigate-queries-with-explain-index-usage-part-2/
- **source_url_lang**: en

### symptom_description

> Let’s return now to the original query. We can also notice that the number of documents examined is still too high (2517) compared to the documents returned (493). That’s not optimal.

### diagnostic_steps

```
[step 1] 用 explain 比较 totalDocsExamined 与 nReturned 的比值
  metric_name: executionStats.totalDocsExamined / executionStats.nReturned
  collection_layer: mongo-shell
  collection_method_quote: "MongoDB > var exp = db.restaurants.explain(\"executionStats\")"
  abnormal_pattern_quote: "the number of documents examined is still too high (2517) compared to the documents returned (493). That’s not optimal."
  abnormal_pattern_threshold: totalDocsExamined / nReturned ≫ 1(原文示例 ≈ 5×)
  metric_unit: ratio
  prerequisite_steps: []

[step 2] 检查 winningPlan 是否含独立 SORT stage
  metric_name: explain.queryPlanner.winningPlan.stage(子节点是否含 SORT)
  collection_layer: mongo-shell
  collection_method_quote: "MongoDB > exp.find( {\"cuisine\" : {$ne : \"American \"}, ... \"grades.grade\" :\"A\", ... \"borough\": \"Brooklyn\"}).sort({\"name\":1})"
  abnormal_pattern_quote: "In this case, we have fewer documents examined but since the cuisine_1 index cannot be used, a SORT stage is needed, and the index used to fetch the document is borough_1. While MongoDB has examined fewer documents, the execution time is worse because of the extra stage used to sort the documents."
  abnormal_pattern_threshold: winningPlan 包含独立 "stage": "SORT" 节点(非索引天然有序)
  metric_unit: enum
  prerequisite_steps: [1]

```

### likely_causes

```
[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Let’s see if we can further improve the query by adding another compound index on (cuisine,borough,grades.grade)."
  linked_diagnostic_step_no: 1
  mitigation_quote: "MongoDB > db.restaurants.createIndex({cuisine:1,borough:1,\"grades.grade\":1})"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "There is not a SORT stage because the documents are already extracted using the index, and so they are already sorted."
  linked_diagnostic_step_no: 2
  mitigation_quote: (NULL · 原文未给单独修复命令 · 把排序键纳入索引前缀,与 cause 1 mitigation 同语义)

```

## case_id: mongo-write-regression-default-writeconcern-majority-journal-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: query-slow
- **case_pattern**: core-perf-diagnosis
- **title**: MongoDB 5.0+ 默认 writeConcern=majority 致 JournalFlusher 写盘成为热点
- **source_heading**: Strange behavior + Digging for the truth
- **diagnostic_steps_count**: 3
- **likely_causes_count**: 3
- **source_url**: https://www.percona.com/blog/mongodb-performance-regression-benchmarking-and-the-truth-behind-journaling/
- **source_url_lang**: en

### symptom_description

> A customer had come with a problem in that the write performance dropped drastically after testing their writes between v4.4 and v7.0 as part of their upgrade. So I did tests around this by creating a write load with a million documents inserted into a collection on my system. I have chosen a single-member replicaSet just to keep the environment simple. In MongoDB v4.4, it took 6 minutes with the default settings, but the same set of tests took 127 minutes in v7.0 which was strange for me.

### diagnostic_steps

```
[step 1] 用 Flamegraph 定位 CPU 热点
  metric_name: flamegraph CPU stack profile
  collection_layer: flamegraph
  collection_method_quote: "I collected a Flamegraph (see here-https://github.com/brendangregg/FlameGraph) to see where the CPU resources spend a huge amount of time."
  abnormal_pattern_quote: "Running with the default RW concern values and Flamegraph showed the culprit: the Journal Flusher was causing the long execution. Here is a screenshot of the Flamegraph where JournalFlusher is visible at the bottom left."
  abnormal_pattern_threshold: flamegraph 中 JournalFlusher 函数占据显著比例(对照态:disabled writeConcernMajorityJournalDefault 后 1.52%)
  metric_unit: percent
  prerequisite_steps: []

[step 2] 读取当前 default writeConcern
  metric_name: getDefaultRWConcern.defaultWriteConcern
  collection_layer: mongo-shell
  collection_method_quote: (NULL · 原文给的是 setDefaultRWConcern 修改命令(写入),未给读取版本)
  abnormal_pattern_quote: "I tested above with the default writeConcern: majority in v7.0 as I was using a single member only and didn’t consider setting writeConcern:1."
  abnormal_pattern_threshold: mongod 版本 ≥ 5.0 且 defaultWriteConcern.w = "majority" 且业务写延迟敏感
  metric_unit: enum
  prerequisite_steps: []

[step 3] 读 rs.conf().writeConcernMajorityJournalDefault
  metric_name: rs.conf().writeConcernMajorityJournalDefault
  collection_layer: mongo-shell
  collection_method_quote: "rs.conf()"
  abnormal_pattern_quote: "If journaling is enabled, w: “majority” may imply j: true. The writeConcernMajorityJournalDefault replica set configuration setting determines the behavior. See Acknowledgment Behavior for details."
  abnormal_pattern_threshold: writeConcernMajorityJournalDefault = true(默认) 且业务对写延迟敏感
  metric_unit: bool
  prerequisite_steps: [2]

```

### likely_causes

```
[parameter_causes · cause 1] defaultWriteConcern.w
  param_name: defaultWriteConcern.w
  abnormal_value_pattern: 5.0+ 默认 "majority"(对比 4.4 默认 1)
  reasoning_quote: "the default global write concern is changed from 1 to “majority” for the replicaset & sharded cluster environments. ... This changed how MongoDB behaves for every request to maintain the data integrity between the replicaSet members"
  linked_diagnostic_step_no: 2

[parameter_causes · cause 2] replicaSet.config.writeConcernMajorityJournalDefault
  param_name: replicaSet.config.writeConcernMajorityJournalDefault
  abnormal_value_pattern: true(默认)
  reasoning_quote: "With j: true, MongoDB returns only after the requested number of members, including the primary, have written to the journal. Previously j: true write concern in a replica set only requires the primary to write to the journal, regardless of the w: <value> write concern."
  linked_diagnostic_step_no: 3

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "Usually, mongod acknowledges the writes when a majority of the members write into the on-disk journal file."
  linked_diagnostic_step_no: 1
  mitigation_quote: "I did another test while keeping the majority RWConcern and writeConcernMajorityJournalDefault: false in rs.conf() to acknowledge the write operation with writing on memory only instead of waiting until the journal writing into the disk. Usually, mongod acknowledges the writes when a majority of the members write into the on-disk journal file. This time as expected after the change, a million documents were inserted within 10 minutes."

```

## case_id: mongo-wt-checkpoint-time-grows-bulk-load-stall-01

- **entry_kind**: diagnostic-flow
- **db**: mongodb
- **platform**: bare
- **engine**: mongodb
- **symptom_category**: disk-io-saturation
- **case_pattern**: core-perf-diagnosis
- **title**: bulk-load 期间 WiredTiger checkpoint 时间从几秒增至数分钟,期间业务停滞
- **source_heading**: Tuning MongoDB for Bulk Loads(全文主线)
- **diagnostic_steps_count**: 2
- **likely_causes_count**: 4
- **source_url**: https://www.percona.com/blog/tuning-mongodb-for-bulk-loads/
- **source_url_lang**: en

### symptom_description

> What we noticed is the load started at a decent rate, but after some time it started to slow down considerably. Doing some research by looking at metrics, we noticed WiredTiger checkpoint time was increasing more and more as time passed. We went from only a few seconds to checkpoints taking even a few minutes(!). During checkpoints, performance basically tanked:

### diagnostic_steps

```
[step 1] 监测 WiredTiger checkpoint 时间(PMM/趋势工具)
  metric_name: wiredTiger checkpoint duration
  collection_layer: mongo-internal-counter
  collection_method_quote: (NULL · 原文未给具体读取命令,仅说"Doing some research by looking at metrics" + 强调 PMM 趋势)
  abnormal_pattern_quote: "WiredTiger checkpoint time was increasing more and more as time passed. We went from only a few seconds to checkpoints taking even a few minutes(!). During checkpoints, performance basically tanked:"
  abnormal_pattern_threshold: checkpoint 时长持续上升;原文期望 < 10s 视为合理
  metric_unit: seconds
  prerequisite_steps: []

[step 2] 评估 cache 中脏页规模与 eviction 触发阈值
  metric_name: wiredTiger.cache (eviction_dirty_trigger / eviction_dirty_target context)
  collection_layer: mongo-runtime-cmd
  collection_method_quote: (NULL · 原文段落给的是 setParameter 命令(写入,见 mitigation),未给读取阈值的命令)
  abnormal_pattern_quote: "Remember that in a sharp or full checkpoint, all dirty pages have to be flushed to disk. This will use all of your disk write capacity for as long as it takes. That explains the reason why these values have “low” defaults, as we want to limit the amount of work that the database has to do at each checkpoint."
  abnormal_pattern_threshold: dirty 页规模超出磁盘单次 checkpoint 可消化容量
  metric_unit: percent / bytes
  prerequisite_steps: [1]

```

### likely_causes

```
[parameter_causes · cause 1] wiredTigerEngineRuntimeConfig.eviction_dirty_trigger / eviction_dirty_target
  param_name: wiredTigerEngineRuntimeConfig.eviction_dirty_trigger / eviction_dirty_target
  abnormal_value_pattern: dirty_trigger 默认 20% · dirty_target 默认 5% · 256GB cache 时 1% 即 2.56GB
  reasoning_quote: "These parameters are again, expressed as a percentage of total WiredTiger cache usage. The lowest we can go is 1% (no floating-point values are allowed). 1% can still be quite a lot on a server with a high memory! A 256G cache is not uncommon these days, and 1% of that is 2.56 Gb. To be flushed all at once, one time per minute."
  linked_diagnostic_step_no: 2

[parameter_causes · cause 2] wiredTigerEngineRuntimeConfig.eviction.threads_min / threads_max
  param_name: wiredTigerEngineRuntimeConfig.eviction.threads_min / threads_max
  abnormal_value_pattern: 默认 threads_min=threads_max=4,bulk-load 下不足
  reasoning_quote: "By default, MongoDB allocates four background threads to perform eviction. ... For this particular case, the default four threads weren’t enough to keep up with the rate of dirty page generation, as evidenced by Percona Monitoring and Management (PMM) graphics:"
  linked_diagnostic_step_no: 1

[non_parameter_causes · cause 1] application-design
  cause_type: application-design
  description_quote: "As of MongoDB 4.2, the WiredTiger engine does a full checkpoint every 60 seconds (controlled by checkpoint=(wait=60)). This means that all dirty pages in the WiredTiger cache have to be flushed to disk every 60 seconds."
  linked_diagnostic_step_no: 1
  mitigation_quote: "db.adminCommand( { \"setParameter\": 1, \"wiredTigerEngineRuntimeConfig\": \"eviction=(threads_min=20,threads_max=20),checkpoint=(wait=60),eviction_dirty_trigger=5,eviction_dirty_target=1,eviction_trigger=95,eviction_target=80\"})"

[non_parameter_causes · cause 2] application-design
  cause_type: application-design
  description_quote: "If the pressure is too high, and cache usage increases to as high as 95 Gb (eviction_trigger), then application/client threads will be throttled. How? they will be asked to help the background threads perform eviction before being allowed to do their job, helping to relieve some of the pressure, at the expense of increasing latency to the clients. If even this is not enough, and the cache reaches 100% of the configured cache size, operations will stall."
  linked_diagnostic_step_no: 2
  mitigation_quote: "After doing some experiments with the available hardware, we decided to increase the number of eviction threads to the maximum 20, reduce the dirty thresholds to the one to five-percent range, and also set a small WiredTiger cache of 1 Gb, which would limit the number of dirty pages to 10-50 Mb."

```

## case_id: wt-evict-cold-page-compact-cure-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **platform**: bare
- **engine**: os-or-allocator
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger 冷数据 evict 后 checkpoint 不再处理 · compact 触发 reconciliation 强制回收
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 0
- **source_url**: https://github.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/blob/main/%E7%A3%81%E7%9B%98%E7%A9%BA%E9%97%B4%E6%B3%84%E6%BC%8F%E5%AE%9E%E9%AA%8C%E7%BB%93%E6%9E%9C%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### diagnostic_steps

```
[step 1] 采火焰图识别栈帧
  collection_layer: flamegraph
  collection_method_quote: perf record -g + flamegraph.pl
  flame_pattern:
    pattern_regex: (compact|reconciliation|evict).*
    scope: storage-engine-wt
    signature_type: stack-pattern

```

## case_id: wt-app-thread-evict-assist-pressure-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **platform**: bare
- **engine**: os-or-allocator
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger 应用线程被迫参与 eviction 助手(cache 使用率超阈值压力 signature)
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 0
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/MongoDB%E5%9C%A8%E7%BA%BF%E8%B0%83%E6%95%B4cache_size%E6%85%A2%E7%9A%84%E6%B7%B1%E5%BA%A6%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### diagnostic_steps

```
[step 1] 采火焰图识别栈帧
  collection_layer: flamegraph
  collection_method_quote: perf record -g + flamegraph.pl
  flame_pattern:
    pattern_regex: ^__wt_cache_eviction_.*
    scope: storage-engine-wt
    signature_type: function-prefix

```

## case_id: wt-evict-reconcile-blocked-ebusy-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **platform**: bare
- **engine**: os-or-allocator
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger eviction reconcile 被多重 EBUSY 阻碍(__evict_review → __evict_reconcile 链路热点)
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 0
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/MongoDB%E5%9C%A8%E7%BA%BF%E8%B0%83%E6%95%B4cache_size%E6%85%A2%E7%9A%84%E6%B7%B1%E5%BA%A6%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### diagnostic_steps

```
[step 1] 采火焰图识别栈帧
  collection_layer: flamegraph
  collection_method_quote: perf record -g + flamegraph.pl
  flame_pattern:
    pattern_regex: ^__evict_(review|reconcile)$
    scope: storage-engine-wt
    signature_type: stack-pattern

```

## case_id: wt-capacity-throttle-cond-signal-crash-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **platform**: bare
- **engine**: os-or-allocator
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger io_capacity 配置语法错误后,后台 eviction 线程经 capacity_throttle 调用 __wt_cond_signal 解引用 NULL capacity_cond 触发 SIGSEGV
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 0
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/MongoDB_io_capacity_crash%E5%AE%8C%E6%95%B4%E4%BF%AE%E5%A4%8D%E6%96%B9%E6%A1%88.md
- **source_url_lang**: zh-cn

### diagnostic_steps

```
[step 1] 采火焰图识别栈帧
  collection_layer: flamegraph
  collection_method_quote: perf record -g + flamegraph.pl
  flame_pattern:
    pattern_regex: (__wt_capacity_throttle|__capacity_signal|__wt_cond_signal)
    scope: storage-engine-wt
    signature_type: stack-pattern

```

## case_id: wt-reconcile-row-tombstone-skip-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **platform**: bare
- **engine**: os-or-allocator
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger reconcile 在 row leaf 上跳过全局可见 stop_ts 的 key(磁盘清理读-判-跳路径 signature)
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 0
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/%E7%A3%81%E7%9B%98%E5%B7%B2%E6%8C%81%E4%B9%85%E5%8C%96%E6%95%B0%E6%8D%AE%E7%9A%84%E6%B8%85%E7%90%86%E4%BB%A3%E7%A0%81%E8%B7%AF%E5%BE%84.md
- **source_url_lang**: zh-cn

### diagnostic_steps

```
[step 1] 采火焰图识别栈帧
  collection_layer: flamegraph
  collection_method_quote: perf record -g + flamegraph.pl
  flame_pattern:
    pattern_regex: ^(__wt_row_leaf_value_cell|__wti_rec_upd_select|__wt_txn_tw_stop_visible_all)$
    scope: storage-engine-wt
    signature_type: stack-pattern

```

## case_id: wt-reconcile-write-wrapup-block-free-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **platform**: bare
- **engine**: os-or-allocator
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger reconcile 写入 wrapup 阶段释放旧页面磁盘块(block manager free-list 入队 signature)
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 0
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/%E7%A3%81%E7%9B%98%E5%B7%B2%E6%8C%81%E4%B9%85%E5%8C%96%E6%95%B0%E6%8D%AE%E7%9A%84%E6%B8%85%E7%90%86%E4%BB%A3%E7%A0%81%E8%B7%AF%E5%BE%84.md
- **source_url_lang**: zh-cn

### diagnostic_steps

```
[step 1] 采火焰图识别栈帧
  collection_layer: flamegraph
  collection_method_quote: perf record -g + flamegraph.pl
  flame_pattern:
    pattern_regex: ^(__rec_write_wrapup|__rec_split_discard|__wt_ref_block_free|__wt_btree_block_free)$
    scope: storage-engine-wt
    signature_type: function-prefix

```

## case_id: wt-reconcile-row-leaf-tombstone-not-globally-visible-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **platform**: bare
- **engine**: os-or-allocator
- **symptom_category**: other
- **case_pattern**: core-perf-diagnosis
- **title**: WiredTiger 行叶页 reconcile 路径下 tombstone 非全局可见 → 已删除数据被整页保留(oldest_timestamp 推进不足 signature)
- **diagnostic_steps_count**: 1
- **likely_causes_count**: 0
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/%E4%B8%BA%E4%BB%80%E4%B9%88%E5%B7%B2%E5%88%A0%E9%99%A4%E6%95%B0%E6%8D%AE%E4%BB%8D%E5%9C%A8%E6%96%87%E4%BB%B6%E4%B8%AD_%E6%B7%B1%E5%BA%A6%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### diagnostic_steps

```
[step 1] 采火焰图识别栈帧
  collection_layer: flamegraph
  collection_method_quote: perf record -g + flamegraph.pl
  flame_pattern:
    pattern_regex: ^(__wti_rec_row_leaf|__wti_rec_upd_select|__wt_txn_tw_stop_visible_all|__wti_rec_image_copy)$
    scope: storage-engine-wt
    signature_type: stack-pattern

```
