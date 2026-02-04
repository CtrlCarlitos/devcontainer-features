#!/bin/bash
set -e
source dev-container-features-test-lib

check "gemini command exists" command -v gemini
check "gemini version" gemini --version

check "gemini-remote-auth exists" test -x /usr/local/bin/gemini-remote-auth
check "gemini-headless exists" test -x /usr/local/bin/gemini-headless
check "gemini-json exists" test -x /usr/local/bin/gemini-json
check "gemini-info exists" test -x /usr/local/bin/gemini-info

reportResults
