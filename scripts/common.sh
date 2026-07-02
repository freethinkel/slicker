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

# Configs replaced wholesale from user/ (tools without a native include
# mechanism). If user/<name>/ exists, it is stowed instead of configs/<name>/.
STOW_OVERRIDE=(omniwm zellij tmuxinator herdr)

# Echo the stow source dir (-d) for a package, honoring user/ overrides.
pkg_src() {
  local name="$1" override
  for override in "${STOW_OVERRIDE[@]}"; do
    if [[ "$name" == "$override" && -d "$SLICKER_USER_DIR/$name" ]]; then
      echo "$SLICKER_USER_DIR"
      return
    fi
  done
  echo "$SLICKER_DIR/configs"
}

# Stow every package in configs/ into $HOME. Optional arg: extra stow flags (e.g. -R).
stow_all() {
  local flags="${1:-}" pkg_dir name src_dir
  for pkg_dir in "$SLICKER_DIR"/configs/*/; do
    name="$(basename "$pkg_dir")"
    src_dir="$(pkg_src "$name")"
    if [[ "$src_dir" != "$SLICKER_DIR/configs" ]]; then
      # Clean up a possibly-stale link from configs/ before switching sources.
      stow -D -t "$HOME" -d "$SLICKER_DIR/configs" "$name" 2>/dev/null || true
    fi
    stow -v $flags -t "$HOME" -d "$src_dir" "$name" 2>&1 | while read -r line; do
      echo "  $line"
    done
  done
}
