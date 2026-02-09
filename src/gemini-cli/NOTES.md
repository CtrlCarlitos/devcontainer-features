
## Example Usage

```json
"features": {
    "ghcr.io/ctrlcarlitos/devcontainer-features/gemini-cli:1": {
        "authMethod": "google-oauth",
        "defaultModel": "gemini-3-pro-preview"
    }
}
```

## OAuth Authentication in Containers

Gemini CLI uses browser-based OAuth. In containers, the localhost redirect will fail because the container's localhost is not accessible from your browser.

**Workarounds:**

**Option 1: API Key (Recommended for CI/Headless)**
```bash
export GEMINI_API_KEY="..."
# OR
export GOOGLE_API_KEY="..."
```

**Option 2: Bind Mount Credentials**
Authenticate on your host machine first, then mount credentials:
```yaml
volumes:
  - ~/.gemini:/home/vscode/.gemini:ro
```

**Option 3: Capture and Forward (Manual OAuth)**
1. Set up a script to capture the auth URL:
```bash
mkdir -p ~/.gemini
cat > ~/capture-url.sh << 'SCRIPT'
#!/bin/bash
echo "$@" >> ~/.gemini/auth-url.txt
SCRIPT
chmod +x ~/capture-url.sh
```

2. Run gemini with capture script:
```bash
export BROWSER=~/capture-url.sh
gemini
# Select /auth -> Login with Google
```

3. Check the captured URL:
```bash
cat ~/.gemini/auth-url.txt
```

4. Find the port in the redirect_uri and forward it manually

## Configuring Persistence (Docker Volumes)

To persist authentication and configuration across container rebuilds, use Docker Volumes.

### Gemini CLI Volumes

Add to your `docker-compose.yml`:

```yaml
services:
  app:
    volumes:
      # Gemini config and auth (oauth_creds.json, settings.json)
      - gemini_config:/home/vscode/.gemini

      # Gemini data
      - gemini_data:/home/vscode/.local/share/gemini-cli

      # Gemini cache
      - gemini_cache:/home/vscode/.cache/gemini-cli

volumes:
  gemini_config:
  gemini_data:
  gemini_cache:
```

**Gemini CLI paths:**
- `~/.gemini/oauth_creds.json` - OAuth credentials
- `~/.gemini/settings.json` - Configuration settings

> **Note:** Replace `/home/vscode` with `/home/node` or `/root` if using a different user.
