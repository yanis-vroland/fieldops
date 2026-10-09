import type { TypeOrmModuleOptions } from '@nestjs/typeorm';
import type { DatabaseConfig } from '../config/configuration.js';

/** Options TypeORM de l'API (ADR-002 : synchronize toujours désactivé). */
export function buildTypeOrmOptions(
  database: DatabaseConfig,
): TypeOrmModuleOptions {
  void database;
  throw new Error('Not implemented');
}
