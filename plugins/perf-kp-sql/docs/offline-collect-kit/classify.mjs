// 离线采集 kit · 命令归一化 + auto/manual 分类 (纯函数 · 可单测)
// 从 _build-precompiled.mjs 抽出 · build 脚本 import 这里 · 测试也 import 这里.
//
// 设计口径 (硬约束):
//   1. auto 集严格只读 — 任何会写/改/杀的命令一律不进 auto (扫整条命令体 · 不只看首词).
//   2. gsql -c "<SQL>" 外壳一律解包成裸 SQL — 让 collector 走 gsql -f (SQL 路径) 而非 bash,
//      这样 SQL 报错探测 (ghost-ok / unsupported) 才生效 (extract-offline-checklist.mjs 既有设计本意).
//   3. 能修成有效只读 auto 的畸形命令就修 (file→cat / sysctl→sysctl / slash 拆多 SHOW / 空格→下划线),
//      修不成的 (JDBC 客户端驱动参数) 才归 manual; 版本特异 GUC 保持 auto 靠运行时标 unsupported.

export const DESC_KEYWORDS = [
  '查看', '判断是否', '如果发现', '通常', '示例为', '排查', '建议', '观察', '尝试',
  '可参考', '例如', '可借助', '需要联系', '以下', '应该', '可在', '可以查',
  '可执行', '建议保留', '建议设置', '日志中', '日志中会', '建议保持', '请联系',
];

// gsql [opts] -c "<SQL>" / 'SQL' → 裸 <SQL>; (让 collector 走 gsql -f 而非 shell)
// 无法干净解包 (多 -c / 管道 / 重定向 / -c 后还有内容) → 原样返回 (matchedRule 会判 manual).
export function unwrapGsqlC(s) {
  let t = (s || '').trim();
  if (!/^gsql\b/.test(t)) return s;
  // 砍掉闭合引号后的 distill 注释残留 (… "<SQL>"  -- 或 SELECT …) · 只认引号后的 · 不碰 SQL 内部
  t = t.replace(/(["'])\s+--\s+[^\n]*$/, '$1');
  // 管道/重定向/多 -c → 不干净 · 不解包 (留 r12 → manual)
  if (/\|\s|[<>]|&&|;\s*gsql\b/.test(t)) return s;
  if ((t.match(/\s-c\b/g) || []).length !== 1) return s;
  const m = t.match(/^gsql\b[^"']*?\s-c\s+(["'])([\s\S]*?)\1\s*$/);
  if (!m) return s;
  let sql = m[2].trim();
  if (!sql) return s;
  if (!/;\s*$/.test(sql)) sql += ';';
  return sql;
}

// 能修成有效只读 auto 的畸形 SHOW 就修; 修不成的原样返回 (matchedRule 兜底判 manual).
export function repairCommand(s) {
  const t = (s || '').trim();
  const m = t.match(/^show\s+(.+?)\s*;?\s*$/i);
  if (!m) return s;
  const arg = m[1].trim();
  // a) 文件路径当 SQL: SHOW /sys/kernel/debug/sched_features → cat <path> (OS 只读)
  if (/^\//.test(arg)) return `cat ${arg}`;
  // b) OS sysctl 当 GUC: SHOW net.core.netdev_max_backlog → sysctl <name>
  //    只认 OS sysctl 命名空间 (net./kernel./vm./fs./dev.) · 不误伤 resource_pool. / sequence. 等 GUC 命名空间
  if (/^(net|kernel|vm|fs|dev)\.[a-z0-9_.]+$/i.test(arg)) return `sysctl ${arg}`;
  // c) 斜杠拼多个 GUC: SHOW a/b/c 或 SHOW a / b → 拆成多条独立 SHOW (都是合法标识符才拆)
  if (arg.includes('/')) {
    const parts = arg.split('/').map(x => x.trim()).filter(Boolean);
    if (parts.length >= 2 && parts.every(p => /^[a-z_][a-z0-9_]*$/i.test(p))) {
      return parts.map(p => `SHOW ${p};`).join('\n');
    }
    return s;
  }
  // d) 空格切碎的标识符: SHOW wal file init num → SHOW wal_file_init_num;
  if (/^[a-z]+(\s+[a-z0-9]+)+$/i.test(arg)) {
    return `SHOW ${arg.replace(/\s+/g, '_')};`;
  }
  return s;
}

export function normalize(m) {
  let s = (m || '').trim();
  // 0. gsql -c "<SQL>" 外壳解包成裸 SQL — 必须在剥首尾引号之前 (否则会把 -c 的闭合引号剥掉解不开)
  //    让 collector 走 gsql -f (SQL 路径) 而非 bash · SQL 报错探测 (ghost-ok/unsupported) 才生效
  s = unwrapGsqlC(s);
  // 1. strip backtick / quote / code-fence 包裹
  s = s.replace(/^[`"']+/, '').replace(/[`"']+$/, '').trim();
  s = s.replace(/^```\w*\s*/, '').replace(/\s*```$/, '').trim();
  // 2. unicode dash → ASCII dash (en-dash – / em-dash — / minus − 都换 -)
  //    distill 蒸 HTML 时被 typographic 替换 · bash / 工具命令不识别非 ASCII dash
  s = s.replace(/[–—−]/g, '-');
  // 3. strip gsql session prompt 残留 (gaussdb=# / yshen=# / 任意 [a-z_]+=# / =>)
  //    distill 阶段从网页文本扒出来的 method 里很常见 · 不去会让 bash 当变量赋值跑
  s = s.replace(/(^|\s)[a-zA-Z_][a-zA-Z0-9_]*=[#>]\s*/g, '$1').trim();
  // 4. 砍 ' -- ' 行内 SQL 注释 (含中文 / 含 "或" 之后的) · 跨多行不动 · 单行就丢
  //    distill 把多语句串在一行 method 里 · -- 后的"或 SELECT ..."注释会污染
  s = s.replace(/\s+--\s+[^\n]*$/g, '').trim();
  // 5. strip leading prompt-like "$ " / "# " / "gaussdb> "
  s = s.replace(/^[#$]\s+/, '').trim();
  // 6. top 单跑要 -b -n 1 (非交互 tty 跑) · 否则 'top: failed tty get'
  if (/^top\s*$/.test(s)) return 'top -b -n 1';
  // 7. sar 同理需要 -n / -u / count interval · 单 'sar' 报错 · 给个轻量兜底
  if (/^sar\s*$/.test(s)) return 'sar -u 1 1';
  // 8. 能修成有效只读 auto 的畸形 SHOW 就修 (file/sysctl/slash/空格)
  s = repairCommand(s);
  return s;
}

// 写/破坏性判定 (r18 + collector 运行时护栏 + 测试共用一份口径 · 严格只读)
//   - 破坏性函数 (pg_terminate_backend 等): 出现即算 (无论位置 · 它会执行)
//   - 写/DDL/重操作 verb: 整词命中即算 · 先剥单引号字符串字面量 (避免 '%vacuum%' / LIKE 模式误伤)
//     \bverb\b 对 autovacuum / last_analyze / pg_create_* 等子串天然不命中 (相邻是 word char · 无边界)
const DESTRUCTIVE_FN = /\b(pg_terminate_backend|pg_cancel_backend|gs_clean|pg_log_backtrace|gs_signal_thread)\b/i;
const WRITE_VERB = /\b(insert|update|delete|drop|truncate|alter|create|reindex|vacuum|analyze|checkpoint|copy|grant|revoke|call)\b/i;
export function isDestructive(m) {
  const noStr = (m || '').replace(/'(?:[^']|'')*'/g, "''");  // 去单引号字符串字面量
  return DESTRUCTIVE_FN.test(noStr) || WRITE_VERB.test(noStr);
}

export function matchedRule(m) {
  if (!m || m.toLowerCase() === 'null') return 'r0-null';
  // r18: 写/改/杀命令一律 manual (硬约束: auto 集严格只读) · 优先于一切 auto 路径
  if (isDestructive(m)) return 'r18-write-destructive';
  const hans = (m.match(/[一-鿿]/g) || []).length;
  const ascii = (m.match(/[a-zA-Z0-9]/g) || []).length;

  if (hans >= 4) return 'r1-cjk-ge-4';
  const hitKw = DESC_KEYWORDS.find(kw => m.includes(kw));
  if (hitKw) return `r2-desc-kw:${hitKw}`;
  if (/^\s*-\s+\*\*[a-z_]+\*\*\s*:/i.test(m)) return 'r3-distill-leak';
  if (hans >= 1 && ascii < 5) return 'r4-cjk-only';
  if (/^[a-z_][a-z0-9_.]+$/i.test(m) && m.length > 6 && !/^(top|sar|free|vmstat|iostat|netstat|pidstat|gstack|gsql|perf|jstack|jmap|strace|tcpdump|dmesg)$/i.test(m)) return 'r5-single-ident';
  if (/进程号|实例号|查询.{0,2}号|<[^>\s]{1,24}>|\bxxx\b|\bXXX\b/.test(m)) return 'r6-cjk-placeholder';
  if (/^(WARNING|ERROR|FATAL|PANIC|NOTICE|HINT)[:\s]/.test(m)) return 'r7-log-kw-start';
  if (/^(查询|查看|检测|分析|定位|确认|计算|获取|读取|检查|执行)/.test(m)) return 'r8-cjk-verb-start';
  if (/^(gstack|strace|jstack|jmap|pstack|pmap)\s+\d{4,}/.test(m)) return 'r9-pid-literal';
  if (/^(gs_ssh|gs_om|cm_ctl|gs_check|gs_collector|gs_dump)\b/.test(m)) return 'r10-cluster-tool';
  // r14: 异地容灾(streaming DR / HADR)专用视图 · 跟拓扑正交 · 没配容灾的部署上不存在 → 不盲采(进 manual)
  if (/\bgs_hadr_/i.test(m)) return 'r14-hadr-deploy-only';
  // r13: 占位对象名字面量(需运行时填具体表/列名才能跑)· 如 'tablename' / 'table_name'::regclass
  if (/'(table_?name|schema_?name|index_?name|your_table|表名|列名|目标表)'/i.test(m)) return 'r13-placeholder-objname';
  // r15: 必带具体表参的函数(table_skewness / pg_get_tabledef)· 离线没具体表 → 进 manual
  if (/\b(table_skewness|pg_get_tabledef)\s*\(/i.test(m)) return 'r15-needs-table-arg';
  // r16: 含 plan hint /*+ ... */ 的示例调优查询(多引用 TPC-DS 等示例表)· 不能盲跑
  if (/\/\*\+/.test(m)) return 'r16-plan-hint-example';
  // r17: 其它占位(花括号 {query_id} / xxxx-xx-xx 占位日期 / $a±$b 占位算式)· 需填值
  if (/\{[a-z_]{2,}\}|x{4,}-x{2}-x{2}|\bxxxx\b|\$[a-z_]{2,}\s*[-+]\s*\$[a-z_]{2,}/i.test(m)) return 'r17-placeholder-value';

  // r23: SQL 里硬编码了具体长数字 id(query_id/sessionid 等 · ≥12 位)· 客户库上不存在 → 返回空 → 需填实际值
  if (/=\s*'?\d{12,}'?/.test(m)) return 'r23-hardcoded-id-literal';
  // r24: 形如 col = 'col'(列名被当字面量过滤 · distill 漏掉了实际值)· 永远匹配不到 → 需填实际值
  if (/\b([a-z_]{3,})\s*=\s*'\1'/i.test(m)) return 'r24-self-name-literal';

  // r21: SHOW <JDBC 客户端驱动参数 / camelCase> · 非服务端 GUC · repair 修不成 auto → 人审
  //   (snake_case 版本特异 GUC 不在此列 · 保持 auto 靠运行时标 unsupported)
  {
    const _sh = m.match(/^show\s+([a-z][a-z0-9_]*)\s*;?\s*$/i);
    if (_sh) {
      const p = _sh[1];
      const JDBC = new Set(['fetchsize', 'logintimeout', 'connectiontimeout', 'connecttimeout',
        'sockettimeout', 'defaultrowfetchsize', 'preparethreshold', 'cancelsignaltimeout']);
      if (JDBC.has(p.toLowerCase()) || /[a-z][A-Z]/.test(p)) return 'r21-jdbc-client-param';
    }
  }
  // r19: 单行 SHOW 参数仍非干净(点分)标识符 — repair 没接住的畸形(slash/空格残留) → 人审
  {
    const _sh = m.match(/^show\s+(.+?)\s*;?\s*$/i);
    if (_sh && !/^[a-z_][a-z0-9_.]*$/i.test(_sh[1].trim())) return 'r19-malformed-show';
  }

  // r22: debugfs (/sys/kernel/debug/*) 只 root 可读 · 采集器以 DB 用户跑必然权限拒绝 · 修不成 auto → 人审
  if (/^cat\s+\/sys\/kernel\/debug\//i.test(m)) return 'r22-needs-root';

  // 只留"无参可盲跑"的命令进 auto · 其余转 manual (剥离前置 set ...; 再判)
  const _body = m.replace(/^\s*(?:set\s+[^;]+;\s*)+/i, '').trim();
  // r11: explain 类 · 离线没有诊断目标 SQL · 不能盲跑
  if (/^explain\b/i.test(_body)) return 'r11-explain-needs-target';
  // r12: 起始不是已知"无参只读"命令(SQL 读取 verb / OS 只读工具) → 不能盲跑
  const _first = (_body.match(/^[a-zA-Z_][a-zA-Z0-9_]*/) || [''])[0].toLowerCase();
  const _BLIND = new Set([
    'select','show','with','values','table',          // SQL 只读
    // 注: 'gsql' 已从 BLIND 移除 — 干净的 gsql -c "<SQL>" 已在 normalize 解包成裸 SQL;
    //     残留的 gsql(管道/多 -c 等解不开的) 落到 r12 → manual (不盲跑整条 gsql 外壳)
    'cat','iostat','sysctl','top','df','free','vmstat','netstat','ps','grep','egrep',
    'find','ss','sar','uptime','lscpu','numactl','mpstat','pidstat','head','tail','du','awk','wc',  // OS 只读
    'gs_guc',                                          // gs_guc check 读参数
  ]);
  if (!_BLIND.has(_first)) return 'r12-not-blind-runnable';

  return null;
}
export function isManual(m) { return matchedRule(m) !== null; }

// 命令是否为"纯 SHOW <guc>"(一条或多条 · 允许多行) — 用来整合进 pg_settings 全量抓取
export function isPureShowGuc(m) {
  const t = (m || '').trim();
  if (!t) return false;
  const stmts = t.split('\n').map(s => s.trim()).filter(Boolean);
  return stmts.length > 0 && stmts.every(s => /^show\s+[a-z_][a-z0-9_.]*\s*;?$/i.test(s));
}

// 命令的"唯一对象目标": 纯 SHOW<guc> → pg_settings; 否则 FROM/JOIN 目标恰好一个且在快照表里 → 该视图; 否则 null.
// (只折"单视图简单切片" · 带 JOIN 别的表的复杂查询不折)
export function soleViewTarget(m, snapshotViews) {
  if (isPureShowGuc(m)) return snapshotViews.has('pg_settings') ? 'pg_settings' : null;
  const tgts = new Set([...(m || '').matchAll(/\b(?:from|join)\s+([a-z_][a-z0-9_.]*)/gi)].map(x => x[1].toLowerCase()));
  if (tgts.size === 1) {
    const v = [...tgts][0];
    if (snapshotViews.has(v)) return v;
  }
  return null;
}

// 整合: 同一对象被多条 check 各采一片 → 收敛成一条"SELECT <指定列> FROM <视图>"全快照(无 WHERE · 离线过滤).
// snapshotMap: { 视图名: '该视图的快照 SQL' }. pg_settings 同时吸收纯 SHOW<guc> 和 SELECT...FROM pg_settings.
// topology 取被折 check 的共同值(不一致则 common). 顺带消化掉单视图里的占位/死 check(WHERE 被整表快照取代).
export function consolidateViewChecks(auto, snapshotMap) {
  const views = new Set(Object.keys(snapshotMap));
  const foldedBy = {};
  const kept = [];
  for (const c of auto) {
    const v = soleViewTarget(c.method, views);
    if (v) { (foldedBy[v] = foldedBy[v] || []).push(c); continue; }
    kept.push(c);
  }
  for (const [v, list] of Object.entries(foldedBy)) {
    // topology 由视图本身决定: pgxc_* 是分布式专用 catalog(集中式没有 → skip-topology); 其余 pg_*/pg_settings 通用.
    // 不继承原 case 标签 — 否则 pg_stat_activity 被误标 distributed-only 会漏采集中式.
    kept.push({
      check_id: `chk-${v.replace(/_/g, '-')}-snapshot`,
      name: `${v} 快照 (整合自 ${list.length} 条 · 离线过滤)`,
      collection_layer: 'db-system-view',
      topology: /^pgxc_/.test(v) ? 'distributed-only' : 'common',
      method: snapshotMap[v],
      matched_rule: null,
      derived_commands: [],
    });
  }
  return kept;
}

// 精确去重(忽略大小写 + 折叠空白): 同一条命令多个 check_id 只留第一个.
export function dedupByMethod(checks) {
  const seen = new Set();
  const out = [];
  for (const c of checks) {
    const k = (c.method || '').replace(/\s+/g, ' ').trim().toLowerCase();
    if (seen.has(k)) continue;
    seen.add(k);
    out.push(c);
  }
  return out;
}
