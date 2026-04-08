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
│   ├── nvim/.config/nvim/
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
│   ├── nvim/lua/user/plugins/
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
slicker update               # Pull latest configs + re-stow (never touches user/)
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
| git      | `configs/git/.gitconfig`         | `[include] path = ...user.gitconfig`|
| ghostty  | `configs/ghostty/config`         | `config-file = ...user.conf`        |
| neovim   | `configs/nvim/.config/nvim/`     | `{ import = "user.plugins" }`       |
| starship | `configs/starship/.config/starship.toml` | `STARSHIP_CONFIG` env var in user.zsh |
| tmux     | `configs/tmux/.config/tmux/`     | `source-file -q ...user.conf`       |

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

## Adding New Configs

1. Create `configs/<tool>/` with files mirroring target layout relative to `$HOME`
2. End base config with a silent include of `user/<tool>/user.conf`
3. Create `user.example/<tool>/user.conf` as a template
4. Add `<tool>` to the stow command in `scripts/install.sh`

## License

MIT
