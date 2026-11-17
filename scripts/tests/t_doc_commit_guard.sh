#!/usr/bin/env bash
# ABOUTME: Asserts brainstorm and story commit the doc they save only where git tracks its folder,
# ABOUTME: and ask first on the default branch (commit there or on a new branch).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
rc=0
for s in brainstorm story; do
    S="$PLUGIN_DIR/skills/$s/SKILL.md"
    assert_file "$S" || { rc=1; continue; }
    L=$(tr -d '\r' < "$S" | grep -E '^- Commit' | head -1)
    [ -n "$L" ] || { echo "    $s: no '- Commit' line"; rc=1; continue; }
    for p in 'if git tracks its folder' 'not ignored' 'on the default branch, ask first' 'on a new branch'; do
        printf '%s\n' "$L" | grep -qF -- "$p" || { echo "    $s commit line missing: $p"; rc=1; }
    done
done
exit $rc
