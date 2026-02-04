#!/bin/bash
set -e

# Feature options
VERSION="${VERSION:-latest}"
ENABLEMCPSERVER="${ENABLEMCPSERVER:-false}"
AUTHMETHOD="${AUTHMETHOD:-none}"
OAUTHPORT="${OAUTHPORT:-52780}"
SKIPPERMISSIONS="${SKIPPERMISSIONS:-false}"
INSTALLMETHOD="${INSTALLMETHOD:-native}"

# Fixed install location (helper scripts use static paths)
BIN_DIR="/usr/local/bin"

# ============================================================================
# Cleanup and Error Handling
# ============================================================================
CLEANUP_FILES=()

cleanup() {
    local exit_code=$?
    for f in "${CLEANUP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null || true
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

echo "Installing Claude Code..."
echo "Target user: $REMOTE_USER"
echo "Target home: $REMOTE_USER_HOME"
echo "Install method: $INSTALLMETHOD"

# ============================================================================
# INSTALLATION METHOD: Native Installer (RECOMMENDED)
# ============================================================================
# The native installer is now the recommended method by Anthropic.
# npm installation is deprecated and will show a warning message.
#
# Key considerations for devcontainers:
# - The native installer installs to ~/.local/bin/claude or ~/.claude/bin/claude
# - When running as root, we need to install for the target non-root user
# - We also create a symlink in /usr/local/bin for system-wide access
# ============================================================================

install_native() {
    echo "Using native installer (recommended by Anthropic)..."

    if ! command -v curl &> /dev/null; then
        echo "ERROR: curl not found. Install curl or use installMethod: npm"
        exit 1
    fi

    if [ "$REMOTE_USER" != "root" ] && [ "$(whoami)" = "root" ]; then
        mkdir -p "${REMOTE_USER_HOME}/.local/state" "${REMOTE_USER_HOME}/.local/bin"
        chown "$REMOTE_USER:$REMOTE_USER" "$REMOTE_USER_HOME" 2>/dev/null || true
        chown -R "$REMOTE_USER:$REMOTE_USER" "${REMOTE_USER_HOME}/.local" 2>/dev/null || true
    fi

    # Download installer to temporary file (more secure than curl | bash)
    local INSTALLER="/tmp/claude-install-$$.sh"
    CLEANUP_FILES+=("$INSTALLER")

    if ! curl -fsSL https://claude.ai/install.sh -o "$INSTALLER"; then
        echo "ERROR: Failed to download Claude Code installer"
        exit 1
    fi

    chmod +x "$INSTALLER"

    # Create install directory for the target user
    local INSTALL_DIR="${REMOTE_USER_HOME}/.local/bin"
    mkdir -p "$INSTALL_DIR"

    # Download and run installer as the target user
    if [ "$REMOTE_USER" != "root" ] && [ "$(whoami)" = "root" ]; then
        # Running as root, but installing for non-root user
        echo "Installing as user: $REMOTE_USER"

        # Run installer as target user
        # Note: Native installer version pinning support may vary
        if [ "$VERSION" = "latest" ]; then
            su - "$REMOTE_USER" -c "bash $INSTALLER"
        else
            # Try passing version; fall back to latest if not supported
            if ! su - "$REMOTE_USER" -c "bash $INSTALLER --version $VERSION" 2>/dev/null; then
                echo "NOTE: Installer may not support version pinning. Installing latest."
                echo "For specific versions, use installMethod: npm"
                su - "$REMOTE_USER" -c "bash $INSTALLER"
            fi
        fi
    else
        # Running as the target user or root is the target
        if [ "$VERSION" = "latest" ]; then
            bash "$INSTALLER"
        else
            if ! bash "$INSTALLER" --version "$VERSION" 2>/dev/null; then
                echo "NOTE: Installer may not support version pinning. Installing latest."
                bash "$INSTALLER"
            fi
        fi
    fi
}

# ============================================================================
# INSTALLATION METHOD: npm (DEPRECATED - fallback only)
# ============================================================================
# This method is deprecated by Anthropic and shows a warning message.
# Only use if native installer fails or for specific compatibility needs.
# ============================================================================

install_npm() {
    echo "WARNING: npm installation is DEPRECATED by Anthropic."
    echo "You will see a deprecation warning when running claude."
    echo "Consider switching to native installer (installMethod: native)."
    echo ""

    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        echo "ERROR: npm not found. Install Node.js or use installMethod: native"
        exit 1
    fi

    # Install globally - avoid sudo npm install -g
    if [ "$VERSION" = "latest" ]; then
        npm install -g @anthropic-ai/claude-code
    else
        npm install -g @anthropic-ai/claude-code@"$VERSION"
    fi
}

# ============================================================================
# Main Installation Logic
# ============================================================================

case "$INSTALLMETHOD" in
    native)
        install_native
        ;;
    npm)
        install_npm
        ;;
    *)
        echo "Unknown install method: $INSTALLMETHOD"
        echo "Valid options: native (recommended), npm (deprecated)"
        exit 1
        ;;
 esac

# Verify installation
CLAUDE_BIN=""
if ! command -v claude &> /dev/null; then
    # Check user-specific paths
    for check_path in "${REMOTE_USER_HOME}/.local/bin/claude" "${REMOTE_USER_HOME}/.claude/bin/claude" "/usr/local/bin/claude"; do
        if [ -x "$check_path" ]; then
            echo "Claude found at: $check_path"
            CLAUDE_BIN="$check_path"
            # Ensure it's in PATH for verification
            export PATH="$PATH:$(dirname "$check_path")"
            break
        fi
    done
fi

if [ -n "$CLAUDE_BIN" ] && [ ! -x "${BIN_DIR}/claude" ]; then
    ln -sf "$CLAUDE_BIN" "${BIN_DIR}/claude"
fi

# Final verification
if command -v claude &> /dev/null; then
    echo "Claude Code installed successfully: $(claude --version 2>/dev/null || echo 'version check failed')"
else
    echo "WARNING: claude command not found in PATH"
    echo "It may be installed in user-specific directory."
    echo "The user should have it available after login."
fi

# Run initial setup if skip permissions is enabled (for headless environments)
if [ "$SKIPPERMISSIONS" = "true" ]; then
    echo "Running initial setup with permissions skip..."
    if ! claude --dangerously-skip-permissions --help > /dev/null 2>&1; then
        echo "NOTE: Initial setup command returned non-zero exit code."
        echo "This may be expected if Claude Code requires authentication first."
        echo "Run 'claude-remote-auth' for authentication instructions."
    fi
fi

# Create helper script for remote authentication
cat > "${BIN_DIR}/claude-remote-auth" << 'AUTHSCRIPT'
#!/bin/bash
# Helper script for authenticating Claude Code in remote/container environments

OAUTH_PORT="${CLAUDE_CODE_OAUTH_PORT:-52780}"

cat << EOF
================================================================================
Claude Code Remote Authentication Guide
================================================================================

Claude Code requires browser-based OAuth authentication. In a container or
remote environment, follow these steps:

METHOD 1: SSH Port Forwarding (Recommended for OAuth)
------------------------------------------------------
1. From your LOCAL machine, connect with port forwarding:

   ssh -L ${OAUTH_PORT}:localhost:${OAUTH_PORT} user@<container-host>

2. In this container, run:

   claude /login

3. When prompted, open the URL in your LOCAL browser (it will use localhost)

4. Complete the authentication in the browser


METHOD 2: API Key Authentication (Headless/CI)
----------------------------------------------
1. Get your API key from https://console.anthropic.com/

2. Set the environment variable:

   export ANTHROPIC_API_KEY="your-api-key-here"

3. Claude Code will automatically use the API key


METHOD 3: Copy Existing Credentials
------------------------------------
If you've authenticated on another machine, you can copy the credentials:

1. On your authenticated machine, locate:
   ~/.claude/credentials.json

2. Copy this file to the same location in this container


Current OAuth Port: ${OAUTH_PORT}
================================================================================
EOF
AUTHSCRIPT

chmod +x "${BIN_DIR}/claude-remote-auth"

# Create headless execution helper
cat > "${BIN_DIR}/claude-headless" << 'HEADLESSSCRIPT'
#!/bin/bash
# Run Claude Code in headless mode with common options

PROMPT="$1"
shift

if [ -z "$PROMPT" ]; then
    echo "Usage: claude-headless \"<prompt>\" [additional claude options]"
    echo ""
    echo "Examples:"
    echo "  claude-headless \"Review this codebase for security issues\""
    echo "  claude-headless \"Fix the bug in main.py\" --output-format json"
    echo "  cat file.py | claude-headless \"Explain this code\""
    exit 1
fi

claude -p "$PROMPT" "$@"
HEADLESSSCRIPT

chmod +x "${BIN_DIR}/claude-headless"

# Create MCP server helper if enabled
cat > "${BIN_DIR}/claude-mcp-server" << 'MCPSCRIPT'
#!/bin/bash
# Run Claude Code as an MCP server for other agents

echo "Starting Claude Code as MCP server..."
echo "Other MCP clients can now connect and use Claude Code's tools."
echo ""
echo "Available tools when connected:"
echo "  - Bash: Execute shell commands"
echo "  - Read: Read file contents"
echo "  - Write: Write to files"
echo "  - Edit: Edit existing files"
echo "  - LS: List directory contents"
echo "  - GrepTool: Search files"
echo "  - GlobTool: Find files by pattern"
echo ""

claude mcp serve
MCPSCRIPT

chmod +x "${BIN_DIR}/claude-mcp-server"

# Create status/info script
cat > "${BIN_DIR}/claude-info" << 'INFOSCRIPT'
#!/bin/bash
# Display Claude Code information and status

echo "Claude Code Information"
echo "======================="
echo ""
echo "Version: $(claude --version 2>/dev/null || echo 'Unknown')"
echo ""

# Check authentication status
if [ -f ~/.claude/credentials.json ]; then
    echo "Authentication: Credentials file found"
else
    echo "Authentication: Not authenticated"
fi

if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "API Key: Set (${#ANTHROPIC_API_KEY} characters)"
else
    echo "API Key: Not set"
fi

echo ""
echo "Available Commands:"
echo "  claude              - Start interactive mode"
echo "  claude -p \"prompt\"  - Headless mode"
echo "  claude mcp serve    - Run as MCP server"
echo "  claude /login       - Authenticate"
echo ""
echo "Helper Scripts:"
echo "  claude-remote-auth  - Authentication guide for containers"
echo "  claude-headless     - Simplified headless execution"
echo "  claude-mcp-server   - Start as MCP server"
echo "  claude-info         - This information"
INFOSCRIPT

chmod +x "${BIN_DIR}/claude-info"

echo ""
echo "Claude Code installation complete!"
echo ""
echo "Run 'claude-remote-auth' for authentication instructions in this environment."
echo "Run 'claude-info' for available commands and status."
