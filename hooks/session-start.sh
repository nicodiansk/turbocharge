#!/usr/bin/env bash
# ABOUTME: SessionStart hook — bootstrap cat, pre-load ATLAS.md + session snapshot.
# ABOUTME: Pre-loading ATLAS means zero tool calls for "where is X" lookups.
set -e
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

cat "$HOOK_DIR/session-bootstrap.md"

if [ -f "ATLAS.md" ]; then
    echo ""
    echo "--- ATLAS.md (pre-loaded for zero-tool-call navigation) ---"
    cat "ATLAS.md"
    echo "--- end ATLAS.md ---"
else
    echo ""
    cat "$HOOK_DIR/missing-atlasmd-nudge.md"
fi

if [ -f ".claude/turbocharge-session.json" ]; then
    echo ""
    echo "--- Session snapshot (previous /wrap) ---"
    cat ".claude/turbocharge-session.json"
    echo "--- end snapshot ---"
fi

if [ ! -f "CLAUDE.md" ]; then
    echo ""
    cat "$HOOK_DIR/missing-claudemd-nudge.md"
fi
