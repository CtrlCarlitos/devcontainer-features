
## Example Usage

### Option 1: With Reverse Proxy (e.g. Traefik)

```json
"features": {
    "ghcr.io/ctrlcarlitos/devcontainer-features/opencode:1": {
        "enableServer": true,
        "enableWebMode": true,
        "serverHostname": "0.0.0.0",  // Explicitly set for network access (default is 127.0.0.1 for security)
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

See the repository-wide [persistence guide](../../DOCKER_VOLUMES.md) for OpenCode state-path classifications and mount examples.

### Server Stability & Security (v1.1.7)

-   **Runtime Passwords**: Set `OPENCODE_SERVER_PASSWORD` at container runtime for an exposed server. Passwords are not stored in feature options or image defaults.
-   **Health Check**: `opencode-server-status` authenticates with `OPENCODE_SERVER_PASSWORD` when it is present in the runtime environment.
