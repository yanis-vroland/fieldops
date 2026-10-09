# Spec 002 : conventions communes de l'API

Statut : validée
Date : 2026-10-09

Phase 1. Applique l'[ADR-003](../adr/003-conventions-api.md). Toutes les specs suivantes de la phase 1 s'appuient sur ces comportements sans les répéter.

## Besoin

En tant que client de l'API (app mobile, serveur MCP, développeur), je veux des erreurs, une validation et une pagination identiques sur toutes les routes, afin d'écrire un seul traitement générique côté client.

## Critères d'acceptation

Erreurs

- CA1 : Étant donné n'importe quelle route, quand l'API renvoie une erreur (4xx ou 5xx), alors la réponse a le type `application/problem+json` et contient `type`, `title`, `status` (égal au code HTTP) et `detail`.
- CA2 : Étant donné une route inconnue, quand on l'appelle, avec ou sans jeton, alors l'API répond 404 au format du CA1. Cela remplace le format du CA16 de la spec 001.
- CA3 : Étant donné une erreur inattendue dans le code, quand elle remonte jusqu'à la réponse, alors l'API répond 500 au format du CA1, sans trace d'exécution ni message technique dans le corps, et l'erreur complète est écrite dans les journaux du serveur.

Validation

- CA4 : Étant donné une route qui attend un corps JSON, quand un champ obligatoire manque ou a un type invalide, alors l'API répond 400 au format du CA1, avec un champ `errors` qui liste chaque champ fautif (`field`, `message`).
- CA5 : Étant donné une route qui attend un corps JSON, quand le corps contient un champ inconnu, alors l'API répond 400 et `errors` nomme ce champ.
- CA6 : Étant donné une route avec un identifiant en paramètre, quand l'identifiant n'est pas un UUID, alors l'API répond 400 (et non 404 ou 500).

Pagination

- CA7 : Étant donné une route de liste, quand on l'appelle sans paramètre, alors la réponse est `{ items, total, limit: 20, offset: 0 }`, avec au plus 20 éléments.
- CA8 : Étant donné une route de liste, quand on passe `limit` et `offset`, alors la réponse contient au plus `limit` éléments à partir du rang `offset`, et `total` compte tous les éléments qui correspondent aux filtres.
- CA9 : Étant donné une route de liste, quand `limit` vaut plus de 100, moins de 1, ou n'est pas un entier, ou quand `offset` est négatif, alors l'API répond 400.

Routes et contrat

- CA10 : Étant donné les routes métier de la phase 1, quand on lit le contrat OpenAPI, alors elles sont toutes sous `/v1`, et `/health` reste hors version.
- CA11 : Étant donné le contrat OpenAPI, quand on le lit, alors chaque route documente ses réponses d'erreur avec le schéma RFC 9457, et chaque route de liste documente `limit`, `offset` et la forme paginée.
- CA12 : Étant donné l'API démarrée sur une base vide, quand elle démarre, alors elle applique les migrations en attente avant d'accepter des requêtes ; quand elle redémarre, alors elle n'en réapplique aucune.

Ordre des contrôles

- CA13 : Étant donné une requête qui enfreint plusieurs règles à la fois, quand l'API la traite, alors elle renvoie l'erreur du premier contrôle qui échoue, dans cet ordre :
  1. route inconnue : 404, même sans jeton ;
  2. identification (route `/v1` hors connexion) : 401 ;
  3. rôle autorisé sur la route : 403 ;
  4. validation des paramètres et du corps : 400 ;
  5. existence de la ressource visée : 404 ;
  6. droit sur cette ressource (par exemple technicien affecté) : 403 ;
  7. état de la ressource et règles métier (transition, stock, unicité) : 409.

## Cas limites et erreurs

- `offset` au-delà du total : 200 avec `items` vide et le `total` réel.
- Corps JSON mal formé (syntaxe) : 400 au format du CA1.
- `Content-Type` autre que JSON sur une route qui attend un corps : 415 au format du CA1.

## Hors périmètre

- Tri personnalisé par paramètre de requête : chaque ressource a un tri par défaut, documenté dans sa spec.
- Recherche plein texte.
- Limitation du débit (rate limiting).

## Questions ouvertes

Aucune.
