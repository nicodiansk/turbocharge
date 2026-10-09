#!/usr/bin/env bash
# ABOUTME: Asserts read-only agents cannot spawn nested subagents (Agent listed in disallowedTools).
# ABOUTME: builder/planner must keep a tools: allowlist that excludes Agent (nesting defaults to depth 3).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
# list_field FILE KEY — print one comma-separated frontmatter list value per line, trimmed.
list_field() { frontmatter "$1" | sed -n "s/^$2:[[:space:]]*//p" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }
for a in researcher task-reviewer code-reviewer; do
    F="$PLUGIN_DIR/agents/$a.md"
    assert_file "$F" || exit 1
    list_field "$F" disallowedTools | grep -qx "Agent" \
        || { echo "    agents/$a.md disallowedTools must include Agent"; exit 1; }
done
for a in builder planner; do
    F="$PLUGIN_DIR/agents/$a.md"
    assert_file "$F" || exit 1
    [ -n "$(list_field "$F" tools)" ] || { echo "    agents/$a.md must keep a tools: allowlist"; exit 1; }
    list_field "$F" tools | grep -qx "Agent" && { echo "    agents/$a.md tools must not include Agent"; exit 1; }
done
exit 0
