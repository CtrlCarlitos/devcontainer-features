#!/bin/bash
set -e
source dev-container-features-test-lib

check "bmad command exists" command -v bmad
check "bmad version" bmad --version

reportResults
