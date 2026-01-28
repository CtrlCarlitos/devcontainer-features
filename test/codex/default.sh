#!/bin/bash
set -e
source dev-container-features-test-lib

check "codex command exists" command -v codex
check "codex version" codex --version

reportResults
