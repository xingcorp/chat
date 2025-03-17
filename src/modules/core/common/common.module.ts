import { CacheModule, Global, Module } from '@nestjs/common'
import { ConfigModule, ConfigService } from '@nestjs/config'
import * as redisStore from 'cache-manager-redis-store'
import { RedisService } from './redis.service'
import { ExcelService } from './excel.service'
import Redis from 'ioredis'

@Global()
@Module({
    imports: [
        CacheModule.registerAsync({
            isGlobal: true,
            imports: [ConfigModule],
            inject: [ConfigService],
            useFactory: async (configService: ConfigService) => ({
                store: redisStore,
                host: configService.get('REDIS_HOST'),
                port: configService.get('REDIS_PORT'),
                auth_pass: configService.get('REDIS_PASSWORD'),
                ttl: configService.get('CACHE_TTL')
            })
        }),
    ],
    providers: [
        {
            provide: 'RedisClient',
            useFactory: () => {
                const redisInstance = new Redis({
                    host: process.env.REDIS_HOST,
                    port: +process.env.REDIS_PORT,
                    password: process.env.REDIS_PASSWORD
                });

                redisInstance.on('error', e => {
                    throw new Error(`Redis connection failed: ${e}`);
                });

                return redisInstance;
            },
            inject: [],
        },
        RedisService,
        ExcelService
    ],
    exports: [
        RedisService,
        ExcelService
    ]
})
export class CommonModule { }
