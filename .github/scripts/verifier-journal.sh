#!/usr/bin/env bash
# Contrôle du journal d'une PR : un fichier par branche, jamais modifié après son
# merge, noms et entrées datés. Deux PR ne peuvent donc pas entrer en conflit.
# Spec : docs/specs/004-reprise-de-session.md
# Usage : verifier-journal.sh <base> <head>, depuis la racine du dépôt.
# Codes : 0 accepté, 1 refusé, 2 usage ou erreur Git.
set -u

if [ "$#" -ne 2 ]; then
  echo "Usage : verifier-journal.sh <base> <head>" >&2
  exit 2
fi
base=$1
head=$2

if ! changes=$(git diff --name-status --no-renames "$base...$head" -- docs/journal docs/journal.md); then
  echo "Erreur : impossible de comparer $base et $head." >&2
  exit 2
fi

fail=0
refuse() {
  echo "Refusé : $1" >&2
  fail=1
}

# valid_date <AAAA> <MM> <JJ> : date du calendrier grégorien
valid_date() {
  local y=$((10#$1)) m=$((10#$2)) d=$((10#$3)) max
  [ "$m" -ge 1 ] && [ "$m" -le 12 ] && [ "$d" -ge 1 ] || return 1
  case $m in
    2)
      if { [ $((y % 4)) -eq 0 ] && [ $((y % 100)) -ne 0 ]; } || [ $((y % 400)) -eq 0 ]; then
        max=29
      else
        max=28
      fi
      ;;
    4 | 6 | 9 | 11) max=30 ;;
    *) max=31 ;;
  esac
  [ "$d" -le "$max" ]
}

# check_entries <fichier> <date du nom> : titres datés, valides et chronologiques
check_entries() {
  local file=$1 name_date=$2 line stamp previous="" content
  content=$(git show "$head:$file") || {
    refuse "$file illisible dans $head."
    return
  }
  while IFS= read -r line; do
    if ! [[ $line =~ ^##\ ([0-9]{4})-([0-9]{2})-([0-9]{2})\ ([0-9]{2}):([0-9]{2})$ ]]; then
      refuse "$file : titre « $line » invalide, format attendu « ## AAAA-MM-JJ HH:MM »."
      continue
    fi
    if ! valid_date "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" ||
      [ $((10#${BASH_REMATCH[4]})) -gt 23 ] || [ $((10#${BASH_REMATCH[5]})) -gt 59 ]; then
      refuse "$file : titre « $line », date ou heure invalide."
      continue
    fi
    stamp=${line#\#\# }
    if [[ ${stamp%% *} < $name_date ]]; then
      refuse "$file : entrée « $line » antérieure à la date du nom du fichier ($name_date)."
    fi
    if [ -n "$previous" ] && [[ $stamp < $previous ]]; then
      refuse "$file : entrée « $line » antérieure à l'entrée précédente ($previous), ordre chronologique attendu."
    fi
    previous=$stamp
  done < <(grep '^## ' <<<"$content")
}

while IFS=$'\t' read -r status path; do
  [ -n "$status" ] || continue
  if [ "$path" = docs/journal.md ]; then
    # La migration supprime l'ancien journal ; il ne doit pas revenir
    [ "$status" = D ] || refuse "$path : l'ancien journal unique ne doit plus être modifié ; écrire dans docs/journal/."
    continue
  fi
  name=${path#docs/journal/}
  if [ "$status" != A ]; then
    refuse "$path : fichier de journal déjà mergé, modifié ou supprimé. Chaque branche écrit dans son propre fichier."
    continue
  fi
  [ "$name" = .gitkeep ] && continue
  if ! [[ $name =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})-[a-z0-9]+(-[a-z0-9]+)*\.md$ ]]; then
    refuse "$path : nom invalide, format attendu docs/journal/AAAA-MM-JJ-<branche>.md (minuscules, chiffres et tirets)."
    continue
  fi
  if ! valid_date "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"; then
    refuse "$path : date du nom invalide."
    continue
  fi
  # L'ancien journal migré garde ses titres d'origine
  case $name in *-historique.md) continue ;; esac
  check_entries "$path" "${name:0:10}"
done <<<"$changes"

if [ "$fail" -eq 0 ]; then
  echo "Journal conforme."
fi
exit "$fail"
