
## Example Usage

### Option 1: With Reverse Proxy (e.g. Traefik)

```json
"features": {
    "ghcr.io/ctrlcarlitos/devcontainer-features/opencode:1": {
        "enableServer": true,
        "enableWebMode": true,
        "serverHostname": "0.0.0.0",
        "serverPassword": "your-secure-password",
        "corsOrigins": "opencode.localhost"
    }
}
```

### Server Startup & troubleshooting

The OpenCode server is configured to start automatically via `postStartCommand`. If it does not start:
1.  Check logs: `cat /tmp/opencode-$(id -u)/opencode-server.log`
2.  Start manually: `opencode-server-start.sh`
3.  Check status: `opencode-server-status`

### Option 2: Direct Localhost Access

```json
"features": {
    "ghcr.io/ctrlcarlitos/devcontainer-features/opencode:1": {
        "enableServer": true,
        "enableWebMode": true,
        "corsOrigins": "http://localhost:4096"
    }
}
```

> **Important Network Note:**
> If you are running Nginx on your **host machine** (outside Docker) and using `proxy_pass http://host.docker.internal:4096`, you must ensure port `4096` is **forwarded/published** from the devcontainer to the host.
>
> Add this to your `devcontainer.json`:
> ```json
> "forwardPorts": [4096],
> // OR if using docker-compose:
> // "appPort": [4096]
> ```
> Without this, `host.docker.internal:4096` on the host will not reach the container.

## Recent Changes & Features (v1.1.7+)

## Configuring Persistence (Docker Volumes)

To persist authentication and configuration across container rebuilds, use Docker Volumes. This avoids the need to re-authenticate every time you recreate the container.

Add the following to your `docker-compose.yml`:

```yaml
services:
  app:
    # ...
    volumes:
      # OpenCode global config (opencode.json, plugins/, agents/, etc.)
      - opencode_config:/home/vscode/.config/opencode

      # OpenCode app data (auth.json, logs, project sessions)
      - opencode_data:/home/vscode/.local/share/opencode

      # OpenCode cache (provider packages + plugin node_modules)
      - opencode_cache:/home/vscode/.cache/opencode

volumes:
  opencode_config:
  opencode_data:
  opencode_cache:
```

> **Note:** Replace `/home/vscode` with `/home/node` or `/root` if using a different user.

### Server Stability & Security (v1.1.7)

-   **Password Persistence**: Fixed issue where `OPENCODE_SERVER_PASSWORD` was lost in some shell sessions. It is now persisted in `/usr/local/etc/opencode-defaults` and loaded via `/etc/profile.d/`.
-   **Health Check**: Fixed `opencode-server-status` reporting "NOT RUNNING" when password auth was enabled. The check now correctly authenticates using the configured password.
