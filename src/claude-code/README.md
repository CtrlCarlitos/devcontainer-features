
# Claude Code (claude-code)

Installs Claude Code with headless mode and MCP server helpers. Uses the native installer (recommended by Anthropic).

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/claude-code:1": {
        "skipPermissions": true
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Claude Code version to install (e.g., 'latest', '1.0.58') | string | latest |
| enableMcpServer | Configure Claude Code to be available as an MCP server for other agents | boolean | false |
| authMethod | Preferred authentication method. 'api-key' uses ANTHROPIC_API_KEY env var, 'oauth' requires browser | string | none |
| oauthPort | Port for OAuth callback server (for SSH port forwarding when using browser auth) | string | 52780 |
| skipPermissions | Run initial setup with --dangerously-skip-permissions for headless environments | boolean | false |

## Authentication

Claude Code requires OAuth in a browser or an API key.

- OAuth: use SSH port forwarding to the OAuth port (default `52780`), then run `claude /login` and open the localhost URL in your local browser.
- API key: set `ANTHROPIC_API_KEY` at runtime.

Run `claude-remote-auth` for step-by-step instructions.

## Helper Commands

- `claude-remote-auth` container authentication guide
- `claude-headless` run headless prompts (`claude -p`)
- `claude-mcp-server` start MCP server over stdio
- `claude-info` show auth status and version

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/CtrlCarlitos/devcontainer-features/blob/main/src/claude-code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
