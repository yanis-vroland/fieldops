# Image de l'API pour docker compose en local, construite depuis la racine du monorepo.
# Non optimisée pour la production (hors périmètre de la spec 001) : elle garde les devDependencies.
FROM node:24-alpine

WORKDIR /repo
RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/api/package.json apps/api/
RUN pnpm install --frozen-lockfile --filter api

COPY apps/api apps/api
RUN pnpm --filter api build

WORKDIR /repo/apps/api
ENV NODE_ENV=production
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
