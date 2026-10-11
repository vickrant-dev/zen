#!/usr/bin/env bash
# Connectivity panel for rofi, in script mode.
# A background daemon keeps each view prepared, so opening the panel is instant.
# Actions run live and re-render in place.
#   desktop menu [root|wifi|bluetooth]   opens the panel
#   desktop menu daemon                  keeps the views prepared (started at login)
set -u

SELF="$(readlink -f "$0")"
CACHE="${XDG_RUNTIME_DIR:-/tmp}/desktop-menu"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a desktop "$1" "${2:-}" >/dev/null 2>&1
  return 0
}

# ---- rofi output -------------------------------------------------------------
header() {
  printf '\0prompt\x1f%s\n' "$1"
  printf '\0no-custom\x1ftrue\n'
  printf '\0keep-selection\x1ftrue\n'
}
row() { printf '%s\0info\x1f%s\n' "$1" "$2"; }

# ---- Wi-Fi -------------------------------------------------------------------
wifi_enabled() { [[ "$(nmcli radio wifi 2>/dev/null)" == enabled ]]; }

wifi_device() {
  nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'
}

wifi_view() {
  header "Wi-Fi"
  if ! wifi_enabled; then
    row "Turn Wi-Fi on" "wifi:toggle"
    row "Back" "view:root"
    return
  fi
  row "Turn Wi-Fi off" "wifi:toggle"
  row "Disconnect" "wifi:disconnect"
  row "Refresh" "wifi:refresh"
  row "Open nmtui" "wifi:nmtui"

  declare -A seen=()
  local inuse signal sec ssid rest mark lock line
  while IFS= read -r line; do
    # nmcli -t output: IN-USE:SIGNAL:SECURITY:SSID (SSID last, colons escaped as \:)
    inuse="${line%%:*}"; rest="${line#*:}"
    signal="${rest%%:*}"; rest="${rest#*:}"
    sec="${rest%%:*}"; ssid="${rest#*:}"
    ssid="${ssid//\\:/:}"
    [[ -z "$ssid" || -n "${seen[$ssid]:-}" ]] && continue
    seen[$ssid]=1
    mark=" "; [[ "$inuse" == "*" ]] && mark="*"
    lock=""; [[ -n "$sec" && "$sec" != "--" ]] && lock="secured"
    row "$(printf '%s  %-32s %3s%%  %s' "$mark" "$ssid" "$signal" "$lock")" "wifi:connect|$ssid"
  done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no 2>/dev/null)

  row "Back" "view:root"
}

wifi_toggle() {
  if wifi_enabled; then
    nmcli radio wifi off >/dev/null 2>&1
  else
    nmcli radio wifi on >/dev/null 2>&1
    for _ in 1 2 3 4 5 6 7 8 9 10; do wifi_enabled && break; sleep 0.3; done
    nmcli device wifi rescan >/dev/null 2>&1
    sleep 2
  fi
}

wifi_disconnect() {
  local dev
  dev="$(wifi_device)"
  if [[ -n "$dev" ]]; then nmcli device disconnect "$dev" >/dev/null 2>&1; fi
  return 0
}

# Connects to SSID. If that fails (usually a missing password), the password prompt
# opens after this panel closes, and the panel reopens when it's done.
wifi_connect() {
  local ssid="$1"
  if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
    notify "Wi-Fi" "Connected to $ssid"
    return 0
  fi
  env -u ROFI_RETV -u ROFI_INFO setsid "$SELF" askpass "$ssid" </dev/null >/dev/null 2>&1 &
  return 1
}

askpass() { # SSID. Runs outside rofi, then reopens the panel.
  local ssid="$1" pw
  sleep 0.6
  pw="$(rofi -dmenu -password -l 0 -p "Password for $ssid" </dev/null 2>/dev/null)" || pw=""
  if [[ -n "$pw" ]]; then
    if nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1; then
      notify "Wi-Fi" "Connected to $ssid"
    else
      notify "Wi-Fi" "Could not connect to $ssid"
    fi
  fi
  exec env -u ROFI_RETV -u ROFI_INFO "$SELF" wifi
}

# ---- Bluetooth ---------------------------------------------------------------
bt_powered() {
  [[ "$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')" == yes ]]
}

bt_view() {
  header "Bluetooth"
  if ! bt_powered; then
    row "Turn Bluetooth on" "bt:power"
    row "Back" "view:root"
    return
  fi
  row "Turn Bluetooth off" "bt:power"
  row "Scan for devices" "bt:scan"
  row "Refresh" "view:bt"

  local _ mac name tag
  while read -r _ mac name; do
    [[ -z "${mac:-}" ]] && continue
    tag=" "
    # timeout stops an out-of-range device from holding up the list
    timeout 1 bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && tag="*"
    row "$(printf '%s  %-30s %s' "$tag" "$name" "$mac")" "bt:device|$mac"
  done < <(bluetoothctl devices 2>/dev/null)

  row "Back" "view:root"
}

bt_power() {
  if bt_powered; then
    bluetoothctl power off >/dev/null 2>&1
  elif ! bluetoothctl power on >/dev/null 2>&1; then
    notify "Bluetooth" "Could not power on. Try: rfkill unblock bluetooth"
  fi
  return 0
}

# Scans for 12 seconds, then the list is redrawn with what was found.
bt_scan() {
  notify "Bluetooth" "Scanning for 12 seconds..."
  bluetoothctl --timeout 12 scan on </dev/null >/dev/null 2>&1
  notify "Bluetooth" "Scan complete"
}

bt_toggle() { # MAC
  local mac="$1"
  if timeout 2 bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$mac" >/dev/null 2>&1 && notify "Bluetooth" "Disconnected"
  elif bluetoothctl connect "$mac" >/dev/null 2>&1; then
    notify "Bluetooth" "Connected"
  elif bluetoothctl pair "$mac" >/dev/null 2>&1 \
       && bluetoothctl trust "$mac" >/dev/null 2>&1 \
       && bluetoothctl connect "$mac" >/dev/null 2>&1; then
    notify "Bluetooth" "Paired and connected"
  else
    notify "Bluetooth" "Could not connect. PIN devices must be paired with bluetoothctl."
  fi
  return 0
}

# ---- Root --------------------------------------------------------------------
root_view() {
  header "Connectivity"
  local w b
  w=off; wifi_enabled && w=on
  b=off; bt_powered && b=on
  row "Wi-Fi                 $w" "view:wifi"
  row "Bluetooth             $b" "view:bt"
}

render_view() { # root | wifi | bluetooth
  case "$1" in
    wifi)      wifi_view ;;
    bluetooth|bt) bt_view ;;
    *)         root_view ;;
  esac
}

# ---- Prepared views (daemon) -------------------------------------------------
write_cache() {
  mkdir -p "$CACHE"
  local v
  for v in root wifi bluetooth; do
    if render_view "$v" > "$CACHE/$v.tmp" 2>/dev/null; then
      mv -f "$CACHE/$v.tmp" "$CACHE/$v"
    fi
  done
}

daemon() {
  mkdir -p "$CACHE"
  exec 9>"$CACHE.lock"
  flock -n 9 || exit 0      # only one daemon at a time
  while true; do
    write_cache
    sleep 3
  done
}

# ---- Dispatch ----------------------------------------------------------------
dispatch() { # ACTION or ACTION|ARG
  local action="${1%%|*}" arg=""
  [[ "$1" == *"|"* ]] && arg="${1#*|}"
  case "$action" in
    view:root)       root_view ;;
    view:wifi)       wifi_view ;;
    view:bt)         bt_view ;;
    wifi:toggle)     wifi_toggle; wifi_view ;;
    wifi:disconnect) wifi_disconnect; wifi_view ;;
    wifi:refresh)
      nmcli device wifi rescan >/dev/null 2>&1
      sleep 1.5
      wifi_view ;;
    wifi:nmtui)
      kitty -e nmtui >/dev/null 2>&1 &
      ;;
    wifi:connect)    wifi_connect "$arg" && wifi_view ;;
    bt:power)        bt_power; bt_view ;;
    bt:scan)         bt_scan; bt_view ;;
    bt:device)       bt_toggle "$arg"; bt_view ;;
    *)               root_view ;;
  esac
}

# ---- Entry -------------------------------------------------------------------
if [[ -n "${ROFI_RETV:-}" ]]; then
  # Called by rofi. A selection sets ROFI_INFO. The first render has none.
  if [[ -n "${ROFI_INFO:-}" ]]; then
    dispatch "$ROFI_INFO"
  else
    v="${MENU_START:-root}"
    if [[ -s "$CACHE/$v" ]]; then
      cat "$CACHE/$v"            # instant: prepared by the daemon
    else
      render_view "$v"           # fallback before the daemon has run
    fi
  fi
  exit 0
fi

case "${1:-}" in
  askpass) askpass "${2:-}" ;;
  daemon)  daemon ;;
  *)
    export MENU_START="${1:-root}"
    exec rofi -show connectivity -modi "connectivity:$SELF"
    ;;
esac
