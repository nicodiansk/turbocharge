#!/usr/bin/env bash
# ABOUTME: Tests that validate.sh runs `claude plugin validate --strict` and skips visibly when the CLI is missing.
# ABOUTME: Checks the wiring only; does NOT re-run validate.sh (avoids recursion). Also guards the moved CLAUDE.md pointer.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/scripts/validate.sh"
assert_file "$F" || exit 1
assert_grep "$F" "claude plugin validate" || exit 1
grep -qF -- "--strict" "$F" || { echo "    validate.sh does not pass --strict"; exit 1; }
grep -qF "skipped claude plugin validate --strict" "$F" || { echo "    validate.sh has no visible skip notice"; exit 1; }
# On failure, show the validator's own findings instead of "run it to see why".
grep -qF 'STRICT_OUT=$(claude plugin validate' "$F" || { echo "    validate.sh discards the validator output"; exit 1; }
grep -qF "see CLAUDE.md Agent Models" "$F" && { echo "    validate.sh still points at the root CLAUDE.md"; exit 1; }
exit 0
