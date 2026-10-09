# CLAUDE.md

Règles de travail de l'agent de code sur FieldOps. Le contexte complet du projet (domaine, briques, phases, principes) est dans [`docs/vision.md`](docs/vision.md) : le lire avant toute spec ou tout choix structurant.

## Projet

FieldOps : plateforme fictive de maintenance industrielle (machines, interventions, pièces, stocks) avec de l'IA intégrée au produit. Projet portfolio qui démontre un produit IA complet (API, mobile, RAG, MCP, agents) et sert de preuve d'usage du template [agentic-dev-workflow](https://github.com/yanis-vroland/agentic-dev-workflow).

Tout est fictif : entreprises, sites, machines, documents et personnes. Aucune donnée réelle, aucun code ni nom issu d'un client ou d'un employeur. Les jeux de données, fixtures et exemples sont inventés.

Phase en cours : 0 (socle). Ordre des phases et critères de fin : [`docs/vision.md`](docs/vision.md#ordre-de-construction).

## Stack et commandes

Stack décidée ([ADR-001](docs/adr/001-choix-de-la-stack.md)) : ne pas la remettre en question.

- Serveur : TypeScript, NestJS, Node 24, pnpm workspaces.
- Base de données : PostgreSQL 17, avec pgvector pour le RAG.
- Mobile : Dart, Flutter (Android et iOS).
- IA : SDK et frameworks TypeScript (Vercel AI SDK ou API directe, LangChain.js, LangGraph.js, SDK MCP officiel), Langfuse pour l'observabilité.
- Infrastructure : Docker Compose.
- ORM : pas encore choisi (ADR-002). N'en installer aucun et n'écrire aucun code qui en dépend avant l'acceptation de l'ADR-002.

Commandes prévues, pas encore en place (aucune brique initialisée) :
- Installer : `pnpm install`
- Lancer toute la plateforme : `docker compose up`
- Tests d'une brique : `pnpm --filter <brique> test`
- Lint d'une brique : `pnpm --filter <brique> lint`
- Mobile : `flutter test` et `flutter analyze` dans `apps/mobile`

Commandes disponibles aujourd'hui (garde-fous) :
- Tests des hooks de Claude Code : `bash tests/hooks.sh`
- Test du hook pre-commit : `bash tests/pre-commit.sh`
- Test de la vérification de la revue IA : `bash tests/verifier-revue-ia.sh`
- Lint des scripts shell : `shellcheck .claude/hooks/*.sh .githooks/pre-commit .github/scripts/*.sh tests/*.sh`

## Langue

- Code en anglais : variables, fonctions, classes, entités, tables, routes d'API.
- Tout le reste en français : README, ADR, specs, commentaires, messages de commit, PR.
- Commits au format Conventional Commits, préfixe en anglais, message en français :
  `feat: ajout du CRUD des machines`

## Méthode de travail

1. Toute modification du comportement observable exige une spec validée dans `docs/specs/` :
   - nouvelle fonctionnalité (feat) : nouvelle spec ;
   - correction (fix) : référence à la spec concernée et test de non-régression qui échoue avant la correction ; si le bug révèle un cas non prévu, compléter d'abord la spec ;
   - sans changement de comportement (refactor, perf, test, chore, ci, docs) : la description de la PR suffit. Si le changement modifie un comportement malgré son préfixe, il relève des cas précédents.

   Pour les deux premiers cas, sans spec, proposer d'en rédiger une et attendre la validation.
2. Test-first ([ADR-003 du template](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/003-strategie-test-first.md)) :
   - écrire les tests à partir des critères d'acceptation (subagent `test-writer`), vérifier qu'ils échouent pour la bonne raison, et les committer avant l'implémentation, dans un commit séparé ;
   - relire les tests avant d'implémenter, et renforcer toute vérification qui passerait sans implémentation ;
   - implémenter jusqu'au vert ;
   - sur les garde-fous (hooks, scripts de sécurité, vérifications de CI), contrôle par mutation : désactiver chaque protection une fois et vérifier qu'au moins un test échoue.
3. Ne jamais modifier ou supprimer un test pour le faire passer sans le signaler explicitement.
4. Face à un choix d'architecture structurant, s'arrêter et proposer un ADR dans `docs/adr/` au lieu de trancher seul. L'agent peut rédiger l'ADR en entier, au statut « proposé » ; il ne passe à « accepté » et n'est mergé qu'après validation humaine ([ADR-002 du template](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).

## Définition du « done »

- Chaque critère d'acceptation de la spec est couvert par au moins un test.
- Lint, format et tests au vert.
- Aucun TODO sans ticket associé.
- Documentation mise à jour si un comportement public change.

## Interdits

- Lire, créer ou modifier un fichier `.env*`, sauf `.env.example`.
- Committer un secret, une clé ou un token.
- Ajouter une dépendance sans la justifier dans la PR.
- Pousser directement sur `main`.
- Merger une PR : seul l'humain merge ([ADR-002 du template](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).

## Architecture

Monorepo de briques indépendantes (détail et schéma : [`docs/vision.md`](docs/vision.md#architecture--un-monorepo-des-briques-indépendantes)) :

- `apps/api` : API cœur, NestJS + PostgreSQL.
- `apps/mobile` : app Flutter du technicien, avec copilote IA.
- `services/rag` : assistant sur la documentation technique, évalué et observé.
- `services/mcp` : serveur MCP exposant l'API cœur.
- `services/agents` : système multi-agents qui organise une intervention.

Règles :
- Contrats explicites uniquement : REST documentée en OpenAPI, ou MCP. Aucun import de code d'une brique vers une autre, pas de package partagé.
- Un changement de contrat est un changement de comportement observable : il exige une spec.
- Chaque brique est démontrable seule : README, démo, tests et commandes de lancement.
- Les appels aux modèles d'IA partent toujours du serveur, jamais de l'app mobile.
- Noms du code : ceux du glossaire de [`docs/vision.md`](docs/vision.md#domaine-métier) (`Site`, `Machine`, `Intervention`, `Part`, `StockItem`, `PartReservation`, `Technician`). Les specs font foi en cas d'écart.

Principes à respecter dans toute fonctionnalité IA :
- Humain dans la boucle : toute écriture déclenchée par l'IA est confirmée par un humain avant exécution.
- Audit : chaque appel d'outil par l'IA est journalisé (qui, quoi, quand, avec quels arguments).
- Moindre privilège : chaque agent n'accède qu'aux outils dont il a besoin.
- Mesure : la qualité de l'IA se prouve par des évaluations chiffrées.
- Sécurité : injection de prompt (directe et indirecte) testée, PII masquée avant envoi au modèle.

Hors périmètre : données réelles, intégration ERP, paiement et facturation, interface web d'administration, multi-entreprise.

Documentation :
- `docs/vision.md` : vision du projet, référence de contexte.
- `docs/specs/` : specs, numérotées (`001-…md`), rédigées avec `/spec` à partir de `docs/templates/spec.md`.
- `docs/adr/` : décisions d'architecture, numérotées, rédigées par l'agent au statut « proposé », acceptées par l'humain.
- `docs/journal.md` : journal de bord du travail avec l'agent.
- `.claude/`, `.githooks/`, `.github/`, `tests/` : garde-fous issus du template, à ne modifier qu'avec une spec.
