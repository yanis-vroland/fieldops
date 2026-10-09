#!/usr/bin/env bash
# Vérifie que le hook pre-commit bloque un secret indexé et laisse passer le reste.
set -u

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "ÉCHEC  gitleaks n'est pas installé : test impossible"
  exit 1
fi

hooks_dir="$(cd "$(dirname "$0")/../.githooks" && pwd)"
fail=0

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

repo="$work/repo"
git init -q "$repo"

# Sortie du dernier commit, pour vérifier la raison d'un refus
output=""
commit() {
  output=$(git -C "$repo" -c core.hooksPath="$hooks_dir" \
    -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false \
    commit -q -m "test" 2>&1)
}

check() {
  local expected=$1 description=$2 code=$3
  if [ "$code" -eq "$expected" ]; then
    echo "OK     $description"
  else
    echo "ÉCHEC  $description (attendu $expected, obtenu $code)"
    fail=1
  fi
}

# Vérifie que le refus vient bien de la détection d'un secret
check_detected() {
  local description=$1
  if grep -q "secret potentiel détecté" <<<"$output"; then
    echo "OK     $description : secret détecté"
  else
    echo "ÉCHEC  $description : refus sans détection (sortie : $output)"
    fail=1
  fi
}

# Faux jeton GitHub assemblé à l'exécution : il ne doit jamais apparaître
# en clair dans ce fichier, sinon le job gitleaks de la CI le détecterait.
fake_token="ghp""_""R7xK2mQ9vL4tW8nB3c""Y6pZ1sD5fH0jG7aE2u"

echo "Bonjour" >"$repo/README.md"
git -C "$repo" add README.md
commit
check 0 "Commit sans secret : accepté" $?

printf 'github = "%s"\n' "$fake_token" >"$repo/config.txt"
git -C "$repo" add config.txt
commit
check 1 "Nouveau fichier avec un secret : refusé" $?
check_detected "Nouveau fichier avec un secret"
git -C "$repo" rm -q --cached config.txt
rm "$repo/config.txt"

printf 'github = "%s"\n' "$fake_token" >>"$repo/README.md"
git -C "$repo" add README.md
commit
check 1 "Secret ajouté à un fichier suivi : refusé" $?
check_detected "Secret ajouté à un fichier suivi"
git -C "$repo" checkout -q HEAD -- README.md

# Sans gitleaks dans le PATH, le hook doit refuser avec un message explicite
fake_bin="$work/bin"
mkdir "$fake_bin"
for cmd in bash git; do
  ln -s "$(command -v "$cmd")" "$fake_bin/$cmd"
done
echo "Encore" >>"$repo/README.md"
git -C "$repo" add README.md
output=$(cd "$repo" && PATH="$fake_bin" "$hooks_dir/pre-commit" 2>&1)
check 1 "Sans gitleaks : refusé" $?
if grep -q "gitleaks n'est pas installé" <<<"$output"; then
  echo "OK     Sans gitleaks : message explicite"
else
  echo "ÉCHEC  Sans gitleaks : message absent (sortie : $output)"
  fail=1
fi

exit $fail
