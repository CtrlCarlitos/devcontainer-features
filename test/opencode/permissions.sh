#!/bin/bash
set -e
source dev-container-features-test-lib

echo "Checking permissions for user: $(whoami)"
echo "HOME: $HOME"

# Check .local/share/opencode
check "local share opencode exists" [ -d "$HOME/.local/share/opencode" ]
check "local share permission" [ "$(stat -c '%u' "$HOME/.local/share/opencode")" = "$(id -u)" ]

# Check .config/opencode
check "config opencode exists" [ -d "$HOME/.config/opencode" ]
check "config permission" [ "$(stat -c '%u' "$HOME/.config/opencode")" = "$(id -u)" ]

# Report
reportResults
