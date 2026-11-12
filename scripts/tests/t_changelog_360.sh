#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.6.0] entry: tests with teeth (RED on an assertion, Never, lane-end mutation,
# ABOUTME: Not done:, four join checks, reviewers reading for toothless tests) and the README images redrawn in Zine style.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.6\.0\]" "$F" || { echo "    missing [3.6.0] entry"; exit 1; }
SECTION="$(mktemp)"; trap 'rm -f "$SECTION"' EXIT
awk '/^## \[3\.6\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in 'Tests with teeth' '### Added' '### Changed' '### Upgrading' 'an assertion on the result' '**Never**' \
    'Lane-End Mutation' 'Mutation:' 'Not done:' 'LANE_SHA' 'join checks' 'zsh' 'task-reviewer' 'code-reviewer' \
    'test-gaps' 'Directory copy' 'Zine' 'hero-banner-v2.svg' 't_join_checks.sh' 'turbocharge@turbocharge' \
    "The evals weren't rerun"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.6.0] section missing: $p"; rc=1; }
done
# Release Naming: name a release by what it does, never after the source of inspiration.
grep -qi 'glitch' "$SECTION" && { echo "    [3.6.0] section names its source of inspiration"; rc=1; }
# The old hero banner left the README with the Zine images, and nothing else uses it.
[ -e "$PLUGIN_DIR/images/hero-banner-v2.svg" ] && { echo "    images/hero-banner-v2.svg is still in the repo"; rc=1; }
exit $rc
