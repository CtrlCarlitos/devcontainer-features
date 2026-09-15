
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
Authenticate on your host machine first, then mount credentials. Replace `<remote-user-home>` with the configured remote user's home directory:
```yaml
volumes:
  - ~/.codex:<remote-user-home>/.codex:ro
```

**Option 3: SSH Port Forwarding (For Manual OAuth)**
```bash
ssh -L 1455:localhost:1455 user@container-host
```

## Configuring Persistence (Docker Volumes)

See the repository-wide [persistence guide](../../DOCKER_VOLUMES.md) for Codex state-path classifications and mount examples.
