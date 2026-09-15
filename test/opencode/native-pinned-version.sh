#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode installs requested native version" bash -c 'opencode --version | grep -q "1.18.30"'

reportResults
