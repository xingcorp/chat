
import { IoAdapter } from '@nestjs/platform-socket.io';
import { Server, ServerOptions } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import { INestApplicationContext } from '@nestjs/common';
import { IAMGraphQlClient } from '@core/iam/iam.client';
import { RedisService } from '@core/common/redis.service';
import { IncomingMessage } from 'http';
import { OfficeUser } from '@models/entities';
import { SocketWithAuth } from './type';
import { RedisKey } from '@core/common/common.type';

export class RedisIoAdapter extends IoAdapter {
  private adapterConstructor: ReturnType<typeof createAdapter>;
  private readonly iamClient: IAMGraphQlClient;
  private readonly redisService: RedisService

  constructor(private app: INestApplicationContext) {
    super(app);
    this.iamClient = app.get(IAMGraphQlClient)
    this.redisService = app.get(RedisService)
  }

  async connectToRedis(): Promise<void> {
    const pubClient = createClient({ url: `redis://${process.env.REDIS_HOST}:${process.env.REDIS_PORT}` });
    const subClient = pubClient.duplicate();
    await Promise.all([pubClient.connect(), subClient.connect()]);
    this.adapterConstructor = createAdapter(pubClient, subClient);
    // TODO change to Redis Stream mechanism
  }

  createIOServer(port: number, options?: ServerOptions): any {
    options.allowRequest = async (request: IncomingMessage, allowFunction) => {
      const authToken = request.headers.authorization
      if (!authToken) {
        return allowFunction('Unauthorized', false);
      }
      return allowFunction(null, true);

    };

    const server: Server = super.createIOServer(port, options);
    server.adapter(this.adapterConstructor);
    server.use(verifyTokenMiddleware(this.iamClient, this.redisService));
    return server;
  }
}

const verifyTokenMiddleware =
  (iamClient: IAMGraphQlClient, redisService: RedisService) =>
    async (socket: SocketWithAuth, next) => {
      try {
        const authToken = socket.handshake.headers['authorization'];
        if (!authToken) next(new Error('FORBIDDEN'));

        const { data, error } = await iamClient.getPermission(authToken, [])

        if (error) {
          next(new Error('FORBIDDEN'));
        }
        if (!data.userInfo.userId) {
          next(new Error('FORBIDDEN'));
        }
        let officeUser: any = await redisService.get(data.userInfo.userId)
        if (!officeUser) {
          officeUser = await OfficeUser.findOne({
            where: { iamUserId: data.userInfo.userId }
          })
          officeUser = JSON.stringify(officeUser)
          await redisService.setWithTtl(RedisKey.UserPublicProfile(officeUser.id), officeUser, 15 * 60) //Caching for 15 minutes
          await redisService.setWithTtl(data.userInfo.userId, officeUser, 15 * 60) //Caching for 15 minutes
        }
        socket.officeUser = JSON.parse(officeUser)
        socket.officeUserId = JSON.parse(officeUser).id
        socket.requesterId = data.userInfo.userId
        next();
      } catch (error) {
        console.log(error);
        next(new Error('FORBIDDEN'));
      }
    };