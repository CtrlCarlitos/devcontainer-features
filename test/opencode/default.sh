#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "opencode command exists" command -v opencode
check "opencode version" opencode --version

check "opencode-server-start.sh exists" test -x /usr/local/bin/opencode-server-start.sh
check "opencode-connect exists" test -x /usr/local/bin/opencode-connect
check "opencode-server-stop exists" test -x /usr/local/bin/opencode-server-stop
check "opencode-server-status exists" test -x /usr/local/bin/opencode-server-status
check "opencode-logs-clean exists" test -x /usr/local/bin/opencode-logs-clean

# Report result
reportResults
