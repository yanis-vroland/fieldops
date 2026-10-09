# ADR-004 : Identification et droits

Statut : proposé
Date : 2026-10-09

Contexte : la phase 1 doit savoir qui appelle l'API, pour trois raisons :
- l'app mobile (phase 2) affiche « mes interventions » au technicien connecté ;
- les droits diffèrent entre technicien et responsable maintenance ([`docs/vision.md`](../vision.md#utilisateurs)) ;
- le journal d'audit enregistre qui a fait chaque écriture.

Contraintes : tout est fictif, il n'y a ni annuaire d'entreprise ni fournisseur d'identité ; pas d'interface d'administration ; les appels aux modèles d'IA (phases 2 à 4) se feront au nom de l'utilisateur connecté.

Options envisagées :
- Fournisseur d'identité externe (Keycloak, Auth0) avec OAuth 2 / OpenID Connect : réaliste, mais un service de plus à lancer et à configurer, sans bénéfice pour une démonstration.
- Sessions côté serveur avec cookie : simple pour un navigateur, moins adapté à une app mobile et à des appels entre services.
- Jeton JWT signé par l'API, après connexion par e-mail et mot de passe : sans état côté serveur, standard pour une app mobile, transmissible au serveur MCP.

Décision :
- Connexion : `POST /v1/auth/login` avec e-mail et mot de passe, réponse avec un jeton d'accès JWT (signature HS256, durée de vie 8 heures, une journée de travail) et le profil de l'utilisateur. Pas de jeton de rafraîchissement en phase 1.
- Mots de passe : hachés avec argon2id (bibliothèque `argon2`), jamais renvoyés ni journalisés.
- Jeton : `Authorization: Bearer <jeton>` sur toutes les routes `/v1`, sauf `/v1/auth/login`. Il porte l'identifiant de l'utilisateur et son rôle.
- Secret de signature : variable d'environnement `JWT_SECRET`, toujours obligatoire, d'au moins 32 caractères ; aucune valeur par défaut dans le code. `docker-compose.yml` et la CI fournissent une valeur fictive explicite, réservée au local.
- Rôles : `technician` et `manager`. Les droits sont vérifiés par des guards NestJS (`@nestjs/jwt`, sans Passport), déclarés par un décorateur sur chaque route.
- Utilisateurs : créés par le seed (spec 009). Pas d'inscription, pas de route de création d'utilisateur en phase 1.

Conséquences :
- Pas de révocation d'un jeton avant expiration : acceptable pour des données fictives, à revoir si l'API est exposée publiquement.
- La valeur fictive de `docker-compose.yml` est publique et ne protège rien : elle est réservée au local, et la documentation le dit. Oublier de la remplacer ailleurs reste possible ; l'absence de valeur par défaut dans le code évite au moins qu'un environnement démarre sans secret explicite.
- Le serveur MCP et les agents (phase 4) relaieront le jeton de l'utilisateur, ou recevront un compte de service : à trancher par un ADR en phase 4.
- Dépendances : `@nestjs/jwt`, `argon2`.
