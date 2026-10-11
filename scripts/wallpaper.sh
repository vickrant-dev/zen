#!/usr/bin/env bash
# Wallpapers for the active theme, from themes/<name>/wallpapers/.
# Usage: wallpaper.sh next | prev | random | set <file> | apply
# Swaps seamlessly: the new swaybg starts on top, and the old one is removed after it has loaded.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

THEME="$(cat "$ROOT/generated/.theme" 2>/dev/null || true)"
[[ -n "$THEME" ]] || die "no active theme; run: desktop theme <name>"
DIR="$ROOT/themes/$THEME/wallpapers"
STATE="$ROOT/generated/.wallpaper"

mapfile -t WALLS < <(find "$DIR" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
(( ${#WALLS[@]} > 0 )) || die "no wallpapers in $DIR"
N=${#WALLS[@]}

# Current position: the saved wallpaper if it belongs to this theme, else the first one.
cur=0
if [[ -f "$STATE" ]]; then
  saved="$(cat "$STATE")"
  for i in "${!WALLS[@]}"; do
    [[ "${WALLS[$i]}" == "$saved" ]] && cur=$i
  done
fi

case "${1:-apply}" in
  next)   target="${WALLS[$(( (cur + 1) % N ))]}" ;;
  prev)   target="${WALLS[$(( (cur - 1 + N) % N ))]}" ;;
  random) target="${WALLS[$(( RANDOM % N ))]}" ;;
  set)    target="$DIR/${2:?usage: wallpaper.sh set <file>}"
          [[ -f "$target" ]] || die "no such wallpaper: $2" ;;
  apply)  target="${WALLS[$cur]}" ;;
  *)      die "usage: wallpaper.sh next | prev | random | set <file> | apply" ;;
esac

mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$target" > "$STATE"

command -v swaybg >/dev/null 2>&1 || die "swaybg is not installed: sudo pacman -S swaybg"

bg="$(sed -n 's/^BG=//p' "$ROOT/themes/$THEME/palette.env")"
mapfile -t old < <(pgrep -x swaybg)

# Start the new image on top. The old one keeps showing until the new one has loaded.
setsid swaybg -c "${bg:-#1e1e2e}" -i "$target" -m fill </dev/null >/dev/null 2>&1 &

if (( ${#old[@]} > 0 )); then
  sleep 0.8
  kill "${old[@]}" 2>/dev/null || true
fi

log "wallpaper: $(basename "$target")  [$THEME]"
