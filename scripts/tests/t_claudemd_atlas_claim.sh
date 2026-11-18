#!/usr/bin/env bash
# ABOUTME: Tests CLAUDE.md has accurate ATLAS.md claim (pre-load, and named in dispatch prompts: agents read @ files themselves).
# ABOUTME: Verifies old inaccurate "Read by setup, wrap, plan" wording is gone.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/.claude/CLAUDE.md"
assert_file "$F" || exit 1
# New accurate claim (v2.5.0: lazy-load — Where to Look only)
assert_grep "$F" "Where to Look table pre-loaded by SessionStart hook" || exit 1
assert_grep "$F" "named in dispatch prompts"                         || exit 1
assert_no_grep "$F" "injected into dispatch prompts"                 || exit 1
# Old inaccurate claim is gone
assert_no_grep "$F" "Read by .setup, wrap, plan. skills"            || exit 1
# 3.8.0: staleness by commit, the skill scripts, no atlas-hash footer
for p in 'atlas-sha' '`skills/<name>/*.sh`' 'wrap reruns atlas only when files changed'; do
    grep -qF -- "$p" "$F" || { echo "    CLAUDE.md missing: $p"; exit 1; }
done
grep -qF 'atlas-hash' "$F" && { echo "    CLAUDE.md still describes the atlas-hash footer"; exit 1; }
exit 0
