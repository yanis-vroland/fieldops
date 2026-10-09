// Régénère apps/api/openapi.json sans base de données (spec 001, CA8).
// Variable OPENAPI_OUTPUT : chemin de sortie, par défaut openapi.json dans apps/api.
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module.js';
import { buildOpenApiDocument } from '../app.setup.js';

// Mode preview : graphe des modules sans instancier les providers, donc sans connexion à PostgreSQL.
const app = await NestFactory.create(AppModule, {
  preview: true,
  logger: false,
});
const document = buildOpenApiDocument(app);
const output =
  process.env.OPENAPI_OUTPUT ??
  fileURLToPath(new URL('../../openapi.json', import.meta.url));
await writeFile(output, `${JSON.stringify(document, null, 2)}\n`);
await app.close();
