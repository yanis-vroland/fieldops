# CLAUDE.md

Contexte projet pour l'agent de code. Les sections marquées « À ADAPTER » sont propres à chaque projet.

## Projet

FieldOps : plateforme fictive de maintenance industrielle avec IA intégrée, destinée aux équipes de maintenance (techniciens terrain, responsables maintenance). Projet vitrine qui sert aussi de premier terrain d'essai au template [agentic-dev-workflow](https://github.com/yanis-vroland/agentic-dev-workflow).

## Stack et commandes

Stack applicative pas encore choisie : le choix fera l'objet d'un ADR (`docs/adr/`) avant la première ligne de code applicatif. Ne pas initialiser de framework sans ADR accepté.

Commandes disponibles aujourd'hui (garde-fous) :
- Tests des hooks de Claude Code : `bash tests/hooks.sh`
- Test du hook pre-commit : `bash tests/pre-commit.sh`
- Test de la vérification de la revue IA : `bash tests/verifier-revue-ia.sh`
- Lint des scripts shell : `shellcheck .claude/hooks/*.sh .githooks/pre-commit .github/scripts/*.sh tests/*.sh`

À compléter (installer, lancer, tests, lint) une fois la stack choisie.

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
2. Test-first ([ADR-003](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/003-strategie-test-first.md)) :
   - écrire les tests à partir des critères d'acceptation (subagent `test-writer`), vérifier qu'ils échouent pour la bonne raison, et les committer avant l'implémentation, dans un commit séparé ;
   - relire les tests avant d'implémenter, et renforcer toute vérification qui passerait sans implémentation ;
   - implémenter jusqu'au vert ;
   - sur les garde-fous (hooks, scripts de sécurité, vérifications de CI), contrôle par mutation : désactiver chaque protection une fois et vérifier qu'au moins un test échoue.
3. Ne jamais modifier ou supprimer un test pour le faire passer sans le signaler explicitement.
4. Face à un choix d'architecture structurant, s'arrêter et proposer un ADR dans `docs/adr/` au lieu de trancher seul. L'agent peut rédiger l'ADR en entier, au statut « proposé » ; il ne passe à « accepté » et n'est mergé qu'après validation humaine ([ADR-002](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).

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
- Merger une PR : seul l'humain merge ([ADR-002](https://github.com/yanis-vroland/agentic-dev-workflow/blob/main/docs/adr/002-place-revue-humaine.md)).

## Architecture

Pas encore de code applicatif. Organisation actuelle :
- `docs/specs/` : specs fonctionnelles, numérotées (`001-…md`), rédigées avec `/spec` à partir de `docs/templates/spec.md`.
- `docs/adr/` : décisions d'architecture, numérotées (`001-…md`).
- `docs/journal.md` : journal de bord du travail avec l'agent.
- `.claude/`, `.githooks/`, `.github/`, `tests/` : garde-fous issus du template, à ne modifier qu'avec une spec.

Domaine métier envisagé (à confirmer par spec) : sites, équipements (machines), interventions de maintenance, techniciens, et une assistance IA (aide au diagnostic, résumé d'interventions).

À compléter : modules, conventions de nommage et emplacement du code une fois la stack choisie.
