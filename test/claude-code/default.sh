#!/bin/bash
set -e
source dev-container-features-test-lib

# Note: The CLI binary for @anthropic-ai/claude-code is typically 'claude'
check "claude command exists" command -v claude
check "claude version" claude --version

check "claude-remote-auth exists" test -x /usr/local/bin/claude-remote-auth
check "claude-headless exists" test -x /usr/local/bin/claude-headless
check "claude-mcp-server exists" test -x /usr/local/bin/claude-mcp-server
check "claude-info exists" test -x /usr/local/bin/claude-info
check "claude defaults file exists" test -f /usr/local/etc/claude-code-defaults
check "claude-remote-auth runs" bash -c "claude-remote-auth >/dev/null"
check "claude-info runs" bash -c "claude-info >/dev/null"
check "claude-headless shows usage" bash -c "! claude-headless"
check "attribution settings exist" test -f "$HOME/.claude/settings.json"
check "attribution helper exists" test -x /usr/local/bin/claude-disable-attribution
check "co-author attribution disabled" jq -e '.includeCoAuthoredBy == false' "$HOME/.claude/settings.json"
check "commit attribution disabled" jq -e '.attribution.commit == ""' "$HOME/.claude/settings.json"
check "PR attribution disabled" jq -e '.attribution.pr == ""' "$HOME/.claude/settings.json"
check "session attribution disabled" jq -e '.attribution.sessionUrl == false' "$HOME/.claude/settings.json"
check "settings mode is private" bash -c '[ "$(stat -c %a "$HOME/.claude/settings.json")" = 600 ]'
check "helper preserves nested settings and mode" bash -c '
  printf "{\"unrelated\":{\"keep\":true},\"attribution\":{\"custom\":\"keep\"}}" > "$HOME/.claude/settings.json"
  chmod 640 "$HOME/.claude/settings.json"
  /usr/local/bin/claude-disable-attribution "$HOME"
  jq -e ".unrelated.keep == true and .attribution.custom == \"keep\" and .attribution.commit == \"\"" "$HOME/.claude/settings.json" >/dev/null
  [ "$(stat -c %a "$HOME/.claude/settings.json")" = 640 ]
'
check "helper handles zero-byte settings atomically" bash -c '
  : > "$HOME/.claude/settings.json"
  before=$(stat -c %i "$HOME/.claude/settings.json")
  /usr/local/bin/claude-disable-attribution "$HOME"
  after=$(stat -c %i "$HOME/.claude/settings.json")
  jq empty "$HOME/.claude/settings.json" && [ "$before" != "$after" ]
'
check "helper preserves malformed settings" bash -c '
  printf "{ malformed" > "$HOME/.claude/settings.json"
  before=$(sha256sum "$HOME/.claude/settings.json" | cut -d" " -f1)
  /usr/local/bin/claude-disable-attribution "$HOME" >/dev/null 2>&1
  [ "$before" = "$(sha256sum "$HOME/.claude/settings.json" | cut -d" " -f1)" ]
'

reportResults
