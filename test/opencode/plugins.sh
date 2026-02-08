#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Verify node/npm is installed
check "npm installed" command -v npm

# Check if opencode-gemini-auth is installed globally
check "opencode-gemini-auth plugin installed" npm list -g opencode-gemini-auth

# Report result
reportResults
