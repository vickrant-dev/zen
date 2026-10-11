#!/usr/bin/env bash
# Print keybinds from apps/hypr/keybinds.conf. --menu shows them in rofi.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

table() {
  awk '
    /^##/   { next }
    /^# /   { desc = substr($0, 3); next }
    /^bind/ {
      line = $0
      sub(/^bind[a-z]* = /, "", line)
      split(line, p, ", ")
      mods = p[1]; gsub(/\$mod/, "SUPER", mods); gsub(/ /, "+", mods)
      combo = (mods == "" ? p[2] : mods "+" p[2])
      printf "%-28s %s\n", combo, desc
      desc = ""
    }' "$ROOT/apps/hypr/keybinds.conf"
}

if [[ "${1:-}" == --menu ]]; then
  table | rofi -dmenu -i -no-custom -p "Keybinds" >/dev/null || true
else
  table
fi
