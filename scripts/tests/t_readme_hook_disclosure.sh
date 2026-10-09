#!/usr/bin/env bash
# ABOUTME: Asserts the README discloses everything the SessionStart hook reads and runs, and states its data flow exactly.
# ABOUTME: The claude.ai directory's security scan flags undisclosed behavior, so the disclosure must be complete and must not overclaim.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/README.md"
assert_file "$F" || exit 1
rc=0
for p in \
    "### What the hook does" \
    "read-only" \
    "cleared or compacted" \
    "sends nothing over the network" \
    "becomes part of the session context" \
    ".claude/turboflow-session.json" \
    ".claude/CLAUDE.md" \
    "md5sum" \
    "codemap stats"; do
    grep -qF "$p" "$F" || { echo "    README missing hook disclosure: $p"; rc=1; }
done
# Hook output reaches the model as context, so "nothing leaves" would overclaim.
grep -qF "Nothing leaves your machine" "$F" && { echo "    README overclaims: hook output is sent as session context"; rc=1; }
exit $rc
