#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# The feature must install 'latest' without any api.github.com availability
# (anonymous API rate limits on shared CI runner IPs).
check "opencode command exists" command -v opencode
check "opencode version" opencode --version

# Report result
reportResults
