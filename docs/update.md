# slicker update

Updates configs without losing personal settings.

## Steps

### 1. Git pull

Pulls latest changes from remote. If the pull fails (conflict, no remote, dirty tree) — prints a warning and continues. This allows `update` to work even when git has issues.

### 2. Sync user configs

Iterates over directories in `user.example/` and checks whether a matching directory exists in `user/`. If not — copies it from the template. This handles the case when a new tool config is added to slicker: after `git pull`, the new template automatically appears in `user/`.

Existing user directories are never overwritten.

Use `--skip-user` to skip this step.

### 3. Re-stow

Runs `stow -R` (restow) — removes old symlinks and recreates them. Picks up any changes to the `configs/` structure.

## Usage

```bash
slicker update              # full update
slicker update --skip-user  # skip user config sync
```

## Notes

- `user/` is never overwritten, only new directories are added from the template
- A git pull failure does not abort the process
- Re-stow (`-R`) recreates all symlinks, ensuring they're up to date
