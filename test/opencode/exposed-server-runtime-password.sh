#!/bin/bash
set -e
source dev-container-features-test-lib

check "lifecycle-started exposed server is healthy with runtime password" bash -c '
  test "$OPENCODE_SERVER_PASSWORD" = "testpassword"
  status=""
  for _ in $(seq 1 10); do
    status="$(opencode-server-status || true)"
    if printf "%s\\n" "$status" | grep -q "Health:   HEALTHY"; then
      exit 0
    fi
    sleep 1
  done
  printf "%s\\n" "$status"
  exit 1
'

reportResults
