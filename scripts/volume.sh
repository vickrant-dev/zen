#!/usr/bin/env bash
# Volume panel for rofi: a 10-segment bar. Click a level to set it. Stays open and updates.
# rofi runs this script again on each selection; the printed list is what rofi shows.
set -u

SELF="$(readlink -f "$0")"
SINK="@DEFAULT_AUDIO_SINK@"

# Current level as a percentage, and whether it's muted
state() {
  local out vol muted=no
  out="$(wpctl get-volume "$SINK" 2>/dev/null)"
  vol="$(awk '{print $2}' <<<"$out")"
  [[ "$out" == *MUTED* ]] && muted=yes
  awk -v v="${vol:-0}" 'BEGIN{printf "%d", v*100+0.5}'
  echo " $muted"
}

view() {
  local pct muted cur L i filled bar mark prompt
  read -r pct muted <<<"$(state)"
  prompt="Volume ${pct}%"
  [[ "$muted" == yes ]] && prompt="$prompt  (muted)"
  cur=$(( (pct + 5) / 10 * 10 ))

  printf '\0prompt\x1f%s\n' "$prompt"
  printf '\0no-custom\x1ftrue\n'
  printf '\0keep-selection\x1ftrue\n'

  for L in 10 20 30 40 50 60 70 80 90 100; do
    filled=$(( L / 10 )); bar=""
    for (( i = 1; i <= 10; i++ )); do
      if (( i <= filled )); then bar+="█"; else bar+="░"; fi
    done
    mark=""
    (( L == cur )) && mark="   <- current"
    printf '%s  %3d%%%s\0info\x1fset|%d\n' "$bar" "$L" "$mark" "$L"
  done

  if [[ "$muted" == yes ]]; then
    printf 'Unmute\0info\x1fmute\n'
  else
    printf 'Mute\0info\x1fmute\n'
  fi
}

dispatch() { # set|LEVEL or mute
  local action="${1%%|*}" arg="${1#*|}"
  case "$action" in
    set)
      wpctl set-mute "$SINK" 0 >/dev/null 2>&1
      wpctl set-volume -l 1.0 "$SINK" "$(awk -v p="$arg" 'BEGIN{printf "%.2f", p/100}')" >/dev/null 2>&1
      ;;
    mute)
      wpctl set-mute "$SINK" toggle >/dev/null 2>&1
      ;;
  esac
  view
}

if [[ -n "${ROFI_RETV:-}" ]]; then
  if [[ -n "${ROFI_INFO:-}" ]]; then dispatch "$ROFI_INFO"; else view; fi
  exit 0
fi

exec rofi -show volume -modi "volume:$SELF"
