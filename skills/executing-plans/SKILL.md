---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use turbocharge:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Red Flags - STOP

| Flag | Problem |
|------|---------|
| Skipping plan review | Missed concerns or ambiguities |
| Not following plan steps | Deviating without discussion |
| Skipping verifications | Can't prove work is correct |
| Guessing through blockers | Should stop and ask |
| No batch reporting | Human partner can't review progress |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Plan is clear enough, skip review" | Plans always have ambiguities. Read critically. |
| "This blocker is minor, push through" | Minor blockers compound. Stop and ask. |
| "I'll verify at the end" | End verification catches too late. Verify per batch. |
| "I know what they meant" | Assumptions kill implementations. Clarify. |
| "Batches slow me down" | Batches catch issues early. Faster overall. |

## Integration

**Workflow position:**
```
writing-plans → executing-plans → finishing-a-development-branch
```

**Chains from:**
- **writing-plans** - Creates the plan this skill executes
- **brainstorming** - Design leads to plan leads to execution

**Chains to:**
- **finishing-a-development-branch** - REQUIRED after all tasks complete
- **test-driven-development** - Used within each task

**Alternative:**
- **subagent-driven-development** - Same-session execution with fresh subagents per task

## Verification Checklist

Before marking plan execution complete:

- [ ] Plan reviewed critically before starting
- [ ] Concerns raised before executing
- [ ] Each task completed with verification
- [ ] Batch reports delivered at checkpoints
- [ ] Feedback applied between batches
- [ ] All tasks pass their verification criteria
- [ ] finishing-a-development-branch skill invoked

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
