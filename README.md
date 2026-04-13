# Turbocharge

**One pipeline. No agent sprawl. From idea to shipped code.**

Turbocharge replaces ad-hoc agents, scattered skills, and custom commands with a single opinionated engineering pipeline for Claude Code.

![Build skill — builder agent with spec and quality reviewers](images/build-review-chain.png)

---

## Why

Claude Code's agent ecosystem has a drift problem. Custom agents in `~/.claude/agents/`. Project commands in `.claude/commands/`. Plugin slash commands. Competing tdd-guides, planners, code-reviewers. Claude doesn't know which to use — and neither do you.

The result: inconsistent process, duplicated work, and review that only happens when you remember to ask.

Turbocharge is the *only* orchestration system you install. One pipeline. Enforced review chains. No ambiguity about which skill does what.

---

## Install

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

## The Pipeline

```
brainstorm → story → plan → build → review → ship
                                  ↑               |
                                debug            wrap
                                  ↑
                                atlas (any point)
```

Each skill chains to the next. Enter at any point — you don't need to start from brainstorm every time.

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

## With vs Without Turbocharge

| | Without | With Turbocharge |
|---|---------|------------------|
| Which agent does X? | Unclear — multiple overlap | One skill per step, clear handoffs |
| Code review | "I'll do it later" | Enforced per-task (spec + quality) + pre-merge (holistic) |
| Bug fixes | Guess-and-check until green | Systematic root-cause before any fix |
| Session continuity | Rewrite context every session | `wrap` captures state; next session resumes instantly |
| TDD discipline | Aspirational | Every task starts with a failing test, gated on review |
| Planning granularity | "Add auth" | 2–5 minute tasks with exact file paths and verification commands |

---

## What You Get

**10 skills** — each one a slash command:

| Skill | Does |
|-------|------|
| `setup` | Audits global config, removes conflicts, one-time |
| `atlas` | Generates project domain map (ATLAS.md) |
| `brainstorm` | Socratic requirements discovery, saves design doc |
| `story` | Requirements → INVEST stories with acceptance criteria |
| `plan` | Stories → 2–5 min tasks with TDD steps and exact code |
| `build` | Dispatches builder agents + enforced review chain per task |
| `review` | Holistic pre-merge assessment against original plan |
| `debug` | 4-phase root-cause investigation before fixes |
| `ship` | Verifies tests, then merge / PR / keep / discard |
| `wrap` | Captures session state + encodes learnings |

![Story skill — acceptance criteria and pipeline chaining](images/story-output.png)

**6 agents** — dispatched by skills, not invoked directly:

| Agent | Role |
|-------|------|
| `builder` | TDD implementation, worktree isolation |
| `planner` | Task decomposition with domain verification |
| `researcher` | Codebase exploration (haiku, background) |
| `spec-reviewer` | Checks task matches spec, doesn't trust builder |
| `quality-reviewer` | Categorized code-quality issues |
| `code-reviewer` | Holistic pre-merge review |

**3 hooks** — fire on lifecycle events:

- `SessionStart` — bootstraps context, flags missing CLAUDE.md / ATLAS.md
- `PreToolUse` on `Read` — nudges `.codemap/` usage when indexes exist
- `Stop` — reminds to wrap when the session ends

---

## Iron Laws

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
<summary><strong>What to remove when you install this</strong></summary>

Turbocharge replaces overlapping systems — clean them up to avoid Claude picking the wrong one:

- Custom agents in `~/.claude/agents/` that duplicate turbocharge agents (`planner`, `code-reviewer`, `tdd-guide`, session-wrappers, etc.)
- Project commands in `.claude/commands/` for session-wrap, story-authoring, or task-breakdown
- Any `agents.md` rule file that references a parallel agent system

Your `~/.claude/rules/common/agents.md` should point to turbocharge as the primary system, not list competing agents.

`/turbocharge:setup` does this audit interactively.

</details>

<details>
<summary><strong>Complementary project skills</strong></summary>

Turbocharge covers the build pipeline — not every workflow. Keep project-level commands in `.claude/commands/` for things turbocharge doesn't do:

- **epic-author** — Business-level epic drafting (WHAT and WHY, not HOW)
- **consistency-review** — Cross-domain coherence between stories/tasks/epics

These complement turbocharge without overlapping.

</details>

<details>
<summary><strong>Directory structure</strong></summary>

```
turbocharge/
├── .claude-plugin/          # plugin.json + marketplace.json
├── skills/                  # 10 skill definitions
│   └── <skill>/SKILL.md
├── agents/                  # 6 agent definitions
├── hooks/                   # hooks.json + content files
├── images/                  # README screenshots
├── docs/                    # Guides and design docs
├── scripts/validate.sh      # Plugin health check
├── examples/                # Sample pipeline outputs
├── settings.json
└── README.md
```

</details>

<details>
<summary><strong>Validation</strong></summary>

```bash
./scripts/validate.sh
```

Verifies plugin structure: manifest validity, skill frontmatter, agent files, hook registration.

</details>

---

## License

MIT — see [LICENSE](LICENSE).
