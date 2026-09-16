
# Curated Agent Skills (curated-skills)

Installs curated AI-agent skills via the vercel-labs `skills` CLI into the standard skill paths (~/.agents/skills, ~/.claude/skills) for Claude Code, OpenCode, and Antigravity.

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
| agents | Comma-separated agent targets for the skills CLI | string | claude-code,opencode,antigravity |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
