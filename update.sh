#!/usr/bin/env bash
set -euo pipefail

# ─── Slicker Update ──────────────────────────────────────────────────
# Pull latest slicker configs + re-stow. Never touches user/.

SLICKER_DIR="$(cd "$(dirname "$0")" && pwd)"

exec "$SLICKER_DIR/bin/slicker" update
