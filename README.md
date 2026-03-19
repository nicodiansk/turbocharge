# Turbocharge

A Claude Code plugin that acts as your tech lead — orchestrating agents through an opinionated product development pipeline from brainstorm to shipped code.

## Quick Start

```bash
# Load the plugin
claude --plugin-dir ./turbocharge

# Start building something
/turbocharge:brainstorm I want to build a CLI tool that manages git worktrees

# Or jump straight to planning if you already have requirements
/turbocharge:plan docs/plans/my-feature-stories.md

# When you're done for the day
/turbocharge:wrap
```

See `examples/` for sample outputs from each stage of the pipeline.

## Installation

**Development (per-session):**
```bash
claude --plugin-dir ./turbocharge
```

**Persistent (own marketplace):**
```bash
claude /plugin marketplace add https://github.com/nicodiansk/turbocharge
claude /plugin install turbocharge
```

## The Workflow

```
brainstorm → story → plan → build → review → ship
                                 ↑               |
                               debug            wrap
```

Each skill chains to the next. `debug` is a side-branch invoked on bugs. `wrap` captures session state for resumption.

## Skills (8)

| Skill | Command | Description |
|-------|---------|-------------|
| brainstorm | `/turbocharge:brainstorm` | Socratic requirements discovery before implementation |
| story | `/turbocharge:story` | INVEST-compliant story breakdown with acceptance criteria |
| plan | `/turbocharge:plan` | Bite-sized task decomposition (2-5 min tasks, exact paths, complete code) |
| build | `/turbocharge:build` | Plan execution with builder→spec-reviewer→quality-reviewer chain |
| review | `/turbocharge:review` | Holistic pre-merge code review against the original plan |
| debug | `/turbocharge:debug` | Systematic root-cause debugging (4-phase investigation) |
| ship | `/turbocharge:ship` | Branch completion: test verification, merge/PR/keep/discard options |
| wrap | `/turbocharge:wrap` | Session continuity — captures state, generates resume prompt |

## Agents (6)

| Agent | Role | Key Properties |
|-------|------|----------------|
| builder | Implements tasks following TDD | `isolation: worktree`, full tool access |
| spec-reviewer | Verifies implementations match spec | Read-only, doesn't trust builder reports |
| quality-reviewer | Assesses code quality and production readiness | Read-only, categorized issue reporting |
| code-reviewer | Holistic pre-merge assessment | Read-only, runs once after all tasks complete |
| planner | Creates detailed implementation plans | Read-only, 2-5 minute task sizing |
| researcher | Deep codebase exploration | Read-only, `model: haiku`, `background: true` |

All agents have `memory: project` for persistent codebase knowledge across sessions.

## How Build Works

The `build` skill orchestrates a review chain for every task:

```
For each task:
  1. Dispatch builder (implements with TDD in isolated worktree)
  2. Dispatch spec-reviewer (verifies against plan)
  3. Dispatch quality-reviewer (checks code quality)
  4. If issues → send back to builder → re-review
  5. Mark complete

Every 3 tasks → checkpoint with human for feedback
```

**Multi-track mode** (Agent Teams): Independent tasks can run in parallel with coordinated builders. Requires opt-in:

```bash
# Enable Agent Teams (experimental) in your Claude Code settings
claude config set env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1
```

## Validation

Run the plugin validation script to check structural integrity:

```bash
./scripts/validate.sh
```

## Directory Structure

```
turbocharge/
├── .claude-plugin/
│   ├── plugin.json            # Plugin manifest (v2.0.0)
│   └── marketplace.json       # For self-hosted distribution
├── skills/                    # 8 skill definitions
│   └── <skill-name>/
│       └── SKILL.md
├── agents/                    # 6 agent definitions
│   └── <agent-name>.md
├── hooks/
│   └── hooks.json             # Stop hook (wrap reminder)
├── scripts/
│   └── validate.sh            # Plugin health check
├── examples/                  # Sample pipeline outputs
├── settings.json              # Plugin settings
├── docs/
│   └── plans/                 # Implementation plans
├── CHANGELOG.md
└── README.md
```

## License

MIT License - See [LICENSE](LICENSE) for details.
