#!/bin/bash
set -e
source dev-container-features-test-lib

check "codex command exists" command -v codex
check "codex version" codex --version
check "codex defaults file exists" test -f /usr/local/etc/codex-defaults

reportResults
