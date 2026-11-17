#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.7.1] entry: build's plan intake and unowned-file fix rounds, the doc commit guard,
# ABOUTME: brainstorm's small path, the directory hold, and no source-of-inspiration names.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.7\.1\]" "$F" || { echo "    missing [3.7.1] entry"; exit 1; }
SECTION="$(mktemp)"; trap 'rm -f "$SECTION"' EXIT
awk '/^## \[3\.7\.1\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in '### Fixed' '### Upgrading' 'plan: in progress' '`Next:` line' 'a file no lane owns' 'Rulings' \
    'if git tracks its folder' 'default branch' 'small path' 'Single approach' 'Directory copy' \
    'restarts that wait' 'turbocharge@turbocharge' "The evals weren't rerun" 't_build_plan_intake.sh' \
    't_fix_round_unowned.sh' 't_doc_commit_guard.sh'; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.7.1] section missing: $p"; rc=1; }
done
# Release Naming: name a release by what it does, never after the source of inspiration.
grep -qiE 'plugin-dev|skill-reviewer' "$SECTION" && { echo "    [3.7.1] section names its source of inspiration"; rc=1; }
exit $rc
