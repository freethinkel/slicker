#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Back up anything in $HOME that a stow package would overwrite and that
# doesn't already resolve into the slicker repo. Targets are derived from
# the packages themselves — no hardcoded list to keep in sync.
backup_dir="$SLICKER_DIR/backups/$(date +%Y%m%d_%H%M%S)"
moved=0

for pkg_dir in "$SLICKER_DIR"/configs/*/; do
  pkg="$(basename "$pkg_dir")"
  src="$(pkg_src "$pkg")/$pkg"
  while IFS= read -r -d '' file; do
    rel="${file#$src/}"
    target="$HOME/$rel"
    if [[ -e "$target" ]] && ! is_stowed "$rel" "$file"; then
      if [[ "$moved" -eq 0 ]]; then
        info "Backing up existing configs to ${backup_dir#$SLICKER_DIR/}/"
        mkdir -p "$backup_dir"
      fi
      dest="$backup_dir/$rel"
      mkdir -p "$(dirname "$dest")"
      mv "$target" "$dest"
      echo "  $rel → ${backup_dir#$SLICKER_DIR/}/$rel"
      moved=1
    fi
  done < <(find "$src" \( -type f -o -type l \) -print0 2>/dev/null)
done

if [[ "$moved" -eq 0 ]]; then
  ok "Nothing to back up."
else
  ok "Backup complete."
fi
