#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

echo -e "${BOLD}Slicker Status${RESET}"
echo ""

# Slicker repo
echo -e "${BOLD}Slicker repo:${RESET} $SLICKER_DIR"
if git -C "$SLICKER_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  branch="$(git -C "$SLICKER_DIR" branch --show-current 2>/dev/null || echo "detached")"
  echo "  branch: $branch"
fi
echo ""

# User symlink
echo -e "${BOLD}User symlink:${RESET}"
if [[ -L "$SLICKER_USER_LINK" ]]; then
  echo "  user/ → $(readlink "$SLICKER_USER_LINK")"
else
  echo "  not linked"
fi
echo ""

# User repo
echo -e "${BOLD}User repo:${RESET} $SLICKER_USER_DIR"
if [[ -d "$SLICKER_USER_DIR" ]]; then
  if git -C "$SLICKER_USER_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    ubranch="$(git -C "$SLICKER_USER_DIR" branch --show-current 2>/dev/null || echo "detached")"
    status_line="$(git -C "$SLICKER_USER_DIR" status --porcelain | wc -l | tr -d ' ')"
    echo "  branch: $ubranch"
    echo "  uncommitted changes: $status_line file(s)"
  else
    echo "  exists (not a git repo)"
  fi
else
  echo "  not found"
fi
echo ""

# Theme
echo -e "${BOLD}Theme:${RESET}"
if [[ -f "$SLICKER_THEME_DIR/.current" ]]; then
  echo "  $(cat "$SLICKER_THEME_DIR/.current")"
else
  echo "  not set (run: slicker theme set <name>)"
fi
echo ""

# Stow links
echo -e "${BOLD}Stowed configs:${RESET}"
for pkg in zsh git ghostty nvim tmux; do
  pkg_dir="$SLICKER_DIR/configs/$pkg"
  if [[ -d "$pkg_dir" ]]; then
    echo -n "  $pkg: "
    linked=false
    while IFS= read -r -d '' file; do
      rel="${file#$pkg_dir/}"
      if [[ -L "$HOME/$rel" ]]; then
        linked=true
        break
      fi
    done < <(find "$pkg_dir" -type f -print0 2>/dev/null)
    if $linked; then
      echo -e "${GREEN}linked${RESET}"
    else
      echo -e "${YELLOW}not linked${RESET}"
    fi
  fi
done
