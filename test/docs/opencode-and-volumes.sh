#!/bin/bash
set -euo pipefail

grep -F 'OPENCODE_SERVER_PASSWORD' DOCKER_VOLUMES.md
grep -F 'containerEnv' DOCKER_VOLUMES.md
grep -F '`~/.claude`' DOCKER_VOLUMES.md
grep -F '`~/.codex`' DOCKER_VOLUMES.md
grep -F '`~/.config/opencode`' DOCKER_VOLUMES.md
grep -F 'optional user-managed' DOCKER_VOLUMES.md
grep -F 'Platform Support' README.md
grep -F '`runtime_core`, `nerd-font`' README.md
grep -F 'Linux x86_64' README.md
grep -F 'x86_64 and arm64' README.md
grep -F 'best effort outside Debian/Ubuntu' README.md
grep -F 'Linux container x86_64/arm64' README.md
grep -F 'configured remote user' src/codex/NOTES.md
! grep -F '/home/vscode/.codex:ro' src/codex/NOTES.md
! grep -F 'serverPassword' src/opencode/README.md
grep -F '| plugins |' src/opencode/README.md
! grep -F 'docs/security-review' README.md
