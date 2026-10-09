---
name: setup
description: Run once after installing turboflow. Audits global config for conflicts — duplicate agents, competing skills, stale rules — and offers to fix them. Also validates turboflow plugin health.
disable-model-invocation: true
---

# Setup Turboflow

One-time audit and cleanup to make turboflow your single orchestration system.

**Announce:** "Running turboflow setup — auditing your config for conflicts."

## The Goal

Turboflow replaces ad-hoc agents, scattered skills, and custom commands with one pipeline. This setup finds and removes the overlap so Claude doesn't get confused about which system to use.

## Audit Steps

### 1. Check for Competing Agents

Scan `~/.claude/agents/` for agent definitions that overlap with turboflow agents:

| Turboflow Agent | Conflicts With |
|-------------------|----------------|
| builder | tdd-guide, implementer |
| planner | planner, architect |
| code-reviewer | code-reviewer |
| researcher | explorer, investigator |
| task-reviewer | spec-reviewer, quality-reviewer |

Also check for: session-wrapper, session-wrap, build-error-resolver (covered by turboflow:debug)

**Action:** List conflicts and offer to delete them. Explain what turboflow agent replaces each one.

### 2. Check for Duplicate Skills/Commands

Scan `.claude/commands/` (project level) for commands that overlap with turboflow skills:

| Turboflow Skill | Conflicts With |
|-------------------|----------------|
| wrap | session-wrap, wrap-up, session-wrapper |
| story | story-author, user-story, story-writer |
| plan | task-breakdown, plan-tasks, task-planner |
| review | code-review |
| build | implement, implement-story |
| brainstorm | brainstorm (if non-turboflow) |
| debug | debug, troubleshoot |

**Action:** List conflicts with file paths. Offer to delete duplicates. Flag any that have unique functionality turboflow doesn't cover (recommend keeping those).

### 3. Check agents.md Rule

Read `~/.claude/rules/common/agents.md` (if exists):
- Does it reference turboflow as the primary system? **Good.**
- Does it list phantom agents (agents not in `~/.claude/agents/`)? **Bad — offer to rewrite.**
- Does it reference both turboflow AND other agent systems? **Bad — offer to consolidate.**

**Action:** If agents.md doesn't point to turboflow, offer to replace it with the turboflow-aware version:
```markdown
# Agent Orchestration
## Primary System: Turboflow Plugin
All orchestration goes through the turboflow plugin...
```

### 4. Check for Plugin Conflicts

Run `claude plugin list --json` to enumerate installed plugins and their enable state, then read `~/.claude/settings.json` `enabledPlugins`:
- Are there disabled plugins cluttering the config? Offer to remove.
- Scan the installed-plugins list for competing **orchestration plugins** (e.g. superpowers, everything-claude-code) enabled alongside turboflow — not just duplicate definitions in `~/.claude/agents/`. Warn about conflicts and explain the overlap.

### 5. Validate Turboflow Plugin Health

Run `claude plugin details turboflow` to confirm the plugin is installed, enabled, and to see its standing token cost. Then run the validation script if available:
```bash
./scripts/validate.sh
```

Or manually check:
- All 10 skills have SKILL.md files
- All 5 agents have .md files
- hooks/hooks.json exists
- .claude-plugin/plugin.json exists and has correct version

### 6. Check Global Rules Alignment

Scan `~/.claude/rules/common/` for rules that conflict with turboflow's iron laws:
- Testing rules should include "never ask permission to run tests"
- Development workflow should include "verify understanding before coding"
- Coding style should include a completion gate
- Reviews should require comprehensive scope by default

**Action:** List missing rules and offer to add them.

### 7. Check for Global Rules / Turboflow Overlap

Scan `~/.claude/rules/common/` for files that duplicate what turboflow skills already enforce:

| Global Rule File | Overlaps With | Recommendation |
|------------------|---------------|----------------|
| `agents.md` | turboflow pipeline (SessionStart bootstrap) | Keep only the "Primary System: Turboflow Plugin" header + pipeline table. Remove agent dispatch details — turboflow skills handle dispatch. |
| `development-workflow.md` | turboflow:plan, turboflow:build | Remove TDD steps and plan-first sections — builder.md and planner.md enforce these. Keep only git workflow and research steps. |
| `testing.md` | builder.md TDD mandate | Remove TDD workflow section — builder.md is the single source. Keep coverage targets and test types. |

**Action:** For each overlap found, show the user what's duplicated and offer to trim. Don't delete files — trim the overlapping sections and keep unique content.

**Why this matters:** Every global rule file is loaded into context on every turn (~4 bytes/token). Duplicate instructions between rules and turboflow skills waste ~2,000 tokens per session and can cause conflicting guidance.

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

Read `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE-turboflow.md`. Substitute answers (test command, naming style, file-header convention, domain terms). Each block is delimited by `<!-- turboflow:NAME -->` and `<!-- /turboflow:NAME -->`.

- If CLAUDE.md exists, `AGENTS.md` also exists, and CLAUDE.md has no `@AGENTS.md` line → offer to add `@AGENTS.md` as its first line. Claude Code ignores AGENTS.md whenever a CLAUDE.md exists, so without the import its instructions never load. Leave the file unchanged if the user declines.
- If CLAUDE.md exists and contains a block with the same marker → replace between markers, leave surrounding content untouched.
- If CLAUDE.md exists and does not contain that block → append to end of file.
- If CLAUDE.md does not exist but `AGENTS.md` does → create CLAUDE.md with `@AGENTS.md` as its first line, then append the rendered blocks below it. Claude Code reads AGENTS.md only while no CLAUDE.md exists, so this import is what keeps AGENTS.md loading once CLAUDE.md is created.
- If neither CLAUDE.md nor AGENTS.md exists → suggest `/init` first, do not create a bare CLAUDE.md from the template alone.

### 4. Show Diff, Confirm, Write

Always show the diff and ask for confirmation before writing. Never modify CLAUDE.md silently.

### 5. Size Guard

After writing, if CLAUDE.md exceeds 180 lines, warn the user and suggest extracting personal rules to `~/.claude/CLAUDE.md`.

### 6. Chain Forward

If ATLAS.md does not exist, offer: `/turboflow:atlas` to generate the navigation index. This closes the bootstrap loop: `/init → /turboflow:setup → /turboflow:atlas`.

## Report Format

```
TURBOFLOW SETUP AUDIT
=======================

Plugin Health: ✅ OK (10 skills, 5 agents, hooks configured)

Conflicts Found:
  🔴 ~/.claude/agents/session-wrapper-agent.md → covered by turboflow:wrap
  🔴 .claude/commands/story-author.md → covered by turboflow:story
  🟡 agents.md references phantom agents, not turboflow

Recommendations:
  1. Delete ~/.claude/agents/session-wrapper-agent.md
  2. Delete .claude/commands/story-author.md
  3. Rewrite agents.md to reference turboflow

No Conflicts:
  ✅ .claude/commands/epic-author.md — unique, keep
  ✅ .claude/commands/consistency-review.md — unique, keep

Apply fixes? [list specific changes, ask for confirmation]
```

## After Setup

Offer to chain:
- `/turboflow:brainstorm` if user has an idea to explore
- `/turboflow:plan` if user has requirements ready
- Nothing if user just wanted the audit

## Red Flags

Do NOT:
- Delete files without listing them first and getting confirmation
- Modify CLAUDE.md without showing the diff
- Assume any file is "safe to delete" — always explain what replaces it
- Skip the audit steps to "save time"
