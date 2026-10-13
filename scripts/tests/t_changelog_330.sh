#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.3.0] entry covering the eval baseline, the quality pack and the builder exit gate.
# ABOUTME: Earlier entries stay frozen; plugin.json's version is checked separately by t_version_matches_changelog.sh.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.3\.0\]" "$F" || { echo "    missing [3.3.0] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.3\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "SubagentStop" "SubagentHandback" "Review Focus" "Declined to judge" "DONE_WITH_CONCERNS" "Blocked on:" \
         "model: opus" "W/OUT" "Fired" "scripts/eval.sh" "discard"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.3.0] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
