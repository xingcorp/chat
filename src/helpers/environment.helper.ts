import * as dotenv from 'dotenv';

dotenv.config();

export const DefaultTTLRedis = +process.env.DEFAULT_TTL_REDIS || 1800

export const isEnvLocal = !process.env.SERVER_ENV || process.env.SERVER_ENV === 'localhost';
export const isEnvProd = process.env.SERVER_ENV === 'production';
export const isEnvDev = process.env.SERVER_ENV === 'development';
export const isEnvStg = process.env.SERVER_ENV === 'staging';

export const isEnvDeploy = isEnvProd || isEnvStg
export const ChatModuleTTLRedis = +process.env.TTL_DATA_REDIS || 1350
export const ChatModuleScheduleAsyncToDb = +process.env.SCHEDULE_ASYNC_FROM_REDIS_TO_DB || 900000