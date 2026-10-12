#!/usr/bin/env bash
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/setup/SKILL.md"
assert_grep "$F" "## CLAUDE.md Phase"             || exit 1
assert_grep "$F" "Auto-Detect"                    || exit 1
assert_grep "$F" "package.json"                   || exit 1
assert_grep "$F" "pyproject.toml"                 || exit 1
assert_grep "$F" "Cargo.toml"                     || exit 1
assert_grep "$F" "go.mod"                         || exit 1
assert_grep "$F" "Interview"                      || exit 1
assert_grep "$F" "Test discipline"                || exit 1
assert_grep "$F" "File-header convention"         || exit 1
assert_grep "$F" "Naming style"                   || exit 1
assert_grep "$F" "Debug protocol strictness"      || exit 1
assert_grep "$F" "domain terms"                   || exit 1
assert_grep "$F" "templates/CLAUDE-turbocharge.md" || exit 1
assert_grep "$F" "<!-- turbocharge:"              || exit 1
# 3.0–3.1 wrote blocks under turboflow markers: setup must adopt them, not append duplicates.
grep -qF '<!-- turboflow:NAME -->' "$F" || { echo "    setup must recognize the 3.x <!-- turboflow:NAME --> markers"; exit 1; }
assert_grep "$F" "never append a duplicate"       || exit 1
# A 2.x -> 3.x project can hold both forms of one block: keep one.
assert_grep "$F" "remove the turboflow duplicate" || exit 1
assert_grep "$F" "180 lines"                      || exit 1
# Chains forward to atlas
assert_grep "$F" "/turbocharge:atlas"               || exit 1
