require("dotenv").config()
import { ValidationPipe } from '@nestjs/common'
import { NestFactory, Reflector } from '@nestjs/core'
import { graphqlUploadExpress } from 'graphql-upload'
import { AppModule } from './app.module'
import { RedisService } from './modules/core/common/redis.service'
import { IAMGraphQlClient } from './modules/core/iam/iam.client'
import { GlobalGuard } from './modules/core/middleware/guard/global.guard'
import * as bodyParser from 'body-parser'
import { useContainer } from 'class-validator';
import { RedisIoAdapter } from '@modules/chat/chat-dapter-redis'
import { UniversalExceptionFilter } from '@core/middleware/universal-exception.filter'

async function bootstrap() {
  const app = await NestFactory.create(AppModule)
  app.use(bodyParser.json({ limit: '50mb' }))
  app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }))
  app.use(graphqlUploadExpress({
    maxFieldSize: 10000000,
    maxFiles: 10
  }))

  app.useGlobalPipes(new ValidationPipe({
    transform: true,
  }))
  const reflector = app.get(Reflector)
  const iamClient = app.get(IAMGraphQlClient)
  const redisService = app.get(RedisService)

  const redisIoAdapter = new RedisIoAdapter(app);
  await redisIoAdapter.connectToRedis();
  app.useWebSocketAdapter(redisIoAdapter);

  /*Use for validate inject DI*/
  useContainer(app.select(AppModule), { fallbackOnErrors: true });
  // app.useGlobalFilters(new UniversalExceptionFilter());
  app.useGlobalGuards(new GlobalGuard(reflector, iamClient, redisService))
  app.enableCors({
    origin: [
      'http://localhost:3000',
      'http://localhost:4200',
      'https://localhost:4200',
      'http://localhost:4300',
      'https://localhost:4300',
      'https://stg-cms-office.smarthiz.vn',
      'https://stg-office.smarthiz.vn',
      'http://34.49.187.253',
      'http://34.120.162.46',
      'https://cms-office.smarthiz.vn',
      'https://office.smarthiz.vn',
      'https://d24sl3ohok1g7j.cloudfront.net',
      'https://stg-office-web-chat.smarthiz.vn',
      'https://192.168.2.49:4200',
      'http://192.168.2.49:4200',
      'https://office-web-chat.smarthiz.vn',
      'https://34.144.235.212',
      'https://stg-office-chat.smarthiz.vn',
      'https://uat-office.smarthiz.vn',
      'https://34.117.175.10',
      'https://uat-office-chat.smarthiz.vn',
      'https://34.107.189.17',
      'https://office-chat.smarthiz.vn',
      'https://soffice-stag.web.app',
      'https://d3gtrwhuvneam7.cloudfront.net',
      'https://localhost',
      'https://dcp0mtjj11nla.cloudfront.net',
      'https://stg-user-office.smarthiz.vn',
      'http://192.168.68.1:4200',
      'https://soffice-prod.web.app',
      'https://d2f8lroznxs3uj.cloudfront.net',
      'https://uat-user-office.smarthiz.vn',
      'http://192.168.0.133:4200',
    ],
    methods: ['GET', 'POST', 'PUT', 'OPTIONS'],
    credentials: true
  })

  const PORT = Number(process.env.SERVER_PORT || 5000)
  const SERVICE_CODE = process.env.SERVICE_CODE || 'OFFICE'
  const server = await app.listen(PORT, () => {
    console.log(`[Application] ${SERVICE_CODE.toUpperCase()} ready serve on port ${PORT}`)
  })

  server.setTimeout(600000)
  console.log('[Application] Server timeout is changed to 600000 miliseconds (10 minutes)')
}

bootstrap()