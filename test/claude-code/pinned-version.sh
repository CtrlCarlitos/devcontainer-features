#!/bin/bash
set -e
source dev-container-features-test-lib

check "claude installs requested version" bash -c 'claude --version | grep -q "2.1.47"'

reportResults
