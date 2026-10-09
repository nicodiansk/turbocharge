#!/usr/bin/env bash
# ABOUTME: Shared assertion helpers for content-shape tests.
# ABOUTME: Sourced by every t_*.sh; provides assert_grep, assert_no_grep, assert_file, assert_jq, frontmatter.
assert_file()      { [ -f "$1" ] || { echo "    missing file: $1"; return 1; }; }
assert_grep()      { grep -q "$2" "$1" || { echo "    missing pattern '$2' in $1"; return 1; }; }
assert_no_grep()   { ! grep -q "$2" "$1" || { echo "    forbidden pattern '$2' still in $1"; return 1; }; }
assert_jq()        { command -v jq >/dev/null 2>&1 || { echo "    jq not installed, skipping"; return 0; }; jq -e "$2" "$1" >/dev/null || { echo "    jq query '$2' failed on $1"; return 1; }; }
# Print the YAML frontmatter body of a markdown file (CRLF-safe; the working tree may be CRLF).
frontmatter()      { awk '{ sub(/\r$/, "") } NR==1 && $0=="---" { f=1; next } f && $0=="---" { exit } f' "$1"; }
