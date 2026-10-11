#!/usr/bin/env bash
# Check tools and look for dangling symlinks left by this repo.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "Tools:"
for c in envsubst hyprctl waybar mako rofi kitty nvim thunar lf firefox; do
  if command -v "$c" >/dev/null 2>&1; then echo "  ok    $c"; else echo "  miss  $c"; fi
done

echo; echo "Current theme: $(cat "$ROOT/generated/.theme" 2>/dev/null || echo none)"

echo; echo "Broken links:"
find "$HOME/.config" "$HOME/.local/bin" "$HOME" -maxdepth 1 -xtype l 2>/dev/null | head -20 || true
