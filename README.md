# FieldOps

Plateforme **fictive** de maintenance industrielle avec IA intégrée : suivi des machines, organisation des interventions, gestion du stock de pièces, copilote mobile pour les techniciens, RAG sur la documentation technique, serveur MCP et agents.

C'est un **projet portfolio** : il montre la construction d'un produit IA complet, de l'API au mobile, avec une méthode de développement agentique outillée par le template [agentic-dev-workflow](https://github.com/yanis-vroland/agentic-dev-workflow). Tout est fictif : entreprises, sites, machines, documents et personnes.

**Statut : phase 0 (socle), aucune brique applicative encore en place.**

## Briques

| Brique | Rôle | Stack | Phase |
| --- | --- | --- | --- |
| `apps/api` | API cœur : sites, machines, interventions, pièces, stock | NestJS, PostgreSQL 17 | 1 |
| `apps/mobile` | App du technicien avec copilote IA | Flutter | 2 |
| `services/rag` | Questions sur la documentation des machines, avec citations et évaluations | TypeScript, pgvector, Langfuse | 3 |
| `services/mcp` | Serveur MCP exposant l'API cœur | TypeScript, SDK MCP | 4 |
| `services/agents` | Système multi-agents qui organise une intervention | LangGraph.js | 4 |

Les briques communiquent uniquement par contrat (OpenAPI, MCP), sans code partagé. Les appels aux modèles d'IA partent toujours du serveur, et toute écriture déclenchée par l'IA est confirmée par un humain.

Vision complète (domaine, architecture, phases, principes) : [`docs/vision.md`](docs/vision.md).

## Méthode

Chaque évolution suit le même chemin : spec validée (`docs/specs/`), tests écrits avant le code, implémentation par l'agent, revue IA puis revue humaine de la PR. Les choix structurants passent par un ADR (`docs/adr/`). Le journal de bord (`docs/journal.md`) garde la trace de ce que l'agent a bien fait et de ce qui a été corrigé.

Règles de l'agent : [`CLAUDE.md`](CLAUDE.md).

## Lancer le projet

Pas encore disponible. Objectif de la phase 0 : `docker compose up` lance toute la plateforme sur un clone neuf.

Après le clone, installer [gitleaks](https://github.com/gitleaks/gitleaks) (sans lui, le hook refuse tous les commits) et [jq](https://jqlang.org) (lu par les hooks de Claude Code), puis activer le hook pre-commit de détection de secrets :

```bash
git config core.hooksPath .githooks
```

## Licence

MIT, voir [LICENSE](LICENSE).
