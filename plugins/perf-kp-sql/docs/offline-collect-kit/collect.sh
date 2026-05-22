#!/usr/bin/env bash
# GaussDB 离线采集 collector · bash 版 (纯 shell + jq)
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
#   COLLECT_DRYRUN   1 = 只解析不执行 (看分类)
#
# 依赖 (RHEL/CentOS/openEuler/Ubuntu 全可一行装):
#   bash 4+ · jq · GNU timeout (coreutils) · grep -E (POSIX)
#   RHEL/CentOS/openEuler:  yum install -y jq coreutils
#   Ubuntu/Debian:          apt install -y jq coreutils
#   macOS 测试:             brew install jq coreutils  (timeout → gtimeout)
#
# 不依赖 python3 / awk gawk 扩展 / 任何编译型工具.

set -uo pipefail

CHECKLIST="${1:-./checklist.ndjson}"
OUTDIR="${2:-./collect-results-$(date +%Y%m%d-%H%M%S)}"
TIMEOUT="${COLLECT_TIMEOUT:-5}"
DRYRUN="${COLLECT_DRYRUN:-0}"

# ── 依赖检查 ──────────────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq not found (yum install -y jq)" >&2; exit 2; }
[ -f "$CHECKLIST" ] || { echo "ERROR: checklist 不存在: $CHECKLIST" >&2; exit 2; }

# timeout: Linux 是 timeout, macOS coreutils 是 gtimeout · dryrun 不需要
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then TIMEOUT_BIN=timeout
elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT_BIN=gtimeout
fi
if [ "$DRYRUN" != "1" ] && [ -z "$TIMEOUT_BIN" ]; then
  echo "ERROR: 没找到 timeout/gtimeout (yum install coreutils · macOS brew install coreutils)" >&2
  exit 2
fi

mkdir -p "$OUTDIR"/{stdout,stderr,cmd}
REPORT="$OUTDIR/collect-report.ndjson"
MANUAL_MD="$OUTDIR/manual.md"
: > "$REPORT"
: > "$MANUAL_MD"

# ── 元数据 ────────────────────────────────────────────────────────────────
START_TS="$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
HOSTNAME_VAL="$(hostname 2>/dev/null || echo unknown)"
USER_VAL="$(whoami)"
{
  echo "# GaussDB 离线采集运行记录"
  echo ""
  echo "- 开始: \`$START_TS\`"
  echo "- host: \`$HOSTNAME_VAL\` · user: \`$USER_VAL\`"
  echo "- timeout: ${TIMEOUT}s · dryrun: $DRYRUN"
  echo ""
  echo "## 描述性 method (跑不了 · 需人审)"
  echo ""
} > "$MANUAL_MD"

# ── 解析 ndjson → 每条记录铺 5 行 (每字段 1 行) ──────────────────────────
# 不用 IFS 切分: bash 不同版本对 control-char IFS / whitespace IFS 行为不稳
# 改成: jq 把每个字段输出 1 行 · method 走 base64 (避免 special char 干扰)
#       bash 用连续 5 次 read 读 5 行 = 1 个 record · 稳 + portable (bash 3+ OK)
jq -r '
  .check_id,
  (.type // ""),
  (.collection_layer // ""),
  (if ((.metric_name // "") == "") then (.param_name // "") else .metric_name end),
  ((.collection_method // "") | @base64)
' < "$CHECKLIST" > "$OUTDIR/parsed.lines"

TOTAL=$(( $(wc -l < "$OUTDIR/parsed.lines" | tr -d ' ') / 5 ))
echo "解析 ${TOTAL} 个 check · 开始执行..."
echo ""

# ── manual heuristic (纯 bash + grep · 数 UTF-8 多字节序列字节数估算汉字) ──
# UTF-8 编码: 3-byte char 头 byte 在 0xE0-0xEF 范围 (CJK 主要在 0xE4-0xE9)
# 我们用 LC_ALL=C + grep -c 数 3-byte 序列起始 byte 数 (≈ 汉字数)
is_manual() {
  local method="$1"
  # 空 / NULL
  case "$method" in ''|NULL|null|n/a|'(NULL'*) return 0 ;; esac
  # 描述关键词
  if echo "$method" | LC_ALL=zh_CN.UTF-8 grep -qE '查看|判断是否|如果发现|通常|示例为|排查|建议|观察|尝试|可参考|例如|可借助|需要联系|以下|应该|可在|可以查|可执行|建议保留|建议设置' 2>/dev/null; then
    return 0
  fi
  # 汉字计数: 找 UTF-8 3-byte 序列起始 byte (0xE0-0xEF)
  # printf '%s' 避免 echo -e 解释 + LC_ALL=C 让 grep 按 byte 处理
  local hans
  hans=$(printf '%s' "$method" | LC_ALL=C grep -oE $'[\xe0-\xef][\x80-\xbf][\x80-\xbf]' 2>/dev/null | wc -l | tr -d ' ')
  [ "${hans:-0}" -ge 8 ] && return 0
  return 1
}

# ── 主循环: 每 5 行读 1 record (cid / type / layer / name / method_b64) ───
i=0
auto_n=0
manual_n=0
err_n=0
skip_n=0

while read -r check_id && read -r check_type && read -r layer && read -r name && read -r method_b64; do
  i=$((i+1))
  # method 走 base64 decode (避免 IFS / 引号 / control char 各种坑)
  method=$(printf '%s' "$method_b64" | base64 -d 2>/dev/null || echo '')
  # strip leading/trailing backtick / quote / spaces (单字符匹配)
  method=$(printf '%s' "$method" | sed -e 's/^[`"'"'"'[:space:]]*//' -e 's/[`"'"'"'[:space:]]*$//')

  if [ -z "$method" ] || [ "$method" = "NULL" ]; then
    status="skip-empty"
    skip_n=$((skip_n+1))
    {
      echo "### \`$check_id\` · empty method · $name"
      echo "- layer: \`$layer\` · type: \`$check_type\`"
      echo ""
    } >> "$MANUAL_MD"
  elif is_manual "$method"; then
    status="manual-descriptive"
    manual_n=$((manual_n+1))
    {
      echo "### \`$check_id\` · $name"
      echo "- layer: \`$layer\` · type: \`$check_type\`"
      echo "- method:"
      echo '  ```'
      printf '  %s\n' "$method"
      echo '  ```'
      echo ""
    } >> "$MANUAL_MD"
  elif [ "$DRYRUN" = "1" ]; then
    status="dryrun-would-run"
    auto_n=$((auto_n+1))
  else
    # 真跑: method 写到 cmd 文件再 bash 执行
    cmd_file="$OUTDIR/cmd/$check_id.sh"
    {
      echo "#!/usr/bin/env bash"
      echo "# check_id: $check_id"
      echo "# name: $name"
      echo "# layer: $layer · type: $check_type"
      echo ""
      printf '%s\n' "$method"
    } > "$cmd_file"
    chmod +x "$cmd_file"

    set +e
    "$TIMEOUT_BIN" "$TIMEOUT" bash "$cmd_file" \
      > "$OUTDIR/stdout/$check_id.txt" \
      2> "$OUTDIR/stderr/$check_id.txt"
    rc=$?
    set -e
    case $rc in
      0)   status="auto-ok"; auto_n=$((auto_n+1)) ;;
      124) status="auto-timeout"; err_n=$((err_n+1)) ;;
      *)   status="auto-error-rc$rc"; err_n=$((err_n+1)) ;;
    esac
  fi

  # 报告一行 · 用 jq 做 JSON escape (避免 bash 拼 JSON 时引号问题)
  jq -nc \
    --arg cid "$check_id" --arg t "$check_type" \
    --arg l "$layer" --arg n "$name" --arg s "$status" \
    '{check_id: $cid, type: $t, layer: $l, name: $n, status: $s}' >> "$REPORT"

  if [ $((i % 30)) -eq 0 ] || [ "$i" = "$TOTAL" ]; then
    echo "[$i/$TOTAL]  auto-ok=$auto_n  manual=$manual_n  skip-empty=$skip_n  error=$err_n"
  fi
done < "$OUTDIR/parsed.lines"

END_TS="$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""
echo "─────────────────────────────────────────────"
echo "完成 · 开始 $START_TS · 结束 $END_TS"
echo "  total              : $TOTAL"
echo "  auto-ok            : $auto_n  (跑成功)"
echo "  auto-error         : $err_n   (执行失败 / 超时)"
echo "  manual-descriptive : $manual_n  (描述性中文 · 见 manual.md)"
echo "  skip-empty         : $skip_n   (method 为 NULL / 空)"
echo ""
echo "报告        : $REPORT"
echo "manual 列表 : $MANUAL_MD"
echo "stdout 目录 : $OUTDIR/stdout/"
echo "stderr 目录 : $OUTDIR/stderr/"
echo "cmd 目录    : $OUTDIR/cmd/    (复跑某条:  bash $OUTDIR/cmd/<check_id>.sh)"
