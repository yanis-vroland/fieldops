import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { configureApp } from '../../src/app.setup.js';

/**
 * Crée l'application comme en production (module racine et configureApp).
 * Import dynamique de AppModule : les variables DATABASE_* fixées par le test
 * avant l'appel sont prises en compte, quel que soit le moment où le module
 * lit sa configuration.
 */
export async function createTestApp(): Promise<INestApplication> {
  const { AppModule } = await import('../../src/app.module.js');
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();
  const app = moduleRef.createNestApplication();
  configureApp(app);
  await app.init();
  return app;
}

/** Interroge une route jusqu'à obtenir le code attendu (polling borné). */
export async function waitForStatus(
  server: Parameters<typeof request>[0],
  path: string,
  expectedStatus: number,
  timeoutMs = 15_000,
): Promise<request.Response> {
  const deadline = Date.now() + timeoutMs;
  let last: request.Response | undefined;
  while (Date.now() < deadline) {
    try {
      last = await request(server).get(path).timeout(5_000);
      if (last.status === expectedStatus) return last;
    } catch {
      // Requête expirée ou refusée : on réessaie jusqu'à l'échéance.
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(
    `GET ${path} : ${expectedStatus} attendu en ${timeoutMs} ms, dernier code ${last?.status ?? 'aucun'}`,
  );
}
