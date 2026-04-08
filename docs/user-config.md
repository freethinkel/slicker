# User Config

Personal settings live in `user/`, which is gitignored in the main Slicker repo.

## Initialization

### From template

On first `slicker install`, if `user/` doesn't exist, `user.example/` is copied.

### From a private repository

```bash
slicker user init git@github.com:yourname/dotfiles-private.git
```

This clones the repo into `user/`. All personal settings are versioned separately.

### Editing

```bash
slicker user edit    # opens user/ in $EDITOR
```

## Structure

```
user/
├── meta.sh              # environment variables (MACHINE, etc.)
├── zsh/user.zsh         # zsh overrides
├── git/user.gitconfig   # git overrides
├── ghostty/user.conf    # ghostty overrides
├── nvim/                # full Neovim config (init.lua, lua/, ...)
├── starship/            # (opt) custom starship.toml via STARSHIP_CONFIG
├── tmux/user.conf       # tmux overrides
├── bin/                 # user scripts (added to PATH)
├── themes/palettes/     # (opt) custom theme palettes
├── themes/templates/    # (opt) custom theme templates
└── Brewfile             # (opt) user Brewfile
```

## meta.sh

Loaded at the very beginning of `.zshrc`. Exports variables for machine-specific logic:

```bash
export MACHINE="work"   # or "home"
```

The base `.zshrc` has a `case $MACHINE` block for conditional configuration.

## Neovim

Neovim is a special case. The entire config lives in `user/nvim/` (not just overrides). `configs/nvim/.config/nvim` is a symlink to `user/nvim/`, and stow creates the chain:

```
~/.config/nvim → configs/nvim/.config/nvim → user/nvim/
```

The template in `user.example/nvim/` contains a base LazyVim config.

## Syncing with user.example

During `slicker update`, new directories from `user.example/` are automatically copied to `user/` if they don't already exist. Existing directories are never touched.
