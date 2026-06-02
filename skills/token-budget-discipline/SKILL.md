---
name: token-budget-discipline
description: Use when starting a multi-step task, an agent loop, or a long-running debugging session, to bound how much context can be spent before checkpointing or restarting.
---

# Token Budget Discipline

## Overview

Without explicit budgets, an agent loop can spend itself into a 50K-token context dump on the same problem. The model will not stop on its own; it will keep re-reasoning over the same growing error message and forget which fixes it has already tried.

**Core principle:** A bounded loop that checkpoints and restarts beats an unbounded loop that drifts.

## When to Use This Skill

Invoke at the start of:
- Multi-step refactors that touch more than ~3 files
- Debugging sessions that have already gone past one round of "let me try something else"
- Any agent loop where the same context keeps growing
- Long pipelines (data migration, batch processing, multi-stage tool chains)

## Default Budgets

Treat these as defaults, not laws. Adjust if the task plainly demands more:

| Scope | Soft budget | Hard budget |
|---|---|---|
| Per task | 4,000 tokens of *new* context | 8,000 tokens |
| Per session | 30,000 tokens | 60,000 tokens |

"New context" = tool results, file reads, error messages, model output. Does not count the original prompt.

## The Discipline

1. **State the budget out loud** at the start of the task: "I'll spend up to ~4K tokens of new context on this before checkpointing."
2. **Track roughly** as you go. After each major tool result, note whether you're at <50%, 50–80%, or >80% of soft budget.
3. **At the soft budget**, stop and summarize:
   - What has been done
   - What has been verified
   - What is still unknown
   - What the next concrete step would be
4. **At the hard budget**, do not push through. Hand the summary back to your human partner and ask whether to restart with a tighter scope or continue.

## What Counts as a Checkpoint

A checkpoint is a paragraph you could paste into a fresh session and resume from. If you cannot write that paragraph, you are not at a checkpoint — you are at "I've forgotten where I am."

A checkpoint:
- Names the original goal in one sentence
- Lists the concrete edits / state changes already made
- Lists the verifications already passed
- Names the next concrete step (not "continue debugging")

## Red Flags

These thoughts mean STOP — you are running an unbounded loop:

| Thought | Reality |
|---|---|
| "One more iteration and I'll get it" | You have thought that for 5 iterations. Checkpoint. |
| "Let me re-read the full error" | The error has not changed. Re-reading it adds context, not signal. |
| "I'll try a slightly different version of the same fix" | This is the third variant. Stop and reconsider the diagnosis. |
| "I just need to load one more file" | The context is the problem, not the missing file. |
| "I don't need a checkpoint, I remember what I'm doing" | If you can't write the summary in 4 lines, you don't. |

## When You Cross the Hard Budget

Do not silently keep going. Explicitly tell your human partner:

> "I've spent ~[N] tokens on this and have not converged. Here is the checkpoint summary. Recommend: (a) restart with tighter scope, (b) hand off to a fresh subagent with the summary as input, or (c) we agreed I'd keep going — say the word."

**Loud failure beats silent drift.** This is also Karpathy rule 12 in spirit; see `karpathy-guidelines`.
