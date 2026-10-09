# Spec 004 : journal d'audit

Statut : brouillon
Date : 2026-10-09

Phase 1. Principe « Audit » de [`docs/vision.md`](../vision.md#principes-transverses), étendu à toutes les écritures (pas seulement celles de l'IA), pour que la phase 2 n'ait rien à ajouter côté API.

## Besoin

En tant que responsable maintenance, je veux savoir qui a modifié quoi, quand et avec quelles données, afin de retracer toute action sur le parc, qu'elle vienne d'un humain ou, plus tard, d'un assistant IA.

## Règles métier

- Toute requête d'écriture (`POST`, `PUT`, `PATCH`) sur `/v1` produit une entrée d'audit, qu'elle réussisse ou échoue (validation, droits, conflit).
- La connexion (`POST /v1/auth/login`) est journalisée, sans le mot de passe.
- Une entrée d'audit n'est jamais modifiée ni supprimée.
- Les lectures (`GET`) ne sont pas journalisées.

## Critères d'acceptation

- CA1 : Étant donné un utilisateur connecté, quand il fait une écriture qui réussit, alors une entrée d'audit est créée avec : identifiant de l'utilisateur, rôle, méthode, route (modèle, par exemple `/v1/machines/{id}`), identifiant de la ressource visée, corps de la requête, code HTTP de la réponse, horodatage, et origine (`origin`, valant `user` en phase 1).
- CA2 : Étant donné une écriture refusée (400, 403, 404, 409), quand la réponse est envoyée, alors une entrée d'audit est aussi créée, avec le code d'erreur.
- CA3 : Étant donné une tentative de connexion, réussie ou non, quand elle est journalisée, alors l'entrée contient l'e-mail saisi mais pas le mot de passe ; l'utilisateur est renseigné seulement si la connexion a réussi.
- CA4 : Étant donné un corps de requête qui contient un champ nommé `password` (ou dont le nom contient `password`, `secret` ou `token`, sans tenir compte de la casse), quand il est journalisé, alors sa valeur est remplacée par `[MASQUÉ]`.
- CA5 : Étant donné un responsable connecté, quand il appelle `GET /v1/audit-entries`, alors il obtient les entrées paginées, de la plus récente à la plus ancienne, filtrables par `userId`, `resourceType`, `resourceId` et période (`from`, `to`).
- CA6 : Étant donné un technicien connecté, quand il appelle `GET /v1/audit-entries`, alors l'API répond 403.
- CA7 : Étant donné l'API, quand on lit le contrat OpenAPI, alors il n'existe aucune route de modification ni de suppression d'une entrée d'audit.
- CA8 : Étant donné une écriture qui réussit, quand l'enregistrement de l'entrée d'audit échoue, alors l'écriture est annulée et l'API répond 500 : aucune écriture sans trace.
- CA9 : Étant donné le champ `origin`, quand on lit le contrat, alors ses valeurs possibles sont `user` et `ai_assistant` (cette dernière sera utilisée en phase 2, avec l'identifiant de l'utilisateur pour le compte duquel l'assistant agit).

## Cas limites et erreurs

- Écriture sans jeton (401) : journalisée sans utilisateur, avec le code 401.
- Corps très volumineux : le corps journalisé est tronqué à 10 Ko, avec une indication de troncature.

## Hors périmètre

- Journalisation des lectures.
- Export, purge ou durée de conservation des entrées.
- Interface de consultation autre que la route de liste.

## Questions ouvertes

Aucune.
