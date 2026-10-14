#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.4.0] entry covering the review swarm, PR triage, the measurements and the release tree.
# ABOUTME: Earlier entries stay frozen; plugin.json's version is checked separately by t_version_matches_changelog.sh.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.4\.0\]" "$F" || { echo "    missing [3.4.0] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.4\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "review-swarm" "verifier" "--watch" "/reload-plugins" "/config" "W/OUT" "Sample" "ready_for_review" "stale" \
         "release.sh" "/turbocharge:review"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.4.0] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
