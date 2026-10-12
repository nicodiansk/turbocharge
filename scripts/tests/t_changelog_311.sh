#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.1.1] entry for the PR-review follow-ups: CLAUDE.local.md nudge,
# ABOUTME: stashing-hook places, task-scoped Verify, plan-time line ranges, exit-code pin. Ordering is t_version_matches_changelog's job.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.1\.1\]" "$F" || { echo "    missing [3.1.1] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.1\.1\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "CLAUDE.local.md" ".husky/" "plan-time" "exit 0" "t_version_matches_changelog.sh"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.1.1] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
