#!/usr/bin/env bash
# ABOUTME: Asserts the README discloses everything all three hooks (SessionStart, builder exit gate, git-guard) read and run, and states their data flow exactly.
# ABOUTME: The claude.ai directory's security scan flags undisclosed behavior, so the disclosure must be complete and must not overclaim.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/README.md"
assert_file "$F" || exit 1
rc=0
for p in \
    "### What the hooks do" \
    "read-only" \
    "cleared or compacted" \
    "sends nothing over the network" \
    "becomes part of the session context" \
    ".claude/turbocharge-session.json" \
    ".claude/CLAUDE.md" \
    "md5sum" \
    "codemap stats" \
    ".github/workflows" \
    "never run on your machine" \
    "SubagentStop" \
    "SubagentHandback" \
    "builder-exit-gate.sh" \
    "git status --porcelain" \
    "commit these by pathspec" \
    "checked again" \
    "### What the review workflow does" \
    "workflows/review-swarm.js" \
    "at most 25" \
    "turbocharge:verifier" \
    "writes no files" \
    "trimmed copy" \
    "jq" \
    "hooks/git-guard.sh" \
    '(`PreToolUse` on `Bash`)' \
    "find <dir> -maxdepth 2 -type l" \
    "lets a command through whenever it can't tell" \
    "It never runs git" \
    "TURBOCHARGE_GIT_GUARD" \
    "TURBOCHARGE_GIT_GUARD_STAGING" \
    "TURBOCHARGE_GIT_GUARD_NOVERIFY" \
    "TURBOCHARGE_GIT_GUARD_SYMLINKS" \
    "run all three hooks" \
    "goes through a symlink" \
    "uname -s" \
    "On macOS and Linux" \
    "On Windows shells" \
    "NTFS junctions as links is unverified"; do
    grep -qF -- "$p" "$F" || { echo "    README missing hook disclosure: $p"; rc=1; }
done
grep -qF "run both hooks" "$F" && { echo "    README still says run both hooks"; rc=1; }
grep -qF "isn't checked again" "$F" && { echo "    README still says a resumed builder isn't checked again"; rc=1; }
grep -qF "### What the hook does" "$F" && { echo "    README still has the single-hook heading"; rc=1; }
grep -qF "merge / PR / keep / discard" "$F" && { echo "    README ship row still offers discard"; rc=1; }
# Hook output reaches the model as context, so "nothing leaves" would overclaim.
grep -qF "Nothing leaves your machine" "$F" && { echo "    README overclaims: hook output is sent as session context"; rc=1; }
exit $rc
