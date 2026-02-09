
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

## Configuring Persistence (Docker Volumes)

To persist authentication and configuration across container rebuilds, use Docker Volumes.

### Claude Code Volumes

Add to your `docker-compose.yml`:

```yaml
services:
  app:
    volumes:
      # Claude Code user settings (settings.json, credentials.json, MCP servers)
      - claude_config:/home/vscode/.claude

      # Claude Code project settings (if using project-specific config)
      - ./project:/workspaces/project:rw

volumes:
  claude_config:
```

**Claude Code paths:**
- `~/.claude/settings.json` - User settings (permissions, hooks, model overrides)
- `~/.claude/credentials.json` - Authentication credentials
- `~/.claude.json` - Global state (theme, OAuth, MCP servers)
- `.claude/settings.json` - Project settings (checked into source control)
- `.mcp.json` - Project MCP servers (checked into source control)

> **Note:** Replace `/home/vscode` with `/home/node` or `/root` if using a different user.
