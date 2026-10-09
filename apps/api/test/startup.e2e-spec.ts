import path from 'node:path';
import { afterEach, describe, expect, it } from 'vitest';
import type { ChildProcess } from 'node:child_process';
import { targetDatabase } from './support/database.js';
import {
  apiRoot,
  freePort,
  runNode,
  startNode,
  stopProcess,
} from './support/process.js';

// Démarrage de l'API compilée, en boîte noire (dist/main.js).
const mainScript = path.join(apiRoot, 'dist/main.js');

// Le nom PORT seul, pas le suffixe de DATABASE_PORT.
const PORT_NAME = /(?<![A-Z_])PORT(?![A-Z_])/;

describe("Démarrage de l'API (spec 001)", () => {
  let server: ChildProcess | undefined;

  afterEach(async () => {
    if (server) await stopProcess(server);
    server = undefined;
  });

  it('CA13 : PORT non numérique : arrêt avec code non nul et message qui nomme PORT', async () => {
    const result = await runNode(
      mainScript,
      { ...process.env, PORT: 'abc' },
      20_000,
    );

    expect(result.timedOut, 'le processus ne s’est pas arrêté').toBe(false);
    expect(result.code).not.toBe(0);
    expect(result.output).toMatch(PORT_NAME);
  }, 30_000);

  it('CA13 : DATABASE_PORT non numérique : arrêt avec code non nul et message qui nomme DATABASE_PORT', async () => {
    const result = await runNode(
      mainScript,
      { ...process.env, PORT: String(await freePort()), DATABASE_PORT: 'abc' },
      20_000,
    );

    expect(result.timedOut, 'le processus ne s’est pas arrêté').toBe(false);
    expect(result.code).not.toBe(0);
    expect(result.output).toMatch(/DATABASE_PORT/);
  }, 30_000);

  // Témoin des CA13 : une configuration valide démarre bien l'API sur PORT,
  // sinon une API qui s'arrête toujours passerait les tests ci-dessus.
  it("CA12 : avec PORT valide, l'API écoute sur ce port et /health répond 200", async () => {
    const port = await freePort();
    const database = targetDatabase();
    server = startNode(mainScript, {
      ...process.env,
      PORT: String(port),
      DATABASE_HOST: database.host,
      DATABASE_PORT: String(database.port),
    });

    const deadline = Date.now() + 20_000;
    let status: number | undefined;
    while (Date.now() < deadline && status !== 200) {
      try {
        const response = await fetch(`http://127.0.0.1:${port}/health`, {
          signal: AbortSignal.timeout(2_000),
        });
        status = response.status;
      } catch {
        // Pas encore à l'écoute.
      }
      if (status !== 200) await new Promise((r) => setTimeout(r, 250));
    }

    expect(status).toBe(200);
  }, 30_000);
});
