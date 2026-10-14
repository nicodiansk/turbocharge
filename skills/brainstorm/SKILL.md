---
name: brainstorm
description: Use when the user asks to add, build or change a feature and hasn't said exactly how, including a one-line request such as "add JSON output to the list command". Sizes the request first - a clear quick fix gets done directly, and anything with open choices is explored with questions before any code.
---

# Brainstorm

Turn ideas into fully formed designs through collaborative dialogue.

**Announce:** "Using brainstorm to explore this idea before implementation."

## The Iron Law

```
NO IMPLEMENTATION WITHOUT UNDERSTANDING REQUIREMENTS FIRST
```

## Process

### 1. Understand Context
- Check project state (files, docs, recent commits)
- Read agent memory for relevant prior context

### 2. Size It
Name the size in one plain line, with the reason. The user can override it.
- **Before any question:** if the request already says everything that matters (clear, a few lines, no open choices), it's **quick**. Do it now, say what you did, no design doc.
- **Otherwise,** discover requirements first (step 3). Once you understand what they want, name the size:
  - **small** (one component, one or two choices): agree the approach in chat, no design doc. Then offer `/turbocharge:plan` or go straight to the change.
  - **project**: continue through the steps below to a design doc.
- If the work grows mid-way, say so and step up a size.
- If several independent projects emerge, say so, agree an order, and take them one at a time, one design doc each.

### 3. Discover Requirements
- Ask questions **one at a time**
- Prefer **multiple choice** when possible
- Focus on: purpose, constraints, success criteria, users
- Don't overwhelm — one question per message
- Once you understand what they want, make the size call from step 2

### 4. Explore Approaches
- Propose **2-3 approaches** with trade-offs
- Lead with your recommendation and reasoning
- Be ready to combine or discard

### 5. Present Design
- Break into sections of **200-300 words**
- Ask after each section: "Does this look right?"
- Cover: architecture, components, data flow, error handling, testing
- Apply YAGNI — remove unnecessary features

### 6. Save and Continue
- Write design to `docs/plans/YYYY-MM-DD-<topic>-design.md`. When you say you're writing it up, tell the user a builder check reads it first and you may come back once with questions.
- **Builder check (projects only)** — before committing the doc:
  1. Dispatch `turbocharge:researcher` with `effort: medium` on the Agent call, prefixed with `@ATLAS.md @CLAUDE.md` and the doc path. Omit a reference whose file doesn't exist; if CLAUDE.md is missing but `AGENTS.md` exists, use `@AGENTS.md` in its place; `.claude/CLAUDE.md` counts as a CLAUDE.md (`@.claude/CLAUDE.md`). Prompt: "Read this design as the developer who will build it. You can't talk to its author. Report only the questions where a wrong guess would change the plan, ranked, most consequential first, each with why the answer matters. Skip what the doc leaves to the builder, what you could reasonably decide yourself, and wording. If nothing important is left, say `nothing important left`."
  2. The researcher runs in the background: wait for its completion notification.
  3. Sort its questions into three piles:
     - **answered already** by the conversation or the codebase → put the answer in the doc;
     - **minor** (a sensible builder could settle it without changing what gets built) → settle it and mark it in the doc as `Ruled in brainstorm: <call>`;
     - **theirs** (only the user can answer, and the answer changes what gets built).
  4. Bring the "theirs" pile to the user in one message, most important first. This is the single batched exception to one question at a time.
  5. Update the doc with their answers.

  With no Agent tool, or `turbocharge:researcher` not registered (some surfaces load skills without agents), read the doc as that builder yourself.
- Commit the design document, then hand it over with the list of `Ruled in brainstorm:` calls for the user to check while reading
- Offer: "Ready for story breakdown?" → chains to `/turbocharge:story`
- Or: "Ready for implementation planning?" → chains to `/turbocharge:plan`

## Red Flags — STOP

| Flag | Problem |
|------|---------|
| Jumping to code | Didn't explore requirements |
| Single approach | Didn't propose 2-3 alternatives |
| Wall of text | Present in 200-300 word sections |
| Unanswered questions | Don't design around unknowns |
| No YAGNI review | Remove unnecessary features |
| Design doc for a quick fix | Size it first |
| Designing several projects at once | Agree an order; one at a time |

## Workflow Position

```
brainstorm → story → plan → build → review → ship
```
