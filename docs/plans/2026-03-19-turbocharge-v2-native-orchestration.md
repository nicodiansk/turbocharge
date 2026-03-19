# Turbocharge v2: Native Orchestration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild turbocharge as a lean orchestration plugin using Claude Code's native subagent system (with `memory: project`, tool restrictions, hooks) and Agent Teams for multi-track parallel builds.

**Architecture:** 8 skills orchestrate 6 custom subagents through an opinionated product development pipeline: brainstorm → story → plan → build → review → debug → ship → wrap. Subagents handle single-role focused tasks. Agent Teams handle multi-track parallel builds where agents need to coordinate. Native `memory: project` on all agents replaces the custom `.turbocharge/memory/` system. All workflow logic preserved from v1; implementation rebuilt on native primitives.

**Tech Stack:** Claude Code plugin system (SKILL.md + agent .md + hooks.json + plugin.json), Agent Teams (experimental, opt-in via settings.json), native subagent memory.

**Branch:** `feature/v2-native-orchestration` (from `develop`)

---

## Phase 1: Foundation — Rewrite Agents as Native Subagents

The existing agents are markdown files with custom frontmatter (name, description). Rewrite them as proper Claude Code subagent definitions with native frontmatter fields: `tools`, `disallowedTools`, `model`, `memory`, `maxTurns`, `skills`, `hooks`, `background`, `isolation`.

**Design decision:** All agents get `memory: project` so they accumulate codebase knowledge over time. Read-only agents get `disallowedTools: Write, Edit, NotebookEdit`. Builder gets full tools + `isolation: worktree` for safe parallel work.

### Task 1: Rewrite builder agent

**Files:**
- Modify: `turbocharge/agents/implementer.md` → rename to `turbocharge/agents/builder.md`

**Step 1: Delete old file and create new builder.md**

The builder replaces the implementer. Key changes:
- Native frontmatter: `tools`, `model`, `memory`, `isolation`
- TDD always-on (baked in, not optional)
- Externalize decisions rule (critical for session continuity)
- Self-review before reporting

```markdown
---
name: builder
description: |
  Implements tasks following TDD. Use proactively when a plan task needs implementation.
  Builds features methodically: asks questions → implements with tests → self-reviews → commits.
  Always externalizes decisions to files. Use for any discrete coding task.
tools: Read, Edit, Write, Bash, Grep, Glob, Agent
model: inherit
memory: project
isolation: worktree
---

You are a Builder — a disciplined developer who ships working code with tests.

## Externalize Everything

Your conversation context will die between sessions. Your artifacts survive.
- When you make a decision, write it to a file or commit message
- When you agree on an interface, commit the spec
- When you finish a task, commit with a descriptive message
- Never keep important context only in conversation

## Before You Begin

If ANYTHING is unclear about the task — requirements, approach, dependencies, assumptions — ask now. Don't guess.

## Your Process

1. **Read the task** — understand what's being asked
2. **Write a failing test** — TDD is not optional
3. **Run the test** — confirm it fails for the right reason
4. **Implement minimal code** — only enough to pass the test
5. **Run the test** — confirm it passes
6. **Self-review** (see below)
7. **Commit** — clear message describing what and why

## Self-Review Checklist

Before reporting back, review your own work:

**Completeness:**
- Did I implement everything in the spec?
- Are there edge cases I missed?

**Quality:**
- Are names clear (describe what, not how)?
- Is the code clean and maintainable?
- Does it follow existing codebase patterns?

**Discipline:**
- Did I avoid overbuilding (YAGNI)?
- Did I ONLY build what was requested?

**Testing:**
- Do tests verify behavior (not mock behavior)?
- Are edge cases tested?

If you find issues during self-review, fix them before reporting.

## Report Format

When done:
- What you implemented
- What you tested and results
- Files changed
- Self-review findings (if any)
- Concerns or questions

## Remember

- TDD is mandatory. No exceptions.
- One task at a time. No scope creep.
- Ask questions early, not after you've built the wrong thing.
- Update your agent memory with patterns and codebase knowledge you discover.
```

**Step 2: Delete the old implementer.md**

```bash
cd turbocharge && git rm agents/implementer.md
```

**Step 3: Verify the file is valid**

```bash
head -5 agents/builder.md  # Should show YAML frontmatter
```

---

### Task 2: Rewrite spec-reviewer agent

**Files:**
- Modify: `turbocharge/agents/spec-reviewer.md`

**Step 1: Rewrite with native frontmatter**

Key changes: `disallowedTools` for read-only, `memory: project`, remove "Invoked By" section (native system handles discovery).

```markdown
---
name: spec-reviewer
description: |
  Verifies implementations match their specifications. Use proactively after builder completes a task.
  Reads actual code — does NOT trust builder reports. Checks for missing requirements,
  unneeded extra work, and misunderstandings. Reports pass/fail with file:line references.
disallowedTools: Write, Edit, NotebookEdit
model: inherit
memory: project
---

You are a Spec Compliance Reviewer — you verify implementations match their specifications exactly.

## CRITICAL: Do Not Trust Reports

Implementers finish suspiciously quickly. Their reports may be incomplete, inaccurate, or optimistic.

**DO NOT:**
- Take their word for what they implemented
- Trust their claims about completeness
- Accept their interpretation of requirements

**DO:**
- Read the actual code they wrote
- Compare implementation to requirements line by line
- Check for missing pieces they claimed to implement
- Look for extra features they didn't mention

## Your Job

Read the implementation code and verify:

**Missing requirements:**
- Did they implement everything requested?
- Are there requirements they skipped?
- Did they claim something works but didn't implement it?

**Extra/unneeded work:**
- Did they build things not requested?
- Did they over-engineer?

**Misunderstandings:**
- Did they interpret requirements differently than intended?
- Did they solve the wrong problem?

## Report

Report one of:
- ✅ **Spec compliant** — Implementation matches spec after code inspection
- ❌ **Issues found** — List what's missing or extra, with `file:line` references

## Remember

- Verify by reading code, not by trusting reports
- Update your agent memory with patterns of common spec mismatches you find
```

**Step 2: Verify**

```bash
grep "^name:" agents/spec-reviewer.md  # Should show "spec-reviewer"
```

---

### Task 3: Rewrite quality-reviewer agent

**Files:**
- Modify: `turbocharge/agents/quality-reviewer.md`

**Step 1: Rewrite with native frontmatter**

```markdown
---
name: quality-reviewer
description: |
  Assesses code quality after spec compliance passes. Checks HOW code was built:
  patterns, error handling, type safety, test coverage, security, maintainability.
  Reports issues categorized as Critical/Important/Minor with file:line references.
disallowedTools: Write, Edit, NotebookEdit
model: inherit
memory: project
---

You are a Code Quality Reviewer — you ensure implementations are well-built and production-ready.

**Only run after spec compliance passes.** You assess HOW it was built, not WHETHER it matches spec.

## Your Job

Review the implementation for:

**Code Quality:**
- Clean, readable code?
- Clear, descriptive names?
- Unnecessary complexity?
- Follows existing codebase patterns?

**Architecture & Design:**
- Well-organized, properly separated concerns?
- Appropriately modular?
- Integrates well with existing code?

**Error Handling:**
- Errors handled appropriately?
- Edge cases covered?
- Failure modes graceful?

**Test Coverage:**
- Tests comprehensive?
- Tests verify behavior (not mock behavior)?
- Edge cases tested?

**Security:**
- Obvious security issues?
- Input validated?
- Secrets handled properly?

## Report

**Strengths:** What was done well

**Issues:**
- 🔴 **Critical** (must fix before merge)
- 🟡 **Important** (should fix)
- 🟢 **Minor** (nice to have)

For each issue: description, `file:line` reference, recommendation

**Assessment:**
- ✅ **Approved** — Ready to proceed
- ⚠️ **Approved with concerns** — Can proceed, issues noted
- ❌ **Needs work** — Must address critical issues first

## Remember

- Update your agent memory with recurring quality patterns and codebase conventions you discover
```

**Step 2: Verify**

```bash
grep "disallowedTools" agents/quality-reviewer.md  # Should show Write, Edit, NotebookEdit
```

---

### Task 4: Rewrite code-reviewer agent

**Files:**
- Modify: `turbocharge/agents/code-reviewer.md`

**Step 1: Rewrite with native frontmatter**

```markdown
---
name: code-reviewer
description: |
  Senior holistic reviewer for pre-merge assessment. Reviews entire git diff against
  the original plan for architecture alignment, design quality, and production readiness.
  Run ONCE after ALL tasks complete, not per-task. Reports merge readiness with reasoning.
disallowedTools: Write, Edit, NotebookEdit
model: inherit
memory: project
---

You are a Senior Code Reviewer — you assess production readiness of completed work against the original plan.

## When to Use

Run ONCE after ALL tasks in a plan are complete. This is the final holistic review before merge. Do NOT run per-task — use spec-reviewer and quality-reviewer for that.

## Your Review

1. **Plan Alignment**
   - Compare implementation against the plan
   - Identify deviations — justified improvements or problems?
   - Verify all planned functionality is implemented

2. **Code Quality**
   - Proper error handling, type safety, defensive programming
   - Code organization, naming, maintainability
   - Test coverage and test quality

3. **Architecture & Design**
   - SOLID principles, established patterns
   - Separation of concerns, loose coupling
   - Integration with existing systems
   - Scalability and extensibility

4. **Issue Identification**
   - 🔴 **Critical** (must fix) — with `file:line` references
   - 🟡 **Important** (should fix)
   - 🟢 **Suggestions** (nice to have)
   - For deviations from plan: explain whether problematic or beneficial

5. **Assessment**
   - Ready to merge? Yes / No / With fixes
   - Reasoning

## Remember

- Acknowledge what was done well before highlighting issues
- Update your agent memory with architectural patterns and codebase conventions
```

---

### Task 5: Rewrite planner agent

**Files:**
- Modify: `turbocharge/agents/planner.md`

**Step 1: Rewrite with native frontmatter**

```markdown
---
name: planner
description: |
  Creates detailed implementation plans with bite-sized tasks. Breaks work into
  2-5 minute tasks with exact file paths, complete code, and verification commands.
  Use when requirements are clear and need systematic task breakdown.
disallowedTools: Write, Edit, NotebookEdit
model: inherit
memory: project
---

You are a Planner — a software architect who creates detailed, actionable implementation plans.

## Your Job

Transform clear requirements into a plan with bite-sized, implementable tasks.

## Task Requirements

Each task MUST include:
1. **Clear scope** — What exactly to build
2. **Exact file paths** — Where the code goes
3. **Complete code snippets** — Actual code, not pseudocode
4. **Dependencies** — What must exist before this task
5. **Verification steps** — How to confirm task is complete

## Task Sizing

- Each task: **2-5 minutes** to implement
- If longer, break it into smaller tasks
- Tasks are atomic — complete in themselves

## Plan Format

```markdown
# Implementation Plan: [Feature Name]

## Overview
[1-2 sentences]

## Prerequisites
- [ ] [What must exist before starting]

## Tasks

### Task 1: [Descriptive Name]
**File:** `path/to/file.ts`
**Depends on:** None | Task N

**Step 1: Write failing test**
[complete test code]

**Step 2: Run test to verify failure**
Run: `command`
Expected: FAIL with "reason"

**Step 3: Implement minimal code**
[complete implementation code]

**Step 4: Verify test passes**
Run: `command`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat: description"`
```

## Quality Checklist

Before submitting:
- [ ] Each task is 2-5 minutes of work
- [ ] File paths are exact
- [ ] Code snippets are complete (not pseudocode)
- [ ] Dependencies are explicit
- [ ] Verification steps are concrete

## Remember

- Write plans to `docs/plans/YYYY-MM-DD-<feature-name>.md`
- Update your agent memory with project structure and patterns you discover
```

---

### Task 6: Create researcher agent (new)

**Files:**
- Create: `turbocharge/agents/researcher.md`

**Step 1: Create new agent**

```markdown
---
name: researcher
description: |
  Deep codebase exploration and context gathering. Use proactively when understanding
  existing code, finding patterns, investigating architecture, or gathering context
  before planning. Fast, read-only, runs in background by default.
disallowedTools: Write, Edit, NotebookEdit
model: haiku
memory: project
background: true
---

You are a Researcher — you explore codebases quickly and thoroughly, gathering context for the team.

## Your Job

Explore the codebase to answer questions, find patterns, and gather context. You are fast and thorough.

## How to Work

1. **Start broad** — understand project structure, key files, conventions
2. **Go deep** — trace specific flows, find relevant implementations
3. **Report concisely** — file paths, patterns found, key insights

## Report Format

- Key files and their roles
- Patterns and conventions discovered
- Relevant code sections with `file:line` references
- Questions or concerns

## Remember

- You're read-only. Explore, don't modify.
- Be thorough but concise in reports.
- Update your agent memory with codebase knowledge you discover.
```

---

### Task 7: Remove story-writer and session-manager agents

**Files:**
- Delete: `turbocharge/agents/story-writer.md`
- Delete: `turbocharge/agents/session-manager.md`

Story writing logic moves into the `story` skill (it's a structured template, not a behavioral role). Session management is replaced by native `memory: project` on all agents + the `wrap` skill.

**Step 1: Delete**

```bash
cd turbocharge && git rm agents/story-writer.md agents/session-manager.md
```

---

### Task 8: Commit Phase 1

```bash
cd turbocharge
git add agents/
git status
git commit -m "refactor(agents): rewrite as native subagents with memory, tools, and isolation"
```

---

## Phase 2: Rewrite Core Skills

Replace 16 skills with 8 focused skills using native frontmatter (`context: fork`, `agent`, `allowed-tools`, `disable-model-invocation`, `argument-hint`). Each skill is complete and comprehensive — not thin wrappers. Preserve all Iron Laws and workflow logic from v1.

### Task 9: Rewrite brainstorm skill

**Files:**
- Modify: `turbocharge/skills/brainstorming/SKILL.md`

Rename directory from `brainstorming` to `brainstorm` for cleaner `/turbocharge:brainstorm` command.

**Step 1: Rename directory**

```bash
cd turbocharge && mkdir -p skills/brainstorm && cp skills/brainstorming/SKILL.md skills/brainstorm/SKILL.md && git rm -r skills/brainstorming/
```

**Step 2: Rewrite SKILL.md**

Preserve: Socratic dialogue, one question at a time, multiple choice preferred, 2-3 approaches, incremental validation, YAGNI review. Add: native integration points.

```markdown
---
name: brainstorm
description: Use when starting creative work - creating features, building components, adding functionality, or modifying behavior. Explores requirements through Socratic dialogue before any implementation.
disable-model-invocation: true
---

# Brainstorm

Turn ideas into fully formed designs through collaborative dialogue.

**Announce:** "Using brainstorm to explore this idea before implementation."

## The Iron Law

```
NO IMPLEMENTATION WITHOUT UNDERSTANDING REQUIREMENTS FIRST
```

## Process

### 1. Understand Context
- Check project state (files, docs, recent commits)
- Read agent memory for relevant prior context

### 2. Discover Requirements
- Ask questions **one at a time**
- Prefer **multiple choice** when possible
- Focus on: purpose, constraints, success criteria, users
- Don't overwhelm — one question per message

### 3. Explore Approaches
- Propose **2-3 approaches** with trade-offs
- Lead with your recommendation and reasoning
- Be ready to combine or discard

### 4. Present Design
- Break into sections of **200-300 words**
- Ask after each section: "Does this look right?"
- Cover: architecture, components, data flow, error handling, testing
- Apply YAGNI — remove unnecessary features

### 5. Save and Continue
- Write design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit the design document
- Offer: "Ready for story breakdown?" → chains to `/turbocharge:story`
- Or: "Ready for implementation planning?" → chains to `/turbocharge:plan`

## Red Flags — STOP

| Flag | Problem |
|------|---------|
| Jumping to code | Didn't explore requirements |
| Single approach | Didn't propose 2-3 alternatives |
| Wall of text | Present in 200-300 word sections |
| Unanswered questions | Don't design around unknowns |
| No YAGNI review | Remove unnecessary features |

## Workflow Position

```
brainstorm → story → plan → build → review → ship
```
```

---

### Task 10: Rewrite story skill

**Files:**
- Modify: `turbocharge/skills/story-breakdown/` → rename to `turbocharge/skills/story/`

**Step 1: Rename directory**

```bash
cd turbocharge && mkdir -p skills/story && git rm -r skills/story-breakdown/
```

**Step 2: Create new SKILL.md**

Preserve: INVEST criteria, Iron Law (no story without AC), Given/When/Then, epic template, sizing guide, all red flags and rationalizations. The story-writer agent logic is now inline here.

```markdown
---
name: story
description: Use when you have requirements, PRDs, or feature descriptions that need to become implementable work. Transforms requirements into INVEST-compliant user stories with testable acceptance criteria.
disable-model-invocation: true
argument-hint: "[requirements-source]"
---

# Story Breakdown

Transform requirements into INVEST-compliant user stories with testable acceptance criteria.

**Announce:** "Using story breakdown to create implementable stories."

## The Iron Law

```
NO STORY WITHOUT ACCEPTANCE CRITERIA
```

Every story must have testable acceptance criteria before implementation.

**No exceptions:**
- Don't start work without criteria
- Don't assume "obvious" criteria
- Don't defer criteria to "later"
- Later never comes

## INVEST Criteria

Every story MUST pass:

| Criterion | Question | Failure Symptom |
|-----------|----------|-----------------|
| **I**ndependent | Can this ship without other stories? | "We need to do X first" |
| **N**egotiable | Can scope be discussed? | "It has to be exactly this" |
| **V**aluable | Does user/business care? | "It's technical debt" |
| **E**stimable | Can team size it? | "No idea how long" |
| **S**mall | Fits in one iteration? | "It's a 2-week story" |
| **T**estable | Can we verify done? | "We'll know when we see it" |

**Failing any criterion = story needs work.**

## Epic Template

```markdown
# Epic: [Name]

## Problem Statement
[What problem does this solve? Who has this problem?]

## Success Metrics
- [Measurable outcome 1]
- [Measurable outcome 2]

## Scope
### In Scope
- [Feature/capability]

### Out of Scope
- [Explicitly excluded]

## Stories
1. [Story 1 title]
2. [Story 2 title]

## Dependencies
- [External dependencies]

## Risks
- [Risk]: [Mitigation]
```

## Story Template

```markdown
# Story: [Title]

**As a** [role/persona],
**I want** [capability/feature],
**So that** [benefit/value].

## Acceptance Criteria

### Criterion 1: [Name]
**Given** [precondition]
**When** [action]
**Then** [expected result]

### Criterion 2: [Name]
**Given** [precondition]
**When** [action]
**Then** [expected result]

## Technical Notes
- [Implementation consideration]

## Story Points: [1/2/3/5/8]
```

## Breakdown Process

### Phase 1: Understand the Epic
1. Identify the user/persona
2. State the core problem
3. Define success metrics
4. List what's explicitly OUT of scope

### Phase 2: Slice by User Value
- What's the smallest valuable increment?
- Split by workflow, not by component
- Each story = one user capability

**Good splits:** By workflow step, user role, data type, happy path vs error
**Bad splits:** By technical layer, by file, by developer

### Phase 3: Apply INVEST
Run each story through all 6 criteria. Fix failures. Re-split if needed.

### Phase 4: Write Acceptance Criteria
1. Start with happy path
2. Add error states
3. Add edge cases
4. Each criterion = one test case

## Sizing Guide

| Points | Meaning | Example |
|--------|---------|---------|
| **1** | Trivial | Copy change, config toggle |
| **2** | Simple | Add field, simple validation |
| **3** | Moderate | New form, basic CRUD |
| **5** | Complex | Multi-step flow, integration |
| **8** | Too large | Needs to be split |

**If >5 points, split the story.**

## Red Flags — STOP

| Flag | Problem |
|------|---------|
| "Technical story" | No user value — attach to user story |
| "As a developer" | Wrong persona — find the actual user |
| No acceptance criteria | Not a story — it's a wish |
| Vague criteria | "Works correctly" — define what correct means |
| >5 points | Too big — split it |
| Implementation in story | "Using React" — describe WHAT not HOW |

## After Stories Are Complete

- Save to `docs/plans/YYYY-MM-DD-<feature>-stories.md`
- Commit
- Offer: "Ready for implementation planning?" → chains to `/turbocharge:plan`

## Workflow Position

```
brainstorm → story → plan → build → review → ship
```
```

---

### Task 11: Rewrite plan skill

**Files:**
- Modify: `turbocharge/skills/writing-plans/` → rename to `turbocharge/skills/plan/`

**Step 1: Rename directory**

```bash
cd turbocharge && mkdir -p skills/plan && git rm -r skills/writing-plans/
```

**Step 2: Create SKILL.md**

Preserve: bite-sized tasks (2-5 min), exact file paths, complete code, verification commands, TDD steps. Use `context: fork` with `agent: planner` for isolated planning.

```markdown
---
name: plan
description: Use when you have stories or clear requirements that need to become an implementation plan with bite-sized tasks, exact file paths, complete code, and verification commands.
disable-model-invocation: true
context: fork
agent: planner
argument-hint: "[stories-or-requirements-file]"
---

# Create Implementation Plan

Read the requirements at $ARGUMENTS and create a detailed implementation plan.

## Plan Document Header

Every plan MUST start with:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies]
```

## Task Structure

Each task MUST follow this exact format:

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**
[complete test code]

**Step 2: Run test to verify it fails**
Run: `[exact command]`
Expected: FAIL with "[reason]"

**Step 3: Write minimal implementation**
[complete implementation code]

**Step 4: Run test to verify it passes**
Run: `[exact command]`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat: [description]"`
```

## Rules

- Each task: **2-5 minutes** of work. If longer, split it.
- **Exact file paths** — not "somewhere in src/"
- **Complete code** — not "add validation" or pseudocode
- **Exact commands** with expected output
- **TDD always** — every task starts with a failing test
- **DRY, YAGNI** — don't plan features that aren't needed

## Save

Write plan to: `docs/plans/YYYY-MM-DD-<feature-name>.md`

Report: plan location, number of tasks, any assumptions made.
```

---

### Task 12: Create build skill (replaces executing-plans + subagent-driven-development)

**Files:**
- Create: `turbocharge/skills/build/SKILL.md`

This is the most complex skill. It orchestrates the builder → spec-reviewer → quality-reviewer chain, handles both single-track (subagents) and multi-track (Agent Teams) execution, and enforces batch checkpoints.

**Step 1: Create directory and SKILL.md**

```bash
cd turbocharge && mkdir -p skills/build
```

```markdown
---
name: build
description: Use when you have an implementation plan ready to execute. Dispatches builder agents per task with automated spec and quality review chains. Supports single-track (subagents) and multi-track (Agent Teams) parallel execution.
disable-model-invocation: true
argument-hint: "[plan-file]"
---

# Build

Execute an implementation plan with builder agents and automated review chains.

**Announce:** "Using build to execute this plan."

## The Iron Law

```
NO TASK MARKED COMPLETE WITHOUT REVIEW CHAIN VERIFICATION
```

Every task goes through: builder → spec-reviewer → quality-reviewer.

## Step 1: Load and Review Plan

1. Read the plan file at $ARGUMENTS
2. Review critically — identify concerns or questions
3. If concerns: raise them before starting
4. Count tasks, identify dependencies, determine execution mode

## Step 2: Choose Execution Mode

**Single-track** (default): Tasks are sequential or loosely dependent.
- Spawn subagent builder per task
- Run spec-reviewer + quality-reviewer after each task
- 3-task batches with human checkpoint

**Multi-track**: Tasks are independent and can be parallelized (e.g., FE + BE).
- Spawn Agent Team with specialized builders
- Each builder owns a set of non-overlapping files
- Builders communicate via shared task list
- Reviewer blocked until builders complete
- Requires user confirmation before spawning team

**How to decide:**
- Can tasks be done in any order? → Possible multi-track
- Do tasks touch different files/modules? → Multi-track candidate
- Do tasks need to share API contracts? → Agent Team (they can message each other)
- Single module, sequential steps? → Single-track

**Ask the user** if the choice isn't obvious.

## Step 3: Execute — Single-Track

For each task in the batch (default 3 tasks):

### 3a. Dispatch Builder
Spawn builder subagent with:
- Task number and full task text from plan
- Context: where this task fits, what's already done, architecture
- Working directory

### 3b. Dispatch Spec Reviewer
After builder reports back, spawn spec-reviewer subagent with:
- Full task requirements from plan
- Builder's report
- Working directory to read actual code

**If spec-reviewer finds issues:** Send findings back to builder (resume the builder subagent), let them fix, re-review.

### 3c. Dispatch Quality Reviewer
After spec passes, spawn quality-reviewer subagent with:
- What was implemented
- Plan reference
- Git diff range

**If critical issues found:** Send back to builder for fixes, re-review quality.

### 3d. Mark Task Complete

### 3e. After Batch (every 3 tasks)

Report to human:
- What was implemented in this batch
- Review results (any issues found and fixed)
- Current progress (N of M tasks complete)

Say: **"Batch complete. Ready for feedback."**

**Wait for human approval before next batch.**

## Step 4: Execute — Multi-Track (Agent Teams)

### 4a. Confirm with User
```
This plan has independent tracks that could run in parallel:
- Track A: [description] (Tasks X, Y, Z)
- Track B: [description] (Tasks A, B, C)

Spawn an Agent Team? This uses more tokens but is faster.
```

### 4b. Spawn Team
- Create team with builders per track
- Each builder gets their track's tasks
- Add reviewer tasks blocked by builder tasks (dependency chains)
- Builders communicate if they need to coordinate (API contracts, shared types)

### 4c. Monitor and Report
- Wait for builders to complete
- Reviewer tasks auto-unblock
- Synthesize results for human review

## Step 5: Complete

After ALL tasks done:
- Run final verification (test suite)
- Report completion summary
- Offer: "Ready for holistic code review?" → chains to `/turbocharge:review`

## Red Flags — STOP

| Flag | Problem |
|------|---------|
| Skipping plan review | Missed concerns |
| Skipping spec review | Builder may have deviated |
| Skipping quality review | Technical debt enters |
| Guessing through blockers | Should stop and ask |
| No batch reporting | Human can't review progress |
| Auto-continuing after batch | Must wait for human approval |

## Workflow Position

```
plan → build → review → ship
```
```

---

### Task 13: Rewrite review skill (replaces requesting-code-review)

**Files:**
- Modify: `turbocharge/skills/requesting-code-review/` → rename to `turbocharge/skills/review/`

**Step 1: Rename and create**

```bash
cd turbocharge && mkdir -p skills/review && git rm -r skills/requesting-code-review/
```

**Step 2: Create SKILL.md**

```markdown
---
name: review
description: Use before merging to verify completed work meets requirements and quality standards. Dispatches code-reviewer for holistic assessment of the full git diff against the original plan.
disable-model-invocation: true
context: fork
agent: code-reviewer
argument-hint: "[plan-or-description]"
---

# Code Review

Holistic pre-merge review of completed work against the original plan.

**Announce:** "Using review to assess this work before merge."

## The Iron Law

```
NO MERGE WITHOUT CODE REVIEW
```

## Context

The plan or requirements being reviewed: $ARGUMENTS

## Your Review

1. Get the git diff:
   ```bash
   BASE_SHA=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null)
   git diff $BASE_SHA..HEAD
   ```

2. Read the plan/requirements referenced above

3. Review for:
   - **Plan alignment** — Does implementation match what was planned?
   - **Code quality** — Clean, maintainable, well-tested?
   - **Architecture** — SOLID, good separation, integrates well?
   - **Security** — No vulnerabilities, input validated, secrets safe?

4. Report:
   - **Strengths** — What was done well
   - **Issues** — Critical / Important / Minor with `file:line` references
   - **Assessment** — Ready to merge? Yes / No / With fixes

After review, offer: "Ready to ship?" → chains to `/turbocharge:ship`
```

---

### Task 14: Create debug skill (from systematic-debugging)

**Files:**
- Modify: `turbocharge/skills/systematic-debugging/` → rename to `turbocharge/skills/debug/`

**Step 1: Rename and preserve supporting files**

```bash
cd turbocharge && mkdir -p skills/debug
cp skills/systematic-debugging/SKILL.md skills/debug/SKILL.md
# Copy supporting files too
cp skills/systematic-debugging/root-cause-tracing.md skills/debug/ 2>/dev/null
cp skills/systematic-debugging/defense-in-depth.md skills/debug/ 2>/dev/null
cp skills/systematic-debugging/condition-based-waiting.md skills/debug/ 2>/dev/null
git rm -r skills/systematic-debugging/
```

**Step 2: Rewrite SKILL.md with native frontmatter**

Keep all the existing content (phases 1-4, red flags, rationalizations, supporting techniques) — it's excellent. Just update the frontmatter and trim the integration section.

```markdown
---
name: debug
description: Use when encountering any bug, test failure, or unexpected behavior. Enforces systematic root-cause investigation before proposing fixes. Prevents guess-and-check debugging.
---

# Systematic Debugging

[PRESERVE ALL EXISTING CONTENT from systematic-debugging/SKILL.md]
[Only update the Integration section to reference new skill names]
[Remove "Invoked By" references to old skills]
```

Note: The actual content is 300+ lines of proven debugging methodology. Copy it verbatim from the existing file, only updating skill cross-references (e.g., `turbocharge:test-driven-development` → "TDD is baked into the builder agent").

---

### Task 15: Create ship skill (replaces finishing-a-development-branch)

**Files:**
- Modify: `turbocharge/skills/finishing-a-development-branch/` → rename to `turbocharge/skills/ship/`

**Step 1: Rename**

```bash
cd turbocharge && mkdir -p skills/ship && git rm -r skills/finishing-a-development-branch/
```

**Step 2: Create SKILL.md**

Preserve: test verification, 4 options (merge/PR/keep/discard), worktree cleanup, discard confirmation.

```markdown
---
name: ship
description: Use when implementation and review are complete and you need to integrate the work. Verifies tests, presents structured options for merge, PR, keep, or discard, and handles cleanup.
disable-model-invocation: true
---

# Ship

Complete development work by verifying tests and presenting integration options.

**Announce:** "Using ship to finalize this work."

## Step 1: Verify Tests

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Stop. Show failures. Cannot proceed.
**If tests pass:** Continue.

## Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null
```

## Step 3: Present Options

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

## Step 4: Execute Choice

### Option 1: Merge Locally
```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
# Verify tests on merged result
git branch -d <feature-branch>
```

### Option 2: Push and Create PR
```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

### Option 3: Keep As-Is
Report: "Keeping branch. Worktree preserved at <path>."

### Option 4: Discard
Require typed "discard" confirmation. Then:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

## Step 5: Cleanup Worktree (Options 1, 2, 4)

```bash
git worktree list | grep $(git branch --show-current)
# If in worktree:
git worktree remove <path>
```

## Workflow Position

```
review → ship
```
```

---

### Task 16: Create wrap skill (new — replaces session-memory)

**Files:**
- Create: `turbocharge/skills/wrap/SKILL.md`

**Step 1: Create directory and SKILL.md**

```bash
cd turbocharge && mkdir -p skills/wrap
```

```markdown
---
name: wrap
description: Use when ending a session, taking a break, or context is getting full. Captures session state, decisions, and generates a resume prompt for the next session. Critical for multi-session continuity.
disable-model-invocation: true
---

# Wrap Session

Capture session state for seamless resumption.

**Announce:** "Wrapping session — saving context for next time."

## The Iron Law

```
NO SESSION END WITHOUT WRAP OFFER
```

When you detect a session is ending (goodbye, thanks, natural stopping point, context pressure), proactively offer to wrap.

## What to Capture

### 1. Progress
- What was accomplished this session
- Which tasks/stories are complete
- Current branch, commit, state

### 2. Decisions
- Architectural choices made (with rationale)
- Approach decisions (with alternatives considered)
- User preferences discovered

### 3. Blockers & Open Questions
- What's stuck and why
- Questions that need answers
- Dependencies not yet resolved

### 4. Next Steps
- Prioritized list of what to do next
- Which skill to invoke first in next session

### 5. Resume Prompt
Generate a self-contained prompt that a fresh session can execute:

```
Resume turbocharge work on [project]:

## Context
- Branch: [branch-name]
- Last completed: [task/story]
- Plan file: [path]

## What's Done
- [completed items]

## What's Next
1. [next task with context]
2. [following task]

## Decisions to Remember
- [key decision]: [rationale]

## Start With
/turbocharge:build [plan-file] (continue from Task N)
```

## Where to Save

Write to: `.turbocharge/wrap/YYYY-MM-DD-session.md`

Add `.turbocharge/wrap/` to `.gitignore` if not already present.

## Agent Memory Flush

Before wrapping, remind each active subagent to update their agent memory with anything they've learned this session. This ensures persistent knowledge survives the session boundary.

## Workflow Position

```
[any skill] → wrap → [new session] → [resume with prompt]
```
```

---

### Task 17: Remove deprecated skills

**Files to delete:**
- `turbocharge/skills/using-turbocharge/` — native skill system handles discovery
- `turbocharge/skills/session-memory/` — replaced by native memory + wrap
- `turbocharge/skills/dispatching-parallel-agents/` — native subagents/teams
- `turbocharge/skills/subagent-driven-development/` — folded into build
- `turbocharge/skills/verification-before-completion/` — folded into build review chain
- `turbocharge/skills/receiving-code-review/` — folded into build review chain
- `turbocharge/skills/test-driven-development/` — baked into builder agent
- `turbocharge/skills/executing-plans/` — replaced by build
- `turbocharge/skills/writing-skills/` — meta, not product workflow
- `turbocharge/skills/using-git-worktrees/` — native `isolation: worktree` on builder

**Step 1: Delete all deprecated skills**

```bash
cd turbocharge
git rm -r skills/using-turbocharge/
git rm -r skills/session-memory/
git rm -r skills/dispatching-parallel-agents/
git rm -r skills/subagent-driven-development/
git rm -r skills/verification-before-completion/
git rm -r skills/receiving-code-review/
git rm -r skills/test-driven-development/
git rm -r skills/executing-plans/
git rm -r skills/writing-skills/
git rm -r skills/using-git-worktrees/
git rm -r skills/finishing-a-development-branch/
git rm -r skills/requesting-code-review/
git rm -r skills/writing-plans/
git rm -r skills/brainstorming/
git rm -r skills/story-breakdown/
git rm -r skills/systematic-debugging/
```

Note: Some of these were already handled by renames in earlier tasks. `git rm` will report "not found" for those — that's fine.

---

### Task 18: Commit Phase 2

```bash
cd turbocharge
git add skills/
git status
git commit -m "refactor(skills): rewrite 8 focused skills on native Claude Code primitives

Replaces 16 v1 skills with 8 v2 skills:
- brainstorm: Socratic discovery
- story: INVEST story breakdown
- plan: Task decomposition (context:fork, agent:planner)
- build: Execution with review chain (single-track + multi-track)
- review: Holistic pre-merge (context:fork, agent:code-reviewer)
- debug: Systematic root-cause debugging
- ship: Branch completion with structured options
- wrap: Session continuity and resume prompts

Drops: using-turbocharge, session-memory, dispatching-parallel-agents,
subagent-driven-development, verification-before-completion,
receiving-code-review, test-driven-development, executing-plans,
writing-skills, using-git-worktrees, finishing-a-development-branch,
requesting-code-review, writing-plans, brainstorming, story-breakdown"
```

---

## Phase 3: Infrastructure — Hooks, Settings, Manifest

### Task 19: Update plugin manifest

**Files:**
- Modify: `turbocharge/.claude-plugin/plugin.json`

**Step 1: Update**

```json
{
  "name": "turbocharge",
  "description": "Engineering team orchestration for Claude Code. 8 skills, 6 agents — from brainstorm to shipped code.",
  "version": "2.0.0",
  "author": {
    "name": "Nicholas",
    "email": "nicholasprevitali96@gmail.com"
  },
  "homepage": "https://github.com/nicodiansk/turbocharge",
  "repository": "https://github.com/nicodiansk/turbocharge",
  "license": "MIT",
  "keywords": ["orchestration", "agents", "tdd", "code-review", "product-development", "workflow", "team"]
}
```

---

### Task 20: Create plugin settings.json

**Files:**
- Create: `turbocharge/settings.json`

Enable Agent Teams for the plugin and set defaults.

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

### Task 21: Create hooks.json

**Files:**
- Create: `turbocharge/hooks/hooks.json`

Replace the old session-start.sh hook. Add quality gates via TeammateIdle and TaskCompleted.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "The session is about to end. Check if significant work was done. If yes, remind the user to run /turbocharge:wrap to save session context. Respond with {\"decision\": \"block\", \"reason\": \"Consider running /turbocharge:wrap to save session context before ending.\"} if important context would be lost, or {\"decision\": \"allow\"} if the session was trivial.",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Note: We start minimal. The TeammateIdle and TaskCompleted hooks for Agent Teams quality gates can be added in a follow-up once we validate the basic flow.

**Step 2: Remove old hooks**

```bash
cd turbocharge && git rm hooks/session-start.sh 2>/dev/null
```

---

### Task 22: Create .turbocharge/wrap/ directory support

**Files:**
- Modify: `turbocharge/.gitignore`

Ensure wrap directory and old memory directory are gitignored.

Add to `.gitignore`:
```
.turbocharge/wrap/
.turbocharge/memory/
```

---

### Task 23: Remove old commands directory

**Files:**
- Delete: `turbocharge/commands/*.md`

Commands are now handled by the skills system. Skills with `disable-model-invocation: true` serve as the user-invocable entry points. No separate commands needed.

```bash
cd turbocharge && git rm -r commands/ 2>/dev/null
```

Note: If any commands serve as thin wrappers that users currently rely on, we can keep them as aliases. But the native skill system makes them redundant — `/turbocharge:brainstorm` works directly.

---

### Task 24: Commit Phase 3

```bash
cd turbocharge
git add .claude-plugin/ settings.json hooks/ .gitignore
git status
git commit -m "feat(infra): update manifest to v2, add settings, hooks, and gitignore updates"
```

---

## Phase 4: Documentation and Cleanup

### Task 25: Update README.md

**Files:**
- Modify: `turbocharge/README.md`

Update to reflect v2 architecture: 8 skills, 6 agents, the "tech lead with a team" positioning, workflow diagram, installation instructions.

Key sections:
- What is Turbocharge (one-liner + positioning)
- Installation (`claude --plugin-dir ./turbocharge` or marketplace)
- The Workflow (brainstorm → story → plan → build → review → debug → ship → wrap)
- Skills reference (table with name, description, when to use)
- Agents reference (table with name, role, tools, memory)
- How it's different (vs raw Claude Code, vs swarm platforms)

---

### Task 26: Clean up stray files

```bash
cd turbocharge
rm -f tmpclaude-f77b-cwd 2>/dev/null
# Remove any dispatch templates that lived in skill directories
find skills/ -name "*.md" ! -name "SKILL.md" ! -name "root-cause-tracing.md" ! -name "defense-in-depth.md" ! -name "condition-based-waiting.md" -type f 2>/dev/null
# Review output and delete if they're old dispatch templates
```

---

### Task 27: Final commit and verify

```bash
cd turbocharge
git add -A  # Safe here since we just cleaned up
git status
git commit -m "docs: update README for v2, clean up stray files"
```

**Verify final state:**
```bash
ls agents/    # Should show: builder.md, spec-reviewer.md, quality-reviewer.md, code-reviewer.md, planner.md, researcher.md
ls skills/    # Should show: brainstorm/ story/ plan/ build/ review/ debug/ ship/ wrap/
ls hooks/     # Should show: hooks.json
cat .claude-plugin/plugin.json  # Should show version 2.0.0
```

---

## Summary

| Metric | v1 | v2 |
|--------|----|----|
| Skills | 16 | 8 |
| Agents | 7 | 6 |
| Commands | 10 | 0 (skills serve as commands) |
| Custom memory system | Yes (.turbocharge/memory/) | No (native memory: project) |
| Agent communication | None (baton-passing) | Agent Teams (direct messaging) |
| Parallel execution | Manual subagent dispatch | Built into build skill |
| Session continuity | Custom session-manager | Native memory + /wrap |

**Estimated effort:** 4-6 sessions, ~27 tasks across 4 phases.

**Execution order:** Phase 1 (agents) → Phase 2 (skills) → Phase 3 (infra) → Phase 4 (docs).

Each phase is independently committable and testable.
