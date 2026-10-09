import { describe, expect, it } from 'vitest';
import { loadConfig } from './configuration.js';

// Le nom PORT seul, pas le suffixe de DATABASE_PORT.
const PORT_NAME = /(?<![A-Z_])PORT(?![A-Z_])/;

describe('loadConfig (spec 001)', () => {
  it("CA12 : sans variable d'environnement, applique les valeurs par défaut du docker-compose.yml", () => {
    expect(loadConfig({})).toEqual({
      port: 3000,
      database: {
        host: 'localhost',
        port: 5432,
        user: 'fieldops',
        password: 'fieldops',
        name: 'fieldops',
      },
    });
  });

  it('CA12 : chaque variable remplace sa valeur par défaut', () => {
    const config = loadConfig({
      PORT: '8080',
      DATABASE_HOST: 'db.fieldops.test',
      DATABASE_PORT: '6543',
      DATABASE_USER: 'alice',
      DATABASE_PASSWORD: 'secret-fictif',
      DATABASE_NAME: 'fieldops_test',
    });

    expect(config).toEqual({
      port: 8080,
      database: {
        host: 'db.fieldops.test',
        port: 6543,
        user: 'alice',
        password: 'secret-fictif',
        name: 'fieldops_test',
      },
    });
  });

  it.each(['abc', '3000abc'])(
    'CA13 : PORT non numérique (%s) : erreur qui nomme PORT',
    (value) => {
      expect(() => loadConfig({ PORT: value })).toThrow(PORT_NAME);
    },
  );

  it.each(['abc', '5432x'])(
    'CA13 : DATABASE_PORT non numérique (%s) : erreur qui nomme DATABASE_PORT',
    (value) => {
      expect(() => loadConfig({ DATABASE_PORT: value })).toThrow(
        /DATABASE_PORT/,
      );
    },
  );

  it.each(['0', '70000', '-1'])(
    'CA13 : PORT hors de la plage 1 à 65535 (%s) : erreur qui nomme PORT',
    (value) => {
      expect(() => loadConfig({ PORT: value })).toThrow(PORT_NAME);
    },
  );

  it('CA13 : DATABASE_PORT hors de la plage 1 à 65535 : erreur qui nomme DATABASE_PORT', () => {
    expect(() => loadConfig({ DATABASE_PORT: '65536' })).toThrow(
      /DATABASE_PORT/,
    );
  });

  it('CA13 : une variable vide est traitée comme absente', () => {
    expect(loadConfig({ PORT: '', DATABASE_HOST: '' })).toMatchObject({
      port: 3000,
      database: { host: 'localhost' },
    });
  });
});
