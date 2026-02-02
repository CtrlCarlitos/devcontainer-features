#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# Test "latest" version resolution
check "font directory exists" [ -d "/usr/local/share/fonts" ]
check "Hack font installed" compgen -G "/usr/local/share/fonts/*Hack*" > /dev/null
check "font cache contains Hack" fc-list | grep -i "Hack"

# Verify we resolved a real version (not "latest" literal)
# The install script should have downloaded from a versioned URL

# Report result
reportResults
