# Implementer Dispatch Template

Dispatch a `turbocharge:implementer` agent for each task.

The agent's behavioral instructions (TDD, self-review, question-asking) are defined in `agents/implementer.md`. This template provides only the task-specific context.

```
Task tool:
  subagent_type: turbocharge:implementer
  description: "Implement Task {N}: {TASK_NAME}"
  prompt: |
    You are implementing Task {N}: {TASK_NAME}

    ## Task Description

    {FULL_TASK_TEXT}

    ## Context

    {SCENE_SETTING_CONTEXT}

    ## Working Directory

    Work from: {WORKING_DIRECTORY}
```

## Placeholders

| Placeholder | Source | Notes |
|---|---|---|
| `{N}` | Plan task number | e.g. "3" |
| `{TASK_NAME}` | Plan task title | e.g. "Add validation to user input form" |
| `{FULL_TASK_TEXT}` | Full text of task from plan | Paste verbatim - don't make subagent read file |
| `{SCENE_SETTING_CONTEXT}` | Controller-provided context | Where this fits, dependencies, architectural context |
| `{WORKING_DIRECTORY}` | Project root or relevant path | Absolute path to working directory |
