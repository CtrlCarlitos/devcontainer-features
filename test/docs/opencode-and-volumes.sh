#!/bin/bash
set -euo pipefail

assert_absent() {
    if grep -F -- "$1" "$2"; then
        echo "Unexpected text in $2: $1" >&2
        return 1
    fi
}

grep -F 'OPENCODE_SERVER_PASSWORD' DOCKER_VOLUMES.md
grep -F 'containerEnv' DOCKER_VOLUMES.md
grep -F '`~/.claude`' DOCKER_VOLUMES.md
grep -F '`~/.claude.json`' DOCKER_VOLUMES.md
grep -F 'never use a named volume' DOCKER_VOLUMES.md
grep -F 'Windows and macOS' DOCKER_VOLUMES.md
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
assert_absent '/home/vscode/.codex:ro' src/codex/NOTES.md
assert_absent '| serverPassword |' src/opencode/README.md
grep -F '| plugins |' src/opencode/README.md
assert_absent 'docs/security-review' README.md
grep -F 'OPENCODE_SERVER_PASSWORD' src/opencode/README.md
grep -F 'Unversioned and `:latest` references automatically receive v2' src/opencode/README.md
grep -F 'the image build fails' src/opencode/README.md
grep -F '"version": "2.0.0"' src/opencode/devcontainer-feature.json
grep -F 'devcontainer-features/opencode:2' src/opencode/README.md
assert_absent 'devcontainer-features/opencode:1' src/opencode/README.md
assert_absent 'devcontainer-features/node:1' src/runtime_core/README.md
