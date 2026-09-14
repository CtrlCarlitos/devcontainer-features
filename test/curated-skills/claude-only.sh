#!/bin/bash
set -e
echo "Testing curated-skills (claude-only agents)..."

REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/vscode}"

if [ -f "$REMOTE_USER_HOME/.claude/skills/find-skills/SKILL.md" ]; then
    echo "✓ ~/.claude/skills/find-skills present"
else
    echo "✗ ~/.claude/skills/find-skills missing"
    exit 1
fi

for skill in find-skills agent-browser skill-creator writing-for-agents; do
    if [ -f "$REMOTE_USER_HOME/.claude/skills/$skill/SKILL.md" ]; then
        echo "✓ ~/.claude/skills/$skill present"
    else
        echo "✗ ~/.claude/skills/$skill missing"
        exit 1
    fi
done

echo "✓ Test passed"
