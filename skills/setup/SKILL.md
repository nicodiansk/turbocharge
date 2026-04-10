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

### 7. Check for Project Atlas

Check if `ATLAS.md` exists in the project root:
- **Exists:** pass "ATLAS.md found — domain map available"
- **Missing:** suggest "No ATLAS.md found — run `/turbocharge:atlas` to generate a domain map for faster context gathering"

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
