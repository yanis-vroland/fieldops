# FieldOps

Plateforme **fictive** de maintenance industrielle avec IA intégrée : suivi des machines, organisation des interventions, gestion du stock de pièces, copilote mobile pour les techniciens, RAG sur la documentation technique, serveur MCP et agents.

C'est un **projet portfolio** : il montre la construction d'un produit IA complet, de l'API au mobile, avec une méthode de développement agentique outillée par le template [agentic-dev-workflow](https://github.com/yanis-vroland/agentic-dev-workflow). Tout est fictif : entreprises, sites, machines, documents et personnes.

**Statut : phase 0 (socle) : monorepo, API NestJS vide avec Swagger et contrôle de santé, PostgreSQL 17, CI.**

## Briques

| Brique | Rôle | Stack | Phase |
| --- | --- | --- | --- |
| `apps/api` | API cœur : sites, machines, interventions, pièces, stock | NestJS, PostgreSQL 17 | 1 |
| `apps/mobile` | App du technicien avec copilote IA | Flutter | 2 |
| `services/rag` | Questions sur la documentation des machines, avec citations et évaluations | TypeScript, pgvector, Langfuse | 3 |
| `services/mcp` | Serveur MCP exposant l'API cœur | TypeScript, SDK MCP | 4 |
| `services/agents` | Système multi-agents qui organise une intervention | LangGraph.js | 4 |

Les briques communiquent uniquement par contrat (OpenAPI, MCP), sans code partagé. Les appels aux modèles d'IA partent toujours du serveur, et toute écriture déclenchée par l'IA est confirmée par un humain.

Documentation :
- [`docs/vision.md`](docs/vision.md) : vision, domaine, phases, principes ;
- [`docs/cahier-des-charges-fonctionnel.md`](docs/cahier-des-charges-fonctionnel.md) : acteurs, droits, règles métier, parcours ;
- [`docs/architecture-technique.md`](docs/architecture-technique.md) : modèle de données, sécurité, contrat, infrastructure ;
- [`docs/specs/`](docs/specs) et [`docs/adr/`](docs/adr) : specs détaillées et décisions.

## Méthode

Chaque évolution suit le même chemin : spec validée (`docs/specs/`), tests écrits avant le code, implémentation par l'agent, revue IA puis revue humaine de la PR. Les choix structurants passent par un ADR (`docs/adr/`). Le journal de bord (`docs/journal/`, un fichier par branche) garde la trace de ce que l'agent a bien fait, de ce qui a été corrigé et de la prochaine étape : une session peut être fermée et reprise sans perte, la mémoire locale de l'agent est désactivée.

Règles de l'agent : [`CLAUDE.md`](CLAUDE.md).

## Lancer le projet

Prérequis : Docker. Pour développer : Node 24 et pnpm, [gitleaks](https://github.com/gitleaks/gitleaks) et [jq](https://jqlang.org).

```bash
docker compose up
```

L'API répond sur http://localhost:3000 : contrôle de santé sur `/health`, Swagger sur `/docs`. Les ports se changent avec `API_PORT` et `POSTGRES_PORT` (voir `.env.example`).

Pour développer :

```bash
pnpm install
git config core.hooksPath .githooks   # pre-commit : détection de secrets
docker compose up -d postgres --wait  # PostgreSQL 17 pour les tests e2e
pnpm --filter api test && pnpm --filter api test:e2e
```

## Licence

MIT, voir [LICENSE](LICENSE).
