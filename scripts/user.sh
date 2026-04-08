#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

user_init() {
  local repo_url="${1:-}"

  if [[ -n "$repo_url" ]]; then
    if [[ -d "$SLICKER_USER_DIR" ]]; then
      err "$SLICKER_USER_DIR already exists. Remove it first to re-clone."
      exit 1
    fi
    git clone "$repo_url" "$SLICKER_USER_DIR"
    ok "Cloned user repo."
  elif [[ -d "$SLICKER_USER_DIR" ]]; then
    ok "User config found at $SLICKER_USER_DIR"
  else
    cp -r "$SLICKER_DIR/user.example" "$SLICKER_USER_DIR"
    warn "Created $SLICKER_USER_DIR from template."
  fi

  if [[ ! -L "$SLICKER_USER_LINK" ]]; then
    ln -s "$SLICKER_USER_DIR" "$SLICKER_USER_LINK"
    ok "Created symlink: user/ → $SLICKER_USER_DIR"
  fi

  ok "User config ready at $SLICKER_USER_DIR"
}

user_edit() {
  local editor="${EDITOR:-vim}"
  info "Opening $SLICKER_USER_DIR in $editor..."
  "$editor" "$SLICKER_USER_DIR"
}

case "${1:-}" in
init) user_init "${2:-}" ;;
edit) user_edit ;;
*)
  err "Unknown user subcommand: ${1:-}"
  echo "Usage: slicker user {init [repo-url] | edit}"
  exit 1
  ;;
esac
