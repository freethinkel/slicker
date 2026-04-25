#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

targets=(
  "$HOME/.zshrc"
  "$HOME/.gitconfig"
  "$HOME/.config/nvim"
  "$HOME/.config/tmux"
  "$HOME/.config/ghostty"
  "$HOME/.config/starship.toml"
  "$HOME/.config/btop"
  "$HOME/.config/glide"
  "$HOME/.claude/skills"
  "$HOME/.claude/commands"
  "$HOME/.claude/agents"
  "$HOME/.claude/hooks"
  "$HOME/.claude/settings.json"
)

needs_backup=false
for target in "${targets[@]}"; do
  if [[ -e "$target" ]] && ! is_slicker_symlink "$target"; then
    needs_backup=true
    break
  fi
done

if ! $needs_backup; then
  ok "Nothing to back up."
  exit 0
fi

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
