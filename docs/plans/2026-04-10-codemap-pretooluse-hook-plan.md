# Codemap PreToolUse Hook — Implementation Plan

**Goal:** Inject a codemap reminder when Claude reads files in projects that have a `.codemap/` index.
**Architecture:** Single PreToolUse hook on Read that checks for `.codemap/` directory and outputs a short nudge to stdout. Non-blocking — the Read proceeds regardless.
**Tech Stack:** Bash hook script, JSON hook registration

---

### Task 1: Create the hook script

**Files:**
- Create: `hooks/pretool-read-codemap.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
# ABOUTME: PreToolUse hook for Read — nudges codemap usage when .codemap/ index exists.
# ABOUTME: Non-blocking: outputs reminder but does not prevent the Read.

# .codemap/ in working directory means the project has a codemap index
if [ -d ".codemap" ]; then
    echo ".codemap/ index found. Before reading full files, try \`codemap find \"SymbolName\"\` or \`codemap show path/to/file\` to locate the exact line range you need — then read only that range."
fi
```

**Step 2: Verify script is valid**
Run: `bash -n hooks/pretool-read-codemap.sh`
Expected: no output (syntax OK)

**Step 3: Test behavior with and without .codemap/**
Run: `cd /tmp && mkdir -p test-hook && cd test-hook && bash /path/to/hooks/pretool-read-codemap.sh`
Expected: no output (no .codemap/)

Run: `mkdir .codemap && bash /path/to/hooks/pretool-read-codemap.sh`
Expected: reminder message printed

---

### Task 2: Register the hook in hooks.json

**Files:**
- Modify: `hooks/hooks.json`

**Step 1: Add PreToolUse entry**

Add `PreToolUse` key to the hooks object, alongside existing `SessionStart` and `Stop`:

```json
"PreToolUse": [
  {
    "matcher": "Read",
    "hooks": [
      {
        "type": "command",
        "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/pretool-read-codemap.sh\""
      }
    ]
  }
]
```

**Step 2: Validate JSON**
Run: `python -c "import json; json.load(open('hooks/hooks.json'))"`
Expected: no error

**Step 3: Run plugin validation**
Run: `./scripts/validate.sh`
Expected: PASSED

---

### Task 3: Bump version to 2.2.1

**Files:**
- Modify: `.claude-plugin/plugin.json`

**Step 1: Update version**
Change `"version": "2.2.0"` → `"version": "2.2.1"`

**Step 2: Run plugin validation**
Run: `./scripts/validate.sh`
Expected: PASSED

**Step 3: Commit**
`git commit -m "feat: PreToolUse hook nudges codemap usage on Read"`
