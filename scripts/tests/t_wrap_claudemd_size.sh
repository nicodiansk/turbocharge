#!/usr/bin/env bash
# ABOUTME: Asserts wrap's step 6 keeps session state out of CLAUDE.md, keeps line endings, and proposes path-scoped rules over 200 lines.
# ABOUTME: Pins the docs' size target, the paths: trade-off (gone after /compact until a match is touched) and the directory copy.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/skills/wrap/SKILL.md"
assert_file "$W" || exit 1
rc=0
sec() { awk -v h="$2" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && /^##/ { s=0 } s' "$1"; }
S=$(sec "$W" '### 6. ')
for p in "never this session's state" 'keeps its line endings' 'Over 200' 'target under 200 lines per CLAUDE.md file' \
    '.claude/rules/<area>.md' 'paths:' 'reads, writes or edits a matching file' '/compact' '`\r` stripped' \
    '/doctor prompt-audit' 'v2.1.283'; do
    printf '%s\n' "$S" | grep -qF -- "$p" || { echo "    wrap step 6 missing: $p"; rc=1; }
done
grep -qF 'Revisit after major model releases' "$W" && { echo "    wrap still says: Revisit after major model releases"; rc=1; }
FILTERED=$(bash "$PLUGIN_DIR/scripts/directory-filter.sh" < "$W")
for p in '.claude/rules/<area>.md' '/compact'; do
    printf '%s\n' "$FILTERED" | grep -qF -- "$p" || { echo "    filtered wrap missing: $p"; rc=1; }
done
exit $rc
