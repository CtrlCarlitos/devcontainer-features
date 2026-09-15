#!/bin/bash
set -e
source dev-container-features-test-lib

check "runtime localhost override starts without a password" bash -c '
  status=""
  for _ in $(seq 1 10); do
    status="$(opencode-server-status || true)"
    if printf "%s\\n" "$status" | grep -q "Health:   HEALTHY"; then
      opencode-server-stop >/tmp/opencode-stop.log 2>&1 || true
      exit 0
    fi
    sleep 1
  done
  printf "%s\\n" "$status"
  opencode-server-stop >/tmp/opencode-stop.log 2>&1 || true
  exit 1
'

reportResults
