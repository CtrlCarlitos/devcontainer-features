#!/bin/bash
set -euo pipefail

echo "Antigravity CLI (agy) Feature"

# Idempotent: skip if already installed
if command -v agy &> /dev/null || [ -x /usr/local/bin/agy ]; then
    echo "Antigravity CLI already installed. Skipping."
    exit 0
fi

# Install via the official installer (self-contained, no Node dependency).
# Downloaded to a temp file and run separately so pipefail can't kill
# the post-install symlink step on benign installer stderr output.
echo "Installing Antigravity CLI..."
INSTALLER_URL="https://antigravity.google/cli/install.sh"
INSTALLER=$(mktemp /tmp/agy-install-XXXXXX.sh)

# The upstream CDN has intermittently answered HTTP 200 with an EMPTY body
# (CI runs 2026-09-23 08:06 and 2026-09-24 00:06). curl -f is happy with
# that, bash runs an empty file silently, and the feature fails a step later
# with "binary not found". So: retry the download, and refuse to run anything
# that is not recognisably a shell script.
fetch_installer() {
    local attempt
    for attempt in 1 2 3 4 5; do
        : > "$INSTALLER"
        if curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
                "$INSTALLER_URL" -o "$INSTALLER" \
            && [ -s "$INSTALLER" ] \
            && head -c 2 "$INSTALLER" | grep -q '^#!' ; then
            return 0
        fi
        echo "  installer download attempt $attempt unusable ($(wc -c < "$INSTALLER") bytes); retrying..."
        sleep $((attempt * 3))
    done
    return 1
}

if ! fetch_installer; then
    echo "ERROR: could not download a valid installer from $INSTALLER_URL after 5 attempts."
    rm -f "$INSTALLER"
    exit 1
fi
bash "$INSTALLER" || echo "  (installer reported non-zero; continuing to check binary)"
rm -f "$INSTALLER"

# The installer puts the binary in ~/.local/bin. Devcontainer test shells
# don't always have that on PATH, so symlink to /usr/local/bin (always on PATH).
AGY_BIN="${HOME}/.local/bin/agy"

if [ -x "$AGY_BIN" ]; then
    # COPY, not symlink: /root/.local doesn't persist across all Docker
    # layer combinations (devcontainer multi-stage builds can clobber it),
    # and a dangling symlink at /usr/local/bin is worse than a real file.
    cp "$AGY_BIN" /usr/local/bin/agy
    chmod +x /usr/local/bin/agy
    echo "Copied $AGY_BIN -> /usr/local/bin/agy"
elif [ -x /usr/local/bin/agy ]; then
    echo "agy already at /usr/local/bin/agy"
else
    # Fallback: search common locations
    for loc in /usr/bin/agy /opt/agy /opt/antigravity/bin/agy; do
        if [ -x "$loc" ]; then
            cp "$loc" /usr/local/bin/agy && chmod +x /usr/local/bin/agy
            echo "Symlinked $loc -> /usr/local/bin/agy"
            break
        fi
    done
fi

# Final verification — the test depends on this
if [ -x /usr/local/bin/agy ] || command -v agy &> /dev/null; then
    echo "Antigravity CLI installed successfully!"
else
    echo "ERROR: agy binary not found after installation."
    echo "  Checked: $AGY_BIN, /usr/local/bin/agy, /usr/bin/agy, /opt/agy"
    echo "  Installer may have placed it elsewhere; check the feature build log."
    exit 1
fi
