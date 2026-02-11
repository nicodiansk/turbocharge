# Spec Compliance Reviewer Dispatch Template

Dispatch a `turbocharge:spec-reviewer` agent after each implementation completes.

The agent's behavioral instructions (distrust reports, verify by reading code, check for missing/extra) are defined in `agents/spec-reviewer.md`. This template provides only the task-specific context.

```
Task tool:
  subagent_type: turbocharge:spec-reviewer
  description: "Review spec compliance for Task {N}"
  prompt: |
    You are reviewing whether an implementation matches its specification.

    ## What Was Requested

    {FULL_TASK_REQUIREMENTS}

    ## What Implementer Claims They Built

    {IMPLEMENTER_REPORT}
```

## Placeholders

| Placeholder | Source | Notes |
|---|---|---|
| `{N}` | Plan task number | e.g. "3" |
| `{FULL_TASK_REQUIREMENTS}` | Full text of task requirements from plan | Paste verbatim |
| `{IMPLEMENTER_REPORT}` | Output from implementer subagent | What they claim to have built, files changed, tests run |
