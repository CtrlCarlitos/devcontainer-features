#!/bin/bash
set -euo pipefail

FONT_DIR="/usr/local/share/fonts"
VERSION="${VERSION:-3.4.0}"
FONTS="${FONTS:-Meslo}"
MAX_RETRIES=3

# Track temporary files created by this script
TEMP_FILES=()

# Cleanup temporary files on exit
cleanup() {
    for file in "${TEMP_FILES[@]}"; do
        rm -f "$file" 2>/dev/null || true
    done
}
trap cleanup EXIT

# Validates version string format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^(latest|[0-9]+\.[0-9]+\.[0-9]+|[0-9]+\.[0-9]+)$ ]]; then
        echo "ERROR: Invalid version format: $version"
        echo "Use 'latest' or a semver version (e.g., '3.4.0', '3.3')"
        exit 1
    fi
}

require_apt() {
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "ERROR: apt-get not found. This feature supports Debian/Ubuntu base images only."
        exit 1
    fi
}

# Retries curl download with exponential backoff
curl_with_retry() {
    local url="$1"
    local output="$2"
    local attempt=1
    local delay=5

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Downloading (attempt $attempt/$MAX_RETRIES)..."
        if curl -fsSL -o "$output" "$url"; then
            return 0
        fi
        if [ $attempt -lt $MAX_RETRIES ]; then
            echo "Download failed, retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done

    echo "ERROR: Failed to download after $MAX_RETRIES attempts"
    return 1
}

validate_version "$VERSION"

echo "Installing Nerd Fonts (Version: ${VERSION})..."

# Ensure dependencies
require_apt
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends unzip fontconfig curl
rm -rf /var/lib/apt/lists/*

# Create directory
mkdir -p "$FONT_DIR"

# Resolve latest version if requested
if [ "$VERSION" = "latest" ]; then
    echo "Resolving latest Nerd Fonts release..."
    # Use redirect URL to avoid GitHub API rate limits (403)
    # Redirects to https://github.com/ryanoasis/nerd-fonts/releases/tag/vX.Y.Z
    LATEST_URL=$(curl -fsSL -I -o /dev/null -w "%{url_effective}" https://github.com/ryanoasis/nerd-fonts/releases/latest)
    
    # Extract version from URL (remove 'v' prefix if present)
    VERSION=$(echo "$LATEST_URL" | sed 's|.*/tag/v\{0,1\}||')

    if [ -z "$VERSION" ] || [ "$VERSION" = "latest" ]; then
        echo "ERROR: Unable to resolve latest Nerd Fonts version from URL: $LATEST_URL"
        exit 1
    fi
    echo "Resolved latest version: ${VERSION}"
fi

# Split comma-separated fonts into array
IFS=',' read -ra FONT_LIST <<< "$FONTS"

for FONT_NAME in "${FONT_LIST[@]}"; do
    # Trim whitespace
    FONT_NAME=$(echo "$FONT_NAME" | xargs)

    if [ -z "$FONT_NAME" ]; then
        continue
    fi

    if ! [[ "$FONT_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo "ERROR: Invalid font name '${FONT_NAME}'. Use Nerd Fonts zip file names (letters, numbers, '.', '_' or '-')."
        exit 1
    fi

    echo "Processing font: $FONT_NAME"
    # Sanitize VERSION to prevent path traversal
    SAFE_VERSION=$(echo "$VERSION" | sed 's/[\/\\]/_/g; s/\.\./_/g')
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${SAFE_VERSION}/${FONT_NAME}.zip"

    if [ "$SAFE_VERSION" != "$VERSION" ]; then
        echo "WARNING: Version sanitized for security: '$VERSION' -> '$SAFE_VERSION'" >&2
    fi

    # Download with retry
    FONT_ZIP="/tmp/${FONT_NAME}-$$-${RANDOM}.zip"
    TEMP_FILES+=("$FONT_ZIP")
    echo "Downloading ${FONT_NAME} from ${FONT_URL}..."
    if ! curl_with_retry "$FONT_URL" "$FONT_ZIP"; then
        echo "ERROR: Failed to download ${FONT_NAME}.zip. Check version and font name."
        exit 1
    fi

    echo "Extracting ${FONT_NAME}..."
    unzip -o "$FONT_ZIP" -d "$FONT_DIR"
    rm -f "$FONT_ZIP"
    # Remove from tracking since we already deleted it
    TEMP_FILES=("${TEMP_FILES[@]/$FONT_ZIP}")
done

# Clean up generic junk usually in these zips
rm -f "$FONT_DIR/"*Windows* "$FONT_DIR/"*Linux* "$FONT_DIR/"*Compatible* "$FONT_DIR/"LICENSE "$FONT_DIR/"readme.md 2>/dev/null || true

# Update cache
echo "Updating font cache..."
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f -v
else
    echo "Warning: fc-cache not found, skipping cache update."
fi

echo "Nerd Fonts installed!"
