#!/bin/bash
set -e
echo "Testing curated-skills (single-skill)..."

REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/vscode}"
SKILL_ROOTS=(
    "$REMOTE_USER_HOME/.claude/skills"
    "$REMOTE_USER_HOME/.config/opencode/skills"
    "$REMOTE_USER_HOME/.gemini/antigravity/skills"
    "$REMOTE_USER_HOME/.gemini/antigravity-cli/skills"
    "$REMOTE_USER_HOME/.agents/skills"
)

for root in "${SKILL_ROOTS[@]}"; do
    if [ -f "$root/find-skills/SKILL.md" ]; then
        echo "✓ $root/find-skills installed"
    else
        echo "✗ $root/find-skills missing"
        exit 1
    fi

    COUNT=$(find "$root" -mindepth 1 -maxdepth 1 -type d | wc -l)
    if [ "$COUNT" -ne 1 ]; then
        echo "✗ $root expected exactly 1 skill directory, found $COUNT:"
        ls "$root"
        exit 1
    fi
    echo "✓ $root has exactly one skill installed"
done

echo "✓ Test passed"
