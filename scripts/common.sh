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

# Expand ${VAR} references in a template file using current env
render_template() {
  local template="$1"
  eval "cat <<SLICKER_TPL_EOF
$(cat "$template")
SLICKER_TPL_EOF"
}

# Check if a path is a symlink pointing into slicker's configs/
is_slicker_symlink() {
  local path="$1"
  if [[ -L "$path" ]]; then
    local target
    target="$(readlink "$path" 2>/dev/null || true)"
    [[ "$target" == *"$SLICKER_DIR/configs/"* ]]
  else
    return 1
  fi
}
