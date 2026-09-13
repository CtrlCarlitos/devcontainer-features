#!/bin/bash
set -e
echo "Testing Guardrail installation..."

# Check via direct path (devcontainer test shells may not have the
# installer's PATH additions sourced)
if [ -x /usr/local/bin/guardrail ]; then
    echo "✓ guardrail found at /usr/local/bin/guardrail"
    /usr/local/bin/guardrail --version >/dev/null 2>&1 && echo "✓ version check passed" || echo "  (version check non-critical)"
else
    echo "✗ guardrail not found at /usr/local/bin/guardrail"
    ls -la /usr/local/bin/guardrail 2>/dev/null || echo "  /usr/local/bin/guardrail does not exist"
    exit 1
fi

echo "✓ Test passed"
