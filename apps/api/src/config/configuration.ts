export interface DatabaseConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  name: string;
}

export interface AppConfig {
  port: number;
  database: DatabaseConfig;
}

// Valeurs fictives, identiques à celles de docker-compose.yml.
const DEFAULTS: AppConfig = {
  port: 3000,
  database: {
    host: 'localhost',
    port: 5432,
    user: 'fieldops',
    password: 'fieldops',
    name: 'fieldops',
  },
};

// Une variable vide est traitée comme absente (spec 001, CA13).
function readString(
  env: NodeJS.ProcessEnv,
  name: string,
  fallback: string,
): string {
  const value = env[name];
  return value === undefined || value === '' ? fallback : value;
}

function readPort(
  env: NodeJS.ProcessEnv,
  name: string,
  fallback: number,
): number {
  const value = env[name];
  if (value === undefined || value === '') return fallback;
  const port = /^\d+$/.test(value) ? Number(value) : NaN;
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error(
      `Invalid environment variable ${name}: expected a port between 1 and 65535, got "${value}"`,
    );
  }
  return port;
}

/**
 * Lit la configuration dans les variables d'environnement (spec 001, CA12 et CA13).
 * Variables : PORT, DATABASE_HOST, DATABASE_PORT, DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME.
 * Lève une erreur qui nomme la variable en cause si une valeur est invalide.
 */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  return {
    port: readPort(env, 'PORT', DEFAULTS.port),
    database: {
      host: readString(env, 'DATABASE_HOST', DEFAULTS.database.host),
      port: readPort(env, 'DATABASE_PORT', DEFAULTS.database.port),
      user: readString(env, 'DATABASE_USER', DEFAULTS.database.user),
      password: readString(
        env,
        'DATABASE_PASSWORD',
        DEFAULTS.database.password,
      ),
      name: readString(env, 'DATABASE_NAME', DEFAULTS.database.name),
    },
  };
}
