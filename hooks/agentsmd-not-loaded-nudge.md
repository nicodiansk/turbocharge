## AGENTS.md May Not Be Loaded

By default, Claude Code counts `CLAUDE.local.md` as a CLAUDE.md, so in this project (`CLAUDE.local.md` and `AGENTS.md`, no `CLAUDE.md`) it skips `AGENTS.md` unless `CLAUDE.local.md` imports it.

If `CLAUDE.local.md`, already in your context, has an `@AGENTS.md` line, ignore this. Otherwise tell the user once: add an `@AGENTS.md` line to `CLAUDE.local.md`, or run `/turbocharge:setup` to create a team-shared `CLAUDE.md` that imports it. (If the Project instructions setting is `claude-md-and-agents-md`, AGENTS.md already loads — ignore this.)
