---
name: maintaining-project-context
description: Use BEFORE marking a code-modifying task complete (and before commit), to enforce that CONTEXT.md / state_machines.md / data_flow.md stay in lockstep with code changes. Classifies each edit (touched a domain concept, a state transition, or a data movement?) and gates task completion on whether the relevant context file was updated in the same change. Exempts trivial mechanical edits (renames of private helpers, formatting, typos). Requires bootstrap-project-context to have established the three files first.
---

# Maintaining Project Context

## Karpathy Reinforcement

Rule 4 — *Goal-Driven Execution* — applied to documentation. The three context files (`CONTEXT.md`, `state_machines.md`, `data_flow.md`) are load-bearing only if they stay current. Drift between code and docs is silent — code keeps working, the agent keeps shipping, but the bigger-picture artifact rots until nobody (human or skill) trusts it. This skill is the enforcement layer that prevents that rot from compounding.

## The Iron Law

**NO TASK COMPLETION IF A CONTEXT-AFFECTING EDIT HAS NOT UPDATED ITS DOC.**

If your edit:

- introduced, renamed, removed, or semantically changed an exported domain concept → `CONTEXT.md` (or the relevant per-context `CONTEXT.md` in multi-context projects) MUST be updated in the same task.
- added, removed, or changed a state value, transition, or transition guard → `state_machines.md` MUST be updated in the same task.
- added, removed, or changed how data moves between components (new endpoint, new consumer, schema change, route change) → `data_flow.md` MUST be updated in the same task.

**"Updated"** means: the file is edited inline as part of the same task. Not deferred. Not "TODO later." The doc and the code ship together or neither ships.

## Prerequisite

The three files must already exist. This skill is the *maintenance* layer; `bootstrap-project-context` is the prerequisite that puts the files on disk with the user-review gate. If any of the three files is missing when this skill fires:

1. STOP the current task
2. Invoke `bootstrap-project-context` to fill the gap (it has the user-review gate)
3. Resume the current task
4. **If `bootstrap-project-context` is not available** (not loaded, not invocable, skill discovery fails): STOP and escalate to your human partner: *"This task affects project context (`CONTEXT.md` / `state_machines.md` / `data_flow.md`), but the three files do not exist and `bootstrap-project-context` is not available to create them. Options: (a) install `bootstrap-project-context`, (b) create the files manually following [`skills/brainstorming/references/context-format.md`](../brainstorming/references/context-format.md) for `CONTEXT.md` and the format reference in [`skills/bootstrap-project-context/SKILL.md`](../bootstrap-project-context/SKILL.md) for the other two, or (c) explicitly skip context-discipline for this task."* Wait for direction — do NOT proceed under the maintenance gate without explicit resolution.

Do NOT create the files yourself in this skill — skipping bootstrap's user-review gate would let load-bearing artifacts land unreviewed.

## The Maintenance Procedure

### Step 1 — Classify the edit

For each file you edited (or are about to edit) in this task, ask the three classification questions:

#### 1a. Did this edit touch a domain concept? → `CONTEXT.md`

**Hard signals (always require CONTEXT.md update):**

- New exported type / class / interface / struct / enum / function whose name reads like a domain noun
- Renamed exported domain name (most common drift source)
- Removed exported domain name (most-forgotten case — deletion needs CONTEXT.md update too)
- Semantic shift in an existing exported name (return type changed; nullability changed; side effect added; precondition relaxed)

**Soft signals (usually require update; classify case by case):**

- New named constant whose name reads like a domain term
- Domain term appears in commit message or task description for the first time

**Non-signals (exempt):**

- Internal helpers, private members, anonymous functions
- Implementation refactor with unchanged external interface
- Test-only changes — unless the test name introduces a new domain term
- Formatting, whitespace, comment typo

**Multi-context projects:** identify which bounded context the edit lives in, and update *that* context's `CONTEXT.md`. Do NOT update the root `CONTEXT.md` (or root `CONTEXT-MAP.md`) for a change inside a bounded context.

#### 1b. Did this edit touch a state transition? → `state_machines.md`

**Hard signals:**

- New state value added to an enum / discriminated union / state field
- Removed state value
- New transition in mutation logic — a code path that moves an entity from one state to another
- Removed or restructured transition
- Transition guard changed — the condition under which a transition is allowed
- State field renamed

**Soft signals:**

- New mutation function whose name suggests a state change (`submit`, `cancel`, `archive`, `publish`, ...)
- A new branch in mutation logic that checks a status field

**Non-signals:**

- Refactor that preserves the transition graph (extracting a helper, renaming a private variable)
- Read-only operations on state fields
- Test-only changes that don't introduce new states or transitions

#### 1c. Did this edit touch a data flow? → `data_flow.md`

**Hard signals (typed and untyped projects):**

- New HTTP endpoint, gRPC method, GraphQL resolver
- New DB query — especially write queries — or new schema migration
- New file read or write
- New message produced or consumed (Kafka, SQS, EventBridge, etc.)
- New IPC, subprocess call, or shell-out
- Schema change to any data passed across a designed boundary (added/removed field, type change, semantics change)

**Soft signals (untyped projects need this more):**

- Change to a function signature that takes a dict / object argument and propagates it
- New external library call that reads or writes data
- Changes to which keys are written to or read from a dict / object passed across function boundaries
- New conditional that routes data differently across boundaries

**Non-signals:**

- Pure-compute refactors with no IO
- Logging additions — unless logging to a new external sink
- Test-only changes
- Internal-only data movement that doesn't cross a designed boundary

**Untyped projects (loose Python, JS without TS, shell):** the type system is NOT doing the work for you. The bar for "did this touch data flow?" is lower — accept more invocations and more exemptions. Better to classify yes-then-exempt than to silently skip.

### Step 2 — For each "yes," update the file

For each context file flagged in Step 1:

1. **Read** the file. Locate the affected entry (or entries).
2. **Edit** the file inline using the canonical format. For `CONTEXT.md`, that's the format in [`skills/brainstorming/references/context-format.md`](../brainstorming/references/context-format.md). For `state_machines.md` and `data_flow.md`, follow the format in [`skills/bootstrap-project-context/SKILL.md`](../bootstrap-project-context/SKILL.md).
3. **Cite** the update in your verification: "Updated `CONTEXT.md`: renamed `OrderItem` → `LineItem`." Or: "Added `state_machines.md` entry: `Subscription: paused → cancelled on cancellation_received, guarded by is_within_refund_window()`."

Do NOT batch updates across tasks. One task, one set of edits, one set of doc updates, all in the same change. Batching IS drift.

### Step 3 — For each "no," explicitly exempt

Record one short line per file you did NOT update:

- "`CONTEXT.md`: no domain-concept touched."
- "`state_machines.md`: no transitions touched."
- "`data_flow.md`: no data movement touched."

This makes the exemption an active choice, not a silent skip. The `Discovered Issues` section at the end of the response is the safety net for anything this classification missed.

### Step 4 — Pass the gate

State explicitly before completion:

> **Context maintenance gate passed.**
> **Updated:** [list]
> **Exempted:** [list]

Only after this statement may the task be marked complete or committed.

## Red Flags — catch yourself before the gate

| Pattern | What it really means |
|---|---|
| "Will update the docs later" | The doc will not be updated — the moment to do it is now |
| "The change is too small to need a doc update" | If an exported domain term was renamed, the rename IS the doc update |
| Same classification answer ("no") for every file edited | You did not classify — you skimmed and defaulted |
| Updating a doc without reading the existing entry first | Drift in two directions — code-vs-doc and doc-vs-doc |
| Multi-context project, updating root `CONTEXT.md` instead of the bounded context's | The bounded-context boundary exists for a reason — respect it |
| Marking complete without the explicit "gate passed" statement | The statement is the gate — if you didn't say it, you didn't pass it |

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The doc will rot anyway, why bother" | Every "why bother" compounds. Either the discipline holds or the doc dies. |
| "Nobody reads the docs" | Skills read them. `brainstorming` reads `CONTEXT.md`. The maintenance gate exists to keep them readable to skills. |
| "It's just one rename" | One rename is exactly when the doc must update — that's the drift point |
| "I'll catch it in the next task" | You won't — the next task has its own edits, and the rename will be invisible by then |
| "The change is in tests, doesn't count" | Tests that introduce new domain terms DO count. Production-only doesn't matter; the lexicon does. |
| "Untyped project, the soft signals are too noisy" | The soft signals are noisy *because* the type system isn't filtering them. Accept the noise; exempt actively; do not skip silently. |

## <HARD-GATE>

You may NOT mark a task complete, run `git commit`, or hand off to your human partner until you have:

1. Run the three classification questions for every code file edited in this task
2. Updated the relevant context files in the same task for every "yes"
3. Explicitly exempted every "no"
4. Stated **"Context maintenance gate passed. Updated: [list]. Exempted: [list]."**

If the three context files do not exist, STOP and invoke `bootstrap-project-context` instead of proceeding.

## Exemption — when this skill does NOT fire

- The task is read-only exploration (no edits made)
- All edits are formatting, whitespace, or comment-typo only
- All edits are within `tests/` AND introduce no new domain terms
- All edits are within infrastructure-only files (CI config, build scripts, lockfiles, dependency bumps) with no semantic project impact
- Your human partner has explicitly opted out for this task ("sketching — skip context maintenance")

When in doubt: do NOT exempt. Run classification and exempt actively per-file — it's cheaper than missing a drift.

## What this skill does NOT do

- It does NOT create the three context files — that's `bootstrap-project-context`'s job (and gate).
- It does NOT verify the docs are *correct* — only that they were *updated in lockstep with code*. Correctness is your human partner's review responsibility. The `verifying-assumptions` Reframe Pass's "expand the read set" technique can be pointed at these files when stuck verification benefits from re-reading project context.
- It does NOT fire automatically on every edit — only at task completion, before commit, before hand-off.
- It does NOT replace the `Discovered Issues` block from the `CLAUDE_APPEND.md` mandatory response format — that block is the safety net for stragglers this skill's classification missed.
- It does NOT enforce that `state_machines.md` and `data_flow.md` exist in projects where they have no content. If the entire project has no entity lifecycles or no documented flows, those files remain as one-line placeholders (per the bootstrap format), and Steps 1b/1c exempt automatically.
