#!/bin/bash
set -euo pipefail

echo "Curated Agent Skills Feature"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/$REMOTE_USER}"

SKILLS="${SKILLS:-vercel-labs/skills:find-skills,vercel-labs/agent-browser:agent-browser,anthropics/skills:skill-creator,mattpocock/skills:writing-great-skills}"
AGENTS="${AGENTS:-claude-code,opencode,antigravity}"

if ! command -v npx &> /dev/null; then
    echo "ERROR: npx not found. Add the runtime_core feature (or another Node.js source) before curated-skills."
    exit 1
fi

# Build -a flags from the comma-separated agents option
AGENT_FLAGS=()
IFS=',' read -ra AGENT_LIST <<< "$AGENTS"
for agent in "${AGENT_LIST[@]}"; do
    agent="${agent//[[:space:]]/}"
    [ -n "$agent" ] && AGENT_FLAGS+=(-a "$agent")
done

if [ "${#AGENT_FLAGS[@]}" -eq 0 ]; then
    echo "ERROR: no valid agents in AGENTS option: $AGENTS"
    exit 1
fi

# Group requested skills by source repo (repo:skill entries) so each repo
# is fetched once with all its skills in a single `skills add`.
declare -A REPO_SKILLS
IFS=',' read -ra SKILL_LIST <<< "$SKILLS"
for entry in "${SKILL_LIST[@]}"; do
    entry="${entry//[[:space:]]/}"
    [ -z "$entry" ] && continue
    if [[ "$entry" != *:* ]]; then
        echo "ERROR: invalid skill entry '$entry' (expected owner/repo:skill-name)"
        exit 1
    fi
    repo="${entry%:*}"
    skill="${entry##*:}"
    REPO_SKILLS["$repo"]+="${REPO_SKILLS[$repo]:+ }$skill"
done

if [ "${#REPO_SKILLS[@]}" -eq 0 ]; then
    echo "ERROR: no valid skills in SKILLS option: $SKILLS"
    exit 1
fi

# HOME must point at the remote user's home so the skills CLI writes
# ~/.agents/skills and ~/.claude/skills for the container user, not root.
# stdin at EOF: the CLI prompts (or stalls) when given a TTY.
for repo in "${!REPO_SKILLS[@]}"; do
    echo "Installing skills from $repo: ${REPO_SKILLS[$repo]}"
    HOME="$REMOTE_USER_HOME" npx --yes --loglevel=error skills@latest add "$repo" \
        -s ${REPO_SKILLS[$repo]} "${AGENT_FLAGS[@]}" -g -y --copy < /dev/null
done

# Feature installs run as root during image build; hand the skill trees
# back to the container user.
if [ "$(id -u)" = "0" ] && [ "$REMOTE_USER" != "root" ]; then
    chown -R "$REMOTE_USER" \
        "$REMOTE_USER_HOME/.agents" \
        "$REMOTE_USER_HOME/.claude" 2>/dev/null || true
fi

INSTALLED=0
for dir in "$REMOTE_USER_HOME/.agents/skills" "$REMOTE_USER_HOME/.claude/skills"; do
    if [ -d "$dir" ]; then
        for skill_dir in "$dir"/*; do
            [ -f "$skill_dir/SKILL.md" ] && INSTALLED=$((INSTALLED + 1))
        done
    fi
done

if [ "$INSTALLED" -eq 0 ]; then
    echo "ERROR: no skills with SKILL.md found under $REMOTE_USER_HOME after install."
    exit 1
fi

echo "Curated skills installed ($INSTALLED skill directories verified)."
