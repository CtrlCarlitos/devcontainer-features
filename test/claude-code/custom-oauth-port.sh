#!/bin/bash
set -e
source dev-container-features-test-lib

check "claude defaults file exists" test -f /usr/local/etc/claude-code-defaults
check "custom oauth port applied" grep -q "CLAUDE_CODE_OAUTH_PORT_DEFAULT=6001" /usr/local/etc/claude-code-defaults

reportResults
