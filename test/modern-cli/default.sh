#!/bin/bash
set -e
echo "Testing Modern CLI Tools installation..."

# Check via direct path first (devcontainer test shells may not have the
# installer's PATH additions sourced), then fall back to PATH lookup.
FAILED=0
for tool in bat eza fd rg delta fzf jq duf; do
    if [ -x "/usr/local/bin/$tool" ]; then
        echo "✓ $tool found at /usr/local/bin/$tool"
    elif [ -x "/usr/bin/$tool" ]; then
        echo "✓ $tool found at /usr/bin/$tool"
    elif command -v "$tool" &> /dev/null; then
        echo "✓ $tool found on PATH at $(command -v "$tool")"
    else
        echo "✗ $tool not found at /usr/local/bin/$tool, /usr/bin/$tool, or on PATH"
        FAILED=1
    fi
done

if [ "$FAILED" -ne 0 ]; then
    echo "✗ Test failed"
    exit 1
fi

# Smoke test one version flag (non-critical)
if [ -x /usr/local/bin/bat ]; then
    /usr/local/bin/bat --version > /dev/null 2>&1 && echo "✓ bat version check passed" || echo "  (bat version check non-critical)"
fi

echo "✓ Test passed"
