#!/usr/bin/env bash
# ABOUTME: Asserts the README's roster, rows, Agents table and tree name the verifier and the review workflow (opt-in).
# ABOUTME: The directory installs a trimmed copy without images/ and examples/, so README links into them are absolute.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
R="$PLUGIN_DIR/README.md"
assert_file "$R" || exit 1
rc=0
for p in 'agents-6' '6 agents, 2 hooks, 1 workflow' '**verifier**' 'review-swarm.js' '--watch' '/config' \
         'except the verifier' 'when you type `/turbocharge:review`' 'Tested with Claude Code' '2.1.287'; do
    grep -qF -- "$p" "$R" || { echo "    README missing: $p"; rc=1; }
done
for p in 'agents-5' '5 agents' 'src="images/' '](examples/'; do
    grep -qF -- "$p" "$R" && { echo "    README still has: $p"; rc=1; }
done
exit $rc
