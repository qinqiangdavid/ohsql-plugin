#!/usr/bin/env python3
"""GaussDB 离线采集 collector · python 版 (纯 stdlib).

跑在 db 服务器上,逐个执行 checklist.ndjson 里的 collection_method,
把 stdout/stderr/exit_code 落到 outdir/。描述性中文 method 标 manual 跳过。

用法:
  python3 collect.py [--checklist checklist.ndjson] [--out OUTDIR]
                     [--timeout 5] [--dryrun]
例:
  source ~/gauss_env_file              # 先 source gsql env
  python3 collect.py --out ./out-$(hostname)-$(date +%Y%m%d)

依赖: python3 3.6+ · (subprocess.run timeout 走 SIGTERM)
输出: 跟 collect.sh 一样
  <outdir>/collect-report.ndjson
  <outdir>/stdout/<check_id>.txt
  <outdir>/stderr/<check_id>.txt
  <outdir>/cmd/<check_id>.sh
  <outdir>/manual.md
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import socket
import subprocess
import sys
from datetime import datetime
from pathlib import Path

DESC_KEYWORDS = [
    '查看', '判断是否', '如果发现', '通常', '示例为', '排查', '建议', '观察', '尝试',
    '可参考', '例如', '可借助', '需要联系', '以下', '应该', '可在', '可以查',
    '可执行', '建议保留', '建议设置',
]
HAN_RE = re.compile(r'[一-鿿]')
CODE_FENCE_RE = re.compile(r'^```\w*\s*|\s*```$')


def is_manual(method: str) -> bool:
    """描述性判定: 8+ 汉字 OR 含描述关键词."""
    m = method.strip()
    if not m or m.lower() in ('null', 'n/a'):
        return True
    hans = len(HAN_RE.findall(m))
    if hans >= 8:
        return True
    return any(kw in m for kw in DESC_KEYWORDS)


def normalize_method(raw: str) -> str:
    """去 backtick / quote / code fence 残留."""
    m = (raw or '').strip()
    m = m.strip('`"\'').strip()
    m = CODE_FENCE_RE.sub('', m)
    return m


def run_one(method: str, cmd_file: Path, stdout_file: Path, stderr_file: Path, timeout: int) -> tuple[str, int]:
    """落 cmd 文件 + bash 执行 + 落 stdout/stderr · 返回 (status, returncode)."""
    cmd_file.write_text(method, encoding='utf-8')
    cmd_file.chmod(0o755)
    try:
        r = subprocess.run(
            ['bash', str(cmd_file)],
            capture_output=True, timeout=timeout, text=False,
        )
        stdout_file.write_bytes(r.stdout)
        stderr_file.write_bytes(r.stderr)
        if r.returncode == 0:
            return ('auto-ok', 0)
        return (f'auto-error-rc{r.returncode}', r.returncode)
    except subprocess.TimeoutExpired as e:
        stdout_file.write_bytes(e.stdout or b'')
        stderr_file.write_bytes((e.stderr or b'') + b'\n[TIMEOUT after %ds]' % timeout)
        return ('auto-timeout', 124)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--checklist', default='./checklist.ndjson')
    ap.add_argument('--out', default=None, help='outdir (default: ./collect-results-<ts>)')
    ap.add_argument('--timeout', type=int, default=5, help='单命令超时秒')
    ap.add_argument('--dryrun', action='store_true', help='只 parse · 不跑命令')
    args = ap.parse_args()

    if not Path(args.checklist).exists():
        print(f'ERROR: checklist 不存在: {args.checklist}', file=sys.stderr)
        sys.exit(2)
    if shutil.which('bash') is None:
        print('ERROR: bash not found', file=sys.stderr)
        sys.exit(2)

    outdir = Path(args.out or f'./collect-results-{datetime.now().strftime("%Y%m%d-%H%M%S")}')
    (outdir / 'stdout').mkdir(parents=True, exist_ok=True)
    (outdir / 'stderr').mkdir(parents=True, exist_ok=True)
    (outdir / 'cmd').mkdir(parents=True, exist_ok=True)

    report_path = outdir / 'collect-report.ndjson'
    manual_path = outdir / 'manual.md'
    report_f = report_path.open('w', encoding='utf-8')

    start_ts = datetime.now().astimezone().isoformat(timespec='seconds')
    host = socket.gethostname()
    user = os.environ.get('USER', os.environ.get('USERNAME', 'unknown'))

    manual_lines = [
        '# GaussDB 离线采集运行记录 (manual.md)',
        '',
        f'- 开始: `{start_ts}`',
        f'- host: `{host}` · user: `{user}`',
        f'- timeout: {args.timeout}s · dryrun: {args.dryrun}',
        '',
        '## 描述性 method (跑不了 · 需人审)',
        '',
    ]

    stats = {'total': 0, 'auto_ok': 0, 'auto_err': 0, 'manual': 0, 'skip': 0}

    with open(args.checklist, 'r', encoding='utf-8') as fin:
        for line_no, line in enumerate(fin, 1):
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except Exception as e:
                print(f'  parse error line {line_no}: {e}', file=sys.stderr)
                continue

            cid = d['check_id']
            ctype = d.get('type', '')
            layer = d.get('collection_layer', '')
            name = d.get('metric_name') or d.get('param_name') or ''
            method = normalize_method(d.get('collection_method', ''))

            stats['total'] += 1

            if not method or method.lower() == 'null':
                status = 'skip-empty'
                stats['skip'] += 1
                manual_lines.append(f'### `{cid}` · empty method · {name}')
                manual_lines.append(f'- layer: `{layer}` · type: `{ctype}`')
                manual_lines.append('')
            elif is_manual(method):
                status = 'manual-descriptive'
                stats['manual'] += 1
                manual_lines += [
                    f'### `{cid}` · {name}',
                    f'- layer: `{layer}` · type: `{ctype}`',
                    '- method:',
                    '  ```',
                    f'  {method}',
                    '  ```',
                    '',
                ]
            elif args.dryrun:
                status = 'dryrun-would-run'
                stats['auto_ok'] += 1
            else:
                cmd_file = outdir / 'cmd' / f'{cid}.sh'
                std_out = outdir / 'stdout' / f'{cid}.txt'
                std_err = outdir / 'stderr' / f'{cid}.txt'
                # 头注释方便复跑
                header = (
                    f'#!/usr/bin/env bash\n'
                    f'# check_id: {cid}\n'
                    f'# name: {name}\n'
                    f'# layer: {layer} · type: {ctype}\n\n'
                )
                cmd_file.write_text(header + method + '\n', encoding='utf-8')
                cmd_file.chmod(0o755)
                # 用 cmd_file 直接 bash 跑
                status, rc = run_one(
                    method=method, cmd_file=cmd_file,
                    stdout_file=std_out, stderr_file=std_err,
                    timeout=args.timeout,
                )
                if rc == 0:
                    stats['auto_ok'] += 1
                else:
                    stats['auto_err'] += 1

            report_f.write(json.dumps({
                'check_id': cid, 'type': ctype, 'layer': layer,
                'name': name, 'status': status,
            }, ensure_ascii=False) + '\n')

            if stats['total'] % 30 == 0:
                print(f"  [{stats['total']}]  auto-ok={stats['auto_ok']}  "
                      f"manual={stats['manual']}  skip={stats['skip']}  err={stats['auto_err']}")

    report_f.close()
    manual_path.write_text('\n'.join(manual_lines) + '\n', encoding='utf-8')

    end_ts = datetime.now().astimezone().isoformat(timespec='seconds')
    print('\n─────────────────────────────────────────────')
    print(f'完成 · 开始 {start_ts} · 结束 {end_ts}')
    print(f"  total              : {stats['total']}")
    print(f"  auto-ok            : {stats['auto_ok']}  (跑成功)")
    print(f"  auto-error         : {stats['auto_err']}  (执行失败 / 超时)")
    print(f"  manual-descriptive : {stats['manual']}  (描述性中文 · 见 manual.md)")
    print(f"  skip-empty         : {stats['skip']}  (method 为 NULL / 空)")
    print()
    print(f'报告        : {report_path}')
    print(f'manual 列表 : {manual_path}')
    print(f'stdout 目录 : {outdir / "stdout"}')
    print(f'stderr 目录 : {outdir / "stderr"}')
    print(f'cmd 目录    : {outdir / "cmd"}  (复跑某条:  bash {outdir}/cmd/<check_id>.sh)')


if __name__ == '__main__':
    main()
