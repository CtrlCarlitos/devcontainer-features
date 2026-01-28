#!/bin/bash
set -e
source dev-container-features-test-lib

# Note: The CLI binary for @anthropic-ai/claude-code is typically 'claude'
check "claude command exists" command -v claude
check "claude version" claude --version

reportResults
