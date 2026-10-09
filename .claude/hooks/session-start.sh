#!/usr/bin/env bash
# Début de session Claude Code : met le dépôt à jour sans risque et affiche l'état
# utile pour reprendre le travail. La sortie est ajoutée au contexte de l'agent.
# Spec : docs/specs/004-reprise-de-session.md
# Ne bloque jamais la session : se termine toujours avec le code 0.
set -u

# Délai maximal de la récupération, en secondes
fetch_timeout=15

# Lance une commande avec un délai maximal (pas de « timeout » sous macOS)
run_with_timeout() {
  local limit=$1 pid elapsed=0
  shift
  "$@" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$elapsed" -ge "$((limit * 10))" ]; then
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      return 124
    fi
    sleep 0.1
    elapsed=$((elapsed + 1))
  done
  wait "$pid"
}

# Dernière entrée (titre de niveau 2 et suite) d'un fichier de journal
last_entry() {
  awk '/^## / { entry = "" } { entry = entry $0 "\n" } END { printf "%s", entry }' "$1"
}

main() {
  cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  cd "$(git rev-parse --show-toplevel)" || return 0

  echo "# État du dépôt au début de la session (hook session-start.sh)"
  echo

  # --- Récupération ----------------------------------------------------------

  if git remote get-url origin >/dev/null 2>&1; then
    if run_with_timeout "$fetch_timeout" env GIT_TERMINAL_PROMPT=0 \
      git fetch --quiet --prune origin >/dev/null 2>&1; then
      echo "- Récupération de origin : faite."
    else
      echo "- Récupération impossible depuis origin (hors ligne, délai dépassé ou accès refusé) : état local seulement."
    fi
  else
    echo "- Pas de remote origin : récupération sautée."
  fi

  # --- Branche et mise à jour ------------------------------------------------

  local branch upstream counts ahead behind
  if ! branch=$(git symbolic-ref --quiet --short HEAD); then
    echo "- HEAD détaché sur $(git rev-parse --short HEAD 2>/dev/null) : aucune mise à jour."
    branch=""
  else
    echo "- Branche : $branch"
    if upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
      counts=$(git rev-list --left-right --count "HEAD...@{u}" 2>/dev/null || echo "0 0")
      ahead=${counts%%[[:space:]]*}
      behind=${counts##*[[:space:]]}
      if [ "$behind" -eq 0 ]; then
        echo "- À jour avec $upstream (en avance de $ahead commit(s))."
      elif [ "$ahead" -gt 0 ]; then
        echo "- La branche a divergé de $upstream ($ahead commit(s) locaux, $behind distants) : aucune mise à jour. Proposer un rebase, sans le faire."
      elif [ -n "$(git status --porcelain --untracked-files=no)" ]; then
        echo "- En retard de $behind commit(s) sur $upstream, mais modifications non committées : aucune mise à jour."
      elif git merge --ff-only --quiet "$upstream" >/dev/null 2>&1; then
        echo "- Branche avancée de $behind commit(s) jusqu'à $upstream."
      else
        echo "- En retard de $behind commit(s) sur $upstream, avance rapide impossible : aucune mise à jour."
      fi
    else
      echo "- Pas de branche distante de suivi : aucune mise à jour."
    fi
  fi

  if [ "$branch" != main ] && git rev-parse --verify --quiet origin/main >/dev/null; then
    behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
    if [ "$behind" -gt 0 ]; then
      echo "- En retard de $behind commit(s) sur origin/main : proposer un rebase, sans le faire."
    fi
  fi

  # --- Journal ---------------------------------------------------------------

  echo
  local slug file
  if [ -n "$branch" ] && [ "$branch" != main ]; then
    slug=${branch//\//-}
    file=$(find docs/journal -maxdepth 1 -type f -name "????-??-??-$slug.md" 2>/dev/null |
      LC_ALL=C sort | tail -n 1)
    if [ -z "$file" ]; then
      echo "Pas de journal pour cette branche : le créer au premier commit, docs/journal/$(date +%Y-%m-%d)-$slug.md."
    fi
  else
    # Sur main : le fichier de journal du dernier commit qui en a ajouté ou modifié un
    file=$(git log -1 --format= --name-only --diff-filter=AM -- 'docs/journal/*.md' 2>/dev/null |
      grep -v '^$' | tail -n 1)
    [ -n "$file" ] || echo "Aucun journal dans docs/journal/."
  fi
  if [ -n "$file" ] && [ -f "$file" ]; then
    echo "Dernière entrée de $file :"
    echo
    last_entry "$file"
  fi

  # --- PR ouvertes -------------------------------------------------------------

  echo
  local prs
  if command -v gh >/dev/null 2>&1 &&
    prs=$(run_with_timeout 10 gh pr list --state open --limit 10 2>/dev/null); then
    if [ -n "$prs" ]; then
      echo "PR ouvertes :"
      echo "$prs"
    else
      echo "Aucune PR ouverte."
    fi
  else
    echo "PR ouvertes : non disponibles (gh absent, non authentifié ou dépôt hors GitHub)."
  fi
}

main 2>/dev/null
exit 0
