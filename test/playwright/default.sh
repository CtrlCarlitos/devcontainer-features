#!/bin/bash
set -e
echo "Testing Playwright installation..."

# Check the CLI
if [ -x /usr/local/bin/playwright ]; then
    echo "✓ playwright CLI found at /usr/local/bin/playwright"
elif command -v playwright &> /dev/null; then
    echo "✓ playwright CLI found on PATH at $(command -v playwright)"
else
    echo "✗ playwright CLI not found at /usr/local/bin/playwright or on PATH"
    exit 1
fi

# Check the browser (shared path, not user-specific)
BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/usr/local/share/ms-playwright}"
if [ -d "$BROWSERS_PATH" ] && ls "$BROWSERS_PATH"/chromium-*/*/chrome-linux/chrome >/dev/null 2>&1 || ls "$BROWSERS_PATH"/*/chrome-linux/chrome >/dev/null 2>&1; then
    echo "✓ chromium browser found in $BROWSERS_PATH"
elif find "$BROWSERS_PATH" -name "chrome" -o -name "chromium" 2>/dev/null | grep -q .; then
    echo "✓ chromium browser found in $BROWSERS_PATH"
else
    echo "✗ chromium browser not found in $BROWSERS_PATH"
    echo "  Contents: $(ls "$BROWSERS_PATH" 2>/dev/null | head -5)"
    exit 1
fi

echo "✓ Test passed"
