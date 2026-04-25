# Slicker

Opinionated macOS dotfiles framework with a two-layer config system.

## Concept

Slicker separates configs into two layers:

- **`configs/`** (base) — upstream configs managed by Slicker. Updated via `git pull`.
- **`user/`** (personal) — your overrides, gitignored. Copied from `user.example/` on first install.

Every base config explicitly sources/includes its user counterpart at the end. This means `git pull` on Slicker **never breaks your personal configs** — they're loaded last and always win.

## Quick Start

```bash
git clone https://github.com/youruser/slicker ~/.config/slicker
cd ~/.config/slicker
./install.sh
```

On first run, if `user/` doesn't exist, Slicker copies `user.example/` into it.

## How It Works

```
~/.config/slicker/
├── configs/                    # base layer (stowed to ~)
│   ├── zsh/.zshrc
│   ├── git/.gitconfig
│   ├── ghostty/config
│   ├── starship/.config/starship.toml
│   └── tmux/.config/tmux/
├── themes/
│   ├── palettes/               # color variables per theme
│   └── templates/              # tool configs with ${VAR} placeholders
├── theme/                      # generated output (gitignored)
├── user/                       # personal overrides (gitignored)
│   ├── zsh/user.zsh
│   ├── git/user.gitconfig
│   ├── ghostty/user.conf
│   ├── nvim/.config/nvim/          # full nvim config (lives in user/nvim/)
│   ├── tmux/user.conf
│   ├── bin/                    # user scripts (added to PATH)
│   └── meta.sh
├── user.example/               # template for user/
├── scripts/                    # install/update/theme logic
├── bin/slicker                 # CLI entry point (added to PATH)
└── Brewfile
```

## CLI

```bash
slicker install              # Full setup: brew, stow, user config
slicker update               # Pull + sync new user configs + re-stow
slicker update --skip-user   # Same but skip user config sync
slicker user init [repo-url] # Clone or initialize user config
slicker user edit            # Open user/ in $EDITOR
slicker theme list           # List available themes
slicker theme set <name>     # Generate theme from palette + templates
slicker theme current        # Show current theme
slicker status               # Show config info
```

## The Two-Layer Pattern

Each config type uses its tool's native include mechanism:

| Config   | Base file                        | How it loads user overrides         |
|----------|----------------------------------|-------------------------------------|
| zsh      | `configs/zsh/.zshrc`             | `source user/zsh/user.zsh`          |
| zsh plugins | `configs/zsh/plugins.txt`     | `cat … user/zsh/plugins.txt` → `antidote load` |
| git      | `configs/git/.gitconfig`         | `[include] path = ...user.gitconfig`|
| ghostty  | `configs/ghostty/config`         | `config-file = ...user.conf`        |
| neovim   | `configs/nvim/.config/nvim` → `user/nvim/` | Entirely in user/ (stow symlinks through) |
| starship | `configs/starship/.config/starship.toml` | `STARSHIP_CONFIG` env var in user.zsh |
| tmux     | `configs/tmux/.config/tmux/`     | `source-file -q ...user.conf`       |
| claude   | `configs/claude/.claude/` (per-item symlinks) | Entirely in `user/claude/` (skills, commands, agents, hooks, settings.json) |

All includes fail silently if the user file doesn't exist.

## Themes

Themes are generated from palettes. Each palette is a shell file with color variables:

```bash
# themes/palettes/catppuccin-mocha.sh
THEME_ACCENT="#b4befe"
THEME_BG="#1e1e2e"
THEME_FG="#cdd6f4"
...
```

Templates in `themes/templates/` use `${THEME_*}` placeholders. Running `slicker theme set <name>` generates tool-specific configs into `theme/`.

Built-in themes: catppuccin-mocha, tokyo-night, rose-pine.

## Documentation

Detailed docs in [`docs/`](docs/):

- [Overview](docs/overview.md) — architecture and how things fit together
- [Install](docs/install.md) — what `slicker install` does step by step
- [Update](docs/update.md) — what `slicker update` does, `--skip-user` flag
- [User Config](docs/user-config.md) — user/ structure, meta.sh, nvim, private repos
- [Themes](docs/themes.md) — palettes, templates, custom themes
- [ZSH](docs/zsh.md) — shell config load order, aliases, functions
- [Adding a Tool](docs/adding-tool.md) — how to add a new tool config

## License

MIT
