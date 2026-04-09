#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

TEMPLATES_DIR="$SLICKER_DIR/default/themed"
USER_TEMPLATES_DIR="$SLICKER_USER_DIR/themed"

# Find theme directory (user themes take priority)
find_theme() {
  local name="$1"
  if [[ -d "$SLICKER_USER_DIR/themes/$name" ]]; then
    echo "$SLICKER_USER_DIR/themes/$name"
  elif [[ -d "$SLICKER_DIR/themes/$name" ]]; then
    echo "$SLICKER_DIR/themes/$name"
  else
    return 1
  fi
}

# Convert hex color to decimal RGB (e.g., "#1e1e2e" -> "30,30,46")
hex_to_rgb() {
  local hex="${1#\#}"
  printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# Generate config files from templates using colors.toml
generate_templates() {
  local colors_file="$SLICKER_THEME_DIR/colors.toml"

  [[ -f "$colors_file" ]] || return 0

  local sed_script
  sed_script=$(mktemp)

  while IFS='=' read -r key value; do
    key="${key//[\"\' ]/}"
    [[ $key && $key != \#* && $key != \[* ]] || continue
    value="${value#*[\"\']}"
    value="${value%%[\"\']*}"

    printf 's|{{ %s }}|%s|g\n' "$key" "$value"
    printf 's|{{ %s_strip }}|%s|g\n' "$key" "${value#\#}"
    if [[ $value =~ ^# ]]; then
      local rgb
      rgb=$(hex_to_rgb "$value")
      echo "s|{{ ${key}_rgb }}|${rgb}|g"
    fi
  done <"$colors_file" >"$sed_script"

  shopt -s nullglob

  # Process user templates first, then built-in (user overrides built-in)
  for tpl in "$USER_TEMPLATES_DIR"/*.tpl "$TEMPLATES_DIR"/*.tpl; do
    [[ -f "$tpl" ]] || continue
    local filename
    filename=$(basename "$tpl" .tpl)
    local output_path="$SLICKER_THEME_DIR/$filename"

    # Don't overwrite files already copied from theme directory
    if [[ ! -f "$output_path" ]]; then
      sed -f "$sed_script" "$tpl" >"$output_path"
    fi
  done

  rm "$sed_script"
}

theme_list() {
  echo -e "${BOLD}Available themes:${RESET}"
  echo ""

  local current=""
  [[ -f "$SLICKER_THEME_DIR/.current" ]] && current="$(cat "$SLICKER_THEME_DIR/.current")"

  # Base themes
  for dir in "$SLICKER_DIR"/themes/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    [[ "$name" != "templates" ]] || continue
    if [[ "$name" == "$current" ]]; then
      echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET}"
    else
      echo -e "  ○ $name"
    fi
  done

  # User themes
  if [[ -d "$SLICKER_USER_DIR/themes" ]]; then
    for dir in "$SLICKER_USER_DIR"/themes/*/; do
      [[ -d "$dir" ]] || continue
      local name
      name="$(basename "$dir")"
      [[ "$name" != "templates" ]] || continue
      if [[ "$name" == "$current" ]]; then
        echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET} (user)"
      else
        echo -e "  ○ $name (user)"
      fi
    done
  fi
}

theme_set() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    err "Usage: slicker theme set <name>"
    echo "Run 'slicker theme list' to see available themes."
    exit 1
  fi

  local theme_dir
  if ! theme_dir="$(find_theme "$name")"; then
    err "Theme '$name' not found."
    echo "Run 'slicker theme list' to see available themes."
    exit 1
  fi

  # Clean theme output directory (keep the dir itself for file watchers)
  mkdir -p "$SLICKER_THEME_DIR"
  find "$SLICKER_THEME_DIR" -mindepth 1 -maxdepth 1 ! -name '.current' -exec rm -rf {} +

  # Copy base theme files first
  local base_dir="$SLICKER_DIR/themes/$name"
  [[ -d "$base_dir" ]] && cp -r "$base_dir/"* "$SLICKER_THEME_DIR/" 2>/dev/null || true

  # Overlay user theme files on top
  local user_dir="$SLICKER_USER_DIR/themes/$name"
  [[ -d "$user_dir" ]] && cp -r "$user_dir/"* "$SLICKER_THEME_DIR/" 2>/dev/null || true

  # Generate dynamic configs from templates
  generate_templates

  echo "$name" >"$SLICKER_THEME_DIR/.current"
  ok "Theme set to ${BOLD}$name${RESET}"

  # Reload tmux if running
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null &&
      ok "Tmux config reloaded."
  fi

  # Set macOS appearance based on light.mode flag
  if [[ -f "$SLICKER_THEME_DIR/light.mode" ]]; then
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null || true
  else
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null || true
  fi

  # Reload ghostty config for all running instances
  osascript -e '
    tell application "System Events"
      repeat with p in (every process whose name is "ghostty")
        tell p
          click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1
        end tell
      end repeat
    end tell' 2>/dev/null || true

  # Reload btop if running
  pkill -USR2 btop 2>/dev/null || true

  # Set wallpaper from theme backgrounds
  if [[ -d "$SLICKER_THEME_DIR/backgrounds" ]]; then
    "$SLICKER_DIR/scripts/wallpaper.sh" next
  fi
}

theme_current() {
  if [[ -f "$SLICKER_THEME_DIR/.current" ]]; then
    cat "$SLICKER_THEME_DIR/.current"
  else
    echo "no theme set"
  fi
}

case "${1:-}" in
list | ls) theme_list ;;
set) theme_set "${2:-}" ;;
current) theme_current ;;
*)
  err "Unknown theme subcommand: ${1:-}"
  echo "Usage: slicker theme {list | set <name> | current}"
  exit 1
  ;;
esac
