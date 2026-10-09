#!/usr/bin/env bash
# Vérifie le hook protect-secrets selon la spec https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/002-hook-protect-secrets.md
set -u

hook="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks/protect-secrets.sh"
fail=0

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Sortie (stderr) du dernier lancement, pour vérifier un fragment du message
output=""

# check <code attendu> <description> <entrée> [PATH]
check() {
  local expected=$1 description=$2 input=$3 path=${4:-$PATH}
  output=$(printf '%s' "$input" | PATH="$path" "$hook" 2>&1 >/dev/null)
  local code=$?
  if [ "$code" -eq "$expected" ]; then
    echo "OK     $description"
  else
    echo "ÉCHEC  $description (attendu $expected, obtenu $code)"
    fail=1
  fi
}

# --- Comportement actuel conservé -------------------------------------------

# Doit être bloqué (exit 2)
check 2 "CA1 : Read .env"             '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env"}}'
check 2 "CA2 : Read .env.local"       '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.local"}}'
check 2 "CA3 : Write .env.production" '{"tool_name":"Write","tool_input":{"file_path":"/repo/.env.production"}}'
check 2 "CA4 : Bash cat .env"         '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}'

# Doit passer (exit 0)
check 0 "CA5 : Read .env.example"     '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.example"}}'
check 0 "CA6 : Edit src/app.ts"       '{"tool_name":"Edit","tool_input":{"file_path":"/repo/src/app.ts"}}'
check 0 "CA7 : Bash grep process.env" '{"tool_name":"Bash","tool_input":{"command":"grep -r process.env src"}}'
check 0 "CA8 : Read .envrc"           '{"tool_name":"Read","tool_input":{"file_path":"/repo/.envrc"}}'

# --- Fermeture en cas de panne (#7) -----------------------------------------

# PATH réduit aux seuls binaires dont le hook a besoin, sans jq. Retirer /usr/bin
# du PATH ne convient pas : sur Ubuntu, jq y côtoie bash et cat.
no_jq="$work/bin"
mkdir "$no_jq"
for cmd in bash cat; do
  ln -s "$(command -v "$cmd")" "$no_jq/$cmd"
done
check 2 "CA9 : jq absent : refus" \
  '{"tool_name":"Read","tool_input":{"file_path":"/repo/src/app.ts"}}' "$no_jq"
if grep -q "jq" <<<"$output"; then
  echo "OK     CA9 : jq absent : message cite jq"
else
  echo "ÉCHEC  CA9 : jq absent : message sans jq (sortie : $output)"
  fail=1
fi

check 2 "CA10 : JSON invalide"           'pas du json {'
check 2 "CA11 : entrée vide"             ''
check 2 "CA12 : tool_name absent"        '{"tool_input":{"file_path":"/repo/src/app.ts"}}'
check 2 "CA13 : tool_input absent"       '{"tool_name":"Read"}'
check 2 "CA12 : tool_name non textuel"   '{"tool_name":5,"tool_input":{"file_path":"/repo/src/app.ts"}}'
check 2 "CA14 : Read sans file_path"     '{"tool_name":"Read","tool_input":{}}'
check 2 "CA14 : Edit sans file_path"     '{"tool_name":"Edit","tool_input":{}}'
check 2 "CA14 : Write sans file_path"    '{"tool_name":"Write","tool_input":{}}'
check 2 "CA14 : MultiEdit sans file_path" '{"tool_name":"MultiEdit","tool_input":{}}'
check 2 "Règle 2 : MultiEdit .env"       '{"tool_name":"MultiEdit","tool_input":{"file_path":"/repo/.env"}}'
check 0 "Règle 4 : autre outil autorisé" '{"tool_name":"Grep","tool_input":{}}'
check 2 "CA15 : Bash sans command"       '{"tool_name":"Bash","tool_input":{}}'

# CA16 : une erreur interne ne doit jamais laisser passer. Les cas testés
# couvrent les commandes externes manquantes (jq en CA9, cat ici) et des entrées
# hors contrat (CA10 à CA15, tool_name non textuel). Limite : une erreur de
# set -u ou un échec de jq après la validation ne peuvent pas être provoqués
# de l'extérieur ; seul le trap EXIT du hook les couvre (vérifié par mutation :
# sans le trap, le cas ci-dessous sort en 127).
no_cat="$work/bin-sans-cat"
mkdir "$no_cat"
for cmd in bash jq; do
  ln -s "$(command -v "$cmd")" "$no_cat/$cmd"
done
check 2 "CA16 : cat absent : refus" \
  '{"tool_name":"Read","tool_input":{"file_path":"/repo/src/app.ts"}}' "$no_cat"

# --- Chemin protégé : dernier segment du chemin (règle 2) -------------------

check 0 "Règle 2 : Read dans un dossier .env.d" '{"tool_name":"Read","tool_input":{"file_path":"/repo/.env.d/x.txt"}}'
check 0 "Règle 2 : Read dans un dossier .env"   '{"tool_name":"Read","tool_input":{"file_path":"/home/u/.env/notes.md"}}'
check 2 "Règle 2 : Edit ./.env.production"      '{"tool_name":"Edit","tool_input":{"file_path":"./.env.production"}}'

# --- Commandes Bash (#9) ----------------------------------------------------

# check_bash <code attendu> <description> <commande> : construit l'entrée avec jq
check_bash() {
  check "$1" "$2" "$(jq -nc --arg c "$3" '{tool_name: "Bash", tool_input: {command: $c}}')"
}

# CA17 : accès réels qui restent refusés
check_bash 2 "CA17 : cat .env"                 'cat .env'
check_bash 2 "CA17 : source .env"              'source .env'
check_bash 2 "CA17 : . .env"                   '. .env'
check_bash 2 "CA17 : cp .env /tmp/copie"       'cp .env /tmp/copie'
check_bash 2 "CA17 : wc -l < .env"             'wc -l < .env'
check_bash 2 "CA17 : cat .env.local"           'cat .env.local'
check_bash 2 "CA17 : cat ./config/.env"        'cat ./config/.env'
check_bash 2 "CA17 : cat \".env\""             'cat ".env"'
check_bash 2 "CA17 : cp .env.example .env"     'cp .env.example .env'
check_bash 2 "CA17 : tool --file=.env"         'tool --file=.env'

# CA18 : commandes non analysables qui citent un fichier d'environnement
check_bash 2 "CA18 : guillemet non fermé"      'echo "a .env'
check_bash 2 "CA18 : heredoc"                  "$(printf 'cat <<EOF\n.env\nEOF')"
# Guillemets simples voulus : la commande testée contient la substitution telle quelle
# shellcheck disable=SC2016
check_bash 2 "CA18 : substitution \$(…)"       'echo $(cat .env)'
# shellcheck disable=SC2016
check_bash 2 "CA18 : accents graves"           'echo `cat .env`'
check_bash 2 "CA18 : substitution de processus" 'diff <(cat .env) x'

# CA19 : texte exécuté comme du code
check_bash 2 "CA19 : bash -c"                  'bash -c "cat .env"'
check_bash 2 "CA19 : python3 -c"               "python3 -c \"open('.env').read()\""
check_bash 2 "CA19 : eval"                     'eval "cat .env"'

# CA20 : motif qui peut s'étendre en fichier d'environnement
check_bash 2 "CA20 : cat .env*"                'cat .env*'

# CA21 à CA24 : mentions dans un texte, désormais autorisées
check_bash 0 "CA21 : gh pr comment --body"     'gh pr comment 8 --body "le .gitignore ajoute .env.* puis la négation"'
check_bash 0 "CA22 : git commit -m"            'git commit -m "chore: ignorer .env.local"'
check_bash 0 "CA23 : gh issue create --title"  'gh issue create --title "fix: lecture de .env" --body-file /tmp/corps.md'
check_bash 0 "CA24 : cat .env.example"         'cat .env.example'

# Cas limites de la spec
check_bash 2 "Limite : --body-file vers un fichier d'environnement" 'gh pr comment 8 --body-file .env'
check_bash 2 "Limite : option de texte sous une commande non listée" 'foo -m "voir .env"'
check_bash 0 "Limite : .env.example cité dans un texte" 'echo "copie .env.example"'

exit $fail
