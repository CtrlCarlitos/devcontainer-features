#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode defaults file exists" test -f /usr/local/etc/opencode-defaults
check "invalid server port falls back to default" grep -q "OPENCODE_SERVER_PORT_DEFAULT=4096" /usr/local/etc/opencode-defaults

reportResults
