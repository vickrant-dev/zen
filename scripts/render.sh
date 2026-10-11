#!/usr/bin/env bash
# Render one theme's templates into generated/. Apps that aren't installed are skipped.
# FORCE=1 renders every template regardless (for testing).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

THEME="${1:?usage: render.sh <theme>}"
THEME_DIR="$ROOT/themes/$THEME"
[[ -d "$THEME_DIR" ]] || die "no such theme: $THEME"

VARS=()
define() { # NAME VALUE: export for envsubst and remember the name
  printf -v "$1" '%s' "$2"
  export "$1"
  VARS+=("\${$1}")
}

read_env() { # FILE KIND (color|value). Parsed, never sourced.
  local file="$1" kind="$2" key val h r g b
  while IFS='=' read -r key val || [[ -n "$key" ]]; do
    key="${key//[[:space:]]/}"
    [[ -z "$key" || "$key" == \#* ]] && continue
    val="$(printf '%s' "$val" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    if [[ "$kind" == color ]]; then
      [[ "$val" =~ ^#?[0-9a-fA-F]{6}$ ]] || die "$file: $key is not a hex color: '$val'"
      h="${val#\#}"
      r=$((16#${h:0:2})); g=$((16#${h:2:2})); b=$((16#${h:4:2}))
      define "$key"          "#$h"
      define "${key}_RGB"    "$r,$g,$b"
      define "${key}_RGBA85" "rgba($r,$g,$b,0.85)"
      define "${key}_RGBA93" "rgba($r,$g,$b,0.93)"
    else
      define "$key" "$val"
    fi
  done < "$file"
}

read_env "$THEME_DIR/palette.env" color
read_env "$THEME_DIR/theme.env" value

FORMAT=""
for v in "${VARS[@]}"; do FORMAT+="$v "; done

available() { # APP -> 0 if this app should be themed on this machine
  local app="$1" req cmd
  [[ -n "${FORCE:-}" ]] && return 0
  req="$ROOT/templates/$app/requires"
  if [[ -f "$req" ]]; then
    while read -r cmd; do
      [[ -z "$cmd" ]] && continue
      command -v "$cmd" >/dev/null 2>&1 || return 1
    done < "$req"
  fi
  if [[ "$app" == gtk-3.0 ]]; then
    [[ -d "/usr/share/themes/$GTK_THEME" || -d "$HOME/.themes/$GTK_THEME" ]] || return 1
  fi
  return 0
}

rendered=0
for tdir in "$ROOT"/templates/*/; do
  tdir="${tdir%/}"
  app="$(basename "$tdir")"
  if ! available "$app"; then
    log "skip $app (not installed or GTK theme missing)"
    continue
  fi
  while IFS= read -r tmpl; do
    rel="${tmpl#"$tdir"/}"
    out="$ROOT/generated/$app/${rel%.tmpl}"
    mkdir -p "$(dirname "$out")"
    tmp="$(mktemp)"
    envsubst "$FORMAT" < "$tmpl" > "$tmp"
    leftover="$(grep -Eo '\$\{[A-Z][A-Z0-9_]*\}' "$tmp" | sort -u | tr '\n' ' ' || true)"
    if [[ -n "$leftover" ]]; then
      rm -f "$tmp"
      die "$tmpl: unknown token(s): $leftover"
    fi
    chmod 644 "$tmp"
    mv "$tmp" "$out"
    rendered=$((rendered + 1))
  done < <(find "$tdir" -type f -name '*.tmpl' | sort)
done

printf '%s\n' "$THEME" > "$ROOT/generated/.theme"
log "rendered $rendered file(s) from $THEME"
