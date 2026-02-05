#!/bin/bash
set -e
source dev-container-features-test-lib

check "codex command exists" command -v codex
check "codex version" codex --version

check "codex-remote-auth exists" test -x /usr/local/bin/codex-remote-auth
check "codex-exec exists" test -x /usr/local/bin/codex-exec
check "codex-mcp-server exists" test -x /usr/local/bin/codex-mcp-server
check "codex-info exists" test -x /usr/local/bin/codex-info
check "codex defaults file exists" test -f /usr/local/etc/codex-defaults
check "codex defaults include oauth port" grep -q "CODEX_OAUTH_PORT_DEFAULT" /usr/local/etc/codex-defaults
check "codex-remote-auth runs" bash -c "codex-remote-auth >/dev/null"
check "codex-info runs" bash -c "codex-info >/dev/null"
check "codex-exec shows usage" bash -c "! codex-exec"

reportResults
