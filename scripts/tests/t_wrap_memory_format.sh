#!/usr/bin/env bash
# ABOUTME: Tests that wrap skill includes the memory bullet format, a 200-line cap that merges topic files, and the session snapshot.
# ABOUTME: Verifies the canonical bullet format example is present.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_grep "$F" "conf:"                    || exit 1
assert_grep "$F" "source,"                  || exit 1
grep -qi "200-line cap" "$F"                || { echo "    missing pattern '200-line cap' in $F"; exit 1; }
assert_grep "$F" "turbocharge-session.json" || exit 1
assert_grep "$F" "\.claude/turbocharge-session" || exit 1
# Specific bullet format shown
grep -qE -- "- .* _\(.*, [0-9]{4}-[0-9]{2}-[0-9]{2}, conf: 0\.[0-9]\)_" "$F" || { echo "    canonical bullet format example missing"; exit 1; }
# The source is a pointer that resolves, not a category word.
grep -qF -- '(`websearch`, `user`, `codebase`, `testrun`)' "$F" && { echo "    wrap still lists sources as category words"; exit 1; }
# The cap merges topic files: sorting an index by confidence deleted links and orphaned topic files.
for p in 'confidence asc' 'until under 180' 'lossy by design'; do
    grep -qF -- "$p" "$F" && { echo "    wrap still says: $p"; exit 1; }
done
exit 0
