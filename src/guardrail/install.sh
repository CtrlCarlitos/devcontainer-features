#!/bin/bash
set -euo pipefail

echo "Guardrail Feature"

VERSION="${VERSION:-v0.18.0-dev}"
ASSET="guardrail_linux_amd64.exe"
BASE_URL="https://github.com/CtrlCarlitos/agent-guardrails/releases/download/${VERSION}"
INSTALL_PATH="/usr/local/bin/guardrail"

# Idempotent: skip if already installed at the default pin (an explicit
# version override forces a reinstall)
if [ -x "$INSTALL_PATH" ] && [ "$VERSION" = "v0.18.0-dev" ]; then
    echo "Guardrail already installed at $INSTALL_PATH. Skipping."
    echo "  (set the 'version' option to force a reinstall/upgrade)"
    exit 0
fi

TMP_DIR=$(mktemp -d /tmp/guardrail-install-XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading Guardrail ${VERSION}..."
curl -fsSL --connect-timeout 15 --max-time 300 -o "$TMP_DIR/$ASSET" "${BASE_URL}/${ASSET}"

echo "Downloading SHA256SUMS..."
curl -fsSL --connect-timeout 15 --max-time 300 -o "$TMP_DIR/SHA256SUMS" "${BASE_URL}/SHA256SUMS"

echo "Verifying checksum..."
EXPECTED=$(awk -v asset="$ASSET" '$NF == asset {print $1}' "$TMP_DIR/SHA256SUMS")
if [ -z "$EXPECTED" ]; then
    echo "ERROR: no checksum entry for $ASSET in SHA256SUMS."
    exit 1
fi
ACTUAL=$(sha256sum "$TMP_DIR/$ASSET" | awk '{print $1}')
if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "ERROR: checksum mismatch for $ASSET."
    echo "  expected: $EXPECTED"
    echo "  actual:   $ACTUAL"
    exit 1
fi
echo "Checksum OK ($ACTUAL)"

# COPY, not symlink: the release binary must live at a stable path that
# persists across Docker layers.
cp "$TMP_DIR/$ASSET" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
echo "Copied binary -> $INSTALL_PATH"

# Final verification — the test depends on this
if [ -x "$INSTALL_PATH" ]; then
    echo "Guardrail installed successfully!"
else
    echo "ERROR: guardrail binary not found at $INSTALL_PATH."
    exit 1
fi
