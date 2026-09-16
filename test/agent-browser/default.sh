#!/bin/bash
set -e

agent_browser="$(npm prefix -g)/bin/agent-browser"
test -x "$agent_browser"
test "$HOME" = /home/vscode
"$agent_browser" --version
"$agent_browser" doctor --json || true
"$agent_browser" open about:blank
pgrep -u "$(id -un)" -f -- '--no-sandbox' >/dev/null
"$agent_browser" close
test -d "$HOME/.agent-browser/browsers"
test "$(stat -c %U "$HOME/.agent-browser")" = "$(id -un)"
test "$(stat -c %U "$HOME/.agent-browser/config.json")" = "$(id -un)"
test ! -d /root/.agent-browser/browsers
test "${PLAYWRIGHT_BROWSERS_PATH:-}" = ""
