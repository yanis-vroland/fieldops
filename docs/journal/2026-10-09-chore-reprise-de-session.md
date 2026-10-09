# Journal : reprise de session sans mémoire locale

Branche `chore/reprise-de-session`. Report des specs 003 et 004 du template agentic-dev-workflow (PR #31, #32 et #33).

## 2026-10-09 16:46

### Fait

- Hook `SessionStart` (`session-start.sh`), contrôle du journal en CI (job « Journal »), mémoire automatique désactivée (`autoMemoryEnabled: false`), reviewer et `/implement` copiés depuis le template, avec leurs tests.
- Ancien `docs/journal.md` déplacé dans `docs/journal/2026-10-09-historique.md`, liens relatifs corrigés. Sa section « Prochaines étapes » est remplacée par la feuille de route du cahier des charges et par la prochaine étape de ce journal.
- `CLAUDE.md` : sections « Reprise de session » et « Organisation des PR et des phases ». Y sont reportées les règles qui n'existaient que dans la mémoire locale de l'agent : PR jamais empilées, validation groupée par phase, réponses en français, labels.
- Faits devenus faux corrigés : phase en cours dans `CLAUDE.md` (1, et non plus 0), statut de la spec 001 dans le cahier des charges (« livrée »).

### Décisions

- Le dépôt est la seule mémoire (spec 004 du template, validée par Yanis le 2026-10-09).

### Corrections et limites

- La règle « une seule PR ouverte à la fois » et ce report de la chaîne n'ont pas de test : ce sont des consignes en langage naturel.

### Prochaine étape

- Yanis : ajouter la vérification « Journal » au ruleset de `main` après le merge.
- Agent, après le merge : supprimer la mémoire locale de l'agent pour FieldOps.
- Puis implémenter la phase 1, une spec par PR, dans l'ordre : [002](../specs/002-conventions-api.md) conventions, [003](../specs/003-identification-et-droits.md) identification et droits, [004](../specs/004-journal-audit.md) audit, [005](../specs/005-sites-et-machines.md) sites et machines, [006](../specs/006-pieces-et-stock.md) pièces et stock, [007](../specs/007-interventions.md) interventions, [008](../specs/008-reservations-de-pieces.md) réservations, [009](../specs/009-donnees-fictives-et-contrat.md) données fictives et contrat `1.0.0`. Pour chaque spec : tests en échec committés, implémentation, contrôle par mutation de ce qui protège (droits, audit, stock), mise à jour des documents de référence.
- À la relecture de la spec 003 : aligner le glossaire sur `User` de rôle `technician` (incohérence relevée dans la PR #10).
