# Serena Agent

Installs [Serena](https://github.com/oraios/serena) — an MCP (Model Context
Protocol) toolkit that gives coding agents **semantic code awareness**:
symbol-level navigation, search, referencing, and editing powered by Language
Servers (LSP). It works across 40+ languages and dramatically reduces token
usage compared to raw file-reading agents, because agents operate on symbols
and context instead of whole files.

## Usage

Add to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/CtrlCarlitos/devcontainer-features/serena:1": {}
    }
}
```

## What it does

- Installs [uv](https://docs.astral.sh/uv/) (Astral) if not already present
- Runs `uv tool install -p 3.13 serena-agent` — uv downloads a managed
  Python 3.13 if the system doesn't have one, and installs Serena into an
  isolated tool environment
- Copies the `serena` launcher to `/usr/local/bin/serena` for global access
- Idempotent — skips if `/usr/local/bin/serena` already exists

## Notes

- Serena is config-free at install time; projects are onboarded on first run
- The uv tool environment lives in `~/.local/share/uv/tools/serena-agent`
  (~200 MB including Python); keep the home directory persistent if you
  image-customize further
- No Node.js required

## Typical use

Point your MCP client (Claude Code, Antigravity, opencode, ...) at:

```
serena start-mcp-server --context ide-assistant
```
