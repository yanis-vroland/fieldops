import type { TypeOrmModuleOptions } from '@nestjs/typeorm';
import type { DatabaseConfig } from '../config/configuration.js';

/** Options TypeORM de l'API (ADR-002 : synchronize toujours désactivé). */
export function buildTypeOrmOptions(
  database: DatabaseConfig,
): TypeOrmModuleOptions {
  return {
    type: 'postgres',
    host: database.host,
    port: database.port,
    username: database.user,
    password: database.password,
    database: database.name,
    synchronize: false,
    autoLoadEntities: true,
  };
}
