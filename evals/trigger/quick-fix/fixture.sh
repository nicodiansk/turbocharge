#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"
cat > README.md <<'MD'
# notes-sync

Syncs your notes between machines.

## Usage

Run `notes-sync pull` to recieve the latest notes from the server.
MD
git add -A
git commit -q -m "docs: add README"
