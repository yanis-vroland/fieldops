# Spec 004 : journal d'audit

Statut : brouillon
Date : 2026-10-09

Phase 1. Principe « Audit » de [`docs/vision.md`](../vision.md#principes-transverses), étendu à toutes les écritures (pas seulement celles de l'IA), pour que la phase 2 n'ait rien à ajouter côté API.

## Besoin

En tant que responsable maintenance, je veux savoir qui a modifié quoi, quand et avec quelles données, afin de retracer toute action sur le parc, qu'elle vienne d'un humain ou, plus tard, d'un assistant IA.

## Règles métier

- Toute requête d'écriture (`POST`, `PUT`, `PATCH`) sur une route `/v1` existante produit une entrée d'audit, qu'elle réussisse ou échoue (401, 400, 403, 404, 409).
- La connexion (`POST /v1/auth/login`) est journalisée, sans le mot de passe.
- Une entrée d'audit n'est jamais modifiée ni supprimée.
- Les lectures (`GET`) ne sont pas journalisées.
- Contenu d'une entrée :

| Champ | Contenu |
| --- | --- |
| `userId`, `userRole` | utilisateur identifié par le jeton et son rôle ; vides si la requête n'est pas identifiée |
| `origin` | `user` en phase 1 ; `ai_assistant` à partir de la phase 2 |
| `method`, `route` | méthode HTTP et modèle de route (`/v1/machines/{id}/status`) |
| `resourceType` | type de ressource, déduit de la route : premier segment après `/v1`, au singulier (`machine`, `intervention`, `stock-movement`, `auth`) |
| `resourceId` | identifiant de la ressource visée : paramètre `{id}` de la route, ou, pour une création réussie, identifiant de la ressource créée ; vide sinon |
| `requestBody` | corps de la requête, masqué et tronqué selon les règles ci-dessous |
| `loginEmail` | e-mail saisi, pour la connexion uniquement |
| `statusCode` | code HTTP de la réponse |
| `createdAt` | horodatage |

- Masquage : dans le corps journalisé, tout champ dont le nom contient `password`, `secret` ou `token` (sans tenir compte de la casse) a sa valeur remplacée par `[MASQUÉ]`, y compris dans les objets imbriqués et les éléments de tableaux, à toute profondeur.
- Troncature : si le corps masqué dépasse 10 Ko une fois sérialisé, `requestBody` vaut `{ "truncated": true, "size": <taille en octets>, "preview": "<10 premiers Ko du JSON, en chaîne>" }`, qui reste du JSON valide.
- Transaction : l'entrée d'une écriture réussie est enregistrée dans la même transaction que l'écriture. L'entrée d'une écriture refusée est enregistrée dans une transaction séparée, puisque l'écriture n'a pas eu lieu.

## Critères d'acceptation

- CA1 : Étant donné un utilisateur connecté, quand il fait une écriture qui réussit, alors une entrée d'audit est créée avec tous les champs du tableau des règles, `origin` valant `user`.
- CA2 : Étant donné une création réussie (par exemple `POST /v1/machines`), quand l'entrée est enregistrée, alors `resourceId` est l'identifiant de la ressource créée.
- CA3 : Étant donné une écriture refusée par la validation (400), les droits (403), l'existence (404) ou l'état (409), quand la réponse est envoyée, alors une entrée d'audit est créée avec ce code.
- CA4 : Étant donné une écriture sans jeton ou avec un jeton invalide (401), quand la réponse est envoyée, alors une entrée d'audit est créée sans utilisateur, avec le code 401.
- CA5 : Étant donné une tentative de connexion, réussie ou non, quand elle est journalisée, alors l'entrée contient `loginEmail` mais pas le mot de passe ; `userId` est renseigné seulement si la connexion a réussi.
- CA6 : Étant donné un corps qui contient `password` à la racine, `apiToken` dans un objet imbriqué et `clientSecret` dans un élément de tableau, quand il est journalisé, alors les trois valeurs sont remplacées par `[MASQUÉ]` et les autres champs sont intacts.
- CA7 : Étant donné un corps de plus de 10 Ko, quand il est journalisé, alors `requestBody` a la forme tronquée des règles, et c'est du JSON valide.
- CA8 : Étant donné un responsable connecté, quand il appelle `GET /v1/audit-entries`, alors il obtient les entrées paginées, de la plus récente à la plus ancienne, filtrables par `userId`, `resourceType`, `resourceId`, `origin` et période (`from`, `to`).
- CA9 : Étant donné un technicien connecté, quand il appelle `GET /v1/audit-entries`, alors l'API répond 403.
- CA10 : Étant donné l'API, quand on lit le contrat OpenAPI, alors il n'existe aucune route de modification ni de suppression d'une entrée d'audit.
- CA11 : Étant donné une écriture qui réussit, quand l'enregistrement de son entrée d'audit échoue, alors l'écriture est annulée et l'API répond 500 : aucune écriture sans trace.
- CA12 : Étant donné une écriture refusée, quand l'enregistrement de son entrée d'audit échoue, alors la réponse d'erreur d'origine est envoyée inchangée, et l'échec est écrit dans les journaux du serveur.
- CA13 : Étant donné le champ `origin`, quand on lit le contrat, alors ses valeurs possibles sont `user` et `ai_assistant`.

## Cas limites et erreurs

- Écriture sur une route inconnue : 404 sans entrée d'audit (aucune ressource visée).
- Corps JSON mal formé (400 de syntaxe) : entrée créée avec un `requestBody` vide.

## Hors périmètre

- Journalisation des lectures.
- Export, purge ou durée de conservation des entrées.
- Interface de consultation autre que la route de liste.

## Questions ouvertes

Aucune.
