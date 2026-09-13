#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode command exists" command -v opencode
check "opencode defaults enable server" grep -q "OPENCODE_ENABLE_SERVER_DEFAULT=true" /usr/local/etc/opencode-defaults
check "opencode server starts healthy" bash -c '
opencode-server-start.sh >/tmp/opencode-start.log 2>&1
status=""
for _ in $(seq 1 10); do
  status="$(opencode-server-status || true)"
  if echo "$status" | grep -q "Health:   HEALTHY"; then
    echo "$status" > /tmp/opencode-status.log
    opencode-server-stop >/tmp/opencode-stop.log 2>&1 || true
    exit 0
  fi
  sleep 1
done
echo "$status" > /tmp/opencode-status.log
opencode-server-stop >/tmp/opencode-stop.log 2>&1 || true
exit 1
'

reportResults
