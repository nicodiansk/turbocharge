#!/usr/bin/env bash
# ABOUTME: Asserts build skill multi-track prose uses current agent-teams mechanics (implicit team, `name` spawn)
# ABOUTME: and documents the builder no-self-isolation decision (T1 option b).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$F" || exit 1

# Current mechanism — env gate, one implicit team, `name`-param spawn, automatic cleanup, no TeamCreate/Delete
assert_grep    "$F" "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1" || exit 1
assert_no_grep "$F" "TeamCreate"                              || exit 1
assert_no_grep "$F" "TeamDelete"                              || exit 1
assert_grep    "$F" "implicit team"                           || exit 1
assert_grep    "$F" "turboflow:builder"                       || exit 1
assert_grep    "$F" "automatic"                               || exit 1
# 2.1.288: a plugin agent spawned by name keeps its definition; skills never applied
assert_grep    "$F" "2\.1\.288"                               || exit 1
assert_grep    "$F" "skills"                                  || exit 1
# A model named in the spawn prompt overrides the definition's Sonnet pin (agent-teams docs)
assert_grep    "$F" "Do NOT name a model"                     || exit 1

# T1 (option b): builder does not self-isolate; worktree mgmt stays in build prose
assert_grep    "$F" "isolation: worktree"                    || exit 1
assert_grep    "$F" "default branch"                         || exit 1
# builder.md must NOT carry an isolation field (decision = no code)
assert_no_grep "$PLUGIN_DIR/agents/builder.md" "^isolation:" || exit 1
