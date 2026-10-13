#!/usr/bin/env bash
# ABOUTME: Asserts CI runs the full gate (validate.sh: content-shape tests + claude plugin validate --strict) on every PR,
# ABOUTME: fails fast if jq is missing (assert_jq would otherwise skip silently), and uses no secrets.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/.github/workflows/tests.yml"
assert_file "$W" || exit 1
rc=0
for p in "pull_request:" "bash scripts/validate.sh" "jq --version" "@anthropic-ai/claude-code@" "contents: read"; do
    grep -qF -- "$p" "$W" || { echo "    tests.yml missing: $p"; rc=1; }
done
grep -qF 'secrets.' "$W" && { echo "    tests.yml must not use secrets"; rc=1; }
grep -qE '@anthropic-ai/claude-code@[0-9]+\.[0-9]+\.[0-9]+' "$W" || { echo "    pin the Claude Code CLI to an exact version"; rc=1; }
exit $rc
