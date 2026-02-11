# Code Quality Reviewer Dispatch Template

Dispatch a `turbocharge:code-reviewer` agent after spec compliance passes.

**Only dispatch after spec compliance review passes.** The code-reviewer assesses HOW it was built, not WHETHER it matches spec.

The agent's behavioral instructions (quality checklist, severity categorization, output format) are defined in `agents/code-reviewer.md`. This template provides only the task-specific context.

```
Task tool:
  subagent_type: turbocharge:code-reviewer
  description: "Review code quality for Task {N}"
  prompt: |
    Review the code changes for Task {N}.

    {WHAT_WAS_IMPLEMENTED}

    Requirements: {PLAN_OR_REQUIREMENTS}
    Base SHA: {BASE_SHA}
    Head SHA: {HEAD_SHA}

    {DESCRIPTION}
```

## Placeholders

| Placeholder | Source | Notes |
|---|---|---|
| `{N}` | Plan task number | e.g. "3" |
| `{WHAT_WAS_IMPLEMENTED}` | From implementer's report | Summary of changes |
| `{PLAN_OR_REQUIREMENTS}` | Task reference from plan | e.g. "Task 3 from docs/plans/feature-plan.md" |
| `{BASE_SHA}` | Commit before task started | `git rev-parse HEAD~N` or pre-task SHA |
| `{HEAD_SHA}` | Current commit after task | `git rev-parse HEAD` |
| `{DESCRIPTION}` | Brief task summary | One-line description |
