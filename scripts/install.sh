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
  ok "User config found at $SLICKER_USER_DIR"
elif [[ -n "${SLICKER_USER_REPO:-}" ]]; then
  info "Cloning user repo from $SLICKER_USER_REPO..."
  git clone "$SLICKER_USER_REPO" "$SLICKER_USER_DIR"
  ok "User repo cloned."
else
  info "No user config found. Copying template..."
  cp -r "$SLICKER_DIR/user.example" "$SLICKER_USER_DIR"
  warn "Created $SLICKER_USER_DIR from template."
  warn "Edit it, then optionally make it a git repo:"
  echo ""
  echo "  cd $SLICKER_USER_DIR"
  echo "  git init && git add -A && git commit -m 'init'"
  echo ""
fi

# User symlink
if [[ -L "$SLICKER_USER_LINK" ]]; then
  ok "user/ symlink exists."
elif [[ -e "$SLICKER_USER_LINK" ]]; then
  err "user/ exists but is not a symlink. Remove it and re-run."
  exit 1
else
  ln -s "$SLICKER_USER_DIR" "$SLICKER_USER_LINK"
  ok "Created symlink: user/ → $SLICKER_USER_DIR"
fi

# Source meta.sh if available
if [[ -f "$SLICKER_USER_DIR/meta.sh" ]]; then
  info "Sourcing user/meta.sh..."
  source "$SLICKER_USER_DIR/meta.sh"
  ok "MACHINE=${MACHINE:-unset}"
fi

# Backup existing configs
targets=(
  "$HOME/.zshrc"
  "$HOME/.gitconfig"
  "$HOME/.config/nvim"
  "$HOME/.config/tmux"
  "$HOME/.config/ghostty"
)

needs_backup=false
for target in "${targets[@]}"; do
  if [[ -e "$target" ]] && ! is_slicker_symlink "$target"; then
    needs_backup=true
    break
  fi
done

if $needs_backup; then
  backup_dir="$SLICKER_DIR/backups/$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$backup_dir"
  info "Backing up existing configs to ${backup_dir#$SLICKER_DIR/}/"

  for target in "${targets[@]}"; do
    if [[ -e "$target" ]] && ! is_slicker_symlink "$target"; then
      rel="${target#$HOME/}"
      dest="$backup_dir/$rel"
      mkdir -p "$(dirname "$dest")"
      mv "$target" "$dest"
      echo "  $rel → ${backup_dir#$SLICKER_DIR/}/$rel"
    fi
  done
  ok "Backup complete."
fi

# Stow
info "Stowing configs into \$HOME..."
cd "$SLICKER_DIR"
stow -v -t "$HOME" -d configs zsh git ghostty nvim tmux 2>&1 | while read -r line; do
  echo "  $line"
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

echo ""
ok "Slicker install complete!"
