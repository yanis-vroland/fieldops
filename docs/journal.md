# Journal de bord

Ce que l'agent a bien fait, ce que j'ai corrigé et pourquoi, les limites observées.

## 2026-10-09 : initialisation

- Projet initialisé depuis le template agentic-dev-workflow avec `scripts/init.sh` (PR #1).
- `/install-github-app` ouvre une PR qui ajoute `claude-code-review.yml` et `claude.yml` : fermée sans merge (doublon avec `ai-review.yml`, et `@claude` hors du cadre spec puis test-first).
- La revue IA ne tourne pas sur une PR qui ajoute `ai-review.yml` : limite connue du template.
- Vérifié sur la PR #3 : une fois `ai-review.yml` sur `main`, la revue IA tourne et publie son commentaire.

## 2026-10-09 : socle (phase 0, spec 001)

- Ce que l'agent a bien fait : tests écrits par `test-writer` avant le code (proxy TCP pour simuler la perte de PostgreSQL sans l'arrêter, témoin contre une API qui s'arrêterait toujours) ; implémentation au vert du premier coup ; 15 mutations, toutes détectées.
- Corrigé à la relecture par l'agent principal : CA13 ne couvrait pas les ports hors plage ni les variables vides.
- Corrigé suite à la revue IA (PR #7) : PostgreSQL publié sur toutes les interfaces, défauts de l'API non comparés au compose, format non vérifié en CI, dépendances non justifiées.
- Écart constaté : NestJS 12 génère Vitest et oxlint, pas Jest ; la spec, écrite avant, supposait Jest.
- Limites : le hook `protect-secrets` refuse toute commande shell avec heredoc qui cite un fichier d'environnement, même `.env.example` (fichiers écrits avec l'outil d'écriture) ; `rm -rf` est interdit à l'agent, le `node_modules` généré par le CLI est resté en place.
- Le job « Revue IA » échoue si la revue tente une action refusée, même quand le rapport est complet (PR #7).
- Incident : la PR #7 était basée sur la branche de la PR #6 ; mergée après la #6, elle a atterri dans cette branche et non dans `main`. Rattrapage par la PR #8. Règle depuis : toute PR cible `main`.

## 2026-10-09 : rédaction de la phase 1

- ADR-003 (conventions de l'API) et ADR-004 (identification et droits), specs 002 à 009, cahier des charges fonctionnel et architecture technique (PR #9).
- Méthode convenue pour les phases : validation groupée des specs d'une phase, puis une PR par spec, une seule ouverte à la fois, toujours basée sur `main`. Identification et audit inclus dès la phase 1 pour préparer le mobile.
- Ce que l'agent a bien fait : 19 questions métier posées en un lot avec une réponse par défaut chacune, aucune règle inventée sans la signaler.
- Corrigé suite à la revue IA (PR #9) : clôture d'intervention définie différemment dans deux specs, journal d'audit incohérent avec son modèle, ordre des contrôles (401, 403, 400, 404, 409) non fixé, secret JWT avec valeur par défaut, remise à zéro du jeu de données trop facile à déclencher.
- Incident : la PR #9 a été mergée avant le commit qui passait les ADR à « accepté » et les specs à « validée » ; repris dans la PR suivante.

## Prochaines étapes

Mis à jour à la fin de chaque session, pour reprendre sans dépendre de la mémoire de l'agent.

Fait :
- Phase 0 (socle) sur `main` ; phase 1 rédigée et validée.
- Ruleset de `main` : vérifications obligatoires « Tests des garde-fous », « Détection de secrets », « API - lint, format, tests et contrat » et « Plateforme - docker compose ».

À faire, dans l'ordre :
1. Implémenter la phase 1, une spec par PR, dans l'ordre : [002](specs/002-conventions-api.md) conventions, [003](specs/003-identification-et-droits.md) identification et droits, [004](specs/004-journal-audit.md) audit, [005](specs/005-sites-et-machines.md) sites et machines, [006](specs/006-pieces-et-stock.md) pièces et stock, [007](specs/007-interventions.md) interventions, [008](specs/008-reservations-de-pieces.md) réservations, [009](specs/009-donnees-fictives-et-contrat.md) données fictives et contrat `1.0.0`.
2. Pour chaque spec : tests écrits par `test-writer` et committés en échec, relus, puis implémentation, contrôle par mutation sur ce qui protège (droits, audit, stock), mise à jour de `docs/architecture-technique.md` si le modèle change.
3. Fin de la phase 1 : vérifier le critère de [`vision.md`](vision.md#ordre-de-construction) sur un clone neuf, puis rédiger les specs et ADR de la phase 2 (copilote : emplacement côté serveur, accès au modèle d'IA ; socle Flutter).

Reprise de session : lire `CLAUDE.md`, ce journal et les PR ouvertes, puis vérifier l'état de `main` avant d'agir.
