#!/usr/bin/env bash
# ABOUTME: Asserts the directory release detail lives in a path-scoped rule and .claude/CLAUDE.md stays under 200 lines.
# ABOUTME: 3.8.0 F33 and F27: CLAUDE.md keeps the push rules for release and points to the rule; an Iron Law is stated, not enforced.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
C="$PLUGIN_DIR/.claude/CLAUDE.md"; R="$PLUGIN_DIR/.claude/rules/directory-release.md"
for f in "$C" "$R"; do assert_file "$f" || exit 1; done
rc=0
n=$(wc -l < "$C" | tr -d ' ')
[ "$n" -lt 200 ] || { echo "    .claude/CLAUDE.md has $n lines, the docs target is under 200"; rc=1; }
# The rule is path-scoped: frontmatter (read with \r stripped) holds paths: and the release script.
FM=$(tr -d '\r' < "$R" | awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1')
for p in 'paths:' 'scripts/release.sh' 'scripts/directory-filter.sh' 'CHANGELOG.md'; do
    printf '%s\n' "$FM" | grep -qF -- "$p" || { echo "    directory-release.md frontmatter missing: $p"; rc=1; }
done
# CLAUDE.md points to the rule and keeps the two rules that guard a push to release.
for p in '.claude/rules/directory-release.md' "Claude can't push \`release\`" "Don't push \`release\` while a publish request waits"; do
    grep -qF -- "$p" "$C" || { echo "    CLAUDE.md missing: $p"; rc=1; }
done
# The detail moved: the scan rule list is in the rule, not in CLAUDE.md.
for p in 'Directory rules met so far' 'LOCAL_CODE_FILE_TYPE' 'DIRECTORY_STRIP_KEYS'; do
    grep -qF -- "$p" "$R" || { echo "    directory-release.md missing: $p"; rc=1; }
done
grep -qF 'Directory rules met so far' "$C" && { echo "    CLAUDE.md still holds the scan rule list"; rc=1; }
# F27: an Iron Law is a rule stated with its reason; only a hook enforces.
grep -qF 'An enforced constraint' "$C" && { echo "    CLAUDE.md still calls an Iron Law enforced"; rc=1; }
grep -qF 'Only a hook enforces anything' "$C" || { echo "    CLAUDE.md Iron Law definition missing its new wording"; rc=1; }
exit $rc
