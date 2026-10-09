import { describe, expect, it } from 'vitest';
import { buildTypeOrmOptions } from './typeorm-options.js';

const database = {
  host: 'db.fieldops.test',
  port: 6543,
  user: 'alice',
  password: 'secret-fictif',
  name: 'fieldops_test',
};

describe('buildTypeOrmOptions (spec 001)', () => {
  it('CA15 : synchronize vaut false (ADR-002)', () => {
    expect(buildTypeOrmOptions(database).synchronize).toBe(false);
  });

  it('CA12 : connexion PostgreSQL reprise de la configuration', () => {
    expect(buildTypeOrmOptions(database)).toMatchObject({
      type: 'postgres',
      host: 'db.fieldops.test',
      port: 6543,
      username: 'alice',
      password: 'secret-fictif',
      database: 'fieldops_test',
    });
  });
});
