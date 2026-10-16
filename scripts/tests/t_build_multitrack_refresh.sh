#!/usr/bin/env bash
# ABOUTME: Asserts build skill multi-track prose uses current agent-teams mechanics (T3)
# ABOUTME: and documents the builder no-self-isolation decision (T1 option b).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$F" || exit 1

# T3: current mechanism — env gate, natural-language spawn, automatic cleanup, no TeamCreate/Delete
assert_grep    "$F" "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1" || exit 1
assert_no_grep "$F" "TeamCreate"                              || exit 1
assert_no_grep "$F" "TeamDelete"                              || exit 1
assert_grep    "$F" "natural-language"                        || exit 1
assert_grep    "$F" "automatic"                               || exit 1
# Teammates honor builder's model/tools but NOT its skills/mcpServers
assert_grep    "$F" "skills"                                  || exit 1

# T1 (option b): builder does not self-isolate; worktree mgmt stays in build prose
assert_grep    "$F" "isolation: worktree"                    || exit 1
assert_grep    "$F" "default branch"                         || exit 1
# builder.md must NOT carry an isolation field (decision = no code)
assert_no_grep "$PLUGIN_DIR/agents/builder.md" "^isolation:" || exit 1
