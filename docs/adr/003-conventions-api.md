# ADR-003 : Conventions de l'API

Statut : accepté
Date : 2026-10-09

Contexte : la phase 1 ajoute à `apps/api` une dizaine de ressources (sites, machines, utilisateurs, pièces, stock, interventions, réservations, audit). Sans conventions communes, chaque spec et chaque PR réinventerait le format des erreurs, la pagination ou les identifiants. Le contrat OpenAPI est consommé par l'app mobile (phase 2) et le serveur MCP (phase 4) : il doit être régulier et stable. Le code est écrit en grande partie par un agent : des règles explicites évitent les écarts d'une ressource à l'autre.

Options envisagées :
- Format des erreurs :
  - format par défaut de NestJS (`statusCode`, `message`, `error`) : rien à faire, mais non standard, et `message` change de type (chaîne ou tableau) selon l'erreur ;
  - RFC 9457 (`application/problem+json`) : standard, extensible (détail par champ), compris par les clients HTTP génériques.
- Pagination :
  - par décalage (`limit`, `offset`) : simple, total disponible, adapté à des volumes de démonstration ;
  - par curseur : robuste aux insertions concurrentes, mais plus complexe pour le mobile et sans total.
- Identifiants : UUID, ou entiers auto-incrémentés. Les entiers exposent le volume et l'ordre de création ; les UUID se génèrent côté client si besoin (mode hors ligne du mobile).
- Suppression : physique, ou archivage. La suppression physique casse l'historique (une intervention terminée qui référence une machine supprimée).

Décision :
- Routes : préfixe `/v1`, ressources au pluriel en kebab-case (`/v1/stock-items`), identifiant en paramètre de chemin (`/v1/machines/{id}`). `/health`, `/docs` et `/docs-json` restent hors version.
- Identifiants techniques : UUID v4, générés par PostgreSQL. Les références lisibles (code de site, code de machine, référence de pièce) sont des champs distincts, uniques, et ne servent pas d'identifiant dans les routes.
- Corps JSON en camelCase ; dates en ISO 8601 UTC (`2026-10-09T13:00:00Z`) ; énumérations en snake_case minuscule (`in_progress`).
- Erreurs : RFC 9457, `Content-Type: application/problem+json`, champs `type`, `title`, `status`, `detail`. Erreur de validation : 400 avec un champ `errors` qui liste `{ field, message }`. Codes : 400 validation, 401 non identifié, 403 interdit, 404 introuvable, 409 conflit (unicité, transition interdite, stock insuffisant), 500 interne sans détail technique.
- Validation des entrées : DTO avec `class-validator` et `class-transformer`, `ValidationPipe` global en mode liste blanche (`whitelist`, `forbidNonWhitelisted`) : un champ inconnu est une erreur 400.
- Pagination des listes : `limit` (défaut 20, maximum 100) et `offset` (défaut 0). Réponse : `{ items, total, limit, offset }`. Tri par défaut documenté pour chaque ressource.
- Suppression : pas de `DELETE` sur les données métier. Les ressources archivables ont un champ `archivedAt` ; les listes excluent les éléments archivés sauf `includeArchived=true`.
- Horodatage : chaque entité a `createdAt` et `updatedAt`, gérés par la base.
- Migrations TypeORM : une migration par PR qui change le schéma, générée à partir des entités, relue, jamais modifiée une fois mergée. Les migrations s'exécutent au démarrage de l'API (`migrationsRun`).
- Contrat : chaque route, paramètre, corps et réponse (erreurs comprises) est décrit dans le contrat OpenAPI. `info.version` suit SemVer : mineure pour un ajout compatible, majeure pour une rupture (qui exige un nouvel ADR et un préfixe `/v2`).

Conséquences :
- Deux dépendances de plus (`class-validator`, `class-transformer`), recommandées par la documentation de NestJS.
- Un filtre d'exceptions global convertit toutes les erreurs au format RFC 9457 : le 404 JSON du socle (spec 001, CA16) change de forme. La spec 002 le précise.
- L'archivage complique les contraintes d'unicité (un code de machine archivé reste réservé) : chaque spec le dit pour sa ressource.
- `migrationsRun` au démarrage convient à une seule instance ; avec plusieurs instances (Kubernetes, plus tard), les migrations devront passer par une étape séparée.
