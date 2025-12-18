# Turbocharge

A Claude Code plugin that provides development skills, collaboration patterns, and product development workflows including epic/story generation.

## Installation

Add turbocharge to your Claude Code plugins:

```bash
claude plugins add /path/to/turbocharge
```

## Features

### Skills (16 total)

Turbocharge provides 16 skills organized by workflow:

**Core Process Skills**
- `using-turbocharge` - Meta-skill for skill discovery and invocation
- `brainstorming` - Collaborative requirements discovery
- `writing-plans` - Detailed implementation planning
- `executing-plans` - Batch execution with review checkpoints

**Development Skills**
- `test-driven-development` - TDD workflow enforcement
- `systematic-debugging` - Root cause analysis framework
- `subagent-driven-development` - Task delegation with reviews
- `verification-before-completion` - Evidence before assertions

**Collaboration Skills**
- `requesting-code-review` - Dispatch code reviewer agent
- `receiving-code-review` - Handle review feedback properly
- `finishing-a-development-branch` - Branch completion workflow
- `dispatching-parallel-agents` - Concurrent agent operations

**Infrastructure Skills**
- `using-git-worktrees` - Isolated workspace management
- `writing-skills` - Create and test skill definitions

**Product Development Skills** (Turbocharge Exclusive)
- `story-breakdown` - Transform requirements into INVEST stories
- `session-memory` - Cross-session context persistence

### Commands (8 total)

| Command | Description |
|---------|-------------|
| `/tc:brainstorm` | Interactive requirements discovery |
| `/tc:write-plan` | Create implementation plan |
| `/tc:execute-plan` | Execute plan with checkpoints |
| `/tc:epic` | Generate epic from requirements |
| `/tc:story` | Generate user stories |
| `/tc:memory` | Manage session memory |
| `/tc:review` | Request code review |
| `/tc:session-wrap` | Wrap up session with handoff |

### Agents (7 total)

**Development Team**
- `implementer` - Task execution with TDD
- `spec-reviewer` - Requirements compliance check
- `quality-reviewer` - Code quality assessment
- `code-reviewer` - Final holistic review

**Support Agents**
- `planner` - Implementation plan creation
- `story-writer` - Epic and story generation
- `session-manager` - Context persistence

## Architecture

Turbocharge uses a "baton-passing" workflow where skills dispatch agents and hand off to each other:

```
using-turbocharge (orchestrator)
       |
       +---> brainstorming --> planner --> subagent-driven-development
       |                                          |
       |                    +---------------------+---------------------+
       |                    v                     v                     v
       |              implementer --> spec-reviewer --> quality-reviewer
       |                    ^                                           |
       |                    +-------- (fix loop) -----------------------+
       |                                          |
       |                    code-reviewer (final) --> finishing-branch
       |
       +---> systematic-debugging --> implementer (fix) --> code-reviewer
       |
       +---> story-breakdown --> story-writer --> planner
```

## How It Works

### Skill Invocation

Before EVERY response, Claude checks if any skill applies. Even a 1% chance means invoking the skill first.

```
User message received
       |
       v
Might any skill apply?
       |
   +---+---+
   |       |
  YES     NO
   |       |
   v       v
Invoke  Respond
Skill   directly
```

### Session Memory

Turbocharge maintains context across sessions via `.turbocharge/memory/`:

- Decisions and rationale
- Architectural choices
- User preferences
- In-progress work state

## Directory Structure

```
turbocharge/
├── .claude-plugin/
│   └── plugin.json         # Plugin manifest
├── skills/                  # 16 skill definitions
│   └── <skill-name>/
│       └── SKILL.md
├── agents/                  # 7 agent definitions
│   └── <agent-name>.md
├── commands/                # 8 slash commands
│   └── <command>.md
├── hooks/                   # Session hooks
│   └── hooks.json
├── lib/
│   └── skills-core.js      # Skill resolution library
├── docs/
│   ├── templates/          # Epic, story, PR templates
│   └── plans/              # Implementation plans
└── README.md
```

## License

MIT License - See [LICENSE](LICENSE) for details.

