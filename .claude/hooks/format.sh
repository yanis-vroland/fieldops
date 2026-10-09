#!/usr/bin/env bash
# Formate le fichier modifié par l'agent, si Prettier est installé dans le projet.

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -z "$file" ] && exit 0

cd "$CLAUDE_PROJECT_DIR" || exit 0
if [ -x node_modules/.bin/prettier ]; then
  node_modules/.bin/prettier --write --ignore-unknown "$file" >/dev/null 2>&1 || true
fi

exit 0
