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

### 7. Write Memory With Confidence Metadata

When persisting items to `~/.claude/projects/<project>/memory/*.md`, use this bullet format:

```
- Summary sentence _(source, YYYY-MM-DD, conf: 0.8)_
```

- `source` — where the claim came from (`websearch`, `user`, `codebase`, `testrun`)
- `YYYY-MM-DD` — date written
- `conf` — 0.1 to 1.0; 0.9+ only for verified facts, 0.5–0.8 for reasoned claims, <0.5 for speculation

Example:
- Tailwind v4 drops the JS config _(websearch, 2026-04-14, conf: 0.9)_

### 8. 200-Line Cap on MEMORY.md — prune-before-build

Before appending new entries, if `~/.claude/projects/<project>/memory/MEMORY.md` is at or over 200 lines:
1. Sort existing entries by (confidence asc, date asc) — lowest confidence and oldest first
2. Drop entries until under 180 lines
3. Then append new entries

Dropped entries are not archived separately — file-based memory is lossy by design; high-value entries survive by being re-surfaced each session.

### 9. Session Snapshot JSON

Write `.claude/turbocharge-session.json` in the project root (the standard Claude Code project-state directory — same place `.claude/settings.json` and `.claude/settings.local.json` live):

```json
{
  "date": "2026-04-14",
  "branch": "master",
  "current_task": "ATLAS reshape design",
  "blockers": [],
  "next_steps": ["Chain to /turbocharge:plan", "Break into tasks"],
  "open_files": ["skills/atlas/SKILL.md"]
}
```

The SessionStart hook cats this on next session so resume is zero-tool-call. Make sure `.claude/turbocharge-session.json` is in the project `.gitignore` — it is per-user session-local state (don't exclude all of `.claude/` because `settings.json` is team-shared).

## How to Deliver

**Output the resume prompt directly in chat** so the user can copy it. Do NOT write files, create directories, or modify `.gitignore` (except for CLAUDE.md and memory updates above, and the session snapshot JSON).

Agent memory (via `memory: project`) handles persistence automatically — no manual file saving needed for session state.

## Workflow Position

```
[any skill] → wrap → [new session] → [resume with prompt]
```
