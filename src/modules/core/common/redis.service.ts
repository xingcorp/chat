import { DefaultTTLRedis } from '@helpers/environment.helper';
import { Injectable, Inject, CACHE_MANAGER } from '@nestjs/common'
import { Cache } from 'cache-manager'
import { Redis } from 'ioredis';
import { LoggerService } from './logger.service';

@Injectable()
export class RedisService {
  logger = new LoggerService(RedisService.name)

  private redisPrefixKey = process.env.REDIS_KEY_PREFIX
    ? String(process.env.REDIS_KEY_PREFIX)
    : 'Undefined'
  constructor(
    @Inject(CACHE_MANAGER) private readonly cache: Cache,
    @Inject('RedisClient') private readonly redisClient: Redis
  ) { }

  exists(key: string) {
    key = `${this.redisPrefixKey}_${key}`
    return this.redisClient.exists(key)
  }

  async get(key): Promise<string> {
    const sKey = `${this.redisPrefixKey}_${key}`
    await this.cache.del(sKey)
    return await this.cache.get(sKey)
  }

  async rawGet(key): Promise<string> {
    key = `${this.redisPrefixKey}_${key}`
    return this.cache.get(key)
  }

  async set(key, value) {
    const sKey = `${this.redisPrefixKey}_${key}`
    await this.cache.set(sKey, value)
  }

  async rawSet(key, value) {
    key = `${this.redisPrefixKey}_${key}`
    return this.cache.set(key, value)
  }

  async delete(key) {
    const sKey = `${this.redisPrefixKey}_${key}`
    await this.cache.del(sKey)
  }

  async setWithTtl(key, value, time: number = DefaultTTLRedis) {
    const sKey = `${this.redisPrefixKey}_${key}`
    await this.cache.set(sKey, value, { ttl: time })
  }

  async pushToArray(key, value) {
    const sKey = `${this.redisPrefixKey}_${key}`
    const existed = await this.get(sKey)
    if (!existed) {
      const array = [value]
      return await this.cache.set(sKey, JSON.stringify(array))
    }

    const array: string[] = JSON.parse(existed)
    if (!array) {
      console.log(`Failed to get array from key: ${key}`)
      return
    }

    array.push(value)
    await this.cache.del(sKey)
    return await this.cache.set(sKey, JSON.stringify(array))
  }

  async deleteFromArray(key, value) {
    const sKey = `${this.redisPrefixKey}_${key}`
    const existed = await this.get(sKey)
    if (!existed) {
      return
    }

    let array: string[] = JSON.parse(existed)
    if (!array) {
      console.log(`Failed to get array from key: ${key}`)
      return
    }

    const index = array.indexOf(value)
    array = array.slice(index, 1)

    return await this.cache.set(sKey, JSON.stringify(array))
  }

  async keys() {
    return this.cache.store.keys()
  }

  /**
   * Increment the integer value of a key by one
   */
  incr(key: string) {
    key = `${this.redisPrefixKey}_${key}`
    return this.redisClient.incr(key)
  }

  decrby(key: string, decrement: number) {
    key = `${this.redisPrefixKey}_${key}`
    return this.redisClient.decrby(key, decrement)
  }

  /**
   * Increment the score of a member in a sorted set
   */
  async zincrby(key: string, increment: number, member: string, ttlInSeconds: number = DefaultTTLRedis) { // sorted set
    try {
      key = `${this.redisPrefixKey}_${key}`
      this.logger.log(`zincrby ${key} ${increment} ${member}`)
      await this.redisClient.zincrby(key, increment, member)
      await this.redisClient.expire(key, ttlInSeconds)
      return
    } catch (error) {
      console.log('error: ', error);
    }
  }

  /**
   * Add one or more members to a sorted set, or update its score if it already exists
   */
  async zadd(key: string, score: number, member: string, ttlInSeconds: number = DefaultTTLRedis) { // sorted set
    try {
      key = `${this.redisPrefixKey}_${key}`
      this.logger.log('zadd', key)
      await this.redisClient.zadd(key, score, member)
      await this.redisClient.expire(key, ttlInSeconds)
      return
    } catch (error) {
      console.log('error: ', error);
    }
  }

  /**
   * Removes the specified members from the sorted set stored at key. Non existing members are ignored.
   */
  async zrem(key: string, members: (string | Buffer | number)[]) {
    try {
      key = `${this.redisPrefixKey}_${key}`
      this.logger.log('zrem', key)
      await this.redisClient.zrem(key, members)
      return
    } catch (error) {
      console.log('error: ', error);
    }
  }

  /**
  * Return a range of members in a sorted set, by index, with scores ordered from high to low
  */
  zrevrange(key: string, start: number = 0, limit: number = 50) {
    key = `${this.redisPrefixKey}_${key}`
    this.logger.log('zrevrange', key)
    return this.redisClient.zrevrange(key, start, limit - 1)
  }

  /**
   * Add one or more members to a set
   */
  async sadd(key: string, member: (string | Buffer | number)[], ttlInSeconds: number = DefaultTTLRedis) { //  set
    try {
      key = `${this.redisPrefixKey}_${key}`
      this.logger.log('sadd', key)
      await this.redisClient.sadd(key, member)
      await this.redisClient.expire(key, ttlInSeconds)
      return
    } catch (error) {
      console.log('error: ', error);
    }
  }

  /**
   * Get all the members in a set
   */
  smember(key: string) {
    key = `${this.redisPrefixKey}_${key}`
    return this.redisClient.smembers(key)
  }

  /**
   * Remove one or more members from a set
   */
  srem(key: string, members: (string | Buffer | number)[]) { // removes the specified member from the set
    key = `${this.redisPrefixKey}_${key}`
    return this.redisClient.srem(key, members)
  }

  /**
   * Set the string value of a hash field
   */
  async hset(key: string, object: object, ttlInSeconds: number = DefaultTTLRedis) {
    try {
      key = `${this.redisPrefixKey}_${key}`
      await this.redisClient.hset(key, object)
      await this.redisClient.expire(key, ttlInSeconds)
      return
    } catch (error) {
      console.log('error: ', error);
    }
  }

  hincrby(key: string, field: string, increment: number) {
    key = `${this.redisPrefixKey}_${key}`
    return this.redisClient.hincrby(key, field, +increment)
  }

  /**
   * Get the value of a hash field
   */
  hget(key: string, field: string) {
    key = `${this.redisPrefixKey}_${key}`
    return this.redisClient.hget(key, field)
  }
}
