#!/bin/bash
# Note: Uses set -e for error handling; consider set -euo pipefail for stricter behavior
set -e

# Feature options (passed as environment variables)
VERSION="${VERSION:-latest}"
INSTALLMETHOD="${INSTALLMETHOD:-native}"
ENABLESERVER="${ENABLESERVER:-false}"
# Note: Default port 4096 may collide with other services. Users can configure via SERVERPORT environment variable.
SERVERPORT="${SERVERPORT:-4096}"
SERVERHOSTNAME="${SERVERHOSTNAME:-127.0.0.1}"
SERVERPASSWORD="${SERVERPASSWORD:-}"
ENABLEMDNS="${ENABLEMDNS:-false}"
ENABLEWEBMODE="${ENABLEWEBMODE:-false}"
CORSORIGINS="${CORSORIGINS:-}"

# Fixed install location (postStartCommand requires static path)
BIN_DIR="/usr/local/bin"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

SERVERPORT="$(validate_port "$SERVERPORT" "4096" "server")"

# Ensure bin directory exists
mkdir -p "$BIN_DIR"

echo "Installing OpenCode..."
echo "Target user: $REMOTE_USER"
echo "Target home: $REMOTE_USER_HOME"
echo "Install method: $INSTALLMETHOD"

# ============================================================================
# INSTALLATION METHOD: Native Installer (RECOMMENDED)
# ============================================================================
# OpenCode supports environment variables to control installation directory:
# - OPENCODE_INSTALL_DIR: Custom installation directory
# - XDG_BIN_DIR: XDG standard bin directory
# ============================================================================

install_native() {
    echo "Using native installer..."

    if ! command -v curl &> /dev/null; then
        echo "ERROR: curl not found. Install curl or use installMethod: npm"
        exit 1
    fi

    local INSTALLER="/tmp/opencode-install-$$.sh"
    CLEANUP_FILES+=("$INSTALLER")

    # Download installer to temporary file (more secure than curl | bash)
    if ! curl -fsSL https://opencode.ai/install -o "$INSTALLER"; then
        echo "ERROR: Failed to download OpenCode installer"
        exit 1
    fi

    # Verify download integrity if hash is provided
    verify_download() {
        local file="$1"
        local expected_hash="$2"
        local algorithm="${3:-sha256}"

        if [ -z "$expected_hash" ]; then
            echo "INFO: No checksum provided. Skipping integrity verification." >&2
            return 0
        fi

        local actual_hash
        case "$algorithm" in
            sha256)
                actual_hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
                ;;
            sha1)
                actual_hash=$(sha1sum "$file" 2>/dev/null | cut -d' ' -f1)
                ;;
            md5)
                actual_hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
                ;;
            *)
                echo "ERROR: Unsupported hash algorithm: $algorithm" >&2
                return 1
                ;;
        esac

        if [ "$actual_hash" = "$expected_hash" ]; then
            return 0
        else
            echo "ERROR: $algorithm checksum mismatch!" >&2
            echo "  Expected: $expected_hash" >&2
            echo "  Actual:   $actual_hash" >&2
            exit 1
        fi
    }

    # Optional: Set OPENCODE_SHA256 environment variable to verify integrity
    if [ -n "${OPENCODE_SHA256:-}" ]; then
        verify_download "$INSTALLER" "$OPENCODE_SHA256" sha256
    else
        echo "INFO: Set OPENCODE_SHA256 environment variable for download verification" >&2
    fi

    chmod +x "$INSTALLER"

    if [ "$REMOTE_USER" != "root" ] && [ "$(whoami)" = "root" ]; then
        # Install as target user so the installer doesn't land in /root
        mkdir -p "${REMOTE_USER_HOME}/.local/bin" "${REMOTE_USER_HOME}/.local/state"
        chown -R "$REMOTE_USER:$REMOTE_USER" "${REMOTE_USER_HOME}/.local" 2>/dev/null || true

        if [ "$VERSION" = "latest" ]; then
            su - "$REMOTE_USER" -c "OPENCODE_INSTALL_DIR=\"${REMOTE_USER_HOME}/.local/bin\" XDG_BIN_DIR=\"${REMOTE_USER_HOME}/.local/bin\" env -u VERSION -u OPENCODE_VERSION bash \"$INSTALLER\""
        else
            # Note: Version pinning support varies by installer
            if ! su - "$REMOTE_USER" -c "OPENCODE_INSTALL_DIR=\"${REMOTE_USER_HOME}/.local/bin\" XDG_BIN_DIR=\"${REMOTE_USER_HOME}/.local/bin\" env -u VERSION -u OPENCODE_VERSION bash \"$INSTALLER\" \"$VERSION\"" 2>/dev/null; then
                echo "NOTE: Installer may not support version pinning. Installing latest."
                su - "$REMOTE_USER" -c "OPENCODE_INSTALL_DIR=\"${REMOTE_USER_HOME}/.local/bin\" XDG_BIN_DIR=\"${REMOTE_USER_HOME}/.local/bin\" env -u VERSION -u OPENCODE_VERSION bash \"$INSTALLER\""
            fi
        fi
    else
        # Install to /usr/local/bin for system-wide access
        export OPENCODE_INSTALL_DIR="$BIN_DIR"
        export XDG_BIN_DIR="$BIN_DIR"

        if [ "$VERSION" = "latest" ]; then
            env -u VERSION -u OPENCODE_VERSION bash "$INSTALLER"
        else
            # Note: Version pinning support varies by installer
            if ! env -u VERSION -u OPENCODE_VERSION bash "$INSTALLER" "$VERSION" 2>/dev/null; then
                echo "NOTE: Installer may not support version pinning. Installing latest."
                env -u VERSION -u OPENCODE_VERSION bash "$INSTALLER"
            fi
        fi
    fi
}

# Verify installation and create symlink if needed
verify_opencode_installation() {
    if command -v opencode &> /dev/null; then
        return 0
    fi

    local npm_global_bin=""
    if command -v npm &> /dev/null; then
        npm_global_bin="$(npm prefix -g)/bin"
    fi

    local candidates=(
        "$BIN_DIR/opencode"
        "/usr/local/bin/opencode"
        "${npm_global_bin}/opencode"
        "${REMOTE_USER_HOME}/.local/bin/opencode"
        "${REMOTE_USER_HOME}/.opencode/bin/opencode"
        "${REMOTE_USER_HOME}/.local/share/opencode/bin/opencode"
    )

    if [ "$REMOTE_USER" = "root" ]; then
        candidates+=(
            "/root/.local/bin/opencode"
            "/root/.opencode/bin/opencode"
            "/root/.local/share/opencode/bin/opencode"
        )
    fi

    for candidate in "${candidates[@]}"; do
        if [ -n "$candidate" ] && [ -x "$candidate" ]; then
            ln -sf "$candidate" "${BIN_DIR}/opencode"
            export PATH="${BIN_DIR}:$PATH"
            return 0
        fi
    done

    if command -v find &> /dev/null; then
        local found
        if [ "$REMOTE_USER" = "root" ]; then
            found=$(find "$REMOTE_USER_HOME" /root -maxdepth 4 -type f -name opencode -perm -u+x 2>/dev/null | head -1)
        else
            found=$(find "$REMOTE_USER_HOME" -maxdepth 4 -type f -name opencode -perm -u+x 2>/dev/null | head -1)
        fi
        if [ -n "$found" ]; then
            ln -sf "$found" "${BIN_DIR}/opencode"
            export PATH="${BIN_DIR}:$PATH"
            return 0
        fi
    fi

    echo "ERROR: opencode CLI not found after install."
    if [ -n "$npm_global_bin" ]; then
        echo "DEBUG: npm prefix -g = $(npm prefix -g 2>/dev/null || echo 'failed')"
        echo "DEBUG: Contents of ${npm_global_bin}:"
        ls -la "${npm_global_bin}" 2>/dev/null || echo "Directory not found"
    fi
    return 1
}

# ============================================================================
# INSTALLATION METHOD: npm
# ============================================================================
# Alternative method using npm. Package name is 'opencode-ai'.
# ============================================================================

install_npm() {
    echo "Using npm installer..."

    if ! command -v npm &> /dev/null; then
        echo "ERROR: npm not found. Install Node.js or use installMethod: native"
        exit 1
    fi

    if [ "$VERSION" = "latest" ]; then
        npm install -g opencode-ai@latest
    else
        npm install -g opencode-ai@"$VERSION"
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
        echo "Valid options: native, npm"
        exit 1
        ;;
esac

# Verify installation
if ! verify_opencode_installation; then
    echo "ERROR: OpenCode installation failed"
    exit 1
fi

echo "OpenCode installed successfully: $(opencode --version)"

# Persist feature option defaults for runtime scripts
DEFAULTS_DIR="/usr/local/etc"
DEFAULTS_FILE="${DEFAULTS_DIR}/opencode-defaults"
mkdir -p "$DEFAULTS_DIR"

{
    printf 'OPENCODE_ENABLE_SERVER_DEFAULT=%q\n' "$ENABLESERVER"
    printf 'OPENCODE_SERVER_PORT_DEFAULT=%q\n' "$SERVERPORT"
    printf 'OPENCODE_SERVER_HOSTNAME_DEFAULT=%q\n' "$SERVERHOSTNAME"
    # Force quotes for password to ensure it's handled correctly by shells and regex
    printf 'OPENCODE_SERVER_PASSWORD_DEFAULT="%s"\n' "$SERVERPASSWORD"
    printf 'OPENCODE_ENABLE_MDNS_DEFAULT=%q\n' "$ENABLEMDNS"
    printf 'OPENCODE_ENABLE_WEB_DEFAULT=%q\n' "$ENABLEWEBMODE"
    printf 'OPENCODE_CORS_ORIGINS_DEFAULT=%q\n' "$CORSORIGINS"
    printf 'OPENCODE_PLUGINS_DEFAULT=%q\n' "$PLUGINS"
} > "$DEFAULTS_FILE"
DEFAULTS_GROUP="$(id -gn "$REMOTE_USER" 2>/dev/null || echo root)"
chown root:"$DEFAULTS_GROUP" "$DEFAULTS_FILE" 2>/dev/null || true
chmod 640 "$DEFAULTS_FILE"


# Create /etc/profile.d initialization script for interactive shells
cat > /etc/profile.d/00-opencode-init.sh << 'PROFILEEOF'
# Source OpenCode defaults
if [ -f "/usr/local/etc/opencode-defaults" ]; then
    . "/usr/local/etc/opencode-defaults"
fi

# Export server password and plugins if default is set
if [ -n "$OPENCODE_SERVER_PASSWORD_DEFAULT" ]; then
    export OPENCODE_SERVER_PASSWORD="$OPENCODE_SERVER_PASSWORD_DEFAULT"
fi
# Plugins are handled by server start script / config file logic
PROFILEEOF
chmod 644 /etc/profile.d/00-opencode-init.sh

# Inject into user's rc files for interactive shells
RC_SNIPPET='
# OpenCode configuration
if [ -f "/usr/local/etc/opencode-defaults" ]; then
    . "/usr/local/etc/opencode-defaults"
    if [ -n "$OPENCODE_SERVER_PASSWORD_DEFAULT" ]; then
        export OPENCODE_SERVER_PASSWORD="$OPENCODE_SERVER_PASSWORD_DEFAULT"
    fi
fi
'

update_rc_file() {
    local rc_file="$1"
    if [ -f "$rc_file" ]; then
        if ! grep -q "OpenCode configuration" "$rc_file"; then
            echo "$RC_SNIPPET" >> "$rc_file"
            echo "Updated $rc_file"
        fi
    fi
}

update_rc_file "${REMOTE_USER_HOME}/.bashrc"
update_rc_file "${REMOTE_USER_HOME}/.zshrc"



# Plugin Installation (Optional)
# ============================================================================
# Plugins are now handled by creating/updating ~/.config/opencode/opencode.json
# at runtime (in opencode-server-start.sh) to support volume persistence.
# Global npm install is removed.

# ============================================================================
# Ensure Permissions for Data Directories
# ============================================================================
# Pre-create XDG directories to ensure they have correct permissions
# even when mounted as volumes (Docker creates missing mount points as root).
if [ "$REMOTE_USER" != "root" ]; then
    echo "Ensuring data directories exist with correct permissions for $REMOTE_USER..."
    for subdir in ".config/opencode" ".local/share/opencode" ".cache/opencode" ".opencode"; do
        FULL_PATH="${REMOTE_USER_HOME}/${subdir}"
        if [ ! -d "$FULL_PATH" ]; then
            echo "Creating $FULL_PATH"
            mkdir -p "$FULL_PATH"
        fi
        
        if [ "$(id -u)" = "0" ]; then
            chown -R "$REMOTE_USER:$(id -gn "$REMOTE_USER" 2>/dev/null || echo root)" "$FULL_PATH"
        fi
    done
    
    # Also ensure parent directories map back to user if created
    # specifically .config, .local/share, .cache
    for parent in ".config" ".local/share" ".local" ".cache"; do
         P_PATH="${REMOTE_USER_HOME}/${parent}"
         if [ -d "$P_PATH" ] && [ "$(stat -c '%u' "$P_PATH")" = "0" ]; then
             echo "Fixing permissions for parent: $P_PATH"
             chown "$REMOTE_USER:$(id -gn "$REMOTE_USER" 2>/dev/null || echo root)" "$P_PATH"
         fi
    done
fi


# Create the server startup script
cat > "${BIN_DIR}/opencode-server-start.sh" << 'SERVERSCRIPT'
#!/bin/bash

# Configuration from environment or feature defaults
DEFAULTS_FILE="/usr/local/etc/opencode-defaults"
DEFAULTS_LOADED="false"
if [ -f "$DEFAULTS_FILE" ]; then
    # shellcheck source=/usr/local/etc/opencode-defaults
    . "$DEFAULTS_FILE"
    DEFAULTS_LOADED="true"
fi

ENABLE_SERVER="${OPENCODE_ENABLE_SERVER:-${OPENCODE_ENABLE_SERVER_DEFAULT:-false}}"
PORT="${OPENCODE_SERVER_PORT:-${OPENCODE_SERVER_PORT_DEFAULT:-4096}}"
HOSTNAME="${OPENCODE_SERVER_HOSTNAME:-${OPENCODE_SERVER_HOSTNAME_DEFAULT:-127.0.0.1}}"
ENABLE_MDNS="${OPENCODE_ENABLE_MDNS:-${OPENCODE_ENABLE_MDNS_DEFAULT:-false}}"
ENABLE_WEB="${OPENCODE_ENABLE_WEB:-${OPENCODE_ENABLE_WEB_DEFAULT:-false}}"
CORS_ORIGINS="${OPENCODE_CORS_ORIGINS:-${OPENCODE_CORS_ORIGINS_DEFAULT:-}}"
PLUGINS="${OPENCODE_PLUGINS:-${OPENCODE_PLUGINS_DEFAULT:-}}"

# Configure Plugins (if specified)
# This handles persistence even with volumes by ensuring the config exists at runtime
if [ -n "$PLUGINS" ]; then
    CONFIG_DIR="${HOME}/.config/opencode"
    CONFIG_FILE="${CONFIG_DIR}/opencode.json"
    
    # Ensure config dir exists
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Initializing OpenCode configuration with plugins..."
        # Create new config file
        # Convert comma-separated string to JSON array
        # Note: simplistic parsing, assumes no commas in plugin names
        IFS=',' read -ra ADDR <<< "$PLUGINS"
        JSON_ARRAY="["
        FIRST=true
        for i in "${ADDR[@]}"; do
            # Trim whitespace
            plugin=$(echo "$i" | xargs)
            if [ -n "$plugin" ]; then
                # Escape JSON special characters: backslash and double quote
                plugin=$(printf '%s' "$plugin" | sed 's/\\/\\\\/g; s/"/\\"/g')
                if [ "$FIRST" = true ]; then
                    JSON_ARRAY="$JSON_ARRAY\"$plugin\""
                    FIRST=false
                else
                    JSON_ARRAY="$JSON_ARRAY, \"$plugin\""
                fi
            fi
        done
        JSON_ARRAY="$JSON_ARRAY]"

        cat > "$CONFIG_FILE" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "plugin": $JSON_ARRAY
}
EOF
        echo "Created $CONFIG_FILE with plugins: $PLUGINS"
    else
        echo "OpenCode configuration already exists at $CONFIG_FILE. Skipping plugin auto-configuration to avoid overwrite."
        echo "Please ensure the following plugins are in your config if needed: $PLUGINS"
    fi
fi

validate_port() {
    local value="$1"
    local fallback="$2"

    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
        echo "$value"
        return 0
    fi

    echo "WARNING: Invalid server port '$value'. Using ${fallback}." >&2
    echo "$fallback"
}

PORT="$(validate_port "$PORT" "4096")"

# Only start if server mode is enabled
if [ "$ENABLE_SERVER" != "true" ]; then
    if [ "$DEFAULTS_LOADED" = "true" ] || [ -n "$OPENCODE_ENABLE_SERVER" ]; then
        echo "OpenCode server mode not enabled. Set enableServer: true to enable."
    fi
    exit 0
fi

# Export password if set (from env or defaults)
SERVER_PASSWORD="${OPENCODE_SERVER_PASSWORD:-${OPENCODE_SERVER_PASSWORD_DEFAULT:-}}"
if [ -n "$SERVER_PASSWORD" ]; then
    export OPENCODE_SERVER_PASSWORD="$SERVER_PASSWORD"
fi

# Detect devcontainer environment
if [ -z "$DEVCONTAINER" ] && [ -z "$CODESPACES" ] && [ -z "$REMOTE_CONTAINERS" ]; then
    echo "NOTE: Running outside detected devcontainer environment."
    echo "If server doesn't auto-start, add postStartCommand to your devcontainer.json"
fi

# ============================================================================
# Secure PID File Handling
# ============================================================================
# Use XDG_RUNTIME_DIR if available (user-specific, protected directory)
# Fall back to user-specific directory in /tmp with restrictive permissions
# Includes symlink attack protection
_get_pid_dir() {
    local pid_dir="${XDG_RUNTIME_DIR:-}"
    if [ -z "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
        pid_dir="/tmp/opencode-$(id -u)"
        # Symlink attack protection: fail if path exists as symlink
        if [ -L "$pid_dir" ]; then
            echo "ERROR: $pid_dir is a symlink. Possible security issue." >&2
            exit 1
        fi
        if ! mkdir -p "$pid_dir"; then
            echo "ERROR: Could not create PID directory: $pid_dir" >&2
            exit 1
        fi
        if [ -L "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
            echo "ERROR: PID directory is not a directory: $pid_dir" >&2
            exit 1
        fi
        chmod 700 "$pid_dir"
    fi
    echo "$pid_dir"
}

PID_DIR="$(_get_pid_dir)"
PID_FILE="${PID_DIR}/opencode-server.pid"
PID_LOCK_FILE="${PID_DIR}/opencode-server.lock"
LOG_FILE="${PID_DIR}/opencode-server.log"

# Prevent duplicate server instances using flock for atomic locking
exec 200>"$PID_LOCK_FILE"
if ! flock -n 200; then
    echo "ERROR: Another instance of OpenCode server is starting. If this is stale, remove: $PID_LOCK_FILE" >&2
    exit 1
fi

# Check PID file with proper locking
if [ -f "$PID_FILE" ]; then
    PID="$(cat "$PID_FILE")"
    if kill -0 "$PID" 2>/dev/null; then
        echo "OpenCode server already running (PID: $PID)."
        exit 0
    else
        echo "Removing stale PID file."
        rm -f "$PID_FILE"
    fi
fi

# Build command arguments safely
ARGS=(--port "$PORT" --hostname "$HOSTNAME")

if [ "$ENABLE_MDNS" = "true" ]; then
    ARGS+=(--mdns)
fi

# ============================================================================
# CORS Origin Validation (Security: prevent shell injection)
# ============================================================================
trim_whitespace() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

if [ -n "$CORS_ORIGINS" ]; then
    IFS=',' read -ra ORIGINS <<< "$CORS_ORIGINS"
    for origin in "${ORIGINS[@]}"; do
        # Trim whitespace
        origin="$(trim_whitespace "$origin")"

        # Auto-fix: Prepend http:// if scheme is missing (common user error)
        if [[ ! "$origin" =~ ^https?:// ]]; then
            origin="http://${origin}"
        fi

        # Improved CORS origin validation
        # Supports: IPv4 (http://1.2.3.4:8080), IPv6 (http://[::1]:8080), hostnames, trailing slashes
        # Rejects suspicious characters
        if [[ "$origin" =~ ^https?://(\[[0-9a-fA-F:]+\]|[a-zA-Z0-9._-]+)(:[0-9]+)?/?$ ]]; then
            ARGS+=(--cors "$origin")
        else
            echo "WARNING: Skipping invalid CORS origin: $origin" >&2
            echo "  CORS origins must be scheme://host[:port] format" >&2
            echo "  Supports IPv4, IPv6, and hostnames" >&2
        fi
    done
fi

# If OPENCODE_SERVER_PASSWORD is set at runtime, authentication is enabled
if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
    echo "OpenCode server authentication enabled"
    echo "  Username: ${OPENCODE_SERVER_USERNAME:-opencode} (default: opencode)"
    echo "  Password: (set via OPENCODE_SERVER_PASSWORD)"
else
    if [ "$HOSTNAME" = "0.0.0.0" ]; then
        echo "WARNING: Server bound to 0.0.0.0. This exposes the server to all network interfaces."
        echo "  Ensure OPENCODE_SERVER_PASSWORD is set for authentication!"
    fi
fi

# ============================================================================
# Log Rotation (rotate if > 10MB)
# ============================================================================
MAX_LOG_SIZE=10485760
if [ -f "$LOG_FILE" ]; then
    size=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        echo "Log rotated at $(date)" > "$LOG_FILE"
    fi
fi

# ============================================================================
# Diagnostic Logging
# ============================================================================
{
    echo "--- Server Start: $(date) ---"
    echo "User: $(whoami)"
    echo "PATH: $PATH"
    echo "PID_DIR: $PID_DIR ($(ls -ld "$PID_DIR" 2>/dev/null))"
    echo "Command: $(command -v opencode || echo 'not found')"
    echo "Version: $(opencode --version 2>&1 || echo 'failed to get version')"
    
    echo "--- Configuration ---"
    if [ -f "$DEFAULTS_FILE" ]; then
        echo "Defaults File: $DEFAULTS_FILE"
        echo "Properties (masked):"
        sed 's/PASSWORD_DEFAULT=.*/PASSWORD_DEFAULT=[MASKED]/' "$DEFAULTS_FILE"
    else
        echo "Defaults File: NOT FOUND"
    fi
} | tee -a "$LOG_FILE"

# Start the appropriate server mode (append to log)
if [ "$ENABLE_WEB" = "true" ]; then
    echo "Starting OpenCode web server on ${HOSTNAME}:${PORT}..."
    if command -v setsid >/dev/null 2>&1; then
        setsid opencode web "${ARGS[@]}" < /dev/null >> "$LOG_FILE" 2>&1 &
    else
        nohup opencode web "${ARGS[@]}" < /dev/null >> "$LOG_FILE" 2>&1 &
    fi
    disown
else
    echo "Starting OpenCode headless server on ${HOSTNAME}:${PORT}..."
    if command -v setsid >/dev/null 2>&1; then
        setsid opencode serve "${ARGS[@]}" < /dev/null >> "$LOG_FILE" 2>&1 &
    else
        nohup opencode serve "${ARGS[@]}" < /dev/null >> "$LOG_FILE" 2>&1 &
    fi
    disown
fi

SERVER_PID=$!
# Use localhost for display URLs when bound to 0.0.0.0 (not a routable address)
DISPLAY_HOST="$HOSTNAME"
[ "$HOSTNAME" = "0.0.0.0" ] && DISPLAY_HOST="localhost"

echo "OpenCode server started with PID: $SERVER_PID"
echo "Server logs: $LOG_FILE"
echo ""
echo "To connect from another machine:"
echo "  opencode attach http://<container-ip>:${PORT}"
echo ""
echo "API documentation available at:"
echo "  http://${DISPLAY_HOST}:${PORT}/doc"

# Save PID for later management
echo "$SERVER_PID" > "$PID_FILE"

# Immediate health check to catch crash-on-start
sleep 2
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "ERROR: OpenCode server process ($SERVER_PID) died immediately after starting." >&2
    echo "Application Logs:" >&2
    echo "---------------------------------------------------" >&2
    cat "$LOG_FILE" >&2
    echo "---------------------------------------------------" >&2
    exit 1
    fi
    
SERVERSCRIPT

chmod +x "${BIN_DIR}/opencode-server-start.sh"

# Create helper script for connecting to remote OpenCode servers
cat > "${BIN_DIR}/opencode-connect" << 'CONNECTSCRIPT'
#!/bin/bash
# Helper script to attach to a running OpenCode server

HOSTNAME="${1:-localhost}"
PORT="${2:-4096}"
URL="http://${HOSTNAME}:${PORT}"

echo "Connecting to OpenCode server at ${URL}..."
opencode attach "${URL}"
CONNECTSCRIPT

chmod +x "${BIN_DIR}/opencode-connect"

# Create helper script for stopping the server
cat > "${BIN_DIR}/opencode-server-stop" << 'STOPSCRIPT'
#!/bin/bash
# Stop the OpenCode server

# Use same PID directory logic as start script (with symlink protection)
_get_pid_dir() {
    local pid_dir="${XDG_RUNTIME_DIR:-}"
    if [ -z "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
        pid_dir="/tmp/opencode-$(id -u)"
        if [ -L "$pid_dir" ]; then
            echo "ERROR: $pid_dir is a symlink. Possible security issue." >&2
            exit 1
        fi
        if ! mkdir -p "$pid_dir"; then
            echo "ERROR: Could not create PID directory: $pid_dir" >&2
            exit 1
        fi
        if [ -L "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
            echo "ERROR: PID directory is not a directory: $pid_dir" >&2
            exit 1
        fi
        chmod 700 "$pid_dir"
    fi
    echo "$pid_dir"
}

PID_DIR="$(_get_pid_dir)"
PID_FILE="${PID_DIR}/opencode-server.pid"
PID_LOCK_FILE="${PID_DIR}/opencode-server.lock"

# Acquire lock for atomic PID file operations
exec 200>"$PID_LOCK_FILE"
flock -n 200 || {
    echo "ERROR: Cannot acquire lock. Another operation is in progress." >&2
    exit 1
}

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping OpenCode server (PID: $PID)..."
        kill "$PID"
        rm -f "$PID_FILE"
        echo "Server stopped."
    else
        echo "Server process not running."
        rm -f "$PID_FILE"
    fi
else
    echo "No server PID file found. Server may not be running."
fi
STOPSCRIPT
chmod +x "${BIN_DIR}/opencode-server-stop"

# Create server status script (rest of file)

# Create status check script with health verification
cat > "${BIN_DIR}/opencode-server-status" << 'STATUSSCRIPT'
#!/bin/bash
# Check OpenCode server status with health verification

# Use same PID directory logic as start script (with symlink protection)
_get_pid_dir() {
    local pid_dir="${XDG_RUNTIME_DIR:-}"
    if [ -z "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
        pid_dir="/tmp/opencode-$(id -u)"
        if [ -L "$pid_dir" ]; then
            echo "ERROR: $pid_dir is a symlink. Possible security issue." >&2
            exit 1
        fi
        if ! mkdir -p "$pid_dir"; then
            echo "ERROR: Could not create PID directory: $pid_dir" >&2
            exit 1
        fi
        if [ -L "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
            echo "ERROR: PID directory is not a directory: $pid_dir" >&2
            exit 1
        fi
        chmod 700 "$pid_dir"
    fi
    echo "$pid_dir"
}

PID_DIR="$(_get_pid_dir)"
PID_FILE="${PID_DIR}/opencode-server.pid"
LOG_FILE="${PID_DIR}/opencode-server.log"

DEFAULTS_FILE="/usr/local/etc/opencode-defaults"
if [ -f "$DEFAULTS_FILE" ]; then
    # shellcheck source=/usr/local/etc/opencode-defaults
    . "$DEFAULTS_FILE"
fi

PORT="${OPENCODE_SERVER_PORT:-${OPENCODE_SERVER_PORT_DEFAULT:-4096}}"
HOSTNAME="${OPENCODE_SERVER_HOSTNAME:-${OPENCODE_SERVER_HOSTNAME_DEFAULT:-127.0.0.1}}"

# Ensure password is set from defaults if available
if [ -z "$OPENCODE_SERVER_PASSWORD" ] && [ -n "$OPENCODE_SERVER_PASSWORD_DEFAULT" ]; then
    OPENCODE_SERVER_PASSWORD="$OPENCODE_SERVER_PASSWORD_DEFAULT"
fi

validate_port() {
    local value="$1"
    local fallback="$2"

    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
        echo "$value"
        return 0
    fi

    echo "$fallback"
}

PORT="$(validate_port "$PORT" "4096")"

# Use localhost for health checks even if bound to 0.0.0.0
HEALTH_HOST="127.0.0.1"

echo "OpenCode Server Status"
echo "======================"

# Check if curl is available for health checks
CURL_AVAILABLE=true
if ! command -v curl &>/dev/null; then
    CURL_AVAILABLE=false
fi

# Health check function
check_health() {
    # If password is set, we need to authenticate
    local curl_opts=("-sf") # fail silently on server errors (4xx/5xx)
    if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
        curl_opts+=("-u" "opencode:${OPENCODE_SERVER_PASSWORD}")
    fi

    if command -v curl >/dev/null; then
        # Try root endpoint
        if curl "${curl_opts[@]}" "http://localhost:${PORT}/" >/dev/null 2>&1; then
            return 0
        fi
        # Try doc endpoint
        if curl "${curl_opts[@]}" "http://localhost:${PORT}/doc" >/dev/null 2>&1; then
            return 0
        fi
    elif command -v wget >/dev/null; then
         # Fallback to simple connection check if curl is missing
         if timeout 1 bash -c "</dev/tcp/localhost/${PORT}" 2>/dev/null; then
             return 0
         fi
    fi
    return 1
}

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Process:  RUNNING (PID: $PID)"

        # Check if actually responding
        if [ "$CURL_AVAILABLE" != "true" ]; then
            echo "Health:   UNKNOWN (curl not installed, cannot verify)"
        elif check_health; then
            echo "Health:   HEALTHY (OK)"
        else
            echo "Health:   UNHEALTHY (NOT OK) (process running but not responding)"
            echo ""
            echo "Possible causes:"
            echo "  - Server still starting up (wait a few seconds)"
            echo "  - Server crashed but process lingers"
            echo "  - Port conflict with another service"
            echo ""
            echo "Try: opencode-server-stop && opencode-server-start.sh"
        fi

        # Use localhost for display URLs when bound to 0.0.0.0 (not a routable address)
        DISPLAY_HOST="$HOSTNAME"
        [ "$HOSTNAME" = "0.0.0.0" ] && DISPLAY_HOST="localhost"
        echo "Endpoint: http://${DISPLAY_HOST}:${PORT}"
        echo "API Docs: http://${DISPLAY_HOST}:${PORT}/doc"
        echo ""
        echo "Recent logs:"
        tail -10 "$LOG_FILE" 2>/dev/null || echo "No logs available"
    else
        echo "Status: STOPPED (stale PID file)"
        rm -f "$PID_FILE"
    fi
else
    # No PID file - try to detect if server is running via health check
    if [ "$CURL_AVAILABLE" != "true" ]; then
        echo "Status: UNKNOWN (no PID file and curl not installed)"
        echo "  Cannot determine if server is running without curl or a PID file."
    elif check_health; then
        echo "Process:  RUNNING (no PID file, but server responding)"
        echo "Health:   HEALTHY (OK)"
        echo ""
        echo "NOTE: PID file missing. Server may have been started manually."
    else
        # Fallback: check process list
        # Note: Pattern is intentionally hardcoded to avoid shell injection
        if pgrep -f "opencode.*(serve|web)" >/dev/null; then
             echo "Status: RUNNING (Verified via process list)"
             echo "Health: UNKNOWN (PID file missing, health check failed)"
             echo "NOTE: PID 661/opencode seen in netstat? Run 'netstat -tulpn | grep 4096' to confirm."
        else
             echo "Status: NOT RUNNING"
        fi
    fi
fi
STATUSSCRIPT

chmod +x "${BIN_DIR}/opencode-server-status"

# Create log cleanup helper
cat > "${BIN_DIR}/opencode-logs-clean" << 'CLEANSCRIPT'
#!/bin/bash
# Clean up OpenCode server logs

_get_pid_dir() {
    local pid_dir="${XDG_RUNTIME_DIR:-}"
    if [ -z "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
        pid_dir="/tmp/opencode-$(id -u)"
        if [ -L "$pid_dir" ]; then
            echo "ERROR: $pid_dir is a symlink. Possible security issue." >&2
            exit 1
        fi
        if ! mkdir -p "$pid_dir"; then
            echo "ERROR: Could not create PID directory: $pid_dir" >&2
            exit 1
        fi
        if [ -L "$pid_dir" ] || [ ! -d "$pid_dir" ]; then
            echo "ERROR: PID directory is not a directory: $pid_dir" >&2
            exit 1
        fi
        chmod 700 "$pid_dir"
    fi
    echo "$pid_dir"
}

PID_DIR="$(_get_pid_dir)"
LOG_FILE="${PID_DIR}/opencode-server.log"
LOG_OLD="${LOG_FILE}.old"

echo "Cleaning OpenCode logs..."
rm -f "$LOG_FILE" "$LOG_OLD"
echo "Done."
CLEANSCRIPT

chmod +x "${BIN_DIR}/opencode-logs-clean"

echo "OpenCode installation complete!"
echo ""
echo "Available commands:"
echo "  opencode               - Start interactive TUI"
echo "  opencode serve         - Start headless server"
echo "  opencode web           - Start web interface"
echo "  opencode attach        - Connect to remote server"
echo "  opencode-connect       - Helper to connect to servers"
echo "  opencode-server-status - Check server status (with health check)"
echo "  opencode-server-stop   - Stop running server"
echo "  opencode-logs-clean    - Clean up server logs"
