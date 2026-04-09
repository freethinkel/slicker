# ZSH Config

Shell configuration is the central part of Slicker.

## Load Order

1. **Path resolution** — `SLICKER_DIR` and `SLICKER_ROOT` are resolved from the `.zshrc` symlink target
2. **Defaults** — `EDITOR`, `LANG`, `PATH` (adds `bin/slicker` and `user/bin/`)
3. **History** — 50k lines, dedupe, shared across sessions
4. **meta.sh** — `user/meta.sh` is loaded early to set `MACHINE` and other env vars
5. **Lib** — all `*.zsh` files from `configs/zsh/lib/` (aliases, functions)
6. **Machine-specific** — `case $MACHINE` for conditional configuration
7. **Starship** — `eval "$(starship init zsh)"` if starship is installed
8. **User overrides** — `user/zsh/user.zsh` is loaded last

## Lib Files

### aliases.zsh

- Replacements: `ls` → `eza`, `cat` → `bat`, `vim` → `nvim`
- Navigation: `ll`, `la`, `..`, `...`
- Git: `gs`, `gd`, `gl`, `gp`

### functions.zsh

- `mkcd <dir>` — create a directory and cd into it
- `ff <name>` — find a file by name

## User Overrides

`user/zsh/user.zsh` is loaded after everything else. You can override any alias, add your own functions, or configure PATH.

Examples:
```bash
# user/zsh/user.zsh
export STARSHIP_CONFIG="$HOME/.config/slicker/user/starship/starship.toml"
alias k="kubectl"
```
