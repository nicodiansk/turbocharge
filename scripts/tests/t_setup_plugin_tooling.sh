#!/usr/bin/env bash
# ABOUTME: Asserts setup skill uses real CLI tooling for health + plugin-conflict scan (T6).
# ABOUTME: claude plugin details/list --json; scans competing plugins; keeps disable-model-invocation.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/setup/SKILL.md"
assert_file "$F" || exit 1

assert_grep "$F" "claude plugin details turbocharge" || exit 1
assert_grep "$F" "claude plugin list --json"          || exit 1
# Scans for competing orchestration PLUGINS, not only ~/.claude/agents/
assert_grep "$F" "orchestration plugin"               || exit 1
# Existing conflict-table audit retained
assert_grep "$F" "Conflicts With"                      || exit 1
# disable-model-invocation retained (cannot be preloaded; setup is a manual run)
assert_grep "$F" "disable-model-invocation: true"      || exit 1
