#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Verify node/npm is installed
check "npm installed" command -v npm

# Check if opencode.json exists and contains the plugin
CONFIG_FILE="$HOME/.config/opencode/opencode.json"
check "config file exists" [ -f "$CONFIG_FILE" ]
check "plugin in config" grep -q "opencode-gemini-auth" "$CONFIG_FILE"

# Report result
reportResults
