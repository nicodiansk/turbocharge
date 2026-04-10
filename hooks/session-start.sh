#!/usr/bin/env bash
# ABOUTME: SessionStart hook script for turbocharge plugin.
# ABOUTME: Outputs bootstrap content, checks for missing CLAUDE.md and ATLAS.md.

set -e

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always output the bootstrap content
cat "$HOOK_DIR/session-bootstrap.md"

# Working directory is the user's project root at hook execution time
if [ ! -f "CLAUDE.md" ]; then
    echo ""
    cat "$HOOK_DIR/missing-claudemd-nudge.md"
fi

if [ ! -f "ATLAS.md" ]; then
    echo ""
    cat "$HOOK_DIR/missing-atlasmd-nudge.md"
fi
