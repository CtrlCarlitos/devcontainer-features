#!/bin/bash
set -e

FONT_DIR="/usr/local/share/fonts"
VERSION="${VERSION:-3.4.0}"
FONTS="${FONTS:-Meslo}"

echo "Installing Nerd Fonts (Version: ${VERSION})..."

# Ensure dependencies
if ! command -v unzip >/dev/null 2>&1; then
    echo "Installing unzip..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y unzip
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache unzip
    else
        echo "Warning: package manager not found. Assuming unzip is available."
    fi
fi

if ! command -v fc-cache >/dev/null 2>&1; then
    echo "Installing fontconfig..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y fontconfig
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache fontconfig
    fi
fi

# Create directory
mkdir -p "$FONT_DIR"

# Split comma-separated fonts into array
IFS=',' read -ra FONT_LIST <<< "$FONTS"

for FONT_NAME in "${FONT_LIST[@]}"; do
    # Trim whitespace
    FONT_NAME=$(echo "$FONT_NAME" | xargs)
    
    if [ -z "$FONT_NAME" ]; then
        continue
    fi

    echo "Processing font: $FONT_NAME"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${VERSION}/${FONT_NAME}.zip"

    # Download and unzip
    echo "Downloading ${FONT_NAME} from ${FONT_URL}..."
    if command -v curl >/dev/null 2>&1; then
        curl -L -f -o "/tmp/${FONT_NAME}.zip" "$FONT_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "/tmp/${FONT_NAME}.zip" "$FONT_URL"
    else
        echo "Error: neither curl nor wget found."
        exit 1
    fi

    if [ ! -f "/tmp/${FONT_NAME}.zip" ]; then
         echo "Error: Failed to download ${FONT_NAME}.zip. Check version and font name."
         # Don't exit here, maybe other fonts work? Or should we strict fail? 
         # Let's strict fail to alert user of config error
         exit 1
    fi

    echo "Extracting ${FONT_NAME}..."
    unzip -o "/tmp/${FONT_NAME}.zip" -d "$FONT_DIR"
    rm "/tmp/${FONT_NAME}.zip"
done

# Clean up generic junk usually in these zips
rm -f "$FONT_DIR/"*Windows* "$FONT_DIR/"*Linux* "$FONT_DIR/"*Compatible* "$FONT_DIR/"LICENSE "$FONT_DIR/"readme.md

# Update cache
echo "Updating font cache..."
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f -v
else
    echo "Warning: fc-cache not found, skipping cache update."
fi

echo "Nerd Fonts installed!"
