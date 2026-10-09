# Spec 009 : données fictives et publication du contrat

Statut : validée
Date : 2026-10-09

Phase 1, dernière spec. Critère de fin de la phase : « les specs de la phase sont implémentées, le contrat OpenAPI est publié » ([`docs/vision.md`](../vision.md#ordre-de-construction)).

## Besoin

En tant que personne qui découvre FieldOps (recruteur, développeur, agent), je veux une plateforme peuplée de données fictives réalistes dès `docker compose up`, afin d'explorer l'API et de rejouer les démos des phases suivantes sans saisie préalable.

En tant que développeur des briques suivantes (mobile, MCP), je veux un contrat OpenAPI versionné et stable, afin de générer mes clients et de détecter les ruptures.

## Règles métier

Contenu du jeu de données, entièrement fictif (aucun nom d'entreprise, de personne ou de lieu réel identifiable) :
- 1 entreprise fictive, 2 sites ;
- environ 15 machines réparties sur les deux sites, de tous les types, dont la presse n°3 (`PRS-003`, type `press`), machine du scénario de référence de la phase 4 ;
- 1 responsable maintenance et 5 techniciens, rattachés aux sites ;
- environ 40 pièces, avec du stock sur les deux sites, dont quelques lignes sous le seuil d'alerte ;
- une vingtaine d'interventions, dans tous les statuts et toutes les priorités, avec des réservations actives, consommées et libérées.

Les mots de passe des comptes fictifs sont documentés dans le README (ce sont des données de démonstration).

## Critères d'acceptation

Données fictives

- CA1 : Étant donné une base vide et `SEED_ON_EMPTY=true` (valeur fixée dans `docker-compose.yml`), quand l'API démarre, alors le jeu de données est chargé après les migrations et avant d'accepter des requêtes, et l'on peut se connecter avec les comptes documentés dans le README. Sans `SEED_ON_EMPTY=true`, rien n'est chargé.
- CA2 : Étant donné une base déjà peuplée, quand l'API redémarre ou que l'on relance le chargement, alors aucune donnée n'est dupliquée ni écrasée (chargement seulement si la base est vide).
- CA3 : Étant donné la commande `pnpm --filter api seed:reset`, quand on la lance avec `ALLOW_SEED_RESET=true`, alors la base est vidée et le jeu de données rechargé ; sans cette variable, quelle que soit la valeur de `NODE_ENV`, la commande refuse de s'exécuter et ne touche à rien.
- CA4 : Étant donné le jeu de données chargé, quand on appelle `GET /v1/machines/by-code/PRS-003`, alors on obtient la presse n°3, avec au moins une intervention corrective `done` dans son historique et des pièces compatibles en stock.
- CA5 : Étant donné le jeu de données chargé, quand on vérifie ses invariants, alors ils sont tous respectés : quantités réservées égales à la somme des réservations `active`, quantités physiques égales à la somme des mouvements, statuts et dates d'intervention cohérents avec les transitions de la spec 007.
- CA6 : Étant donné le jeu de données, quand on le vérifie, alors tous les e-mails sont sur le domaine réservé `fieldops.example`, et tous les noms de personnes, d'entreprise et de sites proviennent de listes de noms inventés versionnées avec le seed.

Publication du contrat

- CA7 : Étant donné le contrat `apps/api/openapi.json` sur `main`, quand on le lit, alors `info.version` vaut `1.0.0` à la fin de la phase 1, et chaque route de la phase 1 y figure avec ses schémas.
- CA8 : Étant donné une PR qui retire ou modifie de façon incompatible une route, un champ obligatoire ou un type du contrat, quand la CI s'exécute, alors elle échoue tant que la version majeure n'a pas été augmentée (comparaison avec le contrat de `main`).
- CA9 : Étant donné une version du contrat mergée sur `main`, quand la CI de `main` s'exécute, alors le contrat est joint comme artefact au workflow, et une release GitHub `api-v<version>` contenant `openapi.json` est créée si la version n'existe pas encore. Ce job seul reçoit le droit d'écriture sur le dépôt (`contents: write`), et seulement sur `main`.

## Cas limites et erreurs

- Chargement interrompu (base arrêtée en cours) : le chargement est transactionnel, la base reste vide et le prochain démarrage recommence.

## Hors périmètre

- Génération aléatoire de données volumineuses (tests de charge).
- Documentation technique des machines pour le RAG : phase 3.
- Publication du contrat sur un portail externe.

## Questions ouvertes

- Faut-il un outil dédié pour détecter les ruptures de contrat (CA8), par exemple `oasdiff` ? Par défaut : oui, `oasdiff` en CI ; son ajout sera justifié dans la PR.
