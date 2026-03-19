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
