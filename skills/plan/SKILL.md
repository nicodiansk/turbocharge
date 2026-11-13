---
name: plan
description: Use when you have stories or clear requirements that need to become an implementation plan — lean tasks grouped into lanes, with decisions, exact file paths, test assertions, and verification commands.
argument-hint: "[stories-or-requirements-file]"
---

# Create Implementation Plan

Turn the requirements at $ARGUMENTS into a lean implementation plan. The planner agent writes it in its own context, from its own instructions; this file is the contract its plan must meet, and the one you check it against.

## Dispatch

Dispatch `turbocharge:planner` through the Agent tool. Its prompt holds the context prefix (Context Gathering, below), the requirements path, and the plan path when the request names one. Wait for its result before you report: if it runs in the background, that is its completion notification. Never write the plan in this session while the planner can be dispatched.

Check the saved plan against this contract before you relay it: a Lanes table with full paths and no file in two lanes, Review Focus lines pinned to a task, every `Like:` target resolves (the Grep tool finds the symbol in the path, and its tests path exists), and a Decision, Test and Verify in every task. Name any gap in your report, then relay the planner's report (Save, below). If the planner fails or stops partway, say so: a rerun resumes from the partial file.

**No agent here:** if the Agent tool is missing, or `turbocharge:planner` is not registered (some surfaces load skills without agents), write the plan in this session to the contract below. Follow the Save section yourself, and run the Spec Self-Review (spec coverage, completeness, lane disjointness, type consistency, Review Focus, `Like:` targets resolve) before you remove the in-progress marker. Say so in one line.

## Plan Document Header

Every plan MUST start with:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies]

## Lanes
| Lane | Owns files | Tasks | After | Executor | Effort |
|------|-----------|-------|-------|----------|--------|
| [name] | `src/full/path.py`, `tests/full/test_path.py` | 1–3 | — | inline | — |
| [name] | `src/other/module.py`, `tests/other/test_module.py` | 4–6 | [lane] | builder | medium |

## Review Focus
- [input or condition the spec implies but never names] → [what a reasonable user expects] (pinned: Task N)
```

**Lanes** let `/turbocharge:build` run independent work side by side and skip a builder spawn for mechanical work:
- A lane owns a set of files, listed as full repo-relative paths — build diffs and reviews each lane by them. **No file belongs to two lanes** — test files included.
- Tasks inside a lane run in order. `After` names lanes that must finish first; lanes with no `After` path between them may overlap.
- **Executor** is a hint: `inline` for mechanical lanes (content edits, exact text given, ≤3 tasks) that the main session applies directly; `builder` for real logic or lanes with judgment calls, run by one builder for the whole lane.
- **Effort** (`low`/`medium`/`high`) applies to builder lanes; use `—` for inline.

**Lane shape:** the task shape decides the lanes.
1. **One lane is the default.** Split only independent work: disjoint files, and no need for another lane's result.
2. **Chain → one lane.** Builder lane B merges into builder lane A when B's only `After` is A and no other lane names A in `After`. Merging loses nothing: B's tasks start after A's either way, and a spawn and a hand-off go away. Repeat until no such pair is left, so A→B→C becomes one lane. The merged lane keeps A's name, owns both file sets, runs A's tasks then B's, and takes the higher Effort.
3. **Inline lanes stay separate**, before or after a builder lane: they cost no spawn. A chain through an inline lane doesn't merge: the builder lane after it names the inline lane in `After`, not a builder lane.
4. **At most 3 builder lanes overlap** (no `After` path between any two). With more independent pieces, merge the smallest into one lane, which owns the union of their files. Inline lanes don't count.

**Review Focus** names up to 5 input classes or failure modes the spec implies but never names, and that no task's test would otherwise exercise: the empty list, the duplicate, the field with a comma, the rerun. One line each, most likely first: the input, then what a reasonable user expects. The spec says what the software must do, not everything it will meet; its silence on an input is not permission for that input to break the program. The task that owns the code gets a test assertion that pins each line, and the line names that task. If nothing is implied, write `None found — <why>`.

## Context Gathering

Before planning, preload domain context. When dispatching the planner agent, prefix its prompt with:

```
@ATLAS.md (navigation index — use its Where to Look and Module Map tables before any codebase search)
@CLAUDE.md (conventions, rules, domain vocabulary)
```

If either file does not exist, omit the corresponding `@` reference. Exception: if CLAUDE.md is missing but `AGENTS.md` exists, use `@AGENTS.md` in its place. `.claude/CLAUDE.md` counts as a CLAUDE.md: if the project keeps it there, use `@.claude/CLAUDE.md`. `@` references auto-read on dispatch so the subagent receives them in context; subagents do NOT inherit parent conversation history.

**Token discipline:** Do NOT paste file contents or summaries into the dispatch prompt — send task description, file paths, and line ranges only. The planner reads actual files in its own context. Duplicating content in the dispatch wastes tokens (same pattern as build skill).

## Task Structure

Each task MUST follow this format:

```markdown
### Task N: [Component Name]
**Lane:** [lane] · **Files:** `exact/path.py:40-62` (modify), `exact/new_file.py` (create)
**Like:** `src/importers/csv.py:parse_row` (tests: `tests/importers/test_csv.py`)
**Decision:** [1–4 lines: what changes and why — names, signatures, behavior, edge cases]
**Test:** `tests/exact/test_file.py`
- [assertion: input/state → expected result]
- [assertion: the edge case that must fail today]
**Verify:** `[exact command]` → [expected result]
**Commit:** `feat: [description]`
```

`**Like:**` is optional. Write it only when the codebase already has code doing the same kind of job, and add `(tests: …)` when the target has tests. Otherwise leave the line out: never invent one.

## Rules

- **Decisions, not code.** Record what to build and why; the builder or the main session writes the code. Include code only where the exact text *is* the decision — a regex, a signature, a JSON key, an error string — inline or in a fence of ≤10 lines. Target ≈1.5 KB per task.
- **Name it, don't describe it.** Code that already does the same kind of job goes in the task's `Like:` line, not into a paragraph about it. Code that does the whole job is reused: the Decision calls it, with no new code.
- Each task: **2-5 minutes** of work. If longer, split it.
- **Exact file paths**, with line ranges for modifications — not "somewhere in src/". Line ranges are plan-time hints; build re-locates code by content when an earlier task in the lane shifts it
- **Verify runs the task's own tests — never the full suite** while another lane can still be running: it would see that lane's half-written files. Build runs the full suite once, at the join; only a final lane that comes `After` every other lane may verify with it
- **Test assertions, not test code** — each one names the input and the expected result, specific enough to write the test from
- **Exact commands** with expected output
- **TDD always** — every task names the test that fails before the change
- **Review Focus pinned** — every Review Focus line has its assertion in the task that owns the code
- **DRY, YAGNI** — don't plan features that aren't needed

## Save

Write plan to: `docs/plans/YYYY-MM-DD-<feature-name>.md`. When the request names a path for the plan, write it there instead.

The planner writes the file early, with line 1 `<!-- plan: in progress -->`, appends tasks as it goes, and removes the marker once its self-review passes. A rerun on a path whose line 1 is that marker resumes it: it keeps the header and every task with its `**Commit:**` line, and continues from the next task. A finished plan at the path is never overwritten; the new one goes to `<name>-2.md`.

Report: plan location, number of tasks, any assumptions made. End with exactly:

``Next: review `<path>`, then `/turbocharge:build <path>`.``

If the planner stopped on a question that would change the design, there is no plan: report the question and end with it instead.

The planner runs as a subagent and cannot ask for approval; the user reviews the saved plan, and running build is the approval.
