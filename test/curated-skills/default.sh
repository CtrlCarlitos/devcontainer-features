#!/bin/bash
set -e
echo "Testing curated-skills (default)..."

REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/vscode}"
EXPECTED="find-skills agent-browser skill-creator frontend-design codebase-design domain-modeling grill-with-docs improve-codebase-architecture prototype research grilling handoff teach writing-for-agents resolving-merge-conflicts mp-code-review"

for skill in $EXPECTED; do
    if [ -f "$REMOTE_USER_HOME/.agents/skills/$skill/SKILL.md" ]; then
        echo "✓ ~/.agents/skills/$skill present"
    else
        echo "✗ ~/.agents/skills/$skill missing"
        exit 1
    fi
done

for skill in $EXPECTED; do
    if [ -f "$REMOTE_USER_HOME/.claude/skills/$skill/SKILL.md" ]; then
        echo "✓ ~/.claude/skills/$skill present"
    else
        echo "✗ ~/.claude/skills/$skill missing"
        exit 1
    fi
done

echo "✓ Test passed"
