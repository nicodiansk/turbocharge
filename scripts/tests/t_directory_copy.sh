#!/usr/bin/env bash
# ABOUTME: The directory copy (markdown through directory-filter.sh, no exit gate, no review workflow) holds nothing the scan
# ABOUTME: holds a version for: image names, repo marketplace, dev scripts, CI, exit gate, swarm; keeps install and disclosures.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
FILTER="$PLUGIN_DIR/scripts/directory-filter.sh"
assert_file "$FILTER" || exit 1
rc=0

# The filter: drops repo-only blocks, un-comments directory-only blocks, folds blank runs, refuses unbalanced markers.
OUT="$(printf 'A\n\n<!-- repo-only -->\nB\n<!-- /repo-only -->\n<!-- directory-only\nD\n-->\n\nC\r\n' | bash "$FILTER")" \
    || { echo "    filter failed on balanced blocks"; rc=1; }
[ "$OUT" = "$(printf 'A\n\nD\n\nC')" ] || { echo "    filter output is wrong: $OUT"; rc=1; }
for bad in '<!-- repo-only -->\nB' '<!-- /repo-only -->' '<!-- repo-only -->\n<!-- directory-only\n-->' \
    '<!-- directory-only\nB' '<!-- directory-only\n<!-- repo-only -->\n-->'; do
    ERR="$(printf "$bad\n" | bash "$FILTER" 2>&1 >/dev/null)" && { echo "    filter accepted: $bad"; rc=1; }
    printf '%s' "$ERR" | grep -q 'line [0-9]' || { echo "    refusal doesn't give a line: $ERR"; rc=1; }
done

# The real README, as the directory gets it.
D="$(bash "$FILTER" < "$PLUGIN_DIR/README.md")" || { echo "    filter refused README.md"; exit 1; }
for p in '<img' '.png' '.svg' 'icon' 'marketplace add' '--plugin-dir' 'scripts/' '.github' 'evals/' 'secret' 'token' \
    '](CHANGELOG.md)' 'repo-only' 'directory-only' 'exit gate' 'builder-exit-gate' 'SubagentStop' 'SubagentHandback' \
    '2 hooks' '--watch' 'swarm' 'workflow' 'lens reviewer'; do
    printf '%s' "$D" | grep -qiF -- "$p" && { echo "    directory README still has: $p"; rc=1; }
done
for p in 'claude plugin install turbocharge-nicodiansk@anthropic-plugin-directory' '### What the hooks do' \
    '`codemap stats`' 'never runs in your sessions' '## Measured' '10 skills, 6 agents, 1 hook.' \
    '| SessionStart hook |' '| **SessionStart** |' '| **review** |' 'one senior reviewer'; do
    printf '%s' "$D" | grep -qF -- "$p" || { echo "    directory README lost: $p"; rc=1; }
done

# The review skill, as the directory gets it: one code-reviewer, no workflow to launch, no tip pointing at one.
RV="$(bash "$FILTER" < "$PLUGIN_DIR/skills/review/SKILL.md")" || { echo "    filter refused skills/review/SKILL.md"; exit 1; }
for p in 'swarm' 'workflow' 'opt-in' 'lens' 'verifier' 'Tip:' 'Step 3'; do
    printf '%s' "$RV" | grep -qiF -- "$p" && { echo "    directory review skill still has: $p"; rc=1; }
done
for p in 'NO MERGE WITHOUT CODE REVIEW' 'Nothing to review' 'Dispatch `turbocharge:code-reviewer`' 'Declined to judge' \
    'No agent here' 'Ready to ship?' '## Red Flags'; do
    printf '%s' "$RV" | grep -qF -- "$p" || { echo "    directory review skill lost: $p"; rc=1; }
done

# The directory copy leaves out the review workflow, the only code added since the live 2.8.1: the directory held 3.5.0
# to 3.5.2 for "Update adds credential forward". Repo installs keep it; keep credential-like words out of it anyway.
grep -nEi 'secret|credential|password|token|api[_ -]?key|\bkey\b|byKey' "$PLUGIN_DIR/workflows/review-swarm.js" \
    && { echo "    workflows/review-swarm.js has credential-like words again"; rc=1; }

cd "$PLUGIN_DIR" || exit 1
SHIPPED_LINE="$(grep '^SHIPPED=(' scripts/release.sh | sed 's/^SHIPPED=(//; s/)[[:space:]]*$//')"
# shellcheck disable=SC2086
set -- $SHIPPED_LINE

# No shipped markdown file, as the directory gets it, mentions the swarm.
for f in $(git ls-files -- "$@" | grep '\.md$'); do
    OUT="$(bash "$FILTER" < "$f")" || { echo "    filter refused $f"; rc=1; continue; }
    printf '%s' "$OUT" | grep -qi 'swarm' && { echo "    directory copy of $f still mentions the swarm"; rc=1; }
done

# No other shipped text names a bundled image or font by file name.
for a in $(git ls-files -- "$@" | sed -n -E 's#^(.*/)?([^/]+\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|otf))$#\2#p'); do
    HITS="$(git grep -lF -e "$a" -- "$@" ":(exclude)*$a" ':(exclude)README.md')"
    [ -z "$HITS" ] || { echo "    shipped text names the bundled $a: $HITS"; rc=1; }
done
exit $rc
