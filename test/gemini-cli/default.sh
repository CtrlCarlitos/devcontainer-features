#!/bin/bash
set -e
source dev-container-features-test-lib

check "gemini command exists" command -v gemini
check "gemini version" gemini --version

reportResults
