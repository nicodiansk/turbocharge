#!/usr/bin/env bash
# ABOUTME: Asserts no script that sets pipefail pipes into `head`: head exits early, the writer dies of SIGPIPE
# ABOUTME: (sed exit 4), pipefail propagates it and set -e kills the script. Linux CI hit this; Windows timing hid it.
# ABOUTME: A heuristic: it only catches `| head`, and it also matches comments, where a hit is a false alarm to reword.
rc=0
while IFS= read -r f; do
    p="$PLUGIN_DIR/$f"
    grep -q 'pipefail' "$p" || continue
    if grep -nE '\|[[:space:]]*head([[:space:]]|$)' "$p"; then
        echo "    $f pipes into head under pipefail (SIGPIPE kills the script); use sed -n '1,Np' or awk"
        rc=1
    fi
done < <(git -C "$PLUGIN_DIR" ls-files '*.sh')
exit $rc
