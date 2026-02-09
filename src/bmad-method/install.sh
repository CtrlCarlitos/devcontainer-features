#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
MIN_NODE_VERSION=20
FEATURE_NAME="BMad Method"
MAX_RETRIES=3

# Validates version string format
validate_version() {
    local version="$1"
    # Empty version is allowed (will install latest via npm)
    [ -z "$version" ] && return 0
    # Supports: keywords, semver (X.Y.Z), semver with prerelease (X.Y.Z-Beta.5), major.minor, major
    if [[ ! "$version" =~ ^(latest|stable|alpha|lts|[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*)?|[0-9]+\.[0-9]+|[0-9]+)$ ]]; then
        echo "ERROR: Invalid version format: $version"
        echo "Use 'latest', 'stable', 'alpha', 'lts', or a semver version (e.g., '1.2.3')"
        exit 1
    fi
}

# Retries npm install with exponential backoff
npm_install_with_retry() {
    local package="$1"
    local attempt=1
    local delay=5

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Installing $package (attempt $attempt/$MAX_RETRIES)..."
        if npm install -g --no-fund --no-audit --ignore-scripts "$package"; then
            return 0
        fi
        if [ $attempt -lt $MAX_RETRIES ]; then
            echo "Install failed, retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done

    echo "ERROR: Failed to install $package after $MAX_RETRIES attempts"
    return 1
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

echo "Installing BMad Method..."

validate_version "$VERSION"

if [ -z "$VERSION" ]; then
    # Empty version means "use the latest default from devcontainer-feature.json"
    # This allows devcontainer CLI to pass the configured default
    npm_install_with_retry "bmad-method@latest"
elif [ "$VERSION" = "stable" ] || [ "$VERSION" = "latest" ]; then
    npm_install_with_retry "bmad-method@latest"
elif [ "$VERSION" = "alpha" ]; then
    npm_install_with_retry "bmad-method@alpha"
else
    npm_install_with_retry "bmad-method@$VERSION"
fi

# Verify installation - bmad-method provides both 'bmad' and 'bmad-method' binaries
if verify_cli_installation "bmad"; then
    : # Success
elif verify_cli_installation "bmad-method"; then
    : # Success with alternate binary name
else
    echo "ERROR: Feature \"$FEATURE_NAME\" (Unknown) failed to install! Look at the documentation at https://github.com/bmad-code-org/BMAD-METHOD for help troubleshooting this error."
    exit 1
fi

echo "BMad Method installed successfully!"
echo "Run 'npx bmad-method install' in your project to set it up."
