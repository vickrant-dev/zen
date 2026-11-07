#!/usr/bin/env bash
# App launcher for rofi (script mode) with a web-search fallback.
# Apps come from XDG desktop entries; text that matches no app is searched in Chrome.
set -u

SELF="$(readlink -f "$0")"

# Fields printed by entry_fields, separated by the ASCII unit separator (\037):
# name, icon, terminal, exec, generic, keywords, tryexec, onlyshowin, notshowin
entry_fields() {
  awk '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^\[/ {
      if (in_entry) { in_entry = 0; done = 1 }
      else if (!done && $0 == "[Desktop Entry]") in_entry = 1
      next
    }
    done || !in_entry { next }
    /^[[:space:]]*#/ { next }
    {
      i = index($0, "=")
      if (!i) next
      k = trim(substr($0, 1, i - 1))
      v = substr($0, i + 1)
      sub(/\r$/, "", v)
      if (k ~ /\[/) next
      if      (k == "Type")        t  = v
      else if (k == "Name")        n  = v
      else if (k == "GenericName") g  = v
      else if (k == "Icon")        ic = v
      else if (k == "Exec")        x  = v
      else if (k == "Terminal")    tm = v
      else if (k == "Keywords")    kw = v
      else if (k == "NoDisplay")   nd = v
      else if (k == "Hidden")      hd = v
      else if (k == "TryExec")     te = v
      else if (k == "OnlyShowIn")  oi = v
      else if (k == "NotShowIn")   ni = v
    }
    END {
      if (t != "Application" || n == "" || nd == "true" || hd == "true") exit 1
      gsub(/[\t\n]/, " ", n)
      gsub(/[\t\n]/, " ", g)
      gsub(/[\t\n]/, " ", kw)
      printf "%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\n", n, ic, tm, x, g, kw, te, oi, ni
    }' "$1"
}

app_dirs() {
  local d base
  base="${XDG_DATA_HOME:-$HOME/.local/share}"
  printf '%s\n' "${base%/}/applications"
  IFS=: read -ra xdg <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  for d in "${xdg[@]}"; do
    [[ -n "$d" ]] && printf '%s\n' "${d%/}/applications"
  done
}

# Hide entries that are not meant for the current desktop.
visible_here() {
  local only="$1" not="$2" cur
  local desktops="${XDG_CURRENT_DESKTOP:-Hyprland}"
  if [[ -n "$only" ]]; then
    local found=0
    for cur in ${desktops//:/ }; do
      [[ ";$only;" == *";$cur;"* ]] && { found=1; break; }
    done
    (( found )) || return 1
  fi
  if [[ -n "$not" ]]; then
    for cur in ${desktops//:/ }; do
      [[ ";$not;" == *";$cur;"* ]] && return 1
    done
  fi
  return 0
}

list_apps() {
  printf '\0prompt\x1fApps\n'
  printf '\0no-custom\x1ffalse\n'
  printf '\0message\x1fNo match? Enter searches the web\n'

  declare -A seen=()
  local d f id line name icon term xcmd generic keywords tryexec only not
  while IFS= read -r d; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' f; do
      id="${f##*/}"
      [[ -n "${seen[$id]:-}" ]] && continue
      seen[$id]=1
      line="$(entry_fields "$f" 2>/dev/null)" || continue
      IFS=$'\x1f' read -r name icon term xcmd generic keywords tryexec only not <<< "$line"
      [[ -z "$name" ]] && continue
      visible_here "$only" "$not" || continue
      if [[ -n "$tryexec" ]] && ! command -v "$tryexec" >/dev/null 2>&1; then
        continue
      fi
      printf '%s' "$name"
      printf '\0info\x1f%s' "$f"
      [[ -n "$icon" ]] && printf '\x1ficon\x1f%s' "$icon"
      [[ -n "$generic$keywords" ]] && printf '\x1fmeta\x1f%s %s' "$generic" "$keywords"
      printf '\n'
    done < <(find "$d" -maxdepth 1 \( -type f -o -type l \) -name '*.desktop' -print0 2>/dev/null)
  done < <(app_dirs)
}

launch_app() {
  local f="${1:-}" line name icon term xcmd generic keywords tryexec only not
  [[ -n "$f" && -f "$f" ]] || return 0
  line="$(entry_fields "$f" 2>/dev/null)" || return 0
  IFS=$'\x1f' read -r name icon term xcmd generic keywords tryexec only not <<< "$line"

  if [[ "$term" == "true" ]]; then
    xcmd="$(printf '%s' "$xcmd" | sed -E 's/%[fFuUdDnNickvm]//g')"
    setsid kitty -e sh -c "$xcmd" >/dev/null 2>&1 &
  else
    setsid gio launch "$f" >/dev/null 2>&1 &
  fi
}

search_web() {
  local query="${1:-}" encoded="" c i
  [[ -n "$query" ]] || return 0
  local LC_ALL=C
  for ((i = 0; i < ${#query}; i++)); do
    c="${query:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) encoded+="$c" ;;
      *) printf -v c '%%%02X' "'$c"; encoded+="$c" ;;
    esac
  done
  local browser="google-chrome-stable"
  command -v "$browser" >/dev/null 2>&1 || browser="xdg-open"
  setsid "$browser" "https://www.google.com/search?q=$encoded" >/dev/null 2>&1 &
}

if [[ -n "${ROFI_RETV:-}" ]]; then
  case "${ROFI_RETV}" in
    0) list_apps ;;
    1) launch_app "${ROFI_INFO:-}" ;;
    2) search_web "${1:-}" ;;
  esac
  exit 0
fi

if [[ "${1:-}" == "--list" ]]; then
  list_apps
  exit 0
fi

exec rofi -show apps -modi "apps:$SELF"
