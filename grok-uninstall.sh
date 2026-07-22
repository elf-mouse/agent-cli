#!/bin/bash
#
# Grok CLI Uninstaller
# Completely removes Grok CLI binaries, configuration, symlinks, and shell integration.

set -e

echo "Uninstalling Grok CLI..."

# 1. Terminate running grok/agent processes
echo "  Stopping background processes..."
pkill -9 -f grok 2>/dev/null || true
pkill -9 -f agent 2>/dev/null || true

# 2. Remove system PATH symlinks across all candidate locations
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
        rm -f "$dir/grok" "$dir/agent" 2>/dev/null || true
    elif [ -e "$dir/grok" ] || [ -e "$dir/agent" ]; then
        echo "  Removing $dir symlinks (requires sudo)..."
        sudo rm -f "$dir/grok" "$dir/agent" 2>/dev/null || true
    fi
done

# 3. Remove fish shell completion
rm -f "$HOME/.config/fish/completions/grok.fish" 2>/dev/null || true

# 4. Remove ~/.grok directory
if [ -d "$HOME/.grok" ]; then
    echo "  Deleting $HOME/.grok directory..."
    rm -rf "$HOME/.grok"
fi

# 5. Clean shell profile integration blocks
clean_rc() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    if grep -qs "grok installer" "$rc" 2>/dev/null; then
        echo "  Cleaning $rc..."
        local tmp="$rc.tmp.$$"
        awk '
            /# >>> grok installer >>>/ { skip=1; next }
            /# <<< grok installer <<</ { skip=0; next }
            !skip { print }
        ' "$rc" > "$tmp" && mv "$tmp" "$rc"
    fi
}

for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.config/fish/config.fish"; do
    clean_rc "$rc"
done

echo "Grok CLI has been completely removed from your system."
