# Spec 008 : réservations de pièces

Statut : validée
Date : 2026-10-09

Phase 1. Glossaire : `PartReservation` ([`docs/vision.md`](../vision.md#domaine-métier)). S'appuie sur les specs 006 (stock) et 007 (interventions).

## Besoin

En tant que responsable maintenance ou technicien, je veux réserver les pièces nécessaires à une intervention, afin qu'elles soient encore disponibles le jour de l'intervention.

## Règles métier

- Une réservation lie une intervention, une pièce, le site de la machine de l'intervention et une quantité.
- Statuts d'une réservation :
  - `active` : la quantité est bloquée dans le stock du site, sans en sortir (elle s'ajoute à `quantityReserved`) ;
  - `consumed` : l'intervention est terminée, la quantité est sortie du stock (mouvement `issue` rattaché à l'intervention) ;
  - `released` : la réservation est annulée ou l'intervention aussi, la quantité est de nouveau disponible.
- On ne peut réserver que pour une intervention `planned` ou `in_progress`, et seulement une pièce compatible avec le type de la machine.
- Une réservation est refusée si la quantité disponible du site est insuffisante : pas de réservation partielle, pas de commande fournisseur.
- Une intervention a au plus une réservation `active` par pièce : réserver de nouveau la même pièce augmente la quantité de la réservation existante.
- Clôture de l'intervention (spec 007) : toutes ses réservations `active` passent à `consumed`, dans la même transaction que la clôture.
- Annulation de l'intervention : toutes ses réservations `active` passent à `released`, dans la même transaction.
- La quantité consommée peut être corrigée à la clôture, par la liste facultative `usedParts` (`partId`, `quantity`) du corps de clôture (spec 007, CA10) :
  - sans `usedParts`, ou pour une pièce réservée absente de `usedParts`, toute la quantité réservée est consommée ;
  - une quantité utilisée inférieure à la quantité réservée : seule la quantité utilisée sort du stock, le reste est libéré, et la réservation passe à `consumed` avec sa quantité consommée (`consumedQuantity`) ;
  - une quantité utilisée nulle : aucune sortie de stock, la réservation passe à `released` ;
  - une pièce de `usedParts` sans réservation active sur l'intervention, ou une quantité supérieure à la quantité réservée : la clôture est refusée (400) et rien ne change.

## Droits

- Réserver, modifier la quantité, libérer : `manager`, et le technicien affecté à l'intervention.

## Critères d'acceptation

- CA1 : Étant donné une intervention `planned` et une pièce compatible avec une quantité disponible suffisante sur le site de la machine, quand on la réserve (`POST /v1/interventions/{id}/reservations` avec `partId` et `quantity`), alors l'API répond 201, la réservation est `active`, et la quantité réservée du stock augmente d'autant (la quantité physique ne change pas).
- CA2 : Étant donné une quantité disponible insuffisante, quand on réserve, alors l'API répond 409 avec un `detail` qui indique la quantité disponible, et rien ne change.
- CA3 : Étant donné une pièce non compatible avec le type de la machine, quand on la réserve, alors l'API répond 409.
- CA4 : Étant donné une intervention `done` ou `cancelled`, quand on réserve, alors l'API répond 409.
- CA5 : Étant donné une réservation `active` d'une pièce, quand on réserve de nouveau la même pièce pour la même intervention, alors la quantité de la réservation existante augmente (200), sans nouvelle réservation.
- CA6 : Étant donné une réservation `active`, quand on modifie sa quantité (`PATCH /v1/reservations/{id}`), alors la quantité réservée du stock suit ; une hausse au-delà du disponible est refusée (409).
- CA7 : Étant donné une réservation `active`, quand on la libère (`POST /v1/reservations/{id}/release`), alors elle passe à `released` et la quantité redevient disponible.
- CA8 : Étant donné une intervention `in_progress` avec des réservations `active`, quand le technicien la clôture, alors chaque réservation passe à `consumed`, un mouvement `issue` rattaché à l'intervention est créé pour chaque pièce, et les quantités physique et réservée baissent d'autant.
- CA9 : Étant donné une clôture avec `usedParts` qui indique pour une pièce une quantité inférieure à la quantité réservée, quand elle est enregistrée, alors seule la quantité utilisée sort du stock, le reste redevient disponible, et la réservation est `consumed` avec `consumedQuantity` égale à la quantité utilisée.
- CA10 : Étant donné une clôture avec `usedParts` qui indique une quantité nulle pour une pièce, quand elle est enregistrée, alors aucun mouvement n'est créé pour cette pièce et sa réservation passe à `released`.
- CA11 : Étant donné une clôture avec `usedParts` qui omet une pièce réservée, quand elle est enregistrée, alors toute la quantité réservée de cette pièce est consommée.
- CA12 : Étant donné une clôture avec `usedParts` qui cite une pièce sans réservation active, ou une quantité supérieure à la quantité réservée, quand on l'envoie, alors l'API répond 400 et ni l'intervention, ni les réservations, ni le stock ne changent.
- CA13 : Étant donné une intervention avec des réservations `active`, quand un responsable l'annule, alors chaque réservation passe à `released` et les quantités redeviennent disponibles.
- CA14 : Étant donné un technicien qui n'est pas affecté à l'intervention, quand il réserve, modifie ou libère, alors l'API répond 403.
- CA15 : Étant donné deux réservations simultanées de la même pièce sur le même site dont la somme dépasse la quantité disponible, quand elles arrivent en même temps, alors une seule réussit et l'autre reçoit 409.
- CA16 : Étant donné une réservation `consumed` ou `released`, quand on tente de la modifier ou de la libérer, alors l'API répond 409.
- CA17 : Étant donné une intervention, quand on appelle `GET /v1/interventions/{id}/reservations`, alors on obtient ses réservations (tous statuts) avec pièce, quantité et statut.

## Cas limites et erreurs

- Réservation d'une pièce archivée : 409.
- Quantité nulle, négative, ou décimale pour l'unité `unit` : 400 (spec 006, CA9).
- La machine a changé de site depuis la réservation : les réservations restent sur le site d'origine ; libérer et réserver de nouveau (pas d'automatisme).

## Hors périmètre

- Réservation partielle, liste d'attente, commande automatique en cas de rupture.
- Réservation sur un autre site que celui de la machine.

## Questions ouvertes

Aucune.
