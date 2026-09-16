#!/bin/bash
set -euo pipefail

for feature in graft; do
    grep -F '"ghcr.io/CtrlCarlitos/devcontainer-features/runtime_core"' "src/$feature/devcontainer-feature.json"
    ! grep -F '"./runtime_core"' "src/$feature/devcontainer-feature.json"
done

grep -F '"./runtime_core"' src/opencode/devcontainer-feature.json
