import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { loadConfig } from './config/configuration.js';
import { buildTypeOrmOptions } from './database/typeorm-options.js';
import { HealthModule } from './health/health.module.js';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      useFactory: () => buildTypeOrmOptions(loadConfig().database),
    }),
    HealthModule,
  ],
})
export class AppModule {}
