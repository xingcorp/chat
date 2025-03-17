import { Controller, Get } from '@nestjs/common'

@Controller()
export class HealthController {
  @Get('/api/health/check')
  async healthCheck() {
    // console.log("Restful health checking -> I'm still servive, don't kill me please!")
    return { status: 'pass' }
  }
}
