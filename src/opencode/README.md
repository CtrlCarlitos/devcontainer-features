
# OpenCode (opencode)

Installs OpenCode, an AI coding agent for the terminal. Supports an optional HTTP server mode for remote access and web UI.

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/opencode:1": {
        "enableServer": true
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | OpenCode version to install (e.g., 'latest', '1.0.0') | string | latest |
| installMethod | Installation method. 'native' uses official curl installer, 'npm' installs opencode-ai package | string | native |
| enableServer | Automatically start OpenCode server on container start for remote access | boolean | false |
| serverPort | Port for OpenCode server (default: 4096) | string | 4096 |
| serverHostname | WARNING: Defaults to '0.0.0.0' (network-accessible). Set OPENCODE_SERVER_PASSWORD when exposed! Use '127.0.0.1' for localhost-only access. | string | 0.0.0.0 |
| enableMdns | Enable mDNS service discovery (advertises as opencode.local on network) | boolean | false |
| enableWebMode | Start with web interface instead of headless server mode | boolean | false |
| corsOrigins | Comma-separated list of additional CORS origins (e.g., 'http://localhost:3000,https://app.example.com') | string |  |

## Remote Access

Enable server mode and set a runtime password:

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/opencode:1": {
        "enableServer": true,
        "serverHostname": "0.0.0.0",
        "serverPort": "4096"
    }
}
```

Set `OPENCODE_SERVER_PASSWORD` at runtime via `remoteEnv`, secrets, or your devcontainer host.

## Helper Commands

- `opencode-server-start.sh` starts the server on container start
- `opencode-connect` connects to a remote server (defaults to localhost:4096)
- `opencode-server-status` checks server status with health verification
- `opencode-server-stop` stops the server
- `opencode-logs-clean` removes server logs

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/CtrlCarlitos/devcontainer-features/blob/main/src/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
