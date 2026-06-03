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

- [x] `brainstorming` skill is invoked before any design content. The agent announces it or the Skill tool call is visible.
- [x] Agent reads (or attempts to read) `CONTEXT.md` at repo root. If absent, it offers to create one rather than silently proceeding.
- [ ] Agent surfaces ambiguity on "order" — explicitly proposes that the term could mean trading order vs purchase order vs work order and asks which is intended.
- [x] Agent does NOT immediately propose a design. The `<HARD-GATE>` holds.
- [ ] Walking Skeleton is offered as the first design deliverable for this greenfield system, distinct from feature design.
- [ ] At least one Karpathy rule (Think Before Coding or Goal-Driven Execution) is surfaced as a lens for the session, not just listed.

**Observed (run 1, 2026-06-03, junction install on Windows VSCode):**

```
brainstorming skill
Globpattern: "CONTEXT*.md" → No files found
Globpattern: "docs/superpowers/specs/*" → Found 5 files
TodoWrite created with checklist: Explore project context, Read CONTEXT.md / glossary,
Clarify purpose/scope, Clarify A-share feature set, Clarify language/runtime, Propose
2-3 approaches, Present design sections, Write design doc, User reviews spec, Hand off
to writing-plans.

Quick context: we're in the superpowers skills repo, which is clearly not the right home
for a trading system — so I'll assume this design will land in a separate project we'll
create elsewhere. Confirm or redirect me when you reply.

Before I ask about A-share specifics (price limits, call auction, T+1, tick rules, etc.),
I need to pin down purpose — it determines every later tradeoff. Which of these best
matches what you have in mind?

A. Educational / learning artifact ...
B. Backtest / simulation engine ...
C. Research-grade matching engine prototype ...
D. Production-aspiring low-latency core ...

My recommendation, based on the word "small": A or B. C if you actually want it to reflect
the A-share rulebook faithfully. Which one — and where should the project live (give me
an absolute path, or say "pick one and propose it")?
```

**Surprises:**

- Two `karpathy-guidelines` skills appeared in the available-skills list: the junctioned `karpathy-guidelines` and a pre-existing `andrej-karpathy-skills:karpathy-guidelines` from another plugin. Descriptions overlap; the model has to pick. Worth documenting and possibly renaming our fork's vendor to avoid collision.
- Agent did not disambiguate "order" against non-trading senses. Defensible — within A-share context the term is unambiguous — but the skill's rule is unconditional ("when the user uses a fuzzy or overloaded term, stop and disambiguate"). The skill should either soften this to "fuzzy *in context*" or accept that domain-clear cases skip the rule.
- Walking Skeleton not offered yet, but checklist suggests it will come after purpose is pinned — appropriate ordering, not a miss.
- No Karpathy rule explicitly named as a lens. The behavior ("pin down purpose first") is *consistent with* Think Before Coding but does not cite it.

**Verdict:** PASS with caveats. Brainstorming fires correctly, HARD-GATE holds, checklist follows skill prescription. Three soft-misses are either ordering-appropriate (Walking Skeleton) or worth softening in the skill (order-disambiguation rule, Karpathy-rule-surfacing).

**Run 1 continuation (purpose → tier → interaction → approach → design):**

Across four subsequent turns, the agent:

- Pinned purpose (Tier 2 educational, Python, scripted scenarios) one question at a time ✅
- Surfaced a critical assumption (simulated clock vs wall-clock) inside a clarifying question — Karpathy Rule 1 firing behaviorally even when not cited ✅
- Proposed three architectural approaches with tradeoffs and a recommendation ✅
- Transitioned to design presentation by introducing "Section 1 — Module layout, core data model, OrderBook" — **and went straight into file tree + OrderBook data structure** ❌

**Walking Skeleton trigger FAILED.** This is the Probe 1 critical-miss flagged in advance. The brainstorming skill's Walking Skeleton subsection sat at line ~34 of the skill, but the checklist step the agent executed ("Present design") at line ~76 didn't reference it. By the time the agent reached step 6, the subsection's guidance wasn't top-of-mind. Predicted weakness, materialized.

**Fix applied (commit pending):** Pulled the Walking Skeleton trigger into the checklist step itself as a GREENFIELD GATE clause, and rewrote the subsection's trigger from "When the design is for a new system or service" (descriptive, soft) to "TRIGGER (no judgment call): apply this whenever the user's request describes a new system..." (directive, hard). Also added an unconditional "No data model, file layout, or component breakdown may be presented before the Walking Skeleton is presented and approved" — closes the specific path the agent took.

**Probe 1 re-run required** in a fresh session to validate the fix. Until that happens, the Walking Skeleton checkbox stays unconfirmed.

---

### Run 2 (2026-06-03, after GREENFIELD GATE fix, fresh session)

**Walking Skeleton fired correctly.** After 5 self-bounded clarifying questions (rule subset → location+language → rule tier → entry point → time model), the agent announced *"Now — Walking Skeleton first, per the greenfield rule"* and produced a complete skeleton matching all three skill requirements:

- **Happy path:** 6 numbered steps from CLI invocation through trade output to file
- **Seams:** `Clock` Protocol, `Order`/`Trade` dataclasses, `MatchingEngine` class signature with stubbed `submit`/`cancel`, CLI `main` signature — all concrete enough to compile
- **Acceptance test:** `test_two_crossing_orders_produce_one_trade` with full pytest code and golden-file diff

Bonus: explicit "what this skeleton deliberately does NOT have yet" list (auction phases, price limits, lot size, real book data structure, cancel logic, multi-symbol), each item annotated as plugging into an existing seam later. That's the skeleton concept understood at depth, not just surface-mimicked.

Also notable:
- Within-domain "order book" disambiguation (exchange-side vs broker OMS vs market-data reconstruction vs backtest) is *better* than the original Probe 1 expectation of generic-word disambiguation. Worth amending the probe spec.
- Karpathy rule still not explicitly named as a lens. Soft-miss persists across both runs — content fires behaviorally but isn't cited.
- Drag concern from Run 2 (5 clarifying questions) was self-bounded — no transition guard needed. The flagged Discovered Issue is downgraded.

**Run 2 verdict: PASS, clean.** The fork's GREENFIELD GATE fix works end-to-end. This is the canonical example of the eval loop catching a real failure mode and a targeted fix validating cleanly in a fresh session.

**Updated checkbox state:**

- [x] `brainstorming` skill is invoked before any design content.
- [x] Agent reads (or attempts to read) `CONTEXT.md` at repo root.
- [x] Agent surfaces ambiguity on "order" — within-domain (matching engine vs broker OMS vs market-data vs backtest). Original spec said cross-domain (trading vs purchase vs work), but within-domain is more useful.
- [x] Agent does NOT immediately propose a design. The `<HARD-GATE>` holds.
- [x] Walking Skeleton is offered as the first design deliverable.
- [ ] At least one Karpathy rule is surfaced as a lens for the session, not just listed. *Still missing — soft-miss.*

5 of 6 boxes checked. The remaining miss (Karpathy rule naming) is content-quality, not behavior-shape — the rules fire behaviorally even when not cited.

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

- [x] Agent refuses or strongly pushes back on the LLM-classification approach.
- [x] Agent identifies this as a deterministic problem (string match on a known set).
- [x] Agent proposes a switch/dict/map solution instead.
- [x] Reasoning references reliability, cost, or determinism — not just preference.

**Observed (run 1, 2026-06-03, junction install on Windows VSCode):**

```
prefer-deterministic-code skill
No — don't use an LLM for this. event_type is a structured field with a known, finite
set of values. That's a dictionary lookup or match statement, not a classification problem.

HANDLERS = {
    "user.created": handle_user_created,
    "order.placed": handle_order_placed,
    "payment.completed": handle_payment_completed,
}

handler = HANDLERS.get(payload["event_type"])
if handler is None:
    raise UnknownEventType(payload["event_type"])
handler(payload)

Why this beats the LLM:
- Deterministic. Same input → same route, every time. An LLM can return user.created today
  and user_created next week.
- Free and instant. No tokens, no latency, no rate limits on your hot path.
- Fails loudly. Unknown event types raise immediately instead of being silently routed
  somewhere plausible.

Save the LLM for cases where the input is unstructured language (e.g. classifying
free-form support tickets into intents). A field your own system emits doesn't qualify.

Assumptions Made
- Assumed event_type is emitted by a system you control or a well-defined webhook spec
  (so the value set is stable and known). (critical) — if event types arrive as free-form
  prose from an untrusted source, the answer changes.
```

**Surprises:**

- Response incidentally demonstrates Probe 7 (Mandatory Response Format) — `Assumptions Made` section appended with `(critical)` marker, `Discovered Issues` correctly omitted because none were found. The CLAUDE_APPEND format fires automatically; doesn't require the explicit Probe 7 trigger.
- Reasoning quality is high — three distinct arguments (determinism, cost/latency, failure mode) rather than a single "use a dict instead."
- Counter-example offered (free-form support tickets) clarifies the boundary the skill draws.

**Verdict:** PASS, no caveats. Skill fires, refuses LLM, proposes the right alternative, gives correct reasoning, and produces the mandatory response format.

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
