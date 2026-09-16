#!/bin/bash
set -euo pipefail

get_target_user() {
    local user="${_REMOTE_USER:-${SUDO_USER:-$(whoami)}}"
    id "$user" >/dev/null 2>&1 || user=root
    echo "$user"
}

get_target_home() {
    local user="$1"
    local home="${_REMOTE_USER_HOME:-}"
    [ -n "$home" ] || home="$(getent passwd "$user" 2>/dev/null | cut -d: -f6)"
    [ -n "$home" ] || home="/home/$user"
    [ "$user" != root ] || home=/root
    echo "$home"
}

REMOTE_USER="$(get_target_user)"
REMOTE_HOME="$(get_target_home "$REMOTE_USER")"

ensure_node_24() {
    if command -v node >/dev/null 2>&1 && [ "$(node -p 'process.versions.node.split(".")[0]')" -ge 24 ]; then
        return
    fi

    echo "Installing Node.js 24..."
    export NVM_DIR=/usr/local/share/nvm
    mkdir -p "$NVM_DIR"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
    nvm install 24
    nvm alias default 24
    node_dir="$NVM_DIR/versions/node/$(nvm current)/bin"
    ln -sf "$node_dir/node" /usr/local/bin/node
    ln -sf "$node_dir/npm" /usr/local/bin/npm
    ln -sf "$node_dir/npx" /usr/local/bin/npx
}

ensure_node_24
export PATH=/usr/local/bin:$PATH

npm install -g --allow-scripts=agent-browser agent-browser
agent_browser="$(npm prefix -g)/bin/agent-browser"
[ -x "$agent_browser" ] || { echo "ERROR: agent-browser was not installed at $agent_browser" >&2; exit 1; }

"$agent_browser" install --with-deps
# --with-deps installs Linux packages as root but also downloads a root-owned
# browser cache. Provision the usable runtime directly for the remote user.
rm -rf /root/.agent-browser/browsers
if [ "$REMOTE_USER" = root ]; then
    "$agent_browser" install
    mkdir -p "$REMOTE_HOME/.agent-browser"
    printf '{"args":"--no-sandbox,--disable-gpu"}\n' > "$REMOTE_HOME/.agent-browser/config.json"
    "$agent_browser" doctor --json || true
    "$agent_browser" open about:blank
    "$agent_browser" close
else
    su - "$REMOTE_USER" -c "'$agent_browser' install"
    su - "$REMOTE_USER" -c 'mkdir -p ~/.agent-browser && printf "{\"args\":\"--no-sandbox,--disable-gpu\"}\n" > ~/.agent-browser/config.json'
    # doctor ignores configured args for its launch check; retain its diagnostics.
    su - "$REMOTE_USER" -c "'$agent_browser' doctor --json || true"
    su - "$REMOTE_USER" -c "'$agent_browser' open about:blank"
    su - "$REMOTE_USER" -c "'$agent_browser' close"
fi

test -d "$REMOTE_HOME/.agent-browser/browsers"
test "$(stat -c %U "$REMOTE_HOME/.agent-browser")" = "$REMOTE_USER"

echo "Agent Browser installed for $REMOTE_USER. Chrome runtime: $REMOTE_HOME/.agent-browser/browsers"
