#!/usr/bin/env bash
# ABOUTME: Asserts no script that sets pipefail pipes into `head`: head exits early, the writer dies of SIGPIPE
# ABOUTME: (sed exit 4), pipefail propagates it and set -e kills the script. Linux CI hit this; Windows timing hid it.
rc=0
for f in $(git -C "$PLUGIN_DIR" ls-files '*.sh'); do
    p="$PLUGIN_DIR/$f"
    grep -q 'pipefail' "$p" || continue
    if grep -nE '\|[[:space:]]*head([[:space:]]|$)' "$p"; then
        echo "    $f pipes into head under pipefail (SIGPIPE kills the script); use sed -n '1,Np' or awk"
        rc=1
    fi
done
exit $rc
