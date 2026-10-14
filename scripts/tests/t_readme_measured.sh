#!/usr/bin/env bash
# ABOUTME: Asserts README's Measured section carries the newest eval summary's family rows verbatim and explains them.
# ABOUTME: Keeps the published numbers in lockstep with evals/summary/<version>.md (3.3.0 eval harness).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
R="$PLUGIN_DIR/README.md"
assert_file "$R" || exit 1
# Plain-version summaries only: a labelled run (3.4.0-single.md, a sizing run) is not the release baseline.
S=$(ls "$PLUGIN_DIR"/evals/summary/*.md 2>/dev/null | grep -E '/[0-9]+\.[0-9]+\.[0-9]+\.md$' | sort -V | tail -1)
[ -n "$S" ] && [ -f "$S" ] || { echo "    no evals/summary/*.md to publish"; exit 1; }
SECTION="$(awk '{ sub(/\r$/, "") } /^## Measured/ { f=1; print; next } f && /^## / { exit } f' "$R")"
[ -n "$SECTION" ] || { echo "    README missing a '## Measured' section"; exit 1; }
rows=0
while IFS= read -r row; do
    rows=$((rows+1))
    printf '%s\n' "$SECTION" | grep -qxF -- "$row" || { echo "    Measured section lacks summary row: $row"; exit 1; }
done < <(tr -d '\r' < "$S" | grep -E '^\| (trigger|defects|planning|triage) \|')
[ "$rows" -gt 0 ] || { echo "    $(basename "$S") has no family rows"; exit 1; }
for p in 'WITH' 'W/OUT' 'Δ' 'Fired' 'scripts/eval.sh' 'never runs in your sessions' 'runs per arm' 'Sample:'; do
    printf '%s\n' "$SECTION" | grep -qF -- "$p" || { echo "    Measured section missing: $p"; exit 1; }
done
printf '%s\n' "$SECTION" | grep -qF 'TBD' && { echo "    Measured section still says TBD"; exit 1; }
exit 0
