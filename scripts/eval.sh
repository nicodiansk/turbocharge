#!/usr/bin/env bash
# ABOUTME: Runs the evals/ suite with `claude plugin eval` under a cost cap, WITH and WITHOUT the plugin.
# ABOUTME: Writes raw results to evals/results/<label>/ (ignored) and a summary to evals/summary/<label>.md.
# Usage: eval.sh <max-cost-usd> [extra claude plugin eval args]
set -uo pipefail

CAP="${1:-}"
if [ -z "$CAP" ]; then
    echo "usage: scripts/eval.sh <max-cost-usd> [extra claude plugin eval args]" >&2
    exit 1
fi
shift

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        echo "run under WSL2 or Linux: Claude Code has no sandbox on native Windows, so Bash-granted eval runs are refused" >&2
        exit 1 ;;
esac
command -v claude >/dev/null 2>&1 || { echo "eval.sh: claude is not installed" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "eval.sh: jq is not installed" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="${TC_EVAL_LABEL:-$(jq -r '.version' "$ROOT/.claude-plugin/plugin.json")}"
RESULT_DIR="$ROOT/evals/results/$LABEL"
RESULT="$RESULT_DIR/aggregate-result.json"

# --output-dir writes the same document and keeps progress printing through a long run.
claude plugin eval "$ROOT" --trust-plugin --scaffold --allow-tools Bash Write Edit \
    --model "${TC_EVAL_MODEL:-claude-sonnet-5-5}" --judge-model "${TC_EVAL_JUDGE:-claude-sonnet-5-5}" \
    --threshold 0 --no-publish --max-cost-usd "$CAP" --output-dir "$RESULT_DIR" "$@"
EVAL_RC=$?

# The report runs even after a non-zero eval exit (2 = cost ceiling) so its reason prints.
if ! SUMMARY="$(bash "$ROOT/scripts/eval-report.sh" "$RESULT")"; then
    echo "eval.sh: eval-report rejected the run; evals/summary/$LABEL.md left unchanged" >&2
    exit 1
fi
mkdir -p "$ROOT/evals/summary"
printf '%s\n' "$SUMMARY" > "$ROOT/evals/summary/$LABEL.md"
printf '%s\n' "$SUMMARY"
exit "$EVAL_RC"
