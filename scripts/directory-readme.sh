#!/usr/bin/env bash
# ABOUTME: Filters README.md (stdin) into the directory copy's README (stdout): drops every line from a
# ABOUTME: `<!-- repo-only -->` line through its `<!-- /repo-only -->` line, and folds the blank runs left behind.
# Usage: directory-readme.sh < README.md > release-README.md
set -euo pipefail

awk '
    { sub(/\r$/, "") }
    $0 == "<!-- repo-only -->" {
        if (skip) { err = "a repo-only block opens inside another at line " NR; exit }
        skip = 1; start = NR; next
    }
    $0 == "<!-- /repo-only -->" {
        if (!skip) { err = "a repo-only block closes without opening at line " NR; exit }
        skip = 0; next
    }
    skip { next }
    /^[[:space:]]*$/ { blank = 1; next }
    { if (blank && printed) print ""; blank = 0; print; printed = 1 }
    END {
        if (!err && skip) err = "the repo-only block opened at line " start " never closes"
        if (err) { print "directory-readme.sh: " err > "/dev/stderr"; exit 1 }
    }
'
