#!/usr/bin/env bash
# ABOUTME: Runs two guard tests against fixtures: the icon test explains an unreadable PNG header, and the SIGPIPE
# ABOUTME: check reads each path whole (a path with a space) and says it's a heuristic (3.2.1 PR review follow-ups).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
T="$PLUGIN_DIR/scripts/tests"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# An icon.png of only the 8 PNG magic bytes has no IHDR: width and height read empty.
mkdir -p "$TMP/icon/scripts/tests" "$TMP/icon/.claude-plugin"
cp "$T/helpers.sh" "$TMP/icon/scripts/tests/"
printf '\211PNG\r\n\032\n' > "$TMP/icon/.claude-plugin/icon.png"
OUT="$(PLUGIN_DIR="$TMP/icon" bash "$T/t_plugin_icon.sh" 2>&1)" && { echo "    t_plugin_icon.sh passed a header-only PNG"; exit 1; }
printf '%s' "$OUT" | grep -qF 'could not read'       || { echo "    t_plugin_icon.sh doesn't explain an unreadable header: $OUT"; exit 1; }
printf '%s' "$OUT" | grep -qF 'integer expression'  && { echo "    t_plugin_icon.sh leaks a shell error: $OUT"; exit 1; }

# A committed script whose path has a space, setting pipefail and piping into head.
R="$TMP/repo"
mkdir -p "$R/scripts"
# The pipe into head is assembled at run time so this file doesn't trip the very check it drives.
printf '#!/usr/bin/env bash\nset -o pipefail\nx | %s -1\n' head > "$R/scripts/a b.sh"
git -C "$R" init -q
git -C "$R" add "scripts/a b.sh"
OUT="$(PLUGIN_DIR="$R" bash "$T/t_no_sigpipe_under_pipefail.sh" 2>&1)" && { echo "    t_no_sigpipe_under_pipefail.sh missed a path with a space"; exit 1; }
printf '%s' "$OUT" | grep -qF 'a b.sh' || { echo "    t_no_sigpipe_under_pipefail.sh doesn't name 'a b.sh': $OUT"; exit 1; }

grep '^# ABOUTME:' "$T/t_no_sigpipe_under_pipefail.sh" | grep -qF 'heuristic' \
    || { echo "    t_no_sigpipe_under_pipefail.sh's ABOUTME doesn't say it's a heuristic"; exit 1; }
exit 0
