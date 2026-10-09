import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';
import { createTestApp, waitForStatus } from './support/app.js';
import { targetDatabase } from './support/database.js';
import { startTcpProxy, type TcpProxy } from './support/tcp-proxy.js';

// L'API passe par un proxy TCP vers le vrai PostgreSQL : le couper rend la base
// injoignable sans arrêter PostgreSQL (CA5, CA6).
describe('GET /health (spec 001)', () => {
  let app: INestApplication;
  let proxy: TcpProxy;
  const savedEnv = {
    DATABASE_HOST: process.env.DATABASE_HOST,
    DATABASE_PORT: process.env.DATABASE_PORT,
  };

  beforeAll(async () => {
    const database = targetDatabase();
    proxy = await startTcpProxy(database.host, database.port);
    process.env.DATABASE_HOST = '127.0.0.1';
    process.env.DATABASE_PORT = String(proxy.port);
    app = await createTestApp();
  }, 60_000);

  afterEach(() => {
    proxy.restore();
  });

  afterAll(async () => {
    await app?.close();
    await proxy?.close();
    for (const [key, value] of Object.entries(savedEnv)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });

  it('CA4 : base joignable : 200, status ok, indicateur database up', async () => {
    const response = await request(app.getHttpServer()).get('/health');

    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ok');
    expect(response.body.info.database.status).toBe('up');
    expect(response.body.details.database.status).toBe('up');
  });

  it('CA5 : base injoignable : 503, status error, indicateur database down', async () => {
    proxy.cut();

    const response = await waitForStatus(app.getHttpServer(), '/health', 503);

    expect(response.body.status).toBe('error');
    expect(response.body.error.database.status).toBe('down');
    expect(response.body.details.database.status).toBe('down');
  }, 30_000);

  it("CA5 : base injoignable : l'API répond encore aux appels suivants", async () => {
    proxy.cut();
    await waitForStatus(app.getHttpServer(), '/health', 503);

    for (let i = 0; i < 3; i++) {
      const response = await request(app.getHttpServer())
        .get('/health')
        .timeout(5_000);
      expect(response.status).toBe(503);
      expect(response.body.details.database.status).toBe('down');
    }
    // Une autre route répond aussi : le processus n'est pas tombé.
    const docs = await request(app.getHttpServer())
      .get('/docs-json')
      .timeout(5_000);
    expect(docs.status).toBe(200);
  }, 40_000);

  it("CA6 : base de nouveau joignable : /health revient à 200 sans redémarrer l'API", async () => {
    proxy.cut();
    await waitForStatus(app.getHttpServer(), '/health', 503);

    proxy.restore();
    const response = await waitForStatus(
      app.getHttpServer(),
      '/health',
      200,
      15_000,
    );

    expect(response.body.status).toBe('ok');
    expect(response.body.details.database.status).toBe('up');
  }, 40_000);
});
