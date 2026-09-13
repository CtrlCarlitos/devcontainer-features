#!/bin/bash
set -e
source dev-container-features-test-lib

CONFIG_PATH=""
if [ -f "/home/vscode/.codex/config.toml" ]; then
    CONFIG_PATH="/home/vscode/.codex/config.toml"
elif [ -f "/root/.codex/config.toml" ]; then
    CONFIG_PATH="/root/.codex/config.toml"
else
    CONFIG_PATH="${HOME}/.codex/config.toml"
fi

check "codex config exists" test -f "$CONFIG_PATH"
check "invalid approval mode falls back" grep -q "approval_policy = \"suggest\"" "$CONFIG_PATH"
check "invalid sandbox mode falls back" grep -q "sandbox_mode = \"workspace-write\"" "$CONFIG_PATH"

reportResults
