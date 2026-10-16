#!/usr/bin/env bash
# ABOUTME: Tests that validate.sh references validate-atlas.sh.
# ABOUTME: Checks the wiring exists; does NOT re-run validate.sh (avoids recursion).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/scripts/validate.sh"
assert_grep "$F" "validate-atlas.sh" || exit 1
