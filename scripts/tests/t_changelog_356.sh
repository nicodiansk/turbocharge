#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.5.6] entry: the clean release (NOTICE, the README's run-and-send disclosure, setup
# ABOUTME: no longer reading the global settings file). Earlier entries stay frozen.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.5\.6\]" "$F" || { echo "    missing [3.5.6] entry"; exit 1; }
SECTION="$(mktemp)"
awk '/^## \[3\.5\.6\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in "NOTICE" "What the skills run and send" "git pull" "gh pr create" "claude plugin list --json" \
    "~/.claude/settings.json" "reviewer" "t_readme_runs_sends.sh" "t_notice.sh"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.5.6] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
