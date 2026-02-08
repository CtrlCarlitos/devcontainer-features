
## Example Usage

### Option 1: With Reverse Proxy (e.g. Traefik)

```json
"features": {
    "ghcr.io/ctrlcarlitos/devcontainer-features/opencode:1": {
        "enableServer": true,
        "enableWebMode": true,
        "corsOrigins": "opencode.localhost"
    }
}
```

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
