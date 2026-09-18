
# Curated Agent Skills (curated-skills)

Installs curated AI-agent skills for Claude Code, OpenCode, Antigravity, and Codex; Antigravity receives skills in both its IDE and CLI global directories.

## Example Usage

```json
"features": {
    "ghcr.io/CtrlCarlitos/devcontainer-features/curated-skills:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| skills | Comma-separated skills as owner/repo:skill-name; append >local-name to rename on install (collision dodging) | string | vercel-labs/skills:find-skills,vercel-labs/agent-browser:agent-browser,anthropics/skills:skill-creator,anthropics/skills:frontend-design,mattpocock/skills:codebase-design,mattpocock/skills:domain-modeling,mattpocock/skills:grill-with-docs,mattpocock/skills:improve-codebase-architecture,mattpocock/skills:prototype,mattpocock/skills:research,mattpocock/skills:grilling,mattpocock/skills:handoff,mattpocock/skills:teach,mattpocock/skills:writing-for-agents,mattpocock/skills:resolving-merge-conflicts,mattpocock/skills:code-review>mp-code-review |
| agents | Comma-separated supported agents: claude-code, opencode, antigravity, codex. Antigravity selects both IDE and CLI global skill directories. | string | claude-code,opencode,antigravity,codex |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
