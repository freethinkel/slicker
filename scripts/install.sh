#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

skip_backup=0
for arg in "$@"; do
  case "$arg" in
    --skip-backup) skip_backup=1 ;;
    *) err "Unknown option: $arg"; exit 1 ;;
  esac
done

info "Starting full install..."
echo ""

# Homebrew
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "Homebrew installed."
else
  ok "Homebrew found."
fi

# Stow
if ! command -v stow &>/dev/null; then
  info "Installing stow via Homebrew..."
  brew install stow
  ok "stow installed."
else
  ok "stow found."
fi

# User config directory
if [[ -d "$SLICKER_USER_DIR" ]]; then
  ok "User config found."
else
  info "Copying user template..."
  cp -r "$SLICKER_DIR/user.example" "$SLICKER_USER_DIR"
  ok "Created user/ from template."
fi

# Source meta.sh if available
if [[ -f "$SLICKER_USER_DIR/meta.sh" ]]; then
  info "Sourcing user/meta.sh..."
  source "$SLICKER_USER_DIR/meta.sh"
  ok "MACHINE=${MACHINE:-unset}"
fi

# Backup existing configs
if [[ "$skip_backup" -eq 1 ]]; then
  info "Skipping backup (--skip-backup)."
else
  "$SLICKER_DIR/scripts/backup.sh"
fi

# Stow
info "Stowing configs into \$HOME..."
stow_all
ok "Configs stowed."

# Brewfiles
if [[ -f "$SLICKER_DIR/Brewfile" ]]; then
  info "Running brew bundle from base Brewfile..."
  brew bundle --file="$SLICKER_DIR/Brewfile"
  ok "Base brew bundle complete."
fi

if [[ -f "$SLICKER_USER_DIR/Brewfile" ]]; then
  info "Running brew bundle from user/Brewfile..."
  brew bundle --file="$SLICKER_USER_DIR/Brewfile"
  ok "User brew bundle complete."
fi

# Post-install tasks (sudoers, etc.)
"$SLICKER_DIR/scripts/post-install.sh"

echo ""
ok "Slicker install complete!"
