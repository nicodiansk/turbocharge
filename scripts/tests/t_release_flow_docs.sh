#!/usr/bin/env bash
# ABOUTME: Asserts .claude/CLAUDE.md documents the directory release flow: the listing tracks a `release` branch that is
# ABOUTME: fast-forwarded to a tag, so master merges stop creating directory versions; and why the switch had to wait.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
C="$PLUGIN_DIR/.claude/CLAUDE.md"
assert_file "$C" || exit 1
rc=0
for p in 'git push origin vX.Y.Z:release' 'cancels a waiting publish request' 'turbocharge@turbocharge' 'Publish update'; do
    grep -qF -- "$p" "$C" || { echo "    CLAUDE.md release flow missing: $p"; rc=1; }
done
exit $rc
