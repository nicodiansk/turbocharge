---
name: review
description: Use before merging to verify completed work meets requirements and quality standards. Dispatches code-reviewer for holistic assessment of the full git diff against the original plan.
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
   BASE_SHA=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || git merge-base HEAD master 2>/dev/null)
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

## Red Flags — Rationalizations That Mean You're Doing a Shallow Review

If you catch yourself thinking any of these, **STOP — you are about to deliver exactly the kind of review that wastes everyone's time:**

| Thought | Why It's Wrong |
|---------|----------------|
| "The code looks reasonable, I'll summarize the changes" | Summarizing is not reviewing. Read every changed line. |
| "I'll focus on the important files and skim the rest" | The bug is always in the file you skimmed |
| "The tests pass, so the logic must be correct" | Tests can pass while testing the wrong thing |
| "This is a minor change, quick review is fine" | Minor changes to core logic cause major production incidents |
| "I've reviewed similar code before, I know the patterns" | This review is about THIS diff, not past patterns |
| "Let me check the main concerns and wrap up" | Checking "main concerns" is a euphemism for a partial review |

### Review Completeness Checklist

Before reporting your assessment, verify:
- [ ] Read EVERY file in the diff (state count: "Reviewed X of Y changed files")
- [ ] Compared implementation against EVERY requirement in the plan
- [ ] Checked for issues that tests DON'T catch (naming, architecture, security)
- [ ] Verified no orphaned code, dead imports, or unfinished TODOs
