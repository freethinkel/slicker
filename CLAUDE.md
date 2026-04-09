# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Slicker

Opinionated macOS dotfiles framework with a two-layer config system. Base configs live in `configs/` (managed by slicker), personal overrides live in `user/` (inside `~/.config/slicker/user/`, a separate private repo). Base configs always source user counterparts last via each tool's native include mechanism, so `git pull` on slicker never breaks personal settings.

## Architecture

**Stow-based symlinking:** `stow -v -t "$HOME" -d configs zsh git ghostty tmux starship` creates symlinks from `~` into `configs/`. Files in `configs/<pkg>/` mirror the target filesystem layout relative to `$HOME`.

**Neovim** uses a symlink inside the stow package: `configs/nvim/.config/nvim` → `user/nvim/`. Stow creates `~/.config/nvim` pointing through this chain, so the full nvim config lives in the user's private repo.

**Two-layer include pattern per tool:**

| Tool    | Include mechanism in base config          | User file path                        |
|---------|-------------------------------------------|---------------------------------------|
| zsh     | `source "$SLICKER_ROOT/user/zsh/user.zsh"` | `~/.config/slicker/user/zsh/user.zsh`       |
| git     | `[include] path = ...user.gitconfig`       | `~/.config/slicker/user/git/user.gitconfig`  |
| ghostty | `config-file = ...user/ghostty/user.conf`  | `~/.config/slicker/user/ghostty/user.conf`   |
| nvim    | `configs/nvim/.config/nvim` → symlink to `user/nvim/` | `~/.config/slicker/user/nvim/`    |
| starship| `STARSHIP_CONFIG` env var in user.zsh      | `~/.config/slicker/user/starship/starship.toml` |
| tmux    | `source-file -q ...user/tmux/user.conf`    | `~/.config/slicker/user/tmux/user.conf`      |
| skhd    | `.load "~/.config/slicker/user/skhd/user.skhdrc"` | `~/.config/slicker/user/skhd/user.skhdrc` |
| yabai   | `source ~/.config/slicker/user/yabai/user.yabairc` | `~/.config/slicker/user/yabai/user.yabairc` |

All includes fail silently if user file doesn't exist.

**`user/meta.sh`** is sourced early in `.zshrc` to export `MACHINE` and other env vars used for machine-specific branching in base configs.

**Brewfile:** Two-layer — base `Brewfile` in repo root (core tools), optional user `Brewfile` in `~/.config/slicker/user/Brewfile`. Both run during install.

## CLI (`bin/slicker`)

```
slicker install    # brew → stow → user dir → symlinks → brewfiles
slicker update     # git pull + re-stow (never touches user/)
slicker status     # show link status and user repo info
slicker user init [repo-url]
slicker user edit
```

Wrappers: `install.sh` → `bin/slicker install`, `update.sh` → `bin/slicker update`.

## Adding a New Config Tool

1. Create `configs/<tool>/` with files mirroring target layout relative to `$HOME`
2. End base config with a silent include of `~/.config/slicker/user/<tool>/user.conf` (or equivalent)
3. Create `user.example/<tool>/user.conf` as template
4. Add row to the two-layer table in README.md

> Stow автоматически подхватывает все папки в `configs/` — вручную добавлять в скрипты не нужно.

## Key Conventions

- `user/` directory is gitignored — it's the user's private config repo
- `SLICKER_ROOT` is resolved from the symlinked `.zshrc` target using zsh's `%x` parameter expansion
- Neovim user module must return a table with optional `setup()` function
- Install is idempotent — safe to re-run
