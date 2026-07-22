#!/bin/bash
#
# Amp CLI Uninstaller
# Completely removes Amp CLI binaries, configuration, symlinks, and shell profile integration.

set -e

echo "Uninstalling Amp CLI..."

# 1. Terminate running amp processes
echo "  Stopping background processes..."
pkill -9 -x amp 2>/dev/null || true
pkill -9 -f "amp " 2>/dev/null || true

# 2. Remove symlinks/binaries across all candidate PATH directories
echo "  Removing binary symlinks..."
SEARCH_PATHS=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.bin"
    "/opt/homebrew/bin"
    "/usr/local/bin"
)

for dir in "${SEARCH_PATHS[@]}"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        rm -f "$dir/amp" 2>/dev/null || true
    elif [ -e "$dir/amp" ]; then
        echo "  Removing $dir/amp (requires sudo)..."
        sudo rm -f "$dir/amp" 2>/dev/null || true
    fi
done

# 3. Remove Amp home directory (~/.amp)
if [ -d "$HOME/.amp" ]; then
    echo "  Deleting $HOME/.amp directory..."
    rm -rf "$HOME/.amp"
fi

# 4. Clean shell profile integration (# Amp CLI block or PATH exports added for amp)
clean_profile() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    if grep -qs "# Amp CLI" "$rc" 2>/dev/null; then
        echo "  Cleaning $rc..."
        local tmp="$rc.tmp.$$"
        awk '
            /# Amp CLI/ { skip=1; next }
            skip && /PATH=.*\.local\/bin/ { skip=0; next }
            skip && /fish_add_path.*\.local\/bin/ { skip=0; next }
            !skip { print }
        ' "$rc" > "$tmp" && mv "$tmp" "$rc"
    fi
}

for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.config/fish/config.fish"; do
    clean_profile "$rc"
done

echo "Amp CLI has been completely removed from your system."
