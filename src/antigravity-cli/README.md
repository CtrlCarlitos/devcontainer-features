# Antigravity CLI (agy)

Installs the [Antigravity CLI](https://antigravity.google/cli) — Google's
terminal/headless AI agent surface. This replaces the retired Gemini CLI.

## Usage

Add to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/CtrlCarlitos/devcontainer-features/antigravity-cli:1": {}
    }
}
```

## What it does

- Downloads and runs the official installer from `antigravity.google/cli/install.sh`
- Symlinks the binary to `/usr/local/bin/agy` for global access
- Idempotent — skips if `agy` is already on PATH

## Base image requirements

- Debian/Ubuntu base (uses `curl` and `bash`)
- No Node.js required — the installer is self-contained

## Replacing gemini-cli

If you were using the `gemini-cli` feature, replace it:

```diff
- "ghcr.io/CtrlCarlitos/devcontainer-features/gemini-cli:1": {}
+ "ghcr.io/CtrlCarlitos/devcontainer-features/antigravity-cli:1": {}
```

Google retired the standalone Gemini CLI for individuals in favor of the
Antigravity suite. See the [Antigravity docs](https://antigravity.google/docs)
for the CLI's capabilities.
