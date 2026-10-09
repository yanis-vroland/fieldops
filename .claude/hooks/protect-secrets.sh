#!/usr/bin/env bash
# Bloque l'accès de l'agent aux fichiers .env (sauf .env.example).
# Spec : https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/specs/002-hook-protect-secrets.md
# Exit 2 = action refusée, le message sur stderr est renvoyé à l'agent.
# Claude Code ne bloque qu'avec le code 2 : toute autre sortie laisserait passer l'action.
set -euo pipefail

# Fermeture en cas de panne : toute sortie autre que 0 ou 2 devient un refus
# Appelée par le trap, que shellcheck ne suit pas (SC2317 avant 0.11, SC2329 ensuite)
# shellcheck disable=SC2317,SC2329
fail_closed() {
  local code=$?
  if [ "$code" -ne 0 ] && [ "$code" -ne 2 ]; then
    echo "protect-secrets : erreur interne (code $code), action refusée par précaution." >&2
    exit 2
  fi
}
trap fail_closed EXIT

deny() {
  echo "protect-secrets : $1" >&2
  exit 2
}

# --- Définitions de la spec ----------------------------------------------------
# Regex de bash plutôt que grep : une commande externe manquante dans un « if »
# ne déclencherait ni set -e ni le trap, et laisserait passer l'action.

# Mention : .env cité dans un texte, .env.example retiré au préalable
mention_re='(^|[^[:alnum:]_])\.env([^[:alnum:]_-]|$)'

has_mention() {
  local text=${1//.env.example/}
  [[ $text =~ $mention_re ]]
}

# Chemin protégé : dernier segment égal à .env ou commençant par .env., sauf .env.example
is_protected_path() {
  local base=${1##*/}
  if [ "$base" = ".env.example" ]; then
    return 1
  fi
  [[ $base == ".env" || $base == .env.?* ]]
}

# --- Découpage d'une commande Bash en mots -------------------------------------
# words[i] : le mot, sans guillemets ; word_op[i] = 1 pour un opérateur (; | & < > ( )) ;
# word_glob[i] = 1 si le mot contient un caractère de motif hors guillemets.

words=()
word_op=()
word_glob=()
cur=""
cur_started=0
cur_glob=0

end_word() {
  if [ "$cur_started" -eq 1 ]; then
    words+=("$cur")
    word_op+=(0)
    word_glob+=("$cur_glob")
  fi
  cur=""
  cur_started=0
  cur_glob=0
}

add_op() {
  end_word
  words+=("$1")
  word_op+=(1)
  word_glob+=(0)
}

# Retourne 1 si la commande n'est pas analysable de façon fiable : guillemet non
# fermé, heredoc, substitution de commande ou de processus.
tokenize() {
  local s=$1 n=${#1} i=0 c next state=none
  while [ "$i" -lt "$n" ]; do
    c=${s:i:1}
    next=${s:i+1:1}
    case $state in
      single)
        if [ "$c" = "'" ]; then
          state=none
        else
          cur+=$c
        fi
        ;;
      double)
        case $c in
          '"') state=none ;;
          '`') return 1 ;;
          '$')
            if [ "$next" = "(" ]; then
              return 1
            fi
            cur+=$c
            ;;
          \\)
            i=$((i + 1))
            if [ "$i" -ge "$n" ]; then
              return 1
            fi
            cur+=${s:i:1}
            ;;
          *) cur+=$c ;;
        esac
        ;;
      none)
        case $c in
          "'")
            state=single
            cur_started=1
            ;;
          '"')
            state=double
            cur_started=1
            ;;
          '`') return 1 ;;
          '$')
            if [ "$next" = "(" ]; then
              return 1
            fi
            cur+=$c
            cur_started=1
            ;;
          \\)
            i=$((i + 1))
            if [ "$i" -ge "$n" ]; then
              return 1
            fi
            cur+=${s:i:1}
            cur_started=1
            ;;
          ' ' | $'\t') end_word ;;
          $'\n' | ';') add_op ";" ;;
          '&' | '|')
            if [ "$next" = "$c" ]; then
              add_op "$c$c"
              i=$((i + 1))
            else
              add_op "$c"
            fi
            ;;
          '<' | '>')
            if [ "$next" = "(" ]; then
              return 1
            fi
            # << : heredoc ou here-string
            if [ "$c" = "<" ] && [ "$next" = "<" ]; then
              return 1
            fi
            if [ "$c" = ">" ] && [ "$next" = ">" ]; then
              add_op ">>"
              i=$((i + 1))
            else
              add_op "$c"
            fi
            ;;
          '(' | ')') add_op "$c" ;;
          '*' | '?' | '[')
            cur+=$c
            cur_started=1
            cur_glob=1
            ;;
          *)
            cur+=$c
            cur_started=1
            ;;
        esac
        ;;
    esac
    i=$((i + 1))
  done
  if [ "$state" != none ]; then
    return 1
  fi
  end_word
}

# Le mot words[i] est-il la valeur d'une option de texte reconnue de la commande
# qui commence à words[start] ?
is_text_option_value() {
  local start=$1 i=$2 opts option
  local cmd=${words[start]} sub=${words[start + 1]:-} action=${words[start + 2]:-}
  if [ "$cmd" = git ] && { [ "$sub" = commit ] || [ "$sub" = tag ]; }; then
    opts="-m --message"
  elif [ "$cmd" = gh ] && { [ "$sub" = pr ] || [ "$sub" = issue ]; } &&
    { [ "$action" = create ] || [ "$action" = comment ] || [ "$action" = edit ]; }; then
    opts="-b --body -t --title"
  else
    return 1
  fi
  for option in $opts; do
    if [[ ${words[i]} == "$option="* ]]; then
      return 0
    fi
    if [ "$i" -gt "$start" ] && [ "${word_op[i - 1]}" -eq 0 ] && [ "${words[i - 1]}" = "$option" ]; then
      return 0
    fi
  done
  return 1
}

check_bash() {
  local command=$1 i start=0 word value
  if ! has_mention "$command"; then
    return 0
  fi
  if ! tokenize "$command"; then
    deny "commande non analysable (heredoc, substitution, guillemet non fermé…) qui cite un fichier .env : refusée par précaution."
  fi
  for i in "${!words[@]}"; do
    word=${words[i]}
    if [ "${word_op[i]}" -eq 1 ]; then
      start=$((i + 1))
      continue
    fi
    # Valeur d'une option de texte : un message, jamais lu comme un fichier
    if is_text_option_value "$start" "$i"; then
      continue
    fi
    value=$word
    if [[ $word == --*=* ]]; then
      value=${word#*=}
    fi
    if is_protected_path "$word" || is_protected_path "$value"; then
      deny "accès à un fichier .env interdit ($word). Utilise .env.example."
    fi
    if ! has_mention "$word"; then
      continue
    fi
    if [ "${word_glob[i]}" -eq 1 ]; then
      deny "motif qui peut désigner un fichier .env ($word) : refusé."
    fi
    deny "texte citant un fichier .env hors d'un message de commit ou de PR : refusé, car il peut être exécuté. Passe par un fichier (git commit -F, gh … --body-file)."
  done
}

# --- Entrée ----------------------------------------------------------------------

command -v jq >/dev/null 2>&1 ||
  deny "jq n'est pas installé, action refusée. Installe jq pour rétablir les hooks de Claude Code."

input=$(cat)
[ -n "$input" ] || deny "entrée vide, action refusée."
jq -e 'type == "object"' >/dev/null 2>&1 <<<"$input" || deny "entrée JSON invalide, action refusée."

jq -e '.tool_name | type == "string" and length > 0' >/dev/null <<<"$input" ||
  deny "tool_name absent ou invalide, action refusée."
tool=$(jq -r '.tool_name' <<<"$input")
jq -e '.tool_input | type == "object"' >/dev/null <<<"$input" || deny "tool_input absent, action refusée."

case "$tool" in
  Bash)
    target=$(jq -r '.tool_input.command // empty' <<<"$input")
    [ -n "$target" ] || deny "commande Bash absente, action refusée."
    check_bash "$target"
    ;;
  Read | Edit | Write | MultiEdit)
    target=$(jq -r '.tool_input.file_path // empty' <<<"$input")
    [ -n "$target" ] || deny "chemin absent pour $tool, action refusée."
    if is_protected_path "$target"; then
      deny "accès aux fichiers .env interdit ($target). Utilise .env.example."
    fi
    ;;
esac

exit 0
