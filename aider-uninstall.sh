#!/bin/bash
#
# Aider & UV Uninstaller
# Completely removes Aider AI, UV package manager binaries, receipts, configs, and shell env script sources.

set -e

echo "Uninstalling Aider & UV..."

# 1. Terminate running processes
echo "  Stopping background processes..."
pkill -9 -f aider 2>/dev/null || true
pkill -9 -x uv 2>/dev/null || true
pkill -9 -x uvx 2>/dev/null || true

# 2. Try uninstalling via tools if present
if command -v uv >/dev/null 2>&1; then
    uv tool uninstall aider-chat 2>/dev/null || true
fi
if command -v pip >/dev/null 2>&1; then
    pip uninstall -y aider-chat 2>/dev/null || true
fi
if command -v pip3 >/dev/null 2>&1; then
    pip3 uninstall -y aider-chat 2>/dev/null || true
fi
if command -v pipx >/dev/null 2>&1; then
    pipx uninstall aider-chat 2>/dev/null || true
fi

# 3. Remove binaries and env scripts across all common system & user locations
echo "  Removing binaries and env scripts..."
SEARCH_PATHS=(
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "${XDG_BIN_HOME:-}"
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "$HOME/bin"
    "$HOME/.bin"
)

# Expand python user bin directories (e.g. ~/Library/Python/*/bin)
for py_bin in "$HOME/Library/Python"/*/bin; do
    [ -d "$py_bin" ] && SEARCH_PATHS+=("$py_bin")
done

for dir in "${SEARCH_PATHS[@]}"; do
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        rm -f "$dir/aider" "$dir/uv" "$dir/uvx" "$dir/env" "$dir/env.fish" 2>/dev/null || true
    fi
done

# 4. Remove fish env integration
rm -f "$HOME/.config/fish/conf.d/uv.env.fish" "$HOME/.config/fish/conf.d/aider.env.fish" 2>/dev/null || true

# 5. Remove directories, caches, and config files
echo "  Deleting configuration and data directories..."
rm -rf "$HOME/.config/uv" "$HOME/.local/share/uv" "$HOME/.cache/uv" 2>/dev/null || true
rm -rf "$HOME/.aider" 2>/dev/null || true
rm -f "$HOME/.aider.conf.yml" "$HOME/.aider.model.settings.yml" "$HOME/.aider.model.metadata.json" 2>/dev/null || true

# 6. Clean shell profiles sourcing the env script
clean_env_source() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    if grep -qs -E '(\.|\bsource\b).*/(env|uv\.env\.fish)' "$rc" 2>/dev/null; then
        echo "  Cleaning $rc..."
        local tmp="$rc.tmp.$$"
        sed -E '/(\.|\bsource\b).*\/(env|uv\.env\.fish)/d' "$rc" > "$tmp" && mv "$tmp" "$rc"
    fi
}

for rc in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.config/fish/config.fish"; do
    clean_env_source "$rc"
done

echo "Aider & UV have been completely removed from your system."
