#!/usr/bin/env bash
# ABOUTME: The directory copy's README (README.md through directory-readme.sh) holds nothing the directory scan holds
# ABOUTME: a version for (image names, the repo marketplace, dev scripts, CI) and keeps install and the hook disclosure.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
FILTER="$PLUGIN_DIR/scripts/directory-readme.sh"
assert_file "$FILTER" || exit 1
rc=0

# The filter: drops marked blocks, folds the blank runs left behind, refuses unbalanced markers.
OUT="$(printf 'A\n\n<!-- repo-only -->\nB\n<!-- /repo-only -->\n\nC\r\n' | bash "$FILTER")" \
    || { echo "    filter failed on a balanced block"; rc=1; }
[ "$OUT" = "$(printf 'A\n\nC')" ] || { echo "    filter output is wrong: $OUT"; rc=1; }
for bad in '<!-- repo-only -->\nB' '<!-- /repo-only -->' '<!-- repo-only -->\n<!-- repo-only -->\n<!-- /repo-only -->'; do
    ERR="$(printf "$bad\n" | bash "$FILTER" 2>&1 >/dev/null)" && { echo "    filter accepted: $bad"; rc=1; }
    printf '%s' "$ERR" | grep -q 'line [0-9]' || { echo "    refusal doesn't give a line: $ERR"; rc=1; }
done

# The real README, as the directory gets it.
D="$(bash "$FILTER" < "$PLUGIN_DIR/README.md")" || { echo "    filter refused README.md"; exit 1; }
for p in '<img' '.png' '.svg' 'icon' 'marketplace add' '--plugin-dir' 'scripts/' '.github' 'evals/' 'secret' 'token' \
    '](CHANGELOG.md)' 'repo-only'; do
    printf '%s' "$D" | grep -qiF -- "$p" && { echo "    directory README still has: $p"; rc=1; }
done
for p in 'claude plugin install turbocharge-nicodiansk@anthropic-plugin-directory' '### What the hooks do' \
    '### What the review workflow does' '`codemap stats`' 'never runs in your sessions' '## Measured'; do
    printf '%s' "$D" | grep -qF -- "$p" || { echo "    directory README lost: $p"; rc=1; }
done

# No other shipped text names a bundled image or font by file name.
cd "$PLUGIN_DIR" || exit 1
SHIPPED_LINE="$(grep '^SHIPPED=(' scripts/release.sh | sed 's/^SHIPPED=(//; s/)[[:space:]]*$//')"
# shellcheck disable=SC2086
set -- $SHIPPED_LINE
for a in $(git ls-files -- "$@" | sed -n -E 's#^(.*/)?([^/]+\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|otf))$#\2#p'); do
    HITS="$(git grep -lF -e "$a" -- "$@" ":(exclude)*$a" ':(exclude)README.md')"
    [ -z "$HITS" ] || { echo "    shipped text names the bundled $a: $HITS"; rc=1; }
done
exit $rc
