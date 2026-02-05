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
check "opencode defaults file exists" test -f /usr/local/etc/opencode-defaults
check "opencode defaults include port" grep -q "OPENCODE_SERVER_PORT_DEFAULT" /usr/local/etc/opencode-defaults
check "opencode-server-status runs" bash -c "opencode-server-status >/dev/null"
check "opencode-logs-clean runs" bash -c "opencode-logs-clean >/dev/null"

# Report result
reportResults
