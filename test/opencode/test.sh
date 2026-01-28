#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "opencode command exists" command -v opencode
check "opencode version" opencode --version

# Report result
reportResults
