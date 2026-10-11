#!/usr/bin/env bash
# Symlink apps/ and generated/ into $HOME. Existing files are moved to *.bak, never deleted.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

link() { # SRC DST
  local src="$1" dst="$2"
  [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]] && return 0
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    log "backed up ${dst/#$HOME/~}"
  fi
  ln -s "$src" "$dst"
  log "linked ${dst/#$HOME/~}"
}

dest() { # path relative to apps/ or generated/ -> path in $HOME
  local rel="$1"
  if [[ "${rel%%/*}" == home ]]; then echo "$HOME/${rel#home/}"; else echo "$HOME/.config/$rel"; fi
}

link_tree() { # apps | generated
  local tree="$1" f rel
  [[ -d "$ROOT/$tree" ]] || return 0
  while IFS= read -r -d '' f; do
    rel="${f#"$ROOT/$tree"/}"
    case "$rel" in
      firefox/*|.theme|*/.gitkeep) continue ;;   # firefox is copied by apply.sh
    esac
    link "$f" "$(dest "$rel")"
  done < <(find "$ROOT/$tree" -type f -print0)
}

link_tree apps
link_tree generated
link "$ROOT/bin/desktop" "$HOME/.local/bin/desktop"
log "done. Make sure ~/.local/bin is on your PATH."
