#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode command exists" command -v opencode
check "opencode defaults enable server" grep -q "OPENCODE_ENABLE_SERVER_DEFAULT=true" /usr/local/etc/opencode-defaults
check "opencode-server-start runs" bash -c "opencode-server-start.sh >/tmp/opencode-start.log 2>&1"

reportResults
