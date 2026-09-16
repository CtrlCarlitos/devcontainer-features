#!/bin/bash
set -e
source dev-container-features-test-lib

SETTINGS="$HOME/.claude/settings.json"
check "settings JSON is valid" jq empty "$SETTINGS"
check "settings file is atomic regular file" test -f "$SETTINGS"
check "settings remains private" bash -c '[ "$(stat -c %a "$SETTINGS")" = 600 ]'

reportResults
