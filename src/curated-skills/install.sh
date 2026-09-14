#!/bin/bash
set -euo pipefail

echo "Curated Agent Skills Feature"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/$REMOTE_USER}"

SKILLS="${SKILLS:-vercel-labs/skills:find-skills,vercel-labs/agent-browser:agent-browser,anthropics/skills:skill-creator,anthropics/skills:frontend-design,mattpocock/skills:codebase-design,mattpocock/skills:domain-modeling,mattpocock/skills:grill-with-docs,mattpocock/skills:improve-codebase-architecture,mattpocock/skills:prototype,mattpocock/skills:research,mattpocock/skills:grilling,mattpocock/skills:handoff,mattpocock/skills:teach,mattpocock/skills:writing-for-agents,mattpocock/skills:resolving-merge-conflicts,mattpocock/skills:code-review>mp-code-review}"
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

valid_name() {
    [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

# Parse entries: "owner/repo:skill" installs as-is (grouped by repo);
# "owner/repo:skill>local-name" stages a renamed copy to dodge name
# collisions with the user's own commands/skills.
declare -A REPO_SKILLS=()
RENAMED=()
IFS=',' read -ra SKILL_LIST <<< "$SKILLS"
for entry in "${SKILL_LIST[@]}"; do
    entry="${entry//[[:space:]]/}"
    [ -z "$entry" ] && continue

    newname=""
    if [[ "$entry" == *">"* ]]; then
        newname="${entry##*>}"
        entry="${entry%>*}"
    fi

    if [[ "$entry" != *:* ]]; then
        echo "ERROR: invalid skill entry '$entry' (expected owner/repo:skill-name)"
        exit 1
    fi
    repo="${entry%:*}"
    skill="${entry##*:}"

    if ! valid_name "$skill"; then
        echo "ERROR: invalid skill name '$skill'"
        exit 1
    fi

    if [ -n "$newname" ]; then
        if ! valid_name "$newname"; then
            echo "ERROR: invalid rename target '$newname'"
            exit 1
        fi
        RENAMED+=("$repo:$skill>$newname")
    else
        REPO_SKILLS["$repo"]+="${REPO_SKILLS[$repo]:+ }$skill"
    fi
done

if [ "${#REPO_SKILLS[@]}" -eq 0 ] && [ "${#RENAMED[@]}" -eq 0 ]; then
    echo "ERROR: no valid skills in SKILLS option: $SKILLS"
    exit 1
fi

# HOME must point at the remote user's home so the skills CLI writes
# ~/.agents/skills and ~/.claude/skills for the container user, not root.
# stdin at EOF: the CLI prompts (or stalls) when given a TTY.
if [ "${#REPO_SKILLS[@]}" -gt 0 ]; then
    for repo in "${!REPO_SKILLS[@]}"; do
        echo "Installing skills from $repo: ${REPO_SKILLS[$repo]}"
        HOME="$REMOTE_USER_HOME" npx --yes --loglevel=error skills@latest add "$repo" \
            -s ${REPO_SKILLS[$repo]} "${AGENT_FLAGS[@]}" -g -y --copy < /dev/null
    done
fi

install_renamed_skill() {
    local repo="$1" skill="$2" newname="$3"
    local tmp
    tmp="$(mktemp -d)"

    if ! git clone --quiet --depth 1 "https://github.com/$repo" "$tmp/repo"; then
        echo "ERROR: failed to clone $repo for rename of '$skill'"
        rm -rf "$tmp"
        exit 1
    fi

    local src="" d
    for d in $(find "$tmp/repo" -type d -name "$skill"); do
        if [ -f "$d/SKILL.md" ]; then
            src="$d"
            break
        fi
    done
    if [ -z "$src" ]; then
        echo "ERROR: skill '$skill' not found in $repo (has upstream moved it?)"
        rm -rf "$tmp"
        exit 1
    fi

    mkdir -p "$tmp/stage/$newname"
    cp -r "$src/." "$tmp/stage/$newname/"
    sed "s/^name:[[:space:]].*/name: $newname/" "$tmp/stage/$newname/SKILL.md" > "$tmp/stage/$newname/SKILL.md.tmp"
    mv "$tmp/stage/$newname/SKILL.md.tmp" "$tmp/stage/$newname/SKILL.md"

    echo "Installing renamed skill: $repo/$skill -> $newname"
    HOME="$REMOTE_USER_HOME" npx --yes --loglevel=error skills@latest add "$tmp/stage" \
        -s "$newname" "${AGENT_FLAGS[@]}" -g -y --copy < /dev/null
    rm -rf "$tmp"
}

if [ "${#RENAMED[@]}" -gt 0 ]; then
    if ! command -v git &> /dev/null; then
        echo "ERROR: git not found (required for skill renames: ${RENAMED[*]})"
        exit 1
    fi
    for entry in "${RENAMED[@]}"; do
        install_renamed_skill "${entry%%:*}" "$(echo "${entry#*:}" | cut -d'>' -f1)" "${entry##*>}"
    done
fi

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
