#!/bin/bash
set -e
source dev-container-features-test-lib

check "vertex ai profile exists" test -f /etc/profile.d/gemini-cli.sh
check "vertex ai export set" grep -q "GOOGLE_GENAI_USE_VERTEXAI=true" /etc/profile.d/gemini-cli.sh

reportResults
