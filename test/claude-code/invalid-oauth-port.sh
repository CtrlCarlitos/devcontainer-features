#!/bin/bash
set -e
source dev-container-features-test-lib

check "claude defaults file exists" test -f /usr/local/etc/claude-code-defaults
check "invalid oauth port falls back to default" grep -q "CLAUDE_CODE_OAUTH_PORT_DEFAULT=52780" /usr/local/etc/claude-code-defaults

reportResults
