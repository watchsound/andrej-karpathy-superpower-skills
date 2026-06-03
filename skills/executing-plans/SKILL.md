---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Karpathy Reinforcement

While executing this plan, also apply:
- **Simplicity First** (Karpathy rule 2) — implement the minimum that satisfies each plan item; no features beyond what the plan calls for.
- **Surgical Changes** (Karpathy rule 3) — every edited line must trace to a plan item; no drive-by refactoring of adjacent code.
- **Goal-Driven Execution** (Karpathy rule 4) — run each step's verification before moving on; don't batch verifications at the end.
- **Consult the glossary** — before introducing a name in code, check `CONTEXT.md`. If the term isn't there and is domain-specific, surface it back to brainstorming rather than naming silently.

Full text: see the `karpathy-guidelines` skill.

## Checkpoint Discipline

After each plan step, write a short checkpoint before moving to the next:

- **Done:** what edits / state changes this step actually produced
- **Verified:** which checks passed (with the command + observed output)
- **Remaining:** the next concrete step

If you cannot write the checkpoint in 4 lines, you are not at a checkpoint — stop and reconstruct your state before continuing. Never start step N+1 from a state you cannot recount to yourself.

**Self-check before starting step N+1.** Ask yourself:

- [ ] Did I write a Done/Verified/Remaining checkpoint for step N? If no, write it now.
- [ ] Does *Verified* cite a command and its observed output, not just a claim? If no, re-run the verification.
- [ ] Does *Remaining* match what the plan says is next? If no, the plan and your state disagree — stop and reconcile.

If any box fails, do not advance. Cumulative drift across steps is the failure mode this exists to prevent.

See also: `token-budget-discipline` for when to checkpoint mid-step. Plan execution is the canonical trigger for budget discipline — if a single step spends more than the per-task soft budget, checkpoint and consider restart rather than pushing through.

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Write the Checkpoint Discipline summary (Done / Verified / Remaining)
5. Mark as completed

**TodoWrite vs Checkpoint Discipline are not the same thing.** TodoWrite tracks *which task* you are on; the Checkpoint summary records *what state the task left the codebase in*. Marking a TodoWrite item complete without writing the checkpoint is the failure this skill is designed to prevent — see Checkpoint Discipline above.

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
