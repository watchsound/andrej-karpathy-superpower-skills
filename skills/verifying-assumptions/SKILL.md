---
name: verifying-assumptions
description: Use when verifying assumptions stated in an "Assumptions Made" section, or when your human partner asks "verify the assumptions" / "check the assumptions" / "are these assumptions right" / similar. Requires per-assumption evidence (file:line, command output, grep hit) and produces validated/refuted/unverifiable verdicts; bounded to one same-procedure redo plus one higher-context Reframe Pass before escalating to your human partner.
---

# Verifying Assumptions With Evidence

## Karpathy Reinforcement

Rule 4 of `karpathy-guidelines` — "Goal-Driven Execution: define success criteria, then verify against them." This skill applies that to the `Assumptions Made` section: each stated assumption is a success criterion that must be checked against *evidence*, not against vibes.

## The Iron Law

**NO "LOOKS RIGHT" VERDICTS.**

Every verdict must be one of:

- **✅ Validated** — accompanied by a citation: file:line, command + output snippet, grep hit, type definition, or "user confirmed: <quote>"
- **❌ Refuted** — accompanied by the same kind of citation showing the actual state
- **⚠ Unverifiable** — accompanied by an explanation of *why* (not just "I'm not sure") and a request to your human partner

Phrases like "seems consistent," "no obvious problems," "checked and it's fine," "behaves as expected" are NOT verdicts. They are restatements of the original assumption in confident clothing.

## The Per-Assumption Procedure

For each assumption in the `Assumptions Made` section:

### Step 1 — Restate

Quote the assumption verbatim. Do not paraphrase. Paraphrasing slides the goalposts and lets a refuted assumption pass as validated.

### Step 2 — Identify what would prove or refute it

Be concrete and adversarial. For each assumption ask: **"What single check could *falsify* this?"** That check is your discharge action.

| Assumption form | Discharge action |
|---|---|
| "File X exists" | `Read` the path. |
| "Function Y returns type Z" | `Read` the signature; or `Grep` callers + their type usage. |
| "Endpoint /foo accepts POST" | `Grep` route definitions. If not findable, send the request. |
| "The build uses tool W" | `Read` `package.json` / `pyproject.toml` / equivalent. |
| "Your human partner wants behavior A" | Ask. No code can verify intent. |
| "No existing implementation" | `Grep` for likely names — singular, plural, snake_case, camelCase, kebab-case. |
| "This is backwards compatible" | Cite the contract or deprecation policy. Compatibility is never self-evident. |

### Step 3 — Run the check

Execute the check. Capture the actual output. Do not summarize — capture the snippet that decides the verdict. A summary is not evidence.

### Step 4 — Record the verdict

Use this format for each assumption:

```
- **Assumption:** <verbatim quote>
  - **Verdict:** ✅ Validated | ❌ Refuted | ⚠ Unverifiable
  - **Evidence:** <file:line | command + output | grep hit | user quote | reason unverifiable>
```

## Common Failures

| You said... | Actual evidence required |
|---|---|
| "The function returns a string" | The return-type annotation, or 3+ call sites consuming it as string |
| "The config defaults to false" | The default-value line in the config schema |
| "No callers depend on this" | `Grep` results across the workspace — not "I didn't see any" |
| "Tests cover this case" | The test file:line exercising *this specific* case, not the suite name |
| "Backwards compatible" | The contract document or an explicit deprecation policy citation |
| "Standard library handles this" | The stdlib function name and a doc/source link |

## Red Flags — Catch yourself during verify

| Pattern | What it means |
|---|---|
| "Seems consistent with..." | You compared the assumption to your memory, not to evidence |
| "No obvious problems" | You looked for confirmation, not refutation |
| "Should be fine" | Same blind spot as the original assumption |
| "I checked and it's fine" | Cite the check or it didn't happen |
| Same tool-call cost as drafting | If verifying took zero new Read/Grep/Bash calls, you didn't verify |
| Verifying multiple assumptions in one paragraph | Each assumption gets its own verdict + evidence. No bundling. |

## Bounded Redo

After verdicts:

1. **All validated?** → Report and stop.
2. **Some refuted?** → Run ONE redo iteration that incorporates the corrected facts. Re-state the assumptions for the redo. Re-verify them with the same procedure.
3. **Still refuted after the redo?** → Run ONE Reframe Pass (see below) before escalating. Same reasoning path twice has already converged; the next attempt must inject *different signal*, not the same procedure a third time.
4. **Still refuted after the Reframe Pass?** → STOP. Escalate to your human partner with:
   - the remaining refuted assumption(s),
   - the evidence showing the actual state,
   - what the Reframe Pass tried and why it did not resolve it,
   - the question or decision you need from them.

Never run a fourth iteration without explicit human direction. Verify→redo spirals burn tokens and converge to subtly-different wrong answers — same blind spot, different bug. The Reframe Pass exists because a same-path redo cannot escape its own blind spot; one round of *different signal* is the bounded escape hatch, after which your human partner is the only remaining source of new signal.

### The Reframe Pass

A Reframe Pass is NOT "run the same procedure harder." It must inject *different signal* into the verification. Pick at least one of the techniques below — and explicitly cite which one(s) you used in the resulting verdict:

- **Re-anchor on intent.** Re-read the **currently-active** task as your human partner phrased it — not necessarily the session's first prompt. If the session has pivoted since the original task (explicit shift signals like *"now let's", "switching to", "back to", "moving on"*, or a noticeably different file scope / bounded context / module being discussed), the *original* task is the wrong anchor; re-anchor on the *current* frame's intent. Then ask: *"What higher-level goal does this assumption serve in the current frame?"* Verify against that goal, not the assumption text. The assumption itself may have been the wrong question — or it may have been asked under a stale frame.
- **Expand the read set.** Read files NOT touched in the prior two passes — config, tests, callers, type definitions, related modules, build scripts. The blind spot was likely the absence of one of these from your verification scope.
- **Fresh-context subagent.** Launch an Explore subagent with the refuted assumption + the original task framing, but NOT the prior verification attempts. Their fresh context IS the different reasoning path.
- **Restate the question.** If the assumption is phrased one way ("does X exist?"), reframe it ("what is the actual mechanism here?") and re-verify. The original phrasing was sometimes the blind spot.

The Reframe Pass MUST still produce cited evidence per the Iron Law. *"I thought about it harder and now it looks right"* is NOT a Reframe Pass output — that is precisely the failure mode this skill exists to prevent. The reframe gives you a different signal source; the Iron Law still gates what the signal must be.

#### Reframe verdict format

```
- **Assumption (refuted twice):** <verbatim quote>
  - **Reframe technique used:** <re-anchor | expand reads | subagent | restate | combination>
  - **What changed:** <new file read / new framing / subagent finding / new question>
  - **Verdict:** ✅ Validated | ❌ Refuted | ⚠ Unverifiable
  - **Evidence:** <citation>
```

## Recording Verdicts in Memory

After verdicts, ask for each one: **"Does this verdict have value beyond today's diff?"**

### Validated assumption with general value → `project` memory

Use the auto-memory `project` type. Lead with the fact, include **Why:** and **How to apply:** lines per the harness auto-memory guidance. Add the verification date and evidence.

```
Verified <YYYY-MM-DD>: <fact, with specifics like file:line or version>.
**Why:** <originating session/context — what made us check>.
**How to apply:** <when this should shape future suggestions>.
**Evidence at verification:** <citation>.
```

Then add an index entry to `MEMORY.md` per the existing convention.

### Refuted assumption with general value → `feedback` memory

Frame the entry as the corrected fact, not the falsehood (positive form is more usable later):

```
Do not assume <X>. Actually: <Y>.
**Why:** <session/context where we learned this>.
**How to apply:** <when the wrong assumption tends to come up>.
```

### Per-task-only verdicts → do NOT persist

If the verdict is specific to today's diff and has no future relevance ("this one PR doesn't break test_foo"), do NOT write to memory. Mention it in the response and let it decay. Memory bloat is real cost — every entry is read on every future session.

### Decision shortcut

- Will this fact still matter in two weeks, in a different conversation? → persist
- Is it about this specific PR or this specific session? → do not persist
- Unsure? → do not persist (false positives in memory cost more than false negatives)

## What this does NOT replace

- This skill is the **post-hoc** verification layer for assumptions that reach the `Assumptions Made` section.
- `surfacing-assumptions` is the **pre-code** layer — preventing wrong assumptions from shaping the diff in the first place. Always prefer prevention; this skill exists for cases where the front-loading layer was bypassed, the response is being reviewed later, or your human partner asks for an explicit verify pass.
- This skill does NOT verify completion claims about the work itself — that's `verification-before-completion`.
