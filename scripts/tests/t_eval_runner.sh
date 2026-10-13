#!/usr/bin/env bash
# ABOUTME: Content and usage test for scripts/eval.sh, the cost-capped eval runner.
# ABOUTME: Checks the cap guard, the pinned claude plugin eval flags, and that results are gitignored.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
E="$PLUGIN_DIR/scripts/eval.sh"
assert_file "$E" || exit 1
if ERR="$(bash "$E" 2>&1 >/dev/null)"; then echo "    eval.sh with no cap should exit non-zero"; exit 1; fi
echo "$ERR" | grep -qi 'usage' || { echo "    eval.sh with no cap should print usage on stderr"; exit 1; }
for p in '--trust-plugin' '--scaffold' '--threshold 0' '--no-publish' '--judge-model' '--max-cost-usd' \
         '--allow-tools Bash Write Edit' '--output-dir' 'aggregate-result.json' 'eval-report.sh' 'evals/summary/' 'MINGW'; do
    grep -qF -- "$p" "$E" || { echo "    missing '$p' in eval.sh"; exit 1; }
done
if grep -qF -- '--json' "$E"; then echo "    eval.sh must not use --json"; exit 1; fi
assert_grep "$PLUGIN_DIR/.gitignore" '^evals/results/' || exit 1
exit 0
