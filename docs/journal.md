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
