#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a [3.8.0] entry: git-guard, atlas by commit, build's Model column, prompt hygiene,
# ABOUTME: setup's rule checks, the directory copy's share, the eval rerun, and no source-of-inspiration names.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.8\.0\]" "$F" || { echo "    missing [3.8.0] entry"; exit 1; }
SECTION="$(mktemp)"; trap 'rm -f "$SECTION"' EXIT
awk '/^## \[3\.8\.0\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in '### Added' '### Changed' '### Fixed' '### Removed' '### Upgrading' \
    'git-guard' 'TURBOCHARGE_GIT_GUARD' 'atlas-sha' 'validate-atlas.sh' 'CodeMap' 'docs/plans/archive/' \
    'Model column' 'plan: done' 'Grep tool' 'Code read at:' '`@` path' '/doctor prompt-audit' \
    'Directory copy' 'turbocharge@turbocharge' 'evals/summary/3.8.0.md' 't_changelog_380.sh'; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.8.0] section missing: $p"; rc=1; }
done
# Release Naming: name a release by what it does, never after the source of inspiration.
grep -qiE 'plugin-dev|skill-reviewer|superpowers' "$SECTION" && { echo "    [3.8.0] section names its source of inspiration"; rc=1; }
exit $rc
