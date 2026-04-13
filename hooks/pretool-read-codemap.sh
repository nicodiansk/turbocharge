#!/usr/bin/env bash
# ABOUTME: PreToolUse hook for Read — nudges codemap usage when .codemap/ index exists.
# ABOUTME: Non-blocking: outputs reminder but does not prevent the Read.

set -e

# .codemap/ in working directory means the project has a codemap index
if [ -d ".codemap" ]; then
    echo ".codemap/ index found. Before reading full files, try \`codemap find \"SymbolName\"\` or \`codemap show path/to/file\` to locate the exact line range you need — then read only that range."
fi
