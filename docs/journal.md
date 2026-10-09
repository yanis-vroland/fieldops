# Journal de bord

Ce que l'agent a bien fait, ce que j'ai corrigé et pourquoi, les limites observées.

## 2026-10-09 : initialisation

- Projet initialisé depuis le template agentic-dev-workflow avec `scripts/init.sh` (PR #1).
- `/install-github-app` ouvre une PR qui ajoute `claude-code-review.yml` et `claude.yml` : fermée sans merge (doublon avec `ai-review.yml`, et `@claude` hors du cadre spec puis test-first).
- La revue IA ne tourne pas sur une PR qui ajoute `ai-review.yml` : limite connue du template.
- Vérifié sur la PR #3 : une fois `ai-review.yml` sur `main`, la revue IA tourne et publie son commentaire.
