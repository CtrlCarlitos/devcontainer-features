#!/bin/bash
# Note: Uses set -e for error handling; consider set -euo pipefail for stricter behavior
set -e

# Feature options
VERSION="${VERSION:-latest}"
INSTALLMETHOD="${INSTALLMETHOD:-npm}"
ENABLEMCPSERVER="${ENABLEMCPSERVER:-false}"
AUTHMETHOD="${AUTHMETHOD:-none}"
APPROVALMODE="${APPROVALMODE:-suggest}"
SANDBOXMODE="${SANDBOXMODE:-workspace-write}"

# Fixed install location (helper scripts use static paths)
BIN_DIR="/usr/local/bin"

# ============================================================================
# Cleanup and Error Handling
# ============================================================================
CLEANUP_FILES=()
CLEANUP_DIRS=()

cleanup() {
    local exit_code=$?
    for f in "${CLEANUP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null || true
    done
    for d in "${CLEANUP_DIRS[@]}"; do
        rm -rf "$d" 2>/dev/null || true
    done
    exit $exit_code
}

trap cleanup EXIT

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

    if [ -z "$home" ] && command -v getent &>/dev/null; then
        home=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
    fi
    if [ -z "$home" ] && [ -r /etc/passwd ]; then
        home=$(awk -F: -v u="$user" '$1==u{print $6}' /etc/passwd)
    fi
    if [ -z "$home" ]; then
        if [ "$user" = "root" ]; then
            home="/root"
        else
            home="/home/$user"
        fi
    fi
    if [ -z "$home" ] || [ "$home" = "~$user" ]; then
        echo "WARNING: Could not determine home for '$user'. Using /root." >&2
        home="/root"
    fi
    echo "$home"
}

REMOTE_USER="$(get_target_user)"
REMOTE_USER_HOME="$(get_target_home "$REMOTE_USER")"

# ============================================================================
# Input Validation
# ============================================================================
validate_port() {
    local value="$1"
    local fallback="$2"
    local label="$3"

    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
        echo "$value"
        return 0
    fi

    echo "WARNING: Invalid ${label} port '$value'. Using ${fallback}." >&2
    echo "$fallback"
}

normalize_approval_mode() {
    case "$1" in
        suggest|auto|full-auto)
            echo "$1"
            ;;
        *)
            echo "WARNING: Invalid approvalMode '$1'. Using 'suggest'." >&2
            echo "suggest"
            ;;
    esac
}

normalize_sandbox_mode() {
    case "$1" in
        workspace-write|full-access|read-only)
            echo "$1"
            ;;
        *)
            echo "WARNING: Invalid sandboxMode '$1'. Using 'workspace-write'." >&2
            echo "workspace-write"
            ;;
    esac
}

APPROVALMODE="$(normalize_approval_mode "$APPROVALMODE")"
SANDBOXMODE="$(normalize_sandbox_mode "$SANDBOXMODE")"

# Ensure bin directory exists
mkdir -p "$BIN_DIR"

echo "Installing OpenAI Codex CLI..."
echo "Target user: $REMOTE_USER"
echo "Target home: $REMOTE_USER_HOME"
echo "Install method: $INSTALLMETHOD"

# ============================================================================
# INSTALLATION METHOD: npm (RECOMMENDED by OpenAI)
# ============================================================================
# npm is the primary installation method recommended by OpenAI.
# Package: @openai/codex
# ============================================================================

install_npm() {
    echo "Using npm installer (recommended by OpenAI)..."

    if ! command -v npm &> /dev/null; then
        echo "ERROR: npm not found. Install Node.js first."
        exit 1
    fi

    if [ "$VERSION" = "latest" ]; then
        npm install -g @openai/codex
    else
        npm install -g @openai/codex@"$VERSION"
    fi
}

verify_codex_installation() {
    local npm_global_bin
    # NOTE: This verifier is only used for npm installs, so npm is expected to exist.
    npm_global_bin="$(npm prefix -g)/bin"

    if command -v codex &> /dev/null; then
        return 0
    fi

    if [ -x "${npm_global_bin}/codex" ]; then
        ln -sf "${npm_global_bin}/codex" "${BIN_DIR}/codex"
        return 0
    fi

    if [ -x "/usr/local/share/nvm/current/bin/codex" ]; then
        ln -sf "/usr/local/share/nvm/current/bin/codex" "${BIN_DIR}/codex"
        return 0
    fi

    echo "ERROR: codex CLI not found after npm install."
    echo "DEBUG: npm prefix -g = $(npm prefix -g 2>/dev/null || echo 'failed')"
    echo "DEBUG: Contents of ${npm_global_bin}:"
    ls -la "${npm_global_bin}" 2>/dev/null || echo "Directory not found"
    return 1
}

# ============================================================================
# INSTALLATION METHOD: Binary (GitHub Releases)
# ============================================================================
# Alternative method downloading prebuilt binary from GitHub releases.
# ============================================================================

install_binary() {
    echo "Using binary installer from GitHub releases..."

    if ! command -v curl &> /dev/null; then
        echo "ERROR: curl not found. Install curl or use installMethod: npm"
        exit 1
    fi

    if ! command -v tar &> /dev/null; then
        echo "ERROR: tar not found. Install tar or use installMethod: npm"
        exit 1
    fi

    # Detect architecture
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$ARCH" in
        x86_64)
            ARCH_STR="x86_64"
            ;;
        aarch64|arm64)
            ARCH_STR="aarch64"
            ;;
        *)
            echo "ERROR: Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    case "$OS" in
        linux)
            BINARY_NAME="codex-${ARCH_STR}-unknown-linux-musl"
            ;;
        darwin)
            BINARY_NAME="codex-${ARCH_STR}-apple-darwin"
            ;;
        *)
            echo "ERROR: Unsupported OS: $OS"
            exit 1
            ;;
    esac

    # Get latest release URL or specific version
    if [ "$VERSION" = "latest" ]; then
        RELEASE_URL="https://github.com/openai/codex/releases/latest/download/${BINARY_NAME}.tar.gz"
    else
        RELEASE_URL="https://github.com/openai/codex/releases/download/${VERSION}/${BINARY_NAME}.tar.gz"
    fi

    # Create temp directory and register for cleanup
    local TEMP_DIR="/tmp/codex-install-$$"
    mkdir -p "$TEMP_DIR"
    CLEANUP_DIRS+=("$TEMP_DIR")

    echo "Downloading from: $RELEASE_URL"

    if ! curl -fsSL "$RELEASE_URL" -o "${TEMP_DIR}/codex.tar.gz"; then
        echo "ERROR: Failed to download Codex binary"
        exit 1
    fi

    # Verify checksum if checksums are published for this release
    CHECKSUM_URL=""
    if [ "$VERSION" = "latest" ]; then
        CHECKSUM_URL="https://github.com/openai/codex/releases/latest/download/checksums.txt"
    else
        CHECKSUM_URL="https://github.com/openai/codex/releases/download/${VERSION}/checksums.txt"
    fi

    if curl -fsSL "$CHECKSUM_URL" -o "${TEMP_DIR}/checksums.txt"; then
        checksum_line=$(grep -E " ${BINARY_NAME}\\.tar\\.gz$" "${TEMP_DIR}/checksums.txt" | head -1 || true)
        if [ -n "$checksum_line" ]; then
            checksum=$(printf '%s' "$checksum_line" | awk '{print $1}')
            if command -v sha256sum &>/dev/null; then
                echo "${checksum}  ${TEMP_DIR}/codex.tar.gz" | sha256sum -c - || {
                    echo "ERROR: Codex binary checksum verification failed"
                    exit 1
                }
            elif command -v shasum &>/dev/null; then
                echo "${checksum}  ${TEMP_DIR}/codex.tar.gz" | shasum -a 256 -c - || {
                    echo "ERROR: Codex binary checksum verification failed"
                    exit 1
                }
            else
                echo "WARNING: No sha256 tool available; skipping checksum verification" >&2
            fi
        else
            echo "WARNING: No matching checksum found for ${BINARY_NAME}.tar.gz; skipping verification" >&2
        fi
    else
        echo "WARNING: Checksums file not available; skipping verification" >&2
    fi

    # Extract and find the binary (handle different archive structures)
    tar -xzf "${TEMP_DIR}/codex.tar.gz" -C "$TEMP_DIR"

    local CODEX_BIN=""
    for candidate in "${TEMP_DIR}/codex" "${TEMP_DIR}/${BINARY_NAME}" "${TEMP_DIR}"/*/codex; do
        if [ -f "$candidate" ]; then
            CODEX_BIN="$candidate"
            break
        fi
    done

    # If not found, search recursively
    if [ -z "$CODEX_BIN" ]; then
        CODEX_BIN=$(find "$TEMP_DIR" -name "codex" -type f | head -1)
    fi

    if [ -z "$CODEX_BIN" ] || [ ! -f "$CODEX_BIN" ]; then
        echo "ERROR: Could not find codex binary in archive"
        echo "Archive contents:"
        ls -la "$TEMP_DIR"
        exit 1
    fi

    chmod +x "$CODEX_BIN"
    mv "$CODEX_BIN" "${BIN_DIR}/codex"
    echo "Installed codex to ${BIN_DIR}/codex"
}

# ============================================================================
# Main Installation Logic
# ============================================================================

case "$INSTALLMETHOD" in
    npm)
        install_npm
        if ! verify_codex_installation; then
            exit 1
        fi
        ;;
    binary)
        install_binary
        ;;
    *)
        echo "Unknown install method: $INSTALLMETHOD"
        echo "Valid options: npm (recommended), binary"
        exit 1
        ;;
 esac

# Verify installation
if ! command -v codex &> /dev/null; then
    echo "ERROR: Codex installation failed"
    exit 1
fi

echo "Codex installed successfully: $(codex --version)"

# Create default config directory for target user
CONFIG_DIR="${REMOTE_USER_HOME}/.codex"
mkdir -p "$CONFIG_DIR"
if ! chown -R "$REMOTE_USER:$REMOTE_USER" "$CONFIG_DIR" 2>/dev/null; then
    echo "NOTE: Could not change ownership of $CONFIG_DIR to $REMOTE_USER"
    echo "This is expected if running in rootless mode."
fi

# Create default config file with user preferences
cat > "${CONFIG_DIR}/config.toml" << CONFIGEOF
# Codex CLI Configuration
# Generated by devcontainer feature

# Default approval mode: suggest, auto, or full-auto
approval_policy = "${APPROVALMODE}"

# Sandbox mode: workspace-write, full-access, or read-only
sandbox_mode = "${SANDBOXMODE}"

# Uncomment to prefer API key over ChatGPT auth
# preferred_auth_method = "apikey"

# Network access in sandbox mode
[sandbox_workspace_write]
network_access = false
CONFIGEOF

# Ensure correct ownership
chown "$REMOTE_USER:$REMOTE_USER" "${CONFIG_DIR}/config.toml" 2>/dev/null || true

# Persist feature option defaults for runtime scripts
DEFAULTS_DIR="/usr/local/etc"
DEFAULTS_FILE="${DEFAULTS_DIR}/codex-defaults"
mkdir -p "$DEFAULTS_DIR"
> "$DEFAULTS_FILE"
DEFAULTS_GROUP="$(id -gn "$REMOTE_USER" 2>/dev/null || echo root)"
chown root:"$DEFAULTS_GROUP" "$DEFAULTS_FILE" 2>/dev/null || true
chmod 644 "$DEFAULTS_FILE"

# Create remote authentication helper
cat > "${BIN_DIR}/codex-remote-auth" << 'AUTHSCRIPT'
#!/bin/bash
# Helper for authenticating Codex in remote/container environments

DEFAULTS_FILE="/usr/local/etc/codex-defaults"
if [ -f "$DEFAULTS_FILE" ]; then
    # shellcheck source=/usr/local/etc/codex-defaults
    . "$DEFAULTS_FILE"
fi

cat << EOF
================================================================================
OpenAI Codex Remote Authentication Guide
================================================================================

Codex supports multiple authentication methods:

METHOD 1: API Key Authentication (Recommended for Headless/CI)
--------------------------------------------------------------
1. Get your API key from https://platform.openai.com/api-keys

2. Set the environment variable:

   export OPENAI_API_KEY="sk-..."

3. Codex will automatically use the API key

4. To make it permanent, add to your shell config or use:

   echo 'export OPENAI_API_KEY="sk-..."' >> ~/.bashrc


METHOD 2: SSH Port Forwarding (For ChatGPT OAuth)
-------------------------------------------------
1. From your LOCAL machine, connect with port forwarding:

   ssh -L 1455:localhost:1455 user@<container-host>

2. In this container, run:

   codex

3. Select "Sign in with ChatGPT" and open the localhost URL in your LOCAL browser


METHOD 3: Device Code Authentication (Experimental)
---------------------------------------------------
1. Run:

   codex login --device-code

2. Follow the instructions to enter the code at the provided URL


METHOD 4: Copy Existing Credentials
------------------------------------
If authenticated elsewhere, copy ~/.codex/auth.json to this container

================================================================================
EOF
AUTHSCRIPT

chmod +x "${BIN_DIR}/codex-remote-auth"

# Create non-interactive execution helper
cat > "${BIN_DIR}/codex-exec" << 'EXECSCRIPT'
#!/bin/bash
# Run Codex in non-interactive mode

PROMPT="$1"

if [ -z "$PROMPT" ]; then
    echo "Usage: codex-exec \"<prompt>\" [additional options]"
    echo ""
    echo "Examples:"
    echo "  codex-exec \"Run the test suite\""
    echo "  codex-exec \"Fix linting errors\" --full-auto"
    echo "  codex-exec \"Review code\" --approval-mode suggest"
    exit 1
fi

shift
codex exec "$PROMPT" "$@"
EXECSCRIPT

chmod +x "${BIN_DIR}/codex-exec"

# Create MCP server helper
cat > "${BIN_DIR}/codex-mcp-server" << 'MCPSCRIPT'
#!/bin/bash
# Run Codex as an MCP server for other agents

echo "Starting Codex as MCP server..."
echo "Other MCP clients can now connect and use Codex's capabilities."
echo ""
echo "Press Ctrl+C to stop the server."
echo ""

codex mcp serve
MCPSCRIPT

chmod +x "${BIN_DIR}/codex-mcp-server"

# Create status/info script
cat > "${BIN_DIR}/codex-info" << 'INFOSCRIPT'
#!/bin/bash
# Display Codex information and status

echo "OpenAI Codex CLI Information"
echo "============================"
echo ""
echo "Version: $(codex --version 2>/dev/null || echo 'Unknown')"
echo ""

# Check authentication
if [ -f ~/.codex/auth.json ]; then
    echo "Authentication: Credentials file found"
else
    echo "Authentication: Not authenticated"
fi

if [ -n "$OPENAI_API_KEY" ]; then
    echo "API Key: Set (${#OPENAI_API_KEY} characters)"
else
    echo "API Key: Not set"
fi

# Show config
if [ -f ~/.codex/config.toml ]; then
    echo ""
    echo "Configuration (~/.codex/config.toml):"
    grep -E "^[^#]" ~/.codex/config.toml 2>/dev/null | head -10
fi

echo ""
echo "Available Commands:"
echo "  codex              - Start interactive TUI"
echo "  codex exec         - Non-interactive execution"
echo "  codex mcp serve    - Run as MCP server"
echo "  codex login        - Authenticate"
echo ""
echo "Helper Scripts:"
echo "  codex-remote-auth  - Authentication guide"
echo "  codex-exec         - Simplified non-interactive mode"
echo "  codex-mcp-server   - Start as MCP server"
echo "  codex-info         - This information"
INFOSCRIPT

chmod +x "${BIN_DIR}/codex-info"

echo ""
echo "Codex installation complete!"
echo ""
echo "Run 'codex-remote-auth' for authentication instructions."
echo "Run 'codex-info' for available commands and status."
