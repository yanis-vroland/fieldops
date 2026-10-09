---
name: spec
description: Rédige une spec à partir d'un besoin exprimé en langage naturel, selon le modèle du projet.
disable-model-invocation: true
argument-hint: <besoin en une phrase>
---

Rédige une spec pour le besoin suivant : $ARGUMENTS

1. Lis le modèle `docs/templates/spec.md` et respecte sa structure.
2. Avant d'écrire, pose-moi les questions nécessaires pour lever les ambiguïtés (5 maximum). N'invente aucune règle métier : ce qui n'est pas tranché va dans « Questions ouvertes ».
3. Rédige des critères d'acceptation testables, au format Étant donné / Quand / Alors, numérotés CA1, CA2…
4. Liste les cas limites et les erreurs attendues.
5. Enregistre la spec dans `docs/specs/NNN-titre-court.md` (numéro suivant le dernier existant), avec le statut « brouillon ».
6. N'écris aucun code. Termine en me demandant de valider la spec.
