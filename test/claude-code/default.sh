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

reportResults
