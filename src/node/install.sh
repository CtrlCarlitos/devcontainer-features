#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-22}"

echo "Node.js Feature: Checking installation..."

# Exit gracefully if Node.js is already installed
if command -v node &> /dev/null; then
    echo "Node.js $(node --version) is already installed. Skipping."
    exit 0
fi

# Validates version string format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^(latest|lts|node|[0-9]+)$ ]]; then
        echo "ERROR: Invalid version format: $version"
        echo "Use 'latest', 'lts', or a major version number (e.g., '22', '20', '18')"
        exit 1
    fi
}

validate_version "$VERSION"

require_apt() {
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "ERROR: apt-get not found. This feature supports Debian/Ubuntu base images only."
        exit 1
    fi
}

case "$VERSION" in
    latest)
        VERSION="node"
        ;;
    lts)
        VERSION="lts/*"
        ;;
esac

echo "Installing Node.js version ${VERSION}..."

require_apt

# Install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates
rm -rf /var/lib/apt/lists/*

# Set up nvm directory
NVM_DIR="/usr/local/share/nvm"
mkdir -p "$NVM_DIR"

# Install nvm (pinned version for reproducibility)
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
