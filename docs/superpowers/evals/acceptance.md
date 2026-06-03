# Acceptance Eval Harness

Purpose: prove that the fork's behavioral additions actually fire in a fresh session, with the expected output shape. This is not an automated test suite — it is a structured probe-and-observe harness. A human runs each probe in a clean Claude Code session and fills in what they observed.

This harness exists because every behavioral claim the fork makes (Walking Skeleton fires for greenfield, Ubiquitous Language disambiguates "order", Test Quality Bar rejects shallow tests) is currently unvalidated. The upstream `CLAUDE.md` requires before/after evidence for skill changes; this harness is how we produce it.

## How to Use

1. **Fresh session.** Quit Claude Code, restart, open this repo. Confirm `/plugin list` shows `superpowers@superpowers-dev` and not the upstream package.
2. **Run one probe at a time.** Send the exact `Probe` message verbatim. Do not add explanation or context.
3. **Capture the transcript.** Copy the full first assistant response (or the response chain up to the first user-decision point). Paste into the `Observed` block.
4. **Score against the checklist.** Tick each `Expected` item that fired. Do not retroactively justify misses — a miss is a finding.
5. **Note any surprise.** Behavior the fork did not predict — neither expected nor counter-expected — goes in `Surprises`. These are the highest-signal entries.

A probe is **passing** only when every Expected box is checked and no critical Surprise was logged. Anything less is a finding to triage.

## Probe 1 — Greenfield + Ubiquitous Language + Walking Skeleton

Tests: `brainstorming` (Karpathy Reinforcement, Ubiquitous Language, Walking Skeleton subsections).

**Probe message:**

> Let's design a small order book for an A-share trading system.

**Expected behavior:**

- [ ] `brainstorming` skill is invoked before any design content. The agent announces it or the Skill tool call is visible.
- [ ] Agent reads (or attempts to read) `CONTEXT.md` at repo root. If absent, it offers to create one rather than silently proceeding.
- [ ] Agent surfaces ambiguity on "order" — explicitly proposes that the term could mean trading order vs purchase order vs work order and asks which is intended.
- [ ] Agent does NOT immediately propose a design. The `<HARD-GATE>` holds.
- [ ] Walking Skeleton is offered as the first design deliverable for this greenfield system, distinct from feature design.
- [ ] At least one Karpathy rule (Think Before Coding or Goal-Driven Execution) is surfaced as a lens for the session, not just listed.

**Observed:**

```
<paste transcript here>
```

**Surprises:** _none yet_

**Verdict:** _pending_

---

## Probe 2 — Brownfield bug fix (Walking Skeleton must NOT fire)

Tests: `brainstorming` Walking Skeleton greenfield-only guard, `systematic-debugging` Iron Law.

**Probe message:**

> The login endpoint in this repo throws a 500 when the user submits an empty password. Help me fix it.

**Expected behavior:**

- [ ] Walking Skeleton is NOT proposed (this is a brownfield bug fix).
- [ ] `systematic-debugging` is invoked — Iron Law is referenced or visible.
- [ ] Agent asks to reproduce the bug or read the relevant code before proposing a fix.
- [ ] Agent does NOT propose a fix in the first response.
- [ ] If "user" or "login" appears ambiguous in context, agent disambiguates or notes it.

**Observed:**

```
<paste transcript here>
```

**Surprises:** _none yet_

**Verdict:** _pending_

---

## Probe 3 — Test Quality Bar rejects shallow tests

Tests: `test-driven-development` Test Quality Bar + Behavior-Not-Implementation.

**Probe message:**

> Here's a function and its test. Is the test good enough?
>
> ```ts
> function calculateDiscount(price: number, isPremium: boolean): number {
>   return isPremium ? price * 0.8 : price;
> }
>
> test('calculates discount', () => {
>   expect(calculateDiscount(100, true)).toBe(80);
> });
> ```

**Expected behavior:**

- [ ] Agent identifies that the test is shallow: only one input/output pair, no test for the non-premium branch, no edge cases (zero, negative, very large).
- [ ] Agent references the mutation-thinking idea: would the test still pass if `* 0.8` became `* 0.5` for non-premium? (It would — the non-premium branch isn't tested.)
- [ ] Agent does NOT just say "looks good" or rewrite without explaining why.
- [ ] Agent proposes at least one additional test that depends on a different input.

**Observed:**

```
<paste transcript here>
```

**Surprises:** _none yet_

**Verdict:** _pending_

---

## Probe 4 — Deterministic-code boundary

Tests: `prefer-deterministic-code`.

**Probe message:**

> I need to route incoming webhooks to the right handler based on the `event_type` field. The event types are: `user.created`, `order.placed`, `payment.completed`. I was thinking of asking the LLM to classify each webhook. Does that work?

**Expected behavior:**

- [ ] Agent refuses or strongly pushes back on the LLM-classification approach.
- [ ] Agent identifies this as a deterministic problem (string match on a known set).
- [ ] Agent proposes a switch/dict/map solution instead.
- [ ] Reasoning references reliability, cost, or determinism — not just preference.

**Observed:**

```
<paste transcript here>
```

**Surprises:** _none yet_

**Verdict:** _pending_

---

## Probe 5 — Plan-mode Contract-First

Tests: `writing-plans` Architecture Contracts First.

**Probe message:**

> I've approved this spec: "Build a `RateLimiter` service that allows up to N requests per window per key, with pluggable storage backends." Please write the implementation plan.

**Expected behavior:**

- [ ] `writing-plans` skill is invoked.
- [ ] Task 1 in the plan defines the `RateLimiter` interface/type — no implementation.
- [ ] Task 2 is a boundary test against that interface.
- [ ] Implementation tasks come after the contract is fixed.
- [ ] Storage backend is also contract-first (defined as an interface before any backend is implemented).

**Observed:**

```
<paste transcript here>
```

**Surprises:** _none yet_

**Verdict:** _pending_

---

## Probe 6 — Checkpoint Discipline self-check

Tests: `executing-plans` Checkpoint Discipline self-check.

**Setup:** Hand the agent a small two-task plan, ask it to execute, and observe after task 1 completes.

**Probe message:**

> Execute this plan:
> Task 1: Create `src/greet.ts` with `export function greet(name: string): string { return 'Hello, ' + name }`. Add a test that asserts `greet('world') === 'Hello, world'`.
> Task 2: Add a `greetLoudly` function that uppercases the result. Test it.

**Expected behavior after Task 1:**

- [ ] Agent writes a Done/Verified/Remaining checkpoint before starting Task 2.
- [ ] *Verified* line cites the actual test command and pass output, not just "tests pass."
- [ ] Agent does not silently advance from Task 1 to Task 2.

**Observed:**

```
<paste transcript here>
```

**Surprises:** _none yet_

**Verdict:** _pending_

---

## Probe 7 — Mandatory Response Format

Tests: `CLAUDE_APPEND.md` Discovered Issues + Assumptions Made format.

**Probe message:**

> Add a `--verbose` flag to the CLI entry point so it logs each step. Don't worry about tests for now.

**Expected behavior:**

- [ ] Response ends with a `### Discovered Issues` and/or `### Assumptions Made` section.
- [ ] At least one assumption is listed (e.g. "Assumed the CLI entry is at X" or "Assumed the logger is the global console").
- [ ] If any assumption is load-bearing, it carries `**(critical)**`.
- [ ] Sections are omitted entirely if empty — not filled with placeholder text.

**Observed:**

```
<paste transcript here>
```

**Surprises:** _none yet_

**Verdict:** _pending_

---

## Scoring & Triage

After all probes run:

| Probe | Pass | Partial | Fail | Notes |
|---|---|---|---|---|
| 1. Greenfield + UL + Walking Skeleton | | | | |
| 2. Brownfield bug fix | | | | |
| 3. Test Quality Bar | | | | |
| 4. Deterministic-code boundary | | | | |
| 5. Contract-First plan | | | | |
| 6. Checkpoint self-check | | | | |
| 7. Mandatory Response Format | | | | |

**Triage rules:**

- A **Fail** on a probe means the corresponding skill change is not firing as designed — fix the skill, not the probe.
- A **Partial** with a recoverable miss (e.g. agent did the right thing but never announced the skill) is a documentation issue, not a behavior issue.
- A **Surprise** that's consistently positive across runs is a finding worth documenting in the README.
- A **Surprise** that's negative is a regression — open an issue and revert the responsible change if needed.

## Re-running

This harness is cheap to re-run after any skill change. The expected behaviors are stable; only the `Observed` blocks change. Keep prior runs in git history (do not overwrite — append a new run as a dated section if useful) so regressions are visible.

## Known limits of this harness

- LLM output is non-deterministic. A single pass is not proof; ideally each probe runs 3× and the verdict is "passes 2/3+."
- These probes test *triggering* and *output shape*, not *correctness of the work produced*. A probe can pass while the underlying skill produces low-quality content. Quality is a separate dimension and would need its own harness.
- The harness assumes the operator runs probes honestly. An operator who fills in expected output without running the probe is gaming the harness, not validating it.
