---
name: review
description: "Use when a branch, pull request or diff should be checked before it merges: a review, a bug hunt against a spec, a last look before shipping. Reviews the diff against the plan and reports the findings with a merge verdict."
argument-hint: "[plan-or-description]"
---

# Code Review

Pre-merge review of completed work against the original plan, by one senior reviewer agent. It runs in this session.

**Announce:** "Using review to assess this work before merge."

## The Iron Law

```
NO MERGE WITHOUT CODE REVIEW
```

## Context

The plan or requirements being reviewed: $ARGUMENTS

## Step 1: Scope the diff

```bash
BASE_SHA=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || git merge-base HEAD master 2>/dev/null)
git diff --stat $BASE_SHA..HEAD
git diff --name-only $BASE_SHA..HEAD
```

- Empty diff: print `Nothing to review: HEAD has no commits beyond <base>.` (naming the base branch) and stop.
- Uncommitted tracked changes (`git status --porcelain`): say in one line that they are not part of this review.
- The plan is `$ARGUMENTS` when it names a file. Otherwise the plan is the description, or none.

## Single reviewer

Dispatch `turbocharge:code-reviewer`, with this prefix so the subagent sees the navigation index (subagents do not inherit parent history):

```
@ATLAS.md (navigation index — use Module Map + Key Symbols to locate touched modules)
@CLAUDE.md (conventions, rules)
```

Omit either reference if the file doesn't exist. Exception: if CLAUDE.md is missing but `AGENTS.md` exists, use `@AGENTS.md` in its place. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, use `@.claude/CLAUDE.md`.

Give it the diff range and the plan. Wait for it, then report:

- **Findings** by severity (Critical / Important / Minor): `file:line` and evidence.
- **Declined to judge**: each behavior the reviewer set aside, one line each with why (or `Declined to judge: none`). The session that receives this report rules on each line before shipping, by what a reasonable user would expect.
- **Assessment**: Yes / No / With fixes.

**No agent here:** if `turbocharge:code-reviewer` can't be dispatched either (no Agent tool, or the agent type is not registered, as on surfaces that load skills without agents), run the review inline in this session: read every changed file against the plan, check plan alignment, code quality, architecture and security, and judge behavior the spec doesn't mention (an empty input, a duplicate, error text, a rerun) by what a reasonable user would expect. Say so in one line.

## After the review

Offer: "Ready to ship?" → chains to `/turbocharge:ship`

## Review for

- **Plan alignment**, **code quality**, **architecture**, **security**
- **Beyond the plan**: grade each gap by its effect on a reasonable user. Check that every line of the plan's Review Focus has its pinning test.

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
| "The diff is small, I'll review it inline" | A reviewer agent does the review. Inline is only for when no agent can be dispatched |

### Review Completeness Checklist

Before reporting your assessment, verify:
- [ ] Read EVERY file in the diff (state count: "Reviewed X of Y changed files")
- [ ] Compared implementation against EVERY requirement in the plan
- [ ] Checked for issues that tests DON'T catch (naming, architecture, security)
- [ ] Verified no orphaned code, dead imports, or unfinished TODOs
