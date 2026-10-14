#!/usr/bin/env bash
# ABOUTME: Asserts SessionStart flags a session snapshot that is more than 3 days old (jq-free, no date -d/-j).
# ABOUTME: The note shares the snapshot's byte budget, and malformed or future dates, and legacy snapshots, add no note.
F="$PLUGIN_DIR/hooks/session-start.sh"
TMP="$(mktemp -d)"
cleanup() { cd /; rm -rf "$TMP"; }
trap cleanup EXIT
TODAY="$(date +%Y-%m-%d)"

fail() { echo "    $1"; exit 1; }

# run_case NAME SNAPSHOT_JSON — fresh non-git dir, runs the hook, sets OUT and ERR.
run_case() {
    D="$TMP/$1"; mkdir -p "$D/.claude"
    printf '%s\n' "$2" > "$D/.claude/turbocharge-session.json"
    cd "$D" || exit 1
    OUT="$(bash "$F" 2>"$TMP/err")"; ERR="$(cat "$TMP/err")"
    cd "$TMP" || exit 1
    [ -z "$ERR" ] || fail "$1: stderr not empty: $ERR"
}

run_case old '{"date": "2020-01-01"}'
echo "$OUT" | grep -q 'may be stale (written 2020-01-01, ' || fail "old date: no staleness note"
echo "$OUT" | grep -q 'days ago)' || fail "old date: note lacks 'days ago)'"
echo "$OUT" | grep -qF 'Check it against git log before relying on it.' || fail "old date: note lacks the advice"
# The note sits right after the snapshot header.
echo "$OUT" | grep -A1 -F -- '--- Session snapshot (previous /wrap) ---' | tail -1 | grep -q '^Note: this snapshot may be stale' \
    || fail "note is not right after the snapshot header"

run_case today "{\"date\": \"$TODAY\"}"
echo "$OUT" | grep -q 'may be stale' && fail "today's snapshot flagged"

run_case future '{"date": "2099-01-01"}'
echo "$OUT" | grep -q 'may be stale' && fail "future date flagged"

run_case malformed '{"date": "yesterday"}'
echo "$OUT" | grep -q 'may be stale' && fail "malformed date flagged"

run_case legacy '{"marker": "LEGACY_1"}'
echo "$OUT" | grep -q 'may be stale' && fail "legacy snapshot flagged"
echo "$OUT" | grep -q 'LEGACY_1' || fail "legacy snapshot not shown"


# --- Branch mismatch (Task 19) ---
# run_git_case NAME SNAPSHOT_JSON [detach] — temp git repo on feat/x.
run_git_case() {
    D="$TMP/$1"; mkdir -p "$D/.claude"
    printf '%s\n' "$2" > "$D/.claude/turbocharge-session.json"
    ( cd "$D" && git init -q -b feat/x . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init \
        && { [ "$3" != detach ] || git checkout -q --detach; } ) >/dev/null 2>&1
    cd "$D" || exit 1
    OUT="$(bash "$F" 2>"$TMP/err")"; ERR="$(cat "$TMP/err")"
    cd "$TMP" || exit 1
    [ -z "$ERR" ] || fail "$1: stderr not empty: $ERR"
}

run_git_case other "{\"date\": \"$TODAY\", \"branch\": \"master @ abc1234, pushed\"}"
echo "$OUT" | grep -qF 'written on branch master, HEAD is on feat/x' || fail "other branch: no mismatch reason"

run_git_case same "{\"date\": \"$TODAY\", \"branch\": \"feat/x @ ef9753f, pushed; tree clean\"}"
echo "$OUT" | grep -q 'may be stale' && fail "same branch (prose value) flagged"

run_git_case detached "{\"date\": \"$TODAY\", \"branch\": \"master\"}" detach
echo "$OUT" | grep -q 'may be stale' && fail "detached HEAD flagged"

run_case nogit "{\"date\": \"$TODAY\", \"branch\": \"master\"}"
echo "$OUT" | grep -q 'may be stale' && fail "non-git dir flagged"

run_git_case both '{"date": "2020-01-01", "branch": "master"}'
echo "$OUT" | grep -qF 'may be stale (written 2020-01-01, ' || fail "both: age reason missing"
echo "$OUT" | grep -qE 'days ago; written on branch master, HEAD is on feat/x\)\.' || fail "both: reasons not joined by '; ' in one line"
[ "$(echo "$OUT" | grep -c 'may be stale')" -eq 1 ] || fail "both: expected exactly one note line"

# Budget: a 300-line old snapshot beside an oversized ATLAS.md stays under the inline limit, note kept.
D="$TMP/big"; mkdir -p "$D/.claude"; cd "$D" || exit 1
{ echo "## Where to Look"; i=0; while [ "$i" -lt 400 ]; do echo "| thing $i | path/to/file_$i.ext:1-50 | long filler text to fill space |"; i=$((i+1)); done; } > ATLAS.md
{ echo '{'; echo '  "date": "2020-01-01",'; i=0; while [ "$i" -lt 300 ]; do echo "  \"k$i\": \"value number $i with filler text to take space\","; i=$((i+1)); done; echo '  "end": 1'; echo '}'; } > .claude/turbocharge-session.json
OUT="$(bash "$F" 2>"$TMP/err")"; ERR="$(cat "$TMP/err")"
cd "$TMP" || exit 1
[ -z "$ERR" ] || fail "big: stderr not empty"
BYTES=$(printf '%s\n' "$OUT" | wc -c | tr -d ' ')
[ "$BYTES" -lt 10000 ] || fail "big: output is $BYTES bytes, expected < 10000"
echo "$OUT" | grep -q 'may be stale (written 2020-01-01, ' || fail "big: note missing"
exit 0
