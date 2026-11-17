#!/usr/bin/env bash
# ABOUTME: Asserts the README says what Atlas does and where it falls short, makes no savings claim, and names the atlas
# ABOUTME: scripts only in repo-only text, so the directory copy keeps the limits and loses the script names.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
R="$PLUGIN_DIR/README.md"
assert_file "$R" || exit 1
rc=0
grep -qF 'Nothing has measured yet' "$R" || { echo "    README lost: Nothing has measured yet"; rc=1; }
grep -qF 'without searching' "$R" && { echo "    README still says the agents navigate without searching"; rc=1; }
grep -qF 'skills/atlas/validate-atlas.sh' "$R" || { echo "    repo README doesn't name skills/atlas/validate-atlas.sh"; rc=1; }
D="$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$R")" || { echo "    filter refused README.md"; exit 1; }
for p in 'Names shared by different modules' 'aliases' 'dynamic calls' 'code intelligence (LSP)'; do
    printf '%s' "$D" | grep -qF -- "$p" || { echo "    directory README lost: $p"; rc=1; }
done
for p in atlas-symbols validate-atlas write-snapshot; do
    printf '%s' "$D" | grep -qF -- "$p" && { echo "    directory README names $p"; rc=1; }
done
exit $rc
