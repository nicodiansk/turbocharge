#!/usr/bin/env bash
# ABOUTME: Asserts the README discloses everything both hooks (SessionStart, builder exit gate) read and run, and states their data flow exactly.
# ABOUTME: The claude.ai directory's security scan flags undisclosed behavior, so the disclosure must be complete and must not overclaim.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/README.md"
assert_file "$F" || exit 1
rc=0
for p in \
    "### What the hooks do" \
    "read-only" \
    "cleared or compacted" \
    "sends nothing over the network" \
    "becomes part of the session context" \
    ".claude/turbocharge-session.json" \
    ".claude/CLAUDE.md" \
    "md5sum" \
    "codemap stats" \
    ".github/workflows" \
    "never run on your machine" \n    "SubagentStop" \n    "SubagentHandback" \n    "builder-exit-gate.sh" \n    "git status --porcelain" \n    "commit these by pathspec" \n    "jq"; do
    grep -qF "$p" "$F" || { echo "    README missing hook disclosure: $p"; rc=1; }
done
grep -qF "### What the hook does" "$F" && { echo "    README still has the single-hook heading"; rc=1; }
grep -qF "merge / PR / keep / discard" "$F" && { echo "    README ship row still offers discard"; rc=1; }
# Hook output reaches the model as context, so "nothing leaves" would overclaim.
grep -qF "Nothing leaves your machine" "$F" && { echo "    README overclaims: hook output is sent as session context"; rc=1; }
exit $rc
