#!/usr/bin/env bash
# ABOUTME: Asserts the plugin icon meets the directory's rules: .claude-plugin/icon.png, a real PNG, square,
# ABOUTME: 512–2048 px per side, under 2 MB (SVG/WebP are rejected). Reads the PNG IHDR with od, no image tools.
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
I="$PLUGIN_DIR/.claude-plugin/icon.png"
assert_file "$I" || exit 1
MAGIC=$(od -An -tx1 -N8 "$I" | tr -d ' \n')
[ "$MAGIC" = "89504e470d0a1a0a" ] || { echo "    icon.png is not a PNG (magic $MAGIC)"; exit 1; }
read -r W H < <(od -An -tu1 -j16 -N8 "$I" | awk '{print $1*16777216+$2*65536+$3*256+$4, $5*16777216+$6*65536+$7*256+$8}')
[ "$W" = "$H" ] || { echo "    icon.png is ${W}x${H}, must be square"; exit 1; }
[ "$W" -ge 512 ] && [ "$W" -le 2048 ] || { echo "    icon.png is ${W}px, must be 512–2048"; exit 1; }
SIZE=$(wc -c < "$I" | tr -d ' ')
[ "$SIZE" -lt 2097152 ] || { echo "    icon.png is $SIZE bytes, must be under 2 MB"; exit 1; }
exit 0
