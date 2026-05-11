# ohsql-plugin

[![validate](https://github.com/zlxtqbdgdgd/ohsql-plugin/actions/workflows/validate.yml/badge.svg)](https://github.com/zlxtqbdgdgd/ohsql-plugin/actions/workflows/validate.yml)

> English · [中文](README.zh-CN.md)

Official plugin marketplace for [OpenHarness-SQL](https://github.com/zlxtqbdgdgd/OpenHarness-SQL) — performance diagnosis, CPU flamegraphs, and database tooling.

All skills follow the [Anthropic Agent Skills open standard](https://github.com/anthropics/skills), so the same skill source runs natively on Claude Code, OpenAI Codex CLI, and ohsql ≥ 0.38.0 — no per-platform tool mapping or build-time conversion required.

## Plugins

| Plugin | Version | Hosts | What it does |
|---|---|---|---|
| [`cpu-flamegraph`](./plugins/cpu-flamegraph/) | 0.4.0 | Claude Code · Codex CLI · ohsql · any agent with shell + read/write | Remote `perf` over SSH → on-CPU / off-CPU flamegraph SVG → top-N hotspot extraction. Pure local `ssh` + Perl `flamegraph.pl`, zero kernel-tool dependency. |
| [`perf-kp-sql`](./plugins/perf-kp-sql/) | 0.54.0 | Claude Code · Codex CLI · ohsql · any standard-compliant agent | Kunpeng ARM64 + MongoDB joint perf diagnosis. SSH-based collection → 7-phase LLM-orchestrated pipeline against 202-case markdown case library → NotebookLM authoritative refresh → impact-ranked markdown report. |

---

## Install

### OpenHarness-SQL (ohsql ≥ 0.38.0)

```text
/plugin marketplace add zlxtqbdgdgd/ohsql-plugin
/plugin install cpu-flamegraph                  # ready immediately
/plugin install perf-kp-sql                     # auto-installs cpu-flamegraph dep
/perf-kp-sql-setup                              # verify runtime + register NotebookLM
```

After `perf-kp-sql-setup` completes:

```text
/perf-kp-sql host=10.0.0.1 user=root password=xxx engine=mongo
```

### Claude Code

```text
/plugin marketplace add zlxtqbdgdgd/ohsql-plugin
/plugin install cpu-flamegraph
/plugin install perf-kp-sql
/perf-kp-sql-setup                              # verify runtime + register NotebookLM
```

### OpenAI Codex CLI

```text
codex plugin marketplace add zlxtqbdgdgd/ohsql-plugin
# Codex auto-discovers skills from the plugin's skills/ directory
# For perf-kp-sql, also run: /perf-kp-sql-setup (verifies runtime + registers NotebookLM)
```

---

## Usage

The two plugins follow different execution models — `cpu-flamegraph` is a single-shot programmatic capture-and-interpret tool, while `perf-kp-sql` is an LLM-orchestrated 7-phase pipeline. Each subsection covers invocation, behavior, and a sample terminal session (illustrative data).

### `cpu-flamegraph`

Three invocation methods are supported:

```text
# slash + full arguments
/cpu-flamegraph host=test.host user=root process=mongod duration=10 type=oncpu

# slash without arguments — the skill interactively prompts for missing parameters
/cpu-flamegraph

# natural language — agent auto-loads the skill on keywords like "high CPU / latency spike / flamegraph / perf record"
> show me the CPU hotspots in mongod on test.host
```

Single-shot capture-and-interpret flow:

- SSH to the remote host and run `perf record` for `<duration>` seconds
- `perf script` extracts call stacks → fold locally → `flamegraph.pl` renders SVG
- Parse top-N hotspot functions; attach function-level interpretation when a KB seed matches
- Render the top-N table in the terminal and print the `scp` command for the remote SVG

The SVG stays on the remote at `/tmp/cpu-flamegraph_<ts>/`; pull it with `scp` manually.

Sample terminal output:

```text
> /cpu-flamegraph host=10.0.0.1 user=root process=mongod duration=3 type=oncpu

Hotspot     : WiredTigerRecordStore::_insertRecords 24.0% (module mongod)
Sampling    : CPU time 12.3 ms ; scope mongod (pid=911593)
Implication : Hotspot is inside the database engine; correlate with slow query, lock, and cache metrics next

═══ Sampling metadata ════════════════════════════════════════════════
┌────┬──────────────────────────────────────────┬─────────┬─────────┐
│ #  │ Function                                 │ Module  │ Percent │
├────┼──────────────────────────────────────────┼─────────┼─────────┤
│ 1  │ WiredTigerRecordStore::_insertRecords    │ mongod  │ 24.0%   │
│ 2  │ __wt_btree_open                          │ mongod  │ 12.6%   │
│ 3  │ memcpy                                   │ libc    │  8.4%   │
│ 4  │ ...                                      │ ...     │  ...    │
└────┴──────────────────────────────────────────┴─────────┴─────────┘

Artifacts (left on remote, fetch manually):
  scp root@10.0.0.1:/tmp/cpu-flamegraph_20260510-143022/flamegraph.svg .
  scp root@10.0.0.1:/tmp/cpu-flamegraph_20260510-143022/mongod .
```

### `perf-kp-sql`

Three invocation methods are supported:

```text
# slash + full arguments
/perf-kp-sql host=10.0.0.1 user=root privateKeyPath=~/.ssh/id_ed25519 engine=mongo

# slash without arguments — enters Phase 0 history menu and interactively collects credentials
/perf-kp-sql

# natural language — agent auto-loads the skill on keywords like "slow database / high CPU / latency spike / mongo perf / Kunpeng performance"
> mongod on a Kunpeng box has been at 100% CPU since 2 AM, please diagnose
```

LLM-orchestrated 7-phase pipeline:

- Env probe (Phase 0) — one SSH session collects OS / DB / hardware / deployment topology
- Symptom intake (Phase 1) — gather the user's description of the issue
- Symptom routing (Phase 2) — LLM matches against `cases/INDEX.md` and narrows to a candidate set
- Metric collection (Phase 3) — issue per-case `collection_method_quote` commands to gather metrics
- Multi-source diagnosis (Phase 4) — threshold judgment from the case library + NotebookLM online KB lookup
- Report generation (Phase 5) — 8-column diagnosis table + remediation steps, written to disk
- Follow-up conversation (Phase 6, optional) — answer further questions grounded in the collected data

`cpu-flamegraph` is invoked automatically when a flamegraph is needed.

Sample terminal output:

```text
> /perf-kp-sql host=10.0.0.1 user=root engine=mongo

━ ohsql perf-kp-sql · perf diagnosis ━
5-step pipeline: 1.env probe / 2.case match /
                3.metric collection / 4.multi-source diagnosis / 5.report

[1. Env probe : OS / DB version / hardware]
[Context]
  OS     : Linux 4.19 aarch64 (Kunpeng 920)
  Mongo  : 6.0.5 (replSet primary, 96C / 256G / NVMe)
  sysctl : vm.swappiness=10 / transparent_hugepage=[always]
  ulimit : nofile=65535

> CPU has been at 100% on mongod since 2 AM

[2. Case match : 202-case library index]
  5 candidates → narrowed to 3 :
    • Flame-007 $where JavaScript interpretation
    • DF-042    WT cache eviction pressure
    • DF-001    slow query latency distribution

[3. Metric collection]
  ✔ OS layer : CPU / memory / disk / network
  ✔ MongoDB layer : connection pool / slow query / locks / WiredTiger
  ✔ mongod CPU flamegraph (perf 3s)

[4. Multi-source diagnosis : case library + NotebookLM online KB]
  ✔ Threshold judgment from case library (3 hits)
  ✔ NotebookLM KB query (2/2)
  ✔ Final assessment

[5. Report]

## Diagnosis
┌────┬───────────────────────────┬──────┬─────────────────┬───────────┬────────────────────────┬─────────┬─────────┐
│ #  │ Root cause                │ Sev  │ Evidence        │ Case      │ Action                 │ Conf    │ Ref     │
├────┼───────────────────────────┼──────┼─────────────────┼───────────┼────────────────────────┼─────────┼─────────┤
│ 1  │ $where JS burns CPU       │ HIGH │ flame self 47%  │ Flame-007 │ use $expr/$function    │ high    │ [ref 1] │
│ 2  │ WT cache pressure         │ HIGH │ dirty 18% > 5%  │ DF-042    │ tune eviction_*_target │ med-hi  │ [ref 2] │
│ 3  │ COLLSCAN-heavy queries    │ MED  │ COLLSCAN 23%    │ DF-001    │ add index / batch      │ medium  │ [ref 3] │
└────┴───────────────────────────┴──────┴─────────────────┴───────────┴────────────────────────┴─────────┴─────────┘

Report : ~/.perf-kp-sql/runs/20260510-143022/report.md
```

The main `## Diagnosis` table is followed by `## Summary` / `## Auxiliary info · Field observations` / `## References` sections (omitted from this sample for brevity). Each `[ref N]` link in the table is expanded under `## References` to a concrete URL — every URL comes from a case library `source_url` field or a NotebookLM `references` payload, never inferred from the model's own knowledge.

---

## Output artifacts

**`cpu-flamegraph`** (standalone)

- Remote `/tmp/cpu-flamegraph_<YYYYMMDD-HHMMSS>/flamegraph.svg` — SVG flamegraph, not auto-downloaded; the skill prints the `scp` command for manual retrieval
- The same directory keeps the raw `perf script` output, named after the captured process
- The top-N hotspot table is rendered in the chat channel only, never written to disk

**`perf-kp-sql`** (single-directory archive at `~/.perf-kp-sql/runs/<YYYYMMDD-HHMMSS>/`)

| File | Contents |
|---|---|
| `report.md` | Main report (impact-ordered diagnosis table + remediation) |
| `env.txt` | Raw output of the Phase 0 environment probe |
| `collect-os.txt` | OS-layer collection (vmstat / iostat / etc.) |
| `collect-mongo.txt` | MongoDB-layer collection (serverStatus / etc.) |
| `flame.svg` | Flamegraph (present only when this run captured one) |

Two more configuration files are reused across runs: `~/.perf-kp-sql/notebooklm.json` (NLM configuration) and `~/.perf-kp-sql/hosts.json` (SSH/DB connection history, mode 0600 — credentials are written only when the user explicitly opts in).

---

## Architecture

The repository is a `marketplace.json` index plus two self-contained plugins. Directory layout:

```text
ohsql-plugin/
├── marketplace.json                       # installable plugin index
└── plugins/
    ├── cpu-flamegraph/
    │   ├── .claude-plugin/plugin.json     # version / metadata
    │   ├── skills/cpu-flamegraph/
    │   │   ├── SKILL.md                   # prose intent guiding the LLM
    │   │   └── scripts/capture.mjs        # SSH + perf + flamegraph.pl → SVG
    │   └── data/kb-seeds/                 # function-level hotspot interpretation dictionary
    └── perf-kp-sql/
        ├── .claude-plugin/plugin.json     # version + depends on cpu-flamegraph ^0.4.0
        ├── skills/
        │   ├── perf-kp-sql/SKILL.md       # main diagnosis pipeline (7 phases)
        │   └── perf-kp-sql-setup/SKILL.md # first-install runtime check + NLM registration
        ├── scripts/
        │   ├── ssh.mjs                    # SSH_ASKPASS wrapper + ControlMaster persistent connection
        │   ├── notebooklm.mjs             # calls the nlm CLI to query Google NotebookLM
        │   ├── capture-flamegraph.mjs     # invokes the cpu-flamegraph sub-skill
        │   ├── format-chat.mjs            # box-drawing terminal report renderer
        │   └── history.mjs                # read/write for ~/.perf-kp-sql/hosts.json
        └── data/
            ├── cases/{INDEX,CASES}.md     # 109 diagnostic cases (diagnostic-flow 96 + flame 13)
            └── best-practice/{INDEX,CASES}.md  # 93 best-practice audit cases
```

---

## License

MIT
