---
name: setup
description: Run once after installing turbocharge. Audits global config for conflicts — duplicate agents, competing skills, stale rules — and offers to fix them. Also validates turbocharge plugin health.
disable-model-invocation: true
---

# Setup Turbocharge

One-time audit and cleanup to make turbocharge your single orchestration system.

**Announce:** "Running turbocharge setup — auditing your config for conflicts."

## The Goal

Turbocharge replaces ad-hoc agents, scattered skills, and custom commands with one pipeline. This setup finds and removes the overlap so Claude doesn't get confused about which system to use.

## Audit Steps

### 1. Check for Competing Agents

Scan `~/.claude/agents/` for agent definitions that overlap with turbocharge agents:

| Turbocharge Agent | Conflicts With |
|-------------------|----------------|
| builder | tdd-guide, implementer |
| planner | planner, architect |
| code-reviewer | code-reviewer |
| researcher | explorer, investigator |
| spec-reviewer | — |
| quality-reviewer | — |

Also check for: session-wrapper, session-wrap, build-error-resolver (covered by turbocharge:debug)

**Action:** List conflicts and offer to delete them. Explain what turbocharge agent replaces each one.

### 2. Check for Duplicate Skills/Commands

Scan `.claude/commands/` (project level) for commands that overlap with turbocharge skills:

| Turbocharge Skill | Conflicts With |
|-------------------|----------------|
| wrap | session-wrap, wrap-up, session-wrapper |
| story | story-author, user-story, story-writer |
| plan | task-breakdown, plan-tasks, task-planner |
| review | code-review |
| build | implement, implement-story |
| brainstorm | brainstorm (if non-turbocharge) |
| debug | debug, troubleshoot |

**Action:** List conflicts with file paths. Offer to delete duplicates. Flag any that have unique functionality turbocharge doesn't cover (recommend keeping those).

### 3. Check agents.md Rule

Read `~/.claude/rules/common/agents.md` (if exists):
- Does it reference turbocharge as the primary system? **Good.**
- Does it list phantom agents (agents not in `~/.claude/agents/`)? **Bad — offer to rewrite.**
- Does it reference both turbocharge AND other agent systems? **Bad — offer to consolidate.**

**Action:** If agents.md doesn't point to turbocharge, offer to replace it with the turbocharge-aware version:
```markdown
# Agent Orchestration
## Primary System: Turbocharge Plugin
All orchestration goes through the turbocharge plugin...
```

### 4. Check for Plugin Conflicts

Read `~/.claude/settings.json` and check `enabledPlugins`:
- Are there disabled plugins cluttering the config? Offer to remove.
- Are there other orchestration plugins enabled alongside turbocharge (superpowers, everything-claude-code)? Warn about conflicts.

### 5. Validate Turbocharge Plugin Health

Run the validation script if available:
```bash
./scripts/validate.sh
```

Or manually check:
- All 10 skills have SKILL.md files
- All 6 agents have .md files
- hooks/hooks.json exists
- .claude-plugin/plugin.json exists and has correct version

### 6. Check Global Rules Alignment

Scan `~/.claude/rules/common/` for rules that conflict with turbocharge's iron laws:
- Testing rules should include "never ask permission to run tests"
- Development workflow should include "verify understanding before coding"
- Coding style should include a completion gate
- Reviews should require comprehensive scope by default

**Action:** List missing rules and offer to add them.

### 7. Check for Global Rules / Turbocharge Overlap

Scan `~/.claude/rules/common/` for files that duplicate what turbocharge skills already enforce:

| Global Rule File | Overlaps With | Recommendation |
|------------------|---------------|----------------|
| `agents.md` | turbocharge pipeline (SessionStart bootstrap) | Keep only the "Primary System: Turbocharge Plugin" header + pipeline table. Remove agent dispatch details — turbocharge skills handle dispatch. |
| `development-workflow.md` | turbocharge:plan, turbocharge:build | Remove TDD steps and plan-first sections — builder.md and planner.md enforce these. Keep only git workflow and research steps. |
| `testing.md` | builder.md TDD mandate | Remove TDD workflow section — builder.md is the single source. Keep coverage targets and test types. |

**Action:** For each overlap found, show the user what's duplicated and offer to trim. Don't delete files — trim the overlapping sections and keep unique content.

**Why this matters:** Every global rule file is loaded into context on every turn (~4 bytes/token). Duplicate instructions between rules and turbocharge skills waste ~2,000 tokens per session and can cause conflicting guidance.

## CLAUDE.md Phase

Run this phase after the conflict audit completes and before the final report.

### 1. Auto-Detect (no questions)

Probe the project root for these files and extract values:

| Signal | Inspect | Extract |
|--------|---------|---------|
| `package.json` | `scripts.test`, `scripts.lint`, top-level `name` | test command, lint command, project name |
| `pyproject.toml` | `[tool.poetry]`, `[project]`, `[tool.pytest.ini_options]` | language (Python), test framework |
| `Cargo.toml` | `[package].name`, `[dev-dependencies]` | language (Rust), test runner |
| `go.mod` | `module` line | language (Go), module path |
| `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` | presence | package manager |
| Primary entry | `src/index.*`, `main.*`, `cmd/*/main.go` | entry-point file |

Do not ask the user about anything detectable.

### 2. Interview (≤5 questions, each skippable)

Ask at most these five, each with `[skip]` producing the template default:

1. **Test discipline** — Strict TDD / Tests-alongside / Tests-when-reasonable
2. **File-header convention** — ABOUTME / JSDoc-style / None
3. **Naming style** — camelCase / snake_case / mixed-by-language
4. **Debug protocol strictness** — Always 4-phase / Non-trivial only
5. **Project-specific domain terms** — free text; empty skips the block

The interview must be completable in under 90 seconds.

### 3. Render and Append

Read `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE-turbocharge.md`. Substitute answers (test command, naming style, file-header convention, domain terms). Each block is delimited by `<!-- turbocharge:NAME -->` and `<!-- /turbocharge:NAME -->`.

- If CLAUDE.md exists and contains a block with the same marker → replace between markers, leave surrounding content untouched.
- If CLAUDE.md exists and does not contain that block → append to end of file.
- If CLAUDE.md does not exist → suggest `/init` first, do not create a bare CLAUDE.md from the template alone.

### 4. Show Diff, Confirm, Write

Always show the diff and ask for confirmation before writing. Never modify CLAUDE.md silently.

### 5. Size Guard

After writing, if CLAUDE.md exceeds 180 lines, warn the user and suggest extracting personal rules to `~/.claude/CLAUDE.md`.

### 6. Chain Forward

If ATLAS.md does not exist, offer: `/turbocharge:atlas` to generate the navigation index. This closes the bootstrap loop: `/init → /turbocharge:setup → /turbocharge:atlas`.

## Report Format

```
TURBOCHARGE SETUP AUDIT
=======================

Plugin Health: ✅ OK (10 skills, 6 agents, hooks configured)

Conflicts Found:
  🔴 ~/.claude/agents/session-wrapper-agent.md → covered by turbocharge:wrap
  🔴 .claude/commands/story-author.md → covered by turbocharge:story
  🟡 agents.md references phantom agents, not turbocharge

Recommendations:
  1. Delete ~/.claude/agents/session-wrapper-agent.md
  2. Delete .claude/commands/story-author.md
  3. Rewrite agents.md to reference turbocharge

No Conflicts:
  ✅ .claude/commands/epic-author.md — unique, keep
  ✅ .claude/commands/consistency-review.md — unique, keep

Apply fixes? [list specific changes, ask for confirmation]
```

## After Setup

Offer to chain:
- `/turbocharge:brainstorm` if user has an idea to explore
- `/turbocharge:plan` if user has requirements ready
- Nothing if user just wanted the audit

## Red Flags

Do NOT:
- Delete files without listing them first and getting confirmation
- Modify CLAUDE.md without showing the diff
- Assume any file is "safe to delete" — always explain what replaces it
- Skip the audit steps to "save time"
