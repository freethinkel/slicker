# ─── Slicker Functions ────────────────────────────────────────────────

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Quick find file by name
ff() {
    find . -type f -name "*$1*" 2>/dev/null
}
