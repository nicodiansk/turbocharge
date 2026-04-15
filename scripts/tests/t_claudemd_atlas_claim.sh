#!/usr/bin/env bash
# ABOUTME: Tests CLAUDE.md has accurate ATLAS.md claim (pre-load + dispatch inject).
# ABOUTME: Verifies old inaccurate "Read by setup, wrap, plan" wording is gone.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CLAUDE.md"
assert_file "$F" || exit 1
# New accurate claim (v2.5.0: lazy-load — Where to Look only)
assert_grep "$F" "Where to Look table pre-loaded by SessionStart hook" || exit 1
assert_grep "$F" "injected into dispatch prompts"                  || exit 1
# Old inaccurate claim is gone
assert_no_grep "$F" "Read by .setup, wrap, plan. skills"            || exit 1
