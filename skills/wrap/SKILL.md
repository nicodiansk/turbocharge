---
name: wrap
description: Use when ending a session, taking a break, or context is getting full. Captures session state, decisions, and generates a resume prompt for the next session. Critical for multi-session continuity.
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
Generate a self-contained prompt the user can paste into a fresh session. Use `@` references for files so Claude reads them automatically.

```
@CLAUDE.md  Continue [PROJECT] - [CURRENT TASK]

Branch: `branch-name`

Completed:
- [completed items]

Next Task: [description]
1. [next task with context]
2. [following task]

Context Files:
- @path/to/design-doc.md (implementation plan)
- @path/to/relevant-code

Decisions to Remember:
- [key decision]: [rationale]

Start With:
/turbocharge:[skill] [args]
```

### 5.5. Atlas Freshness
If ATLAS.md exists and significant structural changes were made this session (new modules, changed entry points, new integrations), note in the resume prompt:
- "Consider running `/turbocharge:atlas` to update the domain map"

### 6. Encode Session Learnings
Before generating the resume prompt, check: did the user correct any misunderstandings or wrong approaches during this session? If so:
- **Update memory files** with corrections that apply to future sessions (domain concepts, preferences, conventions)
- **Update CLAUDE.md** if the correction reveals a missing rule or domain term that would prevent the same mistake
- Don't save ephemeral task details — only save what future sessions need to know

Examples of things worth encoding:
- "autotuning is proactive, not reactive" → domain term in CLAUDE.md
- "always use asyncpg, never psycopg2" → infrastructure note in CLAUDE.md or memory
- "don't ask permission to run tests" → rule in CLAUDE.md

## How to Deliver

**Output the resume prompt directly in chat** so the user can copy it. Do NOT write files, create directories, or modify `.gitignore` (except for CLAUDE.md and memory updates above).

Agent memory (via `memory: project`) handles persistence automatically — no manual file saving needed for session state.

## Workflow Position

```
[any skill] → wrap → [new session] → [resume with prompt]
```
