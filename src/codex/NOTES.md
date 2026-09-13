
## Example Usage

```json
"features": {
    "ghcr.io/ctrlcarlitos/devcontainer-features/codex:1": {
        "authMethod": "chatgpt"
    }
}
```

## OAuth Authentication in Containers

Codex CLI uses a **fixed port (1455)** for OAuth callbacks - it cannot be configured to use a different port.

When running `codex login` in a container, the OAuth URL will show `redirect_uri=http://localhost:1455/auth/callback`. Since `localhost` refers to the container, not your host, the callback will fail unless you forward port 1455.

**Workarounds:**

**Option 1: API Key (Recommended for CI/Headless)**
```bash
export OPENAI_API_KEY="sk-..."
```

**Option 2: Bind Mount Credentials**
Authenticate on your host machine first, then mount credentials:
```yaml
volumes:
  - ~/.codex:/home/vscode/.codex:ro
```

**Option 3: SSH Port Forwarding (For Manual OAuth)**
```bash
ssh -L 1455:localhost:1455 user@container-host
```

## Configuring Persistence (Docker Volumes)

To persist authentication and configuration across container rebuilds, use Docker Volumes.

### Codex Volumes

Add to your `docker-compose.yml`:

```yaml
services:
  app:
    volumes:
      # Codex config and auth (auth.json, config.toml)
      - codex_config:/home/vscode/.codex

      # Codex data (sessions, logs, state)
      - codex_data:/home/vscode/.local/share/codex

      # Codex cache
      - codex_cache:/home/vscode/.cache/codex

volumes:
  codex_config:
  codex_data:
  codex_cache:
```

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

### Gemini CLI Volumes

Add to your `docker-compose.yml`:

```yaml
services:
  app:
    volumes:
      # Gemini config and auth (oauth_creds.json, settings.json)
      - gemini_config:/home/vscode/.gemini

      # Gemini data
      - gemini_data:/home/vscode/.local/share/gemini-cli

      # Gemini cache
      - gemini_cache:/home/vscode/.cache/gemini-cli

volumes:
  gemini_config:
  gemini_data:
  gemini_cache:
```

**Gemini CLI paths:**
- `~/.gemini/oauth_creds.json` - OAuth credentials
- `~/.gemini/settings.json` - Configuration settings

> **Note:** Replace `/home/vscode` with `/home/node` or `/root` if using a different user.
