import type { INestApplication } from '@nestjs/common';

/** Configuration commune de l'application : Swagger UI sur /docs, contrat JSON sur /docs-json. */
export function configureApp(app: INestApplication): void {
  void app;
  throw new Error('Not implemented');
}
