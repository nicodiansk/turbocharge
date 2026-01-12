# Turbocharge Standalone Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use turbocharge:executing-plans to implement this plan task-by-task.

**Goal:** Make turbocharge a fully functional standalone Claude Code plugin with working commands, hooks, and no superpowers references.

**Architecture:** Replicate superpowers plugin infrastructure (hooks, commands) with turbocharge branding. Keep all existing skills. Focus unique value on epic/story generation workflow.

**Tech Stack:** Bash scripts, JSON config, Markdown commands, Claude Code plugin system

---

## Phase 1: Hooks Infrastructure

Create the session startup hooks that auto-load the using-turbocharge skill.

### Task 1.1: Create hooks.json

**Files:**
- Create: `turbocharge/hooks/hooks.json`
- Delete: `turbocharge/hooks/.gitkeep`

**Step 1: Write hooks.json**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start.sh"
          }
        ]
      }
    ]
  }
}
```

**Step 2: Remove .gitkeep**

Run: `rm turbocharge/hooks/.gitkeep`

**Step 3: Verify JSON is valid**

Run: `cat turbocharge/hooks/hooks.json | python -m json.tool`
Expected: Pretty-printed JSON output

---

### Task 1.2: Create run-hook.cmd (Polyglot Wrapper)

**Files:**
- Create: `turbocharge/hooks/run-hook.cmd`

**Step 1: Write polyglot script**

```cmd
: << 'CMDBLOCK'
@echo off
REM Polyglot wrapper: runs .sh scripts cross-platform
REM Usage: run-hook.cmd <script-name> [args...]
REM The script should be in the same directory as this wrapper

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)
"C:\Program Files\Git\bin\bash.exe" -l "%~dp0%~1" %2 %3 %4 %5 %6 %7 %8 %9
exit /b
CMDBLOCK

# Unix shell runs from here
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
"${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

**Step 2: Verify file exists**

Run: `ls -la turbocharge/hooks/run-hook.cmd`
Expected: File exists

---

### Task 1.3: Create session-start.sh

**Files:**
- Create: `turbocharge/hooks/session-start.sh`

**Step 1: Write session-start hook**

```bash
#!/usr/bin/env bash
# ABOUTME: SessionStart hook for turbocharge plugin
# ABOUTME: Loads using-turbocharge skill into conversation context on startup

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read using-turbocharge content
using_turbocharge_content=$(cat "${PLUGIN_ROOT}/skills/using-turbocharge/SKILL.md" 2>&1 || echo "Error reading using-turbocharge skill")

# Escape outputs for JSON using pure bash
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            $'\\') output+='\\' ;;
            '"') output+='\"' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *) output+="$char" ;;
        esac
    done
    printf '%s' "$output"
}

using_turbocharge_escaped=$(escape_for_json "$using_turbocharge_content")

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have turbocharge skills.\n\n**Below is the full content of your 'turbocharge:using-turbocharge' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${using_turbocharge_escaped}\n\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
```

**Step 2: Make executable**

Run: `chmod +x turbocharge/hooks/session-start.sh`

**Step 3: Verify script runs**

Run: `cd turbocharge && bash hooks/session-start.sh | head -5`
Expected: JSON output starting with `{`

**Step 4: Commit hooks**

```bash
cd turbocharge
git add hooks/
git commit -m "feat(hooks): add session startup hooks"
```

---

## Phase 2: Commands

Create slash commands that trigger skills. Commands are simple wrappers.

### Task 2.1: Create brainstorm command

**Files:**
- Create: `turbocharge/commands/brainstorm.md`

**Step 1: Write command**

```markdown
---
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores requirements and design before implementation."
---

Use and follow the brainstorming skill exactly as written
```

**Step 2: Verify file**

Run: `cat turbocharge/commands/brainstorm.md`

---

### Task 2.2: Create write-plan command

**Files:**
- Create: `turbocharge/commands/write-plan.md`

**Step 1: Write command**

```markdown
---
description: Create detailed implementation plan with bite-sized tasks
---

Use the writing-plans skill exactly as written
```

---

### Task 2.3: Create execute-plan command

**Files:**
- Create: `turbocharge/commands/execute-plan.md`

**Step 1: Write command**

```markdown
---
description: Execute plan in batches with review checkpoints
---

Use the executing-plans skill exactly as written
```

---

### Task 2.4: Create story command (TURBOCHARGE UNIQUE)

**Files:**
- Create: `turbocharge/commands/story.md`

**Step 1: Write command**

```markdown
---
description: "Transform requirements into INVEST-compliant user stories with testable acceptance criteria"
---

Use the story-breakdown skill to create user stories.

Focus on:
- Single user story (not epic)
- INVEST criteria compliance
- Given/When/Then acceptance criteria
- Appropriate sizing (1-5 points)
```

---

### Task 2.5: Create epic command (TURBOCHARGE UNIQUE)

**Files:**
- Create: `turbocharge/commands/epic.md`

**Step 1: Write command**

```markdown
---
description: "Break down large requirements into epic with child stories"
---

Use the story-breakdown skill to create an epic.

Focus on:
- Epic-level scope with multiple stories
- Problem statement and success metrics
- Child stories with acceptance criteria
- Dependencies and risks identified
```

---

### Task 2.6: Create review command

**Files:**
- Create: `turbocharge/commands/review.md`

**Step 1: Write command**

```markdown
---
description: Request code review before merging
---

Use the requesting-code-review skill exactly as written
```

---

### Task 2.7: Create debug command

**Files:**
- Create: `turbocharge/commands/debug.md`

**Step 1: Write command**

```markdown
---
description: Systematic debugging with root cause analysis
---

Use the systematic-debugging skill exactly as written
```

---

### Task 2.8: Create tdd command

**Files:**
- Create: `turbocharge/commands/tdd.md`

**Step 1: Write command**

```markdown
---
description: Test-driven development workflow
---

Use the test-driven-development skill exactly as written
```

---

### Task 2.9: Remove .gitkeep and commit commands

**Files:**
- Delete: `turbocharge/commands/.gitkeep`

**Step 1: Remove placeholder**

Run: `rm turbocharge/commands/.gitkeep`

**Step 2: Commit commands**

```bash
cd turbocharge
git add commands/
git commit -m "feat(commands): add 8 slash commands"
```

---

## Phase 3: Cleanup Superpowers References

Remove any mention of superpowers from turbocharge files.

### Task 3.1: Update session-memory skill

**Files:**
- Modify: `turbocharge/skills/session-memory/SKILL.md`

**Step 1: Fix example JSON**

Change line 108 from:
```
"context": "Discovered while implementing turbocharge from superpowers",
```
To:
```
"context": "Discovered while implementing turbocharge plugin",
```

**Step 2: Fix dependencies reference**

Change lines 130-132 from:
```json
"dependencies": {
  "reference": "superpowers plugin",
  "target": "Claude Code plugin system"
}
```
To:
```json
"dependencies": {
  "target": "Claude Code plugin system"
}
```

**Step 3: Commit cleanup**

```bash
cd turbocharge
git add skills/session-memory/SKILL.md
git commit -m "fix(skills): remove external references from session-memory"
```

---

## Phase 4: Update README

Update README to reflect actual state (no /tc: prefix - commands work as standard slash commands).

### Task 4.1: Update README commands section

**Files:**
- Modify: `turbocharge/README.md`

**Step 1: Update commands table**

Replace the commands section with:

```markdown
### Commands (8 total)

| Command | Description |
|---------|-------------|
| `/brainstorm` | Interactive requirements discovery |
| `/write-plan` | Create implementation plan |
| `/execute-plan` | Execute plan with checkpoints |
| `/epic` | Generate epic from requirements |
| `/story` | Generate user stories |
| `/review` | Request code review |
| `/debug` | Systematic debugging |
| `/tdd` | Test-driven development |
```

**Step 2: Update directory structure**

Ensure the docs section reflects reality - remove `docs/templates/` reference if it doesn't exist.

**Step 3: Remove session-wrap command reference**

The `/tc:session-wrap` and `/tc:memory` commands were aspirational. Remove or mark as planned.

**Step 4: Commit README**

```bash
cd turbocharge
git add README.md
git commit -m "docs: update README to reflect actual commands"
```

---

## Phase 5: Final Verification

### Task 5.1: Verify no superpowers references remain

**Step 1: Search for references**

Run: `grep -r "superpowers" turbocharge/ --include="*.md" --include="*.json" --include="*.sh" --include="*.js"`
Expected: No output (no matches)

**Step 2: Verify plugin structure**

Run: `find turbocharge -type f \( -name "*.md" -o -name "*.json" -o -name "*.sh" -o -name "*.js" \) | wc -l`
Expected: ~40-50 files

---

### Task 5.2: Test hooks locally

**Step 1: Run session-start hook**

Run: `cd turbocharge && bash hooks/session-start.sh`
Expected: Valid JSON with using-turbocharge content

**Step 2: Validate hooks.json**

Run: `python -m json.tool turbocharge/hooks/hooks.json`
Expected: Valid JSON output

---

### Task 5.3: Create feature completion commit

**Step 1: Final git status**

Run: `cd turbocharge && git status`
Expected: Clean working tree

**Step 2: Push branch**

Run: `cd turbocharge && git push origin feature/agents`

---

## Summary

After completing this plan:

- **Hooks:** Session startup loads using-turbocharge automatically
- **Commands:** 8 working slash commands (brainstorm, write-plan, execute-plan, epic, story, review, debug, tdd)
- **Skills:** 16 skills unchanged
- **Agents:** 7 agents unchanged
- **Branding:** No superpowers references - fully standalone

**Unique turbocharge value:**
- `/epic` and `/story` commands for product → development workflow
- story-breakdown skill with INVEST criteria
- story-writer agent for requirements transformation
- session-memory skill for context persistence
