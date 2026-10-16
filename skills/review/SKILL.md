---
name: review
description: "Use when a branch, pull request or diff should be checked before it merges: a review, a bug hunt against a spec, a last look before shipping. Reviews the diff against the plan and reports the findings with a merge verdict."
argument-hint: "[plan-or-description]"
---

# Code Review

Pre-merge review of completed work against the original plan, by one senior reviewer agent. It runs in this session.
<!-- repo-only -->
When the user opts in, five lens reviewers find defects instead, then verifier agents try to refute each finding, and only what survives is reported as confirmed.
<!-- /repo-only -->

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

<!-- repo-only -->
## Step 2: Pick the reviewer

The swarm is a workflow, and the Workflow tool launches only on the user's opt-in. Opt-in means the user typed `/turbocharge:review`, or asked in their own words for the swarm, a multi-agent or multi-lens review, or a workflow. This skill reaching you some other way is not an opt-in: you invoked it yourself from a plain request ("check my branch before I merge"), or another skill chained into it.

- Opt-in → **Step 3**.
- No opt-in → **Single reviewer**.

Never review inline when an agent can do it. The inline review is only for **No agent here**.

## Step 3: Launch the swarm

Call the **Workflow** tool with `name: "turbocharge:review-swarm"` and these args as JSON:

```json
{"base": "<BASE_SHA>", "head": "<HEAD sha>", "files": ["<name-only list>"], "plan": "<plan file path or description>", "context": ["<paths>"], "stat": "<git diff --stat output>"}
```

`context` lists the navigation and convention files that exist, by path: `ATLAS.md` (navigation index — Module Map + Key Symbols locate touched modules) and `CLAUDE.md` (conventions, rules). Omit either if the file doesn't exist. Exception: if CLAUDE.md is missing but `AGENTS.md` exists, use `AGENTS.md` in its place. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, list `.claude/CLAUDE.md`.

The workflow runs in the background. Wait for its completion notification. Don't review in parallel, and don't poll.

If the launch is declined, denied or fails, go to **Single reviewer** and say why in one line.

## Step 4: Report

From the workflow's result:

- **Confirmed findings** by severity (Critical / Important / Minor): `file:line`, evidence, and which lenses found it.
- **Not verified**: findings no verifier could settle (a verifier failed, or the agent cap was reached), with why. Never present these as confirmed or as refuted.
- **Declined to judge**: each behavior a lens set aside, one line each with why (or `Declined to judge: none`). The session that receives this report rules on each line before shipping, by what a reasonable user would expect.
- **Refuted**: one collapsed line each, with the verifier's reason.
- **Dropped work**: any lens that failed, so its coverage is missing.
- **Assessment** = the workflow's verdict: Yes / No / With fixes / Incomplete.

Then go to **After the review**.
<!-- /repo-only -->

## Single reviewer

<!-- repo-only -->
Reached on no opt-in (Step 2), when there is no Workflow tool (workflows are off), or when the swarm's launch was declined or failed (Step 3).
<!-- /repo-only -->
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

<!-- repo-only -->
End with one tip, printed once:

- No opt-in: `Tip: type /turbocharge:review for the verified multi-lens review (five lens reviewers plus a verifier per finding; slower, about 10x the cost).`
- No Workflow tool: `Tip: turn on Dynamic workflows in /config for the verified multi-lens review.`
- Launch declined or failed: no tip; the one line from Step 3 says why.
<!-- /repo-only -->

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
