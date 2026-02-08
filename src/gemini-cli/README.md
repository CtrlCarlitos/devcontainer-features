
# Gemini CLI (gemini-cli)

Installs Google Gemini CLI with headless mode support for scripting and automation. Uses npm (the only supported installation method by Google).

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/gemini-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Gemini CLI version to install (e.g., 'latest', 'preview', or specific version) | string | latest |
| authMethod | Preferred authentication method. 'api-key' uses GOOGLE_API_KEY/GEMINI_API_KEY | string | none |
| defaultModel | Default model to use (e.g., 'gemini-2.5-pro', 'gemini-2.5-flash', 'gemini-3-pro') | string | - |
| enableVertexAI | Use Vertex AI instead of Google AI Studio (requires GCP project) | boolean | false |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
