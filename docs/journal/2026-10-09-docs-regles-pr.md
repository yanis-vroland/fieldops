# Journal : règles de PR issues de la mémoire locale

Branche `docs/regles-pr`.

## 2026-10-09 16:52

### Fait

- `CLAUDE.md`, section « Organisation des PR et des phases » : pousser tous les commits avant d'annoncer qu'une PR est prête, vérifier le dernier commit sur `main` après le merge, rebase par l'agent quand une autre PR touche les mêmes fichiers. Reprend la règle n°6 du template (PR #34).
- Ces règles n'existaient que dans la mémoire locale de l'agent (`etat-projet`). La mémoire locale de FieldOps est supprimée : tout son contenu utile est désormais dans le dépôt.

### Décisions

- Le reste de cette mémoire est déjà versionné ou périmé : pièges connus dans `docs/journal/2026-10-09-historique.md`, état et ordre de la phase 1 dans `docs/journal/2026-10-09-chore-reprise-de-session.md`.

### Corrections et limites

- Consignes sans test.

### Prochaine étape

- Implémenter la spec [002](../specs/002-conventions-api.md) (conventions de l'API), première spec de la phase 1 : branche depuis `main`, tests écrits par `test-writer` et committés en échec, puis implémentation.
