#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode command exists" command -v opencode
check "defaults contain no password" bash -c '! grep -q "PASSWORD" /usr/local/etc/opencode-defaults'
check "profile contains no password" bash -c '! grep -q "PASSWORD" /etc/profile.d/00-opencode-init.sh'
check "shell rc files contain no password" bash -c '! grep -q "PASSWORD" "$HOME/.bashrc" "$HOME/.zshrc"'
check "runtime password authenticates server" bash -c '
  opencode-server-stop >/tmp/opencode-stop.log 2>&1 || true
  OPENCODE_SERVER_PASSWORD=testpassword opencode-server-start.sh >/tmp/opencode-start.log 2>&1
  status=""
  for _ in $(seq 1 10); do
    status="$(OPENCODE_SERVER_PASSWORD=testpassword opencode-server-status || true)"
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
