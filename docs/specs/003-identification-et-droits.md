# Spec 003 : identification et droits

Statut : brouillon
Date : 2026-10-09

Phase 1. Applique l'[ADR-004](../adr/004-identification-et-droits.md). Les droits de chaque ressource sont précisés dans sa spec ; celle-ci fixe le mécanisme commun.

## Besoin

En tant que technicien ou responsable maintenance, je veux me connecter avec mon e-mail et mon mot de passe, afin que l'API sache qui je suis et ce que j'ai le droit de faire.

## Règles métier

- Un utilisateur a un e-mail (unique, insensible à la casse), un nom affiché, un rôle (`technician` ou `manager`) et un mot de passe.
- Un technicien (`Technician` dans le glossaire) est un utilisateur de rôle `technician`. Il est rattaché à un site principal.
- Un utilisateur archivé ne peut plus se connecter.
- Les utilisateurs sont créés par le seed (spec 009) : pas d'inscription ni de création par l'API en phase 1.

## Critères d'acceptation

Connexion

- CA1 : Étant donné un utilisateur actif, quand il appelle `POST /v1/auth/login` avec son e-mail et son mot de passe, alors l'API répond 200 avec un `accessToken`, sa durée de validité en secondes (`expiresIn`) et le profil de l'utilisateur (identifiant, e-mail, nom, rôle, site principal), sans le mot de passe ni son empreinte.
- CA2 : Étant donné un e-mail saisi avec une casse différente, quand l'utilisateur se connecte, alors la connexion réussit.
- CA3 : Étant donné un mot de passe faux, ou un e-mail inconnu, ou un utilisateur archivé, quand on appelle `POST /v1/auth/login`, alors l'API répond 401 avec le même `detail` dans les trois cas (rien ne révèle si l'e-mail existe).
- CA4 : Étant donné un utilisateur connecté, quand il appelle `GET /v1/auth/me` avec son jeton, alors l'API renvoie son profil (même forme qu'au CA1).

Jeton

- CA5 : Étant donné une route `/v1` autre que `POST /v1/auth/login`, quand on l'appelle sans jeton, avec un jeton mal formé, signé avec un autre secret, ou expiré, alors l'API répond 401.
- CA6 : Étant donné un jeton valide d'un utilisateur archivé depuis la connexion, quand il appelle une route `/v1`, alors l'API répond 401.
- CA7 : Étant donné le jeton d'un utilisateur dont le rôle n'est pas autorisé sur une route, quand il l'appelle, alors l'API répond 403.
- CA8 : Étant donné `/health` et `/docs`, quand on les appelle sans jeton, alors ils répondent comme avant (spec 001).

Utilisateurs

- CA9 : Étant donné un utilisateur connecté (tout rôle), quand il appelle `GET /v1/users`, alors il obtient la liste paginée des utilisateurs actifs, triée par nom, filtrable par `role` et par `siteId`, sans mot de passe ni empreinte.
- CA10 : Étant donné un utilisateur connecté, quand il appelle `GET /v1/users/{id}`, alors il obtient le profil, y compris pour un utilisateur archivé (avec `archivedAt` renseigné, pour afficher l'historique des interventions) ; 404 si l'utilisateur n'existe pas.

Sécurité

- CA11 : Étant donné un utilisateur en base, quand on lit sa ligne dans la table, alors le mot de passe n'y figure qu'en empreinte argon2id.
- CA12 : Étant donné une connexion réussie ou échouée, quand on lit les journaux du serveur et le journal d'audit, alors le mot de passe n'y apparaît jamais.
- CA13 : Étant donné l'API lancée sans `JWT_SECRET`, ou avec une valeur de moins de 32 caractères, quel que soit `NODE_ENV`, quand elle démarre, alors elle s'arrête avec un message qui nomme `JWT_SECRET`. Il n'y a pas de valeur par défaut dans le code : `docker-compose.yml` et la CI fournissent une valeur fictive explicite, réservée au local.

## Cas limites et erreurs

- Corps de connexion sans e-mail ou sans mot de passe : 400 (spec 002).
- Plusieurs connexions du même utilisateur : chacune reçoit un jeton valide, sans invalider les précédents.

## Hors périmètre

- Création, modification et archivage d'utilisateurs par l'API ; changement et réinitialisation de mot de passe.
- Jeton de rafraîchissement, déconnexion, révocation.
- Limitation des tentatives de connexion.

## Questions ouvertes

- Le technicien a-t-il besoin d'autres informations dans son profil (téléphone, habilitations, spécialités) ? Par défaut : non en phase 1.
