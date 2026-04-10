# SessionStart Hook Enhancement — CLAUDE.md & ATLAS.md Nudge

**Goal:** Make the SessionStart hook detect missing CLAUDE.md and ATLAS.md, nudging users to bootstrap their project for turbocharge compatibility.
**Architecture:** Replace the static `cat` hook command with a shell script that always outputs the bootstrap content, then conditionally appends nudge messages based on file existence checks in the working directory.
**Tech Stack:** Bash shell script, markdown content files

---

## Task 1: Create CLAUDE.md nudge content

**Files:**
- Create: `hooks/missing-claudemd-nudge.md`

**Step 1: Write the content**

The nudge should:
- Tell Claude to suggest `/init` to the user
- List turbocharge-specific sections to add after `/init` runs
- Be concise — this is injected into context every session where CLAUDE.md is missing

```markdown
## ⚠ No CLAUDE.md Detected

This project has no `CLAUDE.md`. Suggest the user run `/init` to generate one.

After `/init`, suggest adding these turbocharge-compatible sections:

### Domain Terms
A table mapping project-specific vocabulary so all skills share a common language:
```
| Term | Definition |
|------|------------|
| Example | What this term means in this project |
```

### ABOUTME Convention
Every file should start with a 2-line comment describing what it does:
```
# ABOUTME: What this file does.
# ABOUTME: Key detail about its role.
```

### TDD Workflow
A section describing the project's test-first expectations so `/turbocharge:build` can enforce them.

### Debugging Protocol
A section describing systematic debugging expectations so `/turbocharge:debug` can follow them.

### Naming Conventions
Rules for naming files, functions, variables — avoids style arguments during build/review.
```

**Step 2: Verify**
Run: `cat hooks/missing-claudemd-nudge.md`
Expected: content renders correctly, no broken markdown

**Step 3: Commit**
`git commit -m "feat: add CLAUDE.md nudge content for session-start hook"`

---

## Task 2: Create session-start.sh script

**Files:**
- Create: `hooks/session-start.sh`

**Step 1: Write a verification test**

Create a minimal test that runs the script in different scenarios:

```bash
# Test from a temp directory with no CLAUDE.md or ATLAS.md
cd /tmp && bash /path/to/hooks/session-start.sh | grep -q "No CLAUDE.md Detected"
# Test from a directory with CLAUDE.md present
cd /tmp && touch CLAUDE.md && bash /path/to/hooks/session-start.sh | grep -qv "No CLAUDE.md Detected"
```

**Step 2: Run test to verify it fails**
Run: `bash hooks/session-start.sh`
Expected: FAIL — file doesn't exist yet

**Step 3: Write the script**

```bash
#!/usr/bin/env bash
# ABOUTME: SessionStart hook script for turbocharge plugin.
# ABOUTME: Outputs bootstrap content, checks for missing CLAUDE.md and ATLAS.md.

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always output the bootstrap content
cat "$HOOK_DIR/session-bootstrap.md"

# Check for CLAUDE.md in working directory
if [ ! -f "CLAUDE.md" ]; then
    echo ""
    cat "$HOOK_DIR/missing-claudemd-nudge.md"
fi

# Check for ATLAS.md in working directory
if [ ! -f "ATLAS.md" ]; then
    echo ""
    echo "## 📍 No ATLAS.md Detected"
    echo ""
    echo "This project has no \`ATLAS.md\` domain map. Suggest the user run \`/turbocharge:atlas\` to generate one."
fi
```

**Step 4: Run verification**
Run: `bash hooks/session-start.sh` from a directory without CLAUDE.md
Expected: outputs bootstrap content + CLAUDE.md nudge + ATLAS.md nudge

Run: `bash hooks/session-start.sh` from the turbocharge repo root (has CLAUDE.md)
Expected: outputs bootstrap content + ATLAS.md nudge only (no CLAUDE.md nudge)

**Step 5: Commit**
`git commit -m "feat: add session-start.sh with CLAUDE.md and ATLAS.md detection"`

---

## Task 3: Update hooks.json and validate

**Files:**
- Modify: `hooks/hooks.json`

**Step 1: Update the SessionStart command**

Change from:
```json
"command": "cat \"${CLAUDE_PLUGIN_ROOT}/hooks/session-bootstrap.md\""
```

To:
```json
"command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh\""
```

**Step 2: Run validate.sh**
Run: `bash scripts/validate.sh`
Expected: PASS — no errors (hooks.json still exists, structure unchanged)

**Step 3: Manual integration test**

Run the hook command as Claude Code would:
```bash
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/session-start.sh
```
Expected: full bootstrap output + conditional nudges based on current directory state

**Step 4: Commit**
`git commit -m "feat: wire session-start.sh into hooks.json"`

---

## Summary

| Task | Files | Minutes |
|------|-------|---------|
| 1. Nudge content | Create `hooks/missing-claudemd-nudge.md` | 2 |
| 2. Shell script | Create `hooks/session-start.sh` | 3 |
| 3. Wire up + validate | Modify `hooks/hooks.json` | 2 |
| **Total** | **2 new, 1 modified** | **~7 min** |

Assumptions:
- `CLAUDE_PLUGIN_ROOT` is set by Claude Code before hook execution (verified by existing hook usage)
- The working directory at hook execution time is the user's project root (where CLAUDE.md would live)
- `bash` is available on all target platforms (Windows Git Bash, macOS, Linux)
