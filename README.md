# Slicker

Opinionated macOS dotfiles framework with a two-layer config system.

## Concept

Slicker separates configs into two layers:

- **`configs/`** (base) — upstream configs managed by Slicker. Updated via `git pull`.
- **`user/`** (personal) — your overrides, gitignored, symlinked to a separate private repo.

Every base config explicitly sources/includes its user counterpart at the end. This means `git pull` on Slicker **never breaks your personal configs** — they're loaded last and always win.

Similar to how [NvChad](https://github.com/NvChad/NvChad) handles `lua/custom/`.

## Quick Start

```bash
# Clone slicker
git clone https://github.com/youruser/slicker ~/.config/slicker
cd ~/.config/slicker

# Full install (brew, stow, user config setup)
./install.sh

# Or use the CLI directly
./bin/slicker install
```

On first run, if no user config exists, Slicker copies `user.example/` to `~/.slicker-user/` and creates a symlink.

### With an existing private config repo

```bash
export SLICKER_USER_REPO=git@github.com:youruser/slicker-user.git
./install.sh
```

Or after install:

```bash
slicker user init git@github.com:youruser/slicker-user.git
```

## How It Works

```
~/.config/slicker/              ~/.slicker-user/ (private repo)
├── configs/                    ├── zsh/
│   ├── zsh/.zshrc ──sources──→ │   └── user.zsh
│   ├── git/.gitconfig ─includes→├── git/
│   ├── ghostty/config ─includes→│   └── user.gitconfig
│   └── nvim/lua/ ──requires──→ ├── ghostty/
├── themes/                     │   └── user.conf
│   ├── catppuccin-mocha/       ├── nvim/lua/user/
│   ├── tokyo-night/            │   └── init.lua
│   └── rose-pine/              ├── meta.sh
├── theme → themes/active-theme │   └── Brewfile (optional)
├── user/ → ~/.slicker-user/    └── themes/ (optional, user themes)
├── user.example/
└── bin/slicker
```

The `user/` directory inside slicker is a **symlink** to `~/.slicker-user/` and is **gitignored**. Your personal configs live in their own repo that you control.

## CLI

```bash
slicker install              # Full setup: brew, stow, user config, symlinks
slicker update               # Pull latest slicker + re-stow (never touches user/)
slicker user init [repo-url] # Clone or init user config repo
slicker user edit            # Open ~/.slicker-user in $EDITOR
slicker theme list           # List available themes
slicker theme set <name>     # Set active theme
slicker theme current        # Show current theme
slicker status               # Show what's linked, user repo status
```

## The Two-Layer Pattern

Each config type uses its tool's native include mechanism:

| Config   | Base file                | How it loads user overrides         |
|----------|--------------------------|-------------------------------------|
| zsh      | `configs/zsh/.zshrc`     | `source user/zsh/user.zsh`          |
| git      | `configs/git/.gitconfig` | `[include] path = ...user.gitconfig`|
| ghostty  | `configs/ghostty/config` | `config-file = ...user.conf`        |
| neovim   | `configs/nvim/lua/`      | `pcall(require, "user")`            |
| tmux     | `configs/tmux/tmux.conf` | `source-file -q ...user.conf`       |

All includes fail silently if the user file doesn't exist.

## `meta.sh`

The `user/meta.sh` file is sourced early and exports environment variables that base configs can use for machine-specific branching:

```bash
# user/meta.sh
export MACHINE="work"    # or "home"
```

Then in base configs:

```bash
case "${MACHINE:-}" in
    work) ... ;;
    home) ... ;;
esac
```

## Creating Your User Config

1. After install, edit `~/.slicker-user/`:
   ```bash
   slicker user edit
   ```

2. Set your git identity in `git/user.gitconfig`
3. Set `MACHINE` in `meta.sh`
4. Add personal aliases to `zsh/user.zsh`
5. Optionally add a `Brewfile` for `brew bundle`

6. Make it a git repo and push to your private remote:
   ```bash
   cd ~/.slicker-user
   git init && git add -A && git commit -m "init"
   git remote add origin git@github.com:youruser/slicker-user.git
   git push -u origin main
   ```

## Adding New Configs

To add support for a new tool (e.g., `tmux`):

1. Create `configs/tmux/.tmux.conf` with base settings
2. End it with: `source-file ~/.slicker-user/tmux/user.conf` (with a guard)
3. Create `user.example/tmux/user.conf` as a template
4. Add `tmux` to the stow command in `bin/slicker`

## License

MIT
