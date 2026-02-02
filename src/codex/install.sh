#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-latest}"
MIN_NODE_VERSION=22

# Validate Node.js version
check_node_version() {
    if ! command -v node &> /dev/null; then
        echo "ERROR: Node.js is not installed."
        echo "Please include the 'node' feature in your devcontainer.json or install Node.js in your Dockerfile."
        exit 1
    fi

    CURRENT_VERSION=$(node --version | sed 's/v//')
    CURRENT_MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)

    if [ "$CURRENT_MAJOR" -lt "$MIN_NODE_VERSION" ]; then
        echo "ERROR: Codex requires Node.js ${MIN_NODE_VERSION}+, but found v${CURRENT_VERSION}."
        echo "Please update your Dockerfile or configure the 'node' feature with version ${MIN_NODE_VERSION} or higher."
        exit 1
    fi

    echo "Node.js v${CURRENT_VERSION} detected (meets minimum requirement of ${MIN_NODE_VERSION}+)"
}

check_node_version

echo "Installing Codex..."

if [ "$VERSION" = "latest" ]; then
    npm install -g --no-fund --no-audit @openai/codex
else
    npm install -g --no-fund --no-audit @openai/codex@"$VERSION"
fi

echo "Codex installed successfully!"
