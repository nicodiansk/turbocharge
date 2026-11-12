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

# Task 8: four join checks on a builder lane's files, above the shortcut grep.
for p in 'git status --porcelain -- <lane paths>' 'git rev-list --count $LANE_SHA..HEAD -- <lane paths>' 'commit these, or say why' 'each distinct command once' 'at least, not equal' 'max 2 per lane' 'rerun all four checks' 'wait until the checks pass' 'With no Lanes table'; do
    printf '%s\n' "$STEP5" | grep -qF -- "$p" || { echo "    build Step 5 missing: $p"; rc=1; }
done
HDR=$(printf '%s\n' "$STEP5" | grep -nF '| # | Check | Command | When it fails |' | head -1 | cut -d: -f1)
RE=$(printf '%s\n' "$STEP5" | grep -n '^SHORTCUT_RE=' | head -1 | cut -d: -f1)
if [ -z "$HDR" ] || [ -z "$RE" ] || ! [ "$HDR" -lt "$RE" ]; then
    echo "    the check table header must sit above the SHORTCUT_RE= line ($HDR $RE)"; rc=1
fi
ROWS=$(printf '%s\n' "$STEP5" | grep -c '^| [1-4] |')
[ "$ROWS" -eq 4 ] || { echo "    build Step 5 needs exactly 4 check rows ($ROWS)"; rc=1; }
sec "$S" '## Step 4' '## ' | grep -qF 'Inline lanes run no mutation and no join checks' || { echo "    build Step 4 missing: Inline lanes run no mutation and no join checks"; rc=1; }
exit $rc
