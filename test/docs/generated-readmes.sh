#!/bin/bash
set -euo pipefail

temporary_copy="$(mktemp -d)"
trap 'rm -rf "$temporary_copy"' EXIT

cp -a src/. "$temporary_copy"
devcontainer features generate-docs --project-folder "$temporary_copy" --namespace CtrlCarlitos/devcontainer-features

for feature in runtime_core opencode codex claude-code nerd-font; do
    cmp "src/$feature/README.md" "$temporary_copy/$feature/README.md"
done
