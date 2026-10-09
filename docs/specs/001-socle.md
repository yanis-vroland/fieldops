# Spec 001 : socle de la plateforme

Statut : brouillon
Date : 2026-10-09

Phase 0 de [`docs/vision.md`](../vision.md#ordre-de-construction). Dépend de l'[ADR-001](../adr/001-choix-de-la-stack.md) (stack) et de l'[ADR-002](../adr/002-choix-orm.md) (TypeORM).

## Besoin

En tant que développeur de FieldOps (humain ou agent), je veux un monorepo pnpm avec une API NestJS vide, documentée en OpenAPI et reliée à PostgreSQL, que l'on lance d'une seule commande, afin de construire les briques suivantes sur un socle vérifié par la CI.

## Critères d'acceptation

Lancement

- CA1 : Étant donné un clone neuf du dépôt, sans fichier `.env`, avec Docker installé, quand on lance `docker compose up`, alors PostgreSQL 17 et l'API démarrent, et l'API répond sur `http://localhost:3000`.
- CA2 : Étant donné la plateforme lancée par `docker compose up`, quand PostgreSQL n'est pas encore prêt au démarrage, alors l'API attend qu'il le soit avant de démarrer (pas d'arrêt en erreur).
- CA3 : Étant donné un clone neuf avec Node 24 et pnpm installés, quand on lance `pnpm install` à la racine, alors les dépendances de toutes les briques du workspace sont installées, sans erreur.

Contrôle de santé

- CA4 : Étant donné l'API et PostgreSQL démarrés, quand on appelle `GET /health`, alors l'API répond 200 avec un corps JSON indiquant que l'API et la base de données sont opérationnelles.
- CA5 : Étant donné l'API démarrée et PostgreSQL injoignable, quand on appelle `GET /health`, alors l'API répond 503 avec un corps JSON indiquant que la base de données est indisponible, et l'API continue de répondre aux appels suivants.

Contrat OpenAPI

- CA6 : Étant donné l'API démarrée, quand on ouvre `/docs`, alors Swagger UI affiche le contrat de l'API, qui contient `GET /health`.
- CA7 : Étant donné le dépôt, quand on lance `pnpm --filter api openapi:generate`, alors le fichier `apps/api/openapi.json` est régénéré à partir du code, sans démarrer de base de données.
- CA8 : Étant donné une modification du code qui change le contrat sans régénérer `apps/api/openapi.json`, quand la CI s'exécute, alors elle échoue en signalant que le contrat versionné n'est pas à jour.

Qualité

- CA9 : Étant donné le dépôt, quand on lance `pnpm --filter api lint`, `pnpm --filter api test` et `pnpm --filter api test:e2e`, alors les trois commandes réussissent. Les tests e2e couvrent CA4 et CA5.
- CA10 : Étant donné une PR, quand la CI s'exécute, alors elle lance le lint, les tests unitaires et e2e de l'API, la vérification de CA8, puis `docker compose up` et un appel à `GET /health` qui doit répondre 200. Un échec de l'une de ces étapes fait échouer la CI.

Configuration

- CA11 : Étant donné l'API, quand elle démarre, alors elle lit la connexion à PostgreSQL dans des variables d'environnement, avec des valeurs par défaut fictives qui correspondent au `docker-compose.yml`. `.env.example` documente ces variables.
- CA12 : Étant donné l'API, quand elle se connecte à PostgreSQL, alors TypeORM n'a pas `synchronize` activé (ADR-002).

## Cas limites et erreurs

- PostgreSQL arrêté pendant que l'API tourne : `GET /health` passe à 503, puis revient à 200 quand PostgreSQL redémarre, sans redémarrer l'API.
- Port 3000 ou 5432 déjà pris sur la machine : `docker compose up` échoue avec le message de Docker ; les ports sont configurables par variable d'environnement.
- Route inconnue : 404 au format JSON par défaut de NestJS.
- Variables d'environnement absentes : l'API utilise les valeurs par défaut (CA11) ; une valeur invalide (port non numérique) arrête l'API au démarrage avec un message explicite.

## Hors périmètre

- Entités métier, migrations, données de démonstration : phase 1.
- Authentification et autorisation.
- Briques `apps/mobile`, `services/rag`, `services/mcp`, `services/agents`.
- Déploiement (Kubernetes, hébergement) et images Docker de production.
- Langfuse et tout appel à un modèle d'IA.

## Questions ouvertes

- Image PostgreSQL : `postgres:17` maintenant, ou directement `pgvector/pgvector:pg17` pour préparer le RAG (phase 3) sans changer d'image plus tard ?
- Format exact du corps de `GET /health` : celui de `@nestjs/terminus` (`{ status, info, error, details }`), ou un format maison plus court ?
- Outils de test : Jest et Supertest (choix par défaut de NestJS) conviennent-ils, ou faut-il un autre outil (Vitest) ?
- La CI de l'API est-elle un nouveau workflow (`api.yml`), ou un job ajouté à `garde-fous.yml` ? Et ses jobs deviennent-ils des vérifications obligatoires du ruleset sur `main` ?
