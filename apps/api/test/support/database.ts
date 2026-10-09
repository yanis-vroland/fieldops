/**
 * PostgreSQL 17 réel des tests e2e : valeurs par défaut du docker-compose.yml,
 * surchargées par les variables DATABASE_* si elles sont présentes.
 */
export function targetDatabase(): { host: string; port: number } {
  return {
    host: process.env.DATABASE_HOST ?? 'localhost',
    port: Number(process.env.DATABASE_PORT ?? 5432),
  };
}
