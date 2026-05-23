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
  '可执行', '建议保留', '建议设置',
];
function isManual(m) {
  if (!m || m.toLowerCase() === 'null') return true;
  const hans = (m.match(/[一-鿿]/g) || []).length;
  if (hans >= 8) return true;
  return DESC_KEYWORDS.some(kw => m.includes(kw));
}
function normalize(m) {
  return (m || '').trim().replace(/^[`"']+/, '').replace(/[`"']+$/, '').trim();
}

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
mkdir -p "\$OUTDIR/stdout" "\$OUTDIR/stderr"

# ── 部署形态自识别 (集中式 vs 分布式) ───────────────────────────────────────
# 探测 enable_stream_operator / enable_fast_query_shipping GUC 是否存在.
# 分布式必有这两个 GUC, 集中式必无 (pg_settings 不返回).
# pgxc_node catalog 表在两种部署都可能存在 (空表 · 不可靠) → 不用作判据.
detect_deploy_form() {
  command -v gsql >/dev/null 2>&1 || { echo "unknown-no-gsql"; return; }
  local cnt
  cnt=\$(gsql -d postgres -t -A -c \\
    "SELECT count(*) FROM pg_settings WHERE name IN ('enable_stream_operator','enable_fast_query_shipping')" \\
    2>/dev/null | tr -d '[:space:]')
  case "\$cnt" in
    0) echo "centralized" ;;
    [1-9]*) echo "distributed" ;;
    *) echo "unknown-detect-fail" ;;
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
  local cid="\$1"
  local tmpf
  tmpf=\$(mktemp)
  cat > "\$tmpf"
  set +e
  if [ -n "\$T_BIN" ]; then
    "\$T_BIN" "\$TIMEOUT" bash "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
  else
    bash "\$tmpf" > "\$OUTDIR/stdout/\$cid.txt" 2> "\$OUTDIR/stderr/\$cid.txt"
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
(OUTDIR / 'stdout').mkdir(parents=True, exist_ok=True)
(OUTDIR / 'stderr').mkdir(parents=True, exist_ok=True)

# ── 部署形态自识别 (集中式 vs 分布式) ───────────────────────────────────────
# 探测 enable_stream_operator / enable_fast_query_shipping GUC 是否存在.
# 分布式必有这两个 GUC, 集中式必无.
# pgxc_node catalog 表在两种部署都可能存在 (空表 · 不可靠) → 不用作判据.
def detect_deploy_form():
    import shutil as _sh
    if not _sh.which('gsql'):
        return 'unknown-no-gsql'
    try:
        r = subprocess.run(
            ['gsql', '-d', 'postgres', '-t', '-A', '-c',
             "SELECT count(*) FROM pg_settings WHERE name IN ('enable_stream_operator','enable_fast_query_shipping')"],
            capture_output=True, timeout=5, text=True,
        )
        if r.returncode != 0:
            return 'unknown-detect-fail'
        cnt = r.stdout.strip()
        if cnt == '0': return 'centralized'
        if cnt.isdigit() and int(cnt) > 0: return 'distributed'
        return 'unknown-detect-fail'
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
    for i, (cid, name, layer, method) in enumerate(CHECKS, 1):
        try:
            r = subprocess.run(['bash', '-c', method], capture_output=True, timeout=TIMEOUT)
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
