#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

skip_user=false
for arg in "$@"; do
  case "$arg" in
  --skip-user) skip_user=true ;;
  esac
done

info "Updating slicker..."
cd "$SLICKER_DIR"

# Pull latest
if git rev-parse --is-inside-work-tree &>/dev/null; then
  if git pull --rebase 2>&1 | while read -r line; do echo "  $line"; done; then
    ok "Pulled latest slicker."
  else
    warn "git pull failed (see above). Continuing..."
  fi
else
  warn "Not a git repo — skipping pull."
fi

# Sync missing user dirs from user.example
if ! $skip_user && [[ -d "$SLICKER_USER_DIR" ]]; then
  for dir in "$SLICKER_DIR"/user.example/*/; do
    name="$(basename "$dir")"
    if [[ ! -d "$SLICKER_USER_DIR/$name" ]]; then
      info "New config found: $name — copying from user.example/"
      cp -r "$dir" "$SLICKER_USER_DIR/$name"
      ok "Created user/$name."
    fi
  done
fi

# Re-stow
info "Re-stowing configs into \$HOME..."

# See install.sh — same override mechanism.
stow_override=(glide zellij)

for pkg_dir in "$SLICKER_DIR"/configs/*/; do
  name="$(basename "$pkg_dir")"
  src_dir="$SLICKER_DIR/configs"
  for override in "${stow_override[@]}"; do
    if [[ "$name" == "$override" && -d "$SLICKER_USER_DIR/$name" ]]; then
      # Clean up a possibly-stale link from configs/ before switching sources.
      stow -D -t "$HOME" -d "$SLICKER_DIR/configs" "$name" 2>/dev/null || true
      src_dir="$SLICKER_USER_DIR"
      break
    fi
  done
  stow -v -R -t "$HOME" -d "$src_dir" "$name" 2>&1 | while read -r line; do
    echo "  $line"
  done
done
ok "Update complete."
