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
