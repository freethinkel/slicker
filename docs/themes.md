# Themes

Slicker supports theme generation from palettes.

## How It Works

A theme = palette + templates.

**Palette** — a shell file with color variables:

```bash
# themes/palettes/catppuccin-mocha.sh
THEME_ACCENT="#b4befe"
THEME_BG="#1e1e2e"
THEME_FG="#cdd6f4"
```

**Templates** — config files with `${THEME_*}` placeholders in `themes/templates/`. During generation, variables are substituted and the result is written to `theme/`.

## Commands

```bash
slicker theme list           # list available themes
slicker theme set <name>     # generate theme
slicker theme current        # show current theme
```

## Priority

User palettes (`user/themes/palettes/`) take priority over base palettes. Same for templates — if `user/themes/templates/` exists, it's used instead of the base one.

## Built-in Themes

catppuccin-mocha, tokyo-night, rose-pine.

## Adding a Theme

1. Create `themes/palettes/<name>.sh` (or `user/themes/palettes/<name>.sh` for private)
2. Define the required `THEME_*` variables
3. Run `slicker theme set <name>`
