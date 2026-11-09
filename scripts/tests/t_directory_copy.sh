#!/usr/bin/env bash
# ABOUTME: The directory copy (markdown through directory-filter.sh, no hooks, no review workflow) holds nothing the scan
# ABOUTME: holds a version for: image names, repo marketplace, dev scripts, CI, exit gate, swarm, file types; keeps install and disclosures.
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
    '2 hooks' '--watch' 'swarm' 'workflow' 'lens reviewer' 'hook' 'SessionStart' 'pre-load'; do
    printf '%s' "$D" | grep -qiF -- "$p" && { echo "    directory README still has: $p"; rc=1; }
done
for p in 'claude plugin install turbocharge-nicodiansk@anthropic-plugin-directory' \
    'never runs in your sessions' '## Measured' '10 skills, 6 agents. One system' \
    'In Chat, agents are ignored' 'get it on every dispatch' '| **review** |' 'one senior reviewer' \
    '## What the skills run and send' '[NOTICE](NOTICE)'; do
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

# The directory copy ships no hooks (3.5.7 was refused: command hooks only from Verified organizations), so no shipped
# markdown file, as the directory gets it, says what a hook does. Repo installs keep the hooks and their text.
for f in $(git ls-files -- "$@" ':(exclude)hooks' | grep '\.md$'); do
    OUT="$(bash "$FILTER" < "$f")" || { echo "    filter refused $f"; rc=1; continue; }
    for p in 'SessionStart' 'session-start' 'hooks/' 'hooks.json'; do
        printf '%s' "$OUT" | grep -qF -- "$p" && { echo "    directory copy of $f still has: $p"; rc=1; }
    done
done
grep -qF 'SessionStart hook also prints it' skills/wrap/SKILL.md || { echo "    repo wrap skill lost the hook line"; rc=1; }
grep -qF 'hooks/hooks.json exists' skills/setup/SKILL.md || { echo "    repo setup skill lost the hooks.json check"; rc=1; }

# No shipped text starts a shell segment with a password-store command and an argument: the scan read
# "(pass sometimes," as the pass command reading a secret and held every version from 3.4.1 to 3.5.6 for it.
HITS="$(cd "$PLUGIN_DIR" && grep -rniE '(^|[({|;`]|&&|[|][|]|[$][(])[[:space:]]*["'"'"']?(pass|gopass|secret-tool|lpass|keepassxc-cli)["'"'"']?[[:space:]]+[^[:space:]|)}]' \
    agents hooks skills templates workflows README.md NOTICE 2>/dev/null)"
[ -z "$HITS" ] || { echo "    shipped text reads as a password-store command: $HITS"; rc=1; }

# No other shipped text names a bundled image or font by file name.
for a in $(git ls-files -- "$@" | sed -n -E 's#^(.*/)?([^/]+\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|otf))$#\2#p'); do
    HITS="$(git grep -lF -e "$a" -- "$@" ":(exclude)*$a" ':(exclude)README.md')"
    [ -z "$HITS" ] || { echo "    shipped text names the bundled $a: $HITS"; rc=1; }
done

# From a non-Verified organization the directory takes only Markdown, text, JSON, YAML and images, and nothing that
# starts with #!: it refused 3.5.8 with LOCAL_CODE_FILE_TYPE (count 2) for the debug skill's script and TypeScript example.
DROP_LIST="$(grep '^DIRECTORY_DROP=(' scripts/release.sh | sed 's/^DIRECTORY_DROP=(//; s/)[[:space:]]*$//')"
for f in $(git ls-files -- "$@"); do
    dropped=0
    for e in $DROP_LIST; do case "$f" in "$e" | "$e"/*) dropped=1 ;; esac; done
    [ "$dropped" = 1 ] && continue
    case "$f" in
        *.md | *.txt | *.json | *.yaml | *.yml | *.png | *.jpg | *.jpeg | *.gif | *.webp | *.ico | LICENSE | NOTICE) ;;
        *) echo "    the directory copy ships $f, a type the directory refuses"; rc=1 ;;
    esac
    [ "$(awk 'NR == 1 { print substr($0, 1, 2) }' "$f")" = '#!' ] \
        && { echo "    the directory copy ships $f, which starts with #!"; rc=1; }
done
# The directory copy drops the agents' memory key (LOCAL_CODE_FRONTMATTER_KEY), so no shipped markdown file, as the
# directory gets it, says the agents have it outside the frontmatter (release.sh drops the key itself; t_release_tree.sh).
# Repo installs keep the key and the text.
for f in $(git ls-files -- "$@" | grep '\.md$'); do
    OUT="$(bash "$FILTER" < "$f")" || { echo "    filter refused $f"; rc=1; continue; }
    BODY="$(printf '%s\n' "$OUT" | awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm')"
    printf '%s' "$BODY" | grep -qF 'memory: project' && { echo "    directory copy of $f still says memory: project"; rc=1; }
    printf '%s' "$BODY" | grep -qi 'agent memory' && { echo "    directory copy of $f still tells Claude to use agent memory"; rc=1; }
done
grep -qF 'memory: project' README.md || { echo "    repo README lost the agent memory line"; rc=1; }
grep -qF 'Update your agent memory' agents/builder.md || { echo "    repo builder lost its agent memory line"; rc=1; }
# The copy drops the researcher's background key too, so its description can't promise background by default.
grep -qF 'background by default' agents/researcher.md && { echo "    researcher still says it runs in background by default"; rc=1; }
# The debug skill, as the directory gets it, keeps the method but names neither left-out file.
for f in skills/debug/condition-based-waiting.md skills/debug/root-cause-tracing.md; do
    OUT="$(bash "$FILTER" < "$f")" || { echo "    filter refused $f"; rc=1; continue; }
    for p in 'find-polluter' 'condition-based-waiting-example'; do
        printf '%s' "$OUT" | grep -qF -- "$p" && { echo "    directory copy of $f still names $p"; rc=1; }
    done
done
RT="$(bash "$FILTER" < skills/debug/root-cause-tracing.md)"
printf '%s' "$RT" | grep -qF 'one at a time' || { echo "    directory root-cause-tracing lost the bisection method"; rc=1; }
grep -qF 'find-polluter.sh' skills/debug/root-cause-tracing.md || { echo "    repo root-cause-tracing lost the script"; rc=1; }
grep -qF 'condition-based-waiting-example.ts' skills/debug/condition-based-waiting.md \
    || { echo "    repo condition-based-waiting lost the example"; rc=1; }
exit $rc
