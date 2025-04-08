import { Module } from '@nestjs/common'
import { AboutResolver } from './about.resolver'
import { HealthController } from './health.controller'

@Module({
  controllers: [HealthController],
  providers: [AboutResolver]
})
export class AboutModule {}
