#!/bin/bash
set -euo pipefail

echo "Curated Agent Skills Feature"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/$REMOTE_USER}"

SKILLS="${SKILLS:-vercel-labs/skills:find-skills,vercel-labs/agent-browser:agent-browser,anthropics/skills:skill-creator,anthropics/skills:frontend-design,mattpocock/skills:codebase-design,mattpocock/skills:domain-modeling,mattpocock/skills:grill-with-docs,mattpocock/skills:improve-codebase-architecture,mattpocock/skills:prototype,mattpocock/skills:research,mattpocock/skills:grilling,mattpocock/skills:handoff,mattpocock/skills:teach,mattpocock/skills:writing-for-agents,mattpocock/skills:resolving-merge-conflicts,mattpocock/skills:code-review>mp-code-review}"
AGENTS="${AGENTS:-claude-code,opencode,antigravity,codex}"

if ! command -v npx &> /dev/null; then
    echo "ERROR: npx not found. Add the runtime_core feature (or another Node.js source) before curated-skills."
    exit 1
fi

# Resolve the comma-separated agent option to its native global skill roots.
TARGET_DIRS=()
declare -A TARGET_DIR_SEEN=()
IFS=',' read -ra AGENT_LIST <<< "$AGENTS"
for agent in "${AGENT_LIST[@]}"; do
    agent="${agent//[[:space:]]/}"
    [ -z "$agent" ] && continue

    case "$agent" in
        claude-code) resolved_dirs=("$REMOTE_USER_HOME/.claude/skills") ;;
        opencode) resolved_dirs=("$REMOTE_USER_HOME/.config/opencode/skills") ;;
        antigravity)
            resolved_dirs=(
                "$REMOTE_USER_HOME/.gemini/antigravity/skills"
                "$REMOTE_USER_HOME/.gemini/antigravity-cli/skills"
            )
            ;;
        codex) resolved_dirs=("$REMOTE_USER_HOME/.agents/skills") ;;
        *) echo "ERROR: unsupported agent '$agent'"; exit 1 ;;
    esac

    for target_dir in "${resolved_dirs[@]}"; do
        if [ -z "${TARGET_DIR_SEEN[$target_dir]+x}" ]; then
            TARGET_DIRS+=("$target_dir")
            TARGET_DIR_SEEN["$target_dir"]=1
        fi
    done
done

if [ "${#TARGET_DIRS[@]}" -eq 0 ]; then
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

# Stage the CLI's Claude Code output once, then copy the canonical roster to
# each selected native target. stdin at EOF prevents interactive CLI prompts.
STAGING_HOME="$(mktemp -d)"
trap 'rm -rf "$STAGING_HOME"' EXIT
STAGED_SKILLS="$STAGING_HOME/.claude/skills"

if [ "${#REPO_SKILLS[@]}" -gt 0 ]; then
    for repo in "${!REPO_SKILLS[@]}"; do
        echo "Installing skills from $repo: ${REPO_SKILLS[$repo]}"
        HOME="$STAGING_HOME" npx --yes --loglevel=error skills@latest add "$repo" \
            -s ${REPO_SKILLS[$repo]} -a claude-code -g -y --copy < /dev/null
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
    HOME="$STAGING_HOME" npx --yes --loglevel=error skills@latest add "$tmp/stage" \
        -s "$newname" -a claude-code -g -y --copy < /dev/null
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

if ! find "$STAGED_SKILLS" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print -quit | grep -q .; then
    echo "ERROR: no staged skills with SKILL.md found after install."
    exit 1
fi

STAGED_COUNT=0
for skill_dir in "$STAGED_SKILLS"/*; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        echo "ERROR: staged skill '$skill_name' is missing SKILL.md"
        exit 1
    fi
    STAGED_COUNT=$((STAGED_COUNT + 1))

    for target_dir in "${TARGET_DIRS[@]}"; do
        mkdir -p "$target_dir"
        rm -rf "$target_dir/$skill_name"
        cp -a "$skill_dir" "$target_dir/"
        if [ "$(id -u)" = "0" ] && [ "$REMOTE_USER" != "root" ]; then
            chown -R "$REMOTE_USER" "$target_dir/$skill_name"
        fi
    done
done

if [ "$STAGED_COUNT" -eq 0 ]; then
    echo "ERROR: no staged skill directories found after install."
    exit 1
fi

for skill_dir in "$STAGED_SKILLS"/*; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    for target_dir in "${TARGET_DIRS[@]}"; do
        if [ ! -f "$target_dir/$skill_name/SKILL.md" ]; then
            echo "ERROR: target '$target_dir' is missing SKILL.md for skill '$skill_name'"
            exit 1
        fi
    done
done

echo "Curated skills installed ($STAGED_COUNT staged skills copied to ${#TARGET_DIRS[@]} target directories)."
