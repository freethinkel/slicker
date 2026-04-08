# Adding a New Tool

How to add a new tool config to Slicker.

## Steps

### 1. Create a stow package

Create `configs/<tool>/` with files mirroring the target layout relative to `$HOME`.

Examples:
- File in `$HOME`: `configs/<tool>/.mytoolrc`
- File in `~/.config/`: `configs/<tool>/.config/<tool>/config`

### 2. Add a user include

At the end of the base config, add a silent include of the user override. The mechanism depends on the tool:

```bash
# shell-like
[[ -f "$SLICKER_ROOT/user/<tool>/user.conf" ]] && source "$SLICKER_ROOT/user/<tool>/user.conf"

# gitconfig-like
[include]
  path = ~/.slicker-user/<tool>/user.conf

# ghostty-like
config-file = ~/.slicker-user/<tool>/user.conf
```

The include must fail silently if the file doesn't exist.

### 3. Create user.example

Create `user.example/<tool>/` with a template for the user config. This directory is copied into `user/` on first install and during update (if `user/<tool>/` doesn't exist yet).

### 4. Add to stow

Add `<tool>` to the stow command in three places:
- `scripts/install.sh` — the `stow -v -t` line
- `scripts/update.sh` — the `stow -v -R -t` line
- `scripts/status.sh` — the `for pkg in ...` loop

### 5. Add to backup

If the tool creates a config in a standard location, add the path to the `targets` array in `scripts/backup.sh`.

### 6. Add to Brewfile

If the tool is installed via Homebrew, add `brew "<tool>"` to `Brewfile`.

### 7. Documentation

Add a row to the two-layer pattern table in `README.md`.
