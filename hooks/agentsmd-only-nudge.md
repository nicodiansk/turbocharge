## AGENTS.md Detected, No CLAUDE.md

By default, Claude Code (v2.1.277 or later) reads `AGENTS.md` only while no `CLAUDE.md` exists, so adding a CLAUDE.md that does not import it would silently stop AGENTS.md from loading (unless the Project instructions setting is `claude-md-and-agents-md`, which loads both). Older versions read it only through an import.

Run `/turbocharge:setup` — it creates `CLAUDE.md` with `@AGENTS.md` as the first line (both files load), then appends turbocharge's rule blocks. If you write CLAUDE.md yourself, start it with `@AGENTS.md`.
