#!/bin/bash
set -e
source dev-container-features-test-lib

check "exposed server requires a runtime password" bash -c '
  output=$(/usr/local/bin/opencode-server-start.sh 2>&1) && exit 1
  printf "%s\\n" "$output" | grep -F "OPENCODE_SERVER_PASSWORD"
'

reportResults
