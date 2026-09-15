# Persisting AI Tool State

Use the configured remote user's home directory for mount targets. `/home/vscode` is only an example.

## Runtime Secrets

Do not place OpenCode server passwords in feature options or commit them to `devcontainer.json`. Pass them at runtime:

```json
"containerEnv": {
  "OPENCODE_SERVER_PASSWORD": "${localEnv:OPENCODE_SERVER_PASSWORD}"
}
```

## Path Matrix

| Tool | Path | Classification |
| --- | --- | --- |
| Claude Code | `~/.claude` | Persist authentication and configuration. |
| Claude Code | `~/.claude.json` | Optional global OAuth and MCP state; use a file-safe bind mount. |
| Codex | `~/.codex` | Persist authentication and configuration. |
| OpenCode | `~/.config/opencode` | Persist configuration. |
| OpenCode | `~/.opencode` | Optional user-managed path. |
| OpenCode | `~/.local/share/opencode` | Optional user-managed data path. |
| OpenCode | `~/.cache/opencode` | Optional user-managed cache path. |
| Antigravity CLI | `~/.Antigravity` | optional user-managed path, not feature requirements. |
| Antigravity CLI | `~/.local/share/Antigravity-cli` | optional user-managed path, not feature requirements. |
| Antigravity CLI | `~/.cache/Antigravity-cli` | optional user-managed path, not feature requirements. |

Mount only the paths you need. For named Docker volumes, replace `/home/vscode` below with the configured remote user's home directory:

`~/.claude.json` is a file. Docker named volumes are directories, so never use a named volume at that path. Pre-create a host file and bind-mount it, or use another file-safe persistence mechanism. On Windows and macOS, prefer named volumes for directory state when host-path permissions or path translation are unsuitable.

```yaml
services:
  app:
    volumes:
      - claude_config:/home/vscode/.claude
      - codex_config:/home/vscode/.codex
      - opencode_config:/home/vscode/.config/opencode

volumes:
  claude_config:
  codex_config:
  opencode_config:
```
