#!/bin/bash
set -e

VERSION="${VERSION:-22}"

echo "Node.js Feature: Checking installation..."

# Check if Node.js is already installed
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node --version | sed 's/v//')
    CURRENT_MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
    echo "Node.js v${CURRENT_VERSION} is already installed (major version: ${CURRENT_MAJOR})"
    echo "Skipping installation. Individual tool features will validate version compatibility."
    exit 0
fi

echo "Node.js not found. Installing version ${VERSION}..."

# Install dependencies
apt-get update
apt-get install -y curl ca-certificates

# Set up nvm directory
NVM_DIR="/usr/local/share/nvm"
mkdir -p "$NVM_DIR"

# Install nvm
export NVM_DIR
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install requested Node.js version
nvm install "$VERSION"
nvm alias default "$VERSION"
nvm use default

# Create symlinks for global access
ln -sf "$NVM_DIR/versions/node/$(nvm current)/bin/node" /usr/local/bin/node
ln -sf "$NVM_DIR/versions/node/$(nvm current)/bin/npm" /usr/local/bin/npm
ln -sf "$NVM_DIR/versions/node/$(nvm current)/bin/npx" /usr/local/bin/npx

# Verify installation
INSTALLED_VERSION=$(node --version)
echo "Node.js ${INSTALLED_VERSION} installed successfully!"
