#!/bin/bash
set -e
source dev-container-features-test-lib

check "bmad-method command exists" command -v bmad-method
check "bmad-method version" bmad-method --version

reportResults
