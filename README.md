# 🦴 Turbocharge

**Claude Code with a spine.**

*An opinionated pipeline that refuses to let you skip review, skip tests, or pick the wrong agent.*

Turbocharge is the pipeline you'd build yourself if you had six months — and the discipline you'd enforce if you weren't tired at 11 PM. Ten skills, six agents, three hooks, one chain of command. Install it and stop maintaining your own orchestration.

It also remembers. Every session you close with `/wrap` teaches Claude something — your preferences, your conventions, the corrections you made today. Next Monday, Claude already knows.

![Build skill — builder agent with spec and quality reviewers](images/build-review-chain.png)

---

## 🎬 Five Scenes

### 🌙 The 11 PM Skip

_(Before)_ Feature works. You know you should review. You're tired. You don't. Two days later, your teammate finds the bug you'd have caught.

_(After)_ `/turbocharge:build` won't mark the task complete until the spec-reviewer and quality-reviewer have run. It isn't a button you remember to press — it's the only way the pipeline lets you exit.

### 🪦 The Agent Graveyard

_(Before)_ `code-reviewer.md`, `code-reviewer-v2.md`, `tdd-guide.md`, `tdd-guide-strict.md`, `planner.md`, `planner-actually-good.md`. Claude picks one at random. You can't remember which one is current.

_(After)_ One plugin. Ten skills. Six agents. `/turbocharge:setup` audits `~/.claude/agents/` on first run and offers to delete the graveyard. The only orchestration you install is the one you stop maintaining.

### 📅 The Monday Re-explain

_(Before)_ Monday morning. You explain it again — immutable patterns, tests live in `__tests__/`, files stay under 400 lines. The exact speech you gave Friday afternoon to a Claude that has since forgotten you exist.

_(After)_ `/wrap` wrote it all to memory Friday at 5 PM — preferences, conventions, the corrections you made that week. Monday's Claude read it before you sat down. You open the laptop and skip the speech.

### 🧠 The Context Amnesia

_(Before)_ "Where was I?" Scroll terminal history. Re-read your own commits. Open three files to rebuild the mental model. Twenty minutes gone before you write a line.

_(After)_ `/wrap` captured the state — open question, current file, last decision, what's next. The fresh session reads the resume prompt and you're typing code in ninety seconds.

### 🎯 The Guess-and-Check Debug

_(Before)_ Test fails. Try a thing. Still red. Try another thing. An hour in, the bar is green and you have no idea why. The bug will be back in three weeks.

_(After)_ `/turbocharge:debug` forces a four-phase root-cause investigation before any fix lands. You name the broken assumption, prove it, then change one thing. You unbreak it on purpose, not by coincidence.

---

## 📦 Install

```bash
claude plugin marketplace add nicodiansk/turbocharge
claude plugin install turbocharge@turbocharge
```

First run:

```
/turbocharge:setup
```

`setup` audits your global config for conflicting agents/skills and offers to clean them up. Run it once.

Update later:

```bash
claude plugin update turbocharge@turbocharge
```

Or load locally for plugin development:

```bash
claude --plugin-dir ./turbocharge
```

---

## 🔁 The Pipeline

```
brainstorm → story → plan → build → review → ship
                                  ↑               |
                                debug            wrap
                                  ↑
                                atlas (any point)
```

Enter at any step. Each skill gates the next — review before ship, root-cause before fix, wrap before you forget.

| Start here | When |
|------------|------|
| `brainstorm` | Vague idea, need to explore requirements |
| `story` | Requirements clear, need INVEST-compliant stories |
| `plan` | Stories approved, need implementation tasks |
| `build` | Plan exists, time to write code |
| `review` | Code done, need pre-merge assessment |
| `debug` | Something's broken |
| `ship` | Ready to merge, PR, or discard |
| `wrap` | Session ending — capture state for next time |
| `atlas` | Need a domain map of the project |

---

## ⚖️ With vs Without Turbocharge

| | ❌ Without | ✅ With Turbocharge |
|---|---------|------------------|
| Which agent for X? | Three overlapping ones — Claude rolls the dice. | One skill per step. The handoff is the design. |
| Code review | "I'll do it later." (You won't.) | The build skill won't exit until spec + quality review pass. |
| Bug fixes | Try things until green. Ship the coincidence. | Four-phase root-cause before any fix touches code. |
| Session continuity | Re-explain your project every Monday. | `/wrap` captures state Friday. Monday picks it up. |
| Claude gets smarter across sessions? | You re-teach the same lessons every week. | Memory populated by `/wrap`. Yesterday's correction is today's default. |
| TDD discipline | "Next time I'll write the test first." | Every task starts on a failing test. The pipeline gates on it. |
| Planning granularity | "Add auth." | 2–5 minute tasks with exact paths and verification commands. |

---

## 📋 What You Get

**🛠️ Ten skills** — each a slash command:

| Skill | What it refuses to let you skip |
|-------|---------------------------------|
| `setup` | Running with conflicting agents. Audits `~/.claude/agents/` on first run. |
| `atlas` | Coding without a domain map. Generates `ATLAS.md` from the actual codebase. |
| `brainstorm` | Implementing a half-formed idea. Socratic discovery, design doc out. |
| `story` | Vague work. Forces INVEST stories with testable acceptance criteria. |
| `plan` | "Add auth." Breaks stories into 2–5 minute TDD tasks with exact paths. |
| `build` | Marking a task done before spec + quality review pass. |
| `review` | Merging without a holistic pass against the original plan. |
| `debug` | Guess-and-check. Four-phase root-cause investigation before any fix. |
| `ship` | Shipping with red tests. Verifies, then merge / PR / discard. |
| `wrap` | Closing the laptop without saving what you taught Claude today. |

![Story skill — acceptance criteria and pipeline chaining](images/story-output.png)

**🤖 Six agents** — dispatched by skills, never invoked directly:

| Agent | Role |
|-------|------|
| `builder` | TDD implementation in an isolated worktree. |
| `planner` | Decomposes stories into tasks; verifies entity names against the codebase. |
| `researcher` | Fast codebase exploration on Haiku, runs in the background. |
| `spec-reviewer` | Reads the task spec and the diff. Doesn't take builder's word. |
| `quality-reviewer` | Categorized code quality issues. Blocks completion on CRITICAL. |
| `code-reviewer` | Holistic pre-merge pass against the original plan. |

**🪝 Three hooks** — fire on lifecycle events, not on request:

- `SessionStart` — bootstraps context, flags missing `CLAUDE.md` / `ATLAS.md`.
- `PreToolUse` on `Read` — nudges `.codemap/` usage when an index exists.
- `Stop` — reminds you to `/wrap` before the session ends.

---

## ⛓️ Iron Laws

Enforced inside the skills themselves, not suggested:

- `NO IMPLEMENTATION WITHOUT UNDERSTANDING REQUIREMENTS FIRST`
- `NO STORY WITHOUT ACCEPTANCE CRITERIA`
- `NO TASK MARKED COMPLETE WITHOUT REVIEW CHAIN VERIFICATION`
- `NO MERGE WITHOUT CODE REVIEW`
- `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`
- `NO SESSION END WITHOUT WRAP OFFER`
- `NO ATLAS WITHOUT READING THE CODEBASE FIRST`

The review chain for every build task:

```
builder → spec-reviewer → quality-reviewer
              ↓ issues?        ↓ issues?
         back to builder   back to builder
         (max 2 cycles)    (max 2 cycles)
```

---

<details>
<summary><strong>🧹 What to remove when you install this</strong></summary>

Turbocharge replaces overlapping systems — clean them up to avoid Claude picking the wrong one:

- Custom agents in `~/.claude/agents/` that duplicate turbocharge agents (`planner`, `code-reviewer`, `tdd-guide`, session-wrappers, etc.)
- Project commands in `.claude/commands/` for session-wrap, story-authoring, or task-breakdown
- Any `agents.md` rule file that references a parallel agent system

Your `~/.claude/rules/common/agents.md` should point to turbocharge as the primary system, not list competing agents.

`/turbocharge:setup` does this audit interactively.

</details>

---

## 📜 License

MIT — see [LICENSE](LICENSE).
