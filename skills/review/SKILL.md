---
name: review
description: Use before merging to verify completed work meets requirements and quality standards. Dispatches code-reviewer for holistic assessment of the full git diff against the original plan.
context: fork
agent: code-reviewer
background: false
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

Dispatch the code-reviewer agent with this prefix so the subagent sees the navigation index (subagents do not inherit parent history):

```
@ATLAS.md (navigation index — use Module Map + Key Symbols to locate touched modules)
@CLAUDE.md (conventions, rules)
```

Omit either reference if the file doesn't exist. Exception: if CLAUDE.md is missing but `AGENTS.md` exists, use `@AGENTS.md` in its place. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, use `@.claude/CLAUDE.md`.

**No agent here:** if this review isn't already running as the code-reviewer and `turbocharge:code-reviewer` can't be dispatched (no Agent tool, or the agent type is not registered, as on surfaces that load skills without agents), run the review inline in this session with the same steps and report shape, and say so in one line.

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
   - **Beyond the plan** — For behavior the spec and plan don't mention (an empty input, a duplicate, error text, a rerun), judge by what a reasonable user would expect, and grade each gap by its effect on that user. Check that every line of the plan's Review Focus has its pinning test.

4. Report:
   - **Strengths** — What was done well
   - **Issues** — Critical / Important / Minor with `file:line` references
   - **Declined to judge** — each behavior set aside, one line each, with why (or `Declined to judge: none`). The session that receives this report rules on each line before shipping.
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
