# Code Reviewer Dispatch Template

Dispatch a `turbocharge:code-reviewer` agent for production readiness review.

The agent's behavioral instructions (review checklist, severity categories, output format, critical rules) are defined in `agents/code-reviewer.md`. This template provides only the review-specific context.

```
Task tool:
  subagent_type: turbocharge:code-reviewer
  description: "Code review: {DESCRIPTION}"
  prompt: |
    Review code changes for production readiness.

    ## What Was Implemented

    {WHAT_WAS_IMPLEMENTED}

    ## Requirements/Plan

    {PLAN_OR_REQUIREMENTS}

    ## Git Range to Review

    Base: {BASE_SHA}
    Head: {HEAD_SHA}

    ```bash
    git diff --stat {BASE_SHA}..{HEAD_SHA}
    git diff {BASE_SHA}..{HEAD_SHA}
    ```

    ## Summary

    {DESCRIPTION}
```

## Placeholders

| Placeholder | Source | Notes |
|---|---|---|
| `{WHAT_WAS_IMPLEMENTED}` | Description of completed work | What was built |
| `{PLAN_OR_REQUIREMENTS}` | Plan file reference or inline requirements | What it should do |
| `{BASE_SHA}` | Starting commit | `git rev-parse origin/main` or pre-feature SHA |
| `{HEAD_SHA}` | Ending commit | `git rev-parse HEAD` |
| `{DESCRIPTION}` | Brief summary | One-line description for Task tool |
