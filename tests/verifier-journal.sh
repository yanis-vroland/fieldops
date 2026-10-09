#!/usr/bin/env bash
# Vérifie .github/scripts/verifier-journal.sh <base> <head> selon la spec
# docs/specs/004-reprise-de-session.md (CA8 à CA16), sur des dépôts temporaires.
# Le script est lancé depuis la racine du dépôt, avec base = main et head = la
# branche de la PR. Codes : 0 accepté, 1 refusé, 2 usage invalide.
set -u

template="$(cd "$(dirname "$0")/.." && pwd -P)"
script="$template/.github/scripts/verifier-journal.sh"
fail=0

if [ ! -f "$script" ]; then
  echo "ÉCHEC  $script est absent : toutes les vérifications vont échouer"
  fail=1
fi

# Chemin canonique : sous macOS, /var est un lien vers /private/var
work="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$work"' EXIT

# Isole les tests de la configuration Git de l'utilisateur et de l'appelant
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
cat >"$work/gitconfig" <<'EOF'
[user]
	name = Test
	email = test@example.com
[init]
	defaultBranch = main
[commit]
	gpgsign = false
EOF
export GIT_CONFIG_GLOBAL="$work/gitconfig"
export GIT_CONFIG_NOSYSTEM=1

# --- Outils de vérification -------------------------------------------------

output=""
code=0

pass() {
  echo "OK     $1"
}

failed() {
  echo "ÉCHEC  $1${2:+ ($2)}"
  fail=1
}

# Lance le script depuis la racine du dépôt
run_script() {
  local repo=$1
  shift
  output=$(cd "$repo" && "$script" "$@" 2>&1)
  code=$?
}

# verify <code attendu> <description> <fragment ou vide> : vérifie le dernier lancement
verify() {
  local expected=$1 description=$2 fragment=$3
  if [ "$code" -ne "$expected" ]; then
    failed "$description" "attendu $expected, obtenu $code : $(head -n 1 <<<"$output")"
  elif [ -n "$fragment" ] && ! grep -qiF -- "$fragment" <<<"$output"; then
    failed "$description" "fragment « $fragment » absent de la sortie : $(head -n 1 <<<"$output")"
  else
    pass "$description"
  fi
}

# write_file <dépôt> <chemin> <contenu>
write_file() {
  mkdir -p "$(dirname "$1/$2")"
  printf '%s\n' "$3" >"$1/$2"
}

commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -q -m "$2"
}

# Journal déjà mergé sur main
base_journal='# Journal : feat/ancienne

## 2026-10-01 09:00

- Fait : mise en place'

# Nouveau dépôt : main avec un README et un journal déjà mergé ; affiche son chemin
new_repo() {
  local r
  r=$(mktemp -d "$work/repo.XXXXXX")
  git init -q -b main "$r"
  write_file "$r" README.md "Projet de test"
  write_file "$r" docs/journal/2026-10-01-feat-ancienne.md "$base_journal"
  commit_all "$r" "chore: initialisation"
  echo "$r"
}

# Ajoute docs/journal.md (ancien format) sur main
add_old_journal() {
  write_file "$1" docs/journal.md '# Journal de bord

## 2026-01-01 : première entrée

- Une note.'
  commit_all "$1" "docs: ancien journal"
}

# case_add <code attendu> <description> <fragment> <chemin> <contenu>
# PR qui ajoute un seul fichier sur la branche feat/pr depuis main
case_add() {
  local expected=$1 description=$2 fragment=$3 path=$4 content=$5 r
  r=$(new_repo)
  git -C "$r" checkout -q -b feat/pr
  write_file "$r" "$path" "$content"
  commit_all "$r" "docs: journal de la PR"
  run_script "$r" main feat/pr
  verify "$expected" "$description" "$fragment"
}

# Fichier de journal conforme : plusieurs entrées, rubriques en niveau 3
valid_journal='# Journal : feat/pr

## 2026-10-08 09:15

### Fait

- Spec rédigée.

### Décisions

- rien

### Corrections et limites

- rien

### Prochaine étape

- Écrire les tests.

## 2026-10-08 17:40

### Fait

- Tests écrits.

## 2026-10-09 08:05

### Prochaine étape

- Implémenter.'

# --- CA8 : fichier conforme --------------------------------------------------

case_add 0 "CA8 : fichier de journal conforme accepté" "" \
  docs/journal/2026-10-08-feat-pr.md "$valid_journal"

# --- CA9 : fichier présent dans la base modifié, supprimé ou renommé ---------

r=$(new_repo)
git -C "$r" checkout -q -b feat/pr
printf '\n## 2026-10-09 10:00\n\n- Fait : ajout tardif\n' \
  >>"$r/docs/journal/2026-10-01-feat-ancienne.md"
commit_all "$r" "docs: modification d'un journal mergé"
run_script "$r" main feat/pr
verify 1 "CA9 : journal de la base modifié refusé, fichier cité" "2026-10-01-feat-ancienne.md"

r=$(new_repo)
git -C "$r" checkout -q -b feat/pr
git -C "$r" rm -q docs/journal/2026-10-01-feat-ancienne.md
commit_all "$r" "docs: suppression d'un journal mergé"
run_script "$r" main feat/pr
verify 1 "CA9 : journal de la base supprimé refusé, fichier cité" "2026-10-01-feat-ancienne.md"

r=$(new_repo)
git -C "$r" checkout -q -b feat/pr
git -C "$r" mv docs/journal/2026-10-01-feat-ancienne.md docs/journal/2026-10-01-feat-renomme.md
commit_all "$r" "docs: renommage d'un journal mergé"
run_script "$r" main feat/pr
# L'ancien ou le nouveau nom peut être cité : les deux commencent ainsi
verify 1 "CA9 : journal de la base renommé refusé, fichier cité" "2026-10-01-feat-"

# --- CA10 : nom de fichier invalide (format ou date) -------------------------

entry='# Journal

## 2026-10-09 10:00

- Fait : quelque chose'

case_add 1 "CA10 : nom avec majuscules refusé, fichier cité" "2026-10-09-Feat-Majuscules.md" \
  docs/journal/2026-10-09-Feat-Majuscules.md "$entry"
case_add 1 "CA10 : nom sans date refusé, fichier cité" "feat-sans-date.md" \
  docs/journal/feat-sans-date.md "$entry"
case_add 1 "CA10 : fichier dans un sous-dossier refusé, chemin cité" "sous-dossier" \
  docs/journal/sous-dossier/2026-10-09-feat-x.md "$entry"
case_add 1 "CA10 : slug avec un tiret bas refusé, fichier cité" "2026-10-09-feat_x.md" \
  docs/journal/2026-10-09-feat_x.md "$entry"
case_add 1 "CA10 : extension autre que .md refusée, fichier cité" "2026-10-09-feat-x.txt" \
  docs/journal/2026-10-09-feat-x.txt "$entry"
case_add 1 "CA10 : date de nom invalide (2026-02-30) refusée, fichier cité" "2026-02-30-feat-x.md" \
  docs/journal/2026-02-30-feat-x.md "$entry"
case_add 1 "CA10 : date de nom invalide (2026-13-01) refusée, fichier cité" "2026-13-01-feat-x.md" \
  docs/journal/2026-13-01-feat-x.md "$entry"

# --- CA11 : titre d'entrée invalide (format ou date) -------------------------
# La date du nom diffère de celle du titre fautif, pour que le fragment cherché
# ne puisse venir que du titre cité.

case_add 1 "CA11 : titre sans heure refusé, titre cité" "2026-10-09" \
  docs/journal/2026-10-08-feat-titre.md '# Journal

## 2026-10-08 10:00

- Fait : entrée valide

## 2026-10-09

- Fait : titre sans heure'
case_add 1 "CA11 : heure invalide (25:00) refusée, titre cité" "25:00" \
  docs/journal/2026-10-08-feat-titre.md '# Journal

## 2026-10-08 10:00

- Fait : entrée valide

## 2026-10-09 25:00

- Fait : heure invalide'
case_add 1 "CA11 : date de titre invalide (2026-02-30) refusée, titre cité" "2026-02-30" \
  docs/journal/2026-02-01-feat-titre.md '# Journal

## 2026-02-01 10:00

- Fait : entrée valide

## 2026-02-30 10:00

- Fait : date invalide'
case_add 1 "CA11 : titre sans date (## Notes) refusé, titre cité" "Notes" \
  docs/journal/2026-10-08-feat-titre.md '# Journal

## 2026-10-08 10:00

- Fait : entrée valide

## Notes

- Un titre libre'

# --- CA12 : ordre chronologique et date du nom --------------------------------

case_add 1 "CA12 : entrées non chronologiques refusées, fichier cité" "2026-10-09-feat-ordre.md" \
  docs/journal/2026-10-09-feat-ordre.md '# Journal

## 2026-10-09 14:00

- Fait : après-midi

## 2026-10-09 09:00

- Fait : matin, écrit après'
case_add 1 "CA12 : entrée antérieure à la date du nom refusée, fichier cité" "2026-10-09-feat-avant.md" \
  docs/journal/2026-10-09-feat-avant.md '# Journal

## 2026-10-08 23:59

- Fait : la veille de la création'
case_add 0 "CA12 : deux entrées à la même minute acceptées" "" \
  docs/journal/2026-10-09-feat-meme-minute.md '# Journal

## 2026-10-09 10:00

- Fait : première

## 2026-10-09 10:00

- Fait : seconde'

# --- CA13 : docs/journal.md recréé ou modifié --------------------------------

r=$(new_repo)
git -C "$r" checkout -q -b feat/pr
write_file "$r" docs/journal.md '# Journal de bord

## 2026-10-09 : recréé'
commit_all "$r" "docs: recréation de l'ancien journal"
run_script "$r" main feat/pr
verify 1 "CA13 : docs/journal.md recréé refusé, fichier cité" "journal.md"

r=$(new_repo)
add_old_journal "$r"
git -C "$r" checkout -q -b feat/pr
printf '\n## 2026-10-09 : ajout\n' >>"$r/docs/journal.md"
commit_all "$r" "docs: modification de l'ancien journal"
run_script "$r" main feat/pr
verify 1 "CA13 : docs/journal.md modifié refusé, fichier cité" "journal.md"

# --- CA14 : PR sans journal, suppression de docs/journal.md, .gitkeep ---------

r=$(new_repo)
git -C "$r" checkout -q -b feat/pr
write_file "$r" src/app.txt "code"
commit_all "$r" "feat: code sans journal"
run_script "$r" main feat/pr
verify 0 "CA14 : PR qui ne touche pas docs/journal/ acceptée" ""

r=$(new_repo)
add_old_journal "$r"
git -C "$r" checkout -q -b feat/pr
git -C "$r" rm -q docs/journal.md
commit_all "$r" "docs: suppression de l'ancien journal"
run_script "$r" main feat/pr
verify 0 "CA14 : docs/journal.md supprimé accepté" ""

r=$(new_repo)
add_old_journal "$r"
git -C "$r" checkout -q -b feat/pr
git -C "$r" mv docs/journal.md docs/journal/2026-01-01-historique.md
commit_all "$r" "docs: migration de l'ancien journal"
run_script "$r" main feat/pr
verify 0 "CA14/CA15 : migration par git mv vers 2026-01-01-historique.md acceptée" ""

case_add 0 "CA14 : docs/journal/.gitkeep ajouté accepté" "" docs/journal/.gitkeep ""

# --- CA15 : historique à l'ancien format --------------------------------------

case_add 0 "CA15 : 2026-10-07-historique.md avec titres à l'ancien format accepté" "" \
  docs/journal/2026-10-07-historique.md '# Journal de bord

## 2026-10-07 : mise en place

- Une note.

## 2026-10-08 : suite

- Une autre note.'
case_add 1 "CA15 : historique au nom invalide (2026-13-01) refusé, fichier cité" "2026-13-01-historique.md" \
  docs/journal/2026-13-01-historique.md '# Journal de bord

## 2026-10-07 : mise en place'

# --- CA16 : deux branches parallèles, fusionnées l'une après l'autre ---------

r=$(new_repo)
git -C "$r" checkout -q -b feat/un
write_file "$r" docs/journal/2026-10-09-feat-un.md '# Journal : feat/un

## 2026-10-09 10:00

- Fait : branche un'
commit_all "$r" "docs: journal de feat/un"
git -C "$r" checkout -q main
git -C "$r" checkout -q -b feat/deux
write_file "$r" docs/journal/2026-10-09-feat-deux.md '# Journal : feat/deux

## 2026-10-09 11:00

- Fait : branche deux'
commit_all "$r" "docs: journal de feat/deux"
git -C "$r" checkout -q main

git -C "$r" merge -q --no-ff -m "Merge feat/un" feat/un >/dev/null 2>&1
code=$?
verify 0 "CA16 : merge de la première branche sans conflit" ""

run_script "$r" main feat/deux
verify 0 "CA16 : script accepté pour la seconde branche, base = main après le premier merge" ""

git -C "$r" merge -q --no-ff -m "Merge feat/deux" feat/deux >/dev/null 2>&1
code=$?
verify 0 "CA16 : merge de la seconde branche sans conflit" ""

# --- Usage invalide ----------------------------------------------------------

r=$(new_repo)
run_script "$r"
verify 2 "Usage : aucun argument, code de sortie 2" ""
run_script "$r" main
verify 2 "Usage : un seul argument, code de sortie 2" ""

exit $fail
