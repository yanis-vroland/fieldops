import type { INestApplication } from '@nestjs/common';
import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
} from '@nestjs/swagger';

/** Contrat OpenAPI de l'API, construit à partir du code. */
export function buildOpenApiDocument(app: INestApplication): OpenAPIObject {
  const config = new DocumentBuilder()
    .setTitle('FieldOps API')
    .setDescription('API cœur de FieldOps')
    .setVersion('0.1.0')
    .build();
  return SwaggerModule.createDocument(app, config);
}

/** Configuration commune de l'application : Swagger UI sur /docs, contrat JSON sur /docs-json. */
export function configureApp(app: INestApplication): void {
  app.enableShutdownHooks();
  SwaggerModule.setup('docs', app, () => buildOpenApiDocument(app), {
    jsonDocumentUrl: 'docs-json',
  });
}
