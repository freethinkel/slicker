# ─── Slicker ZSH Config ───────────────────────────────────────────────
# Base layer — managed by slicker. Personal overrides go in user/zsh/user.zsh

SLICKER_DIR="${${(%):-%x}:A:h}"
# Resolve back to slicker root from ~/.zshrc symlink target
SLICKER_ROOT="$(cd "$SLICKER_DIR/../.." 2>/dev/null && pwd)"

# ─── Defaults ─────────────────────────────────────────────────────────

export EDITOR="${EDITOR:-nvim}"
export LANG="${LANG:-en_US.UTF-8}"

# Force emacs keymap (otherwise EDITOR=nvim silently selects viins and breaks alt+backspace)
bindkey -e

# Add slicker bin + user bin to PATH
export PATH="$SLICKER_ROOT/bin:$PATH"
[[ -d "$SLICKER_ROOT/user/bin" ]] && export PATH="$SLICKER_ROOT/user/bin:$PATH"

# History
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ─── Source user/meta.sh early (sets MACHINE, etc) ────────────────────

[[ -f "$SLICKER_ROOT/user/meta.sh" ]] && source "$SLICKER_ROOT/user/meta.sh"

# ─── Slicker lib ──────────────────────────────────────────────────────

for f in "$HOME/.config/zsh/lib/"*.zsh(N); do
    source "$f"
done

# ─── Plugin manager (antidote) ───────────────────────────────────────

for _antidote in \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" \
    "/usr/local/opt/antidote/share/antidote/antidote.zsh"; do
    if [[ -f $_antidote ]]; then
        source "$_antidote"
        break
    fi
done
unset _antidote

if (( $+functions[antidote] )); then
    _slicker_plugins_cache="${XDG_CACHE_HOME:-$HOME/.cache}/slicker/zsh_plugins.txt"
    _slicker_plugins_base="$SLICKER_ROOT/configs/zsh/plugins.txt"
    _slicker_plugins_user="$SLICKER_ROOT/user/zsh/plugins.txt"

    if [[ ! -f $_slicker_plugins_cache \
          || $_slicker_plugins_base -nt $_slicker_plugins_cache \
          || ( -f $_slicker_plugins_user && $_slicker_plugins_user -nt $_slicker_plugins_cache ) ]]; then
        mkdir -p "${_slicker_plugins_cache:h}"
        cat "$_slicker_plugins_base" "$_slicker_plugins_user"(N) > "$_slicker_plugins_cache"
    fi

    antidote load "$_slicker_plugins_cache"
    unset _slicker_plugins_cache _slicker_plugins_base _slicker_plugins_user
fi

# ─── Machine-specific base config ────────────────────────────────────

case "${MACHINE:-}" in
    work)
        # Add work-specific base config here
        ;;
    home)
        # Add home-specific base config here
        ;;
esac

# ─── Starship prompt ─────────────────────────────────────────────────

if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ─── Zoxide (smarter cd) ─────────────────────────────────────────────

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ─── User overrides (loaded last, always wins) ───────────────────────

[[ -f "$SLICKER_ROOT/user/zsh/user.zsh" ]] && source "$SLICKER_ROOT/user/zsh/user.zsh"
