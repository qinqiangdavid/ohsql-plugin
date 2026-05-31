# Flame-Signature Index

> 生成时间: 2026-05-31T04:10:00.016Z
> 数据源: distill-v2/cases/<db>/flame-signature/*.md
> 总计: 13 signatures
> 配套: by-flame-signature/CASES.md
> 用途: Phase 2 火焰图路径懒查 — 撞到需读火焰图的 DF case 时,用 pattern_regex 匹配 perf 热点

| case_id | scope | signature_type | pattern_regex | 行号 |
|---|---|---|---|---:|
| linux-fs-mmap-metadata-archiver-01 | linux-fs | stack-pattern | ^(sys_newfstatat\|sys_getdents\|sys_openat\|page_fault).* | 3 |
| glibc-malloc-allocator-hot-stack-01 | mem-allocator-glibc | stack-pattern | ^(__GI___libc_malloc\|Perl_pp_split\|JOIN::(optimize\|exec)).* | 27 |
| linux-mm-brk-heap-expansion-01 | linux-mm | function-prefix | ^(sys_brk\|SyS_brk\|brk)$ | 51 |
| linux-mm-mmap-vm-growth-01 | linux-mm | function-prefix | ^(sys_mmap\|SyS_mmap\|mmap)$ | 75 |
| linux-mm-page-fault-physical-population-01 | linux-mm | function-prefix | ^(handle_mm_fault\|page_fault_user\|page_fault_kernel)$ | 99 |
| linux-block-offwake-disk-io-block-completion-01 | linux-block | stack-pattern | ^(blkif_interrupt\|__blk_mq_complete_request\|blk_mq_end_request\|blk_update_request\|mpage_end_io\|wake_up_page_bit\|__wake_up_common\|autoremove_wake_function\|finish_task_switch\|__schedule\|schedu | 123 |
| wt-evict-cold-page-compact-cure-01 | storage-engine-wt | stack-pattern | (compact\|reconciliation\|evict).* | 147 |
| wt-app-thread-evict-assist-pressure-01 | storage-engine-wt | function-prefix | ^__wt_cache_eviction_.* | 171 |
| wt-evict-reconcile-blocked-ebusy-01 | storage-engine-wt | stack-pattern | ^__evict_(review\|reconcile)$ | 195 |
| wt-capacity-throttle-cond-signal-crash-01 | storage-engine-wt | stack-pattern | (__wt_capacity_throttle\|__capacity_signal\|__wt_cond_signal) | 219 |
| wt-reconcile-row-tombstone-skip-01 | storage-engine-wt | stack-pattern | ^(__wt_row_leaf_value_cell\|__wti_rec_upd_select\|__wt_txn_tw_stop_visible_all)$ | 243 |
| wt-reconcile-write-wrapup-block-free-01 | storage-engine-wt | function-prefix | ^(__rec_write_wrapup\|__rec_split_discard\|__wt_ref_block_free\|__wt_btree_block_free)$ | 271 |
| wt-reconcile-row-leaf-tombstone-not-globally-visible-01 | storage-engine-wt | stack-pattern | ^(__wti_rec_row_leaf\|__wti_rec_upd_select\|__wt_txn_tw_stop_visible_all\|__wti_rec_image_copy)$ | 299 |
