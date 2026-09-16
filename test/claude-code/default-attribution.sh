#!/bin/bash
set -e
source dev-container-features-test-lib

SETTINGS="$HOME/.claude/settings.json"
check "attribution settings exist" test -f "$SETTINGS"
check "co-author attribution disabled" jq -e '.includeCoAuthoredBy == false' "$SETTINGS"
check "commit attribution disabled" jq -e '.attribution.commit == ""' "$SETTINGS"
check "PR attribution disabled" jq -e '.attribution.pr == ""' "$SETTINGS"
check "session attribution disabled" jq -e '.attribution.sessionUrl == false' "$SETTINGS"
check "settings mode is private" bash -c '[ "$(stat -c %a "$SETTINGS")" = 600 ]'

reportResults
