#!/usr/bin/env bash
# ABOUTME: Asserts .claude/CLAUDE.md documents the directory release flow: the listing tracks a `release` branch that is
# ABOUTME: fast-forwarded to a tag, so master merges stop creating directory versions; why the switch had to wait; and
# ABOUTME: why the directory copy ships no hooks since 3.5.8.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
C="$PLUGIN_DIR/.claude/CLAUDE.md"
assert_file "$C" || exit 1
rc=0
for p in 'scripts/release.sh vX.Y.Z --push' 'DEV_ONLY' 'cancels a waiting publish request' 'turbocharge@turbocharge' 'Publish update'; do
    grep -qF -- "$p" "$C" || { echo "    CLAUDE.md release flow missing: $p"; rc=1; }
done
grep -qF 'git push origin vX.Y.Z:release' "$C" && { echo "    CLAUDE.md still pushes the tag itself to release (untrimmed)"; rc=1; }
# 3.5.7 was refused for its command hook (Verified organizations only); since 3.5.8 the directory copy ships no hooks.
for p in 'LOCAL_CODE_HOOK_COMMAND' 'LOCAL_CODE_NOT_CHECKED' 'Verified organization' 'mcp_tool' 'ships no hooks since 3.5.8'; do
    grep -qF -- "$p" "$C" || { echo "    CLAUDE.md missing the hook refusal: $p"; rc=1; }
done
# 3.5.8 was refused for two files outside the allowed types and for frontmatter keys (Verified organizations only).
for p in 'LOCAL_CODE_FILE_TYPE' 'LOCAL_CODE_FRONTMATTER_KEY' 'DIRECTORY_STRIP_KEYS' 'claude plugin validate' \
    'differs from the tag in six ways' 'a `context` or `agent` key' 'plan dispatches the planner'; do
    grep -qF -- "$p" "$C" || { echo "    CLAUDE.md missing the 3.5.8 refusal: $p"; rc=1; }
done
for p in 'ships SessionStart only' 'keeps SessionStart only' 'say `1 hook` instead of' 'DIRECTORY_TOOLS_DENY' \
    'DIRECTORY_MODEL_INVOCABLE'; do
    grep -qF -- "$p" "$C" && { echo "    CLAUDE.md still says: $p"; rc=1; }
done
exit $rc
