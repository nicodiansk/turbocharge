#!/usr/bin/env bash
# ABOUTME: Asserts build's join checks a builder lane's files (status, commit count, test shortcuts, tests) before lane done.
# ABOUTME: Tests with teeth, tasks 7-9: runs the shortcut grep extracted from Step 5 on a fixture diff.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/build/SKILL.md"
assert_file "$S" || exit 1
rc=0
sec() { awk -v h="$2" -v e="$3" '{ sub(/\r$/, "") } index($0, h) == 1 { s=1; next } s && index($0, e) == 1 { s=0 } s' "$1"; }
STEP5=$(sec "$S" '## Step 5' '## Step 6')
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# Task 7: the shortcut grep, extracted from Step 5 and run on a fixture diff.
PREFIX='git diff $LANE_SHA..HEAD -- <lane paths> | '
RE_LINES=$(printf '%s\n' "$STEP5" | grep -c '^SHORTCUT_RE=')
PIPE_LINES=$(printf '%s\n' "$STEP5" | awk -v p="$PREFIX" 'index($0, p) == 1 { n++ } END { print n+0 }')
[ "$RE_LINES" -eq 1 ] || { echo "    build Step 5 needs exactly one SHORTCUT_RE= line ($RE_LINES)"; rc=1; }
[ "$PIPE_LINES" -eq 1 ] || { echo "    build Step 5 needs exactly one line starting: $PREFIX ($PIPE_LINES)"; rc=1; }
if [ "$RE_LINES" -eq 1 ] && [ "$PIPE_LINES" -eq 1 ]; then
    RE_LINE=$(printf '%s\n' "$STEP5" | grep '^SHORTCUT_RE=')
    PIPE=$(printf '%s\n' "$STEP5" | awk -v p="$PREFIX" 'index($0, p) == 1')
    {
        printf '%s\n' "$RE_LINE"
        printf 'cat "$1" | %s\n' "${PIPE#"$PREFIX"}"
    } > "$T/grep.sh"
    cat > "$T/fixture.diff" <<'DIFF'
+++ b/tests/test_x.py
+  it.skip('new', () => {})
+@pytest.mark.skip
+    t.Skip("x")
+    sys.exit(0)
+@Disabled
+exit 0
-  it.skip('old', () => {})
+++ b/tests/test_xfail.py
DIFF
    bash "$T/grep.sh" "$T/fixture.diff" > "$T/out.txt"
    EXPECTED=$(printf '%s\n' "+  it.skip('new', () => {})" '+@pytest.mark.skip' '+    t.Skip("x")' '+    sys.exit(0)' '+@Disabled')
    [ "$(cat "$T/out.txt")" = "$EXPECTED" ] || { echo "    the extracted shortcut grep must print exactly the 5 shortcut lines; got:"; sed 's/^/      /' "$T/out.txt"; rc=1; }
fi
for p in 'git diff --diff-filter=D --name-only $LANE_SHA..HEAD -- <lane paths>' 'left to the reviewers' 'a skip when a tool is missing' 'a deletion the plan names' "shortcut check: <line> — <why it's legitimate>"; do
    printf '%s\n' "$STEP5" | grep -qF -- "$p" || { echo "    build Step 5 missing: $p"; rc=1; }
done
exit $rc
