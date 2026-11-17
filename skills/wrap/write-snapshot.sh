#!/usr/bin/env bash
# ABOUTME: Writes wrap's session snapshot only when no string field looks like a key (known prefix, PEM block, long hex or base64 run).
# ABOUTME: Usage: write-snapshot.sh [--allow FIELD]... [--target PATH] < draft.json. Exit 0 written, 1 blocked, 2 bad usage or not JSON.
set -uo pipefail

target=".claude/turbocharge-session.json"
allowed=" "   # a space-padded string: an empty array under bash 3.2 and set -u fails
while [ $# -gt 0 ]; do
    case "$1" in
        --allow)  [ $# -ge 2 ] || { echo "write-snapshot: --allow needs a field name" >&2; exit 2; }
                  allowed="$allowed$2 "; shift 2 ;;
        --target) [ $# -ge 2 ] || { echo "write-snapshot: --target needs a path" >&2; exit 2; }
                  target="$2"; shift 2 ;;
        *) echo "usage: write-snapshot.sh [--allow FIELD]... [--target PATH] < draft.json" >&2; exit 2 ;;
    esac
done

draft="$(mktemp)" || exit 2
trap 'rm -f "$draft"' EXIT
cat > "$draft"

is_json() {
    grep -q '[^[:space:]]' "$draft" || return 1
    if command -v jq >/dev/null 2>&1; then jq -e 'type == "object"' "$draft" >/dev/null 2>&1; return; fi
    if command -v python3 >/dev/null 2>&1; then
        python3 -I -c 'import json,sys; assert isinstance(json.load(open(sys.argv[1])), dict)' "$draft" >/dev/null 2>&1
        return
    fi
    local flat; flat="$(tr -d '\n\r' < "$draft" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    case "$flat" in "{"*"}") return 0 ;; *) return 1 ;; esac
}
is_json || { echo "write-snapshot: the draft isn't JSON" >&2; exit 2; }

LC_ALL=C awk -v allow="$allowed" '
function inclass(c, cls) { return c ~ cls }
# does s hold prefix at the start of a word (risk-, task- and desk- hold sk- inside one) followed by at least min chars
# of cls, with a digit among them when digit is set?
function after(s, prefix, cls, min, digit,    p, at, rest, n, d, off) {
    off = 0
    while ((p = index(substr(s, off + 1), prefix)) > 0) {
        at = off + p
        if (at == 1 || substr(s, at - 1, 1) !~ /[A-Za-z0-9]/) {
            rest = substr(s, at + length(prefix)); n = 0; d = 0
            while (n < length(rest) && inclass(substr(rest, n + 1, 1), cls)) { if (substr(rest, n + 1, 1) ~ /[0-9]/) d = 1; n++ }
            if (n >= min && (d || !digit)) return 1
        }
        off = at
    }
    return 0
}
function longest_run(s, cls,    i, n, best) {
    n = 0; best = 0
    for (i = 1; i <= length(s); i++) {
        if (inclass(substr(s, i, 1), cls)) { n++; if (n > best) best = n } else n = 0
    }
    return best
}
function cclass(c) { return c ~ /[A-Z]/ ? "U" : c ~ /[a-z]/ ? "L" : c ~ /[0-9]/ ? "D" : "O" }
# a base64-looking run of 40+ whose letters and digits change class (upper, lower, digit) on at least 0.40 of their
# adjacent pairs. A pair that touches - _ / + = does not count, so hyphenated slugs and URL paths read as words.
function random_run(s,    i, c, prev, ch, pairs, len) {
    s = s " "; len = 0; ch = 0; pairs = 0; prev = ""
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c ~ /[A-Za-z0-9+\/=_-]/) {
            if (len > 0 && cclass(c) != "O" && cclass(prev) != "O") { pairs++; if (cclass(c) != cclass(prev)) ch++ }
            len++; prev = c
        } else {
            if (len >= 40 && pairs > 0 && ch / pairs >= 0.40) return 1
            len = 0; ch = 0; pairs = 0
        }
    }
    return 0
}
# blank out each 40-hex run that git resolves to a commit
function scrub(s,    i, c, n, out, run, cmd) {
    out = ""; run = ""
    s = s " "
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c ~ /[0-9a-fA-F]/) { run = run c; continue }
        if (length(run) == 40) {
            cmd = "git cat-file -e \047" run "^{commit}\047 >/dev/null 2>&1"
            if (system(cmd) == 0) run = sprintf("%40s", "")
        }
        out = out run c; run = ""
    }
    return substr(out, 1, length(out) - 1)
}
function rule_of(v,    w) {
    w = scrub(v)
    if (after(w, "sk-", "[A-Za-z0-9_-]", 16, 1)) return "sk- key"
    if (after(w, "AKIA", "[0-9A-Z]", 16)) return "AWS key"
    if (after(w, "ghp_", "[A-Za-z0-9]", 20) || after(w, "gho_", "[A-Za-z0-9]", 20) || after(w, "ghu_", "[A-Za-z0-9]", 20) \
        || after(w, "ghs_", "[A-Za-z0-9]", 20) || after(w, "ghr_", "[A-Za-z0-9]", 20) \
        || after(w, "github_pat_", "[A-Za-z0-9_]", 20)) return "GitHub token"
    if (after(w, "xoxa-", "[A-Za-z0-9-]", 10) || after(w, "xoxb-", "[A-Za-z0-9-]", 10) || after(w, "xoxp-", "[A-Za-z0-9-]", 10) \
        || after(w, "xoxr-", "[A-Za-z0-9-]", 10) || after(w, "xoxs-", "[A-Za-z0-9-]", 10)) return "Slack token"
    if (index(w, "-----BEGIN") > 0) return "PEM block"
    if (longest_run(w, "[0-9a-fA-F]") >= 32) return "long hex"
    if (random_run(w)) return "long base64"
    return ""
}
function finish_string(    r) {
    if (depth == 1 && expect_key) { key = buf; expect_key = 0; return }
    if (index(allow, " " key " ") > 0) return
    r = rule_of(buf)
    if (r != "") { print "write-snapshot: BLOCKED " key " (line " sline "): looks like " r > "/dev/stderr"; blocked = 1 }
}
{
    for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (instr) {
            if (c == "\\") { buf = buf c substr($0, i + 1, 1); i++ }
            else if (c == "\"") { instr = 0; finish_string() }
            else buf = buf c
            continue
        }
        if (c == "\"") { instr = 1; buf = ""; sline = NR }
        else if (c == "{") { depth++; if (depth == 1) expect_key = 1 }
        else if (c == "[") depth++
        else if (c == "}" || c == "]") depth--
        else if (c == "," && depth == 1) expect_key = 1
    }
}
END { exit blocked ? 1 : 0 }
' "$draft"
case $? in
    0) ;;
    1) echo "write-snapshot: nothing written. Replace each value with its name, file and sha256:<first 12 hex>, or rerun with --allow <field> if it isn't a key." >&2
       exit 1 ;;
    *) echo "write-snapshot: the key check failed to run" >&2; exit 2 ;;
esac

mkdir -p "$(dirname "$target")" || exit 2
cat "$draft" > "$target.tmp" && mv "$target.tmp" "$target"
