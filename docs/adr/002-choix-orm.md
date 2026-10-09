# ADR-002 : Choix de l'ORM

Statut : accepté
Date : 2026-10-09

Contexte : l'[ADR-001](001-choix-de-la-stack.md) fixe NestJS et PostgreSQL 17 pour le serveur, et laisse l'ORM ouvert. Il faut le choisir avant le socle (phase 0), où l'API se connecte déjà à PostgreSQL pour son contrôle de santé, et avant la phase 1, qui introduit le modèle métier (`Site`, `Machine`, `Intervention`, `Part`, `StockItem`, `PartReservation`, `Technician`). Contraintes :
- Le code est écrit en grande partie par un agent : les conventions doivent être documentées et prévisibles.
- Le RAG (phase 3) stockera ses embeddings dans PostgreSQL avec pgvector. C'est une brique séparée, qui pourra faire son propre choix, mais un ORM commun aux briques serveur simplifie les consignes de l'agent.
- Le projet est mené par une seule personne : le moins d'outillage spécifique possible.

Options envisagées :
- Prisma : schéma déclaratif dans un fichier `.prisma`, client typé généré, migrations intégrées. Typage des requêtes très fort. En revanche, ce n'est pas une intégration officielle de NestJS (pas de module `@nestjs/prisma`), il ajoute une étape de génération de code, et les types non pris en charge par son schéma (comme `vector` de pgvector) passent par du SQL brut.
- TypeORM : intégration officielle de NestJS (`@nestjs/typeorm`), entités déclarées par décorateurs, dans le style du reste de NestJS (modules, injection de dépendances, repositories). Migrations générées à partir des entités. En revanche, le typage des requêtes complexes (QueryBuilder) est plus faible, et certains comportements par défaut sont risqués (`synchronize`).
- Driver SQL seul (`pg`) ou query builder (Kysely, Knex) : contrôle total du SQL, mais tout le mapping, les relations et les migrations restent à écrire.

Décision : TypeORM, avec `@nestjs/typeorm`, pour les briques serveur NestJS.
- `synchronize` est désactivé dans tous les environnements : le schéma n'évolue que par des migrations versionnées.
- Les migrations sont générées à partir des entités, relues, et committées avec le code qui les utilise.
- Les entités portent les noms du glossaire du [cahier des charges](../cahier-des-charges-fonctionnel.md#glossaire) (lien mis à jour : le glossaire était dans la vision à la date de cet ADR).

Conséquences :
- Les entités et les modules suivent les conventions de la documentation officielle de NestJS, que l'agent connaît bien.
- Le typage des requêtes complexes est moins strict qu'avec Prisma : les requêtes non triviales doivent être couvertes par des tests sur une vraie base PostgreSQL, pas par des mocks. C'est déjà le cas des tests e2e du socle ([spec 001](../specs/001-socle.md)).
- Avec `synchronize` désactivé, chaque évolution du modèle exige une migration : plus de fichiers par PR, mais un schéma maîtrisé.
- Le support de pgvector par TypeORM est limité : le RAG (phase 3) pourra avoir besoin de SQL brut pour les colonnes et les requêtes vectorielles. La spec du RAG devra trancher : TypeORM avec SQL brut pour la partie vectorielle, ou autre choix pour cette brique, par un nouvel ADR.
