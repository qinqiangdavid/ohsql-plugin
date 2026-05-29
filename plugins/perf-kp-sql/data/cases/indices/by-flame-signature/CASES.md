<!-- ============ Flame-Signature (13 signatures) ============ -->

## case_id: linux-fs-mmap-metadata-archiver-01

- **entry_kind**: flame-signature
- **db**: _common
- **scope**: linux-fs
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: ^(sys_newfstatat|sys_getdents|sys_openat|page_fault).*
- **source_authority**: community-canonical
- **source_url**: https://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html
- **source_url_lang**: en

### pattern_quote

> Most of the kernel time is in sys_newfstatat() and sys_getdents(): metadata work as the file system is walked. sys_openat() is on the right, as files are opened to be read, which are then mmap()d (look to the right of sys_getdents(), these are in alphabetical order), and finally page faulted into user-space (see the page_fault() mountain on the left).

### mechanism_quote

> Most of the kernel time is in sys_newfstatat() and sys_getdents(): metadata work as the file system is walked. sys_openat() is on the right, as files are opened to be read, which are then mmap()d (look to the right of sys_getdents(), these are in alphabetical order), and finally page faulted into user-space (see the page_fault() mountain on the left). The actual work of moving bytes is then spent in user-land on the mmap'd segments (and not shown in this kernel flame graph).

### workload_implication_quote

> As an example of a different workload, this shows the Linux kernel CPU time while an ext4 file system was being archived

## case_id: glibc-malloc-allocator-hot-stack-01

- **entry_kind**: flame-signature
- **db**: _common
- **scope**: mem-allocator-glibc
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: ^(__GI___libc_malloc|Perl_pp_split|JOIN::(optimize|exec)).*
- **source_authority**: community-canonical
- **source_url**: https://www.brendangregg.com/FlameGraphs/memoryflamegraphs.html
- **source_url_lang**: en

### pattern_quote

> __GI___libc_malloc Perl_sv_grow Perl_sv_setpvn Perl_newSVpvn_flags Perl_pp_split Perl_runops_standard

### mechanism_quote

> This is where the memory allocator functions, malloc(), free(), etc, are traced. Imagine you could run Valgrind memcheck with "-p PID" on a process, and gather memory leak statistics for 60 seconds or so. Not a complete picture, but hopefully enough to catch egregious leaks.

### workload_implication_quote

> This tells us that the most malloc() calls were in st_select_lex::optimize() -> JOIN::optimize(). But that's not where most of the bytes were allocated.

## case_id: linux-mm-brk-heap-expansion-01

- **entry_kind**: flame-signature
- **db**: _common
- **scope**: linux-mm
- **signature_type**: function-prefix
- **match_layer**: function
- **pattern_regex**: ^(sys_brk|SyS_brk|brk)$
- **source_authority**: community-canonical
- **source_url**: https://www.brendangregg.com/FlameGraphs/memoryflamegraphs.html
- **source_url_lang**: en

### pattern_quote

> brk() can be traced via its kernel function, SyS_brk() or sys_brk(), or on 4.14+ kernels via the syscalls:sys_enter_brk tracepoint.

### mechanism_quote

> Many applications grow using brk(). This syscall sets the program break point: the end of the heap segment (aka the process data segment). brk() isn't called by the application directly, but rather the user-level allocator which provides the malloc()/free() interface. Such allocators typically don't give memory back the OS, keeping freed memory as a cache for future allocations. And so, brk() is typically for growth only (not shrinks).

### workload_implication_quote

> What brk() tracing can tell us is the code paths that lead to heap expansion. This could be either: > A memory growth code path A memory leak code path An innocent application code path, that happened to spill-over the current heap size Asynchronous allocator code path, that grew the application in response to diminishing free space

## case_id: linux-mm-mmap-vm-growth-01

- **entry_kind**: flame-signature
- **db**: _common
- **scope**: linux-mm
- **signature_type**: function-prefix
- **match_layer**: function
- **pattern_regex**: ^(sys_mmap|SyS_mmap|mmap)$
- **source_authority**: community-canonical
- **source_url**: https://www.brendangregg.com/FlameGraphs/memoryflamegraphs.html
- **source_url_lang**: en

### pattern_quote

> mmap() can be traced via its kernel function, SyS_mmap() or sys_mmap(), or on 4.14+ kernels via the syscalls:sys_enter_mmap tracepoint.

### mechanism_quote

> The mmap() syscall may be explicitly used by the application for loading data files or creating working segments, especially during initialization and application start. In this context, we're interested in creeping application growth, which may occur via mmap() if the allocator uses it instead of brk(). glibc does this for larger allocations, which can be returned to the system using munmap().

### workload_implication_quote

> Unlike brk(), mmap() calls don't necessarily mean growth, as they may be freed shortly after using munmap(). And so tracing mmap() may show many new mappings, but most or all of them are neither growth nor leaks. If your system has frequent short-lived processes (eg, doing a software build), the mmap()s as part of process initialization can flood the trace.

## case_id: linux-mm-page-fault-physical-population-01

- **entry_kind**: flame-signature
- **db**: _common
- **scope**: linux-mm
- **signature_type**: function-prefix
- **match_layer**: function
- **pattern_regex**: ^(handle_mm_fault|page_fault_user|page_fault_kernel)$
- **source_authority**: community-canonical
- **source_url**: https://www.brendangregg.com/FlameGraphs/memoryflamegraphs.html
- **source_url_lang**: en

### pattern_quote

> Page faults can be dynamically traced via a kernel function, eg, handle_mm_fault(), or on 4.14+ kernels via the tracepoints t:exceptions:page_fault_user and t:exceptions:page_fault_kernel.

### mechanism_quote

> brk() and mmap() tracing show virtual memory expansion. Physical memory is consumed later, when the memory is written to, causing page faults, and virtual to physical mappings to be initialized. This activity can happen in a different code path, and one that may (or may not) be more illuminating.

### workload_implication_quote

> Page fault tracing shows different code paths: those that are populating physical memory. They will be either: > A memory growth code path A memory leak code path

## case_id: linux-block-offwake-disk-io-block-completion-01

- **entry_kind**: flame-signature
- **db**: _common
- **scope**: linux-block
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: ^(blkif_interrupt|__blk_mq_complete_request|blk_mq_end_request|blk_update_request|mpage_end_io|wake_up_page_bit|__wake_up_common|autoremove_wake_function|finish_task_switch|__schedule|schedule|io_schedule|generic_file_read_iter|__vfs_read|vfs_read).*
- **source_authority**: community-canonical
- **source_url**: https://www.brendangregg.com/FlameGraphs/offcpuflamegraphs.html
- **source_url_lang**: en

### pattern_quote

> blkif_interrupt __blk_mq_complete_request blk_mq_end_request blk_update_request mpage_end_io wake_up_page_bit __wake_up_common autoremove_wake_function -- -- finish_task_switch __schedule schedule io_schedule generic_file_read_iter __vfs_read vfs_read SyS_pread64 entry_SYSCALL_64_fastpath __GI___libc_pread

### mechanism_quote

> As an intermediate and more practical step, I began by associating off-CPU stacks with a single wakeup stack. This is my offwaketime bcc/eBPF tool.

### workload_implication_quote

> Zoom into the do_command() function (use Search on the top right, if you can't find it) and you can see the block I/O completion interrupts waking up our vfs_read() stacks.

## case_id: wt-evict-cold-page-compact-cure-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **scope**: storage-engine-wt
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: (compact|reconciliation|evict).*
- **source_authority**: community-canonical
- **source_url**: https://github.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/blob/main/%E7%A3%81%E7%9B%98%E7%A9%BA%E9%97%B4%E6%B3%84%E6%BC%8F%E5%AE%9E%E9%AA%8C%E7%BB%93%E6%9E%9C%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### pattern_quote

> 删除操作： - DELETE冷数据时 - 需要读取page到内存 - 删除后可能被evict（因为是冷数据） - 后续没有访问 - 🔥 Page不再进入内存 - 🔥 Checkpoint不会处理 - 🔥 磁盘空间不会被回收 > 解决： db.runCommand({compact: "collection"}) - 强制读取所有page - 触发reconciliation - 清理过时数据

### mechanism_quote

> 访问模式： - 热数据：最近1小时的数据（在cache中） - 温数据：最近1天的数据（偶尔在cache中） - 冷数据：7天前的数据（永远不在cache中）

### workload_implication_quote

> ### 为什么生产环境会有问题？ > ``` 生产环境特点： - Cache: 几GB - 数据: 几百GB到几TB - Cache只能容纳1-5%的数据 - 大部分数据在磁盘上

## case_id: wt-app-thread-evict-assist-pressure-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **scope**: storage-engine-wt
- **signature_type**: function-prefix
- **match_layer**: function
- **pattern_regex**: ^__wt_cache_eviction_.*
- **source_authority**: community-canonical
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/MongoDB%E5%9C%A8%E7%BA%BF%E8%B0%83%E6%95%B4cache_size%E6%85%A2%E7%9A%84%E6%B7%B1%E5%BA%A6%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### pattern_quote

> * __wt_cache_eviction_check -- *     如果 cache 使用量超过阈值，阻塞应用线程， *     强制其参与 eviction

### mechanism_quote

> 如果 cache 使用量超过阈值，阻塞应用线程， 强制其参与 eviction

### workload_implication_quote

> 总耗时: 几百毫秒到几秒

## case_id: wt-evict-reconcile-blocked-ebusy-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **scope**: storage-engine-wt
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: ^__evict_(review|reconcile)$
- **source_authority**: community-canonical
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/MongoDB%E5%9C%A8%E7%BA%BF%E8%B0%83%E6%95%B4cache_size%E6%85%A2%E7%9A%84%E6%B7%B1%E5%BA%A6%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### pattern_quote

> // ⚠️ 关键检查: 页面是否可以被逐出？ WT_ERR(__evict_review(session, ref, flags, &inmem_split)); >     // 🔥 如果页面是脏的，需要 reconcile if (!tree_dead && __wt_page_is_modified(page)) WT_ERR(__evict_reconcile(session, ref, flags));  // ← 耗时操作！

### mechanism_quote

> * __evict_reconcile -- *     对页面进行 reconcile（对账），准备写入磁盘 * *     这是 eviction 过程中最耗时的操作！

### workload_implication_quote

> Eviction 线程尝试逐出 → 返回 EBUSY

## case_id: wt-capacity-throttle-cond-signal-crash-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **scope**: storage-engine-wt
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: (__wt_capacity_throttle|__capacity_signal|__wt_cond_signal)
- **source_authority**: community-canonical
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/MongoDB_io_capacity_crash%E5%AE%8C%E6%95%B4%E4%BF%AE%E5%A4%8D%E6%96%B9%E6%A1%88.md
- **source_url_lang**: zh-cn

### pattern_quote

> T9: __wt_capacity_throttle() 被调用 ↓ T10: __capacity_signal() 尝试发送信号 ↓ T11: __wt_cond_signal(conn->capacity_cond)

### mechanism_quote

> T5: capacity_cond条件变量未正确创建或保持为NULL

### workload_implication_quote

> T13: 💥 Segmentation Fault!

## case_id: wt-reconcile-row-tombstone-skip-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **scope**: storage-engine-wt
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: ^(__wt_row_leaf_value_cell|__wti_rec_upd_select|__wt_txn_tw_stop_visible_all)$
- **source_authority**: community-canonical
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/%E7%A3%81%E7%9B%98%E5%B7%B2%E6%8C%81%E4%B9%85%E5%8C%96%E6%95%B0%E6%8D%AE%E7%9A%84%E6%B8%85%E7%90%86%E4%BB%A3%E7%A0%81%E8%B7%AF%E5%BE%84.md
- **source_url_lang**: zh-cn

### pattern_quote

> if (upd == NULL && __wt_txn_tw_stop_visible_all(session, twp))

### mechanism_quote

> 如果我们 reconcile 一个磁盘上的 key，该 key 有一个全局可见的 stop 时间点，

### workload_implication_quote

> 结果：这个 key 不会被写入新的磁盘页面

| 字段 | 值 |
|---|---|
| hotness_threshold | (NULL · 原文未给具体占比阈值) |

## case_id: wt-reconcile-write-wrapup-block-free-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **scope**: storage-engine-wt
- **signature_type**: function-prefix
- **match_layer**: function
- **pattern_regex**: ^(__rec_write_wrapup|__rec_split_discard|__wt_ref_block_free|__wt_btree_block_free)$
- **source_authority**: community-canonical
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/%E7%A3%81%E7%9B%98%E5%B7%B2%E6%8C%81%E4%B9%85%E5%8C%96%E6%95%B0%E6%8D%AE%E7%9A%84%E6%B8%85%E7%90%86%E4%BB%A3%E7%A0%81%E8%B7%AF%E5%BE%84.md
- **source_url_lang**: zh-cn

### pattern_quote

> __wt_btree_block_free(WT_SESSION_IMPL *session, const uint8_t *addr, size_t addr_size)

### mechanism_quote

> *     Helper function to free a block from the current tree.

### workload_implication_quote

> 后续写入优先使用 free list 中的块

| 字段 | 值 |
|---|---|
| hotness_threshold | (NULL · 原文未给具体占比阈值) |

## case_id: wt-reconcile-row-leaf-tombstone-not-globally-visible-01

- **entry_kind**: flame-signature
- **db**: mongodb
- **scope**: storage-engine-wt
- **signature_type**: stack-pattern
- **match_layer**: stack-frame-pattern
- **pattern_regex**: ^(__wti_rec_row_leaf|__wti_rec_upd_select|__wt_txn_tw_stop_visible_all|__wti_rec_image_copy)$
- **source_authority**: community-canonical
- **source_url**: https://raw.githubusercontent.com/y123456yz/reading-and-annotate-wiredtiger-11.3.1/main/%E4%B8%BA%E4%BB%80%E4%B9%88%E5%B7%B2%E5%88%A0%E9%99%A4%E6%95%B0%E6%8D%AE%E4%BB%8D%E5%9C%A8%E6%96%87%E4%BB%B6%E4%B8%AD_%E6%B7%B1%E5%BA%A6%E5%88%86%E6%9E%90.md
- **source_url_lang**: zh-cn

### pattern_quote

> // __wti_rec_row_leaf() - 行叶页 reconciliation > /* For each entry in the page... */ WT_ROW_FOREACH (page, rip, i) {  // 遍历页面中的每一行 >     /* Look for an update. */ WT_ERR(__wti_rec_upd_select(session, r, NULL, rip, vpack, &upd_select)); upd = upd_select.upd; >     // 对于每个 key 单独判断 if (upd == NULL && __wt_txn_tw_stop_visible_all(session, twp)) upd = &upd_tombstone;  // 这个 key 可以跳过 >     if (upd->type == WT_UPDATE_TOMBSTONE) goto leaf_insert;  // 跳过这个 key >     // 否则写入这个 key __wti_rec_image_copy(session, r, key); __wti_rec_image_copy(session, r, val); }

### mechanism_quote

> Reconciliation 逻辑： - 遍历整个页面的所有 key - 只要有任何一个 key 的 tombstone 不是全局可见 - 整个页面都会被保留（包括那些很旧的 key）

### workload_implication_quote

> 结果： - Z=4 虽然很旧，但和 Z=1997571 在同一页 - Z=1997571 不能删除（仍在窗口内） - → 整个页面被保留 - → Z=4 也被保留
