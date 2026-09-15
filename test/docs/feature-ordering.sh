#!/bin/bash
set -euo pipefail

for feature in opencode graft; do
    grep -F '"ghcr.io/CtrlCarlitos/devcontainer-features/runtime_core"' "src/$feature/devcontainer-feature.json"
    ! grep -F '"./runtime_core"' "src/$feature/devcontainer-feature.json"
done
