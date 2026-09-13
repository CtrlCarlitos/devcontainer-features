# Guardrail

Installs [Guardrail](https://github.com/CtrlCarlitos/agent-guardrails) —
safety guardrails for AI coding agents. Guardrail wraps agent sessions with
enforceable policies (command filtering, path restrictions, approval flows)
so autonomous coding tools can't take dangerous actions unchecked.

> **⚠️ PRIVATE REPO WARNING**: the `agent-guardrails` repository is currently
> **private**. The release download will fail for anyone outside the repo's
> collaborators until the repo goes public. This feature is primarily for
> Carlitos's own devcontainers until then.

## Usage

Add to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/CtrlCarlitos/devcontainer-features/guardrail:1": {}
    }
}
```

## Options

| Option    | Default      | Description                              |
|-----------|--------------|------------------------------------------|
| `version` | `v0.18.0-dev`| Release tag to install (e.g. `v0.19.0`)  |

## What it does

- Downloads the pinned release binary from GitHub Releases
- Downloads `SHA256SUMS` from the same release and **verifies the checksum**
  before installing (fails hard on mismatch)
- Copies the binary to `/usr/local/bin/guardrail` (COPY, not symlink)
- Idempotent — skips if already installed at the default pin; a non-default
  `version` forces a reinstall

## Notes

- x86_64 Linux only (the release asset is `guardrail_linux_amd64.exe` —
  it is a Linux binary despite the `.exe` suffix)
- No Node.js required
