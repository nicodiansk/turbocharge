#!/usr/bin/env bash
# ABOUTME: Filters a shipped markdown file (stdin) into the directory copy (stdout): drops `<!-- repo-only -->` …
# ABOUTME: `<!-- /repo-only -->` blocks, un-comments `<!-- directory-only` … `-->` blocks, folds the blank runs left behind.
# Usage: directory-filter.sh < README.md > release-README.md
set -euo pipefail

awk '
    { sub(/\r$/, "") }
    $0 == "<!-- repo-only -->" || $0 == "<!-- directory-only" {
        if (skip || emit) { err = "a block opens inside another at line " NR; exit }
        if ($0 == "<!-- repo-only -->") skip = 1; else emit = 1
        start = NR; next
    }
    $0 == "<!-- /repo-only -->" {
        if (!skip) { err = "a repo-only block closes without opening at line " NR; exit }
        skip = 0; next
    }
    emit && $0 == "-->" { emit = 0; next }
    emit && index($0, "-->") { err = "a directory-only block holds --> at line " NR " (it would end the comment on GitHub)"; exit }
    skip { next }
    /^[[:space:]]*$/ { blank = 1; next }
    { if (blank && printed) print ""; blank = 0; print; printed = 1 }
    END {
        if (!err && (skip || emit)) err = "the block opened at line " start " never closes"
        if (err) { print "directory-filter.sh: " err > "/dev/stderr"; exit 1 }
    }
'
