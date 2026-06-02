# Personal Engineering Standard

Append this block to project-level CLAUDE.md, or load it as a user-global instruction. It assumes the Karpathy guidelines (think-before-coding, simplicity-first, surgical-changes, goal-driven-execution) and the superpowers skill set are already in effect; this file adds only what they do not cover.

## Mandatory Response Format

When a response modifies code, end with these two sections. Omit a section if it would be empty — never invent entries to fill them.

### Discovered Issues

Bugs, smells, or risks noticed in code adjacent to the task. **Do not fix them in this change.** List them here so they can be triaged as separate work.

Format:
- `<file:line>` — short description of the issue and why it matters.

### Assumptions Made

Any assumption taken to proceed instead of asking. One bullet per assumption. Mark with **(critical)** any assumption whose wrongness would invalidate the change.

Format:
- Assumed *X*, because *Y*. **(critical)** if a wrong guess here breaks the work.

## Reasoning Transparency

When a change is non-obvious — an architectural choice, a tradeoff, anything a reviewer would ask "why?" about — include one or two sentences of reasoning alongside the diff. Not what the code does (the code shows that), but *why this approach over the obvious alternative*.

Skip the reasoning note for mechanical changes (rename, typo, formatting fix).
