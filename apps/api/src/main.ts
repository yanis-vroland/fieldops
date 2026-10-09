import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { configureApp } from './app.setup.js';
import { loadConfig } from './config/configuration.js';

async function bootstrap() {
  // Configuration lue avant tout : une variable invalide arrête l'API (spec 001, CA13).
  const config = loadConfig();
  const app = await NestFactory.create(AppModule);
  configureApp(app);
  await app.listen(config.port);
}

try {
  await bootstrap();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}
