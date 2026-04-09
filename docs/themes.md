# Themes

Slicker supports per-tool theming with color palettes and templates.

## How It Works

Each theme is a subdirectory in `themes/` containing:

```
themes/
  tokyo-night/
    colors.toml       # color palette (hex colors)
    neovim.lua        # neovim theme plugin spec
  templates/
    ghostty.conf.tpl  # ghostty template with {{ variable }} placeholders
    tmux.conf.tpl     # tmux template
```

`slicker theme set <name>`:

1. Copies theme files (colors.toml, neovim.lua, etc.) into `theme/`
2. Generates config files from `templates/*.tpl` by substituting `{{ variable }}` placeholders with values from `colors.toml`
3. Theme-specific files take priority over generated ones

## colors.toml Format

```toml
accent = "#7aa2f7"
cursor = "#c0caf5"
foreground = "#a9b1d6"
background = "#1a1b26"
selection_foreground = "#c0caf5"
selection_background = "#7aa2f7"

color0 = "#32344a"
color1 = "#f7768e"
...
color15 = "#acb0d0"
```

## Template Placeholders

Templates use `{{ key }}` syntax. Available modifiers:

- `{{ accent }}` — hex value (`#7aa2f7`)
- `{{ accent_strip }}` — without `#` prefix (`7aa2f7`)
- `{{ accent_rgb }}` — decimal RGB (`122,162,247`)

## Commands

```bash
slicker theme list           # list available themes
slicker theme set <name>     # apply theme
slicker theme current        # show current theme
```

## Priority

User themes (`user/themes/<name>/`) overlay base themes. User templates (`user/themes/templates/`) override base templates.

## Built-in Themes

catppuccin, catppuccin-latte, ethereal, everforest, flexoki-light, gruvbox, hackerman, kanagawa, lumon, matte-black, miasma, nord, osaka-jade, retro-82, ristretto, rose-pine, tokyo-night, vantablack, white.

## Adding a Theme

1. Create `themes/<name>/` directory
2. Add `colors.toml` with hex color palette
3. Add `neovim.lua` with theme plugin spec
4. Run `slicker theme set <name>`
