#!/usr/bin/env bash
# ABOUTME: Asserts the plugin ships no settings.json: it was empty (permissions {}, env {}), Chat and Cowork ignore
# ABOUTME: plugin settings, and the directory flagged it as MODIFIES_SETTINGS. Docs and validate.sh must not expect it.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
rc=0
[ ! -f "$PLUGIN_DIR/settings.json" ] || { echo "    plugin root still ships settings.json"; rc=1; }
grep -qE 'for f in .*[[:space:]]settings\.json[[:space:]]' "$PLUGIN_DIR/scripts/validate.sh" \
    && { echo "    validate.sh still requires settings.json"; rc=1; }
grep -qF 'settings.json   →' "$PLUGIN_DIR/.claude/CLAUDE.md" && { echo "    CLAUDE.md architecture still lists settings.json"; rc=1; }
grep -qF '| `settings.json` |' "$PLUGIN_DIR/.claude/CLAUDE.md" && { echo "    CLAUDE.md file types still list settings.json"; rc=1; }
grep -qF '├── settings.json' "$PLUGIN_DIR/README.md" && { echo "    README project tree still lists settings.json"; rc=1; }
exit $rc
