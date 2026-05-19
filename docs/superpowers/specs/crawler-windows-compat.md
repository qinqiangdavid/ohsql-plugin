# crawler 工程 Windows 兼容隐患扫描笔记

> 扫描时间: 2026-05-18
> 范围: /Volumes/WD_BLACK/crawler/ 全工程（Python + Node.js .mjs 脚本）
> 方法: grep + Read · 不修代码

---

## TL;DR（3 句话）

总结：有 **4 处 P0 阻断** / **4 处 P1 大概率坏** / **2 处 P2 小坑**。
最严重的是 `distill-v2/scripts/build-runtime-cases-from-md.mjs` 的双重硬编码：运行时默认路径写死了 `/Volumes/WD_BLACK/myagent/...`，`--dry-run` 输出目录写死了 `/tmp/build-runtime-out`，在 Windows 上两条都直接失败。
建议：Windows 上跑之前必须修 P0 项；P1 项遇到时再修；P2 项影响较小可忽略。

---

## P0 阻断（共 4 处 · 一定坏）

### 1. `build-runtime-cases-from-md.mjs` 硬编码 `/Volumes/` 路径作为默认参数

- **文件**: `distill-v2/scripts/build-runtime-cases-from-md.mjs:44-45`
- **当前代码**:
  ```js
  const RUNTIME = resolve(getArg('runtime',
    '/Volumes/WD_BLACK/myagent/new_ohsql/ohsql-plugin/plugins/perf-kp-sql'));
  ```
- **Windows 上会怎么坏**: `/Volumes/WD_BLACK/...` 是 macOS 外挂磁盘路径，Windows 上这个路径不存在。用户如果不传 `--runtime` 参数（文档中 dry-run 示例也没传），Node.js 的 `resolve()` 会把它当作相对路径的奇怪拼接，`readFileSync` 直接报 ENOENT。
- **修复方向**: 去掉 hardcoded 默认值，改为必填参数；或用 `import.meta.url` 推算相对路径。

---

### 2. `build-runtime-cases-from-md.mjs` 硬编码 `/tmp/` 作为 dry-run 输出目录

- **文件**: `distill-v2/scripts/build-runtime-cases-from-md.mjs:47-48`
- **当前代码**:
  ```js
  const OUT_DIR = resolve(getArg('out',
    DRY ? '/tmp/build-runtime-out' : join(RUNTIME, 'data')));
  ```
- **Windows 上会怎么坏**: Windows 没有 `/tmp` 目录（有 `%TEMP%` 或 `C:\Users\<user>\AppData\Local\Temp\`）。`mkdirSync('/tmp/build-runtime-out', { recursive: true })` 实际上会在当前盘符根目录创建 `\tmp\` 文件夹（行为取决于 Node.js 版本），且与用户预期不符。如果盘符权限受限则直接报权限错误。
- **修复方向**: 用 `os.tmpdir()`（Node.js `node:os` 模块）替代 `'/tmp'`：`import { tmpdir } from 'node:os'; DRY ? join(tmpdir(), 'build-runtime-out') : ...`。

---

### 3. `reverse-map-helper.mjs` 硬编码 `/Volumes/` 路径作为默认参数

- **文件**: `distill-v2/scripts/reverse-map-helper.mjs:17, 29`
- **当前代码**:
  ```js
  // runtime 路径默认: /Volumes/WD_BLACK/myagent/new_ohsql/ohsql-plugin/plugins/perf-kp-sql
  const RUNTIME = getArg('runtime',
    '/Volumes/WD_BLACK/myagent/new_ohsql/ohsql-plugin/plugins/perf-kp-sql');
  ```
- **Windows 上会怎么坏**: 和 P0-1 同理。这个脚本定义为"一次性"，但如果在 Windows 上接手的开发者需要跑 reverse-map，不传参数直接失败。`readFileSync(resolve(RUNTIME, 'data/cases/CASES.md'))` 报 ENOENT。
- **修复方向**: 同 P0-1，去掉 hardcoded 默认值改必填，或注释中明确标注必须 `--runtime` 传参。

---

### 4. `probe-titles.mjs` 和 `fetch-and-prepare.mjs` 调用 `curl` 二进制

- **文件**:
  - `distill-v2/scripts/probe-titles.mjs:28`
  - `distill-v2/scripts/fetch-and-prepare.mjs:66`
- **当前代码**:
  ```js
  const out = execFileSync('curl', [
    '-L', '-A', UA, '-sS', '--compressed', '--max-time', '20',
    '-w', '\n%{http_code}', url,
  ], { encoding: 'utf8', ... });
  ```
- **Windows 上会怎么坏**: Windows 10 Build 17063（2018 年 4 月）及以上内置了 curl.exe，但更早版本没有。更大的问题是：`-w '\n%{http_code}'` 中的 `\n` 在 Windows cmd/PowerShell 解析行为与 bash 不同——不过这里是 `execFileSync` 直接传数组（非 shell=true），所以这个参数本身 OK。真正的风险是 PATH 里找不到 curl 的环境（企业 Windows 镜像、最小化安装）。
- **修复方向**: 这两个脚本是工具脚本（PoC 性质），Windows 上建议改用 Node.js 内置 `fetch()` 替代 curl，彻底消除外部依赖。

---

## P1 大概率坏（共 4 处）

### 5. 所有 `.mjs` 文件的 shebang 行 `#!/usr/bin/env node`

- **文件**: `distill-v2/scripts/*.mjs`（共 17 个文件，全部第一行）
- **代表**:
  ```
  #!/usr/bin/env node
  ```
- **Windows 上会怎么坏**: Windows 不支持 shebang。直接双击或在 cmd/PowerShell 执行 `./build-runtime-cases-from-md.mjs` 会失败（"找不到程序"）。必须改为 `node build-runtime-cases-from-md.mjs`。对 macOS 用户透明，对 Windows 用户是隐形陷阱，错误信息不直观。
- **修复方向**: 文档/README 中明确说明必须 `node <script>.mjs` 执行；shebang 行本身保留即可（不影响 Windows 上用 node 显式调用）。⚠️ 属于"用户操作习惯"问题，不修代码也可通过文档解决。

---

### 6. `settings.py` 的 `TWISTED_REACTOR` 在 Windows Python 3.8+ 需要先设置 Event Loop Policy

- **文件**: `crawler/settings.py:32`
- **当前代码**:
  ```python
  TWISTED_REACTOR = "twisted.internet.asyncioreactor.AsyncioSelectorReactor"
  ```
- **Windows 上会怎么坏**: Twisted 的 `AsyncioSelectorReactor` 类文档明确指出：「Applications that use AsyncioSelectorReactor on Windows with Python 3.8+ must call `asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())` before instantiating the reactor.」Python 3.8+ 在 Windows 上默认使用 `WindowsProactorEventLoop`，与 `AsyncioSelectorReactor` 不兼容。

  **缓解因素（已确认）**: Scrapy 的 `utils/reactor.py:102-105` 中已自动检测并设置 `WindowsSelectorEventLoopPolicy`。同时 scrapy-playwright 在 Windows 上自动用 `_ThreadedLoopAdapter` 跑 `WindowsProactorEventLoop`（独立线程）。因此 **Scrapy + scrapy-playwright 组合在 Windows 上理论可用**，但依赖 Scrapy 内部的隐式 patch，脆弱——如果用户绕过 Scrapy 直接用 Twisted reactor，就会炸。
- **修复方向**: 在 `crawl.py` 的 `_run_scrapy()` 中加显式注释说明依赖 Scrapy 的 reactor patch；或直接在入口加一个 `sys.platform == 'win32'` 的 guard 提前 `set_event_loop_policy`。

---

### 7. HANDOFF.md 文档中 `sed -n` 命令和路径示例全部 Unix-only

- **文件**: `HANDOFF.md:34-44`
- **当前代码**:
  ```bash
  sed -n '1,55p' /Volumes/WD_BLACK/myagent/new_ohsql/ohsql-plugin/plugins/perf-kp-sql/data/cases/CASES.md
  ```
  ```bash
  node distill-v2/scripts/build-runtime-cases-from-md.mjs \
    --runtime /Volumes/WD_BLACK/myagent/new_ohsql/ohsql-plugin/plugins/perf-kp-sql
  ```
- **Windows 上会怎么坏**: `sed` 在 Windows 原生不可用（需要 Git Bash、WSL 或 GnuWin32）；`/Volumes/WD_BLACK/...` 路径在 Windows 无效。文档主要是人工操作指南，但 Windows 接手者会直接卡住。
- **修复方向**: 文档中标注"以下命令在 macOS/Linux 执行"，或加 Windows 等价命令（`Get-Content` + 路径替换）。这是文档问题，不影响实际代码执行。

---

### 8. `fetch-and-prepare.mjs` 和 `probe-titles.mjs` 的 User-Agent 写死 macOS 字符串

- **文件**:
  - `distill-v2/scripts/fetch-and-prepare.mjs:57`
  - `distill-v2/scripts/probe-titles.mjs:21`
- **当前代码**:
  ```js
  const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 ...';
  ```
- **Windows 上会怎么坏**: 不会直接崩溃，但如果目标网站有 bot 检测或平台差异化内容（某些中国站对 Mac/Windows UA 返回不同内容），会影响抓取结果正确性。这是**语义问题**，不是崩溃问题。⚠️ 风险等级偏低，但和 curl 依赖同属这两个脚本，一并修更干净。
- **修复方向**: 换成中性 UA 或用变量管理，与平台无关。

---

## P2 小坑（共 2 处）

### 9. `store.py` 中文件路径不截断 slug，可能接近 Windows MAX_PATH 260 限制

- **文件**: `crawler/pipelines/store.py:82-83`
- **当前代码**:
  ```python
  slug = slugify(doc["title"]) or "untitled"
  return Path(doc["source_name"]) / yyyymm / f"{slug}-{url_hash}.md"
  ```
- **Windows 上会怎么坏**: `python-slugify` 默认**不截断**输出。长标题（如百字中文技术文章标题）可产生 100+ 字符的 slug。典型路径结构：`corpus/huaweicloud-kunpeng-docs/2024-08/<slug>-abc123.md`。加上工作目录（如 `C:\Users\david\projects\crawler\`）总长可能超过 260 字符，触发 Windows API `ERROR_PATH_NOT_FOUND`（`ENAMETOOLONG` 等价）。Python 3.6+ 在 Windows 上开启长路径支持（需注册表或 `longPathsEnabled` 组策略）可绕过，但默认不开启。
- **修复方向**: `slugify(doc["title"], max_length=80)` 限制 slug 长度；或在项目文档中注明需要在 Windows 开启长路径支持。⚠️ 未确认，需 Windows 实测（取决于实际 title 长度分布和工作目录深度）。

---

### 10. `METHODOLOGY.md` 中 `--dry-run` 输出路径文档描述写的是 `/tmp/`

- **文件**: `METHODOLOGY.md` 中多处以及 `HANDOFF.md:227`
- **当前内容**:
  ```bash
  # 输出到 /tmp/build-runtime-out/
  node distill-v2/scripts/build-runtime-cases-from-md.mjs --dry-run
  ```
- **Windows 上会怎么坏**: 文档描述与代码实际行为一致（代码也硬编码 `/tmp/`，即 P0-2），但这里的 P2 是指即使修了代码的 P0 问题，文档也要同步更新，否则 Windows 用户在文档里看到 `/tmp/` 目录作为预期输出位置，会困惑找不到文件。
- **修复方向**: 修 P0-2 的同时同步更新文档，写明实际输出到系统临时目录（`%TEMP%\build-runtime-out` 或 `$env:TEMP\build-runtime-out`）。

---

## 整体建议

### 必须先修（阻断级）

按照修复成本从小到大排序：

1. **P0-2**: `build-runtime-cases-from-md.mjs:48` 的 `/tmp/` → `os.tmpdir()`。改一行，零风险。
2. **P0-3**: `reverse-map-helper.mjs:29` 去掉 `/Volumes/` 默认值，改为必填或提示必须传参。改一行。
3. **P0-1**: `build-runtime-cases-from-md.mjs:45` 去掉 `/Volumes/` 默认值，同上。
4. **P0-4**: `probe-titles.mjs` + `fetch-and-prepare.mjs` 的 curl 调用改为 Node.js `fetch()`（`node:https` 或 Node 18+ 内置 fetch）。工作量略大，但这两个是 PoC 工具脚本，Windows 优先级较低。

### P1 遇到再修

5. **P1-6**: Twisted reactor 问题理论上已被 Scrapy 处理，实测如果 `crawl` 命令在 Windows 能正常启动就跳过；否则在 `crawl.py` 入口显式加 `asyncio.set_event_loop_policy`。
6. **P1-5/7/8**: shebang、文档、UA 字符串——文档更新即可，不阻塞运行。

### Windows 跑一次 mongo 示范 run 的前提

1. Python 3.11+ for Windows 安装（需勾选"Add to PATH"）
2. `pip install -e .[dev]`（注意 `w3lib` 等依赖在 Windows 上有二进制包）
3. `playwright install chromium`（playwright 有原生 Windows 包）
4. Node.js 18+ for Windows（用于蒸馏脚本）
5. 修 P0 项（尤其是 `/tmp/` 和 `/Volumes/` 硬编码）
6. Windows 长路径支持建议开启：`HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled = 1`

### 是否值得完整跨平台

**爬虫核心（Python 部分）**: 整体写得相当规范，全用 `pathlib.Path`、全加 `encoding="utf-8"`、无 Unix-only 模块，跨平台风险小。主要障碍是 Scrapy/Playwright/Twisted 的 Windows event loop 兼容性——已被 Scrapy 和 scrapy-playwright 内部处理，理论可用，但社区实际在 Linux/macOS 测试为主。

**蒸馏脚本（Node.js .mjs 部分）**: 硬编码路径问题集中在这里，修 P0 后基本可用。

**结论**: Python 爬虫部分跨平台代价低，值得修；蒸馏脚本的 curl 依赖是最大的不确定因素，如果团队长期只在 macOS/Linux 跑，可以接受只在那两个平台上维护蒸馏脚本。
