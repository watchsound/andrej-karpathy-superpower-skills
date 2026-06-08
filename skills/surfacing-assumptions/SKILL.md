---
name: surfacing-assumptions
description: Use BEFORE writing or editing code on any non-trivial change. Surfaces every assumption about scope, file locations, types, contracts, behavior, or environment, then requires each to be discharged with concrete evidence (file:line, command output, grep hit, or explicit user confirmation) before implementation begins. Trivial mechanical edits (renames, typo fixes, formatting) are exempt.
---

# Surfacing Assumptions Before Code

## Karpathy Reinforcement

This skill operationalizes Rule 1 of `karpathy-guidelines` — "Think Before Coding: Don't assume. Don't hide confusion. Surface tradeoffs." Karpathy says state assumptions explicitly. This skill says state them **and** discharge each one with evidence *before* any code is written.

## The Iron Law

**NO IMPLEMENTATION WITHOUT DISCHARGED ASSUMPTIONS.**

Every assumption that shapes the code you are about to write must be either:

1. **Discharged** by concrete evidence (file:line, command output, grep hit, type definition), OR
2. **Accepted** explicitly by your human partner as a known risk, OR
3. **Escalated** to your human partner with the assumption text and what would resolve it.

Code written on undischarged assumptions is code shaped by a guess. When the guess is wrong, the whole change is wrong — and the cost of redo is much larger than the cost of surfacing.

## The Surface-and-Discharge Procedure

Run this BEFORE the first Edit / Write / mutating Bash:

### Step 1 — Enumerate

List every belief that, if false, would change the code. Be aggressive:

- "The function lives in file X"
- "The existing function returns type Y"
- "The caller handles error case Z"
- "The framework provides utility W"
- "Your human partner wants behavior A, not B"
- "The build uses tool C, not D"

If you have fewer than three assumptions for a non-trivial task, you are not looking hard enough.

### Step 2 — Categorize

For each assumption, mark it:

- **Code-verifiable** — can be confirmed by reading a file, grepping a symbol, running a command
- **User-only** — requires intent/preference clarification from your human partner
- **Unverifiable now** — cannot be confirmed before code is written; explicitly accept as a known risk and note what would falsify it later

### Step 3 — Identify the discharge action

For each code-verifiable assumption, name the concrete check:

- "Run `grep -n parseSemver src/`"
- "Read `package.json` for the `main` field"
- "Bash: `python -c 'import json; print(json.__version__)'`"
- "Check that `User.email` exists in `models/user.py`"

For user-only assumptions, draft the clarifying question — one specific question, not a vague check-in.

### Step 4 — Discharge or escalate

Execute the checks. Record the evidence inline. Examples:

- ✅ `parseSemver` does not exist (`grep` returned 0 hits) — will create new
- ❌ Existing `parseVersion` in `src/util/semver.ts:14` returns `[major, minor, patch]` not `{major, minor, patch}` — adjusting plan
- ⚠ Cannot verify from code: strict or lenient parsing? — asking

Refuted assumptions reshape the plan BEFORE code is written, not after.

### Step 5 — Pass the gate

Once every assumption is discharged, accepted-with-known-risk, or escalated, state explicitly: **"Gate passed. Proceeding with implementation."** Now you may edit.

## Red Flags — Catch yourself before the gate

| Pattern | What it really means |
|---|---|
| "Should work" | Assumption you haven't tested |
| "Probably / I think / I assume" | Undischarged assumption |
| "Based on standard patterns" | Pattern-matching from training, not from this codebase |
| "Following the convention" | Which convention? Cite the file. |
| "It's obvious from context" | If obvious, cite the context. If you can't cite, it isn't. |
| Zero files read before editing | You have made every assumption invisible to yourself |
| Same code structure as your last similar task | You are not in your last task. Verify in *this* one. |

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "Just a quick change" | Quick changes built on wrong assumptions become slow rewrites |
| "I've seen this pattern before" | Different codebase, different conventions. Verify in *this* one. |
| "My human partner will catch it in review" | They asked you to think, not to outsource thinking |
| "I'll list it in Assumptions Made at the end" | Too late — the code is already shaped |
| "Discharging takes too long" | One refuted assumption saves one redo cycle. Always cheaper. |
| "This is too small to surface assumptions for" | Use the trivial-edits exemption below if it really qualifies; otherwise surface. |

## <HARD-GATE>

You may NOT use `Edit`, `Write`, `NotebookEdit`, or any Bash command that mutates state (`touch`, `mkdir` on project files, `rm`, `mv`, `cp` writing into the project, `sed -i`, `>` redirects into project files, `git add` / `commit` / `push`, package installs, migrations, etc.) until you have:

1. Enumerated assumptions
2. Categorized them
3. Discharged the code-verifiable ones with cited evidence
4. Escalated unresolved user-only ones
5. Explicitly stated **"Gate passed."**

Reading files, grepping, globbing, running read-only Bash, launching read-only subagents — these are NOT gated. They are the discharge mechanism.

## Exemption — Trivial Mechanical Edits

This skill does NOT fire for:

- Renaming a single variable/function/file with no semantic change
- Fixing typos in comments, strings, or docs
- Whitespace / formatting fixes
- Reverting a recent commit verbatim
- Applying a one-line change explicitly dictated by your human partner

When in doubt: if you cannot finish the task without first reading other code, it is not trivial.

## What this does NOT replace

- This skill is the **front-loading** layer. `verifying-assumptions` handles **post-hoc verification** of the `Assumptions Made` section in your response.
- This skill does not replace `brainstorming` (which negotiates intent) or `writing-plans` (which structures multi-step work). It runs *after* those, just before the first edit.
- It does not exempt you from the existing CLAUDE.md "Mandatory Response Format" — `Discovered Issues` and `Assumptions Made` sections still appear at the end of the response. This skill is what makes those sections accurate.
