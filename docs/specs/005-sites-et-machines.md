# Spec 005 : sites et machines

Statut : validée
Date : 2026-10-09

Phase 1. Glossaire : `Site`, `Machine` ([cahier des charges](../cahier-des-charges-fonctionnel.md#glossaire)).

## Besoin

En tant que responsable maintenance, je veux tenir à jour la liste des sites et de leurs machines, afin que chaque intervention, pièce et document technique se rattache à une machine identifiée de façon unique dans toute la plateforme.

## Règles métier

- Un site a un code (unique, 2 à 10 caractères, majuscules, chiffres et tirets), un nom et une ville.
- Une machine a :
  - un code, unique sur toute la plateforme, qui sert d'identifiant partagé entre les briques (API, RAG, agents) : 3 lettres majuscules, un tiret, 3 chiffres (par exemple `PRS-003` pour la presse n°3) ;
  - un nom, un type, un fabricant, un modèle, une date de mise en service (facultative) ;
  - un site de rattachement ;
  - un état : `in_service`, `stopped` (arrêt prévu) ou `broken_down` (en panne).
- Types de machine : `press`, `conveyor`, `compressor`, `cnc_machine`, `robot`, `pump`, `other`.
- Le code d'un site ou d'une machine ne change jamais une fois créé, et n'est jamais réattribué, même après archivage.
- Un site ne peut pas être archivé s'il a des machines non archivées, du stock physique, une réservation active ou un utilisateur actif rattaché.
- Une machine peut changer de site (déménagement).

## Droits

- Lecture : tout utilisateur connecté.
- Création, modification, archivage des sites et des machines : `manager`.
- Changement d'état d'une machine : `manager` et `technician`, sur toutes les machines (un technicien peut intervenir en renfort sur un autre site).

## Critères d'acceptation

Sites

- CA1 : Étant donné un responsable, quand il crée un site avec un code, un nom et une ville valides, alors l'API répond 201 avec le site créé.
- CA2 : Étant donné un site existant, actif ou archivé, quand on crée un site avec le même code, alors l'API répond 409.
- CA3 : Étant donné des sites, quand on appelle `GET /v1/sites`, alors on obtient la liste paginée triée par code, sans les sites archivés sauf `includeArchived=true`.
- CA4 : Étant donné un site, quand un responsable modifie son nom ou sa ville, alors l'API répond 200 ; quand le corps contient `code`, alors l'API répond 400.
- CA5 : Étant donné un site sans machine active, sans stock physique, sans réservation active et sans utilisateur actif rattaché, quand un responsable l'archive (`POST /v1/sites/{id}/archive`), alors `archivedAt` est renseigné ; si l'une de ces conditions n'est pas remplie, alors l'API répond 409 avec un `detail` qui la nomme.

Machines

- CA6 : Étant donné un responsable, quand il crée une machine valide sur un site actif, alors l'API répond 201 avec la machine, à l'état `in_service` par défaut.
- CA7 : Étant donné un code de machine qui ne respecte pas le format, quand on crée la machine, alors l'API répond 400 ; si le code existe déjà (machine active ou archivée), alors 409.
- CA8 : Étant donné un site archivé ou inexistant, quand on y crée ou déplace une machine, alors l'API répond 409 (archivé) ou 404 (inexistant).
- CA9 : Étant donné des machines, quand on appelle `GET /v1/machines`, alors on obtient la liste paginée triée par code, filtrable par `siteId`, `type` et `status`, sans les machines archivées sauf `includeArchived=true`.
- CA10 : Étant donné un code de machine, quand on appelle `GET /v1/machines/by-code/{code}`, alors on obtient la machine (même archivée) ; 404 si le code n'existe pas. C'est la route utilisée par le RAG et les agents.
- CA11 : Étant donné une machine, quand un responsable modifie son nom, son fabricant, son modèle, sa date de mise en service ou son site, alors l'API répond 200 ; quand le corps contient `code`, alors l'API répond 400.
- CA12 : Étant donné une machine, quand un technicien ou un responsable change son état (`POST /v1/machines/{id}/status` avec `status` et un `comment` facultatif), alors l'état change et l'API répond 200.
- CA13 : Étant donné un technicien, quand il tente de créer, modifier ou archiver une machine ou un site, alors l'API répond 403.
- CA14 : Étant donné une machine, quand un responsable l'archive, alors `archivedAt` est renseigné ; une machine archivée n'accepte plus de changement d'état (409).

## Cas limites et erreurs

- Code saisi en minuscules (`prs-003`) : refusé (400), pour garder un format unique dans toutes les briques.
- Date de mise en service dans le futur : 400.
- Archivage d'une machine qui a des interventions planifiées ou en cours : 409 (règle reprise dans la spec 007).

## Hors périmètre

- Hiérarchie dans un site (ateliers, lignes de production).
- Compteurs (heures de fonctionnement), capteurs, données temps réel.
- Historique des états d'une machine autre que le journal d'audit.

## Questions ouvertes

- Le passage d'une machine à `broken_down` doit-il créer automatiquement une intervention corrective ? Par défaut : non, le responsable la crée (spec 007) ; c'est le copilote de la phase 2 qui pourra la proposer.
