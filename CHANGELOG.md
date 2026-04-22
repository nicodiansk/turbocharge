# Changelog

## [2.5.2] - 2026-04-22

CodeMap + ATLAS enforcement at session start and wrap.

### Changed
- `hooks/session-start.sh`: injects CodeMap stats and usage reminder when `.codemap/` index is present — models now see the index on every session start, same as ATLAS.
- `skills/wrap/SKILL.md`: `@ATLAS.md` added to resume prompt template (was `@CLAUDE.md` only); section 5.5 Atlas Freshness made mandatory — always run `/turbocharge:atlas` and `codemap update` before ending a session, not conditional on "significant changes".

## [2.5.1] - 2026-04-15

Token waste fix for planner and researcher agents.

### Changed
- `planner.md`: replaced "read ATLAS.md first" with "do NOT re-read @-referenced files" — eliminates redundant ATLAS.md read on every plan invocation.
- `researcher.md`: same "do not re-read @-referenced files" instruction.
- `skills/plan/SKILL.md`: added token discipline rule — dispatch sends paths and line ranges only, not file contents (matches build skill pattern from v2.5.0).

## [2.5.0] - 2026-04-15

ATLAS gets smarter; token overhead trimmed.

### Added
- Lazy-load: SessionStart pre-loads only the Where to Look table; remaining sections available via Read on demand.
- Staleness detection: atlas generation writes a directory-listing hash (`<!-- atlas-hash:XXXX -->`); SessionStart compares it and nudges re-run if structure changed.
- Codemap integration: `/turbocharge:atlas` reads `.codemap/` JSON index (when present) to auto-populate Key Symbols and Module Map, cutting generation cost from ~20 tool calls to ~5.
- Setup audit: `/turbocharge:setup` now checks for global rules that duplicate turbocharge behavior and suggests consolidation.

### Changed
- `planner`, `researcher`, `code-reviewer` agents updated to reflect lazy-load (Where to Look in context, full file on demand).
- ATLAS.md template now includes `<!-- atlas-hash:XXXX -->` footer comment.
- Build skill: builder dispatch sends file paths + line ranges instead of full code blocks (~1-3K tokens saved per task).
- Debug skill: trimmed from 10.7KB to <7KB — removed verbose examples, redundant tables, meta-commentary.
- CLAUDE.md: ATLAS.md term updated to reflect lazy-load and staleness detection.

## [2.4.0] - 2026-04-14

ATLAS becomes core navigation layer; CLAUDE.md bootstrap gets a coherent chain.

### Added
- ATLAS pre-load: SessionStart hook cats `ATLAS.md` (if present) into context every session — navigation lookups cost zero tool calls after turn 1.
- Session snapshot: `/wrap` writes `.claude/turbocharge-session.json`; SessionStart cats it for zero-tool-call resume.
- `CLAUDE.md bootstrap` phase in `/turbocharge:setup` — auto-detects language/test command/package manager, asks ≤5 skippable questions, writes HTML-comment-delimited idempotent blocks.
- `templates/CLAUDE-turbocharge.md` — default values for the setup interview.
- `scripts/validate-atlas.sh` — ATLAS.md format check; wired into `scripts/validate.sh`.
- `scripts/tests/` — shell-based content-shape test harness.
- Memory discipline in `/wrap`: confidence+source metadata on bullets, 200-line cap with prune-before-build, session snapshot JSON.

### Changed
- ATLAS.md format reshaped to lookup-first tables (Where to Look, Entry Points, Module Map, Key Symbols, Integration Points, Conventions & Gotchas). Data Flows / Domain Model / Active Work sections removed.
- `planner`, `researcher`, `code-reviewer` agents now explicitly read ATLAS.md before exploration.
- `/turbocharge:plan` and `/turbocharge:review` inject `@ATLAS.md` + `@CLAUDE.md` into subagent dispatch prompts (subagents do not inherit parent history).
- `/turbocharge:build` injects `@CLAUDE.md` into builder/reviewer dispatches; only the on-demand researcher sub-dispatch gets `@ATLAS.md`.
- `hooks/missing-claudemd-nudge.md` tightened from 30 lines of manual copy-paste to a 2-line `/init → /turbocharge:setup` chain.
- `hooks/missing-atlasmd-nudge.md` tightened; notes pre-load behavior.
- `CLAUDE.md` (this repo) demoted inaccurate ATLAS claim to match new pre-load+dispatch-inject wording.

### Removed
- `PreToolUse` Read hook + `hooks/pretool-read-codemap.sh` — redundant once ATLAS is pre-loaded on every session.

### Migration
- Existing users: re-run `/turbocharge:atlas` to regenerate ATLAS.md in the new lookup-first format. Old ATLAS files still work but won't match the expected headers.

## [2.3.0] - 2026-04-13

Single-repo distribution — plugin and marketplace manifest now live together.

### Changed
- Restored `.claude-plugin/marketplace.json` as the authoritative marketplace manifest (previously in sibling `nicodiansk/turbocharge-marketplace` repo)
- Install command: `claude plugin marketplace add nicodiansk/turbocharge` (was `nicodiansk/turbocharge-marketplace`)
- Update command: `claude plugin update turbocharge@turbocharge` (was `turbocharge@turbocharge-marketplace`)
- README rewritten: ruflo-inspired structure, with vs without comparison, progressive disclosure via collapsible deep-dives
- CLAUDE.md Publishing Flow collapsed from 6 steps across 2 repos to 3 steps in one repo

### Removed
- Sibling `nicodiansk/turbocharge-marketplace` repo deleted — no longer needed

### Migration
- Existing users must re-add the marketplace: `claude plugin marketplace remove turbocharge-marketplace` then `claude plugin marketplace add nicodiansk/turbocharge`

## [2.2.0] - 2026-04-10

New skill: semantic domain mapping.

### Added
- `atlas` skill — generates and maintains ATLAS.md, a semantic domain map covering entry points, data flows, domain model, module purposes, integration points, and conventions
- Pipeline integration: session-bootstrap lists atlas, plan skill reads ATLAS.md for context, wrap skill nudges atlas refresh, setup skill checks for ATLAS.md

### Changed
- Plugin description updated to "10 skills, 6 agents"
- README updated with atlas documentation and revised pipeline diagram
- .gitignore updated to exclude `.codemap/` directory

## [2.1.0] - 2026-04-09

Pipeline hardening and operational discipline — driven by 91 sessions of real usage.

### Added
- `setup` skill — one-time config audit that finds duplicate agents, competing skills, and stale rules; offers to clean them up
- SessionStart hook — bootstraps skill awareness so Claude knows the pipeline exists from the first message
- Stop hook — reminds users to run `/turbocharge:wrap` before ending a session
- Anti-rationalization "Red Flags" tables in build, review, and debug skills — catches Claude skipping process steps
- Mandatory domain verification step in builder and planner agents

### Changed
- `wrap` skill now encodes session learnings into memory files and CLAUDE.md (not just resume prompts)
- README rewritten with install/usage/architecture sections
- CLAUDE.md updated with full plugin conventions and domain terms
- validate.sh now recognizes the `setup` skill and fixes a bash arithmetic bug with `((VAR++))` under `set -e`

### Removed
- `docs/power-user-guide.md` — content migrated to global rules and blog post draft

## [2.0.0] - 2026-03-19

Complete rebuild on native Claude Code primitives.

### Changed
- Rebuilt all agents as native subagents with `memory: project`, tool restrictions, and isolation
- Replaced 16 skills with 8 focused skills: brainstorm, story, plan, build, review, debug, ship, wrap
- Replaced custom `.turbocharge/memory/` system with native `memory: project` on all agents
- Replaced session-manager agent with `/turbocharge:wrap` skill
- Replaced baton-passing workflow with native subagent dispatch and Agent Teams
- Builder agent now runs in isolated worktree (`isolation: worktree`)
- TDD enforcement baked into builder agent (no longer a separate skill)
- Plugin manifest updated to v2.0.0

### Added
- `build` skill — orchestrates builder→spec-reviewer→quality-reviewer review chain
- `wrap` skill — session continuity with resume prompts
- `researcher` agent — fast, read-only codebase exploration (haiku model, background)
- Agent Teams support for multi-track parallel execution
- Stop hook reminding users to wrap sessions
- `settings.json` enabling experimental Agent Teams
- `marketplace.json` for self-hosted distribution
- `scripts/validate.sh` for plugin health checks
- `examples/` directory with sample pipeline outputs

### Removed
- 10 slash commands (skills now serve as commands via `/turbocharge:skillname`)
- `lib/skills-core.js` (custom skill dispatch infrastructure)
- `hooks/session-start.sh` (replaced by Stop hook)
- Agents: implementer (→ builder), story-writer (→ story skill), session-manager (→ wrap skill)
- Skills: using-turbocharge, session-memory, dispatching-parallel-agents, subagent-driven-development, verification-before-completion, receiving-code-review, test-driven-development, executing-plans, writing-skills, using-git-worktrees

## [1.0.0] - 2026-02-11

Initial release. 16 skills, 7 agents, 10 commands with baton-passing orchestration workflow.
