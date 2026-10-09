import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import {
  HealthCheck,
  HealthCheckService,
  TypeOrmHealthIndicator,
} from '@nestjs/terminus';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly database: TypeOrmHealthIndicator,
  ) {}

  // 200 si PostgreSQL répond, 503 sinon (spec 001, CA4 à CA6).
  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.database.pingCheck('database', { timeout: 1500 }),
    ]);
  }
}
