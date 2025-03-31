import { forwardRef, Inject, Injectable } from '@nestjs/common'
import { GraphQLClient } from '../../common/graphql.client'
import { RedisService } from '../../common/redis.service'
import * as GQLTag from 'graphql-tag'
import { OrganizationSchema } from './organization.schema'
import { OrganizationFilter } from './organization.arg'

@Injectable()
export class OrganizationService extends GraphQLClient {
  constructor(
    @Inject(forwardRef(() => RedisService))
    private readonly redisService: RedisService
  ) {
    super(process.env.SRT_IAM_MICROSERVICE_DOMAIN)
  }

  public async organizationFindById(bearerToken: string, value: string) {
    return await this.sendMutationThrowError(
      bearerToken,
      OrganizationSchema.GET_ORGANIZATION_DETAIL,
      { id: value }
    )
  }

  public async organizationFindByOwnerId(bearerToken, ownerId: string) {
    return await this.sendQueryThrowError(
      bearerToken,
      OrganizationSchema.ORGANIZATION_GET_BY_OWNER_ID,
      { ownerId: ownerId }
    )
  }

  public async oganizationFindByPhone(bearerToken, phone: string) {
    return await this.sendQueryThrowError(
      bearerToken,
      OrganizationSchema.ORGANIZATION_GET_BY_PHONE,
      { phone: phone }
    )
  }

  public async getGroup(token: string) {
    return this.sendQuery(token, OrganizationSchema.ORGANIZATION_GET_GROUP)
  }

  getListSaleSteam(token: string, filter: OrganizationFilter) {
    return this.sendQueryThrowError(token, OrganizationSchema.ORGANIZATION_GET_LIST_SALE_STEAM, { filter })
  }

}
