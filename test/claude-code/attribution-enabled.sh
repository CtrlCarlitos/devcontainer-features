#!/bin/bash
set -e
source dev-container-features-test-lib

check "opt-out leaves settings absent" test ! -e "$HOME/.claude/settings.json"

reportResults
