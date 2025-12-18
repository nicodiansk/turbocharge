---
name: session-memory
description: Use when starting or ending sessions to maintain context across conversations - loads previous decisions at session start, offers to persist learnings at session end
---

# Session Memory

## Overview

Maintain context across sessions. Never lose decisions, learnings, or context.

**Core principle:** If it was worth deciding, it's worth remembering.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Session Start:**
- Beginning new conversation
- Resuming after break
- Switching contexts
- "/tc:memory load" command

**During Session:**
- Significant decisions made
- Problems solved with non-obvious solutions
- User preferences discovered
- Blockers identified

**Session End:**
- Completing task
- Taking break
- Ending conversation
- "/tc:memory save" command

**Keywords that trigger this skill:**
- session, context, remember
- "where were we", "what did we decide"
- "save progress", "load context"

## The Iron Law

```
NO SESSION END WITHOUT MEMORY SAVE OFFER
```

Before ending any significant session, offer to save context.

**No exceptions:**
- Don't assume user will remember
- Don't skip for "short" sessions
- Don't wait for user to ask
- Proactively offer

## Memory Location

```
.turbocharge/memory/
├── session.json          # Current session state
├── decisions.json        # Architectural/design decisions
├── learnings.json        # Lessons learned
└── project-context.json  # Project-specific knowledge
```

**Important:** Add `.turbocharge/memory/` to `.gitignore` - memory is personal, not shared.

## Memory Schema

### session.json
```json
{
  "project": "project-name",
  "lastUpdated": "2025-12-18T10:30:00Z",
  "currentPhase": "Phase 4: New Skills",
  "activeTask": "Implementing session-memory skill",
  "blockers": [],
  "nextSteps": [
    "Complete session-memory SKILL.md",
    "Create PR for Phase 4"
  ]
}
```

### decisions.json
```json
{
  "decisions": [
    {
      "date": "2025-12-18",
      "topic": "Memory file format",
      "decision": "Use JSON for structured data",
      "rationale": "Easy to parse, human-readable, supports schema validation",
      "alternatives": ["YAML", "Markdown", "SQLite"],
      "context": "Needed format for session memory persistence"
    }
  ]
}
```

### learnings.json
```json
{
  "learnings": [
    {
      "date": "2025-12-18",
      "category": "workflow",
      "learning": "Always copy skills before adapting them",
      "context": "Discovered while implementing turbocharge from superpowers",
      "applies_to": ["similar migrations", "framework adoption"]
    }
  ]
}
```

### project-context.json
```json
{
  "name": "turbocharge",
  "type": "claude-code-plugin",
  "structure": {
    "skills": "skills/*/SKILL.md",
    "agents": "agents/*.md",
    "commands": "commands/*.md"
  },
  "conventions": {
    "branch_prefix": "feature/",
    "commit_format": "feat(scope): description",
    "pr_workflow": "branch → PR → Claude review → merge"
  },
  "dependencies": {
    "reference": "superpowers plugin",
    "target": "Claude Code plugin system"
  }
}
```

## Session Protocols

### Session Start Protocol

```
1. CHECK: Does .turbocharge/memory/ exist?
   - Yes → Load and summarize
   - No → Offer to initialize

2. LOAD: Read session.json
   - Report current phase
   - Report active task
   - Report blockers
   - Report next steps

3. SUMMARIZE: Brief context for user
   "Last session: [phase], working on [task]"
   "Next steps: [list]"
   "Blockers: [list or 'none']"

4. CONFIRM: Ask user to verify context
   "Does this match where you want to continue?"
```

### During Session Protocol

**Record decisions when:**
- Choosing between alternatives
- Establishing conventions
- Making architectural choices
- User expresses preference

**Record learnings when:**
- Problem solved non-obviously
- Mistake made and corrected
- Pattern discovered
- Best practice identified

**Update session state when:**
- Task completed
- Phase changed
- Blocker discovered
- Next steps clarified

### Session End Protocol

```
1. DETECT: Signs session is ending
   - User says goodbye/thanks
   - Task completed
   - Natural stopping point
   - User idle

2. SUMMARIZE: What happened this session
   - Decisions made
   - Tasks completed
   - Learnings captured
   - New blockers

3. OFFER: "Would you like to save session context?"
   - Yes → Write to memory files
   - No → Acknowledge, no save

4. PROVIDE: Resume prompt for next session
   "To continue: [brief context]"
   "Next steps: [prioritized list]"
```

## Memory Operations

### Load Memory
```
Function: Load all memory files, construct context

Steps:
1. Read session.json → current state
2. Read decisions.json → recent decisions (last 10)
3. Read learnings.json → relevant learnings
4. Read project-context.json → project knowledge

Output:
- Structured context summary
- Suggested starting point
- Outstanding blockers
```

### Save Memory
```
Function: Persist current session state

Steps:
1. Update session.json with current state
2. Append new decisions to decisions.json
3. Append new learnings to learnings.json
4. Update project-context.json if conventions changed

Output:
- Confirmation of saved items
- Summary for next session
```

### Clear Memory
```
Function: Reset memory (use with caution)

Steps:
1. Confirm with user
2. Archive existing memory (optional)
3. Remove memory files
4. Reinitialize empty structure

Use when:
- Project completed
- Context no longer relevant
- Starting fresh
```

## Red Flags - STOP

| Flag | Problem |
|------|---------|
| No memory check at start | Missing context from previous sessions |
| No save offer at end | Losing decisions and learnings |
| Memory files in git | Personal context shared inappropriately |
| Decisions without rationale | Can't understand why later |
| Stale session.json | Context doesn't match reality |
| Memory never cleared | Irrelevant old context confusing |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll remember" | You won't. Neither will the next session. |
| "It's obvious" | Obvious today, mysterious tomorrow. |
| "Too minor to save" | Minor decisions compound. Save them. |
| "User didn't ask" | User expects you to manage context. |
| "Just a quick session" | Quick sessions have important decisions too. |
| "Memory is overhead" | Forgetting is more expensive. |
| "Project too simple" | Simple projects still have decisions. |
| "Will save at end" | End comes suddenly. Save incrementally. |

## Integration

### Workflow Position
```
session-memory (start) → [any workflow] → session-memory (end)
```

### Agents
- **session-manager**: Handles memory operations

### Hooks
- **SessionStart**: Trigger memory load
- **SessionEnd**: Trigger save offer

### Commands
- `/tc:memory load` - Load and display context
- `/tc:memory save` - Save current context
- `/tc:memory clear` - Clear with confirmation

## Example: Session Flow

### Session Start
```
User: Let's continue working on turbocharge

Claude: [Loads memory]

📋 Session Context:
- Project: turbocharge (Claude Code plugin)
- Last session: 2025-12-17
- Phase: Phase 3 - Copied Skills
- Completed: 13 skills copied and adapted

⏳ In Progress:
- PR #4 waiting for review

📌 Next Steps:
1. Merge PR #4 after approval
2. Start Phase 4: New Skills
3. Create story-breakdown skill

🚧 Blockers: None

Does this match where you want to continue?
```

### During Session
```
User: Let's use Given/When/Then for acceptance criteria

Claude: [Records decision]
Decision recorded:
- Topic: Acceptance criteria format
- Decision: Given/When/Then (Gherkin)
- Rationale: Standard BDD format, testable, clear structure

Continuing with story-breakdown skill...
```

### Session End
```
User: Good progress today, let's wrap up

Claude: [Triggers end protocol]

📊 Session Summary:
- Completed: story-breakdown skill
- Completed: session-memory skill
- Decisions: 2 (AC format, memory schema)
- Learnings: 1 (INVEST split patterns)

💾 Save session context?

If yes, here's your resume prompt:
"Continue turbocharge Phase 4 - skills complete,
ready for git commit and PR creation"
```

## Verification Checklist

Before ending session:

- [ ] Memory loaded at session start (or initialized)
- [ ] Significant decisions recorded with rationale
- [ ] Session state reflects current reality
- [ ] Save offered before ending
- [ ] Resume prompt provided if saved
- [ ] No memory files committed to git

Can't check all boxes? Session context may be lost.

## File Initialization

When `.turbocharge/memory/` doesn't exist:

```javascript
// Initialize memory structure
const initMemory = {
  session: {
    project: "",
    lastUpdated: new Date().toISOString(),
    currentPhase: "",
    activeTask: "",
    blockers: [],
    nextSteps: []
  },
  decisions: { decisions: [] },
  learnings: { learnings: [] },
  projectContext: {
    name: "",
    type: "",
    structure: {},
    conventions: {},
    dependencies: {}
  }
};
```

Prompt user to fill in project details on first initialization.
