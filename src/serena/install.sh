#!/bin/bash
set -euo pipefail

echo "Serena Agent Feature"

# Idempotent: skip if already installed
if [ -x /usr/local/bin/serena ]; then
    echo "Serena already installed at /usr/local/bin/serena. Skipping."
    exit 0
fi

# Make sure ~/.local/bin is visible even in minimal install shells
export PATH="${HOME}/.local/bin:${PATH}"

# 1. Install uv (Astral) if missing
if ! command -v uv &> /dev/null; then
    echo "Installing uv package manager..."
    INSTALLER=$(mktemp /tmp/uv-install-XXXXXX.sh)
    curl -fsSL --connect-timeout 15 --max-time 300 https://astral.sh/uv/install.sh -o "$INSTALLER"
    bash "$INSTALLER"
    rm -f "$INSTALLER"
    export PATH="${HOME}/.local/bin:${PATH}"
else
    echo "uv already installed at $(command -v uv)"
fi

# 2. Install serena-agent into an isolated uv tool env (Python 3.13,
#    downloaded/managed by uv if the system lacks it)
echo "Installing serena-agent via uv tool..."
uv tool install -p 3.13 serena-agent

# 3. uv puts the launcher in ~/.local/bin. Devcontainer test shells don't
#    see that PATH and /root/.local doesn't persist across Docker layers,
#    so COPY the binary to /usr/local/bin (always on PATH).
SERENA_BIN="${HOME}/.local/bin/serena"

if [ -f "$SERENA_BIN" ]; then
    cp "$SERENA_BIN" /usr/local/bin/serena
    chmod +x /usr/local/bin/serena
    echo "Copied $SERENA_BIN -> /usr/local/bin/serena"
fi

# Final verification — the test depends on this
if [ -x /usr/local/bin/serena ]; then
    echo "Serena installed successfully!"
else
    echo "ERROR: serena binary not found after installation."
    echo "  Checked: $SERENA_BIN, /usr/local/bin/serena"
    echo "  Try running 'uv tool install -p 3.13 serena-agent' manually to inspect."
    exit 1
fi
