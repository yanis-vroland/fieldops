---
name: implement
description: Implémente une spec validée en test-first.
disable-model-invocation: true
argument-hint: <chemin de la spec>
---

Implémente la spec : $ARGUMENTS

1. Vérifie que la spec a le statut « validée ». Sinon, arrête-toi et dis-le.
2. Crée une branche `feat/<nom-court>` depuis `main` à jour.
3. Délègue au subagent `test-writer` l'écriture des tests couvrant chaque critère d'acceptation.
4. Lance les tests et montre-moi qu'ils échouent pour la bonne raison. Attends mon accord avant d'implémenter.
5. Implémente le minimum pour faire passer les tests. Ne modifie aucun test : si un test te semble faux, arrête-toi et explique pourquoi.
6. Lance le lint et les tests jusqu'au vert.
7. Mets à jour les documents de référence (section « Documents de référence » de `CLAUDE.md`) : statut « livrée » de la fonctionnalité dans le cahier des charges, et architecture technique si le modèle de données, un contrat, la sécurité ou l'infrastructure a changé.
8. Termine par un récapitulatif : chaque critère et son ou ses tests, les documents de référence mis à jour, les fichiers modifiés, les dépendances ajoutées et pourquoi, les points d'attention pour la revue.
