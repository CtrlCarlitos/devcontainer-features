# Additional Notes for Node.js Feature

## Behavior

This feature acts as a **fallback installer** for Node.js:

- ✅ If Node.js is **already installed** → Skips installation and exits gracefully
- 📦 If Node.js is **not present** → Installs via [nvm](https://github.com/nvm-sh/nvm)

> **Note**: This feature does NOT upgrade or replace existing Node.js installations. If you need a specific version, either use a base image with that version or use the official [devcontainers/features/node](https://github.com/devcontainers/features/tree/main/src/node) feature.

## Version Options

| Value | Behavior |
|-------|----------|
| `22` (default) | Installs Node.js 22.x (current LTS) |
| `20` | Installs Node.js 20.x |
| `18` | Installs Node.js 18.x |
| `lts` | Installs the current LTS version |
| `latest` | Installs the latest available version |

## Example Configurations

### Default (Node 22)
```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/node:1": {}
}
```

### Specific Major Version
```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/node:1": {
        "version": "20"
    }
}
```

### Latest Version
```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/node:1": {
        "version": "latest"
    }
}
```

## Environment Variables

This feature sets the following environment variables:

| Variable | Value |
|----------|-------|
| `NVM_DIR` | `/usr/local/share/nvm` |
| `PATH` | Prepends `/usr/local/share/nvm/current/bin` |

## Symlinks

The feature creates symlinks for global access:
- `/usr/local/bin/node`
- `/usr/local/bin/npm`
- `/usr/local/bin/npx`

## Use with Other Features

This feature is designed to work with features that depend on Node.js:

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/node:1": {},
    "ghcr.io/CtrlCarlitos/devcontainer-features/claude-code:1": {}
}
```

Features like `claude-code` will check for Node.js 18+ and provide clear error messages if the version is too old.

## Supported Base Images

This feature requires `apt-get` and works with:
- Debian-based images (Ubuntu, Debian)
- Microsoft's devcontainer base images

Alpine and other non-Debian distributions are **not currently supported**.
