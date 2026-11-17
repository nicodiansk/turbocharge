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
# Keys appear as name + file + fingerprint, and the snapshot goes through a code check (3.8.0).
rc=0
FILTERED=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$F")
for p in 'sha256:<first 12 hex>' 'looks like a key' 'name the field' 'prints only its name, length and fingerprint'; do
    grep -qF -- "$p" "$F" || { echo "    wrap missing: $p"; rc=1; }
done
for p in 'skills/wrap/write-snapshot.sh"' '--allow <field>'; do
    grep -qF -- "$p" "$F" || { echo "    wrap repo copy missing: $p"; rc=1; }
    printf '%s\n' "$FILTERED" | grep -qF -- "$p" && { echo "    filtered wrap keeps: $p"; rc=1; }
done
printf '%s\n' "$FILTERED" | grep -qF 'write-snapshot' && { echo "    filtered wrap names write-snapshot"; rc=1; }
printf '%s\n' "$FILTERED" | grep -qF 'looks like a key' || { echo "    filtered wrap lost: looks like a key"; rc=1; }
exit $rc
