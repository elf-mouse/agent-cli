#!/bin/bash
#
# Factory Droid CLI Uninstaller
# Completely removes Droid CLI binary, configuration, cache, and shell integration.

set -e

echo "Uninstalling Factory Droid CLI..."

# 1. Terminate running droid processes
echo "  Stopping background processes..."
pkill -9 -x droid 2>/dev/null || true
pkill -9 -f "droid " 2>/dev/null || true

# 2. Remove binaries across all candidate PATH directories
echo "  Removing droid binary..."
SEARCH_PATHS=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/.bin"
    "/opt/homebrew/bin"
    "/usr/local/bin"
)

for dir in "${SEARCH_PATHS[@]}"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        rm -f "$dir/droid" 2>/dev/null || true
    elif [ -e "$dir/droid" ]; then
        echo "  Removing $dir/droid (requires sudo)..."
        sudo rm -f "$dir/droid" 2>/dev/null || true
    fi
done

# 3. Remove Factory CLI config and state directories (~/.factory and ~/.droid if present)
echo "  Deleting Factory configuration and cache directories..."
rm -rf "$HOME/.factory" "$HOME/.droid" 2>/dev/null || true

# 4. Clean any PATH entries added to shell profile
clean_profile() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    if grep -qs -E 'export PATH=.*\.local/bin' "$rc" 2>/dev/null && grep -qs 'droid' "$rc" 2>/dev/null; then
        echo "  Cleaning $rc..."
        local tmp="$rc.tmp.$$"
        sed -E '/export PATH=.*\.local\/bin:\$PATH.*#.*droid/d' "$rc" > "$tmp" && mv "$tmp" "$rc"
    fi
}

for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.config/fish/config.fish"; do
    clean_profile "$rc"
done

echo "Factory Droid CLI has been completely removed from your system."
