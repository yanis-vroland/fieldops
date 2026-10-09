#!/usr/bin/env bash
# Vérifie .github/scripts/verifier-revue-ia.sh (spec 002, CA25 et CA26) sur des
# fichiers de résultat factices de claude-code-action.
set -u

script="$(cd "$(dirname "$0")/.." && pwd)/.github/scripts/verifier-revue-ia.sh"
fail=0

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

output=""

# check <code attendu> <description> <fragment attendu ou vide> <argument>
check() {
  local expected=$1 description=$2 fragment=$3
  shift 3
  output=$("$script" "$@" 2>&1)
  local code=$?
  if [ "$code" -ne "$expected" ]; then
    echo "ÉCHEC  $description (attendu $expected, obtenu $code : $output)"
    fail=1
  elif [ -n "$fragment" ] && ! grep -qiF -- "$fragment" <<<"$output"; then
    echo "ÉCHEC  $description (fragment « $fragment » absent : $output)"
    fail=1
  else
    echo "OK     $description"
  fi
}

# Fichier au format de l'action : tableau de messages, le dernier de type result
result_file() {
  local name=$1 result=$2
  printf '[{"type":"system","subtype":"init"},%s]\n' "$result" >"$work/$name"
  echo "$work/$name"
}

f=$(result_file zero.json '{"type":"result","subtype":"success","permission_denials_count":0}')
check 0 "CA25 : aucun refus : succès" "" "$f"

f=$(result_file trois.json '{"type":"result","subtype":"success","permission_denials_count":3}')
check 1 "CA25 : 3 refus : échec, nombre affiché" "3" "$f"

f=$(result_file liste.json '{"type":"result","subtype":"success","permission_denials":[{"tool_name":"Bash"},{"tool_name":"Bash"}]}')
check 1 "CA25 : liste de 2 refus : échec" "2" "$f"

f=$(result_file liste-vide.json '{"type":"result","subtype":"success","permission_denials":[]}')
check 0 "CA25 : liste de refus vide : succès" "" "$f"

# Format en lignes JSON (un message par ligne)
printf '%s\n' '{"type":"system","subtype":"init"}' \
  '{"type":"result","subtype":"success","permission_denials_count":0}' >"$work/lignes.jsonl"
check 0 "CA25 : format en lignes JSON, aucun refus : succès" "" "$work/lignes.jsonl"

# CA26 : revue non exécutée
check 1 "CA26 : fichier absent : échec" "non exécutée" "$work/absent.json"
check 1 "CA26 : argument vide : échec" "non exécutée" ""
: >"$work/vide.json"
check 1 "CA26 : fichier vide : échec" "non exécutée" "$work/vide.json"
printf 'pas du json {' >"$work/invalide.json"
check 1 "CA26 : fichier illisible : échec" "" "$work/invalide.json"
f=$(result_file sans-resultat.json '{"type":"assistant"}')
check 1 "CA26 : aucun message result : échec" "" "$f"
f=$(result_file sans-compteur.json '{"type":"result","subtype":"success"}')
check 1 "CA26 : result sans compteur de refus : échec" "" "$f"
f=$(result_file compteur-null.json '{"type":"result","subtype":"success","permission_denials_count":null}')
check 1 "CA26 : compteur non numérique : échec" "" "$f"

exit $fail
