#!/usr/bin/env bash
# Vérifie docker-compose.yml et .env.example selon la spec docs/specs/001-socle.md (CA2, CA12, CA14).
# Lit la configuration résolue par Docker Compose, sans démarrer de conteneur.
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
compose_file="$root/docker-compose.yml"
env_example="$root/.env.example"
fail=0

ok() { echo "OK     $1"; }
ko() { echo "ÉCHEC  $1"; fail=1; }

for cmd in docker jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ÉCHEC  $cmd introuvable"
    exit 1
  fi
done

# config_json [VAR=valeur…] : configuration résolue, au format JSON.
# --env-file /dev/null : ignore un éventuel fichier d'environnement local, pour
# tester les valeurs par défaut.
config_json() {
  env -u API_PORT -u POSTGRES_PORT "$@" \
    docker compose --env-file /dev/null -f "$compose_file" config --format json 2>&1
}

# check <description> <filtre jq> : le filtre doit valoir true sur $config.
check() {
  local description=$1 filter=$2
  if jq -e "$filter" >/dev/null 2>&1 <<<"$config"; then
    ok "$description"
  else
    ko "$description"
  fi
}

# published_port <service> <port cible> : port publié sur la machine.
published_port() {
  jq -r --arg s "$1" --argjson t "$2" \
    '[.services[$s].ports[]? | select(.target == $t) | .published | tostring] | first // "aucun"' \
    <<<"$config"
}

# check_port <description> <service> <cible> <publié attendu>
check_port() {
  local description=$1 service=$2 target=$3 expected=$4 actual
  actual=$(published_port "$service" "$target")
  if [ "$actual" = "$expected" ]; then
    ok "$description"
  else
    ko "$description (attendu $expected, obtenu $actual)"
  fi
}

if [ ! -f "$compose_file" ]; then
  echo "ÉCHEC  docker-compose.yml absent ($compose_file)"
  exit 1
fi

# --- Valeurs par défaut (sans API_PORT ni POSTGRES_PORT) ---------------------

if ! config=$(config_json); then
  echo "ÉCHEC  docker compose config : $config"
  exit 1
fi

check "CA2 : image postgres:17" \
  '.services.postgres.image == "postgres:17"'
check "CA2 : healthcheck de postgres basé sur pg_isready" \
  '.services.postgres.healthcheck.test | tostring | contains("pg_isready")'
check "CA2 : api dépend de postgres avec condition service_healthy" \
  '.services.api.depends_on.postgres.condition == "service_healthy"'

check "CA12 : POSTGRES_USER de postgres = défaut de l'API (fieldops)" \
  '.services.postgres.environment.POSTGRES_USER == "fieldops"'
check "CA12 : POSTGRES_PASSWORD de postgres = défaut de l'API (fieldops)" \
  '.services.postgres.environment.POSTGRES_PASSWORD == "fieldops"'
check "CA12 : POSTGRES_DB de postgres = défaut de l'API (fieldops)" \
  '.services.postgres.environment.POSTGRES_DB == "fieldops"'

check_port "CA14 : sans API_PORT, api publiée sur 3000" api 3000 3000
check_port "CA14 : sans POSTGRES_PORT, postgres publié sur 5432" postgres 5432 5432

# --- Ports surchargés --------------------------------------------------------

if ! config=$(config_json API_PORT=3101 POSTGRES_PORT=5501); then
  echo "ÉCHEC  docker compose config (ports surchargés) : $config"
  exit 1
fi

check_port "CA14 : API_PORT=3101, api publiée sur 3101" api 3000 3101
check_port "CA14 : POSTGRES_PORT=5501, postgres publié sur 5501" postgres 5432 5501

# --- .env.example documente toutes les variables -----------------------------

if [ -f "$env_example" ]; then
  for var in PORT DATABASE_HOST DATABASE_PORT DATABASE_USER DATABASE_PASSWORD \
    DATABASE_NAME API_PORT POSTGRES_PORT; do
    # Ligne VAR=…, éventuellement commentée.
    if grep -Eq "^[#[:space:]]*${var}=" "$env_example"; then
      ok "CA12 : .env.example documente $var"
    else
      ko "CA12 : .env.example ne documente pas $var"
    fi
  done
else
  ko "CA12 : .env.example absent ($env_example)"
fi

exit $fail
