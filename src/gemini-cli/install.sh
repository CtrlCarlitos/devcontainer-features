#!/bin/bash
set -e

# Feature options
VERSION="${VERSION:-latest}"
AUTHMETHOD="${AUTHMETHOD:-none}"
DEFAULTMODEL="${DEFAULTMODEL:-}"
ENABLEVERTEXAI="${ENABLEVERTEXAI:-false}"

# Fixed install location (helper scripts use static paths)
BIN_DIR="/usr/local/bin"

# ============================================================================
# Robust User Detection
# ============================================================================
get_target_user() {
    local user="${_REMOTE_USER:-}"
    [ -z "$user" ] && user="${SUDO_USER:-}"
    [ -z "$user" ] && user="$(whoami)"

    if ! id "$user" &>/dev/null; then
        echo "WARNING: Target user '$user' does not exist. Using 'root'." >&2
        user="root"
    fi
    echo "$user"
}

get_target_home() {
    local user="$1"
    local home="${_REMOTE_USER_HOME:-}"

    if [ -z "$home" ]; then
        home=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
    fi
    if [ -z "$home" ]; then
        home=$(eval echo "~$user" 2>/dev/null)
    fi
    if [ -z "$home" ] || [ "$home" = "~$user" ]; then
        echo "WARNING: Could not determine home for '$user'. Using /root." >&2
        home="/root"
    fi
    echo "$home"
}

REMOTE_USER="$(get_target_user)"
REMOTE_USER_HOME="$(get_target_home "$REMOTE_USER")"

# Ensure bin directory exists
mkdir -p "$BIN_DIR"

echo "Installing Gemini CLI..."
echo "Target user: $REMOTE_USER"
echo "Target home: $REMOTE_USER_HOME"

# ============================================================================
# INSTALLATION METHOD: npm (ONLY recommended method)
# ============================================================================
# npm is the only recommended installation method for Gemini CLI.
# There is no native binary installer like Claude Code.
# Package: @google/gemini-cli
#
# Requirements:
# - Node.js 18+ (preferably 20+)
# - npm
# ============================================================================

if ! command -v npm &> /dev/null; then
    echo "ERROR: npm not found."
    echo "Gemini CLI requires npm for installation."
    echo "Ensure Node.js is installed first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v 2>/dev/null | cut -d'.' -f1 | sed 's/v//')
if [ -n "$NODE_VERSION" ] && [ "$NODE_VERSION" -lt 18 ]; then
    echo "WARNING: Node.js version is below 18. Gemini CLI requires Node.js 18+."
    echo "Current version: $(node -v)"
fi

# Install Gemini CLI via npm
if [ "$VERSION" = "latest" ]; then
    npm install -g @google/gemini-cli
else
    npm install -g @google/gemini-cli@"$VERSION"
fi

# Verify installation
if ! command -v gemini &> /dev/null; then
    echo "ERROR: Gemini CLI installation failed"
    exit 1
fi

echo "Gemini CLI installed successfully"

# Create settings directory for target user
SETTINGS_DIR="${REMOTE_USER_HOME}/.gemini"
mkdir -p "$SETTINGS_DIR"
if ! chown -R "$REMOTE_USER:$REMOTE_USER" "$SETTINGS_DIR" 2>/dev/null; then
    echo "NOTE: Could not change ownership of $SETTINGS_DIR to $REMOTE_USER"
fi

# Create default settings if model specified
if [ -n "$DEFAULTMODEL" ]; then
    cat > "${SETTINGS_DIR}/settings.json" << SETTINGSEOF
{
    "model": "${DEFAULTMODEL}"
}
SETTINGSEOF
    chown "$REMOTE_USER:$REMOTE_USER" "${SETTINGS_DIR}/settings.json" 2>/dev/null || true
fi

# Set Vertex AI environment if enabled
if [ "$ENABLEVERTEXAI" = "true" ]; then
    echo 'export GOOGLE_GENAI_USE_VERTEXAI=true' >> /etc/profile.d/gemini-cli.sh
fi

# Create remote authentication helper
cat > "${BIN_DIR}/gemini-remote-auth" << 'AUTHSCRIPT'
#!/bin/bash
# Helper for authenticating Gemini CLI in remote/container environments

cat << 'EOF'
================================================================================
Gemini CLI Remote Authentication Guide
================================================================================

Gemini CLI supports multiple authentication methods:

METHOD 1: API Key Authentication (Recommended for Headless/CI)
--------------------------------------------------------------
1. Get your API key from https://aistudio.google.com/app/apikey

2. Set the environment variable:

   export GOOGLE_API_KEY="your-api-key"
   # OR
   export GEMINI_API_KEY="your-api-key"

3. Gemini CLI will automatically use the API key

Note: Free tier includes 60 requests/min and 1,000 requests/day


METHOD 2: Google OAuth (For Personal Google Accounts)
-----------------------------------------------------
This is tricky in headless environments. Workaround:

1. Create a script to capture the auth URL:

   mkdir -p ~/.gemini
   cat > ~/capture-url.sh << 'SCRIPT'
   #!/bin/bash
   echo "$@" >> ~/.gemini/auth-url.txt
   SCRIPT
   chmod +x ~/capture-url.sh

2. Set the browser to the capture script:

   export BROWSER=~/capture-url.sh

3. Run gemini and select Google login:

   gemini
   # Select /auth -> Login with Google

4. Check the captured URL:

   cat ~/.gemini/auth-url.txt

5. Open this URL in your local browser and complete authentication

6. After authentication, copy the callback URL and use curl:

   curl "http://localhost:PORT/callback?code=..."


METHOD 3: Service Account (For Enterprise/GCP)
----------------------------------------------
1. Create a service account in Google Cloud Console

2. Download the JSON key file

3. Set the environment variable:

   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

4. Enable Vertex AI:

   export GOOGLE_GENAI_USE_VERTEXAI=true


METHOD 4: Vertex AI with ADC
----------------------------
If running in Google Cloud (GCE, Cloud Run, etc.):

1. Ensure the instance has appropriate IAM roles

2. Enable Vertex AI:

   export GOOGLE_GENAI_USE_VERTEXAI=true


================================================================================
EOF
AUTHSCRIPT

chmod +x "${BIN_DIR}/gemini-remote-auth"

# Create headless execution helper
cat > "${BIN_DIR}/gemini-headless" << 'HEADLESSSCRIPT'
#!/bin/bash
# Run Gemini CLI in headless mode

PROMPT="$1"
shift

if [ -z "$PROMPT" ]; then
    echo "Usage: gemini-headless \"<prompt>\" [additional options]"
    echo ""
    echo "Options:"
    echo "  --output-format json         Structured JSON output"
    echo "  --output-format stream-json  Real-time JSON events"
    echo ""
    echo "Examples:"
    echo "  gemini-headless \"Explain this code\""
    echo "  gemini-headless \"Review for bugs\" --output-format json"
    echo "  cat file.py | gemini-headless \"Analyze this\""
    exit 1
fi

gemini -p "$PROMPT" "$@"
HEADLESSSCRIPT

chmod +x "${BIN_DIR}/gemini-headless"

# Create JSON output helper
cat > "${BIN_DIR}/gemini-json" << 'JSONSCRIPT'
#!/bin/bash
# Run Gemini with JSON output and extract response

PROMPT="$1"
shift

if [ -z "$PROMPT" ]; then
    echo "Usage: gemini-json \"<prompt>\" [additional options]"
    echo ""
    echo "Returns only the response text from JSON output."
    echo "Use 'gemini-headless' for full JSON with stats."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required for gemini-json."
    echo "Install jq or use 'gemini-headless' instead."
    exit 1
fi

gemini -p "$PROMPT" --output-format json "$@" | jq -r '.response'
JSONSCRIPT

chmod +x "${BIN_DIR}/gemini-json"

# NOTE: gemini-json requires jq. Ensure jq is available (e.g., add common-utils or install jq directly).

# Create status/info script
cat > "${BIN_DIR}/gemini-info" << 'INFOSCRIPT'
#!/bin/bash
# Display Gemini CLI information and status

echo "Gemini CLI Information"
echo "======================"
echo ""

# Check authentication status
if [ -n "$GOOGLE_API_KEY" ] || [ -n "$GEMINI_API_KEY" ]; then
    echo "Authentication: API Key set"
elif [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "Authentication: Service Account configured"
    echo "  Credentials: $GOOGLE_APPLICATION_CREDENTIALS"
elif [ -f ~/.gemini/oauth_creds.json ]; then
    echo "Authentication: Google OAuth (credentials cached)"
else
    echo "Authentication: Not configured"
fi

if [ "$GOOGLE_GENAI_USE_VERTEXAI" = "true" ]; then
    echo "Backend: Vertex AI"
else
    echo "Backend: Google AI Studio"
fi

# Show settings
if [ -f ~/.gemini/settings.json ]; then
    echo ""
    echo "Settings (~/.gemini/settings.json):"
    cat ~/.gemini/settings.json
fi

echo ""
echo "Available Commands:"
echo "  gemini              - Start interactive mode"
echo "  gemini -p \"prompt\"  - Headless mode"
echo "  gemini /auth        - Authenticate"
echo "  gemini /model       - Change model"
echo ""
echo "Helper Scripts:"
echo "  gemini-remote-auth  - Authentication guide"
echo "  gemini-headless     - Simplified headless mode"
echo "  gemini-json         - JSON output with response extraction"
echo "  gemini-info         - This information"
echo ""
echo "Free Tier Limits:"
echo "  60 requests/minute"
echo "  1,000 requests/day"

# Check for jq dependency
if ! command -v jq &>/dev/null; then
    echo ""
    echo "NOTE: 'gemini-json' helper requires jq. Install with:"
    echo "  apt-get install jq  # Debian/Ubuntu"
    echo "  apk add jq          # Alpine"
fi
INFOSCRIPT

chmod +x "${BIN_DIR}/gemini-info"

echo ""
echo "Gemini CLI installation complete!"
echo ""
echo "Run 'gemini-remote-auth' for authentication instructions."
echo "Run 'gemini-info' for available commands and status."
