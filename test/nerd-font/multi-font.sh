#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# Test multi-font installation (FiraCode + JetBrainsMono)
check "font directory exists" [ -d "/usr/local/share/fonts" ]
check "FiraCode font installed" compgen -G "/usr/local/share/fonts/*FiraCode*" > /dev/null
check "JetBrainsMono font installed" compgen -G "/usr/local/share/fonts/*JetBrainsMono*" > /dev/null
check "font cache contains FiraCode" fc-list | grep -i "FiraCode"
check "font cache contains JetBrainsMono" fc-list | grep -i "JetBrainsMono"

# Report result
reportResults
