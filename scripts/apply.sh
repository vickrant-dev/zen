#!/usr/bin/env bash
# Render a theme, relink, set its wallpaper, copy Firefox CSS, then reload running apps.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

THEME="${1:?usage: apply.sh <theme>}"
"$ROOT/scripts/render.sh" "$THEME"
"$ROOT/scripts/install.sh" >/dev/null

css="$ROOT/generated/firefox/userChrome.css"
if [[ -f "$css" ]]; then
  for prof in "$HOME"/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default* \
              "$HOME"/.mozilla/firefox/*.default*; do
    [[ -d "$prof" ]] || continue
    mkdir -p "$prof/chrome"
    cp "$css" "$prof/chrome/userChrome.css"
    log "firefox: $prof"
  done
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null && log "hyprland reloaded"
fi
if pgrep -x waybar >/dev/null 2>&1; then pkill -SIGUSR2 -x waybar; log "waybar reloaded"; fi
if command -v makoctl >/dev/null 2>&1; then makoctl reload >/dev/null 2>&1 || true; log "mako reloaded"; fi
if pgrep -x kitty >/dev/null 2>&1; then pkill -USR1 -x kitty; log "kitty reloaded"; fi

"$ROOT/scripts/wallpaper.sh" apply || log "no wallpapers yet for $THEME"

log "theme applied: $THEME"
