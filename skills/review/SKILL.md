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
