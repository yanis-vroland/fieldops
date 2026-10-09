# Spec 001 : socle de la plateforme

Statut : validée
Date : 2026-10-09

Phase 0 de [`docs/vision.md`](../vision.md#ordre-de-construction). Dépend de l'[ADR-001](../adr/001-choix-de-la-stack.md) (stack) et de l'[ADR-002](../adr/002-choix-orm.md) (TypeORM).

## Besoin

En tant que développeur de FieldOps (humain ou agent), je veux un monorepo pnpm avec une API NestJS vide, documentée en OpenAPI et reliée à PostgreSQL, que l'on lance d'une seule commande, afin de construire les briques suivantes sur un socle vérifié par la CI.

## Choix retenus

- PostgreSQL : image Docker officielle `postgres:17`. Le passage à une image avec pgvector se fera en phase 3, par une spec du RAG.
- Contrôle de santé : `@nestjs/terminus`, avec son format de réponse (`status`, `info`, `error`, `details`) ; l'indicateur de la base s'appelle `database`.
- Tests : Vitest et Supertest, outils par défaut de NestJS 12 (avec oxlint pour le lint). Les tests e2e utilisent un vrai PostgreSQL 17 (ADR-002), jamais un mock.
- CI de l'API : nouveau workflow `.github/workflows/api.yml`. Ses jobs deviennent des vérifications obligatoires du ruleset sur `main`.
- `.env.example` à la racine du dépôt : il documente les variables de l'API et les ports publiés par docker compose.
- Attente de PostgreSQL au démarrage : `healthcheck` sur le service PostgreSQL (`pg_isready`) et `depends_on` avec `condition: service_healthy` sur l'API.

## Critères d'acceptation

Lancement

- CA1 : Étant donné un clone neuf du dépôt, sans fichier `.env`, avec Docker installé, quand on lance `docker compose up`, alors PostgreSQL 17 et l'API démarrent, et `GET http://localhost:3000/health` répond 200.
- CA2 : Étant donné `docker-compose.yml`, quand on lit la définition des services, alors PostgreSQL a un `healthcheck` basé sur `pg_isready`, et l'API dépend de PostgreSQL avec `condition: service_healthy`.
- CA3 : Étant donné un clone neuf avec Node 24 et pnpm installés, quand on lance `pnpm install` à la racine, alors les dépendances de toutes les briques du workspace sont installées, sans erreur.

Contrôle de santé

- CA4 : Étant donné l'API et PostgreSQL démarrés, quand on appelle `GET /health`, alors l'API répond 200 avec `status` à `ok` et l'indicateur `database` à `up`.
- CA5 : Étant donné l'API démarrée et PostgreSQL injoignable, quand on appelle `GET /health`, alors l'API répond 503 avec `status` à `error` et l'indicateur `database` à `down`, et l'API répond encore aux appels suivants.
- CA6 : Étant donné l'API qui répond 503 parce que PostgreSQL est injoignable, quand PostgreSQL redevient joignable, alors `GET /health` répond de nouveau 200, sans redémarrer l'API.

Contrat OpenAPI

- CA7 : Étant donné l'API démarrée, quand on ouvre `/docs`, alors Swagger UI s'affiche, et `/docs-json` renvoie un contrat OpenAPI qui contient `GET /health`.
- CA8 : Étant donné le dépôt, quand on lance `pnpm --filter api openapi:generate`, alors le fichier `apps/api/openapi.json` est régénéré à partir du code, sans démarrer de base de données, et contient `GET /health`.
- CA9 : Étant donné une modification du code qui change le contrat sans régénérer `apps/api/openapi.json`, quand la CI s'exécute, alors elle échoue : elle régénère le fichier et compare avec la version committée (`git diff --exit-code apps/api/openapi.json`).

Qualité et CI

- CA10 : Étant donné le dépôt, quand on lance `pnpm --filter api lint`, `pnpm --filter api test` et `pnpm --filter api test:e2e` (avec un PostgreSQL 17 joignable pour les tests e2e), alors les trois commandes réussissent.
- CA11 : Étant donné une PR, quand la CI s'exécute, alors elle lance le lint, les tests unitaires et e2e de l'API, la vérification du CA9, puis `docker compose up` et un appel à `GET /health` qui doit répondre 200. Un échec de l'une de ces étapes fait échouer la CI.

Configuration

- CA12 : Étant donné l'API, quand elle démarre sans variable d'environnement, alors elle utilise des valeurs par défaut fictives qui correspondent au `docker-compose.yml`. `.env.example` documente toutes les variables.
- CA13 : Étant donné une variable d'environnement invalide (un port non numérique, ou hors de la plage 1 à 65535), quand l'API démarre, alors elle s'arrête avec un code de sortie non nul et un message qui nomme la variable en cause. Une variable vide est traitée comme absente : la valeur par défaut s'applique.
- CA14 : Étant donné les variables `API_PORT` et `POSTGRES_PORT`, quand on lance `docker compose up` avec d'autres valeurs, alors l'API et PostgreSQL sont exposés sur ces ports de la machine.
- CA15 : Étant donné la configuration TypeORM de l'API, quand un test unitaire la lit, alors `synchronize` vaut `false` (ADR-002).

Erreurs

- CA16 : Étant donné l'API démarrée, quand on appelle une route inconnue, alors elle répond 404 avec un corps JSON.

## Cas limites et erreurs

- Port de la machine déjà pris : `docker compose up` échoue avec le message de Docker ; le contournement est le CA14.
- PostgreSQL arrêté pendant que l'API tourne : couvert par les CA5 et CA6.

## Hors périmètre

- Entités métier, migrations, données de démonstration : phase 1.
- Authentification et autorisation.
- Briques `apps/mobile`, `services/rag`, `services/mcp`, `services/agents`.
- Image PostgreSQL avec pgvector : phase 3.
- Déploiement (Kubernetes, hébergement) et images Docker optimisées pour la production.
- Langfuse et tout appel à un modèle d'IA.

## Questions ouvertes

Aucune.
