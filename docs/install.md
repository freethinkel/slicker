# slicker install

Full setup from scratch. Idempotent — safe to re-run.

## Steps

### 1. Homebrew

Checks for Homebrew, installs it if missing.

### 2. Stow

Checks for GNU Stow, installs via brew if needed.

### 3. User config

If `user/` doesn't exist — copies `user.example/` as a starter template. If `user/` already exists (e.g. a cloned private repo) — skips.

### 4. meta.sh

Sources `user/meta.sh` if present. This file exports variables like `MACHINE` for machine-specific logic in base configs.

### 5. Backup

Before stowing, checks for existing configs in `$HOME`. If a file exists and is not already a slicker symlink — moves it to `backups/<timestamp>/`. Backed up paths:

- `~/.zshrc`
- `~/.gitconfig`
- `~/.config/nvim`
- `~/.config/tmux`
- `~/.config/ghostty`
- `~/.config/starship.toml`

### 6. Stow

Runs `stow -v -t "$HOME" -d configs zsh git ghostty nvim tmux starship`. Creates symlinks from `$HOME` into `configs/`.

### 7. Brew bundle

Runs `brew bundle` from the base `Brewfile` (core tools), then from `user/Brewfile` if it exists.

## Usage

```bash
slicker install
# or
./install.sh
```
