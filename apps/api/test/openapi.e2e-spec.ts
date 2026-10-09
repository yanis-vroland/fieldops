import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createTestApp } from './support/app.js';
import { apiRoot, runNode, type RunResult } from './support/process.js';

const generateScript = path.join(apiRoot, 'dist/scripts/generate-openapi.js');

/** Lance le script de génération vers `output`, base de données injoignable. */
function generateContract(output: string): Promise<RunResult> {
  return runNode(
    generateScript,
    {
      ...process.env,
      OPENAPI_OUTPUT: output,
      // Base injoignable : le script ne doit pas s'y connecter.
      DATABASE_HOST: '127.0.0.1',
      DATABASE_PORT: '1',
    },
    20_000,
  );
}

let workDir: string;

beforeAll(async () => {
  workDir = await mkdtemp(path.join(tmpdir(), 'fieldops-openapi-'));
});

afterAll(async () => {
  await rm(workDir, { recursive: true, force: true });
});

// Sans application démarrée : le script se suffit à lui-même.
describe('Génération du contrat OpenAPI (spec 001)', () => {
  it('CA8 : le script écrit un contrat qui contient GET /health, base injoignable', async () => {
    const output = path.join(workDir, 'openapi-ca8.json');

    const result = await generateContract(output);

    expect(result.timedOut, result.output).toBe(false);
    expect(result.code, result.output).toBe(0);
    const contract = JSON.parse(await readFile(output, 'utf8'));
    expect(contract.openapi).toMatch(/^3\./);
    expect(contract.paths?.['/health']?.get).toBeDefined();
  }, 30_000);
});

describe('Contrat OpenAPI servi par l’API (spec 001)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  }, 60_000);

  afterAll(async () => {
    await app?.close();
  });

  it('CA7 : /docs affiche Swagger UI', async () => {
    const response = await request(app.getHttpServer())
      .get('/docs')
      .redirects(1);

    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toMatch(/html/);
    expect(response.text).toMatch(/swagger-ui/i);
  });

  it('CA7 : /docs-json renvoie un contrat OpenAPI qui contient GET /health', async () => {
    const response = await request(app.getHttpServer()).get('/docs-json');

    expect(response.status).toBe(200);
    expect(response.body.openapi).toMatch(/^3\./);
    expect(response.body.paths?.['/health']?.get).toBeDefined();
  });

  it("CA8 : le contrat généré est identique à celui de l'API démarrée", async () => {
    const output = path.join(workDir, 'openapi-compare.json');

    const result = await generateContract(output);
    expect(result.code, result.output).toBe(0);

    const generated = JSON.parse(await readFile(output, 'utf8'));
    const live = await request(app.getHttpServer()).get('/docs-json');
    // Document entier : chemins, opérations, réponses et schémas.
    expect(generated).toEqual(live.body);
  }, 30_000);
});
