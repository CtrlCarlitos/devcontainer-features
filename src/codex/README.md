
# OpenAI Codex CLI (codex)

Installs OpenAI Codex CLI with headless mode and MCP server helpers. Uses npm by default (recommended by OpenAI).

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/codex:1": {
        "approvalMode": "suggest",
        "sandboxMode": "workspace-write"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Codex CLI version to install | string | latest |
| installMethod | Installation method. 'npm' is primary method (recommended), 'binary' downloads from GitHub releases | string | npm |
| enableMcpServer | Configure Codex to be available as an MCP server for other agents | boolean | false |
| authMethod | Preferred authentication method. 'api-key' uses OPENAI_API_KEY, 'chatgpt' uses browser OAuth, 'device-code' is experimental headless auth | string | none |
| oauthPort | Port for OAuth callback server (for SSH port forwarding) | string | 1455 |
| approvalMode | Default approval mode: 'suggest' (review all), 'auto' (auto-approve safe), 'full-auto' (no prompts) | string | suggest |
| sandboxMode | Sandbox mode for command execution | string | workspace-write |

## Authentication

Codex supports multiple authentication methods.

- API key: set `OPENAI_API_KEY` at runtime.
- OAuth: use SSH port forwarding to the OAuth port (default `1455`) and sign in with ChatGPT.
- Device code: run `codex login --device-code` (experimental).

Run `codex-remote-auth` for step-by-step instructions.

## Helper Commands

- `codex-remote-auth` container authentication guide
- `codex-exec` run headless prompts (`codex exec`)
- `codex-mcp-server` start MCP server over stdio
- `codex-info` show auth status and config

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/CtrlCarlitos/devcontainer-features/blob/main/src/codex/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
