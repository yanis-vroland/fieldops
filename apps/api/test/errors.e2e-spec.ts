import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createTestApp } from './support/app.js';

describe('Erreurs (spec 001)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  }, 60_000);

  afterAll(async () => {
    await app?.close();
  });

  it('CA16 : route inconnue : 404 avec un corps JSON', async () => {
    const response = await request(app.getHttpServer()).get(
      '/route-qui-n-existe-pas',
    );

    expect(response.status).toBe(404);
    expect(response.headers['content-type']).toMatch(/application\/json/);
    expect(response.body.statusCode).toBe(404);
    expect(typeof response.body.message).toBe('string');
  });
});
