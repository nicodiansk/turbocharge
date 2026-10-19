You have 6 agents in `~/.claude/agents/`, 4 custom commands, 3 rule files that contradict each other, and a `planner-actually-good.md` you wrote at 2 AM. Claude picks whichever it finds first. You can't remember which is current. Neither can Claude.

**Turbocharge replaces all of it** with a single opinionated pipeline: 10 skills, 6 agents, 1 hook. One system to install, nothing to maintain.

## Install

Requires **Claude Code 2.1.287 or later** (`claude --version`). Tested with Claude Code 2.1.296 and 2.1.287 (stable channel).

Install **Turbocharge** from Claude's plugin directory. Claude Code has the directory built in, so there's no marketplace to add first:

```bash
claude plugin install turbocharge-nicodiansk@anthropic-plugin-directory
# later, to update:
claude plugin update turbocharge-nicodiansk@anthropic-plugin-directory
```

In a session, `/plugin` → **Discover** → search "turbocharge" and pick `turbocharge-nicodiansk` also works.

Restart Claude Code, then start building:

```bash
/turbocharge:brainstorm I want to build a CLI tool that manages git worktrees
```

Every skill announces itself, does one job well, and hands you the next step.

### Upgrading

From the directory or from 2.x, update as usual with the update command for your copy above. Your commands stay `/turbocharge:<skill>`, and your session snapshot and setup's CLAUDE.md blocks carry over. 3.5 needs Claude Code 2.1.287 or later. Full notes are in the [CHANGELOG](https://github.com/nicodiansk/turbocharge/blob/master/CHANGELOG.md).

## Where it works

Turbocharge is built for **Claude Code**, where the whole pipeline runs. Each Claude app loads a different part of a plugin:

| | Claude Code | Cowork | Chat (claude.ai, desktop, mobile) |
|:--|:--:|:--:|:--:|
| 10 skills | ✓ | ✓ | ✓ |
| 6 agents (builder, reviewers, verifier, planner, researcher) | ✓ | ✓ | ignored |
| SessionStart hook | ✓ | ✓ | ignored |

In Chat, agents and hooks are ignored, so the planning skills (`brainstorm`, `story`, `plan`) are the useful part there. `build`, `review`, `ship` and `debug` need a shell and git, which means Claude Code. A plugin you add on claude.ai also reaches Claude Code at your next session start.

## The Pipeline

```
brainstorm → story → plan → build → review → ship
                                ↑
                              debug
```

Enter at any step. Each skill gates the next. `debug` loops under `build` when bugs surface.

**`wrap`** stands alone — run it any time to capture session state, decisions, and a resume prompt for your next session.

**`atlas`** stands alone — generates `ATLAS.md` domain map from the actual codebase. Pre-loaded every session for zero-tool-call navigation.

| Skill | Command | What it does |
|:------|:--------|:-------------|
| **setup** | `/turbocharge:setup` | Audits config for conflicting agents/skills/rules. Bootstraps `CLAUDE.md`. |
| **atlas** | `/turbocharge:atlas` | Generates `ATLAS.md` domain map. Pre-loaded every session. |
| **brainstorm** | `/turbocharge:brainstorm` | Socratic requirements discovery before implementation |
| **story** | `/turbocharge:story` | INVEST-compliant story breakdown with acceptance criteria |
| **plan** | `/turbocharge:plan` | Lean plans — decisions, exact paths and test assertions in 2-5 min tasks, grouped into file-disjoint lanes |
| **build** | `/turbocharge:build` | Runs each lane inline or with one Sonnet builder, overlaps independent lanes, then one full-suite gate. Opt-in per-lane review (`--reviewed`). |
| **review** | `/turbocharge:review` | Pre-merge review against the plan by one senior reviewer |
| **debug** | `/turbocharge:debug` | Systematic 4-phase root-cause investigation — no fix until cause is proven |
| **ship** | `/turbocharge:ship` | Test verification, then merge / PR / keep (discard only when you ask). Triages review comments you save to a file or paste: verifies each, fixes the valid ones, drafts the replies |
| **wrap** | `/turbocharge:wrap` | Session continuity — captures state, generates resume prompt |

## Why a Pipeline

- **One source of truth.** No competing `planner-v2.md` files, no rules that contradict each other. Install once, update once.
- **Each step gates the next.** Requirements before stories, stories before plans, plans before code. The skill you skipped is usually the bug you ship.
- **Right model for each role.** Builders, reviewers, and researchers run on Sonnet — fast and focused. Your orchestration session runs whatever model you've configured, so you can reach for a more capable one on the planning and judgment calls.
- **Drop in anywhere.** Already have a plan? Start at `build`. Hit a bug? `debug`. Wrapping up? `wrap`. You're never forced through the whole chain.

## How Build Works

A plan groups its tasks into **lanes** — sets of tasks that own disjoint files. Build routes each lane one of two ways:

- **Inline** — mechanical lanes (content edits, exact text in the plan) run in your main session, task by task. No spawn at all.
- **Builder** — lanes with real logic get one Sonnet builder for the whole lane, at the effort the plan sets.

Independent lanes **overlap**: builders work in the background while your session runs the inline lanes, and every commit is scoped to its lane's files. When all lanes finish, build runs the full suite **once** — the full-suite gate. A failure goes back to the lane that owns the file; a builder lane's fix round **resumes** the same builder, context and prompt cache intact, instead of paying for a fresh spawn.

`--inline` runs every lane in your session; `--delegate` gives every lane a builder. For security-sensitive or unfamiliar code, `--reviewed` adds one Sonnet `task-reviewer` per lane that reads the lane's diff once and returns Spec + Quality verdicts, looping fixes for up to two cycles. `--checkpoint` pauses for your feedback after each lane. After the gate, chain to `/turbocharge:review` for the final holistic assessment.

Plans written before 3.1 have no Lanes table; build runs them as one lane.

## Measured

Each eval case sends the same prompt to Claude in a fresh, empty workspace, once with Turbocharge loaded (**WITH**) and once with no plugin at all (**W/OUT**). **Δ** is the difference: what the plugin adds. **Fired** counts the runs in which the intended Turbocharge skill was invoked; it has no baseline, because without the plugin there is no skill to fire.

| Family | Cases | WITH | W/OUT | Δ | Fired |
|---|---|---|---|---|---|
| defects | 2 | 0.85 | 0.96 | -0.10 | 6/6 |
| planning | 1 | 1.00 | 0.50 | +0.50 | 3/3 |
| triage | 1 | 1.00 | 0.75 | +0.25 | 3/3 |
| trigger | 4 | 1.00 | 0.83 | +0.17 | 6/9 |

Sample: 2 defects cases, 1 planning, 4 trigger, 1 triage; 3 runs per arm, 48 runs in all. A difference of one run in three is noise-sized.

- **Trigger** (4 cases): natural phrasing should reach the right skill, and its first move should fit: ask before building a vague feature, find the root cause of a failing test, flag the bug in a branch under review, fix a typo without ceremony.
- **Defects** (2 cases): review a branch against its spec. One branch has 5 planted bugs; a larger one has 7 cross-file and spec-implied bugs plus 3 decoys that look wrong but aren't. One grader per bug, plus one that penalizes false alarms.
- **Planning** (1 case): turn a CSV-export spec into a plan. Graded on whether the plan covers fields with commas or quotes (which the spec implies but never names) and whether every task names its files, a concrete expected result and a verify command.
- **Triage** (1 case): three PR review comments handed over in a file (a real bug, a false positive, a style nit). Fix the bug, rebut the false positive, leave the nit to you, push nothing.

What 3.4.0 shows: `brainstorm` now fires on "add CSV export to this tool" (3/3, was 0/3), lifting trigger to +0.17, while the typo fix still gets no ceremony. `review` fires on both defects prompts (6/6, was 0/3). Triage gains +0.25: without the plugin, every run changed `slugify`'s signature, which the style nit asked for and the plugin leaves to you. Planning holds at +0.50. Defects reads −0.10, and all of it is the false-alarm grader: with the plugin, the reviewer found every planted bug in every run (36 of 36) but rated extra findings Critical or Important. Some were real bugs the larger fixture held by accident, which the grader counted as false alarms; the fixtures were cleaned after this run and aren't re-measured yet. `debug` didn't fire (0/3), and Sonnet found the root cause anyway.

Claude Code 2.1.296 · model `claude-sonnet-5-5`, judge `claude-sonnet-5-5` · 3 runs per arm · 2026-10-14 · $6.59 list-price estimate (run on a Max plan, so it drew plan usage, not billing). Measured on the plugin as released (`e5abd26`); only the eval fixtures changed after.

The suite runs on the maintainer's machine before a release, and never runs in your sessions.

## Agents

Dispatched by skills. You never invoke them directly.

| Agent | Role | Model |
|:------|:-----|:------|
| **builder** | TDD implementation, self-review, commits | Sonnet |
| **planner** | Task breakdown, verifies entity names against codebase | inherit |
| **researcher** | Fast background codebase exploration | Sonnet |
| **task-reviewer** | Spec + Quality verdicts on a lane diff (opt-in) | Sonnet |
| **code-reviewer** | Holistic pre-merge assessment | Sonnet |
| **verifier** | Tries to refute one finding or review comment; read-only | Sonnet |

All agents except the verifier have `memory: project` for persistent codebase knowledge across sessions; the verifier judges each finding fresh.

## Hooks

| Hook | When | What |
|:-----|:-----|:-----|
| **SessionStart** | Start of session | Loads `ATLAS.md` Where to Look table, injects CodeMap stats when `.codemap/` present, restores session snapshot, flags a missing CLAUDE.md (AGENTS.md-aware, including an AGENTS.md that `CLAUDE.local.md` may keep from loading) or ATLAS.md, checks ATLAS staleness. Each section is capped so the output stays under Claude Code's 10,000-char inline limit |

### What the hooks do

`hooks/session-start.sh` runs whenever a session starts, resumes, or is cleared or compacted. It is read-only: it prints text to stdout and does nothing else. It writes no files, changes no settings or permissions, and sends nothing over the network itself. What it prints becomes part of the session context, so it reaches the model like any file Claude reads.

| It reads | Why |
|:---------|:----|
| The plugin's own `hooks/*.md` | Bootstrap text and setup nudges |
| `ATLAS.md` | Its Where to Look table and its `atlas-hash` footer |
| `.claude/turbocharge-session.json` | The snapshot your last `/turbocharge:wrap` wrote, or the 3.0–3.1 `.claude/turboflow-session.json` when that one is newer |
| Whether `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md` or `AGENTS.md` exist | To pick a setup nudge. Their contents are never read |
| Top-level file and folder names | Hashed with `md5sum` (or `md5` on macOS) to spot a stale `ATLAS.md` |

| It runs | When |
|:--------|:-----|
| `codemap stats` | Only when the project has a `.codemap/` index and the `codemap` CLI is installed |

## What the skills run and send

Only `ship` reaches a remote, and only through the git and GitHub CLI already set up on your machine:

| Skill | It runs | When |
|:------|:--------|:-----|
| **ship** | `git pull` on the base branch, then a local merge | Option 1, merge locally |
| **ship** | `git push` of the feature branch to `origin`, then `gh pr create` | Option 2, push and open a pull request |

Ship runs neither until you pick the option. Triaging review comments changes the branch locally and never pushes or posts: you post the drafted replies.

The other skills stay on your machine:
- **setup** runs `claude plugin list --json` and `claude plugin details turbocharge`, and reads `~/.claude/agents/` and `~/.claude/rules/common/` to find overlaps. It changes those files only after you agree, and shows the diff before it writes your CLAUDE.md.
- **wrap** writes `.claude/turbocharge-session.json` in the project and adds notes under `~/.claude/projects/<project>/memory/`. With a `.codemap/` index it runs `codemap update`.
- **atlas** writes `ATLAS.md`. **build** and its builders commit to your local branch.

Nothing else sends or fetches anything: no skill or agent tells Claude to use the web, and the plugin sends no telemetry.

## Quick Start Examples

```bash
# Full pipeline from scratch
/turbocharge:brainstorm I want to build a REST API for managing bookmarks

# Jump to planning with existing requirements
/turbocharge:plan docs/plans/my-feature-stories.md

# Debug a specific issue
/turbocharge:debug The CSV export drops rows that contain commas

# Wrap up your session
/turbocharge:wrap
```

See [`examples/`](https://github.com/nicodiansk/turbocharge/tree/master/examples) for sample outputs from each stage.

## What to Remove After Installing

Turbocharge replaces scattered config. `/turbocharge:setup` handles this, but in short:

- Agents in `~/.claude/agents/` (planner, code-reviewer, tdd-guide, session-wrappers)
- Commands in `.claude/commands/` for story-authoring, task-breakdown, session-wrap
- Rule files that reference competing agents

## License

MIT — see [LICENSE](LICENSE). Parts of the debug, ship and plan skills are adapted from another MIT-licensed project; [NOTICE](NOTICE) has its copyright and license.

---

<p align="center">
  <sub>Built by <a href="https://github.com/nicodiansk">@nicodiansk</a> — one pipeline to replace them all.</sub>
</p>
