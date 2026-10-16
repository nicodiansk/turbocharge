## AGENTS.md May Not Be Loaded

This project has `CLAUDE.local.md` and `AGENTS.md` but no `CLAUDE.md`. Claude Code counts `CLAUDE.local.md` as a CLAUDE.md, so it skips `AGENTS.md` unless `CLAUDE.local.md` imports it.

If `CLAUDE.local.md`, already in your context, has an `@AGENTS.md` line, ignore this. Otherwise tell the user once: add an `@AGENTS.md` line to `CLAUDE.local.md`, or run `/turbocharge:setup` to create a team-shared `CLAUDE.md` that imports it. (If the Project instructions setting is `claude-md-and-agents-md`, AGENTS.md already loads — ignore this.)
