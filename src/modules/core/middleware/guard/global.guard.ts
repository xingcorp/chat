import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common'
import { Reflector } from '@nestjs/core'
import { GqlExecutionContext } from '@nestjs/graphql'
import { Observable } from 'rxjs'
import { ApolloError } from 'apollo-server-express'
import { ServiceKeys, ServiceActions, ServiceRedisKey } from './service.action'
import { BusinessRoleStatus } from '../../iam/objects/business.role'
import { RedisService } from '../../common/redis.service'
import { IAMGraphQlClient } from '../../iam/iam.client'
import { OfficeUser } from '@models/entities'
import { generateNoneDashUUID } from '@core/common/uuid'
import { RedisKey } from '@core/common/common.type'

@Injectable()
export class GlobalGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly iamClient: IAMGraphQlClient,
    private readonly redisService: RedisService
  ) { }

  private checkPermission = async (
    request,
    serviceActions: string[],
    businessRoleCodes: string[],
    userTypes: string[],
    globalGuardLogs: string[]
  ) => {
    globalGuardLogs.push(`Check permission: ${JSON.stringify({
      actions: serviceActions,
      businessRoles: businessRoleCodes,
      userTypes: userTypes
    })} - ${(new Date()).getTime()}`)

    //Public is exception
    if (
      (!serviceActions && !businessRoleCodes) ||
      (serviceActions && serviceActions.includes(ServiceActions.Public))
    ) {
      globalGuardLogs.push(`Access granted by public rule - ${(new Date()).getTime()}`)
      return { granted: true }
    }

    //Check authentication
    const authToken = request.headers['authorization']
    if (!authToken) {
      globalGuardLogs.push(`Authorization token not found - ${(new Date()).getTime()}`)
      return { error: new ApolloError('Bạn chưa đăng nhập', 'Office.UserNotLogin') }
    }

    //Call IAM to get permission
    globalGuardLogs.push(`Send request get permission to IAM - ${(new Date()).getTime()}`)
    const { data, error } = await this.iamClient.getPermission(authToken, serviceActions || [])
    globalGuardLogs.push(`Got permission from IAM - ${(new Date()).getTime()}`)

    if (error) {
      globalGuardLogs.push(`User's token not found - ${(new Date()).getTime()}`)
      return { error: new ApolloError(error.message, 'Office.TokenNotFound') }
    }

    request.requesterInfo = data.userInfo
    request.requesterId = data.userInfo.userId
    request.userType = data.userInfo.user?.type
    console.log('request.userType: ', request.userType);
    request.businessRoleIds = data.userInfo.businessRoleIds
    request.organizationId = data.userInfo.organizationId

    if (!data.userInfo.userId) {
      globalGuardLogs.push('Không tìm thấy thông tin người dùng')
      return { error: new ApolloError('Không tìm thấy thông tin người dùng', '401') }
    }

    let officeUser: any = await this.redisService.get(data.userInfo.userId)
    globalGuardLogs.push(`Get userInfo from Redis: ${(new Date()).getTime()}`)
    if (!officeUser) {
      officeUser = await OfficeUser.findOne({
        where: { iamUserId: data.userInfo.userId }
      })
      officeUser = JSON.stringify(officeUser)
      await this.redisService.setWithTtl(RedisKey.UserPublicProfile(officeUser.id), officeUser, 15 * 60) //Caching for 15 minutes
      await this.redisService.setWithTtl(data.userInfo.userId, officeUser, 15 * 60) //Caching for 15 minutes
    }
    request.officeUser = JSON.parse(officeUser)
    request.officeRequesterId = (JSON.parse(officeUser))?.id

    globalGuardLogs.push(`Authenticated with:  ${JSON.stringify({
      userId: data.userInfo.userId,
      organizationId: data.userInfo.organizationId,
      businessRoleIds: data.userInfo.businessRoleIds,
      userType: data.userInfo.user?.type
    })} - ${(new Date()).getTime()}`)

    if (data.isRoot && data.isRoot === true) {
      globalGuardLogs.push(`The system is under attack by backdoor - ${(new Date()).getTime()}`)
      return { granted: true }
    }

    //Check business role
    if (businessRoleCodes) {
      if (request.requesterInfo.businessRoles) {
        for (const role of request.requesterInfo.businessRoles) {
          if (role.status === BusinessRoleStatus.Approved && businessRoleCodes.includes(role.code)) {
            globalGuardLogs.push(`Access granted by business role: ${role.code} - ${(new Date()).getTime()}`)
            return { granted: true }
          }

          if (role.status !== BusinessRoleStatus.Approved
            && businessRoleCodes.length == 1
            && businessRoleCodes.includes(role.code)
          ) {
            globalGuardLogs.push(`Accessing system by not approved bussiness role: ${role.code} - ${(new Date()).getTime()}`)
            return {
              error: new ApolloError(
                'Vai trò của bạn chưa được phê duyệt',
                'Office.RoleHasNotBeenApproved',
                {
                  seviceCode: process.env.SERVICE_CODE,
                  serviceAction: serviceActions,
                  businessRoleCodes: businessRoleCodes,
                  targetBusinessRoleCode: role.code
                }
              )
            }
          }
        }
      }
    }

    if (userTypes) {
      if (!userTypes.includes(request.userType)) {
        globalGuardLogs.push(`Permission denied by userType: ${request.userType} - ${(new Date()).getTime()}`)
        return {
          error: new ApolloError(
            'Bạn không có quyền sử dụng tính năng',
            'Office.FunctionPermissionDenied',
            {
              seviceCode: process.env.SERVICE_CODE,
              serviceAction: serviceActions,
              userTypes: userTypes,
              targetUserType: request.userType
            }
          )
        }
      }
    }

    //Check authenticated
    if ((!serviceActions && !businessRoleCodes) ||
      (serviceActions && serviceActions.includes(ServiceActions.Authenticated))
    ) {
      globalGuardLogs.push(`Access granted by service action: ${ServiceActions.Authenticated} - ${(new Date()).getTime()}`)
      return { granted: true }
    }

    //Check permission
    return { granted: data.granted ? data.granted : false }
  }

  canActivate(
    context: ExecutionContext
  ): boolean | Promise<boolean> | Observable<boolean> {
    const isFowardAuthentication = this.reflector.get<boolean>("isFowardAuthentication", context.getHandler()) || false;
    const contextType = context.getType() as string
    const globalGuardLogs = []
    const globalGuardStartAt = new Date()
    const requestId = generateNoneDashUUID()
    let request = null
    if (contextType === 'http') {
      request = context.switchToHttp().getRequest()
      globalGuardLogs.push(`Request ${requestId} has accepted: REST - ${request.method} - ${request.path} - ${(new Date()).getTime()}`)
    } else if (contextType === 'graphql') {
      const ctx = GqlExecutionContext.create(context).getContext()
      if (ctx && ctx.req && !isFowardAuthentication) {
        request = ctx.req;
        globalGuardLogs.push(`Request ${requestId} has accepted: GraphQL - ${request.body.operationName} - ${(new Date()).getTime()}`)
      }
      else if (ctx && ctx.extra && isFowardAuthentication) {
        request = ctx.extra;
        globalGuardLogs.push(`Request ${requestId} has accepted: GraphQL - Subcriptions - ${(new Date()).getTime()}`)
      }
    }

    if (!request) {
      globalGuardLogs.push(`Request not found - ${(new Date()).getTime()}`)
      globalGuardLogs.push(`Execute time: ${(new Date()).getTime() - globalGuardStartAt.getTime()}`)
      console.log(`[GlobalGuard] execution logs: ${JSON.stringify(globalGuardLogs)}`)
      throw new ApolloError('Không tìm thấy thông tin request trong context', '404')
    }

    //Check permission
    const serviceActions = this.reflector.get<string[]>(ServiceKeys.Action, context.getHandler())
    const businessRoleCodes = this.reflector.get<string[]>(ServiceKeys.BusinessRole, context.getHandler())
    const userTypes = this.reflector.get<string[]>(ServiceKeys.UserType, context.getHandler())
    request.requestId = requestId
    return this.checkPermission(
      request,
      serviceActions,
      businessRoleCodes,
      userTypes,
      globalGuardLogs
    ).then((result: any) => {
      globalGuardLogs.push(`Execute time: ${(new Date()).getTime() - globalGuardStartAt.getTime()}`)
      console.log(`[GlobalGuard] execution logs: ${JSON.stringify(globalGuardLogs)}`)

      if (result.error) { throw result.error }

      if (!result.granted) {
        throw new ApolloError('Bạn không có quyền truy cập vào chức năng này', '403', {
          seviceCode: process.env.SERVICE_CODE,
          serviceAction: serviceActions
        })
      }

      return true
    })
  }
}
