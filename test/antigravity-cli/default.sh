#!/bin/bash
set -e
echo "Testing Antigravity CLI installation..."

# Check via direct path (devcontainer test shells may not have the
# installer's PATH additions sourced)
if [ -x /usr/local/bin/agy ]; then
    echo "✓ agy found at /usr/local/bin/agy"
    /usr/local/bin/agy --version 2>/dev/null && echo "✓ version check passed" || echo "  (version check non-critical)"
elif command -v agy &> /dev/null; then
    echo "✓ agy found on PATH at $(command -v agy)"
else
    echo "✗ agy not found at /usr/local/bin/agy or on PATH"
    ls -la /usr/local/bin/agy 2>/dev/null || echo "  /usr/local/bin/agy does not exist"
    ls -la /root/.local/bin/agy 2>/dev/null || echo "  /root/.local/bin/agy does not exist"
    exit 1
fi

echo "✓ Test passed"
