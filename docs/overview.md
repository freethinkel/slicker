# Slicker Overview

Slicker is an opinionated macOS dotfiles framework with a two-layer config system.

## How It Works

Configs are split into two layers:

- **Base** (`configs/`) — shared configs managed by Slicker. Updated via `git pull`.
- **User** (`user/`) — personal overrides. Gitignored in the main repo, can live in a separate private repository.

Base configs always source user configs last via each tool's native include mechanism. This means `slicker update` never breaks personal settings.

## Repository Structure

```
~/.config/slicker/
├── bin/slicker              # CLI entry point (added to PATH)
├── configs/                 # base layer (stowed into ~)
│   ├── zsh/.zshrc
│   ├── git/.gitconfig
│   ├── ghostty/...
│   ├── nvim/.config/nvim    # symlink → user/nvim (config lives entirely in user/)
│   ├── starship/.config/starship.toml
│   └── tmux/.config/tmux/
├── themes/
│   ├── palettes/            # color variables per theme
│   └── templates/           # configs with ${THEME_*} placeholders
├── theme/                   # generated output (gitignored)
├── user/                    # personal overrides (gitignored)
├── user.example/            # template for user/
├── scripts/                 # install/update/theme/status logic
├── docs/                    # documentation
└── Brewfile                 # base Homebrew dependencies
```

## Symlinking via Stow

GNU Stow creates symlinks from `$HOME` into `configs/`. Each directory in `configs/` is a stow package whose files mirror the target layout relative to `$HOME`.

For example:
- `configs/zsh/.zshrc` → `~/.zshrc`
- `configs/starship/.config/starship.toml` → `~/.config/starship.toml`
- `configs/tmux/.config/tmux/tmux.conf` → `~/.config/tmux/tmux.conf`

### Special Case: Neovim

`configs/nvim/.config/nvim` is a symlink to `user/nvim/`. Stow creates `~/.config/nvim` pointing through this chain into the user directory. This way the entire Neovim config lives in the user's private repo.

## Two-Layer Include

Each tool loads user overrides via its native mechanism:

| Tool     | Mechanism in base config                    | User file path              |
|----------|---------------------------------------------|-----------------------------|
| zsh      | `source "$SLICKER_ROOT/user/zsh/user.zsh"`  | `user/zsh/user.zsh`         |
| git      | `[include] path = ...user.gitconfig`        | `user/git/user.gitconfig`   |
| ghostty  | `config-file = ...user.conf`                | `user/ghostty/user.conf`    |
| nvim     | Entire config in user/ (symlink)            | `user/nvim/`                |
| starship | `STARSHIP_CONFIG` env var in user.zsh       | `user/starship/starship.toml` |
| tmux     | `source-file -q ...user.conf`               | `user/tmux/user.conf`       |

All includes fail silently if the user file doesn't exist.
