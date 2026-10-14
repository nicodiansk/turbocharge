#!/usr/bin/env bash
# ABOUTME: Asserts CI runs the full gate (validate.sh: content-shape tests + claude plugin validate --strict) on every PR,
# ABOUTME: fails fast without jq or node, uses no secrets, pins its actions and CLIs, and has macOS and stable-CLI legs.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/.github/workflows/tests.yml"
assert_file "$W" || exit 1
rc=0
for p in "pull_request:" "bash scripts/validate.sh" "jq --version" "node --version" "@anthropic-ai/claude-code@" "contents: read" \
         "timeout-minutes:" "concurrency:" "cancel-in-progress: true" "macos-latest" '${{ matrix.cli }}'; do
    grep -qF -- "$p" "$W" || { echo "    tests.yml missing: $p"; rc=1; }
done
grep -qF 'secrets.' "$W" && { echo "    tests.yml must not use secrets"; rc=1; }
grep -qE 'actions/checkout@[0-9a-f]{40}' "$W"   || { echo "    pin actions/checkout to a commit SHA"; rc=1; }
grep -qE 'actions/setup-node@[0-9a-f]{40}' "$W" || { echo "    pin actions/setup-node to a commit SHA"; rc=1; }
grep -qE "node-version: '[0-9]+\.[0-9]+\.[0-9]+'" "$W" || { echo "    pin Node to an exact version"; rc=1; }
# Each CLI pin is an exact version, and there are at least two (the latest pin and the stable channel).
CLIS="$(grep -oE "cli: '[0-9]+\.[0-9]+\.[0-9]+'" "$W" | sort -u | wc -l | tr -d ' ')"
[ "$CLIS" -ge 2 ] || { echo "    the matrix needs two exact CLI pins (latest and stable), found $CLIS"; rc=1; }
exit $rc
