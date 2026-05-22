#!/usr/bin/env bash
# GaussDB 离线采集 collector · bash 版
#
# 跑在 db 服务器上, 逐个执行 checklist.ndjson 里的 collection_method,
# 把 stdout/stderr/exit_code 落到 outdir/。
# 描述性中文 method (蒸馏出来不可执行) 标 manual 跳过。
#
# 用法:
#   ./collect.sh [checklist.ndjson] [outdir]
# 例:
#   source ~/gauss_env_file              # 先 source gsql env
#   ./collect.sh ./checklist.ndjson ./out-$(hostname)-$(date +%Y%m%d)
#
# 环境变量:
#   COLLECT_TIMEOUT  单命令超时秒 (default: 5)
#   COLLECT_DRYRUN   1 = 只解析不执行 (走 manual heuristic 看分类)
#
# 依赖: bash 4+ · python3 3.6+ · coreutils timeout
# 输出:
#   <outdir>/collect-report.ndjson    # 每行一 check · 状态汇总
#   <outdir>/stdout/<check_id>.txt    # 单 check stdout (auto-ok 才有)
#   <outdir>/stderr/<check_id>.txt    # 单 check stderr
#   <outdir>/cmd/<check_id>.sh        # 真正执行的命令 (便于复跑)
#   <outdir>/manual.md                # 描述性 method 集合 (人审用)

set -uo pipefail

CHECKLIST="${1:-./checklist.ndjson}"
OUTDIR="${2:-./collect-results-$(date +%Y%m%d-%H%M%S)}"
TIMEOUT="${COLLECT_TIMEOUT:-5}"
DRYRUN="${COLLECT_DRYRUN:-0}"

# ── 依赖检查 ──────────────────────────────────────────────────────────────
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found (需 3.6+)" >&2; exit 2; }
[ -f "$CHECKLIST" ] || { echo "ERROR: checklist 不存在: $CHECKLIST" >&2; exit 2; }
# timeout: 只在真跑(非 dryrun)时强制要求 · Linux 是 timeout · macOS coreutils 是 gtimeout
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN=gtimeout
fi
if [ "$DRYRUN" != "1" ] && [ -z "$TIMEOUT_BIN" ]; then
  echo "ERROR: 没找到 timeout/gtimeout (Linux 装 coreutils · macOS 装 brew install coreutils)" >&2
  exit 2
fi

mkdir -p "$OUTDIR"/{stdout,stderr,cmd}
REPORT="$OUTDIR/collect-report.ndjson"
MANUAL_MD="$OUTDIR/manual.md"
: > "$REPORT"
: > "$MANUAL_MD"

# ── 元数据 ────────────────────────────────────────────────────────────────
START_TS="$(date -Iseconds)"
HOSTNAME_VAL="$(hostname 2>/dev/null || echo unknown)"
USER_VAL="$(whoami)"
echo "# GaussDB 离线采集运行记录" > "$MANUAL_MD"
echo "" >> "$MANUAL_MD"
echo "- 开始: \`$START_TS\`" >> "$MANUAL_MD"
echo "- host: \`$HOSTNAME_VAL\` · user: \`$USER_VAL\`" >> "$MANUAL_MD"
echo "- timeout: ${TIMEOUT}s · dryrun: $DRYRUN" >> "$MANUAL_MD"
echo "" >> "$MANUAL_MD"
echo "## 描述性 method (跑不了 · 需人审)" >> "$MANUAL_MD"
echo "" >> "$MANUAL_MD"

# ── 解析 ndjson → TSV (check_id, type, layer, method, metric_or_param) ──
# 用 python3 -c 而非 heredoc · heredoc 跟外层 stdin redirect 冲突
python3 -c '
import json, sys, re
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
    except Exception as e:
        print(f"# parse err: {e}", file=sys.stderr)
        continue
    m = (d.get("collection_method") or "").strip()
    m = m.strip("`\"\x27").strip()
    m = re.sub(r"^```\w*\s*", "", m); m = re.sub(r"\s*```$", "", m)
    name = d.get("metric_name") or d.get("param_name") or ""
    print("\t".join([
        d["check_id"], d.get("type",""), d.get("collection_layer",""),
        name.replace("\t"," ").replace("\n"," "),
        m.replace("\t"," ").replace("\n","\\n"),
    ]))
' < "$CHECKLIST" > "$OUTDIR/parsed.tsv"

TOTAL=$(wc -l < "$OUTDIR/parsed.tsv")
echo "解析 ${TOTAL} 个 check · 开始执行..."
echo ""

# ── manual heuristic (跟 collect.py 保持一致) ─────────────────────────────
is_manual() {
  local method="$1"
  python3 - "$method" <<'PY_CHK'
import sys, re
m = sys.argv[1].strip()
if not m or m.lower() in ('null', 'n/a', ''):
    sys.exit(0)
hans = len(re.findall(r'[一-鿿]', m))
desc_kw = ['查看', '判断是否', '如果发现', '通常', '示例为', '排查', '建议', '观察', '尝试',
           '可参考', '例如', '可借助', '需要联系', '以下', '应该', '可在', '可以查',
           '可执行', '建议保留', '建议设置']
desc = any(kw in m for kw in desc_kw)
# 含 8+ 汉字 OR 含描述关键词 → manual
sys.exit(0 if hans >= 8 or desc else 1)
PY_CHK
}

# ── 主循环 ────────────────────────────────────────────────────────────────
i=0
auto_n=0
manual_n=0
err_n=0
skip_n=0

while IFS=$'\t' read -r check_id check_type layer name method_oneline; do
  i=$((i+1))
  # method 回原 (反单行)
  method="${method_oneline//\\n/$'\n'}"

  if [ -z "$method" ] || [ "$method" = "NULL" ]; then
    status="skip-empty"
    skip_n=$((skip_n+1))
    echo "[$check_id]  empty  ($name)" >> "$MANUAL_MD"
    echo "" >> "$MANUAL_MD"
  elif is_manual "$method"; then
    status="manual-descriptive"
    manual_n=$((manual_n+1))
    echo "### \`$check_id\` · $name" >> "$MANUAL_MD"
    echo "- layer: \`$layer\` · type: \`$check_type\`" >> "$MANUAL_MD"
    echo '- method:' >> "$MANUAL_MD"
    echo '  ```' >> "$MANUAL_MD"
    echo "  $method" >> "$MANUAL_MD"
    echo '  ```' >> "$MANUAL_MD"
    echo "" >> "$MANUAL_MD"
  elif [ "$DRYRUN" = "1" ]; then
    status="dryrun-would-run"
    auto_n=$((auto_n+1))
  else
    # 真跑: method 写到 cmd 文件再 bash 执行 (避免 quote/escape 黑魔法)
    cmd_file="$OUTDIR/cmd/$check_id.sh"
    {
      echo "#!/usr/bin/env bash"
      echo "# check_id: $check_id"
      echo "# name: $name"
      echo "# layer: $layer · type: $check_type"
      echo ""
      echo "$method"
    } > "$cmd_file"
    chmod +x "$cmd_file"

    set +e
    "$TIMEOUT_BIN" "$TIMEOUT" bash "$cmd_file" \
      > "$OUTDIR/stdout/$check_id.txt" \
      2> "$OUTDIR/stderr/$check_id.txt"
    rc=$?
    set -e
    if [ $rc -eq 0 ]; then
      status="auto-ok"
      auto_n=$((auto_n+1))
    elif [ $rc -eq 124 ]; then
      status="auto-timeout"
      err_n=$((err_n+1))
    else
      status="auto-error-rc$rc"
      err_n=$((err_n+1))
    fi
  fi

  # 报告一行 (JSON · 用 python 处理引号 escape)
  python3 -c "
import json
print(json.dumps({
  'check_id': '$check_id',
  'type': '$check_type',
  'layer': '$layer',
  'name': '''$name''',
  'status': '$status',
}, ensure_ascii=False))
" >> "$REPORT"

  if [ $((i % 30)) -eq 0 ] || [ $i -eq $TOTAL ]; then
    echo "[$i/$TOTAL]  auto-ok=$auto_n  manual=$manual_n  skip-empty=$skip_n  error=$err_n"
  fi
done < "$OUTDIR/parsed.tsv"

END_TS="$(date -Iseconds)"
echo ""
echo "─────────────────────────────────────────────"
echo "完成 · 开始 $START_TS · 结束 $END_TS"
echo "  total            : $TOTAL"
echo "  auto-ok          : $auto_n  (跑成功)"
echo "  auto-error       : $err_n   (执行失败 / 超时)"
echo "  manual-descriptive: $manual_n  (描述性中文 · 见 manual.md)"
echo "  skip-empty       : $skip_n   (method 为 NULL / 空)"
echo ""
echo "报告        : $REPORT"
echo "manual 列表 : $MANUAL_MD"
echo "stdout 目录 : $OUTDIR/stdout/"
echo "stderr 目录 : $OUTDIR/stderr/"
echo "cmd 目录    : $OUTDIR/cmd/    (复跑某条:  bash $OUTDIR/cmd/<check_id>.sh)"
