# Spec 008 : réservations de pièces

Statut : brouillon
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
- La quantité consommée peut être corrigée à la clôture (pièce finalement non utilisée, ou utilisée en partie) : la différence est libérée.

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
- CA9 : Étant donné une clôture qui précise une quantité réellement utilisée (`usedParts` : `partId`, `quantity`) inférieure à la quantité réservée, quand elle est enregistrée, alors seule la quantité utilisée sort du stock et le reste est libéré ; une quantité utilisée supérieure à la quantité réservée est refusée (400).
- CA10 : Étant donné une intervention avec des réservations `active`, quand un responsable l'annule, alors chaque réservation passe à `released` et les quantités redeviennent disponibles.
- CA11 : Étant donné un technicien qui n'est pas affecté à l'intervention, quand il réserve, modifie ou libère, alors l'API répond 403.
- CA12 : Étant donné deux réservations simultanées de la même pièce sur le même site dont la somme dépasse la quantité disponible, quand elles arrivent en même temps, alors une seule réussit et l'autre reçoit 409.
- CA13 : Étant donné une réservation `consumed` ou `released`, quand on tente de la modifier ou de la libérer, alors l'API répond 409.
- CA14 : Étant donné une intervention, quand on appelle `GET /v1/interventions/{id}/reservations`, alors on obtient ses réservations (tous statuts) avec pièce, quantité et statut.

## Cas limites et erreurs

- Réservation d'une pièce archivée : 409.
- Quantité nulle, négative, ou décimale pour l'unité `unit` : 400 (spec 006, CA9).
- La machine a changé de site depuis la réservation : les réservations restent sur le site d'origine ; libérer et réserver de nouveau (pas d'automatisme).

## Hors périmètre

- Réservation partielle, liste d'attente, commande automatique en cas de rupture.
- Réservation sur un autre site que celui de la machine.

## Questions ouvertes

Aucune.
