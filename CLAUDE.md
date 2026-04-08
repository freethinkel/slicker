# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Slicker

Opinionated macOS dotfiles framework with a two-layer config system. Base configs live in `configs/` (managed by slicker), personal overrides live in `user/` (symlinked to `~/.slicker-user/`, a separate private repo). Base configs always source user counterparts last via each tool's native include mechanism, so `git pull` on slicker never breaks personal settings.

## Architecture

**Stow-based symlinking:** `stow -v -t "$HOME" -d configs zsh git ghostty nvim tmux` creates symlinks from `~` into `configs/`. Files in `configs/<pkg>/` mirror the target filesystem layout relative to `$HOME`.

**Two-layer include pattern per tool:**

| Tool    | Include mechanism in base config          | User file path                        |
|---------|-------------------------------------------|---------------------------------------|
| zsh     | `source "$SLICKER_ROOT/user/zsh/user.zsh"` | `~/.slicker-user/zsh/user.zsh`       |
| git     | `[include] path = ...user.gitconfig`       | `~/.slicker-user/git/user.gitconfig`  |
| ghostty | `config-file = ~/.slicker-user/ghostty/user.conf` | `~/.slicker-user/ghostty/user.conf` |
| nvim    | `pcall(require, "user")`                   | `~/.slicker-user/nvim/lua/user/init.lua` |
| starship| `STARSHIP_CONFIG` env var in user.zsh      | `~/.slicker-user/starship/starship.toml` |
| tmux    | `source-file -q ~/.slicker-user/tmux/user.conf` | `~/.slicker-user/tmux/user.conf`  |

All includes fail silently if user file doesn't exist.

**`user/meta.sh`** is sourced early in `.zshrc` to export `MACHINE` and other env vars used for machine-specific branching in base configs.

**Brewfile:** Two-layer — base `Brewfile` in repo root (core tools), optional user `Brewfile` in `~/.slicker-user/Brewfile`. Both run during install.

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
2. End base config with a silent include of `~/.slicker-user/<tool>/user.conf` (or equivalent)
3. Create `user.example/<tool>/user.conf` as template
4. Add `<tool>` to the `stow` command in `stow_configs()` and the `for pkg in ...` loop in `cmd_status()` in `bin/slicker`
5. Add row to the two-layer table in README.md

## Key Conventions

- `user/` directory is gitignored — it's a symlink to `~/.slicker-user/`
- `SLICKER_ROOT` is resolved from the symlinked `.zshrc` target using zsh's `%x` parameter expansion
- Neovim user module must return a table with optional `setup()` function
- Install is idempotent — safe to re-run
