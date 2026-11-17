#!/usr/bin/env bash
# ABOUTME: Behavioral test for hooks/git-guard.sh: feeds PreToolUse hook JSON on stdin, checks the deny JSON or silence.
# ABOUTME: Fixture folders (path with a space) and stub `uname` scripts make every platform branch run on macOS and Linux CI.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
GUARD="$PLUGIN_DIR/hooks/git-guard.sh"
if ! command -v jq >/dev/null 2>&1; then echo "    jq not installed, skipping"; exit 0; fi
assert_file "$GUARD" || exit 1

ROOT="$(mktemp -d)"; trap 'rm -rf "$ROOT"' EXIT
WORK="$ROOT/work dir"; mkdir -p "$WORK"
FAILS=0
CHECK_CWD="$WORK"; CHECK_TOOL="Bash"; PREPATH=""

# check [VAR=value ...] <allow|block> <command> [reason substring]
check() {
    local envs=()
    while [ $# -gt 0 ] && [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do envs+=("$1"); shift; done
    local mode="$1" cmd="$2" want="${3:-}" out rc err
    out="$(jq -nc --arg c "$cmd" --arg d "$CHECK_CWD" --arg t "$CHECK_TOOL" \
        '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{command:$c},cwd:$d}' \
        | env ${envs[@]+"${envs[@]}"} PATH="${PREPATH:+$PREPATH:}$PATH" bash "$GUARD" 2>"$ROOT/err")"; rc=$?
    err="$(cat "$ROOT/err")"
    if [ "$rc" != 0 ]; then bad "$cmd" "exit $rc"; return; fi
    if [ -n "$err" ]; then bad "$cmd" "stderr: $err"; return; fi
    if [ "$mode" = allow ]; then
        [ -z "$out" ] || bad "$cmd" "expected allow, got: $out"
    else
        [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)" = deny ] \
            || { bad "$cmd" "expected deny, got: $out"; return; }
        printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null 2>&1 \
            || { bad "$cmd" "deny lacks hookEventName PreToolUse"; return; }
        [ -z "$want" ] || printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -qF -- "$want" \
            || bad "$cmd" "reason lacks '$want': $out"
    fi
}
bad() { echo "    FAIL: $1 -- $2"; FAILS=$((FAILS+1)); }
# check_raw <allow> <stdin text>
check_raw() {
    local out rc
    out="$(printf '%s' "$1" | bash "$GUARD" 2>"$ROOT/err")"; rc=$?
    [ "$rc" = 0 ] && [ -z "$out" ] && [ ! -s "$ROOT/err" ] || bad "raw: $1" "rc=$rc out=$out err=$(cat "$ROOT/err")"
}

# --- Task 1: bulk git add on a plain command
check block 'git add -A' 'Stage explicit paths after `git status`'
for c in 'git add .' 'git add ./' 'git add :/' 'git add -u' 'git add --update' 'git add --all'; do check block "$c"; done
check allow 'git add .gitignore'
check allow 'git add ./src'
CHECK_TOOL=Read check allow 'git add -A'
check_raw 'not json'
check allow ''
check TURBOCHARGE_GIT_GUARD=off allow 'git add -A'
check TURBOCHARGE_GIT_GUARD=OFF allow 'git add -A'

# --- Task 2: quotes and command chains
for c in 'git status && git add -A' 'git diff; git add .' 'cd sub && git add --all' 'git log | cat || git add -u' '(git add -A)' 'git status&&git add -A' 'git add "."'; do check block "$c"; done
check allow 'echo "git add -A"'
check allow "printf '%s' 'git add .'"
check allow 'git commit -m "use git add -A" -- a.txt'
check allow "git add \"my file.txt\" 'other file'"
check allow 'git add "unterminated'
check allow ';;'
check allow '&&'
check allow 'git'
check block 'git status # note
git add -A'
check allow 'git status # git add -A'

# --- Task 3: command substitution and heredocs
CLASSIC="$(printf '%s\n' 'git add new.txt && git commit -m "$(cat <<'"'EOF'"'' \
    "feat: it's done" '' 'Notes 1) say "git add -A" and --no-verify' 'EOF' ')" -- new.txt')"
check allow "$CLASSIC"
check allow "$(printf '%s\n' 'cat > notes.md <<'"'EOF'" 'git add -A' 'EOF')"
check block "$(printf '%s\n' 'cat <<EOF' 'x' 'EOF' 'git add -A')"
check block "$(printf '%s\n' 'cat <<-EOF' '	x' '	EOF' 'git add -A')"
check block 'x=$(git add -A)'
check block 'out=`git add .`'
check block 'echo "$(git add -A)"'
check allow 'git add $(git ls-files -m)'
check allow 'echo $(echo a) && git add b.txt'
check block "$(printf '%s\n' 'cat <<< x; git add .')"

check allow 'echo $(git add -A'
check block 'echo $(echo $(echo $(echo $(git add -A))))'
check allow 'echo $(echo $(echo $(echo $(echo $(git add -A)))))'
check block 'echo "a $(echo "b $(git add -A)") c"'

# --- Task 4: git global options, add/stage, commit -a
for c in 'git -C "../other repo" add -A' 'git --git-dir=.git --work-tree=. add .' 'git -c color.ui=never add -- .' 'git stage -A' 'git add -Av' 'git add -vu' 'git add x -A' 'git add -- ./'; do
    check block "$c" 'Stage explicit paths after `git status`'
done
for c in 'git commit -a -m x' 'git commit --all' 'git commit -am "x"' 'git commit -qam x' 'git commit -m x -a'; do
    check block "$c" 'Stage explicit paths after `git status`'
done
for c in 'git add -- -A' 'git add -n .' 'git add --dry-run -A' 'git add -nA' 'git add --chmod=+x a.sh'; do check allow "$c"; done
for c in 'git commit -m -a' 'git commit -ma' 'git commit --message --all' 'git commit --allow-empty -m x' "git commit --allow-empty-message -m ''" \
    'git commit --amend --no-edit' 'git commit -uno -m x' 'git commit -m x -- -a' 'git commit --author -a -m x' 'git commit -qF -a'; do check allow "$c"; done

# --- Task 5: skipped git hooks
for c in 'git commit --no-verify -m x' 'git commit -n -m x' 'git commit -nm x' 'git push --no-verify' 'git push origin main --no-verify' \
    'git -c core.hooksPath=/dev/null commit -m x' 'git -c CORE.HOOKSPATH= push' 'git --config-env=core.hooksPath=X status' \
    'git --config-env core.hooksPath=X status' 'git -qn commit --no-verify'; do
    check block "$c" "skips the repository's git hooks"
done
for c in 'git push -n' 'git push --dry-run' 'git commit -m "--no-verify is banned"' 'git commit -mn' 'git -c core.editor=vim commit' \
    'git commit -m x -- --no-verify' 'git -c core.hooksPathX=1 status' 'git push -- --no-verify'; do check allow "$c"; done

# --- Task 6: wrappers and nested shells
for c in "bash -c 'git add -A'" 'sh -lc "cd x && git commit -am wip"' "zsh -c 'bash -c \"git push --no-verify\"'" "eval 'git add .'" 'eval git add -A' \
    'sudo git add -A' 'env GIT_DIR=.git git add -A' 'FOO=1 /usr/bin/git add --all' 'command git add -u' '\git add -A' 'FOO=$X git add -A' \
    'nohup nice git add -A' "bash -x -c 'git add -A'" 'if git add -A; then echo ok; fi' 'for f in a b; do git add -A; done' '! git add -A'; do check block "$c"; done
for c in 'bash -c "$SCRIPT"' 'bash script.sh' 'sudo -u bob git add -A' "echo bash -c 'git add -A'" 'eval "$CMD"' 'eval git add $x' 'bash -c' 'sudo' 'env'; do check allow "$c"; done

wrap() { printf 'bash -c %q' "$1"; }
check block "$(wrap "$(wrap "$(wrap 'git add -A')")")"
check allow "$(wrap "$(wrap "$(wrap "$(wrap 'git add -A')")")")"

# --- Task 7: rm -r through a symlink, with cd tracking
mkdir -p "$WORK/plain" "$WORK/linked" "$WORK/deep/a" "$WORK/node_modules/.pnpm/pkg" "$ROOT/stub-linux"
echo x > "$WORK/plain/f.txt"; echo x > "$WORK/node_modules/.pnpm/pkg/index.js"
ln -s ../plain "$WORK/linked/up"
ln -s ../../plain "$WORK/deep/a/l"
ln -s plain "$WORK/linkonly"
ln -s linked "$WORK/linkdir"
ln -s .pnpm/pkg "$WORK/node_modules/pkg"
printf '#!/bin/sh\necho Linux\n' > "$ROOT/stub-linux/uname"; chmod +x "$ROOT/stub-linux/uname"
PREPATH="$ROOT/stub-linux"

check block 'rm -rf linkdir/' 'linkdir'
for c in 'rm -r linkonly/.' 'rm -fr linkonly//' 'rm -R linkdir/' 'rm --recursive linkdir/' 'rm -r -f -- linkdir/' "/bin/rm -rf \"$WORK/linkdir/\"" \
    'sudo rm -rf linkdir/' 'rm -rf plain linkdir/'; do check block "$c" 'goes through the symlink'; done
CHECK_CWD=/ check block "cd \"$WORK\" && rm -rf linkdir/" 'linkdir'
CHECK_CWD=/ check block "cd '$ROOT' && cd 'work dir' && rm -rf linkdir/"
for c in 'rm -rf linked' 'rm -rf deep' 'rm -rf node_modules' 'rm -rf linkonly' 'rm -rf plain/' 'rm -rf missing/' 'rm -f linkdir/' 'rm -rf linked/*' \
    'cd "$X" && rm -rf linkdir/' 'cd - && rm -rf linkdir/' 'rm -rf' 'rm' 'rm -rf -- ' 'rm -rf /' 'rm -rf linkdir'; do check allow "$c"; done
CHECK_CWD=/ check allow 'rm -rf linkdir/'
CHECK_CWD=/ check allow "cd \"$WORK/plain\" && rm -rf linkdir/"

# --- Task 8: Windows shells, a folder holding links
mkdir -p "$WORK/deeper/a/b" "$WORK/many" "$ROOT/stub-darwin" "$ROOT/stub-win" "$ROOT/stub-msys" "$ROOT/stub-cygwin"
ln -s ../../../plain "$WORK/deeper/a/b/l"
for k in 01 02 03 04 05 06 07 08 09 10 11 12; do ln -s ../plain "$WORK/many/l$k"; done
stub() { printf '#!/bin/sh\necho %s\n' "$2" > "$ROOT/stub-$1/uname"; chmod +x "$ROOT/stub-$1/uname"; }
stub darwin Darwin; stub win MINGW64_NT-10.0-19045; stub msys MSYS_NT-10.0; stub cygwin CYGWIN_NT-10.0
# check_on <stub name> <check args...>: check with that stub's uname first on PATH
check_on() { local PREPATH="$ROOT/stub-$1"; shift; check "$@"; }
check_win() { check_on win "$@"; }
reason_on() {
    jq -nc --arg c "$2" --arg d "$CHECK_CWD" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d}' \
        | PATH="$ROOT/stub-$1:$PATH" bash "$GUARD" | jq -r '.hookSpecificOutput.permissionDecisionReason // empty'
}

check_win block 'rm -rf linked' 'up'
check_win block 'rm -rf linked' 'holds links'
for c in 'rm -r deep' 'rm -rf node_modules' "/bin/rm -rf \"$WORK/linked\"" 'rm -rf linked/'; do check_win block "$c" 'holds links'; done
check_on msys block 'rm -rf linked' 'holds links'
check_on cygwin block 'rm -rf linked' 'holds links'
for c in 'rm -rf plain' 'rm -rf deeper' 'rm -rf linkonly' 'rm -f linked' 'rm -rf missing'; do check_win allow "$c"; done
check_win block 'rm -rf many' '(+2 more)'
MANY="$(reason_on win 'rm -rf many')"
[ "$(printf '%s' "$MANY" | grep -o 'l[0-9][0-9]' | wc -l | tr -d ' ')" = 10 ] || bad 'rm -rf many' "reason doesn't list exactly 10 links: $MANY"
for s in linux darwin; do for c in 'rm -rf linked' 'rm -rf node_modules' 'rm -rf many'; do check_on "$s" allow "$c"; done; done

# --- Task 9: git worktree remove
for c in 'git worktree remove linkdir/' 'git worktree remove --force linkdir/' 'git worktree remove -f -f linkonly/.'; do check block "$c" 'goes through the symlink'; done
CHECK_CWD=/ check block "git -C \"$WORK\" worktree remove linkdir/" 'linkdir'
CHECK_CWD=/ check block "cd \"$ROOT\" && git -C 'work dir' worktree remove linkdir/" 'linkdir'
for c in 'git worktree remove linked' 'git worktree remove -f -f deep' 'git worktree remove plain' 'git worktree list' 'git worktree add ../x' 'git worktree prune' \
    'git worktree remove' 'git worktree' 'git worktree remove $W' 'git worktree remove -f'; do check allow "$c"; done
CHECK_CWD=/ check allow "git worktree remove linkdir/"
CHECK_CWD=/ check allow "git -C \"\$D\" worktree remove linkdir/"
for c in 'git worktree remove linked' 'git worktree remove -f -f deep'; do check_win block "$c" 'holds links'; done
check_win block 'git worktree remove linked' 'up'
check_win allow 'git worktree remove plain'
check_win allow 'git worktree list'

# --- Task 10: per-guard opt-outs and the builder's allowed table
check TURBOCHARGE_GIT_GUARD_STAGING=off allow 'git add -A'
check TURBOCHARGE_GIT_GUARD_STAGING=off allow 'git commit -am x'
check TURBOCHARGE_GIT_GUARD_STAGING=off block 'git commit --no-verify -m x' "skips the repository's git hooks"
check TURBOCHARGE_GIT_GUARD_STAGING=off block 'git commit -an -m x' "skips the repository's git hooks"
check TURBOCHARGE_GIT_GUARD_NOVERIFY=Off allow 'git push --no-verify'
check TURBOCHARGE_GIT_GUARD_NOVERIFY=Off allow 'git -c core.hooksPath=x status'
check TURBOCHARGE_GIT_GUARD_NOVERIFY=Off block 'git add .' 'stages files in bulk'
check TURBOCHARGE_GIT_GUARD_SYMLINKS=off allow 'rm -rf linkdir/'
check_win TURBOCHARGE_GIT_GUARD_SYMLINKS=off allow 'rm -rf linked'
check_win TURBOCHARGE_GIT_GUARD_SYMLINKS=off allow 'git worktree remove linked'
check TURBOCHARGE_GIT_GUARD_SYMLINKS=off block 'git add -A'
check TURBOCHARGE_GIT_GUARD=on block 'git add -A'
check TURBOCHARGE_GIT_GUARD_STAGING=on block 'git add -A'
check TURBOCHARGE_GIT_GUARD_STAGING=0 block 'git add -A'
# with the symlink guard off, find never runs (a spy find and a Windows uname)
mkdir -p "$ROOT/stub-spy"
printf '#!/bin/sh\necho MINGW64_NT-10.0\n' > "$ROOT/stub-spy/uname"
printf '#!/bin/sh\ntouch "%s"\nexit 0\n' "$ROOT/find-ran" > "$ROOT/stub-spy/find"
chmod +x "$ROOT/stub-spy/uname" "$ROOT/stub-spy/find"
check_on spy TURBOCHARGE_GIT_GUARD_SYMLINKS=off allow 'rm -rf linked'
[ ! -e "$ROOT/find-ran" ] || bad 'rm -rf linked' 'find ran with the symlink guard off'
check_on spy allow 'rm -rf linked'
[ -e "$ROOT/find-ran" ] || bad 'rm -rf linked' 'the spy find never ran with the guard on: the test has no teeth'
# the builder's pathspec commits and its read-only git calls are never blocked
for c in 'git add hooks/git-guard.sh scripts/tests/t_git_guard.sh' \
    'git commit -m "feat: x" -- hooks/git-guard.sh scripts/tests/t_git_guard.sh' \
    'git add new.txt; git commit -m "test: pin" -- new.txt a.txt' \
    'git checkout -- a.txt' 'git status --porcelain -- a.txt b.txt' 'LANE_SHA=$(git rev-parse HEAD)' \
    'git rev-list --count abc123..HEAD -- a.txt' \
    "git diff abc123..HEAD -- a.txt | grep -E '^[+]' | grep -vE '^[+]{3} '" \
    'git diff --diff-filter=D --name-only abc123..HEAD -- a.txt'; do check allow "$c"; done
COMMIT_FORM='`git commit -m "<message>" -- <this task'"'"'s files>`'
for f in agents/builder.md skills/build/SKILL.md; do
    grep -qF -- "$COMMIT_FORM" "$PLUGIN_DIR/$f" \
        || bad "$f" "the builder's commit form changed: update the allowed table in t_git_guard.sh"
done

[ "$FAILS" = 0 ] || { echo "    $FAILS check(s) failed"; exit 1; }
exit 0
