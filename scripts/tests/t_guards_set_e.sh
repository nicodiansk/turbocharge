#!/usr/bin/env bash
# ABOUTME: Asserts the git-grep guard tests survive `bash -e` when grep finds no match (exit 1).
# ABOUTME: A bare $(git grep ...) aborts under set -e on a clean tree; guards must append || true.
for g in t_no_old_repo_path.sh t_no_titlecase_brand.sh; do
    bash -e "$PLUGIN_DIR/scripts/tests/$g" >/dev/null 2>&1 \
        || { echo "    $g did not exit 0 under bash -e"; exit 1; }
done
exit 0
