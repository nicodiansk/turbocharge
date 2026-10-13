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

grep -qF -- '/mnt/' "$E" || { echo "    eval.sh should refuse a /mnt/ claude"; exit 1; }
# A Windows claude reached through WSL interop is refused (uname faked to Linux).
FAKE="$(mktemp -d)"
trap 'rm -rf "$FAKE"' EXIT
printf '#!/bin/sh\necho Linux\n' > "$FAKE/uname"
printf '#!/bin/sh\nexit 0\n' > "$FAKE/claude"
printf '#!/bin/sh\nexit 0\n' > "$FAKE/jq"
chmod +x "$FAKE/uname" "$FAKE/claude" "$FAKE/jq"
if ERR="$(PATH="$FAKE:$PATH" TC_EVAL_CLAUDE=/mnt/c/fake/claude bash "$E" 1 2>&1 >/dev/null)"; then
    echo "    a /mnt/ claude should exit 1"; exit 1
fi
echo "$ERR" | grep -qF 'WSL interop' || { echo "    stderr should mention WSL interop: $ERR"; exit 1; }
exit 0
