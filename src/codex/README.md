
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
| version | Codex CLI version to install | string | 0.157.1 |
| installMethod | Installation method. 'npm' is primary method (recommended), 'binary' downloads from GitHub releases | string | npm |
| enableMcpServer | Configure Codex to be available as an MCP server for other agents | boolean | false |
| authMethod | Preferred authentication method. 'api-key' uses OPENAI_API_KEY, 'chatgpt' uses browser OAuth, 'device-code' is experimental headless auth | string | none |
| approvalMode | Default approval mode: 'suggest' (review all), 'auto' (auto-approve safe), 'full-auto' (no prompts) | string | suggest |
| sandboxMode | Sandbox mode for command execution | string | workspace-write |


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


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
