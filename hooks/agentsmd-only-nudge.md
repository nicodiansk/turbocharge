## AGENTS.md Detected, No CLAUDE.md

Claude Code reads `AGENTS.md` only while no `CLAUDE.md` exists, so adding a CLAUDE.md that does not import it would silently stop AGENTS.md from loading.

Run `/turboflow:setup` — it creates `CLAUDE.md` with `@AGENTS.md` as the first line (both files load), then appends turboflow's rule blocks. If you write CLAUDE.md yourself, start it with `@AGENTS.md`.
