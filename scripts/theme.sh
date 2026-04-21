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

# Sync generated obsidian.css to every Obsidian vault as an "Omarchy" theme
sync_obsidian() {
  local css="$SLICKER_THEME_DIR/obsidian.css"
  [[ -f "$css" ]] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local obsidian_json=""
  for candidate in \
    "$HOME/Library/Application Support/obsidian/obsidian.json" \
    "$HOME/.config/obsidian/obsidian.json"; do
    if [[ -f "$candidate" ]]; then
      obsidian_json="$candidate"
      break
    fi
  done
  [[ -n "$obsidian_json" ]] || return 0

  local synced=0
  while IFS= read -r vault_path; do
    [[ -n "$vault_path" && -d "$vault_path/.obsidian" ]] || continue

    local theme_dir="$vault_path/.obsidian/themes/Omarchy"
    mkdir -p "$theme_dir"

    if [[ ! -f "$theme_dir/manifest.json" ]]; then
      cat >"$theme_dir/manifest.json" <<'EOF'
{
  "name": "Omarchy",
  "version": "1.0.0",
  "minAppVersion": "0.16.0",
  "description": "Automatically syncs with your current Slicker theme colors.",
  "author": "Slicker",
  "authorUrl": "https://github.com/freethinkel/slicker"
}
EOF
    fi

    cp "$css" "$theme_dir/theme.css"
    synced=$((synced + 1))
  done < <(jq -r '.vaults | values[].path' "$obsidian_json" 2>/dev/null)

  ((synced > 0)) && ok "Obsidian theme synced to $synced vault(s)."
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
    if ! command -v fzf &>/dev/null; then
      err "Usage: slicker theme set <name>"
      echo "Run 'slicker theme list' to see available themes."
      exit 1
    fi

    local themes=()
    for dir in "$SLICKER_DIR"/themes/*/; do
      [[ -d "$dir" ]] || continue
      local t
      t="$(basename "$dir")"
      [[ "$t" != "templates" ]] && themes+=("$t")
    done
    if [[ -d "$SLICKER_USER_DIR/themes" ]]; then
      for dir in "$SLICKER_USER_DIR"/themes/*/; do
        [[ -d "$dir" ]] || continue
        local t
        t="$(basename "$dir")"
        [[ "$t" != "templates" ]] && themes+=("$t (user)")
      done
    fi

    if [[ ${#themes[@]} -eq 0 ]]; then
      err "No themes found."
      exit 1
    fi

    name=$(printf '%s\n' "${themes[@]}" | fzf --prompt="Select theme: " --height=~20) || exit 0
    # Strip " (user)" suffix if present
    name="${name% (user)}"
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

  # Restart sketchybar (launchd auto-restarts it)
  killall sketchybar 2>/dev/null || true

  # Update JankyBorders active color from theme
  # Active window border (via JankyBorders) — accent color from theme
  _slicker_accent="e1e1e1"
  _slicker_colors="$HOME/.config/slicker/theme/colors.toml"
  if [[ -f "$_slicker_colors" ]]; then
    _slicker_accent=$(grep '^accent' "$_slicker_colors" | sed 's/.*"#\([^"]*\)".*/\1/')
  fi
  borders active_color=0xff${_slicker_accent} inactive_color=0x50${_slicker_accent} width=6.0 &

  # Apply browser theme via macOS managed policies (BrowserThemeColor)
  local bg_color
  bg_color=$(grep '^background' "$SLICKER_THEME_DIR/colors.toml" 2>/dev/null | sed 's/.*"\(#[^"]*\)".*/\1/')
  if [[ -n "$bg_color" ]]; then
    local color_scheme="dark"
    [[ -f "$SLICKER_THEME_DIR/light.mode" ]] && color_scheme="light"

    local browsers=(
      "com.google.Chrome|Google Chrome"
      "com.brave.Browser|Brave Browser"
      "org.chromium.Chromium|Chromium"
      "com.microsoft.Edge|Microsoft Edge"
    )
    local applied=false
    for entry in "${browsers[@]}"; do
      local bundle_id="${entry%%|*}"
      local browser_name="${entry#*|}"
      if mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" 2>/dev/null | grep -q .; then
        defaults write "$bundle_id" BrowserThemeColor -string "$bg_color"
        defaults write "$bundle_id" BrowserColorScheme -string "$color_scheme"
        applied=true
        ok "Browser theme applied to ${browser_name}."
      fi
    done
    $applied || info "No supported Chromium browsers found, skipping browser theme."
  fi

  # Set wallpaper from theme backgrounds
  if [[ -d "$SLICKER_THEME_DIR/backgrounds" ]]; then
    "$SLICKER_DIR/scripts/wallpaper.sh" next
  fi

  # Sync generated obsidian.css to all Obsidian vaults
  sync_obsidian
}

theme_install() {
  local repo="${1:-}"
  if [[ -z "$repo" ]]; then
    err "Usage: slicker theme install <git-url> [name]"
    exit 1
  fi

  local name="${2:-$(basename "$repo" .git)}"
  local dest="$SLICKER_USER_DIR/themes/$name"

  if [[ -d "$dest" ]]; then
    err "Theme '$name' already exists at $dest"
    exit 1
  fi

  mkdir -p "$SLICKER_USER_DIR/themes"
  info "Installing theme ${BOLD}$name${RESET} from $repo..."

  if ! git clone "$repo" "$dest" 2>&1; then
    err "Failed to clone repository."
    rm -rf "$dest"
    exit 1
  fi

  if [[ ! -f "$dest/colors.toml" ]]; then
    err "Invalid theme: colors.toml not found in repository root."
    rm -rf "$dest"
    exit 1
  fi

  ok "Theme ${BOLD}$name${RESET} installed. Run 'slicker theme set $name' to activate."
}

theme_uninstall() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    err "Usage: slicker theme uninstall <name>"
    exit 1
  fi

  local dest="$SLICKER_USER_DIR/themes/$name"
  if [[ ! -d "$dest" ]]; then
    err "User theme '$name' not found."
    exit 1
  fi

  rm -rf "$dest"
  ok "Theme ${BOLD}$name${RESET} uninstalled."
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
install) theme_install "${2:-}" "${3:-}" ;;
uninstall | remove) theme_uninstall "${2:-}" ;;
*)
  err "Unknown theme subcommand: ${1:-}"
  echo "Usage: slicker theme {list | set <name> | current | install <git-url> [name] | uninstall <name>}"
  exit 1
  ;;
esac
