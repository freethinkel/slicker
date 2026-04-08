#!/usr/bin/env bash
set -euo pipefail

# ─── Slicker Install ─────────────────────────────────────────────────
# Full setup: brew, stow, user config, symlinks.
# Safe to re-run — idempotent by design.

SLICKER_DIR="$(cd "$(dirname "$0")" && pwd)"

exec "$SLICKER_DIR/bin/slicker" install
