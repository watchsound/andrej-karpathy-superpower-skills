# Andrej Karpathy × Superpowers Skills

A personal fork of [obra/superpowers](https://github.com/obra/superpowers) that bakes Andrej Karpathy's anti-LLM-slop principles into each skill, adds a runtime ubiquitous-language ritual to prevent semantic drift, and introduces a small number of new skills for failure modes that show up in long-running agent work.

> **This is a personal fork**, not affiliated with the upstream maintainers. Changes here may diverge from upstream design decisions and have not been adversarially eval'd to the upstream's bar. For the canonical project, see [obra/superpowers](https://github.com/obra/superpowers) and [README_ORIGINAL.md](./README_ORIGINAL.md).

## Motivation

Superpowers gives agents disciplined workflows (TDD, brainstorming, systematic debugging, plan-driven execution). What it doesn't yet encode is the *moment-to-moment* failure modes [Karpathy described in January 2026](https://x.com/karpathy/status/2015883857489522876):

> "The models make wrong assumptions on your behalf and just run along with them without checking. They don't manage their confusion, don't seek clarifications, don't surface inconsistencies, don't present tradeoffs, don't push back when they should. They really like to overcomplicate code and APIs, bloat abstractions..."

[Forrest Chang's distillation](https://github.com/forrestchang/andrej-karpathy-skills) of those observations into four rules — *think before coding, simplicity first, surgical changes, goal-driven execution* — works as a CLAUDE.md preamble. But a preamble competes with skill content for attention budget, and it doesn't fire at the moment a specific skill is running.

**This fork bakes the four rules into each skill's body**, so the discipline is invoked exactly when the skill fires. It also adds a small set of rules targeting agent-loop failure modes (token budgets, deterministic-code boundary, test quality, checkpoint discipline) and a runtime-built glossary mechanism adapted from [mattpocock/skills](https://github.com/mattpocock/skills) to prevent semantic drift across long sessions.

## What's Added

### Three new skills

- **`karpathy-guidelines`** — verbatim vendor of forrestchang's 4-rule CLAUDE.md (MIT). Loads on demand so the full rule text is available to any skill that cross-references it.
- **`prefer-deterministic-code`** — refuses to wrap an LLM call around a question with a deterministic answer (routing, retries, status codes, validation, type checks). Reserves LLM calls for unstructured language work only.
- **`token-budget-discipline`** — explicit per-task and per-session budgets with checkpoint-and-restart discipline, to bound agent loops that would otherwise spend themselves into a 50K-token context dump.

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

### `CLAUDE_APPEND.md` (personal engineering standard)

A short add-on for your project-level or user-global `CLAUDE.md` that introduces a **mandatory response format** for any code-modifying response:

- `Discovered Issues` — bugs and risks noticed in adjacent code, listed (not fixed) so they can be triaged.
- `Assumptions Made` — every assumption taken to proceed, with `(critical)` markers on the load-bearing ones.

This turns invisible discipline (the four Karpathy rules) into a visible artifact at the end of every response.

## Installation

```bash
# Add the marketplace
/plugin marketplace add watchsound/andrej-karpathy-superpower-skills

# Install
/plugin install superpowers@superpowers-dev
```

If the upstream `superpowers` plugin is already installed, **uninstall it first** to avoid duplicate auto-trigger conflicts:

```bash
/plugin uninstall superpowers
```

Restart Claude Code so the SessionStart hook fires and `using-superpowers` bootstraps.

## Verification

In a fresh session, send:

> "Let's design a small order book for an A-share trading system."

Expected behavior:

- `brainstorming` fires (not direct code generation).
- The Ubiquitous Language block surfaces — the agent looks for `CONTEXT.md` and proposes creating one if absent.
- The agent asks to disambiguate "order" (trading order vs purchase order vs work order) before proposing any design.
- The four Karpathy rules are surfaced as the lens for the rest of the conversation.

If none of that happens, the plugin's SessionStart hook didn't fire — restart Claude Code or confirm `/plugin list` shows the fork.

## Attribution

- Original **Superpowers** project: [Jesse Vincent](https://blog.fsck.com) and Prime Radiant — [obra/superpowers](https://github.com/obra/superpowers).
- **Karpathy guidelines** distillation: [Forrest Chang](https://github.com/forrestchang/andrej-karpathy-skills).
- **CONTEXT.md format and ritual**: [Matt Pocock](https://github.com/mattpocock/skills).
- Original **Karpathy observations** on LLM coding pitfalls: [@karpathy on X](https://x.com/karpathy/status/2015883857489522876).

All upstream content is MIT-licensed; attribution is preserved in vendored files.

For the full upstream documentation, philosophy section, and per-harness install instructions (Codex CLI, Gemini CLI, OpenCode, Cursor, GitHub Copilot CLI, Factory Droid), see [README_ORIGINAL.md](./README_ORIGINAL.md).

## License

MIT — see [LICENSE](./LICENSE). All vendored content retains its original MIT terms and attribution.
