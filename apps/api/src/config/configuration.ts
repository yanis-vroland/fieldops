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

/**
 * Lit la configuration dans les variables d'environnement (spec 001, CA12 et CA13).
 * Variables : PORT, DATABASE_HOST, DATABASE_PORT, DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME.
 * Lève une erreur qui nomme la variable en cause si une valeur est invalide.
 */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  void env;
  throw new Error('Not implemented');
}
