# Changelog

## [2.7.2] - 2026-06-23

Directory-readiness — leaner SessionStart payload, read-only hook attestation.

### Changed
- `hooks/session-bootstrap.md`: replaced the 10-row skill table with a one-line pipeline summary + `/help` pointer. Standing per-session context cost ~434 → ~306 tokens (~30% lighter; the skill table duplicated descriptions Claude Code already loads). Red Flags and Critical Rules retained — they add anti-rationalization behavior Claude Code's skill descriptions don't. All 10 skills still named (pipeline line + red flags).
- `hooks/session-start.sh`: header now attests the hook is read-only (stdout only, no writes, no network) for plugin-directory safety screening.

## [2.7.1] - 2026-06-23

README visuals refresh — value/positioning diagram, terminal mockups, accurate build chain.

### Added
- `images/before-after.svg`: scattered-config vs. single-pipeline diagram, embedded under the README intro.
- `images/brainstorm-session.svg`: hand-authored terminal mockup of a brainstorm session (announce → dialogue → captured doc → chain-forward).
- `images/build-review-chain.svg`: accurate SVG of default vs. `--reviewed` task execution (2–6 spawns/task on the failure path); replaces the ASCII diagrams in "How Build Works".
- `README.md`: "Why a Pipeline" section sharpening the positioning.
- `scripts/tests/t_svg_roster_counts.sh`: asserts each SVG's "N skills · N agents · N hooks" tagline matches ground truth (skills/agents from `plugin.json`, hooks from `hooks.json`) — guards against the next stale-count regression.

### Changed
- `CLAUDE.md`: document the planner's deliberate `model: inherit` carve-out (rides the orchestrator model, ≥ Sonnet in normal use) so it no longer reads as a contradiction of the Sonnet-floor rule.

### Fixed
- `images/hero-banner-v2.svg`: agent count corrected 6 → 5 (missed in the 2.7.0 roster update; now matches `plugin.json` and the README badge).

### Removed
- `images/build-review-chain.png` (orphaned and stale — depicted the `spec-reviewer`/`quality-reviewer` agents removed in 2.7.0) and `images/story-output.png` (orphaned, unreferenced). Replaced by version-controlled SVGs.

## [2.7.0] - 2026-06-23

Lean review pipeline — planner self-review, single Sonnet task-reviewer, Sonnet floor, build UX.

### Added
- `agents/planner.md`: mandatory Spec Self-Review 3-point checklist (spec coverage + add missing tasks, placeholder scan, type consistency) run inline before the plan is written.
- `agents/task-reviewer.md` (NEW, Sonnet): reads a task diff once and emits two verdicts — `Spec: ✅/❌` and `Quality: Approved/Issues found`. Replaces the spec-reviewer + quality-reviewer pair.
- `skills/build/SKILL.md`: `--checkpoint=N` flag (default 3; `0` / `--no-checkpoint` disables the batch wait) and a per-batch + completion visibility line (`agents spawned: A · models: sonnet×A · tasks: X/Y`).
- `CLAUDE.md`: "Sonnet minimum, never Haiku" agent-model convention.

### Changed
- `agents/researcher.md`: model changed from Haiku to Sonnet.
- `skills/build/SKILL.md`: Reviewed mode now spawns one Sonnet task-reviewer per task (two verdicts, one diff-load) instead of two reviewers — 2 spawns/task instead of 3.
- `README.md`, `images/model-tiering.svg`: updated to the Sonnet-floor roster; agent count 6 → 5.

### Removed
- `agents/spec-reviewer.md` and `agents/quality-reviewer.md` (merged into `task-reviewer`).

### Performance
- Reviewed build: 2 spawns per task (was 3), all Sonnet. One diff-load instead of two.
- No agent runs Haiku — turn count beats token price.

## [2.6.1] - 2026-05-20

Fix: session snapshot always on first line of resume prompt.

### Fixed
- `skills/wrap/SKILL.md`: `@.claude/turbocharge-session.json` moved from "Context Files" list onto the first line of the resume prompt template — it is now fixed and mandatory, not a variable placeholder. Added explicit MANDATORY note to prevent Claude from omitting it.

## [2.6.0] - 2026-05-20

Lean Builder v3 — simpler, faster, cheaper build pipeline.

### Changed
- `agents/builder.md`: model changed from inherit (Opus) to Sonnet; worktree isolation removed — builder works in main tree.
- `agents/spec-reviewer.md`: model changed from inherit to Haiku.
- `agents/quality-reviewer.md`: model changed from inherit to Haiku.
- `agents/code-reviewer.md`: model changed from inherit to Sonnet.
- `skills/build/SKILL.md`: review chain (spec-reviewer + quality-reviewer) now opt-in via `--reviewed` flag, not mandatory. Default mode is builder-only with self-review. Leaner dispatch — plan file:line pointers instead of context dumps. Frontmatter description and argument-hint updated.

### Performance
- Default build: 1 agent spawn per task (was 3-5). ~70% token reduction.
- Reviewed build: 3 spawns per task on Haiku/Sonnet (was 3-5 on Opus). ~30% additional token + cost reduction.
- Builder runs on Sonnet (98% of Opus coding capability at 1/5 cost, 2x speed).
- No worktree overhead.

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
