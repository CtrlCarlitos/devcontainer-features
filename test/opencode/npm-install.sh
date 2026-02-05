#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode command exists" command -v opencode
check "opencode version" opencode --version
check "opencode defaults file exists" test -f /usr/local/etc/opencode-defaults
check "opencode-server-status runs" bash -c "opencode-server-status >/dev/null"

reportResults
