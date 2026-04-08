# ─── Slicker ZSH Config ───────────────────────────────────────────────
# Base layer — managed by slicker. Personal overrides go in user/zsh/user.zsh

SLICKER_DIR="${${(%):-%x}:A:h}"
# Resolve back to slicker root from ~/.zshrc symlink target
SLICKER_ROOT="$(cd "$SLICKER_DIR/../.." 2>/dev/null && pwd)"

# ─── Defaults ─────────────────────────────────────────────────────────

export EDITOR="${EDITOR:-nvim}"
export LANG="${LANG:-en_US.UTF-8}"

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

for f in "$SLICKER_ROOT/configs/zsh/lib/"*.zsh(N); do
    source "$f"
done

# ─── Machine-specific base config ────────────────────────────────────

case "${MACHINE:-}" in
    work)
        # Add work-specific base config here
        ;;
    home)
        # Add home-specific base config here
        ;;
esac

# ─── User overrides (loaded last, always wins) ───────────────────────

[[ -f "$SLICKER_ROOT/user/zsh/user.zsh" ]] && source "$SLICKER_ROOT/user/zsh/user.zsh"
