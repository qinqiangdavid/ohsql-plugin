#!/usr/bin/env node
// 从 checklist.ndjson 编译出"自包含"采集脚本 collect-precompiled.{sh,py}.
// 跟 collect.{sh,py} 的区别:那俩"现场解析" ndjson · 这俩"预编译" 命令直接 inline.
//
// 部署到 db 服务器后:不需要 jq / python3 解析 ndjson / 现场 heuristic.
//
// 用法 (本地一次性跑):
//   node _build-precompiled.mjs
// 改 checklist.ndjson 后重跑即可重新生成 .sh / .py.

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const NDJSON = join(HERE, 'checklist.ndjson');
const OUT_SH = join(HERE, 'collect-precompiled.sh');
const OUT_PY = join(HERE, 'collect-precompiled.py');

const DESC_KEYWORDS = [
  '查看', '判断是否', '如果发现', '通常', '示例为', '排查', '建议', '观察', '尝试',
  '可参考', '例如', '可借助', '需要联系', '以下', '应该', '可在', '可以查',
  '可执行', '建议保留', '建议设置', '日志中', '日志中会', '建议保持', '请联系',
];
function isManual(m) {
  if (!m || m.toLowerCase() === 'null') return true;
  const hans = (m.match(/[一-鿿]/g) || []).length;
  const ascii = (m.match(/[a-zA-Z0-9]/g) || []).length;

  // 1. 短描述: 4+ 汉字 (从 8 降下来 · 集中式实测 8 个 rc127 都是 3-6 汉字纯描述)
  if (hans >= 4) return true;
  // 2. 描述关键词
  if (DESC_KEYWORDS.some(kw => m.includes(kw))) return true;
  // 3. distill 字段残留 ('- **abnormal_patterns**: [...]' / '- **collection_method**: ...')
  if (/^\s*-\s+\*\*[a-z_]+\*\*\s*:/i.test(m)) return true;
  // 4. 纯中文 metric 名 (含汉字 · ASCII alphanumeric 太少 → 不是命令)
  if (hans >= 1 && ascii < 5) return true;
  // 5. 单 token 视图/表名 (含 _ · 无空格 · 没 SELECT FROM · 不是 ready-to-run)
  if (/^[a-z_][a-z0-9_.]+$/i.test(m) && m.length > 6 && !/^(top|sar|free|vmstat|iostat|netstat|pidstat|gstack|gsql|perf|jstack|jmap|strace|tcpdump|dmesg)$/i.test(m)) return true;
  // 6. 含中文占位符 (进程号 / 实例号 / xxx / <var>)
  if (/进程号|实例号|查询.{0,2}号|<\w+>|\bxxx\b|\bXXX\b/.test(m)) return true;
  // 7. 日志关键词描述行 (WARNING / ERROR / 日志中 starts)
  if (/^(WARNING|ERROR|FATAL|PANIC|NOTICE|HINT)[:\s]/.test(m)) return true;
  // 8. 起始中文动词 ("查询pg_proc" / "查看 xxx" / "执行 EXPLAIN ..." 类 · 非 ready-to-run)
  if (/^(查询|查看|检测|分析|定位|确认|计算|获取|读取|检查|执行)/.test(m)) return true;
  // 9. 含真 PID/OID 数字占位 (4+ 连续数字 + 短 cmd) · 像 'gstack 14104' / 'strace -p 12345'
  if (/^(gstack|strace|jstack|jmap|pstack|pmap)\s+\d{4,}/.test(m)) return true;
  // 10. GaussDB 集群工具 (gs_ssh / gs_om / cm_ctl / gs_check) · 分布式专用 · 集中式无效
  if (/^(gs_ssh|gs_om|cm_ctl|gs_check|gs_collector|gs_dump)\b/.test(m)) return true;

  return false;
}
function normalize(m) {
  let s = (m || '').trim();
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
  return s;
}

// 起始词在这些 SQL 关键字里 · collector 跑时自动走 gsql -f 而非 bash
const SQL_FIRST_WORDS = ['SELECT','EXPLAIN','SHOW','WITH','SET','VACUUM','ANALYZE',
  'CREATE','ALTER','DROP','TRUNCATE','UPDATE','INSERT','DELETE','COPY','REINDEX',
  'CHECKPOINT','GRANT','REVOKE','RESET','BEGIN','COMMIT','ROLLBACK','CALL','VALUES'];

// 分类
const checks = readFileSync(NDJSON, 'utf8').trim().split('\n').map(l => JSON.parse(l));
const auto = [], manual = [], skip = [];
for (const c of checks) {
  const m = normalize(c.collection_method || '');
  const name = c.metric_name || c.param_name || '';
  const e = { ...c, name, method: m };
  if (!m || m.toLowerCase() === 'null') skip.push(e);
  else if (isManual(m)) manual.push(e);
  else auto.push(e);
}
console.log(`auto=${auto.length} · manual=${manual.length} · skip=${skip.length} · total=${checks.length}`);

// ── bash 预编译版 (heredoc 风格 · 不需 jq / python3) ───────────────────────
const shHead = `#!/usr/bin/env bash
# GaussDB 离线采集 · 预编译版 · 完全自包含
# 所有 ${auto.length} 个 auto 命令已 inline 为 heredoc (不解析 ndjson · 不需 jq).
#
# 生成时间: ${new Date().toISOString()}
# 数据: auto=${auto.length} · manual=${manual.length} · skip=${skip.length} · total=${checks.length}
#
# 用法:
#   source ~/gauss_env_file              # 先 source gsql env (如需要)
#   ./collect-precompiled.sh             # 默认输出到 ./collect-results-<ts>/
#   ./collect-precompiled.sh /tmp/out    # 自定义 outdir
#
# 环境变量:
#   COLLECT_TIMEOUT  单命令超时秒 (default: 5)
#
# 依赖: bash 3+ · mktemp · (可选) GNU timeout / gtimeout

set -uo pipefail
OUTDIR="\${1:-./collect-results-\$(date +%Y%m%d-%H%M%S)}"
TIMEOUT="\${COLLECT_TIMEOUT:-5}"
T_BIN=\$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || echo "")
# top / sar / vmstat 等 tty 工具在非交互 shell 会抱怨 TERM unset · 给个 dumb 兜底
export TERM="\${TERM:-dumb}"
mkdir -p "\$OUTDIR/stdout" "\$OUTDIR/stderr"

# ── 部署形态自识别 (集中式 / 分布式 / 单节点) ──────────────────────────────
# 用 GaussDB 内置函数 pg_catalog.gs_deployment() (C immutable · 返回 text).
# 实测返回值:
#   BusinessCentralized   → 集中式 (商用版)
#   Distribute            → 分布式 (含 CN/DN 拓扑)
#   SingleNode 类         → 单节点 (兜底匹配)
# 这函数 GaussDB 内核保证一致 · 不依赖 GUC 注册时机 / catalog schema 残留.
detect_deploy_form() {
  command -v gsql >/dev/null 2>&1 || { echo "unknown-no-gsql"; return; }
  local v
  v=\$(gsql -d postgres -t -A -c "SELECT pg_catalog.gs_deployment()" 2>/dev/null | tr -d '[:space:]')
  local lower
  lower=\$(echo "\$v" | tr '[:upper:]' '[:lower:]')
  case "\$lower" in
    *centralized*) echo "centralized" ;;
    *distribut*)   echo "distributed" ;;
    *single*node*|*singlenode*) echo "single-node" ;;
    "") echo "unknown-detect-fail" ;;
    *)  echo "unknown-\$v" ;;
  esac
}
DEPLOY_FORM=\$(detect_deploy_form)
echo "部署形态自识别: \$DEPLOY_FORM" >&2

# 写到 report 头部元数据 (注释行 · 也 dump 到 deploy.txt 便于程序解析)
{
  printf '# deploy_form\\t%s\\n' "\$DEPLOY_FORM"
  printf '# detected_at\\t%s\\n' "\$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '# host\\t%s\\n' "\$(hostname 2>/dev/null || echo unknown)"
  printf '# user\\t%s\\n' "\$(whoami)"
  printf 'check_id\\texit_code\\tstatus\\n'
} > "\$OUTDIR/report.tsv"
printf '%s\\n' "\$DEPLOY_FORM" > "\$OUTDIR/deploy.txt"

run_check() {
  # 用法: run_check <check_id> <<'EOF_XXX'
  #         <真命令>
  #       EOF_XXX
  # 自动 dispatch: 起始词是 SQL 关键字 → gsql -f, 否则 bash.
  local cid="\$1"
  local tmpf
  tmpf=\$(mktemp)
  cat > "\$tmpf"
  # 取第一个非空 token (大写化 · 砍标点)
  local first
  first=\$(awk 'NF{for(i=1;i<=NF;i++)if(\$i!~/^--/){print toupper(\$i);exit}}' "\$tmpf" | tr -d '[:punct:]')
  local cmd_kind="shell"
  case "\$first" in
    SELECT|EXPLAIN|SHOW|WITH|SET|VACUUM|ANALYZE|CREATE|ALTER|DROP|TRUNCATE|UPDATE|INSERT|DELETE|COPY|REINDEX|CHECKPOINT|GRANT|REVOKE|RESET|BEGIN|COMMIT|ROLLBACK|CALL|VALUES)
      cmd_kind="sql" ;;
  esac
  set +e
  if [ "\$cmd_kind" = "sql" ]; then
    if [ -n "\$T_BIN" ]; then
      "\$T_BIN" "\$TIMEOUT" gsql -d postgres -f "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    else
      gsql -d postgres -f "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    fi
  else
    if [ -n "\$T_BIN" ]; then
      "\$T_BIN" "\$TIMEOUT" bash "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    else
      bash "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
    fi
  fi
  local rc=\$?
  set -e
  rm -f "\$tmpf"
  local s
  case \$rc in 0) s=ok;; 124) s=timeout;; *) s="error-rc\$rc";; esac
  printf '%s\\t%s\\t%s\\n' "\$cid" "\$rc" "\$s" >> "\$OUTDIR/report.tsv"
}

i=0
TOTAL=${auto.length}
echo "开始: \$TOTAL 个 auto 命令 · timeout \${TIMEOUT}s · outdir \$OUTDIR"
echo ""

`;

let shBody = '';
for (const c of auto) {
  const term = `EOF_${c.check_id.replace(/[^a-zA-Z0-9]/g, '_').toUpperCase()}`;
  shBody += `i=\$((i+1))
[ \$((i % 30)) -eq 0 ] && echo "[\$i/\$TOTAL]" >&2
# ${c.check_id} · ${c.name.replace(/\n/g, ' ').slice(0, 80)} · layer=${c.collection_layer}
run_check "${c.check_id}" <<'${term}'
${c.method}
${term}

`;
}

let shTail = `
# ── ${manual.length} 个描述性 method (蒸馏不可执行 · 写 manual.md) ──────────
cat > "\$OUTDIR/manual.md" <<'MANUAL_DOC_END'
# 需人审 method (描述性中文 · 不自动跑 · 共 ${manual.length} 项)

> distill-v2 蒸馏出来的描述性文本 (含 8+ 汉字 OR "查看/判断/通常/建议..." 等关键词),
> 不能直接当 shell 命令跑。请人工解读后手工执行,把结果跟 case abnormal_pattern 比对。

`;
for (const c of manual) {
  const cleanMethod = c.method.replace(/\n/g, '\n  ');
  shTail += `## ${c.check_id} · ${c.name}\n- layer: \`${c.collection_layer}\` · type: \`${c.type}\`\n- method:\n  \`\`\`\n  ${cleanMethod}\n  \`\`\`\n\n`;
}

shTail += `MANUAL_DOC_END

# ── ${skip.length} 个 NULL/空 method (蒸馏没抽到抓法 · 仅记录) ─────────────
cat > "\$OUTDIR/skip.md" <<'SKIP_DOC_END'
# Skip-empty method (蒸馏没抽到 collection_method · 共 ${skip.length} 项)

`;
for (const c of skip) {
  shTail += `- \`${c.check_id}\` · ${c.name} (layer=\`${c.collection_layer}\`)\n`;
}

shTail += `SKIP_DOC_END

echo ""
echo "─────────────────────────────────────────────"
echo "完成 · TOTAL=${checks.length} · auto=${auto.length} · manual=${manual.length} · skip=${skip.length}"
echo "  报告:        \$OUTDIR/report.tsv"
echo "  stdout 目录: \$OUTDIR/stdout/"
echo "  stderr 目录: \$OUTDIR/stderr/"
echo "  人审 (${manual.length}): \$OUTDIR/manual.md"
echo "  空 method (${skip.length}): \$OUTDIR/skip.md"
`;

writeFileSync(OUT_SH, shHead + shBody + shTail);
console.log(`wrote: ${OUT_SH} (${((shHead+shBody+shTail).length/1024).toFixed(1)} KB)`);

// ── python 预编译版 (CHECKS list · 全 inline) ─────────────────────────────
const pyHead = `#!/usr/bin/env python3
"""GaussDB 离线采集 · 预编译版 · 自包含 · python 纯 stdlib.

所有 ${auto.length} 个 auto 命令已 inline 在 CHECKS list 里 (不解析 ndjson).

生成时间: ${new Date().toISOString()}
数据: auto=${auto.length} · manual=${manual.length} · skip=${skip.length} · total=${checks.length}

用法:
  source ~/gauss_env_file
  python3 collect-precompiled.py [outdir]

环境变量:
  COLLECT_TIMEOUT  单命令超时秒 (default: 5)

依赖: python3 3.6+ · bash (用来跑 method)
"""
import os, subprocess, sys
from pathlib import Path
from datetime import datetime

OUTDIR = Path(sys.argv[1] if len(sys.argv) > 1 else f'./collect-results-{datetime.now().strftime("%Y%m%d-%H%M%S")}')
TIMEOUT = int(os.environ.get('COLLECT_TIMEOUT', '5'))
os.environ.setdefault('TERM', 'dumb')  # top/sar 等 tty 工具非交互需 TERM
(OUTDIR / 'stdout').mkdir(parents=True, exist_ok=True)
(OUTDIR / 'stderr').mkdir(parents=True, exist_ok=True)

# ── 部署形态自识别 (集中式 / 分布式 / 单节点) ──────────────────────────────
# 用 GaussDB 内置函数 pg_catalog.gs_deployment() (C immutable · 返回 text).
# 实测返回值: BusinessCentralized → 集中式 · Distribute → 分布式 · SingleNode → 单节点
def detect_deploy_form():
    import shutil as _sh
    if not _sh.which('gsql'):
        return 'unknown-no-gsql'
    try:
        r = subprocess.run(
            ['gsql', '-d', 'postgres', '-t', '-A', '-c',
             "SELECT pg_catalog.gs_deployment()"],
            capture_output=True, timeout=5, text=True,
        )
        if r.returncode != 0:
            return 'unknown-detect-fail'
        v = r.stdout.strip()
        lo = v.lower()
        if not v: return 'unknown-detect-fail'
        if 'centralized' in lo:                       return 'centralized'
        if 'distribut' in lo:                         return 'distributed'
        if 'singlenode' in lo or 'single_node' in lo: return 'single-node'
        return f'unknown-{v}'
    except Exception:
        return 'unknown-detect-fail'

DEPLOY_FORM = detect_deploy_form()
print(f'部署形态自识别: {DEPLOY_FORM}', file=sys.stderr, flush=True)
(OUTDIR / 'deploy.txt').write_text(DEPLOY_FORM + '\\n')

# (check_id, name, layer, method) · ${auto.length} 条 auto · 直接跑
CHECKS = [
`;

let pyBody = '';
for (const c of auto) {
  pyBody += `    (${JSON.stringify(c.check_id)}, ${JSON.stringify(c.name)}, ${JSON.stringify(c.collection_layer)}, ${JSON.stringify(c.method)}),\n`;
}

let pyMid = `]

# (check_id, name, layer, method) · ${manual.length} 条 manual · 描述性 · 不自动跑
MANUAL = [
`;
for (const c of manual) {
  pyMid += `    (${JSON.stringify(c.check_id)}, ${JSON.stringify(c.name)}, ${JSON.stringify(c.collection_layer)}, ${JSON.stringify(c.method)}),\n`;
}

let pyTail = `]

# (check_id, name, layer) · ${skip.length} 条 skip · 蒸馏没抽到 method
SKIP = [
`;
for (const c of skip) {
  pyTail += `    (${JSON.stringify(c.check_id)}, ${JSON.stringify(c.name)}, ${JSON.stringify(c.collection_layer)}),\n`;
}

pyTail += `]

# ── 主循环 ────────────────────────────────────────────────────────────────
print(f'开始: {len(CHECKS)} 个 auto 命令 · timeout {TIMEOUT}s · outdir {OUTDIR}', flush=True)
report = OUTDIR / 'report.tsv'
with open(report, 'w', encoding='utf-8') as rf:
    import socket as _sk
    rf.write(f'# deploy_form\\t{DEPLOY_FORM}\\n')
    rf.write(f'# detected_at\\t{datetime.now().astimezone().isoformat(timespec="seconds")}\\n')
    rf.write(f'# host\\t{_sk.gethostname()}\\n')
    rf.write(f'# user\\t{os.environ.get("USER", "unknown")}\\n')
    rf.write('check_id\\texit_code\\tstatus\\n')
    # 自动 dispatch: SQL 起始词走 gsql -f, 其他走 bash -c
    SQL_FIRST = {'SELECT','EXPLAIN','SHOW','WITH','SET','VACUUM','ANALYZE','CREATE',
                 'ALTER','DROP','TRUNCATE','UPDATE','INSERT','DELETE','COPY','REINDEX',
                 'CHECKPOINT','GRANT','REVOKE','RESET','BEGIN','COMMIT','ROLLBACK','CALL','VALUES'}
    import tempfile, re as _re
    for i, (cid, name, layer, method) in enumerate(CHECKS, 1):
        # 取第一个非注释 token 大写化
        first = ''
        for tok in _re.split(r'\\s+', method.strip()):
            if tok and not tok.startswith('--'):
                first = _re.sub(r'[^A-Z0-9_]', '', tok.upper())
                break
        is_sql = first in SQL_FIRST
        try:
            if is_sql:
                with tempfile.NamedTemporaryFile('w', suffix='.sql', delete=False) as tf:
                    tf.write(method)
                    sqlf = tf.name
                r = subprocess.run(['gsql','-d','postgres','-f',sqlf],
                                   capture_output=True, timeout=TIMEOUT)
                os.unlink(sqlf)
            else:
                r = subprocess.run(['bash','-c', method], capture_output=True, timeout=TIMEOUT)
            rc = r.returncode
            (OUTDIR / 'stdout' / f'{cid}.txt').write_bytes(r.stdout)
            (OUTDIR / 'stderr' / f'{cid}.txt').write_bytes(r.stderr)
            status = 'ok' if rc == 0 else f'error-rc{rc}'
        except subprocess.TimeoutExpired as e:
            rc = 124
            status = 'timeout'
            (OUTDIR / 'stdout' / f'{cid}.txt').write_bytes(e.stdout or b'')
            (OUTDIR / 'stderr' / f'{cid}.txt').write_bytes((e.stderr or b'') + f'\\n[TIMEOUT {TIMEOUT}s]'.encode())
        rf.write(f'{cid}\\t{rc}\\t{status}\\n')
        if i % 30 == 0 or i == len(CHECKS):
            print(f'  [{i}/{len(CHECKS)}] {cid}', file=sys.stderr, flush=True)

# manual.md
manual_lines = [f'# 需人审 method (描述性中文 · 不自动跑 · 共 {len(MANUAL)} 项)', '',
                '> distill-v2 蒸馏的描述性文本 · 不能直接 shell 跑 · 请人工解读后手工执行', '']
for cid, name, layer, method in MANUAL:
    manual_lines += [f'## {cid} · {name}', f'- layer: \`{layer}\`',
                     '- method:', '  \`\`\`', f'  {method}', '  \`\`\`', '']
(OUTDIR / 'manual.md').write_text('\\n'.join(manual_lines), encoding='utf-8')

# skip.md
skip_lines = [f'# Skip-empty method (蒸馏没抽到 · 共 {len(SKIP)} 项)', '']
for cid, name, layer in SKIP:
    skip_lines.append(f'- \`{cid}\` · {name} (layer=\`{layer}\`)')
(OUTDIR / 'skip.md').write_text('\\n'.join(skip_lines), encoding='utf-8')

print()
print('─────────────────────────────────────────────')
print(f'完成 · TOTAL={len(CHECKS)+len(MANUAL)+len(SKIP)} · auto={len(CHECKS)} · manual={len(MANUAL)} · skip={len(SKIP)}')
print(f'  报告:         {report}')
print(f'  stdout 目录:  {OUTDIR}/stdout/')
print(f'  stderr 目录:  {OUTDIR}/stderr/')
print(f'  人审 ({len(MANUAL)}): {OUTDIR}/manual.md')
print(f'  空 method ({len(SKIP)}): {OUTDIR}/skip.md')
`;

writeFileSync(OUT_PY, pyHead + pyBody + pyMid + pyTail);
console.log(`wrote: ${OUT_PY} (${((pyHead+pyBody+pyMid+pyTail).length/1024).toFixed(1)} KB)`);
