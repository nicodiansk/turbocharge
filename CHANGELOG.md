# Changelog

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
