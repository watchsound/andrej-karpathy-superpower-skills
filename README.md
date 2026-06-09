# Andrej Karpathy × Superpowers Skills

A personal fork of [obra/superpowers](https://github.com/obra/superpowers) that bakes Andrej Karpathy's anti-LLM-slop principles into each skill, adds a runtime ubiquitous-language ritual to prevent semantic drift, and introduces a small number of new skills for failure modes that show up in long-running agent work.

> **This is a personal fork**, not affiliated with the upstream maintainers. Changes here may diverge from upstream design decisions and have not been adversarially eval'd to the upstream's bar. For the canonical project, see [obra/superpowers](https://github.com/obra/superpowers) and [README_ORIGINAL.md](./README_ORIGINAL.md).

## Motivation

Superpowers gives agents disciplined workflows (TDD, brainstorming, systematic debugging, plan-driven execution). What it doesn't yet encode is the *moment-to-moment* failure modes [Karpathy described in January 2026](https://x.com/karpathy/status/2015883857489522876):

> "The models make wrong assumptions on your behalf and just run along with them without checking. They don't manage their confusion, don't seek clarifications, don't surface inconsistencies, don't present tradeoffs, don't push back when they should. They really like to overcomplicate code and APIs, bloat abstractions..."

[Forrest Chang's distillation](https://github.com/forrestchang/andrej-karpathy-skills) of those observations into four rules — *think before coding, simplicity first, surgical changes, goal-driven execution* — works as a CLAUDE.md preamble. But a preamble competes with skill content for attention budget, and it doesn't fire at the moment a specific skill is running.

**This fork bakes the four rules into each skill's body**, so the discipline is invoked exactly when the skill fires. It also adds a small set of rules targeting agent-loop failure modes (token budgets, deterministic-code boundary, test quality, checkpoint discipline) and a runtime-built glossary mechanism adapted from [mattpocock/skills](https://github.com/mattpocock/skills) to prevent semantic drift across long sessions.

A second, independent failure mode motivated this fork: **bottom-up TDD can produce 100 perfectly-tested units that compose into a bad architecture.** The units pass, the seams are wrong, and no red test tells you. Karpathy's rules address how you write code in the moment; they say nothing about whether you're building the right structure. This fork harnesses TDD within an Architecture-Driven Design (ADD) pipeline so architecture remains the boss and TDD is the worker. The discipline is distributed across the three skills that own each stage: `brainstorming` requires a **Walking Skeleton** for greenfield systems — an end-to-end thin slice with no business logic that validates every architectural seam before any feature is designed; `writing-plans` requires **Contract-First** interface definition before any TDD cycle runs, so the shape and boundaries are committed before the worker starts; and `test-driven-development` imposes **outside-in ordering** — the next failing test always targets the highest-uncovered architectural boundary, not the lowest leaf utility — without London-school heavy mocking.

## What's Added

### Seven new skills

- **`karpathy-guidelines`** — verbatim vendor of forrestchang's 4-rule CLAUDE.md (MIT). Loads on demand so the full rule text is available to any skill that cross-references it.
- **`prefer-deterministic-code`** — refuses to wrap an LLM call around a question with a deterministic answer (routing, retries, status codes, validation, type checks). Reserves LLM calls for unstructured language work only.
- **`token-budget-discipline`** — explicit per-task and per-session budgets with checkpoint-and-restart discipline, to bound agent loops that would otherwise spend themselves into a 50K-token context dump.
- **`surfacing-assumptions`** — front-loads the *Assumptions Made* discipline. Gates Edit/Write/mutating Bash until each assumption is discharged by cited evidence (file:line, command output, grep hit, or explicit user confirmation). Targets the "wrong assumptions, run along with them" failure mode at its source, before code is shaped.
- **`verifying-assumptions`** — evidence-based post-hoc verification of the `Assumptions Made` block. Produces per-assumption verdicts (validated / refuted / unverifiable) with cited evidence. Bounded escalation: one same-procedure redo, then one higher-context **Reframe Pass** (which must inject *different signal* — re-anchored intent, expanded read set, fresh-context subagent, or restated question), then escalate to the user.
- **`bootstrap-project-context`** — generates the three project-context files (`CONTEXT.md` glossary / `state_machines.md` lifecycles / `data_flow.md` data movement) once per project. Two modes: greenfield composes from the design conversation; brownfield mines existing source. **Uses [CodeGraph](https://github.com/colbymchenry/codegraph) as the structural-extraction backend when installed and indexed** (roughly 5–10× cheaper than walking source with Explore subagents, because CodeGraph already maintains a live SQLite-backed graph of nodes + edges with framework-aware resolvers); falls back to Explore subagents otherwise. HARD-GATE requires user review before any file is written to disk. Uses brainstorming's canonical `CONTEXT.md` format (no parallel format invented); brownfield traceability preserved via HTML-comment annotations.
- **`maintaining-project-context`** — enforces lockstep updates between code edits and the three context files. Classifies each edit against three categories (domain concept → `CONTEXT.md`; state transition → `state_machines.md`; data movement → `data_flow.md`) and gates task completion on whether the relevant file was updated *in the same change*. Multi-context aware (updates the bounded-context `CONTEXT.md`, not the root). Untyped projects (loose Python / JS-without-TS / shell) get a lower-bar classification with active exemption rather than silent skip — because the type system is not doing the filtering work for them. Graceful fallback when `bootstrap-project-context` is not installed: escalates to the user rather than silently bypassing the gate.

### Karpathy Reinforcement across existing skills (13)

Each relevant existing skill gained a small `## Karpathy Reinforcement` block listing only the rules that materially strengthen its behavior. `using-superpowers` gained the full 4-rule baseline as a permanent lens for every session. `using-git-worktrees` (purely mechanical) was deliberately left untouched.

### Ubiquitous Language in `brainstorming`

A new `## Ubiquitous Language` subsection in the `brainstorming` skill:

- Reads `CONTEXT.md` (or `CONTEXT-MAP.md` for multi-context repos) at session start.
- Disambiguates fuzzy or overloaded terms inline ("you're saying 'order' — trading order, purchase order, or work order?").
- Refuses technical jargon (`Manager`, `Processor`, `Helper`) when a domain term exists.
- Writes resolved terms back to the glossary as they emerge, not batched.

Format reference adapted from `mattpocock/skills/grill-with-docs/CONTEXT-FORMAT.md` (MIT). Three downstream skills — `executing-plans`, `receiving-code-review`, `systematic-debugging` — gained one-line cross-references so the vocabulary doesn't get bypassed downstream.

### Inline strengtheners

- **Test Quality Bar** in `test-driven-development` — every test must encode *why* the behavior matters, not just *that* the function returned something. A green test that would still pass if the function body were replaced with `return <constant>` is worthless.
- **Checkpoint Discipline** in `executing-plans` — after each plan step, write a 4-line summary (done / verified / remaining) before continuing. Never start step N+1 from a state you cannot recount to yourself.

### Architecture-Driven TDD harness (3 skills extended)

A separate failure mode from semantic drift: bottom-up TDD can produce 100 perfectly-tested units that compose into a bad architecture. This fork harnesses TDD within an Architecture-Driven Design pipeline — architecture is the boss, TDD is the worker. The discipline is spread across the three skills that own each stage, not stuffed into TDD alone.

- **`brainstorming` gained a Walking Skeleton subsection** — for greenfield work, the first design deliverable is an end-to-end thin slice with zero business logic, proving every layer is wired before any feature is designed.
- **`writing-plans` gained an Architecture Contracts First section** — for each new module or boundary, Task 1 defines the interface (type/abstract/schema), Task 2 writes the boundary test, Task 3+ implements under TDD.
- **`test-driven-development` gained four sections** after Test Quality Bar:
  - *Where to Start the Cycle* — outside-in ordering (target the architectural boundary, not the leaf utility) **without** London-school heavy mocking.
  - *Behavior, Not Implementation* — forbid call-count spies and private-field assertions; allow side-effect contracts when the side effect *is* the behavior; mutation thinking as the green-test verifier.
  - *Test Organization & Traceability* — colocate test files with sources, name tests using `CONTEXT.md` canonical terms, tag by bounded context, run related-tests during iteration (`jest --findRelatedTests`, `pytest -k`, `nx affected:test`) and the full suite at the completion gate.
  - *Layered Tests* — domain/unit (fast, most of the suite) vs integration (slow, thin smoke layer); needing 5+ mocks signals a design problem, not a test problem.

### `CLAUDE_APPEND.md` (personal engineering standard)

A short add-on for your project-level or user-global `CLAUDE.md` that introduces a **mandatory response format** for any code-modifying response:

- `Discovered Issues` — bugs and risks noticed in adjacent code, listed (not fixed) so they can be triaged.
- `Assumptions Made` — every assumption taken to proceed, with `(critical)` markers on the load-bearing ones.

This turns invisible discipline (the four Karpathy rules) into a visible artifact at the end of every response. The new `surfacing-assumptions` and `verifying-assumptions` skills are the operational mechanism that makes those two sections accurate — at the front-end (before code is written) and at the back-end (when verifying a written block). The `bootstrap-project-context` and `maintaining-project-context` skills extend the same discipline to the project level: they establish and maintain the bigger-picture artifact (glossary + lifecycles + flows) that prevents the agent from getting trapped in narrow reasoning paths during long sessions.

## Installation

### Standard install (Claude Code with `/plugin` available)

```bash
# Add the marketplace
/plugin marketplace add watchsound/andrej-karpathy-superpower-skills

# Install
/plugin install superpowers@superpowers-dev
```

> **Important: if you already have the upstream `obra/superpowers` plugin installed, uninstall it before installing this fork.** Both plugins ship the same skill names. Without uninstalling, every skill auto-triggers twice — once from each plugin — producing spurious double-invocations and confusing behavior. This is the single most common install mistake.

```bash
/plugin uninstall superpowers
```

Then restart Claude Code so the SessionStart hook from this fork fires and `using-superpowers` bootstraps.

### Alternative: junction/symlink install (environments without `/plugin`)

Some Claude Code surfaces (e.g. older VSCode extension builds) don't expose `/plugin`. You can wire skills into the user-global skills directory directly. Skills auto-trigger from their description field even without the SessionStart hook.

PowerShell (Windows, no admin required):

```powershell
$src = "<path-to-this-repo>\skills"
$dst = "$env:USERPROFILE\.claude\skills"
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Get-ChildItem $src -Directory | ForEach-Object {
  New-Item -ItemType Junction -Path (Join-Path $dst $_.Name) -Target $_.FullName
}
```

Bash (macOS/Linux):

```bash
mkdir -p ~/.claude/skills
for d in <path-to-this-repo>/skills/*/; do
  ln -s "$(cd "$d" && pwd)" ~/.claude/skills/$(basename "$d")
done
```

**Idempotent re-sync after `git pull`.** The repo ships [`sync-skills.ps1`](./sync-skills.ps1) (Windows) and [`sync-skills.sh`](./sync-skills.sh) (macOS/Linux) at the root that do the same junction/symlink creation as above, but only for skills that don't already have a link. Run after every `git pull` to pick up new skills as the fork evolves; existing links are left untouched.

```powershell
# Windows
pwsh ./sync-skills.ps1
```

```bash
# macOS / Linux
bash ./sync-skills.sh
```

To revert: delete `~/.claude/skills/` (junctions/symlinks delete cleanly without touching the source). What you lose vs the full plugin install: the SessionStart hook that bootstraps `using-superpowers`. Individual skills still auto-trigger via their description.

## Optional: CodeGraph integration

The `bootstrap-project-context` skill prefers [CodeGraph](https://github.com/colbymchenry/codegraph) (MIT) as its brownfield structural-extraction backend. CodeGraph maintains a local file-watched SQLite-backed graph of nodes (symbols) and edges (calls, imports, references, framework routes) and exposes MCP tools that Claude Code can query directly — much cheaper than walking source with Explore subagents on a large repo. Per [codegraph's own benchmarks](https://github.com/colbymchenry/codegraph#benchmark-results) (7 real-world codebases, 7 languages, Claude Code Opus): **~16% cheaper, ~47% fewer tokens, ~22% faster, ~58% fewer tool calls** averaged across all runs.

**CodeGraph is optional.** The bootstrap skill detects whether it's installed and falls back to Explore subagents when it isn't. Install only if you want the faster brownfield path.

### 1. Install the CLI

**Windows (PowerShell)** — downloads a self-contained bundle (vendored Node runtime, no Node.js prerequisite) into `%LOCALAPPDATA%\codegraph\current\` and adds it to your user PATH:

```powershell
irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
```

**macOS / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

**Alternative** (any platform, requires Node 20+): `npm install -g @colbymchenry/codegraph`. The standalone installer is preferred — no Node dependency and easier upgrades via `codegraph upgrade`.

**Restart your terminal** so the new PATH takes effect. Verify with `codegraph --help`.

### 2. Wire CodeGraph into Claude Code

```bash
codegraph install
```

**This is the load-bearing step.** The CLI alone does NOT connect CodeGraph to Claude Code — `codegraph install` writes the MCP server config (auto-detecting other agents like Cursor / Codex / Gemini / opencode if present) and sets up auto-allow permissions for the MCP tools. **Restart Claude Code** after running so it loads the new MCP server.

### 3. Initialize each project

```bash
cd <your project>
codegraph init -i
```

`-i` builds the initial graph in the same step. This creates `.codegraph/codegraph.db` at the project root. From then on a native file watcher keeps the index fresh automatically — no manual `codegraph sync` needed in normal use.

### How the bootstrap skill picks it up

`bootstrap-project-context` Step 3b.0 checks for `.codegraph/codegraph.db` at the project root and pings the `codegraph_status` MCP tool. When both succeed, it routes to the CodeGraph-aware path (per-file query plans via `codegraph_search` / `codegraph_node` / `codegraph_callers` / `codegraph_callees` / `codegraph_impact`). When either check fails, it falls back to Explore subagents. **No skill configuration is needed** — install CodeGraph once, init per-project, and the skill takes the cheap path automatically.

### Uninstall

```bash
codegraph uninstall    # strip MCP wiring from each configured agent
codegraph uninit       # in a project: remove its .codegraph/ index
```

Then remove the binary. **Windows:** delete `%LOCALAPPDATA%\codegraph` and drop the `...\current\bin` entry from your user PATH. **macOS/Linux:** the installer ships an `--uninstall` flag that handles both the bundle (`~/.codegraph`) and the launcher symlink (`~/.local/bin/codegraph`) in one shot:

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh -s -- --uninstall
```

## Verification

In a fresh session, send:

> "Let's design a small order book for an A-share trading system."

What you should see (validated in eval runs — see [docs/superpowers/evals/acceptance.md](docs/superpowers/evals/acceptance.md)):

- `brainstorming` skill announces and fires — agent does *not* leap to code.
- Agent globs for `CONTEXT.md` at repo root; if absent, offers lazy creation as terms get pinned down.
- Agent disambiguates *within-domain* (matching engine vs broker OMS vs market-data reconstruction vs backtest) before proposing a design.
- One-question-at-a-time clarifying flow with multiple-choice options and a recommendation.
- Because the order book is a greenfield system, the agent offers a **Walking Skeleton** as the first design deliverable — end-to-end happy path, named seams as concrete interfaces, one acceptance test — before any data model or file layout.
- Karpathy rules fire behaviorally (e.g. surfacing critical assumptions in the design itself), though the agent may not cite them by name. That's the current state, not a bug.

If `brainstorming` does not announce at all, the install didn't take. For the standard install: confirm `/plugin list` shows the fork. For the junction install: confirm `~/.claude/skills/brainstorming/SKILL.md` exists and is readable.

**If you also installed CodeGraph** (per the *Optional: CodeGraph integration* section above), verify the MCP server is reachable from Claude Code by sending:

> *"Use codegraph to show me which files are indexed in this project."*

The agent should invoke `codegraph_files` or `codegraph_status` (visible in the tool-call trace) rather than falling back to `Glob` or Explore subagents. If it does fall back, the MCP wiring did not take — run `codegraph install` again and restart Claude Code. The `bootstrap-project-context` skill's CodeGraph-aware brownfield path only activates when this probe succeeds.

For deeper validation across 7 probes covering 5 skills, see the [acceptance eval harness](docs/superpowers/evals/acceptance.md) — it includes the exact probe messages, expected behaviors, and recorded results from validation runs.

## Attribution

- Original **Superpowers** project: [Jesse Vincent](https://blog.fsck.com) and Prime Radiant — [obra/superpowers](https://github.com/obra/superpowers).
- **Karpathy guidelines** distillation: [Forrest Chang](https://github.com/forrestchang/andrej-karpathy-skills).
- **CONTEXT.md format and ritual**: [Matt Pocock](https://github.com/mattpocock/skills).
- Original **Karpathy observations** on LLM coding pitfalls: [@karpathy on X](https://x.com/karpathy/status/2015883857489522876).

All upstream content is MIT-licensed; attribution is preserved in vendored files.

For the full upstream documentation, philosophy section, and per-harness install instructions (Codex CLI, Gemini CLI, OpenCode, Cursor, GitHub Copilot CLI, Factory Droid), see [README_ORIGINAL.md](./README_ORIGINAL.md).

## License

MIT — see [LICENSE](./LICENSE). All vendored content retains its original MIT terms and attribution.
