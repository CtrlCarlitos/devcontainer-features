#!/bin/bash
set -e
echo "Testing curated-skills (claude-only agents)..."

REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/vscode}"

if [ -r "$REMOTE_USER_HOME/.claude/skills/find-skills/SKILL.md" ]; then
    echo "✓ ~/.claude/skills/find-skills present and readable"
else
    echo "✗ ~/.claude/skills/find-skills missing or unreadable"
    exit 1
fi

for skill in find-skills agent-browser skill-creator frontend-design codebase-design domain-modeling grill-with-docs improve-codebase-architecture prototype research grilling handoff teach writing-for-agents resolving-merge-conflicts mp-code-review; do
    skill_file="$REMOTE_USER_HOME/.claude/skills/$skill/SKILL.md"
    if [ -r "$skill_file" ]; then
        echo "✓ ~/.claude/skills/$skill present and readable"
    else
        echo "✗ ~/.claude/skills/$skill missing or unreadable"
        exit 1
    fi

    if [ "$(stat -c %U "$skill_file")" != "${_REMOTE_USER:-vscode}" ]; then
        echo "✗ $skill_file has incorrect owner"
        exit 1
    fi
done

for root in \
    "$REMOTE_USER_HOME/.config/opencode/skills" \
    "$REMOTE_USER_HOME/.gemini/antigravity/skills" \
    "$REMOTE_USER_HOME/.gemini/antigravity-cli/skills" \
    "$REMOTE_USER_HOME/.agents/skills"; do
    if [ -d "$root" ]; then
        echo "✗ $root should not exist for the claude-code subset"
        exit 1
    fi
done

echo "✓ Test passed"
