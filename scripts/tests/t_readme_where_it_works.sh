#!/usr/bin/env bash
# ABOUTME: Asserts the README (the directory listing's description) says where Turbocharge works: the full pipeline in
# ABOUTME: Claude Code, skills/agents/hooks in Cowork, and only the skills in Chat (agents and hooks are ignored there).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
R="$PLUGIN_DIR/README.md"
assert_file "$R" || exit 1
SECTION="$(mktemp)"
awk '/^## Where it works/{f=1; print; next} f && /^## /{exit} f' "$R" > "$SECTION"
rc=0
[ -s "$SECTION" ] || { echo "    README missing a '## Where it works' section"; rm -f "$SECTION"; exit 1; }
for p in "Claude Code" "Cowork" "Chat" "agents and hooks" "ignored" "SubagentStop"; do
    grep -qF -- "$p" "$SECTION" || { echo "    'Where it works' missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
