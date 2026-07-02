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

# User config
echo -e "${BOLD}User config:${RESET}"
if [[ -d "$SLICKER_USER_DIR" ]]; then
  echo -e "  ${GREEN}present${RESET}"
else
  echo -e "  ${YELLOW}not found${RESET} (run: slicker install)"
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

# Stow links: every file in the package must resolve to its source
# (readlink -f handles both direct links and stow-folded dir links).
echo -e "${BOLD}Stowed configs:${RESET}"
while IFS= read -r pkg; do
  src="$(pkg_src "$pkg")/$pkg"
  linked=true
  while IFS= read -r -d '' file; do
    rel="${file#$src/}"
    if ! is_stowed "$rel" "$file"; then
      linked=false
      break
    fi
  done < <(find "$src" \( -type f -o -type l \) ! -name '.DS_Store' -print0 2>/dev/null)
  echo -n "  $pkg: "
  if $linked; then
    echo -e "${GREEN}linked${RESET}"
  else
    echo -e "${YELLOW}not linked${RESET}"
  fi
done < <(stow_pkgs)
