#!/bin/bash
set -euo pipefail

echo "Graft Feature"

# Ensure Node.js is available (the node feature may not have run yet in
# the Docker build ordering). If node is missing, install a minimal
# Node 22 via nvm — same approach as the node feature, but self-contained.
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

# Ensure npm is reachable
export PATH="/usr/local/bin:$(dirname "$(command -v node 2>/dev/null || echo /usr/local/bin/node)"):$PATH"

# Idempotent: skip if graft is already installed
if command -v graft &> /dev/null || [ -x /usr/local/bin/graft ]; then
    echo "graft already installed. Skipping."
    exit 0
fi

echo "Installing @nanonets/graft globally via npm..."

# tree-sitter native builds need python3 + make + g++ (node-gyp)
if command -v apt-get &> /dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y --no-install-recommends python3 make g++ > /dev/null 2>&1 || \
        echo "  (build deps install warning; native builds may fail)"
    rm -rf /var/lib/apt/lists/*
fi

npm install -g @nanonets/graft

# Find and link the binary to /usr/local/bin
GRAFT_BIN="$(command -v graft 2>/dev/null || true)"
if [ -z "$GRAFT_BIN" ]; then
    NPM_GLOBAL_BIN="$(npm prefix -g 2>/dev/null)/bin"
    [ -e "$NPM_GLOBAL_BIN/graft" ] && GRAFT_BIN="$NPM_GLOBAL_BIN/graft"
fi

if [ -n "$GRAFT_BIN" ]; then
    RESOLVED="$(readlink -f "$GRAFT_BIN" 2>/dev/null || echo "$GRAFT_BIN")"
    if [ ! -e /usr/local/bin/graft ]; then
        ln -sf "$RESOLVED" /usr/local/bin/graft
        echo "Linked $RESOLVED -> /usr/local/bin/graft"
    fi
else
    echo "ERROR: graft binary not found after npm install."
    echo "  Checked: PATH, \$(npm prefix -g)/bin/graft"
    exit 1
fi

echo "Graft installed successfully!"
