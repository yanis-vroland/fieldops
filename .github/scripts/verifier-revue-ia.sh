#!/usr/bin/env bash
# Fait échouer le job de revue IA si la revue n'a pas tourné ou si des actions
# ont été refusées pendant la revue.
# Spec : https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/002-hook-protect-secrets.md (CA25, CA26)
# Usage : verifier-revue-ia.sh <fichier de résultat de claude-code-action>
set -euo pipefail

file=${1:-}

if [ -z "$file" ] || [ ! -s "$file" ]; then
  echo "::error::Revue IA non exécutée : aucun fichier de résultat (action sautée ou en échec)."
  exit 1
fi

# Accepte un tableau de messages ou un message par ligne ; retient le dernier « result »
if ! count=$(jq -rs '
    flatten
    | map(select(type == "object" and .type == "result"))
    | last
    | if . == null then "absent"
      elif has("permission_denials_count") then .permission_denials_count
      elif has("permission_denials") then (.permission_denials | length)
      else "absent" end
  ' "$file" 2>/dev/null); then
  echo "::error::Revue IA : fichier de résultat illisible ($file)."
  exit 1
fi

if ! [[ $count =~ ^[0-9]+$ ]]; then
  echo "::error::Revue IA : aucun résultat exploitable dans $file. Types de messages trouvés :"
  jq -sc 'flatten | map(.type? // type)' "$file" | cut -c1-500
  exit 1
fi

if [ "$count" -gt 0 ]; then
  echo "::error::Revue IA : $count action(s) refusée(s) pendant la revue. Le rapport peut être incomplet ou absent."
  exit 1
fi

echo "Revue IA exécutée, aucune action refusée."
