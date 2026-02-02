#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-latest}"
MIN_NODE_VERSION=18
FEATURE_NAME="Claude Code"

# Validates version string format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^(latest|stable|alpha|lts|[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?|[0-9]+\.[0-9]+|[0-9]+)$ ]]; then
        echo "ERROR: Invalid version format: $version"
        echo "Use 'latest', 'stable', 'alpha', 'lts', or a semver version (e.g., '1.2.3')"
        exit 1
    fi
}

# Validates Node.js and npm are installed and meet minimum version
check_node_version() {
    if ! command -v node &> /dev/null; then
        echo "ERROR: Node.js is not installed."
        echo "Please include the 'node' feature in your devcontainer.json or install Node.js in your Dockerfile."
        exit 1
    fi

    if ! command -v npm &> /dev/null; then
        echo "ERROR: npm is not installed."
        echo "Please ensure npm is available alongside Node.js."
        exit 1
    fi

    local current_version
    current_version=$(node --version | sed 's/v//')
    local current_major
    current_major=$(echo "$current_version" | cut -d. -f1)

    if ! [[ "$current_major" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Could not parse Node.js version: $current_version"
        exit 1
    fi

    if [ "$current_major" -lt "$MIN_NODE_VERSION" ]; then
        echo "ERROR: $FEATURE_NAME requires Node.js ${MIN_NODE_VERSION}+, but found v${current_version}."
        echo "Please update your Dockerfile or configure the 'node' feature with version ${MIN_NODE_VERSION} or higher."
        exit 1
    fi

    echo "Node.js v${current_version} detected (meets minimum requirement of ${MIN_NODE_VERSION}+)"
}

# Verifies CLI binary is accessible and creates symlink if needed
verify_cli_installation() {
    local binary_name="$1"
    local npm_global_bin
    npm_global_bin="$(npm prefix -g)/bin"

    if command -v "$binary_name" &> /dev/null; then
        echo "$binary_name CLI found at: $(command -v "$binary_name")"
        return 0
    elif [ -x "$npm_global_bin/$binary_name" ]; then
        echo "$binary_name CLI found at: $npm_global_bin/$binary_name"
        ln -sf "$npm_global_bin/$binary_name" "/usr/local/bin/$binary_name"
        return 0
    else
        echo "ERROR: $binary_name CLI not found after install."
        echo "DEBUG: npm prefix -g = $(npm prefix -g 2>/dev/null || echo 'failed')"
        echo "DEBUG: Contents of $npm_global_bin:"
        ls -la "$npm_global_bin" 2>/dev/null || echo "Directory not found"
        return 1
    fi
}

check_node_version

echo "Installing Claude Code..."

validate_version "$VERSION"

if [ "$VERSION" = "latest" ]; then
    npm install -g --no-fund --no-audit @anthropic-ai/claude-code
else
    npm install -g --no-fund --no-audit @anthropic-ai/claude-code@"$VERSION"
fi

if ! verify_cli_installation "claude"; then
    echo "ERROR: Feature \"$FEATURE_NAME\" (Unknown) failed to install! Look at the documentation at https://github.com/anthropics/claude-code for help troubleshooting this error."
    exit 1
fi

echo "Claude Code installed successfully!"
