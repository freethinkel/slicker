#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

user_init() {
  local repo_url="${1:-}"

  if [[ -n "$repo_url" ]]; then
    if [[ -d "$SLICKER_USER_DIR" ]]; then
      err "user/ already exists. Remove it first to re-clone."
      exit 1
    fi
    git clone "$repo_url" "$SLICKER_USER_DIR"
    ok "Cloned user repo."
  elif [[ -d "$SLICKER_USER_DIR" ]]; then
    ok "User config found."
  else
    cp -r "$SLICKER_DIR/user.example" "$SLICKER_USER_DIR"
    ok "Created user/ from template."
  fi
}

user_edit() {
  local editor="${EDITOR:-vim}"
  info "Opening user/ in $editor..."
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
