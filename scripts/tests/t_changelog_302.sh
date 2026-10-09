#!/usr/bin/env bash
# ABOUTME: Asserts CHANGELOG.md has a newest-first [3.0.2] entry documenting the directory-ready release:
# ABOUTME: CLAUDE.md move + strict validation, CLAUDE.md-variant detection, version-only-in-plugin.json, hook disclosure.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/CHANGELOG.md"
assert_file "$F" || exit 1
grep -q "^## \[3\.0\.2\]" "$F" || { echo "    missing [3.0.2] entry"; exit 1; }
grep -m1 "^## \[" "$F" | grep -q "^## \[3\.0\.2\]" || { echo "    [3.0.2] is not the newest entry"; exit 1; }

SECTION="$(mktemp)"
awk '/^## \[3\.0\.2\]/{f=1; next} f && /^## \[/{exit} f' "$F" > "$SECTION"
rc=0
for p in \
    ".claude/CLAUDE.md" \
    "--strict" \
    "CLAUDE.local.md" \
    "plugin.json" \
    "What the hook does" \
    "@../AGENTS.md" \
    "t_version_lockstep.sh"; do
    grep -qF -- "$p" "$SECTION" || { echo "    [3.0.2] section missing: $p"; rc=1; }
done
rm -f "$SECTION"
exit $rc
