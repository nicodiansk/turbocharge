#!/usr/bin/env bash
# ABOUTME: Asserts ship's "Triage review comments" works from comments in a file or pasted: verifies each through the
# ABOUTME: verifier, fixes valid ones locally, drafts replies, and never reads or writes the PR itself (no gh api, no push).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
S="$PLUGIN_DIR/skills/ship/SKILL.md"
assert_file "$S" || exit 1
SEC=$(awk '{ sub(/\r$/, "") } /^## Triage review comments/ { f=1; next } f && /^## / { exit } f' "$S")
[ -n "$SEC" ] || { echo "    could not find the '## Triage review comments' section"; exit 1; }
fail=0
need() { printf '%s\n' "$SEC" | grep -qF -- "$1" || { echo "    Triage review comments missing: $1"; fail=1; }; }
for p in 'pasted' 'never pushes' 'never posts' 'already answered' 'turbocharge:verifier' 'UNCERTAIN' 'false positive' \
  'nit' 'decided earlier' 'stop' 'not registered' 'never edited' 'Never verify an item yourself' 'verified by' \
  'commit by pathspec' 'drafted reply'; do
  need "$p"
done
# 3.5.0: the directory held every update whose plugin read and wrote PRs with the user's GitHub login ("Update adds
# credential forward"). Watching a PR is Claude Code's /autofix-pr; triage works from comments handed over.
for p in 'gh api' 'gh pr checks' 'gh pr comment' '--watch' '/replies' 'Watch and triage'; do
  grep -qF -- "$p" "$S" && { echo "    ship still has: $p"; fail=1; }
done
printf '%s\n' "$SEC" | grep -qF 'git push' && { echo "    triage pushes"; fail=1; }
PRE=$(awk '{ sub(/\r$/, "") } /^## Step 1/ { exit } /^---$/ { n++; next } n>=2' "$S")
for p in triage 'Triage review comments' pasted '/autofix-pr'; do
  printf '%s\n' "$PRE" | grep -qF -- "$p" || { echo "    routing text before Step 1 missing: $p"; fail=1; }
done
FM=$(frontmatter "$S")
printf '%s\n' "$FM" | grep -q '^argument-hint' && { echo "    ship takes no arguments now (no --watch)"; fail=1; }
DESC=$(printf '%s\n' "$FM" | grep '^description:')
printf '%s\n' "$DESC" | grep -qF 'pasted' || { echo "    ship description must name triage of comments saved or pasted"; fail=1; }
for p in 'pr-comments.json' 'PR #7' 'slugify' 'gh' 'watch'; do
  printf '%s\n' "$DESC" | grep -qwF -- "$p" && { echo "    ship description has: '$p'"; fail=1; }
done
exit $fail
