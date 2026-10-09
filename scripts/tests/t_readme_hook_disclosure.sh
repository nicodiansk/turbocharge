#!/usr/bin/env bash
# ABOUTME: Asserts the README discloses everything the SessionStart hook reads and runs, and that nothing leaves the machine.
# ABOUTME: The claude.ai directory's security scan flags undisclosed behavior, so the disclosure must stay complete.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/README.md"
assert_file "$F" || exit 1
rc=0
for p in \
    "### What the hook does" \
    "read-only" \
    "no network" \
    "Nothing leaves your machine" \
    ".claude/turboflow-session.json" \
    ".claude/CLAUDE.md" \
    "md5sum" \
    "codemap stats"; do
    grep -qF "$p" "$F" || { echo "    README missing hook disclosure: $p"; rc=1; }
done
exit $rc
