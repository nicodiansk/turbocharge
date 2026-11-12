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
    # One added line per alternative, each hit by that alternative only: dropping any alternative changes the output.
    cat > "$T/hits.txt" <<'HITS'
+  it.skip('new', () => {})
+@unittest.skipIf(sys.platform == "win32", "x")
+@unittest.skipUnless(HAS_GPU, "x")
+@pytest.mark.skip
+@pytest.mark.xfail(reason="x")
+    @unittest.expectedFailure
+describe.only('x', () => {})
+  xit('x', () => {})
+xdescribe('x', () => {})
+fdescribe('x', () => {})
+    t.Skip("x")
+    t.Skipf("x %d", 1)
+#[ignore]
+@Disabled
+@Ignore
+    sys.exit(0)
+  process.exit(0)
+    os.Exit(0)
HITS
    # Never hits: a shell test's exit 0, a removed line, diff headers (one naming xfail), model.fit( (why fit( is out),
    # and an ordinary exit(1): a bare xit\( would match the "xit(" inside every exit(.
    cat > "$T/misses.txt" <<'MISSES'
+exit 0
-  it.skip('old', () => {})
+++ b/tests/test_xfail.py
+    model.fit(x, y)
+    sys.exit(1)
MISSES
    { echo '+++ b/tests/test_x.py'; cat "$T/hits.txt" "$T/misses.txt"; } > "$T/fixture.diff"
    bash "$T/grep.sh" "$T/fixture.diff" > "$T/out.txt"
    cmp -s "$T/out.txt" "$T/hits.txt" || { echo "    the extracted shortcut grep must print exactly the $(wc -l < "$T/hits.txt" | tr -d ' ') hit lines; got:"; sed 's/^/      /' "$T/out.txt"; rc=1; }
    # Every alternative in SHORTCUT_RE has a fixture line, so a new alternative can't land without one.
    RE_BODY=${RE_LINE#SHORTCUT_RE=\'}; RE_BODY=${RE_BODY%\'}
    IFS='|' read -r -a ALTS <<< "$RE_BODY"
    for alt in "${ALTS[@]}"; do
        grep -qE -- "$alt" "$T/hits.txt" || { echo "    SHORTCUT_RE alternative with no fixture line: $alt"; rc=1; }
    done
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
# zsh doesn't split an unquoted variable: a $P of several paths reaches git as one missing path, and checks 1 and 3
# print nothing, so they pass on nothing (seen on the first run of these checks, 2026-11-12). Check 2's 0 gives it away.
for p in 'Run the checks in `bash`' '"${P[@]}"' "zsh doesn't split an unquoted variable" 'checks 1 and 3 then pass on nothing' \
    'A check 2 count of 0' 'fix them before trusting checks 1 and 3'; do
    printf '%s\n' "$STEP5" | grep -qF -- "$p" || { echo "    build Step 5 missing: $p"; rc=1; }
done
# Review 🟡 1: shell variables don't survive between Bash calls. An empty $LANE_SHA makes `..HEAD`, an empty range, and
# checks 2 and 3 then pass on nothing too, so Step 3 keeps the value and Step 5's zero-count clue names both causes.
sec "$S" '## Step 3' '## ' | grep -qF "Shell variables don't survive between Bash calls" \
    || { echo "    build Step 3 missing: Shell variables don't survive between Bash calls"; rc=1; }
sec "$S" '## Step 3' '## ' | grep -qF 'write the SHA itself into each later command' \
    || { echo "    build Step 3 missing: write the SHA itself into each later command"; rc=1; }
printf '%s\n' "$STEP5" | grep -qF -- '`$LANE_SHA` is empty' || { echo "    build Step 5 missing: \`\$LANE_SHA\` is empty"; rc=1; }
ROWS=$(printf '%s\n' "$STEP5" | grep -c '^| [1-4] |')
[ "$ROWS" -eq 4 ] || { echo "    build Step 5 needs exactly 4 check rows ($ROWS)"; rc=1; }
sec "$S" '## Step 4' '## ' | grep -qF 'Inline lanes run no mutation and no join checks' || { echo "    build Step 4 missing: Inline lanes run no mutation and no join checks"; rc=1; }

# Task 9: a builder lane is done only after its checks.
printf '%s\n' "$STEP5" | grep -qF '· files checked' || { echo "    build Step 5 missing: · files checked"; rc=1; }
for lead in '- **DONE**' '- **No Status line**'; do
    printf '%s\n' "$STEP5" | grep -F -- "$lead" | grep -qF 'join checks' || { echo "    build Step 5 bullet '$lead' must mention join checks"; rc=1; }
done
grep -qF "check the lane's commits yourself" "$S" && { echo "    build still says: check the lane's commits yourself"; rc=1; }
STEP7=$(sec "$S" '## Step 7' '## ')
for p in 'shortcut check:' 'check 2'; do
    printf '%s\n' "$STEP7" | grep -qF -- "$p" || { echo "    build Step 7 missing: $p"; rc=1; }
done
FLAGS=$(sec "$S" '## Red Flags' '## ')
for p in 'Marking a builder lane ✓ from its report' 'A return is a claim: run the four checks on its files first'; do
    printf '%s\n' "$FLAGS" | grep -qF -- "$p" || { echo "    build Red Flags missing: $p"; rc=1; }
done
exit $rc
