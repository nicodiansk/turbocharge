#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
assert_file "$F" || exit 1
# New format required sections
assert_grep "$F" "^## Where to Look"        || exit 1
assert_grep "$F" "^## Entry Points"         || exit 1
assert_grep "$F" "^## Module Map"           || exit 1
assert_grep "$F" "^## Key Symbols"          || exit 1
assert_grep "$F" "^## Integration Points"   || exit 1
assert_grep "$F" "^## Conventions & Gotchas" || exit 1
# Removed sections must NOT appear in the template section of the skill
assert_no_grep "$F" "^## Data Flows"        || exit 1
assert_no_grep "$F" "^## Domain Model"      || exit 1
assert_no_grep "$F" "^## Active Work"       || exit 1
# Manual-note marker must shift from 📌 to 📌-prefixed line comment
assert_grep "$F" "📌"                       || exit 1
