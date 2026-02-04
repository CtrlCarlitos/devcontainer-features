#!/bin/bash
set -e
source dev-container-features-test-lib

check "codex command exists" command -v codex
check "codex version" codex --version

check "codex-remote-auth exists" test -x /usr/local/bin/codex-remote-auth
check "codex-exec exists" test -x /usr/local/bin/codex-exec
check "codex-mcp-server exists" test -x /usr/local/bin/codex-mcp-server
check "codex-info exists" test -x /usr/local/bin/codex-info

reportResults
