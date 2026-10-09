# Spec 006 : pièces et stock

Statut : validée
Date : 2026-10-09

Phase 1. Glossaire : `Part`, `StockItem` ([cahier des charges](../cahier-des-charges-fonctionnel.md#glossaire)).

## Besoin

En tant que responsable maintenance, je veux connaître pour chaque pièce la quantité disponible sur chaque site et l'historique de ses mouvements, afin d'éviter les ruptures et de préparer les interventions.

En tant que technicien, je veux vérifier qu'une pièce est disponible sur mon site avant une intervention.

## Règles métier

- Une pièce a une référence (unique, majuscules, chiffres et tirets, 3 à 30 caractères), un nom, une description facultative, une unité (`unit`, `meter`, `liter`, `kilogram`) et la liste des types de machine compatibles (types de la spec 005).
- Le stock (`StockItem`) d'une pièce sur un site contient :
  - la quantité physique (`quantityOnHand`) ;
  - la quantité réservée (`quantityReserved`, alimentée par la spec 008) ;
  - la quantité disponible (`quantityAvailable` = physique − réservée) ;
  - un seuil d'alerte (`reorderThreshold`).
- La quantité physique ne se modifie jamais directement : elle résulte des mouvements de stock.
- Types de mouvement :
  - `receipt` (entrée, quantité positive) ;
  - `issue` (sortie, quantité positive retirée) ;
  - `adjustment` (correction d'inventaire, quantité signée).
- Un mouvement ne peut pas rendre la quantité physique négative, ni inférieure à la quantité réservée.
- Une pièce est « sous le seuil » quand sa quantité disponible est inférieure ou égale au seuil d'alerte.
- Les quantités sont des nombres décimaux à 3 décimales au plus (pour les unités autres que `unit`) ; pour l'unité `unit`, des entiers.

## Droits

- Lecture des pièces, du stock et des mouvements : tout utilisateur connecté.
- Création et modification des pièces, réglage des seuils, mouvements `receipt` et `adjustment` : `manager`.
- Mouvement `issue` : `manager` et `technician` (sortie de pièce pour une intervention hors réservation).

## Critères d'acceptation

Pièces

- CA1 : Étant donné un responsable, quand il crée une pièce valide, alors l'API répond 201 ; si la référence existe déjà, alors 409.
- CA2 : Étant donné des pièces, quand on appelle `GET /v1/parts`, alors on obtient la liste paginée triée par référence, filtrable par `compatibleMachineType`, sans les pièces archivées sauf `includeArchived=true`.
- CA3 : Étant donné une machine, quand on appelle `GET /v1/parts?compatibleWithMachineId={id}`, alors on obtient les pièces compatibles avec le type de cette machine.
- CA4 : Étant donné une pièce, quand un responsable modifie son nom, sa description ou ses types compatibles, alors l'API répond 200 ; la référence et l'unité ne se modifient pas (400).

Stock

- CA5 : Étant donné une pièce sans ligne de stock sur un site, quand un responsable enregistre une entrée (`POST /v1/stock-movements`, type `receipt`) ou un ajustement positif sur ce site, alors la ligne de stock est créée avec cette quantité et un seuil d'alerte à 0 ; une sortie ou un ajustement négatif sur une ligne inexistante est refusé (409).
- CA6 : Étant donné une ligne de stock, quand on appelle `GET /v1/stock-items`, alors chaque ligne indique pièce, site, quantités physique, réservée et disponible, seuil, et un indicateur `belowThreshold` ; la liste est filtrable par `siteId`, `partId` et `belowThreshold=true`.
- CA7 : Étant donné une sortie (`issue`) dont la quantité dépasse la quantité disponible, quand on l'enregistre, alors l'API répond 409 et le stock ne change pas.
- CA8 : Étant donné un ajustement qui rendrait la quantité physique négative ou inférieure à la quantité réservée, quand on l'enregistre, alors l'API répond 409.
- CA9 : Étant donné une quantité décimale pour une pièce à l'unité `unit`, ou une quantité nulle, quand on enregistre un mouvement, alors l'API répond 400.
- CA10 : Étant donné des mouvements, quand on appelle `GET /v1/stock-movements`, alors on obtient l'historique paginé du plus récent au plus ancien, filtrable par `siteId`, `partId`, `type` et `interventionId`, avec l'auteur de chaque mouvement.
- CA11 : Étant donné une ligne de stock, quand un responsable modifie son seuil (`PATCH /v1/stock-items/{id}`, `reorderThreshold` ≥ 0), alors l'API répond 200.
- CA12 : Étant donné deux sorties simultanées dont la somme dépasse la quantité disponible, quand elles sont enregistrées en même temps, alors une seule réussit et l'autre reçoit 409 : la quantité physique ne devient jamais incohérente.
- CA13 : Étant donné un technicien, quand il enregistre une entrée ou un ajustement, ou modifie un seuil, alors l'API répond 403.
- CA14 : Étant donné une pièce sans quantité physique ni réservée sur aucun site, quand un responsable l'archive (`POST /v1/parts/{id}/archive`), alors `archivedAt` est renseigné ; s'il reste du stock ou une réservation, alors l'API répond 409.

## Cas limites et erreurs

- Mouvement sur une pièce ou un site archivé : 409.
- Mouvement avec un `interventionId` facultatif : il doit exister (404 sinon) ; il sert à rattacher une sortie à une intervention.

## Hors périmètre

- Commandes fournisseurs, fournisseurs, prix et valorisation du stock.
- Transferts entre sites (faisables en deux mouvements : sortie puis entrée).
- Emplacements dans un magasin, lots, numéros de série.
- Notifications de passage sous le seuil.

## Questions ouvertes

Aucune.
