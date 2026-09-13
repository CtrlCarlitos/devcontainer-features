#!/bin/bash
set -e
echo "Testing Graft installation..."

# Check via direct path first (devcontainer test shells may not have the
# npm global bin dir on PATH), then fall back to PATH lookup.
if [ -x /usr/local/bin/graft ]; then
    echo "✓ graft found at /usr/local/bin/graft"
elif command -v graft &> /dev/null; then
    echo "✓ graft found on PATH at $(command -v graft)"
else
    echo "✗ graft not found at /usr/local/bin/graft or on PATH"
    ls -la /usr/local/bin/graft 2>/dev/null || echo "  /usr/local/bin/graft does not exist"
    npm prefix -g 2>/dev/null || true
    exit 1
fi

# Version check (non-critical)
GRAFT_BIN="$(command -v graft || echo /usr/local/bin/graft)"
"$GRAFT_BIN" --version >/dev/null 2>&1 && echo "✓ version check passed" || echo "  (version check non-critical)"

echo "✓ Test passed"
