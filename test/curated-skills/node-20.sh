#!/bin/bash
set -e
echo "Testing curated-skills on Node 20..."

REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/vscode}"
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"

if [ "$NODE_MAJOR" != "20" ]; then
    echo "Expected Node 20, got $(node --version)"
    exit 1
fi

SKILL_FILE="$REMOTE_USER_HOME/.claude/skills/find-skills/SKILL.md"
if [ ! -r "$SKILL_FILE" ]; then
    echo "$SKILL_FILE missing or unreadable"
    exit 1
fi

echo "Node $(node --version) installed curated skills successfully."
