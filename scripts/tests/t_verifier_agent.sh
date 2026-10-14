#!/usr/bin/env bash
# ABOUTME: Asserts the verifier agent is read-only, Sonnet, capped, memory-free and registered in validate.sh.
# ABOUTME: It tries to refute one finding and answers with a fixed three-line verdict.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/agents/verifier.md"
assert_file "$F" || exit 1
FM=$(frontmatter "$F")
for line in "name: verifier" "model: sonnet" "effort: medium" "maxTurns: 20"; do
    printf '%s\n' "$FM" | grep -qx "$line" || { echo "    verifier frontmatter missing '$line'"; exit 1; }
done
printf '%s\n' "$FM" | grep -q "^memory:" && { echo "    verifier must not carry memory:"; exit 1; }
printf '%s\n' "$FM" | grep -q "^description:" || { echo "    verifier missing description"; exit 1; }
assert_grep "$F" "Verdict: CONFIRMED | REFUTED | UNCERTAIN" || exit 1
assert_grep "$F" "Kind: defect | nit" || exit 1
assert_grep "$F" "Never modify" || exit 1
assert_grep "$F" "UNCERTAIN" || exit 1
assert_grep "$PLUGIN_DIR/scripts/validate.sh" '^EXPECTED_AGENTS=.*verifier' || exit 1
exit 0
