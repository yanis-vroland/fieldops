# ADR-001 : Choix de la stack

Statut : proposé
Date : 2026-10-09

Contexte : FieldOps est une plateforme fictive de maintenance industrielle, construite comme projet portfolio ([`docs/vision.md`](../vision.md)). Elle réunit cinq briques dans un monorepo : une API cœur (`apps/api`), une app mobile de technicien avec copilote IA (`apps/mobile`), un RAG sur la documentation technique (`services/rag`), un serveur MCP (`services/mcp`) et un système multi-agents (`services/agents`). Contraintes :
- Les briques communiquent uniquement par contrat (OpenAPI, MCP), sans code partagé.
- Les appels aux modèles d'IA partent toujours du serveur.
- Une seule commande lance toute la plateforme (`docker compose up`).
- Le code est écrit en grande partie par un agent (Claude Code) dans le cadre du template agentic-dev-workflow : spec, tests d'abord, revue IA et humaine.
- Le projet est mené par une seule personne : chaque langage ou outil en plus a un coût d'entretien.

Options envisagées :
- Serveur :
  - TypeScript partout (NestJS) : un seul langage pour l'API, le RAG, le MCP et les agents ; écosystème IA TypeScript disponible (Vercel AI SDK, LangChain.js, LangGraph.js, SDK MCP officiel).
  - Python pour les briques IA (FastAPI, LangChain, LangGraph), TypeScript ou Python pour l'API : écosystème IA le plus riche, mais deux langages côté serveur, deux chaînes d'outillage et deux CI.
- Mobile :
  - Flutter : une base de code pour Android et iOS, compilation native.
  - React Native : même langage que le serveur, mais l'app reste une brique séparée sans code partagé, ce qui retire l'essentiel de cet avantage.
  - Natif (Kotlin et Swift) : deux bases de code, hors de portée d'une seule personne.
- Base de données :
  - PostgreSQL avec pgvector : une seule base pour les données métier et les embeddings du RAG.
  - PostgreSQL et une base vectorielle dédiée : un service de plus à lancer et à sauvegarder, sans besoin identifié à cette échelle.

Décision :
- Serveur : TypeScript, NestJS, Node 24 (LTS), pour toutes les briques serveur.
- Mobile : Dart, Flutter (Android et iOS).
- Base de données : PostgreSQL 17, avec pgvector pour le RAG.
- IA : SDK et frameworks TypeScript (Vercel AI SDK ou API directe, LangChain.js, LangGraph.js, SDK MCP officiel), Langfuse pour l'observabilité.
- Monorepo : pnpm workspaces.
- Infrastructure : Docker Compose ; déploiement Kubernetes possible plus tard.
- L'ORM n'est pas tranché ici : il fera l'objet de l'ADR-002.

Conséquences :
- Un seul langage côté serveur : une chaîne d'outillage (lint, format, tests) et une convention de projet NestJS communes à quatre briques, ce qui simplifie les specs et les consignes de l'agent.
- L'écosystème IA TypeScript est moins fourni que celui de Python : certaines bibliothèques d'évaluation ou de RAG n'y existent pas ou arrivent plus tard. Le RAG et les évaluations (phase 3) en dépendent le plus.
- Deux langages au total (TypeScript et Dart) : l'app mobile a sa propre chaîne d'outillage et sa propre CI.
- pnpm workspaces sert à l'outillage commun (installation, lancement des scripts), pas au partage de code : la règle « aucun code partagé » doit être tenue par la revue, car les workspaces la rendent facile à enfreindre.
- Node 24 et PostgreSQL 17 sont fixés : leurs mises à jour majeures passeront par un nouvel ADR.
