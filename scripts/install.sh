#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

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
"$SLICKER_DIR/scripts/backup.sh"

# Stow
info "Stowing configs into \$HOME..."
cd "$SLICKER_DIR"

# Configs that support full replacement from user/ (for tools without a
# native include mechanism). If user/<name>/ exists, stow it instead of
# configs/<name>/.
stow_override=(glide zellij)

for pkg_dir in configs/*/; do
  name="$(basename "$pkg_dir")"
  src_dir="configs"
  for override in "${stow_override[@]}"; do
    if [[ "$name" == "$override" && -d "$SLICKER_USER_DIR/$name" ]]; then
      src_dir="$SLICKER_USER_DIR"
      break
    fi
  done
  stow -v -t "$HOME" -d "$src_dir" "$name" 2>&1 | while read -r line; do
    echo "  $line"
  done
done
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
