
# Gemini CLI (gemini-cli)

Installs Google Gemini CLI with headless mode support for scripting and automation. Uses npm (the only supported installation method by Google).

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/gemini-cli:1": {
        "defaultModel": "gemini-2.5-pro"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Gemini CLI version to install (e.g., 'latest', 'preview', or specific version) | string | latest |
| authMethod | Preferred authentication method. 'api-key' uses GOOGLE_API_KEY/GEMINI_API_KEY | string | none |
| defaultModel | Default model to use (e.g., 'gemini-2.5-pro', 'gemini-2.5-flash', 'gemini-3-pro') | string |  |
| enableVertexAI | Use Vertex AI instead of Google AI Studio (requires GCP project) | boolean | false |

## Authentication

Gemini CLI supports API keys, Google OAuth, and service accounts. For headless environments, API keys are recommended.

- API key: set `GOOGLE_API_KEY` or `GEMINI_API_KEY` at runtime.
- Service account: set `GOOGLE_APPLICATION_CREDENTIALS` and `GOOGLE_GENAI_USE_VERTEXAI=true`.
- OAuth: see `gemini-remote-auth` for container workflow.

## Helper Commands

- `gemini-remote-auth` container authentication guide
- `gemini-headless` run headless prompts (`gemini -p`)
- `gemini-json` JSON output with response extraction (requires `jq`)
- `gemini-info` show auth status and settings

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/CtrlCarlitos/devcontainer-features/blob/main/src/gemini-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
