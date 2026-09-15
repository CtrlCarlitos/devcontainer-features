
# Claude Code (claude-code)

Installs Claude Code AI coding assistant with headless mode and MCP server support. Uses the native installer (recommended by Anthropic).

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/claude-code:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Claude Code version to install (e.g., 'latest', '1.0.58') | string | 2.1.47 |
| enableMcpServer | Configure Claude Code to be available as an MCP server for other agents | boolean | false |
| authMethod | Preferred authentication method. 'api-key' uses ANTHROPIC_API_KEY env var, 'oauth' requires browser | string | none |
| skipPermissions | Run initial setup with --dangerously-skip-permissions for headless environments | boolean | false |


## Example Usage

```json
"features": {
    "ghcr.io/ctrlcarlitos/devcontainer-features/claude-code:1": {
        "authMethod": "oauth"
    }
}
```

## OAuth Troubleshooting

Claude Code CLI uses a **random port** for OAuth callbacks, which prevents automatic port forwarding from working reliably.

**If authentication hangs or callback fails:**

1. Run `claude login` in terminal.
2. Copy the URL it generates.
3. Look for the `redirect_uri` query parameter (e.g., `...&redirect_uri=http://localhost:39485/...`).
4. **Manually forward this port** in VS Code:
   * Open to **Ports** view (Ctrl+Shift+P > "Ports: Focus on Ports View").
   * Click **Forward a Port**.
   * Enter the port number (e.g., `39485`).
5. Open the auth URL in your browser.

**Alternative: API Key**
For a more stable experience in containers, consider using an API Key instead of OAuth:
```bash
export ANTHROPIC_API_KEY="sk-..."
```

## Configuring Persistence

See the repository-wide [persistence guide](../../DOCKER_VOLUMES.md). It covers `~/.claude` and the file-safe handling required for `~/.claude.json`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
