#!/bin/bash
set -euo pipefail

echo "Playwright Feature"

BROWSER="${BROWSER:-chromium}"

# Ensure Node.js is available (self-contained if the node feature hasn't run)
ensure_node() {
    if command -v node &> /dev/null || [ -x /usr/local/bin/node ]; then
        return 0
    fi

    echo "  Node.js not found — installing Node 22 (self-contained)..."
    local NVM_DIR="/usr/local/share/nvm"
    mkdir -p "$NVM_DIR"
    export NVM_DIR

    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm alias default 22
    nvm use default

    local CURRENT_DIR="$NVM_DIR/versions/node/$(nvm current)"
    ln -sf "$CURRENT_DIR/bin/node" /usr/local/bin/node
    ln -sf "$CURRENT_DIR/bin/npm" /usr/local/bin/npm
    ln -sf "$CURRENT_DIR/bin/npx" /usr/local/bin/npx
    echo "  Node.js $(node --version) installed."
}

ensure_node
export PATH="/usr/local/bin:$PATH"

# Install playwright globally
echo "Installing playwright npm package..."
npm install -g playwright

# Link the CLI to /usr/local/bin (npm global bin isn't always on PATH
# in devcontainer test shells)
PLAYWRIGHT_BIN="$(command -v playwright 2>/dev/null || true)"
if [ -z "$PLAYWRIGHT_BIN" ]; then
    NPM_GLOBAL_BIN="$(npm prefix -g 2>/dev/null)/bin"
    [ -e "$NPM_GLOBAL_BIN/playwright" ] && PLAYWRIGHT_BIN="$NPM_GLOBAL_BIN/playwright"
fi
if [ -n "$PLAYWRIGHT_BIN" ] && [ ! -e /usr/local/bin/playwright ]; then
    ln -sf "$(readlink -f "$PLAYWRIGHT_BIN" 2>/dev/null || echo "$PLAYWRIGHT_BIN")" /usr/local/bin/playwright
fi

# Install the browser (default: chromium) to a shared path so it works
# for all users (root installs it during build; vscode user uses it at runtime)
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/ms-playwright"
echo "Installing $BROWSER browser to $PLAYWRIGHT_BROWSERS_PATH..."
npx --yes playwright install "$BROWSER"

# Install system dependencies for headless operation (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    echo "Installing system dependencies for headless $BROWSER..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    npx playwright install-deps "$BROWSER" 2>/dev/null || echo "  (deps install non-critical; browser may need additional libraries)"
    rm -rf /var/lib/apt/lists/*
fi

echo "Playwright + $BROWSER installed successfully!"
echo "  Browser cache: ~/.cache/ms-playwright (~170MB for chromium)"
