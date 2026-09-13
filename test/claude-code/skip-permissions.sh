#!/bin/bash
set -e
source dev-container-features-test-lib

check "claude command exists" command -v claude
check "claude defaults file exists" test -f /usr/local/etc/claude-code-defaults
check "claude-remote-auth runs" bash -c "claude-remote-auth >/dev/null"

reportResults
