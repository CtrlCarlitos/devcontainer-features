
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

**If authentication hangs or the callback fails:**

1.  Run `claude login` in the terminal.
2.  Copy the URL it generates.
3.  Look for the `redirect_uri` query parameter (e.g., `...&redirect_uri=http://localhost:39485/...`).
4.  **Manually forward this port** in VS Code:
    *   Open the **Ports** view (Ctrl+Shift+P > "Ports: Focus on Ports View").
    *   Click **Forward a Port**.
    *   Enter the port number (e.g., `39485`).
5.  Open the auth URL in your browser.

**Alternative: API Key**
For a more stable experience in containers, consider using an API Key instead of OAuth:
```bash
export ANTHROPIC_API_KEY="sk-..."
```
