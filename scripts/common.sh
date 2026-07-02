#!/usr/bin/env bash
# ─── Slicker shared definitions ──────────────────────────────────────
# Sourced by all scripts. Expects nothing — resolves paths itself.

SLICKER_DIR="${SLICKER_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SLICKER_USER_DIR="$SLICKER_DIR/user"
SLICKER_THEME_DIR="$SLICKER_DIR/theme"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info() { echo -e "${BLUE}[slicker]${RESET} $*"; }
ok() { echo -e "${GREEN}[slicker]${RESET} $*"; }
warn() { echo -e "${YELLOW}[slicker]${RESET} $*"; }
err() { echo -e "${RED}[slicker]${RESET} $*" >&2; }

# True if $HOME/<rel> already resolves to the same file as the package
# source <file> — i.e. stow has linked it, directly or via a folded parent
# dir. readlink -f, not readlink: stow links are relative, and user/ content
# may itself symlink outside the repo.
is_stowed() {
  local rel="$1" file="$2"
  [[ "$(readlink -f "$HOME/$rel" 2>/dev/null || true)" == "$(readlink -f "$file")" ]]
}

# A dir is a stow package if it's non-empty and every top-level entry is a
# dot-entry (i.e. it mirrors $HOME layout: .config/, .claude/, .zshrc, …).
# Include-target dirs (user/zsh, user/git, …) hold plain-named files and fail this.
is_stow_pkg() {
  [[ -d "$1" ]] || return 1
  [[ -n "$(find "$1" -mindepth 1 -maxdepth 1 -print 2>/dev/null | head -1)" ]] || return 1
  [[ -z "$(find "$1" -mindepth 1 -maxdepth 1 ! -name '.*' -print | head -1)" ]]
}

# Echo the stow source dir (-d) for a package. A $HOME-shaped user/<name>/
# replaces configs/<name>/ wholesale (for tools without a native include).
pkg_src() {
  if is_stow_pkg "$SLICKER_USER_DIR/$1"; then
    echo "$SLICKER_USER_DIR"
  else
    echo "$SLICKER_DIR/configs"
  fi
}

# Emit each package name once: everything in configs/, plus any $HOME-shaped
# dir in user/ — those are auto-stowed without being listed anywhere.
stow_pkgs() {
  local d name
  for d in "$SLICKER_DIR"/configs/*/; do
    basename "$d"
  done
  for d in "$SLICKER_USER_DIR"/*/; do
    name="$(basename "$d")"
    [[ -d "$SLICKER_DIR/configs/$name" ]] && continue
    is_stow_pkg "$d" && echo "$name" || true
  done
}

# Stow every package into $HOME. Optional arg: extra stow flags (e.g. -R).
stow_all() {
  local flags="${1:-}" name src_dir
  while IFS= read -r name; do
    src_dir="$(pkg_src "$name")"
    if [[ "$src_dir" != "$SLICKER_DIR/configs" && -d "$SLICKER_DIR/configs/$name" ]]; then
      # Clean up a possibly-stale link from configs/ before switching sources.
      stow -D -t "$HOME" -d "$SLICKER_DIR/configs" "$name" 2>/dev/null || true
    fi
    stow -v $flags --ignore='\.DS_Store' -t "$HOME" -d "$src_dir" "$name" 2>&1 | while read -r line; do
      echo "  $line"
    done
  done < <(stow_pkgs)
}
