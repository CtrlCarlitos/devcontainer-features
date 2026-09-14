#!/bin/bash
set -e
echo "Testing curated-skills (single-skill)..."

REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/vscode}"
AGENTS_DIR="$REMOTE_USER_HOME/.agents/skills"

if [ -f "$AGENTS_DIR/find-skills/SKILL.md" ]; then
    echo "✓ find-skills installed"
else
    echo "✗ find-skills missing"
    exit 1
fi

COUNT=$(find "$AGENTS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$COUNT" -ne 1 ]; then
    echo "✗ expected exactly 1 skill directory, found $COUNT:"
    ls "$AGENTS_DIR"
    exit 1
fi
echo "✓ exactly one skill installed"

echo "✓ Test passed"
