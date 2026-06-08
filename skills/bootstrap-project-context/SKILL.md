---
name: bootstrap-project-context
description: Use ONCE per project to generate the three project-context files (CONTEXT.md, state_machines.md, data_flow.md) that the maintenance skills will keep current. Two modes — greenfield (compose from the brainstorming / Walking-Skeleton design conversation) and brownfield (mines existing source via the CodeGraph index when available, Explore subagents as fallback). Skip if all three files already exist. Files become load-bearing after this skill runs; the maintenance-discipline skills enforce updates against them.
---

# Bootstrap Project Context

## Karpathy Reinforcement

Rule 1 — *Think Before Coding* — at the project scale. The three project-context files (`CONTEXT.md`, `state_machines.md`, `data_flow.md`) are the *bigger-picture artifact* that prevents the agent from getting trapped in narrow reasoning paths during long sessions. They must exist before any maintenance discipline can keep them current. This skill is the one-shot prerequisite.

## The Iron Law

**NO LOAD-BEARING WORK WITHOUT THE THREE CONTEXT FILES.**

If a project uses the context-discipline skills (`maintaining-project-context`, and the Reframe Pass in `verifying-assumptions`), the three files must exist first. Without them, the maintenance skill has nothing to enforce, and the Reframe Pass has no extra read targets to inject *different signal* into stuck verification.

**"Load-bearing work"** = anything beyond exploration: writing new features, refactoring, building plans, brainstorming designs that will be implemented. Reading the codebase to understand it does NOT require the files. As soon as the agent is about to *change* the system, the files must exist.

## The Bootstrap Procedure

### Step 1 — Detect current state

Check for the three files at repo root (default location). If your project already uses a `docs/` or similar convention, check there too.

**Multi-context layout.** Per the canonical CONTEXT format ([`skills/brainstorming/references/context-format.md`](../brainstorming/references/context-format.md)), a project with multiple bounded contexts may have a `CONTEXT-MAP.md` at the repo root and a per-context `CONTEXT.md` under each bounded-context directory. Check for both layouts; treat the multi-context layout's `CONTEXT-MAP.md` + per-context `CONTEXT.md`s as the equivalent of a single root `CONTEXT.md` for the purposes of the state table below.

| State | Action |
|---|---|
| All three exist (or multi-context equivalent for vocab) | Exit. Bootstrap done; nothing to do. |
| Some exist | Partial bootstrap — generate only the missing files |
| None exist | Full bootstrap. Continue to Step 2. |

### Step 2 — Choose mode (greenfield vs brownfield)

Detection signals (any one is sufficient):

- **Greenfield**: repo has fewer than ~10 non-config source files, OR a recent `brainstorming` Walking Skeleton sits in the current session, OR `git log --oneline | wc -l` is small (< 20 commits), OR there is no business logic on disk yet
- **Brownfield**: established codebase with meaningful business logic already implemented

If the signals are mixed or unclear, **ask your human partner once**: *"Is this a new project we're designing, or are we mining an existing codebase to back-fill its context files?"* One question; do not guess. Mis-classification is more expensive than the question.

### Step 3a — Greenfield mode

Compose the three files from the design conversation that is already happening (`brainstorming` and/or `writing-plans` output):

- **`CONTEXT.md`** — every term that came up during brainstorming / Walking-Skeleton design that has a project-specific meaning. Quote disambiguations directly from the conversation. If `brainstorming` already wrote a `CONTEXT.md` for ubiquitous-language purposes, *extend* it (do not duplicate) — this skill subsumes the ubiquitous-language file.
- **`state_machines.md`** — every entity lifecycle the design explicitly named (e.g., Order: draft → submitted → filled → settled). If none surfaced, write a one-line placeholder: *"No entity lifecycles defined yet — populate when first state-bearing entity is designed."* Do NOT invent states the design did not specify.
- **`data_flow.md`** — every cross-boundary data movement the Walking Skeleton named (e.g., "FIX gateway → matching engine → blotter"). If none surfaced, placeholder. Do NOT invent flows.

After composing, present the three files to your human partner for review **BEFORE** writing them to disk. They are about to become load-bearing artifacts that every future session reads — wrong content is worse than missing content.

### Step 3b — Brownfield mode

Brownfield mode mines an existing codebase to back-fill the three files. It has two backends: **CodeGraph** (preferred when available — dramatically cheaper for the structural-extraction phase) and **Explore subagents** (fallback when CodeGraph is not present). The domain-semantic synthesis step is identical in both paths — only the structural extraction differs.

#### Step 3b.0 — Detect whether CodeGraph is available

CodeGraph (`@colbymchenry/codegraph`, MIT — local-first code-intelligence index) pre-extracts the structural graph this skill needs. Querying it is roughly 5–10× cheaper than asking Explore subagents to walk the source from scratch, because the structural extraction is already done and continuously kept fresh by a file watcher.

Detection (run both checks):

1. `.codegraph/codegraph.db` exists at project root → CodeGraph is indexed for this project
2. `codegraph_status` MCP tool responds → CodeGraph is reachable

| Result | Branch |
|---|---|
| Both true | Step 3b.1 — CodeGraph-aware path |
| Reachable but not yet indexed for this project | Offer `codegraph init` to your human partner, wait for the first scan, then Step 3b.1 |
| Either check fails (not installed, MCP not reachable, persistent failure) | Step 3b.2 — Explore-subagent path |

Do NOT install CodeGraph unilaterally. If it is not present, fall back to Explore subagents. CodeGraph is an *optimization*, not a *dependency* — this skill must work without it.

#### Step 3b.1 — CodeGraph-aware path (preferred when available)

CodeGraph supplies the structural extraction; you supply the domain-semantic synthesis. Per-file query plans:

**For `CONTEXT.md` (glossary):**

1. `codegraph_search(filter: { is_exported: true, kind: [class, interface, type, enum, function] })` — enumerate domain-y exported symbols
2. For each candidate: `codegraph_node(id)` → name, qualified_name, docstring, signature, visibility
3. Filter out generic-pattern names (`Helper`, `Manager`, `Processor`, `Util`, `Service[Impl]`, etc.) — these are infrastructure scaffolding, not domain language
4. For each remaining symbol: compose a one-sentence definition + `_Avoid_` variants per the canonical CONTEXT format. Flag `<!-- needs-confirmation: <reason> -->` when meaning had to be inferred from the name alone
5. Append `<!-- source: <file:line> -->` from the node's location data

**For `state_machines.md` (lifecycles):**

1. `codegraph_search(name_pattern: "*Status|*State|*Phase|*Kind", kind: [enum, type])` — find state-bearing types
2. For each: `codegraph_callers(id)` to identify code paths that read the field; `codegraph_callees(id)` on mutation functions to trace what happens after a state assignment
3. **Read the actual mutation code paths CodeGraph surfaced** — this is where graph data ends and procedural understanding begins. The graph tells you *which* fields are state and *who* mutates them; you must read the code to reconstruct *what transitions exist* and *what guards them*.
4. Compose state-machine entries per the format in the "Output format" section below; flag inferred guards with `<!-- needs-confirmation -->`

**For `data_flow.md` (data movement):**

This is where CodeGraph offers the largest leverage — its 14 framework resolvers (Django, FastAPI, Express, NestJS, Laravel, Rails, Gin, Spring, etc.) already synthesize route / handler / consumer edges as first-class nodes.

1. `codegraph_search(kind: route)` — all HTTP endpoints, GraphQL resolvers, message consumers, CLI entry points that CodeGraph recognized
2. For each entry point: `codegraph_callees(id, depth: 5)` → reach the data sinks (DB writes, file IO, message emits, response writes)
3. `codegraph_impact(id)` → transitive radius for cross-component flows
4. For each entry point, compose one flow entry: source → transformations → sink + shape at each step
5. Cross-language bridges (Swift↔ObjC, React Native legacy/Fabric, Expo Modules) are already marked `provenance: heuristic` in CodeGraph — surface them with `<!-- needs-confirmation -->` since they were inferred, not read directly

**Coverage gap detection.** If `codegraph_status` reports a low edge count for a project that visibly has many files, or if your queries return few routes for a project that obviously has HTTP endpoints, CodeGraph may have under-indexed (custom framework, embedded DSL, in-house messaging library, generated code). In that case, **supplement** the CodeGraph queries with targeted Explore-subagent passes for the under-covered area — do not silently accept incomplete data.

#### Step 3b.2 — Explore-subagent path (fallback when CodeGraph is unavailable)

Launch `Explore` subagents (parallel if the codebase is large — use `dispatching-parallel-agents`) to mine each file from source:

- **`CONTEXT.md`** — walk exported types / classes / interfaces / functions with domain-y names. For each, extract the most likely user-facing meaning from docstrings, type annotations, and call sites. Flag with `[needs-confirmation]` any term whose meaning had to be **inferred** rather than read directly.
- **`state_machines.md`** — for each entity that has a state-like field (`status`, `state`, `phase`, `step`, `kind`), enumerate observed values and find the code paths that mutate them. Reconstruct transitions and guards. Flag inferred guards with `[needs-confirmation]`.
- **`data_flow.md`** — trace inputs (HTTP endpoints, message consumers, file readers, CLI args) → transformations → outputs (responses, emits, file writers). For **typed** projects, the type system gives the boundary shapes for free. For **untyped** projects (loose Python, JS without TS, shell pipelines), follow function calls and record the inferred shape at each boundary, flagged. Untyped projects need this file MORE than typed projects, because the type system is not doing the work for you.

#### After Step 3b.1 or 3b.2

Compose the three files from the data gathered. Present to your human partner with all `[needs-confirmation]` items explicitly listed BEFORE writing to disk.

### Step 4 — User review gate

Present each file with these explicit asks:

- *"Does this match your mental model of the project?"*
- *"Anything missing that should be in here from day one?"*
- *"Any `[needs-confirmation]` items I should resolve before we commit?"*

Only after explicit approval, write the files. Once on disk, they are the canonical source of project context — drift becomes the maintenance skill's problem, not yours.

## Output format

Each file uses a lightweight structure. Projects may extend, but must not omit the required fields.

### CONTEXT.md

**Use the canonical format defined in [`skills/brainstorming/references/context-format.md`](../brainstorming/references/context-format.md).** Do not invent a parallel format — `brainstorming` writes to `CONTEXT.md` inline as terms resolve during conversation, and downstream skills (`test-driven-development`, `executing-plans`, `systematic-debugging`, `receiving-code-review`) all read it. A format divergence here breaks every one of them.

Quick reference of that format:

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
A request submitted by a customer to buy or sell a quantity of an instrument.
_Avoid_: Trade, transaction

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

**Brownfield mining augmentation.** When mining from source, append an HTML comment after each term recording the canonical source location, so traceability survives without breaking the format any other skill consumes:

```md
**Order**:
A request submitted by a customer to buy or sell a quantity of an instrument.
_Avoid_: Trade, transaction
<!-- source: src/domain/order.ts:14 -->
```

For terms inferred from domain conversation rather than read directly from code, use `<!-- source: domain only -->`. For terms whose meaning had to be guessed, append `<!-- needs-confirmation: <reason> -->` instead — that flag is what the user-review gate looks for.

**Multi-context projects.** For projects with multiple bounded contexts, generate `CONTEXT-MAP.md` at the repo root plus a per-context `CONTEXT.md` per bounded context, as described in the canonical format spec. Do not flatten a multi-context project into a single `CONTEXT.md` — that loses the context boundaries the maintenance skill needs to enforce updates against.

### state_machines.md

```
# State Machines — <project name>

> Entity lifecycles. What states exist, how transitions happen, what guards them.

## <Entity>

**States:** <state1>, <state2>, ...
**Initial:** <state>
**Transitions:**
- <from> → <to> on <event>, guarded by <condition>
- ...
**Source:** <file:line where states are enumerated, OR "domain only">.

## <Next entity>
...
```

### data_flow.md

```
# Data Flow — <project name>

> Where data originates, how it transforms, where it ends up.

## <Flow name>

**Source:** <where the data enters — endpoint, queue, file, CLI>
**Sink:** <where it ends up — DB row, response, emit, file write>
**Transformations:** <ordered list of operations applied>
**Shape at each step:** <type / schema / dict-key list — be concrete>
**Source:** <file:line, OR "domain only">.

## <Next flow>
...
```

## Red Flags — catch yourself during bootstrap

| Pattern | What it really means |
|---|---|
| "Looks good enough, ship it" | You did not present for review |
| Removing a `[needs-confirmation]` flag without asking | You guessed and called it a fact |
| Composing without reading the source (brownfield) | You are pattern-matching from your training, not from this repo |
| Skipping a file because "the project probably doesn't need this one" | Write all three even if some are placeholders — the maintenance skill expects them |
| Writing files before user review | You skipped the gate — wrong content on disk is harder to undo than missing content |
| Treating brownfield like greenfield (composing without mining) | You will hallucinate the design instead of recovering it |

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "User will fix it later" | They won't — they'll trust the file, act on it, and regret it |
| "It's just a draft" | A draft on disk is a load-bearing fact to every future session |
| "The codebase is too large to mine thoroughly" | Use CodeGraph if installed (designed for exactly this scale problem). Otherwise use parallel Explore subagents via `dispatching-parallel-agents`. Better to do it right once than rewrite after drift compounds. |
| "Brainstorming already covered all this" | Brainstorming covered design intent. The files are persistent canonical artifacts; the design conversation is ephemeral. Persist explicitly. |
| "We can always regenerate from code" | Regeneration loses the disambiguations and inferred meanings your human partner has already made. The point of persistence is to preserve those decisions. |

## <HARD-GATE>

Files MUST be reviewed by your human partner before being written to disk. You may NOT use `Write` to create `CONTEXT.md`, `state_machines.md`, or `data_flow.md` until you have:

1. Composed the file content (greenfield) OR mined it via subagent (brownfield)
2. Presented all `[needs-confirmation]` items explicitly
3. Received explicit approval to write each file

The maintenance skill will enforce updates against these files for the project's entire lifetime. Wrong content now is harder to fix later than missing content now.

## Exemption — when this skill does NOT fire

- All three files already exist (run `ls` to confirm before exiting)
- The session is read-only exploration of an unfamiliar codebase
- A library / dependency rather than a project (no entity lifecycles, no project-specific domain language)
- A single-file script with no architecture to speak of
- The user explicitly opts out for this project ("this is a sketch, skip the context bootstrap")

## What this skill does NOT do

- It does NOT keep the files current — that's `maintaining-project-context` (the second skill in this pair).
- It does NOT replace `brainstorming`'s Walking Skeleton — Walking Skeleton is design-time architecture validation; this skill *records* the design afterward as canonical artifacts.
- It does NOT enforce that the files are correct — the user review gate is the only correctness check.
- It does NOT run on every session — fires once when the project starts using context-discipline skills, then stays out of the way until a new project needs it.
