#!/usr/bin/env bash
# ABOUTME: Asserts ship's "Watch and triage" section waits for checks, collects unanswered comments, and answers each safely.
# ABOUTME: Pins the Review Focus cases: issue comments have no thread, and a rerun never answers a comment twice.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/ship/SKILL.md"
assert_file "$S" || exit 1
SEC=$(awk '{ sub(/\r$/, "") } /^## Watch and triage/ { f=1; next } f && /^## / { exit } f' "$S")
[ -n "$SEC" ] || { echo "    could not find the '## Watch and triage' section"; exit 1; }
fail=0
need() { printf '%s\n' "$SEC" | grep -qF -- "$1" || { echo "    Watch and triage missing: $1"; fail=1; }; }
for p in 'gh pr checks' '--watch' 'run_in_background' 'completion notification' \
  'repos/{owner}/{repo}/pulls/{pr}/comments' 'repos/{owner}/{repo}/issues/{pr}/comments' \
  'gh api user' 'in_reply_to_id' 'html_url' 'already answered' 'one message' \
  'never force-push' "Don't wait for a new automated review" 'Offline'; do
  need "$p"
done
exit $fail
