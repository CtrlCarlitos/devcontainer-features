
# OpenCode (opencode)

Installs OpenCode AI coding agent with optional server mode for remote connections. Supports both native installer and npm.

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/opencode:1": {}
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
| corsOrigins | Comma-separated list of additional CORS origins (e.g., 'http://localhost:3000,https://app.example.com') | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
