---
name: spec
description: Rédige une spec à partir d'un besoin exprimé en langage naturel, selon le modèle du projet.
disable-model-invocation: true
argument-hint: <besoin en une phrase>
---

Rédige une spec pour le besoin suivant : $ARGUMENTS

1. Lis le modèle `docs/templates/spec.md` et respecte sa structure.
2. Lis `docs/cahier-des-charges-fonctionnel.md` : acteurs et droits, glossaire, règles métier, fonctionnalités déjà prévues. Si la fonctionnalité touche les données ou un contrat, lis aussi `docs/architecture-technique.md`. Utilise les termes du glossaire. Si le cahier des charges est absent, signale-le et propose de le créer à partir de `docs/templates/cahier-des-charges-fonctionnel.md`.
3. Avant d'écrire, pose-moi les questions nécessaires pour lever les ambiguïtés (5 maximum). N'invente aucune règle métier, et ne repose pas une question que le cahier des charges tranche déjà : ce qui n'est pas tranché va dans « Questions ouvertes ».
4. Rédige des critères d'acceptation testables, au format Étant donné / Quand / Alors, numérotés CA1, CA2…
5. Liste les cas limites et les erreurs attendues.
6. Enregistre la spec dans `docs/specs/NNN-titre-court.md` (numéro suivant le dernier existant), avec le statut « brouillon ».
7. Mets à jour le cahier des charges : ajoute la spec à la liste des fonctionnalités (statut « spec brouillon »), et reporte les règles métier, termes et droits que mes réponses ont tranchés.
8. N'écris aucun code. Termine en me demandant de valider la spec.
