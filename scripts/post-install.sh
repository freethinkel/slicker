#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

info "Running post-install tasks..."
echo ""

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
