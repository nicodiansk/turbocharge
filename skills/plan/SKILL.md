---
name: plan
description: Use when you have stories or clear requirements that need to become an implementation plan — lean tasks grouped into lanes, with decisions, exact file paths, test assertions, and verification commands.
context: fork
agent: planner
background: false
argument-hint: "[stories-or-requirements-file]"
---

# Create Implementation Plan

Read the requirements at $ARGUMENTS and create a lean implementation plan.

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
```

**Lanes** let `/turboflow:build` run independent work side by side and skip a builder spawn for mechanical work:
- A lane owns a set of files, listed as full repo-relative paths — build diffs and reviews each lane by them. **No file belongs to two lanes** — test files included.
- Tasks inside a lane run in order. `After` names lanes that must finish first; lanes with no `After` path between them may overlap.
- **Executor** is a hint: `inline` for mechanical lanes (content edits, exact text given, ≤3 tasks) that the main session applies directly; `builder` for real logic or lanes with judgment calls, run by one builder for the whole lane.
- **Effort** (`low`/`medium`/`high`) applies to builder lanes; use `—` for inline.
- A small plan can be a single lane.

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
**Decision:** [1–4 lines: what changes and why — names, signatures, behavior, edge cases]
**Test:** `tests/exact/test_file.py`
- [assertion: input/state → expected result]
- [assertion: the edge case that must fail today]
**Verify:** `[exact command]` → [expected result]
**Commit:** `feat: [description]`
```

## Rules

- **Decisions, not code.** Record what to build and why; the builder or the main session writes the code. Include code only where the exact text *is* the decision — a regex, a signature, a JSON key, an error string — inline or in a fence of ≤10 lines. Target ≈1.5 KB per task.
- Each task: **2-5 minutes** of work. If longer, split it.
- **Exact file paths**, with line ranges for modifications — not "somewhere in src/". Line ranges are plan-time hints; build re-locates code by content when an earlier task in the lane shifts it
- **Verify runs the task's own tests — never the full suite** while another lane can still be running: it would see that lane's half-written files. Build runs the full suite once, at the join; only a final lane that comes `After` every other lane may verify with it
- **Test assertions, not test code** — each one names the input and the expected result, specific enough to write the test from
- **Exact commands** with expected output
- **TDD always** — every task names the test that fails before the change
- **DRY, YAGNI** — don't plan features that aren't needed

## Save

Write plan to: `docs/plans/YYYY-MM-DD-<feature-name>.md`

Report: plan location, number of tasks, any assumptions made.
