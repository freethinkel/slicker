#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Find palette file by theme name (user palettes take priority)
find_palette() {
  local name="$1"
  if [[ -f "$SLICKER_USER_DIR/themes/palettes/$name.sh" ]]; then
    echo "$SLICKER_USER_DIR/themes/palettes/$name.sh"
  elif [[ -f "$SLICKER_DIR/themes/palettes/$name.sh" ]]; then
    echo "$SLICKER_DIR/themes/palettes/$name.sh"
  else
    return 1
  fi
}

# Generate theme files from palette + templates
generate_theme() {
  local palette="$1"
  source "$palette"

  mkdir -p "$SLICKER_THEME_DIR"

  # Use user templates if they exist, otherwise base templates
  local tmpl_dir="$SLICKER_DIR/themes/templates"
  [[ -d "$SLICKER_USER_DIR/themes/templates" ]] && tmpl_dir="$SLICKER_USER_DIR/themes/templates"

  for template in "$tmpl_dir"/*; do
    [[ -f "$template" ]] || continue
    local filename
    filename="$(basename "$template")"
    render_template "$template" > "$SLICKER_THEME_DIR/$filename"
  done
}

theme_list() {
  echo -e "${BOLD}Available themes:${RESET}"
  echo ""

  local current=""
  [[ -f "$SLICKER_THEME_DIR/.current" ]] && current="$(cat "$SLICKER_THEME_DIR/.current")"

  # Base palettes
  for palette in "$SLICKER_DIR"/themes/palettes/*.sh; do
    [[ -f "$palette" ]] || continue
    local name
    name="$(basename "$palette" .sh)"
    if [[ "$name" == "$current" ]]; then
      echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET}"
    else
      echo -e "  ○ $name"
    fi
  done

  # User palettes
  if [[ -d "$SLICKER_USER_DIR/themes/palettes" ]]; then
    for palette in "$SLICKER_USER_DIR"/themes/palettes/*.sh; do
      [[ -f "$palette" ]] || continue
      local name
      name="$(basename "$palette" .sh)"
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

  local palette
  if ! palette="$(find_palette "$name")"; then
    err "Theme '$name' not found."
    echo "Run 'slicker theme list' to see available themes."
    exit 1
  fi

  generate_theme "$palette"
  echo "$name" > "$SLICKER_THEME_DIR/.current"
  ok "Theme set to ${BOLD}$name${RESET}"

  # Reload tmux if running
  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null &&
      ok "Tmux config reloaded."
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
