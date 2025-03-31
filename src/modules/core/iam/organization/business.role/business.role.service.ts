import { forwardRef, Inject, Injectable } from '@nestjs/common'
import { Request } from 'express'
import { IAMGraphQlClient } from '../../iam.client'
import { BusinessRoleSchema } from './business.role.schema'

@Injectable()
export class BusinessRoleService {
  constructor(
    @Inject(forwardRef(() => IAMGraphQlClient))
    private readonly iamClient: IAMGraphQlClient
  ) { }

  public async forwardRequest(request: Request) {
    return await this.iamClient.forwardRequest(request)
  }


  public async findById(bearerToken: string, id: string) {
    return this.iamClient.sendQuery(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_FIND_BY_ID,
      { id: id }
    )
  }

  public async findByCode(bearerToken: string, code: string) {
    return this.iamClient.sendQuery(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_FIND_BY_CODE,
      { code: code }
    )
  }

  public async findByName(bearerToken: string, name: string) {
    return this.iamClient.sendQuery(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_FIND_BY_NAME,
      { name }
    )
  }

  public async findByCodes(bearerToken: string, codes: string[]) {
    return this.iamClient.sendQuery(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_FIND_BY_CODES,
      { codes: codes }
    )
  }

  public async getUsersByCode(
    bearerToken: string,
    codes: string[],
    lastUpdateAt: number = undefined,
    withDeleted: boolean = false,
    keyword: string = undefined,
    page: number = undefined,
    size: number = undefined
  ) {
    const variables: Record<string, any> = { codes }

    if (lastUpdateAt !== undefined) {
      variables.lastUpdateAt = lastUpdateAt
    }

    if (keyword) {
      variables.keyword = keyword
    }

    if (page) {
      variables.page = page
    }

    if (size) {
      variables.size = size
    }

    if (withDeleted) {
      variables.withDeleted = true
    }

    return this.iamClient.sendQuery(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_USERS_BY_CODE,
      { arguments: variables }
    )
  }

  public async getUsersByCodes(
    bearerToken: string,
    businessCodes: string[],
    keyword: string = null,
    page: number = null,
    size: number = null
  ) {
    const variables: any = {
      codes: businessCodes
    }

    if (keyword) {
      variables.keyword = keyword
    }

    if (page) {
      variables.page = page
    }

    if (size) {
      variables.size = size
    }

    return this.iamClient.sendQuery(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_USERS_BY_CODE,
      { arguments: variables }
    )
  }

  public async getList(bearerToken: string, args: Record<string, any>) {
    return await this.iamClient.sendQueryThrowError(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_ROLE_CMS_LIST,
      { filter: args }
    )
  }

  public async getTotalList(bearerToken: string) {
    return await this.iamClient.sendQueryThrowError(
      bearerToken,
      BusinessRoleSchema.GET_BUSINESS_ROLE_TOTAL_LIST
    )
  }

  public async update(bearerToken: string, args: Record<string, any>) {
    return await this.iamClient.sendMutationThrowError(
      bearerToken,
      BusinessRoleSchema.BUSINESS_ROLE_UPDATE,
      { arguments: args }
    )
  }

  public async create(bearerToken: string, args: Record<string, any>) {
    return await this.iamClient.sendMutationThrowError(
      bearerToken,
      BusinessRoleSchema.BUSINESS_ROLE_CREATE,
      { arguments: args }
    )
  }

  public async addUsers(
    token: string,
    businessRoleId: string,
    userIds: string[],
    resignOthers: boolean = false
  ) {
    return await this.iamClient.sendMutationThrowError(
      token,
      BusinessRoleSchema.BUSSINESS_ROLE_ADD_USERS,
      {
        arguments: {
          businessRoleId: businessRoleId,
          userIds: userIds,
          resignOthers: resignOthers ? resignOthers : undefined
        }
      })
  }

  public async removeUsers(
    token: string,
    businessRoleId: string,
    userIds: string[]
  ) {
    return await this.iamClient.sendMutationThrowError(
      token,
      BusinessRoleSchema.BUSSINESS_ROLE_REMOVE_USERS,
      {
        arguments: {
          businessRoleId: businessRoleId,
          userIds: userIds
        }
      }
    )
  }

  public async approveUsers(
    token: string,
    businessRoleId: string,
    userIds: string[]
  ) {
    return await this.iamClient.sendMutationThrowError(
      token,
      BusinessRoleSchema.BUSSINESS_ROLE_APPROVE_USERS,
      {
        arguments: {
          businessRoleId: businessRoleId,
          userIds: userIds
        }
      }
    )
  }

  public async rejectUsers(
    token: string,
    businessRoleId: string,
    userIds: string[]
  ) {
    return await this.iamClient.sendMutationThrowError(
      token,
      BusinessRoleSchema.BUSSINESS_ROLE_REJECT_USERS,
      {
        arguments: {
          businessRoleId: businessRoleId,
          userIds: userIds
        }
      }
    )
  }

  public async suspendUsers(
    token: string,
    businessRoleId: string,
    userIds: string[]
  ) {
    return await this.iamClient.sendMutationThrowError(
      token,
      BusinessRoleSchema.BUSSINESS_ROLE_SUSPEND_USERS,
      {
        arguments: {
          businessRoleId: businessRoleId,
          userIds: userIds
        }
      }
    )
  }

  public async userRoleList(bearerToken: string, codes: string[], userId: string) {
    return this.iamClient.sendQuery(
      bearerToken,
      BusinessRoleSchema.BUSSINESS_ROLE_USER_LIST_QUERY,
      { filter: { codes: codes, userId: userId } }
    )
  }
}
