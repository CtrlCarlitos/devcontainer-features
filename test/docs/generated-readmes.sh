#!/bin/bash
set -euo pipefail

temporary_copy="$(mktemp -d)"
trap 'rm -rf "$temporary_copy"' EXIT

cp -a src/. "$temporary_copy"
rm -f "$temporary_copy"/*/README.md
npx --yes @devcontainers/cli features generate-docs \
    --project-folder "$temporary_copy" \
    --namespace CtrlCarlitos/devcontainer-features

shopt -s nullglob
metadata_files=(src/*/devcontainer-feature.json)

if [ "${#metadata_files[@]}" -eq 0 ]; then
    echo "No feature metadata files found" >&2
    exit 1
fi

for metadata in "${metadata_files[@]}"; do
    feature_directory="${metadata%/devcontainer-feature.json}"
    feature="${feature_directory##*/}"
    cmp "$feature_directory/README.md" "$temporary_copy/$feature/README.md"
done
