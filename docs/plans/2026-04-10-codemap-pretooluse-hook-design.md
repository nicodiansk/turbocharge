# Codemap PreToolUse Hook — Design

**Date:** 2026-04-10
**Status:** Approved
**Skill:** brainstorm → plan

## Problem

Claude defaults to reading full files (~1,950 tokens) even when a codemap index exists that could narrow the read to ~250 tokens (~87% reduction). The codemap skill description appears in the available skills list, but Claude ignores it because the information isn't present at the point of decision — the moment Claude reaches for the Read tool.

## Solution

A single **PreToolUse hook on Read** that detects `.codemap/` in the project and injects a short reminder before the read proceeds.

## Design

### Hook Registration

Add to `hooks/hooks.json`:

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

### Hook Script: `hooks/pretool-read-codemap.sh`

- Check if `.codemap/` exists in the working directory
- If yes → print reminder message to stdout
- If no → exit silently (no output = no noise)
- Non-blocking: does NOT prevent the Read from proceeding

### Reminder Message

```
.codemap/ index found. Before reading full files, try `codemap find "SymbolName"` or `codemap show path/to/file` to locate the exact line range you need — then read only that range.
```

## What We're NOT Building

- No SessionStart nudge for codemap (don't nag users who haven't installed it)
- No CLAUDE.md instructions (background noise, doesn't change behavior)
- No hard blocking of Read (soft nudge only)
- No setup changes
- No codemap plugin detection (only check for `.codemap/` directory)

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Discovery vs enforcement | Enforcement only | Users who installed codemap don't need to be told it exists |
| Hard gate vs soft nudge | Soft nudge | Blocking Read would be annoying for legitimate full-file reads |
| Detect plugin vs detect index | Detect `.codemap/` only | Simpler, no coupling to plugin cache paths |
| CLAUDE.md instructions | Skip | Doesn't change behavior at point of decision |

## Scope

- 1 new file: `hooks/pretool-read-codemap.sh`
- 1 modified file: `hooks/hooks.json`
- Version bump: patch (2.2.0 → 2.2.1)
