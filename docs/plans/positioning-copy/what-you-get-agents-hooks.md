**Six agents** — dispatched by skills, never invoked directly:

| Agent | Role |
|-------|------|
| `builder` | TDD implementation in an isolated worktree. |
| `planner` | Decomposes stories into tasks; verifies entity names against the codebase. |
| `researcher` | Fast codebase exploration on Haiku, runs in the background. |
| `spec-reviewer` | Reads the task spec and the diff. Doesn't take builder's word. |
| `quality-reviewer` | Categorized code quality issues. Blocks completion on CRITICAL. |
| `code-reviewer` | Holistic pre-merge pass against the original plan. |

**Three hooks** — fire on lifecycle events, not on request:

- `SessionStart` — bootstraps context, flags missing `CLAUDE.md` / `ATLAS.md`.
- `PreToolUse` on `Read` — nudges `.codemap/` usage when an index exists.
- `Stop` — reminds you to `/wrap` before the session ends.
