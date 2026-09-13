#!/bin/bash
set -e
echo "Testing Serena installation..."

# Check via direct path (devcontainer test shells may not have the
# installer's PATH additions sourced)
if [ -x /usr/local/bin/serena ]; then
    echo "✓ serena found at /usr/local/bin/serena"
    /usr/local/bin/serena --help >/dev/null 2>&1 && echo "✓ help check passed" || echo "  (help check non-critical)"
else
    echo "✗ serena not found at /usr/local/bin/serena"
    ls -la /usr/local/bin/serena 2>/dev/null || echo "  /usr/local/bin/serena does not exist"
    ls -la /root/.local/bin/serena 2>/dev/null || echo "  /root/.local/bin/serena does not exist"
    exit 1
fi

echo "✓ Test passed"
