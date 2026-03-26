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

**If spec-reviewer finds issues:** Send findings back to builder (resume the builder subagent), let them fix, re-review. **Max 2 review cycles per task** — if still failing after 2 rounds, stop and surface the issue to the user.

### 3c. Dispatch Quality Reviewer
After spec passes, spawn quality-reviewer subagent with:
- What was implemented
- Plan reference
- Git diff range

**If critical issues found:** Send back to builder for fixes, re-review quality. **Max 2 review cycles per task** — escalate to user if unresolved.

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
| Review loop >2 cycles | Escalate to user, don't keep retrying |

## Workflow Position

```
plan → build → review → ship
```
