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

# Verify download integrity if hash is provided
verify_download() {
    local file="$1"
    local expected_hash="$2"
    local algorithm="${3:-sha256}"

    if [ -z "$expected_hash" ]; then
        echo "WARNING: No checksum provided. Skipping integrity verification." >&2
        return 0
    fi

    local actual_hash
    case "$algorithm" in
        sha256)
            actual_hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
            ;;
        sha1)
            actual_hash=$(sha1sum "$file" 2>/dev/null | cut -d' ' -f1)
            ;;
        md5)
            actual_hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
            ;;
        *)
            echo "ERROR: Unsupported hash algorithm: $algorithm" >&2
            return 1
            ;;
    esac

    if [ "$actual_hash" = "$expected_hash" ]; then
        return 0
    else
        echo "ERROR: $algorithm checksum mismatch!" >&2
        echo "  Expected: $expected_hash" >&2
        echo "  Actual:   $actual_hash" >&2
        return 1
    fi
}

# Install nvm (pinned version for reproducibility)
export NVM_DIR
NVM_INSTALLER="/tmp/nvm-installer-$$.sh"
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh -o "$NVM_INSTALLER"

# Optional: Set NVM_SHA256 environment variable to verify integrity
if [ -n "${NVM_SHA256:-}" ]; then
    verify_download "$NVM_INSTALLER" "$NVM_SHA256" sha256 || exit 1
else
    echo "INFO: Set NVM_SHA256 environment variable for download verification" >&2
fi

bash "$NVM_INSTALLER"
rm -f "$NVM_INSTALLER"

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install requested Node.js version with retry
MAX_RETRIES=3
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if nvm install "$VERSION"; then
        break
    else
        echo "nvm install failed, retrying in 3 seconds..."
        RETRY_COUNT=$((RETRY_COUNT+1))
        sleep 3
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "ERROR: Failed to install Node.js $VERSION after $MAX_RETRIES attempts."
    exit 1
fi

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
