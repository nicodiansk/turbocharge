#!/usr/bin/env bash
# ABOUTME: Asserts NOTICE carries the MIT notice of the project that parts of debug, ship and plan come from, lists each of
# ABOUTME: those files (all of which exist), ships in the directory copy (release.sh SHIPPED), and the README points to it.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
F="$PLUGIN_DIR/NOTICE"
assert_file "$F" || exit 1
rc=0
for p in 'MIT License' 'Permission is hereby granted, free of charge' 'THE SOFTWARE IS PROVIDED "AS IS"' 'https://github.com/'; do
    grep -qF -- "$p" "$F" || { echo "    NOTICE missing: $p"; rc=1; }
done
# The upstream copyright line, not this project's.
OURS="$(grep -m1 '^Copyright (c)' "$PLUGIN_DIR/LICENSE")"
grep '^Copyright (c) [0-9]' "$F" | grep -qvxF -- "$OURS" || { echo "    NOTICE has no upstream copyright line"; rc=1; }
for f in skills/debug/SKILL.md skills/debug/root-cause-tracing.md skills/debug/defense-in-depth.md \
    skills/debug/condition-based-waiting.md skills/debug/condition-based-waiting-example.ts skills/debug/find-polluter.sh \
    skills/ship/SKILL.md skills/plan/SKILL.md; do
    grep -qF -- "$f" "$F" || { echo "    NOTICE doesn't list $f"; rc=1; }
done
for f in $(grep -oE '(skills|agents|hooks|templates)/[A-Za-z0-9._/-]+' "$F"); do
    [ -f "$PLUGIN_DIR/$f" ] || { echo "    NOTICE lists a file that doesn't exist: $f"; rc=1; }
done
grep '^SHIPPED=(' "$PLUGIN_DIR/scripts/release.sh" | grep -qw NOTICE || { echo "    release.sh SHIPPED leaves out NOTICE"; rc=1; }
awk '/^## License/{f=1; next} f && /^## /{exit} f' "$PLUGIN_DIR/README.md" | grep -qF '[NOTICE](NOTICE)' \
    || { echo "    README's License section doesn't point to NOTICE"; rc=1; }
exit $rc
