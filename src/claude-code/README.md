
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
| version | Claude Code version to install (e.g., 'latest', '1.0.58') | string | latest |
| enableMcpServer | Configure Claude Code to be available as an MCP server for other agents | boolean | false |
| authMethod | Preferred authentication method. 'api-key' uses ANTHROPIC_API_KEY env var, 'oauth' requires browser | string | none |
| skipPermissions | Run initial setup with --dangerously-skip-permissions for headless environments | boolean | false |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
