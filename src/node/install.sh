#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-22}"

echo "Node.js Feature: Checking installation..."

require_apt() {
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "ERROR: apt-get not found. This feature supports Debian/Ubuntu base images only."
        exit 1
    fi
}

ensure_node_version() {
    if ! command -v node &> /dev/null; then
        return 1
    fi

    CURRENT_VERSION=$(node --version | sed 's/v//')
    CURRENT_MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
    echo "Node.js v${CURRENT_VERSION} is already installed (major version: ${CURRENT_MAJOR})"

    if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
        if [ "$CURRENT_MAJOR" -ge "$VERSION" ]; then
            echo "Installed Node.js meets requested major version ${VERSION}. Skipping installation."
            return 0
        fi
        echo "Installed Node.js is older than requested major ${VERSION}. Will install via nvm."
        return 1
    fi

    echo "Requested version is '${VERSION}'. Will install via nvm to ensure correct version."
    return 1
}

if ensure_node_version; then
    exit 0
fi

echo "Node.js not found. Installing version ${VERSION}..."

require_apt

# Install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates
rm -rf /var/lib/apt/lists/*

# Set up nvm directory
NVM_DIR="/usr/local/share/nvm"
mkdir -p "$NVM_DIR"

# Install nvm
export NVM_DIR
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install requested Node.js version
nvm install "$VERSION"
nvm alias default "$VERSION"
nvm use default

CURRENT_DIR="$NVM_DIR/versions/node/$(nvm current)"
ln -sfn "$CURRENT_DIR/bin" "$NVM_DIR/current"

# Create symlinks for global access
ln -sf "$CURRENT_DIR/bin/node" /usr/local/bin/node
ln -sf "$CURRENT_DIR/bin/npm" /usr/local/bin/npm
ln -sf "$CURRENT_DIR/bin/npx" /usr/local/bin/npx

# Verify installation
INSTALLED_VERSION=$(node --version)
echo "Node.js ${INSTALLED_VERSION} installed successfully!"
