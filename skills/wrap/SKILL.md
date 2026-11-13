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
@CLAUDE.md @ATLAS.md @.claude/turbocharge-session.json  Continue [PROJECT] - [CURRENT TASK]

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

**MANDATORY:** `@.claude/turbocharge-session.json` MUST appear on the first line of every resume prompt — it is not optional context, it is the session state. Do not move it to "Context Files" or omit it. If the project keeps CLAUDE.md at `.claude/CLAUDE.md`, write `@.claude/CLAUDE.md` in place of `@CLAUDE.md`.

### 5.5. Atlas + CodeMap Freshness (MANDATORY)
Before generating the resume prompt:
1. **Always run `/turbocharge:atlas`** to refresh the domain map — do not skip, even if changes seem minor.
2. **If `.codemap/` exists**, run `codemap update` (or note it in the resume prompt if watch mode is active).

Include in the resume prompt:
```
Navigation: @ATLAS.md is current. CodeMap index: run `codemap validate` if unsure.
```

### Provenance: who decided, and where it came from
Every line steps 6–9 write to CLAUDE.md, memory or the snapshot, and every proposal, takes one of three formats:

| Who decided | Line |
|---|---|
| The user | `<rule> (ruled YYYY-MM-DD by user)` |
| The user changed their mind | `<new rule> (ruled YYYY-MM-DD, supersedes YYYY-MM-DD "<old, short>")`, and the old line is deleted |
| An agent, with no person's ruling | `[proposal · <agent> · YYYY-MM-DD · not yet ruled] <text>` |

- **No pointer, no line.** Every line points at its source: a `file:line`, the user's words (15 at most), or the test command.
- **Check the pointer before writing:** `sed -n '<line>p' <file>` shows the line, or the user's words are in this session.
- **Never** write a credential, token, key or cookie value, in memory, CLAUDE.md or the snapshot.
- **Never two lines for the same rule.** Rewrite the old one.
- **Short tags:** a date and a pointer, nothing more, since memory loads only its first 200 lines or 25 KB.

### 6. Encode Session Learnings
Before generating the resume prompt, check: did the user correct any misunderstandings or wrong approaches during this session? If so:
- **Update memory files** with corrections that apply to future sessions (domain concepts, preferences, conventions), the way step 7 says
- **Update CLAUDE.md** (`./CLAUDE.md`, or `./.claude/CLAUDE.md` if the project keeps it there — never create a second) if the correction reveals a missing rule or domain term that would prevent the same mistake
  - The lines wrap writes or rewrites carry `(ruled YYYY-MM-DD by user)`.
  - A correction that changes an existing rule rewrites that line with `supersedes` (Provenance), and never adds one next to it.
  - Lines wrap doesn't touch stay as they are: CLAUDE.md is team-shared.
- Don't save ephemeral task details — only save what future sessions need to know

Examples of things worth encoding:
- "autotuning is proactive, not reactive" → domain term in CLAUDE.md
- "always use asyncpg, never psycopg2" → infrastructure note in CLAUDE.md or memory
- "don't ask permission to run tests" → rule in CLAUDE.md: `Run tests without asking (ruled 2026-04-14 by user)`

### 6.5. Rule on Pending Proposals
Agents with memory can leave inferred rules as `[proposal · <agent> · YYYY-MM-DD · not yet ruled]` lines. Read `.claude/agent-memory*/*/MEMORY.md` (project and local scope; plugin agents write to `.claude/agent-memory/turbocharge-<agent>/`), list each `not yet ruled` line with its file, and ask the user to rule on each:
- Accepted: rewrite it in place as `<text> (ruled YYYY-MM-DD by user)`.
- Rejected: delete it.

Files under `.claude/agent-memory/` may be committed, which makes a ruling there the team's: say so when you ask. No such line: skip this step without a word.

### 7. Write Memory in Auto Memory's Shape

`~/.claude/projects/<project>/memory/` is Claude Code's auto memory directory, and wrap writes the way auto memory does:
- `MEMORY.md` is an index, one line per topic file: `- [Title](file.md) — one-line hook`. No `MEMORY.md` yet: create it with a `# Memory Index` heading above the index lines, never a flat list of bullets.
- Each topic file opens with frontmatter. Copy the keys an existing topic file in that folder uses, leaving out any you can't fill truthfully (a session id). With none, write `name`, `description` and `metadata.type` (`user`, `feedback`, `project` or `reference`).
- Add to the topic file the memory belongs to, or create one with its frontmatter and its index line. Never write what the code or CLAUDE.md already says.
- A `MEMORY.md` that still holds tagged bullets from an older wrap (it wrote them straight into the index): move them into a topic file with one index line, and delete none.

Lines in a topic file use this bullet format:

```
- Summary sentence _(source, YYYY-MM-DD, conf: 0.8)_
```

- `source` — the pointer to where the claim came from: `user: "<words>"`, `src/x.py:42`, `testrun: <command>`, `websearch: <url>`
- `YYYY-MM-DD` — date written
- `conf` — 0.1 to 1.0; 0.9+ only for verified facts, 0.5–0.8 for reasoned claims, <0.5 for speculation

Example:
- Tailwind v4 drops the JS config _(websearch: https://tailwindcss.com/blog/tailwindcss-v4, 2026-04-14, conf: 0.9)_

An entry that contradicts an older one rewrites it, adding `supersedes YYYY-MM-DD "<old, short>"` to its tag, and is never written next to it.

### 8. 200-Line Cap on MEMORY.md — prune-before-build

Before appending new entries, if `~/.claude/projects/<project>/memory/MEMORY.md` is at or over 200 lines:
1. Sort existing entries by (confidence asc, date asc) — lowest confidence and oldest first
2. Drop entries until under 180 lines
3. Then append new entries

Dropped entries are not archived separately — file-based memory is lossy by design; high-value entries survive by being re-surfaced each session.

### 9. Session Snapshot JSON

Write `.claude/turbocharge-session.json` in the project root (the standard Claude Code project-state directory — same place `.claude/settings.json` and `.claude/settings.local.json` live). If a `.claude/turboflow-session.json` from 3.0–3.1 exists, delete it after writing: this snapshot supersedes it.

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

The resume prompt's `@.claude/turbocharge-session.json` loads this into the next session.
<!-- repo-only -->
The SessionStart hook also prints it when the next session starts, so resume takes no tool call.
<!-- /repo-only -->

**Gitignore check (MANDATORY):** Before writing the snapshot, verify `.claude/turbocharge-session.json` is in the project `.gitignore`. If not, add exactly this line:
```
.claude/turbocharge-session.json
```
This is per-user session-local state — do NOT exclude all of `.claude/` because `settings.json` is team-shared.

## How to Deliver

**Output the resume prompt directly in chat** so the user can copy it. Do NOT write files, create directories, or modify `.gitignore` (except for CLAUDE.md and memory updates above, the rulings on pending proposals in `.claude/agent-memory*/*/MEMORY.md` (step 6.5), and the session snapshot JSON).

<!-- repo-only -->
Agent memory (via `memory: project`) handles persistence automatically — no manual file saving needed for session state.
<!-- /repo-only -->

## Workflow Position

```
[any skill] → wrap → [new session] → [resume with prompt]
```
