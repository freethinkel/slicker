#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

info "Running post-install tasks..."
echo ""

# yabai scripting addition sudoers (passwordless sudo for --load-sa)
if command -v yabai &>/dev/null; then
  yabai_path="$(which yabai)"
  yabai_hash="$(shasum -a 256 "$yabai_path" | cut -d' ' -f1)"
  sudoers_line="$(whoami) ALL=(root) NOPASSWD: sha256:${yabai_hash} ${yabai_path} --load-sa"
  sudoers_file="/private/etc/sudoers.d/yabai"

  if [[ -f "$sudoers_file" ]] && grep -qF "$yabai_hash" "$sudoers_file" 2>/dev/null; then
    ok "yabai sudoers already up to date."
  else
    info "Configuring passwordless sudo for yabai --load-sa..."
    echo "$sudoers_line" | sudo tee "$sudoers_file" >/dev/null
    ok "yabai sudoers configured."
  fi
else
  warn "yabai not found, skipping sudoers setup."
fi

# Raycast extension
raycast_ext="$SLICKER_DIR/extras/raycast/slicker-theme"
raycast_tmp="/tmp/slicker-raycast-ext"
if [[ -d "$raycast_ext" ]] && command -v npm &>/dev/null; then
  info "Installing Raycast extension..."
  rm -rf "$raycast_tmp"
  cp -r "$raycast_ext" "$raycast_tmp"
  npm --prefix "$raycast_tmp" install --silent 2>/dev/null
  (cd "$raycast_tmp" && node node_modules/@raycast/api/bin/run.js develop &>/dev/null &)
  ok "Raycast extension installed."
fi

echo ""
ok "Post-install complete!"
