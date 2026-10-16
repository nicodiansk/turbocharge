#!/usr/bin/env bash
# ABOUTME: Tests that atlas SKILL.md preserves 📌 manual-note contract in Update Mode.
# ABOUTME: Verifies the pin emoji is present and Update Mode explicitly preserves them.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/atlas/SKILL.md"
# Manual notes still preserved, still signaled by 📌
assert_grep "$F" "📌"                                || exit 1
# Update Mode explicitly says preserve 📌-prefixed lines
grep -q "preserve.*📌" "$F" || grep -q "📌.*preserve" "$F" || { echo "    Update Mode does not explicitly preserve 📌 lines"; exit 1; }
