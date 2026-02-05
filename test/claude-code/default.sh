#!/bin/bash
set -e
source dev-container-features-test-lib

# Note: The CLI binary for @anthropic-ai/claude-code is typically 'claude'
check "claude command exists" command -v claude
check "claude version" claude --version

check "claude-remote-auth exists" test -x /usr/local/bin/claude-remote-auth
check "claude-headless exists" test -x /usr/local/bin/claude-headless
check "claude-mcp-server exists" test -x /usr/local/bin/claude-mcp-server
check "claude-info exists" test -x /usr/local/bin/claude-info
check "claude defaults file exists" test -f /usr/local/etc/claude-code-defaults
check "claude defaults include oauth port" grep -q "CLAUDE_CODE_OAUTH_PORT_DEFAULT" /usr/local/etc/claude-code-defaults
check "claude-remote-auth runs" bash -c "claude-remote-auth >/dev/null"
check "claude-info runs" bash -c "claude-info >/dev/null"
check "claude-headless shows usage" bash -c "! claude-headless"

reportResults
