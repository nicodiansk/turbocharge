---
name: wrap
description: Use when ending a session, taking a break, or context is getting full. Captures session state, decisions, and generates a resume prompt for the next session. Critical for multi-session continuity.
disable-model-invocation: true
---

# Wrap Session

Capture session state for seamless resumption.

**Announce:** "Wrapping session — saving context for next time."

## The Iron Law

```
NO SESSION END WITHOUT WRAP OFFER
```

When you detect a session is ending (goodbye, thanks, natural stopping point, context pressure), proactively offer to wrap.

## What to Capture

### 1. Progress
- What was accomplished this session
- Which tasks/stories are complete
- Current branch, commit, state

### 2. Decisions
- Architectural choices made (with rationale)
- Approach decisions (with alternatives considered)
- User preferences discovered

### 3. Blockers & Open Questions
- What's stuck and why
- Questions that need answers
- Dependencies not yet resolved

### 4. Next Steps
- Prioritized list of what to do next
- Which skill to invoke first in next session

### 5. Resume Prompt
Generate a self-contained prompt that a fresh session can execute:

```
Resume turbocharge work on [project]:

## Context
- Branch: [branch-name]
- Last completed: [task/story]
- Plan file: [path]

## What's Done
- [completed items]

## What's Next
1. [next task with context]
2. [following task]

## Decisions to Remember
- [key decision]: [rationale]

## Start With
/turbocharge:build [plan-file] (continue from Task N)
```

## Where to Save

Write to: `.turbocharge/wrap/YYYY-MM-DD-session.md`

Add `.turbocharge/wrap/` to `.gitignore` if not already present.

## Agent Memory Flush

Before wrapping, remind each active subagent to update their agent memory with anything they've learned this session. This ensures persistent knowledge survives the session boundary.

## Workflow Position

```
[any skill] → wrap → [new session] → [resume with prompt]
```
