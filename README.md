# Turbocharge

One plugin. One pipeline. No conflicts.

## The Problem

You have 6 agents in `~/.claude/agents/`, 4 custom commands, 3 rule files that contradict each other, and a `planner-actually-good.md` you wrote at 2 AM. Claude picks whichever one it finds first. You can't remember which is current. Neither can Claude.

Turbocharge replaces all of it with a single opinionated pipeline: 10 skills, 6 agents, 2 hooks. One system to install, nothing to maintain.

## Install

Run these inside the Claude Code REPL (not your shell):

```
claude plugin marketplace add nicodiansk/turbocharge
claude plugin install turbocharge@turbocharge
```

Restart Claude Code, then run `/turbocharge:setup` to audit your config for conflicts.

Update: `claude plugin update turbocharge@turbocharge`

Local dev: `claude --plugin-dir ./turbocharge`

## The Pipeline

```
brainstorm → story → plan → build → review → ship
                                  ↑               |
                                debug            wrap
                                  ↑
                                atlas (any point)
```

Enter at any step. Each skill gates the next.

| Skill | What it does |
|-------|-------------|
| `setup` | Audits config for conflicting agents/skills/rules. Bootstraps `CLAUDE.md`. |
| `atlas` | Generates `ATLAS.md` domain map from the actual codebase. Pre-loaded every session. |
| `brainstorm` | Explores requirements before implementation. Design doc out. |
| `story` | INVEST-compliant stories with testable acceptance criteria. |
| `plan` | 2-5 minute TDD tasks with exact file paths and verification commands. |
| `build` | Dispatches builder → spec-reviewer → quality-reviewer chain per task. |
| `review` | Holistic pre-merge review of full diff against the plan. |
| `debug` | Four-phase root-cause investigation. No fix until cause is proven. |
| `ship` | Verifies tests pass, then merge / PR / discard. |
| `wrap` | Captures session state, decisions, learnings. Resume prompt for next session. |

## How Build Works

Every task goes through a mandatory review chain:

```
builder → spec-reviewer → quality-reviewer
              ↓ issues?        ↓ issues?
         back to builder   back to builder
         (max 2 cycles)    (max 2 cycles)
```

You can't mark a task complete without passing both reviews.

## Agents

Dispatched by skills. You never invoke them directly.

| Agent | Role |
|-------|------|
| `builder` | TDD implementation in isolated worktree |
| `planner` | Task breakdown; verifies entity names against the codebase |
| `researcher` | Fast codebase exploration (Haiku, background) |
| `spec-reviewer` | Reads the spec and the diff. Doesn't take builder's word. |
| `quality-reviewer` | Code quality assessment. Blocks on CRITICAL issues. |
| `code-reviewer` | Pre-merge review against the original plan |

## Hooks

- **SessionStart** — loads `ATLAS.md` into context (zero-tool-call navigation), restores session snapshot from last `/wrap`, flags missing `CLAUDE.md` / `ATLAS.md`.
- **Stop** — reminds you to `/wrap`.

## What to Remove After Installing

`/turbocharge:setup` handles this, but in short:

- Delete agents in `~/.claude/agents/` that overlap (planner, code-reviewer, tdd-guide, session-wrappers)
- Delete commands in `.claude/commands/` for story-authoring, task-breakdown, session-wrap
- Point `~/.claude/rules/common/agents.md` at turbocharge, not a list of competing agents

## License

MIT — see [LICENSE](LICENSE).
