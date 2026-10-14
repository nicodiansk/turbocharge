#!/usr/bin/env bash
# ABOUTME: Asserts the automated PR review also runs when a PR is marked ready or reopened (3.4.0, dogfood D2).
# ABOUTME: Retargeting a stacked PR to master and marking it ready ran no review: only opened/synchronize triggered it.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/.github/workflows/claude-code-review.yml"
assert_file "$W" || exit 1
TYPES="$(awk '{ sub(/\r$/, "") } /^  pull_request:/ { f=1; next } f && /^  [a-z]/ { exit } f && /types:/ { print; exit }' "$W")"
[ -n "$TYPES" ] || { echo "    no types: line under pull_request in claude-code-review.yml"; exit 1; }
for t in opened synchronize ready_for_review reopened; do
    printf '%s' "$TYPES" | grep -qw "$t" || { echo "    the review doesn't trigger on $t: $TYPES"; exit 1; }
done
exit 0
