#!/bin/bash
set -e
source dev-container-features-test-lib

SETTINGS_PATH=""
if [ -f "/home/vscode/.gemini/settings.json" ]; then
    SETTINGS_PATH="/home/vscode/.gemini/settings.json"
elif [ -f "/root/.gemini/settings.json" ]; then
    SETTINGS_PATH="/root/.gemini/settings.json"
else
    SETTINGS_PATH="${HOME}/.gemini/settings.json"
fi

check "settings file exists" test -f "$SETTINGS_PATH"
check "default model set" grep -q "\"model\": \"gemini-1.5-pro\"" "$SETTINGS_PATH"

reportResults
