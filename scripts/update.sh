#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

info "Updating slicker (user/ is untouched)..."
cd "$SLICKER_DIR"

if git rev-parse --is-inside-work-tree &>/dev/null; then
  git pull --rebase
  ok "Pulled latest slicker."
else
  warn "Not a git repo — skipping pull."
fi

# Re-stow
info "Stowing configs into \$HOME..."
stow -v -t "$HOME" -d configs zsh git ghostty nvim tmux starship 2>&1 | while read -r line; do
  echo "  $line"
done
ok "Update complete."
