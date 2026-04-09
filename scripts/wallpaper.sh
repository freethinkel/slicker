#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

WALLPAPER_INDEX="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"

resolve_path() {
  python3 - <<'PY' "$1"
import pathlib, sys
print(pathlib.Path(sys.argv[1]).expanduser().resolve())
PY
}

set_with_desktoppr() {
  /usr/local/bin/desktoppr all "$1" >/dev/null 2>&1
}

set_with_finder() {
  /usr/bin/osascript - "$1" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  set imagePath to POSIX file (item 1 of argv)
  tell application "Finder"
    set desktop picture to imagePath
  end tell
end run
APPLESCRIPT
}

set_with_system_events() {
  /usr/bin/osascript - "$1" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  set imagePath to POSIX file (item 1 of argv)
  tell application "System Events"
    repeat with d in desktops
      set picture of d to imagePath
    end repeat
  end tell
end run
APPLESCRIPT
}

set_with_wallpaper_store() {
  python3 - <<PY "$WALLPAPER_INDEX" "$1"
import datetime as dt
import plistlib
import sys
import time
from pathlib import Path

index_path = Path(sys.argv[1]).expanduser()
image_path = Path(sys.argv[2]).expanduser().resolve()

if not index_path.is_file():
    raise SystemExit(1)

raw = index_path.read_bytes()
root = plistlib.loads(raw)
now = dt.datetime.now()
uri = image_path.as_uri()

def desktop_choice():
    return {
        "Configuration": plistlib.dumps(
            {"type": "imageFile", "url": {"relative": uri}},
            fmt=plistlib.FMT_BINARY,
            sort_keys=False,
        ),
        "Files": [],
        "Provider": "com.apple.wallpaper.choice.image",
    }

def update_desktop(node):
    if not isinstance(node, dict):
        return
    desktop = node.get("Desktop")
    if not isinstance(desktop, dict):
        return
    content = desktop.setdefault("Content", {})
    content["Choices"] = [desktop_choice()]
    desktop["LastSet"] = now
    desktop["LastUse"] = now

updated = 0

for top_key in ("SystemDefault", "AllSpacesAndDisplays"):
    top = root.get(top_key)
    if isinstance(top, dict):
        before = updated
        update_desktop(top)
        if updated == before and isinstance(top.get("Desktop"), dict):
            updated += 1

for display in root.get("Displays", {}).values():
    if isinstance(display, dict):
        update_desktop(display)
        if isinstance(display.get("Desktop"), dict):
            updated += 1

for space in root.get("Spaces", {}).values():
    if not isinstance(space, dict):
        continue
    default = space.get("Default")
    if isinstance(default, dict):
        update_desktop(default)
        if isinstance(default.get("Desktop"), dict):
            updated += 1
    for display in space.get("Displays", {}).values():
        if isinstance(display, dict):
            update_desktop(display)
            if isinstance(display.get("Desktop"), dict):
                updated += 1

backup = index_path.with_name(f"{index_path.name}.bak.{int(time.time())}")
backup.write_bytes(raw)
index_path.write_bytes(plistlib.dumps(root, fmt=plistlib.FMT_BINARY, sort_keys=False))

if updated == 0:
    raise SystemExit(1)
PY
}

refresh_wallpaper_agents() {
  /bin/launchctl kickstart -k "gui/$(id -u)/com.apple.wallpaper.agent" >/dev/null 2>&1 || true
  /usr/bin/killall WallpaperAgent >/dev/null 2>&1 || true
}

# Apply wallpaper image to all desktops
apply_wallpaper() {
  local img="$1"

  if [[ ! -f "$img" ]]; then
    err "Image not found: $img"
    exit 1
  fi

  local applied=0

  # Write to wallpaper store for all spaces
  if set_with_wallpaper_store "$img"; then
    refresh_wallpaper_agents
    applied=1
  fi

  # Apply visually via desktoppr/Finder/System Events (no Dock restart)
  set_with_desktoppr "$img" 2>/dev/null ||
    set_with_finder "$img" 2>/dev/null ||
    set_with_system_events "$img" 2>/dev/null || true

  if [[ "$applied" -ne 1 ]]; then
    err "Failed to set wallpaper"
    exit 1
  fi
}

# Pick next wallpaper from current theme's backgrounds/
wallpaper_next() {
  local bg_dir="$SLICKER_THEME_DIR/backgrounds"

  if [[ ! -d "$bg_dir" ]]; then
    err "No backgrounds/ in current theme."
    exit 1
  fi

  shopt -s nullglob
  local images=("$bg_dir"/*)
  shopt -u nullglob

  if [[ ${#images[@]} -eq 0 ]]; then
    err "No images in $bg_dir"
    exit 1
  fi

  # Read current index
  local idx_file="$SLICKER_THEME_DIR/.wallpaper_index"
  local idx=0
  [[ -f "$idx_file" ]] && idx=$(cat "$idx_file")

  # Wrap around
  if [[ "$idx" -ge "${#images[@]}" ]]; then
    idx=0
  fi

  local img="${images[$idx]}"
  apply_wallpaper "$img"

  # Save next index
  echo $(( (idx + 1) % ${#images[@]} )) > "$idx_file"
  ok "Wallpaper set: $(basename "$img")"
}

# Set wallpaper from explicit path
wallpaper_set() {
  local path="${1:-}"
  if [[ -z "$path" ]]; then
    err "Usage: slicker wallpaper set <path>"
    exit 1
  fi

  local img
  img="$(resolve_path "$path")"
  apply_wallpaper "$img"
  ok "Wallpaper set: $img"
}

case "${1:-}" in
next) wallpaper_next ;;
set) wallpaper_set "${2:-}" ;;
*)
  err "Unknown wallpaper subcommand: ${1:-}"
  echo "Usage: slicker wallpaper {next | set <path>}"
  exit 1
  ;;
esac
