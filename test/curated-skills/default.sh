#!/bin/bash
set -e
echo "Testing curated-skills (default)..."

REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/vscode}"
EXPECTED="find-skills agent-browser skill-creator frontend-design codebase-design domain-modeling grill-with-docs improve-codebase-architecture prototype research grilling handoff teach writing-for-agents resolving-merge-conflicts mp-code-review"
SKILL_ROOTS=(
    "$REMOTE_USER_HOME/.claude/skills"
    "$REMOTE_USER_HOME/.config/opencode/skills"
    "$REMOTE_USER_HOME/.gemini/antigravity/skills"
    "$REMOTE_USER_HOME/.gemini/antigravity-cli/skills"
    "$REMOTE_USER_HOME/.agents/skills"
)

for root in "${SKILL_ROOTS[@]}"; do
    for skill in $EXPECTED; do
        skill_file="$root/$skill/SKILL.md"
        if [ ! -f "$skill_file" ]; then
            echo "✗ $skill_file missing"
            exit 1
        fi
        if [ "$(stat -c %U "$skill_file")" != "${_REMOTE_USER:-vscode}" ]; then
            echo "✗ $skill_file has incorrect owner"
            exit 1
        fi
        echo "✓ $skill_file present and owned by ${_REMOTE_USER:-vscode}"
    done
done

echo "✓ Test passed"
