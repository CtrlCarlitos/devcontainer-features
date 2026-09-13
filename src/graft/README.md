# Graft

Installs [Graft](https://www.npmjs.com/package/@nanonets/graft) — a codebase
context graph. Graft pre-indexes every symbol, its file:line span, and who
calls what into a small linked graph of markdown nodes, so coding agents can
answer "where is X / who calls Y / what breaks if Z changes" in a couple of
tool calls instead of grepping and re-reading files. Massive token savings
for agent-driven development.

## Usage

Add to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/devcontainers/features/node:1": {},
        "ghcr.io/CtrlCarlitos/devcontainer-features/graft:1": {}
    }
}
```

## What it does

- Requires Node.js (install the node feature first — `installsAfter` is set)
- Runs `npm install -g @nanonets/graft` if `graft` is not already on PATH
- Links the npm-installed binary into `/usr/local/bin/graft` so minimal
  devcontainer shells can find it
- Idempotent — skips the npm install if `graft` already resolves

## Typical use

```bash
graft map          # token-budgeted orientation: dirs, hubs, hotspots
graft ask "where does auth happen?" --source
graft callers someFunction
```
