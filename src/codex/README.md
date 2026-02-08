
# OpenAI Codex CLI (codex)

Installs OpenAI Codex CLI with headless mode and MCP server support. Uses npm (the primary installation method recommended by OpenAI).

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/codex:1": {}
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



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
