## AGENTS.md Not Loaded

This project has `CLAUDE.local.md` and `AGENTS.md` but no `CLAUDE.md`. Claude Code counts `CLAUDE.local.md` as a CLAUDE.md, so it skips `AGENTS.md`: those instructions are not in this session.

Add an `@AGENTS.md` line to `CLAUDE.local.md`, or run `/turboflow:setup` to create a team-shared `CLAUDE.md` that imports it. (If your Project instructions setting is `claude-md-and-agents-md`, AGENTS.md already loads — ignore this.)
