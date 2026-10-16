#!/usr/bin/env bash
# ABOUTME: Aggregator for all content-shape tests for turbocharge plugin.
# ABOUTME: Each test file in scripts/tests/t_*.sh is sourced; non-zero exit fails the run.
set -u
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/../.." && pwd)"
export PLUGIN_DIR
FAIL=0
for t in "$TESTS_DIR"/t_*.sh; do
    [ -f "$t" ] || continue
    echo "--- $(basename "$t") ---"
    if bash "$t"; then
        echo "  PASS"
    else
        echo "  FAIL"
        FAIL=$((FAIL+1))
    fi
done
echo ""
if [ "$FAIL" -eq 0 ]; then echo "All tests passed."; exit 0
else echo "$FAIL test file(s) failed."; exit 1
fi
