# Lean Builder v3 Implementation Plan

**Goal:** Simplify the builder pipeline — drop worktree isolation, make review chain opt-in, add model tiering across all agents.
**Architecture:** Change agent frontmatter (model + isolation), rewrite build skill to default to builder-only mode with opt-in review chain, bump version.
**Tech Stack:** Markdown agent definitions, JSON manifests (no compiled code)

## Context

Builder is too slow, too expensive, and worktree isolation causes confusion. Superpowers (197K stars) validates two-stage review but uses model tiering (Haiku for mechanical review, Sonnet for implementation). We adopt the same strategy while making the review chain opt-in rather than mandatory.

**Key metrics (current → target):**
- Spawns per task: 3-5 → 1 (default) or 3 (with reviews)
- Builder model: Opus (inherited) → Sonnet
- Reviewer models: Opus (inherited) → Haiku
- Token waste: ~18K/8-task feature → ~5K (estimated)

## Tasks

### Task 1: Agent model tiering — builder, spec-reviewer, quality-reviewer, code-reviewer

**Files:**
- Modify: `agents/builder.md` (lines 1-11 frontmatter)
- Modify: `agents/spec-reviewer.md` (lines 1-10 frontmatter)
- Modify: `agents/quality-reviewer.md` (lines 1-10 frontmatter)
- Modify: `agents/code-reviewer.md` (lines 1-10 frontmatter)

**Changes:**

`agents/builder.md` frontmatter — change `model: inherit` to `model: sonnet`, remove `isolation: worktree`:
```yaml
---
name: builder
description: |
  Implements tasks following TDD. Use proactively when a plan task needs implementation.
  Builds features methodically: asks questions -> implements with tests -> self-reviews -> commits.
  Always externalizes decisions to files. Use for any discrete coding task.
tools: Read, Edit, Write, Bash, Grep, Glob
model: sonnet
memory: project
---
```

`agents/spec-reviewer.md` frontmatter — change `model: inherit` to `model: haiku`:
```yaml
---
name: spec-reviewer
description: |
  Verifies implementations match their specifications. Use proactively after builder completes a task.
  Reads actual code — does NOT trust builder reports. Checks for missing requirements,
  unneeded extra work, and misunderstandings. Reports pass/fail with file:line references.
disallowedTools: Write, Edit, NotebookEdit
model: haiku
memory: project
---
```

`agents/quality-reviewer.md` frontmatter — change `model: inherit` to `model: haiku`:
```yaml
---
name: quality-reviewer
description: |
  Assesses code quality after spec compliance passes. Checks HOW code was built:
  patterns, error handling, type safety, test coverage, security, maintainability.
  Reports issues categorized as Critical/Important/Minor with file:line references.
disallowedTools: Write, Edit, NotebookEdit
model: haiku
memory: project
---
```

`agents/code-reviewer.md` frontmatter — change `model: inherit` to `model: sonnet`:
```yaml
---
name: code-reviewer
description: |
  Senior holistic reviewer for pre-merge assessment. Reviews entire git diff against
  the original plan for architecture alignment, design quality, and production readiness.
  Run ONCE after ALL tasks complete, not per-task. Reports merge readiness with reasoning.
disallowedTools: Write, Edit, NotebookEdit
model: sonnet
memory: project
---
```

**Note:** `agents/researcher.md` already has `model: haiku` — no change needed.

**Verification:** Read each file's frontmatter and confirm model values: builder=sonnet, spec-reviewer=haiku, quality-reviewer=haiku, code-reviewer=sonnet, researcher=haiku.

---

### Task 2: Rewrite build skill — default builder-only, review chain opt-in

**Files:**
- Modify: `skills/build/SKILL.md` (frontmatter + body rewrite)

**Changes:**

**2a. Update frontmatter description and argument-hint:**

Current:
```yaml
description: Use when you have an implementation plan ready to execute. Dispatches builder agents per task with automated spec and quality review chains. Supports single-track (subagents) and multi-track (Agent Teams) parallel execution.
argument-hint: "[plan-file]"
```

New:
```yaml
description: Use when you have an implementation plan ready to execute. Dispatches builder agents (Sonnet) per task with self-review. Opt-in review chain (spec + quality reviewers on Haiku) for high-risk tasks. Supports single-track and multi-track parallel execution.
argument-hint: "[plan-file] [--reviewed]"
```

**2b. Replace the Iron Law** from:
```
NO TASK MARKED COMPLETE WITHOUT REVIEW CHAIN VERIFICATION
```
To:
```
NO TASK MARKED COMPLETE WITHOUT BUILDER SELF-REVIEW AND PASSING TESTS
```

Replace Step 2 (Choose Execution Mode) to add review chain opt-in:
```markdown
## Step 2: Choose Execution Mode

**Standard** (default): Builder implements each task with self-review. No separate reviewer agents.
- Spawn builder (Sonnet) per task
- Builder self-reviews using its built-in checklist
- 3-task batches with human checkpoint

**Reviewed**: User requests "with reviews" or tasks are high-risk.
- Same as Standard, plus: spec-reviewer (Haiku) + quality-reviewer (Haiku) after each task
- Leaner dispatch: pass plan file path + task line range + git diff only — no narrative summaries
- Max 2 review cycles per task — escalate to user if unresolved

**Multi-track**: Independent parallel tasks (same as current, unchanged).

**How to decide:**
- Default to Standard — it covers 80% of tasks
- Use Reviewed for: unfamiliar codebase, security-sensitive code, complex integrations
- Use Multi-track for independent tracks touching different files
- When in doubt, start Standard — user can always run `/turbocharge:review` after
```

Replace Step 3 (Execute — Single-Track) to reflect leaner dispatch:
```markdown
## Step 3: Execute

For each task in the batch (default 3 tasks):

### 3a. Dispatch Builder
Spawn builder subagent (Sonnet) with:
- Task number and description (objective, file paths, line ranges, verification commands)
- Plan file path and line range for the task (builder reads the actual file — do NOT paste plan content)
- Context: where this task fits in the sequence, what previous tasks completed
- Working directory
- Prefix: `@CLAUDE.md` (conventions). Do NOT inject `@ATLAS.md` — builders read the spec and diff.

### 3b. Review (only in Reviewed mode)
After builder reports back:
1. Dispatch spec-reviewer (Haiku) with: plan file path + task line range, working directory. No builder narrative — reviewer reads actual code.
2. If spec passes, dispatch quality-reviewer (Haiku) with: file paths changed, git diff range. No summaries — reviewer reads actual code.
3. If either finds issues: send findings back to builder (resume subagent), re-review. Max 2 cycles.

### 3c. Mark Task Complete

### 3d. After Batch (every 3 tasks)
Report to human:
- What was implemented in this batch
- Review results (if Reviewed mode)
- Current progress (N of M tasks complete)

Say: **"Batch complete. Ready for feedback."**

**Wait for human approval before next batch.**
```

Update Red Flags table — replace "Skipping spec review" and "Skipping quality review" entries:
```markdown
| Skipping self-review | Builder has a checklist — use it |
| Using Reviewed mode for trivial tasks | Wastes tokens on mechanical checks |
| NOT using Reviewed mode for security-sensitive code | Save tokens, lose safety |
```

Update the rationalizations table — replace "This task is simple, I don't need the review chain":
```markdown
| "This task is simple, self-review is enough" | True for most tasks. But security-sensitive or integration-heavy tasks need Reviewed mode |
| "I'll skip the batch checkpoint, we're on a roll" | Human oversight exists for a reason — never skip |
```

**Verification:** Read the full SKILL.md and confirm: default is builder-only, review chain requires explicit opt-in, dispatch instructions reference plan file:line-range (not context dumps), model names match (Sonnet for builder, Haiku for reviewers).

---

### Task 3: Update CLAUDE.md agent description table

**Files:**
- Modify: `CLAUDE.md` (no structural changes, just accuracy)

**Changes:**

The CLAUDE.md doesn't have an agent table, but the description says "6 agents" and references the builder having worktree isolation. Scan for any mention of `worktree` or `isolation` and remove/update it. No other CLAUDE.md changes needed since the agent count stays at 6.

**Verification:** Grep CLAUDE.md for "worktree" — should return zero matches after edit.

---

### Task 4: Version bump and changelog

**Files:**
- Modify: `.claude-plugin/plugin.json` (version: "2.5.2" → "2.6.0")
- Modify: `.claude-plugin/marketplace.json` (metadata.version + plugins[0].version: "2.5.2" → "2.6.0")
- Modify: `CHANGELOG.md` (add entry at top)

**Changes:**

Version bump to 2.6.0 (minor: behavioral change to build pipeline defaults).

Changelog entry:
```markdown
## [2.6.0] - 2026-05-20

Lean Builder v3 — simpler, faster, cheaper build pipeline.

### Changed
- `agents/builder.md`: model changed from inherit (Opus) to Sonnet; worktree isolation removed (builds in main tree).
- `agents/spec-reviewer.md`: model changed from inherit to Haiku.
- `agents/quality-reviewer.md`: model changed from inherit to Haiku.
- `agents/code-reviewer.md`: model changed from inherit to Sonnet.
- `skills/build/SKILL.md`: review chain (spec-reviewer + quality-reviewer) now opt-in, not mandatory. Default mode is builder-only with self-review. Leaner dispatch — plan file:line pointers instead of context dumps.

### Performance
- Default build: 1 agent spawn per task (was 3-5). ~70% token reduction.
- Reviewed build: 3 spawns per task on Haiku/Sonnet (was 3-5 on Opus). ~30% token + cost reduction.
- No worktree overhead — builder works in main tree.
```

**Verification:** Read both JSON files and confirm all three version fields are "2.6.0". Read CHANGELOG.md and confirm new entry is at top.

---

## Summary

| Task | Files | Complexity |
|------|-------|------------|
| 1. Agent model tiering | 4 agent .md files | Low — frontmatter edits |
| 2. Build skill rewrite | 1 skill SKILL.md (frontmatter + body) | Medium — structural rewrite |
| 3. CLAUDE.md accuracy | 1 file | Low — grep + minor edit |
| 4. Version bump + changelog | 3 files | Low — value changes |

**Total: 4 tasks, 9 files, ~15-20 minutes.**

No tests to run (plugin is markdown + JSON). Validation is reading changed files and confirming consistency.

---

## Post-Build Follow-Up (not part of this plan)

**Global rules update:** `~/.claude/rules/common/agents.md` has a "Review Chain (Every Task)" section that says `builder → spec-reviewer → quality-reviewer` is mandatory. After this plan ships, update that section to reflect the new opt-in default:

```markdown
### Review Chain (Opt-In per Task)

Default: builder self-reviews and commits.
With `--reviewed` flag: builder → spec-reviewer (Haiku) → quality-reviewer (Haiku).
```

This is a user-global file, not a plugin file, so it's out of scope for this version bump but must be updated to avoid contradicting the plugin behavior.
