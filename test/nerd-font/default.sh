#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "font directory exists" [ -d "/usr/local/share/fonts" ]
check "Meslo font installed" compgen -G "/usr/local/share/fonts/*Meslo*" > /dev/null
check "font cache updated" fc-list | grep "Meslo"

# Report result
reportResults
