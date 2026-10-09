# Spec 007 : interventions

Statut : brouillon
Date : 2026-10-09

Phase 1. Glossaire : `Intervention` ([cahier des charges](../cahier-des-charges-fonctionnel.md#glossaire)). Les réservations de pièces liées à une intervention sont dans la spec 008.

## Besoin

En tant que responsable maintenance, je veux planifier les interventions sur les machines et les affecter aux techniciens, afin d'organiser le travail de l'équipe.

En tant que technicien, je veux voir mes interventions, les démarrer et les clôturer avec un rapport, afin de rendre compte de mon travail.

## Règles métier

- Une intervention a :
  - une machine ;
  - un type : `preventive` ou `corrective` ;
  - une priorité : `low`, `normal`, `high` ou `urgent` ;
  - un titre et une description ;
  - une date prévue (`scheduledFor`, facultative) ;
  - un technicien affecté (facultatif à la création) ;
  - un statut ;
  - un rapport de clôture.
- Statuts et transitions permises :
  - `planned` → `in_progress` (démarrage) ;
  - `in_progress` → `done` (clôture) ;
  - `planned` ou `in_progress` → `cancelled` (annulation).
- Une intervention `done` ou `cancelled` ne change plus : ni statut, ni champ, ni affectation.
- Démarrer exige un technicien affecté. Seul ce technicien peut démarrer et clôturer l'intervention.
- Clôturer exige un rapport (`report`, texte de 10 à 5 000 caractères).
- Les dates de démarrage (`startedAt`) et de fin (`completedAt` ou `cancelledAt`) sont renseignées par l'API au moment de la transition.
- Une intervention ne peut pas être créée sur une machine archivée. Une machine qui a des interventions `planned` ou `in_progress` ne peut pas être archivée.
- Annuler exige un motif (`cancellationReason`).

## Droits

- Lecture : tout utilisateur connecté.
- Création, modification (titre, description, priorité, date prévue), affectation et annulation : `manager`.
- Démarrage et clôture : le technicien affecté uniquement.
- Le technicien affecté peut compléter la description pendant que l'intervention est `in_progress`.

## Critères d'acceptation

Création et lecture

- CA1 : Étant donné un responsable, quand il crée une intervention valide sur une machine active, alors l'API répond 201 avec l'intervention au statut `planned`.
- CA2 : Étant donné une machine archivée ou inexistante, quand on crée une intervention dessus, alors l'API répond 409 (archivée) ou 404 (inexistante).
- CA3 : Étant donné des interventions, quand on appelle `GET /v1/interventions`, alors on obtient la liste paginée, triée par priorité décroissante dans l'ordre métier `urgent`, `high`, `normal`, `low` (et non alphabétique), puis par date prévue croissante (sans date en dernier), filtrable par `status` (plusieurs valeurs possibles), `machineId`, `siteId`, `assignedTechnicianId`, `type` et `priority`.
- CA4 : Étant donné un utilisateur connecté, quand il appelle `GET /v1/interventions?assignedTo=me`, alors il n'obtient que les interventions qui lui sont affectées (liste vide pour un responsable, à qui rien n'est affecté). C'est la vue « mes interventions » de l'app mobile.
- CA5 : Étant donné une intervention, quand on appelle `GET /v1/interventions/{id}`, alors on obtient l'intervention avec sa machine (code, nom, site), son technicien affecté et ses réservations de pièces (spec 008).

Affectation et modification

- CA6 : Étant donné une intervention `planned` ou `in_progress`, quand un responsable l'affecte à un utilisateur de rôle `technician` actif (`POST /v1/interventions/{id}/assign`), alors l'API répond 200 ; si l'utilisateur n'est pas un technicien actif, alors 409.
- CA7 : Étant donné une intervention `planned` ou `in_progress`, quand un responsable modifie son titre, sa description, sa priorité ou sa date prévue, alors l'API répond 200 ; la machine et le type ne se modifient pas (400).

Transitions

- CA8 : Étant donné une intervention `planned` affectée au technicien connecté, quand il la démarre (`POST /v1/interventions/{id}/start`), alors elle passe à `in_progress` et `startedAt` est renseigné.
- CA9 : Étant donné une intervention `planned` sans technicien, ou affectée à un autre technicien, quand un technicien tente de la démarrer, alors l'API répond 409 (sans technicien) ou 403 (autre technicien).
- CA10 : Étant donné une intervention `in_progress` affectée au technicien connecté, quand il la clôture (`POST /v1/interventions/{id}/complete`) avec un rapport valide (`report`) et, facultativement, les quantités de pièces réellement utilisées (`usedParts`, règles de la spec 008), alors elle passe à `done`, `completedAt` est renseigné, et ses réservations sont traitées selon la spec 008, dans la même transaction.
- CA11 : Étant donné une clôture sans rapport ou avec un rapport trop court, quand on l'envoie, alors l'API répond 400 et le statut ne change pas.
- CA12 : Étant donné une intervention `planned` ou `in_progress`, quand un responsable l'annule (`POST /v1/interventions/{id}/cancel`) avec un motif, alors elle passe à `cancelled` et `cancelledAt` est renseigné.
- CA13 : Étant donné une intervention, quand on demande une transition non listée dans les règles (par exemple démarrer une intervention `done`, clôturer une intervention `planned`), alors l'API répond 409 avec un `detail` qui nomme le statut actuel.
- CA14 : Étant donné une intervention `done` ou `cancelled`, quand on tente de la modifier ou de la réaffecter, alors l'API répond 409.
- CA15 : Étant donné une machine qui a une intervention `planned` ou `in_progress`, quand un responsable tente d'archiver la machine, alors l'API répond 409.
- CA16 : Étant donné deux demandes de transition simultanées sur la même intervention (par exemple clôture et annulation), quand elles arrivent en même temps, alors une seule réussit et l'autre reçoit 409.

Droits

- CA17 : Étant donné une intervention `in_progress` affectée au technicien connecté, quand il modifie sa description (`PATCH /v1/interventions/{id}` avec seulement `description`), alors l'API répond 200 ; s'il modifie un autre champ, ou si l'intervention n'est pas `in_progress`, alors 403.
- CA18 : Étant donné un technicien, quand il tente de créer, d'affecter ou d'annuler une intervention, ou d'en modifier un autre champ que la description (CA17), alors l'API répond 403.
- CA19 : Étant donné un responsable, quand il tente de démarrer ou de clôturer une intervention, alors l'API répond 403.
- CA20 : Étant donné un technicien non affecté, quand il tente de démarrer une intervention `done`, alors l'API répond 403 : les droits sont contrôlés avant l'état (spec 002, CA13).

## Cas limites et erreurs

- Date prévue dans le passé à la création : acceptée (rattrapage d'une intervention oubliée).
- Technicien affecté archivé après l'affectation : l'intervention reste affectée ; un responsable doit la réaffecter pour qu'elle puisse être démarrée.

## Hors périmètre

- Interventions récurrentes et plans de maintenance préventive automatiques.
- Durée estimée, temps passé, coûts.
- Plusieurs techniciens sur une même intervention.
- Pièces jointes (photos) au rapport : à voir en phase 2 avec le mobile.

## Questions ouvertes

- La clôture d'une intervention corrective doit-elle remettre la machine à l'état `in_service` ? Par défaut : non, le technicien change l'état de la machine séparément (spec 005, CA12).
