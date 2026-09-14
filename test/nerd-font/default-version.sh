#!/bin/bash
set -euo pipefail

METADATA_VERSION="$(node -p "require('./src/nerd-font/devcontainer-feature.json').options.version.default")"
SCRIPT_VERSION="$(sed -n 's/^VERSION="${VERSION:-\([^}]*\)}"/\1/p' src/nerd-font/install.sh)"

if [ -z "$SCRIPT_VERSION" ]; then
    echo "Could not read Nerd Font install.sh fallback version"
    exit 1
fi

if [ "$METADATA_VERSION" != "$SCRIPT_VERSION" ]; then
    echo "Nerd Font default mismatch: metadata=$METADATA_VERSION install.sh=$SCRIPT_VERSION"
    exit 1
fi

echo "Nerd Font default version: $METADATA_VERSION"
