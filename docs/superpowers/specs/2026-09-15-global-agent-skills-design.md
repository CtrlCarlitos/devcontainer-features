# Global Agent Skills Design

## Goal

Install the same curated skill roster globally for the configured remote user
so Claude Code, OpenCode, Antigravity (IDE and `agy` CLI), and Codex each
discover it through their documented native location.

## Scope

This changes `curated-skills` only. Serena, Graft, and Guardrail remain
PATH-provided tools and are not part of this integration.

## Design

The feature will install the curated roster once into an internal staging tree
and copy each installed skill directory into all native global targets:

| Agent surface | Target |
| --- | --- |
| Claude Code | `$HOME/.claude/skills` |
| OpenCode | `$HOME/.config/opencode/skills` |
| Antigravity IDE | `$HOME/.gemini/antigravity/skills` |
| Antigravity CLI (`agy`) | `$HOME/.gemini/antigravity-cli/skills` |
| Codex | `$HOME/.agents/skills` |

The staged roster is the sole source for the copies. This avoids relying on
undocumented shared-directory discovery and avoids the `skills` CLI's Codex
mapping, which differs from Codex's documented global location.

The feature will preserve the existing agent-selection option only if it can
continue to produce a complete, explicit target set. A selected target means
the corresponding documented directory or directories receive the complete
roster; `antigravity` includes both its IDE and CLI targets.

## Data Flow

1. Resolve the configured remote user's home directory.
2. Install the curated source repositories into the staging tree.
3. Validate the staged roster contains every requested `SKILL.md`, including
   renamed skills such as `mp-code-review`.
4. Copy the validated roster to every selected native target.
5. Set remote-user ownership on staging and destination trees.
6. Fail installation if staging, copying, ownership, or post-copy validation
   fails. Do not silently omit an agent.

## Verification

Add a default scenario covering all four agent selections. It must assert the
complete roster at every listed target, including both Antigravity locations.
Keep the existing single-agent and renamed-skill checks, updating their
expected locations to the documented paths. The test suite must confirm that
each installed copy has a readable `SKILL.md` and that the remote user owns the
files.

## Out of Scope

- Making every individual skill behaviorally portable across all agents.
- Registering Serena, Graft, or Guardrail as MCP servers, plugins, hooks, or
  policies.
- Relying on workspace-local `.agents/skills` for global discovery.
