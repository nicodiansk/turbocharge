## AGENTS.md Not Loaded

This project has `CLAUDE.local.md` and `AGENTS.md` but no `CLAUDE.md`. Claude Code counts `CLAUDE.local.md` as a CLAUDE.md, so it skips `AGENTS.md`: those instructions are not in this session.

Add `@AGENTS.md` as the first line of `CLAUDE.local.md`, or run `/turboflow:setup` to create a team-shared `CLAUDE.md` that imports it.
