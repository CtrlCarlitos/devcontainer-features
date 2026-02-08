#!/bin/bash
set -e
source dev-container-features-test-lib

check "opencode command exists" command -v opencode
check "opencode defaults enables server" grep -q "OPENCODE_ENABLE_SERVER_DEFAULT=true" /usr/local/etc/opencode-defaults
check "opencode password is set in defaults" grep -q 'OPENCODE_SERVER_PASSWORD_DEFAULT="testpassword"' /usr/local/etc/opencode-defaults

# Check if environment variable is accessible in shell
check "OPENCODE_SERVER_PASSWORD env var is set" bash -c '
source /etc/profile.d/00-opencode-init.sh
if [ "$OPENCODE_SERVER_PASSWORD" == "testpassword" ]; then
    exit 0
else
    echo "Expected testpassword, got [$OPENCODE_SERVER_PASSWORD]"
    exit 1
fi
'

# Check process list for debugging
echo "Process list:"
ps aux

# Validate one server instance is running
check "opencode server is running (pgrep)" pgrep -f "opencode.*serve"

# Check dependencies
check "curl is installed" command -v curl

# Check connectivity
echo "Checking port 4096..."
check "port 4096 is listening" timeout 2 bash -c '</dev/tcp/localhost/4096' || echo "Port check failed"

# Check health endpoint directly
echo "Checking health endpoint..."
check "health endpoint responds" curl -v http://localhost:4096/health

# Check status script
echo "Checking opencode-server-status..."
check "opencode-server-status reports healthy" bash -c '/usr/local/bin/opencode-server-status | grep "Health:   HEALTHY"' || {
    echo "Status script failed. Output:"
    /usr/local/bin/opencode-server-status
    exit 1
}


reportResults
