---
name: build
description: Use when you have an implementation plan ready to execute. Dispatches builder agents (Sonnet) per task with self-review. Opt-in review chain (spec + quality reviewers on Haiku) for high-risk tasks. Supports single-track and multi-track parallel execution.
argument-hint: "[plan-file] [--reviewed]"
---

# Build

Execute an implementation plan with builder agents and automated review chains.

**Announce:** "Using build to execute this plan."

## The Iron Law

```
NO TASK MARKED COMPLETE WITHOUT BUILDER SELF-REVIEW AND PASSING TESTS
```

## Step 1: Load and Review Plan

1. Read the plan file at $ARGUMENTS
2. Review critically — identify concerns or questions
3. If concerns: raise them before starting
4. Count tasks, identify dependencies, determine execution mode
5. Check if `--reviewed` is in $ARGUMENTS — if so, enable review chain for all tasks

## Step 2: Choose Execution Mode

**Standard** (default): Builder implements each task with self-review. No separate reviewer agents.
- Spawn builder (Sonnet) per task
- Builder self-reviews using its built-in checklist
- 3-task batches with human checkpoint

**Reviewed** (`--reviewed` flag, or user says "with reviews"): For high-risk, security-sensitive, or unfamiliar codebases.
- Same as Standard, plus: spec-reviewer (Haiku) + quality-reviewer (Haiku) after each task
- Leaner dispatch: pass plan file path + task line range + git diff only — no narrative summaries
- Max 2 review cycles per task — escalate to user if unresolved

**Multi-track**: Independent tasks that can be parallelized (e.g., FE + BE).
- Spawn Agent Team with specialized builders
- Each builder owns a set of non-overlapping files
- Builders communicate via shared task list
- Reviewer blocked until builders complete
- Requires user confirmation before spawning team

**How to decide:**
- Default to Standard — covers 80% of tasks
- Use Reviewed for: unfamiliar codebase, security-sensitive code, complex integrations
- Use Multi-track for independent tracks touching different files
- When in doubt, start Standard — user can always run `/turbocharge:review` after

**Ask the user** if the choice isn't obvious.

## Step 3: Execute — Standard

For each task in the batch (default 3 tasks):

### 3a. Dispatch Builder
Spawn builder subagent (Sonnet) with:
- Task number and description (objective, file paths, line ranges, verification commands)
- Plan file path and task line range — do NOT paste plan content, builder reads the file directly
- Context: where this task fits in the sequence, what previous tasks completed
- Working directory
- Prefix: `@CLAUDE.md` (conventions). Do NOT inject `@ATLAS.md` — builders read the spec and diff, not the navigation index.

### 3b. Mark Task Complete

### 3c. After Batch (every 3 tasks)

Report to human:
- What was implemented in this batch
- Current progress (N of M tasks complete)

Say: **"Batch complete. Ready for feedback."**

**Wait for human approval before next batch.**

## Step 4: Execute — Reviewed

Same as Step 3, with these additions after each builder completes:

### 4a. Dispatch Spec Reviewer
Spawn spec-reviewer subagent (Haiku) with:
- Plan file path + task line range (reviewer reads the plan directly — do NOT paste requirements)
- Working directory to read actual code
- Do NOT send the builder's narrative report — reviewer reads code, not claims

**If spec-reviewer finds issues:** Resume the builder subagent with findings, re-review. **Max 2 cycles** — if still failing, escalate to user.

### 4b. Dispatch Quality Reviewer
After spec passes, spawn quality-reviewer subagent (Haiku) with:
- File paths changed
- Git diff range (`git diff HEAD~1..HEAD`)
- Do NOT send implementation summaries — reviewer reads code directly

**If critical issues found:** Resume builder with findings, re-review quality. **Max 2 cycles** — escalate to user if unresolved.

### 4c. Dispatch Researcher (on demand)
If the builder blocks on unclear context, dispatch the researcher with `@ATLAS.md @CLAUDE.md` prefixed. Subagents do not inherit parent history — `@ATLAS.md` must ride on the dispatch prompt itself.

### 4d. Mark Task Complete

### 4e. After Batch (every 3 tasks)

Report to human:
- What was implemented in this batch
- Review results (issues found and fixed)
- Current progress (N of M tasks complete)

Say: **"Batch complete. Ready for feedback."**

**Wait for human approval before next batch.**

## Step 5: Execute — Multi-Track (Agent Teams)

### 5a. Confirm with User
```
This plan has independent tracks that could run in parallel:
- Track A: [description] (Tasks X, Y, Z)
- Track B: [description] (Tasks A, B, C)

Spawn an Agent Team? This uses more tokens but is faster.
```

### 5b. Spawn Team
- Create team with builders per track
- Each builder gets their track's tasks
- Add reviewer tasks blocked by builder tasks (dependency chains)
- Builders communicate if they need to coordinate (API contracts, shared types)

### 5c. Monitor and Report
- Wait for builders to complete
- Reviewer tasks auto-unblock
- Synthesize results for human review

## Step 6: Complete

After ALL tasks done:
- Report completion summary
- Offer: "Ready for holistic code review?" → chains to `/turbocharge:review`

## Red Flags — STOP

### Process Violations
| Flag | Problem |
|------|---------|
| Skipping plan review | Missed concerns |
| Skipping builder self-review | Builder has a checklist — use it |
| Skipping Reviewed mode for security-sensitive code | Save tokens, lose safety |
| Using Reviewed mode for trivial tasks | Wastes tokens on mechanical checks |
| Guessing through blockers | Should stop and ask |
| No batch reporting | Human can't review progress |
| Auto-continuing after batch | Must wait for human approval |
| Review loop >2 cycles | Escalate to user, don't keep retrying |

### Rationalizations That Mean You're Wrong

If you catch yourself thinking any of these, **STOP:**

| Thought | Why It's Wrong |
|---------|----------------|
| "Self-review is enough for this security-sensitive task" | Security tasks need Reviewed mode — self-review misses attack vectors |
| "I'll skip the batch checkpoint, we're on a roll" | Human oversight exists for a reason — never skip |
| "Running the full test suite is overkill for this change" | The 1-line change that broke 47 tests says otherwise |
| "I'll verify it works manually" | Manual verification is not verification |
| "Let me just finish this batch and review later" | Later never comes. Checkpoint every batch. |
| "I can skip domain verification, the task description is clear" | Clear descriptions still use wrong entity names half the time |

## Workflow Position

```
plan → build → review → ship
```
