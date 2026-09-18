
# Agent Browser (agent-browser)

Installs the agent-browser CLI and its separate Chrome-for-Testing runtime for interactive browser automation.

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/agent-browser:1": {}
}
```



## Container Chrome

Agent Browser stores Chrome-for-Testing in `~/.agent-browser/browsers`, separate
from Playwright's browser cache. Docker may block Chrome's normal sandbox, so
uses `~/.agent-browser/config.json` with `--no-sandbox,--disable-gpu` for
browser-launching commands in this container.

`--no-sandbox` weakens Chrome isolation. It is required only for this Docker
container environment and is not a default for host installations. `doctor --json`
may report a sandboxed-launch failure in Docker because upstream ignores this
configuration for its own launch check; the feature's browser launch test is
authoritative.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
