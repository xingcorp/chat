import { forwardRef, Inject } from '@nestjs/common'
import { Args, Mutation, Query, Resolver } from '@nestjs/graphql'
import { BearerAccessToken, CurrentRequest } from '../../middleware/decorator/request.decorator'
import { StorageService } from '../../storage/storage.service'
import { NotificationService } from '../notification/notification.service'
import { User } from '../objects/user'
import { OfficeOrgChart, OfficeUser, UserDepartment } from '../../../../models/entities'
import { AccessService } from '../access/access.service'
import {
  IdentityOrgDeviceArgs,
  UserLoginArgs,
  UserPasswordArgs,
} from './identity.arg'
import {
  OtpResponse,
  UserResponse,
  NotificationSubscribeResponse
} from './identity.response'
import { IdentityService } from './identity.service'
import { Request } from 'express'
import { CustomerService } from './customer.service'
import { OfficeError } from 'src/common/office.error'
import { ObjectStatus } from 'src/models/entities/profile.info.block'
import { validateEmail } from '@common/regex'
import { RandomHelper } from '@common/random'
import { RequestContext } from "@common/context/request.context";
import { IAMGraphQlClient } from "@core/iam/iam.client";
import { UserType } from "@core/middleware/guard/service.action";
import { RedisService } from "@core/common/redis.service";
import { CACHE_KEY } from "@common/cache-key.common";
import { RequesterId, RootOfficeOrganization } from "@core/middleware/decorator/user.decorator";
import { ApolloError } from "apollo-server-express";
import { OrganizationDevice } from '@models/entities/organization.device'
import { OrganizationDeviceStatus } from '@enum/device/device.enum'
import { In, IsNull } from 'typeorm'

@Resolver()
export class IdentityResolver {
  constructor(
    private readonly identityService: IdentityService,
    private readonly _customerService: CustomerService,
    private readonly _accessService: AccessService,
    private readonly _notificationService: NotificationService,
    private readonly iamClient: IAMGraphQlClient,

    @Inject(forwardRef(() => StorageService))
    private readonly storageService: StorageService,

    @Inject(forwardRef(() => RedisService))
    private readonly redisService: RedisService

    // @Inject(forwardRef(() => CrmUserService))
    // private readonly crmUserService: CrmUserService
  ) { }

  @Query(() => User, { name: 'identityProfile' })
  async profile(
    @CurrentRequest() request: Request,
    @BearerAccessToken() token: string,
    @Args('argument', { nullable: true }) argument: IdentityOrgDeviceArgs
  ): Promise<User> {
    const requestId = RandomHelper.generateUUID()
    const user = await this.identityService.userProfile(token, requestId)
    const officeUser = await OfficeUser.findOne({ where: { iamUserId: user.id } })
    const cacheKey = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + user.id
    const cacheKeyId = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + user.id + '__' + 'id'
    const cacheKeyName = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + user.id + '__' + 'name'
    const cacheKeyStatus = CACHE_KEY.USER.IDENTITY_PROFILE + '__' + user.id + '__' + 'status'

    const cached = await this.redisService.get(cacheKey)
    const cachedId = await this.redisService.get(cacheKeyId)
    const cachedName = await this.redisService.get(cacheKeyName)
    const cachedStatus = await this.redisService.get(cacheKeyStatus)


    if (cached && cachedId && cachedName && cachedStatus) {
      user.id = cachedId
      user.name = cachedName
      user.status = cachedStatus
      user.requestId = requestId
      user.organizationDevices = await OrganizationDevice.find({
        where: {
          userId: user.id,
          status: OrganizationDeviceStatus.APPROVED
        }
      })
      const checkOrg = await this.identityService.checkOrgOxi(user.id)
      if (checkOrg === true) {
        user.isCheckDeviceValidated = true
      } else {
        user.isCheckDeviceValidated = false
      }

      return user
    }

    console.log(`[Query]:[identityProfile]:[${requestId}] authorization: ${token}`)
    console.log(`[Query]:[identityProfile]:[${requestId}] iamUser: ${JSON.stringify(user)}`)
    if (user && user.id) {
      const officeUser = await OfficeUser.findOne({ where: { iamUserId: user.id } })
      if (officeUser) {
        user.id = officeUser.id
        user.name = officeUser.fullname
        user.status = officeUser.status
        user.requestId = requestId
        user.organizationDevices = await OrganizationDevice.find({
          where: {
            userId: user.id,
            status: OrganizationDeviceStatus.APPROVED
          }
        })
      } else {
        throw OfficeError.UserNotExist
      }
      const checkOrg = await this.identityService.checkOrgOxi(user.id)
      if (checkOrg === true) {
        user.isCheckDeviceValidated = true
      } else {
        user.isCheckDeviceValidated = false
      }


      await this.redisService.setWithTtl(cacheKey, user.id, 7 * 60 * 60)
      await this.redisService.setWithTtl(cacheKeyId, officeUser.id, 7 * 60 * 60)
      await this.redisService.setWithTtl(cacheKeyName, officeUser.fullname, 7 * 60 * 60)
      await this.redisService.setWithTtl(cacheKeyStatus, officeUser.status, 7 * 60 * 60)


    }
    console.log(`[Query]:[identityProfile]:[${requestId}] officeUser: ${JSON.stringify(user)}`)


    return user
  }

  // @Mutation(() => User, { nullable: true, name: 'identityProfileUpdate' })
  // async profileUpdate(
  //   @Args('arguments', { nullable: false }) args: UserInfoArgs,
  //   @CurrentRequest() request: Request
  // ): Promise<User> {
  //   return await this.identityService.forwardRequest(request)
  // }

  // @Mutation(() => UserResponse, { name: 'identityKarofiLogin', nullable: false })
  // async karofiLogin(
  //   @Args('credential', { nullable: false }) credential: UserLoginArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.login(
  //     credential.phone,
  //     credential.password,
  //     process.env.SERVICE_ID,
  //     process.env.KAROFI_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => UserResponse, { name: 'identityEcoLogin', nullable: false })
  // async ecoLogin(
  //   @Args('credential', { nullable: false }) credential: UserLoginArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.login(
  //     credential.phone,
  //     credential.password,
  //     process.env.SERVICE_ID,
  //     process.env.ECO_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => UserResponse, { name: 'identityDichvu3tLogin', nullable: false })
  // async dichvu3tLogin(
  //   @Args('credential', { nullable: false }) credential: UserLoginArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.login(
  //     credential.phone,
  //     credential.password,
  //     process.env.SERVICE_ID,
  //     process.env.DICHVU3T_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => UserResponse, { name: 'identitySteamLogin', nullable: false })
  // async steamLogin(
  //   @Args('credential', { nullable: false }) credential: UserLoginArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.login(
  //     credential.phone,
  //     credential.password,
  //     process.env.SERVICE_ID,
  //     process.env.STEAM_ORGANIZATION_ID
  //   )
  // }

  @Mutation(() => UserResponse, { name: 'identityOfficeLogin', nullable: false })
  async officeLogin(
    @Args('credential', { nullable: false }) credential: UserLoginArgs
  ): Promise<UserResponse> {
    return this.identityService.officeLogin(credential)
  }

  // @Mutation(() => OtpResponse, { name: 'identityKarofiRegister', nullable: false })
  // async karofiRegister(
  //   @Args('arguments', { nullable: false }) args: UserRegisterArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.register(
  //     args.name,
  //     args.phone,
  //     args.password,
  //     process.env.SERVICE_ID,
  //     process.env.KAROFI_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => OtpResponse, { name: 'identityEcoRegister', nullable: false })
  // async ecoRegister(
  //   @Args('arguments', { nullable: false }) args: UserRegisterArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.register(
  //     args.name,
  //     args.phone,
  //     args.password,
  //     process.env.SERVICE_ID,
  //     process.env.ECO_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => OtpResponse, { name: 'identityDichvu3tRegister', nullable: false })
  // async dichvu3tRegister(
  //   @Args('arguments', { nullable: false }) args: UserRegisterArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.register(
  //     args.name,
  //     args.phone,
  //     args.password,
  //     process.env.SERVICE_ID,
  //     process.env.DICHVU3T_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => OtpResponse, { name: 'identitySteamRegister', nullable: false })
  // async steamRegister(
  //   @Args('arguments', { nullable: false }) args: UserRegisterArgs
  // ): Promise<UserResponse> {
  //   return this.identityService.register(
  //     args.name,
  //     args.phone,
  //     args.password,
  //     process.env.SERVICE_ID,
  //     process.env.STEAM_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => OtpResponse, { name: 'identityKarofiPhoneChallenge', nullable: true })
  // async karofiPhoneChallenge(
  //   @Args('phone', { nullable: false }) phone: string
  // ): Promise<OtpResponse> {
  //   return this.identityService.challengeWithPhone(
  //     phone,
  //     process.env.SERVICE_ID,
  //     process.env.KAROFI_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => OtpResponse, { name: 'identityEcoPhoneChallenge', nullable: true })
  // async ecoPhoneChallenge(
  //   @Args('phone', { nullable: false }) phone: string
  // ): Promise<OtpResponse> {
  //   return this.identityService.challengeWithPhone(
  //     phone,
  //     process.env.SERVICE_ID,
  //     process.env.ECO_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => OtpResponse, { name: 'identityDichvu3tPhoneChallenge', nullable: true })
  // async dichvu3tPhoneChallenge(
  //   @Args('phone', { nullable: false }) phone: string
  // ): Promise<OtpResponse> {
  //   return this.identityService.challengeWithPhone(
  //     phone,
  //     process.env.SERVICE_ID,
  //     process.env.DICHVU3T_ORGANIZATION_ID
  //   )
  // }

  // @Mutation(() => OtpResponse, { name: 'identitySteamPhoneChallenge', nullable: true })
  // async steamPhoneChallenge(
  //   @Args('phone', { nullable: false }) phone: string
  // ): Promise<OtpResponse> {
  //   return this.identityService.challengeWithPhone(
  //     phone,
  //     process.env.SERVICE_ID,
  //     process.env.STEAM_ORGANIZATION_ID
  //   )
  // }

  @Mutation(() => OtpResponse, { name: 'identityOfficePhoneChallenge', nullable: true })
  async officePhoneChallenge(
    @Args('phone', { nullable: false }) phone: string
  ): Promise<OtpResponse> {
    if (validateEmail(phone)) {
      const existedEmail = await OfficeUser.findOne({
        where: {
          email: phone
        }
      })
      if (!existedEmail) throw OfficeError.OfficeUserWithEmailNotExisted
      return this.identityService.challengeWithPhone(
        existedEmail.phone,
        process.env.SERVICE_ID,
        process.env.OFFICE_ORGANIZATION_ID,
        phone,
      )
    }

    const existedPhone = await OfficeUser.findOne({
      where: {
        phone: phone
      }
    })
    if (!existedPhone) throw OfficeError.OfficeUserWithPhoneNotExisted
    return this.identityService.challengeWithPhone(
      phone,
      process.env.SERVICE_ID,
      process.env.OFFICE_ORGANIZATION_ID
    )
  }

  // @Mutation(() => UserResponse, { name: 'identityVerifyOtp', nullable: true })
  // async verifyOtp(
  //   @Args('session', { nullable: false }) _sessionBase64: string,
  //   @Args('otp', { nullable: false }) _otp: string,
  //   @CurrentRequest() request: Request
  // ): Promise<UserResponse> {
  //   return this.identityService.forwardRequest(request)
  // }

  // @Mutation(() => UserResponse, { name: 'identityLoginWithBusinessRole' })
  // async loginWithBusinessRole(
  //   @Args('businessRoleId', { nullable: false }) _businessRoleId: string,
  //   @CurrentRequest() request: Request
  // ): Promise<UserResponse> {
  //   return await this.identityService.forwardRequest(request)
  // }

  // @Mutation(() => UserResponse, { name: 'identityRegisterWithBusinessRole' })
  // async registerWithBusinessRole(
  //   @Args('businessRoleId', { nullable: false }) _businessRoleId: string,
  //   @Args('registerInfo') _registerInfo: RegisterBusinessRoleArgs,
  //   @CurrentRequest() request: Request
  // ): Promise<UserResponse> {
  //   return await this.identityService.forwardRequest(request)
  // }

  @Mutation(() => UserResponse, { name: 'identityRefreshToken', nullable: true })
  async refreshToken(
    @Args('refreshToken', { nullable: false }) _refreshTK: string,
    @CurrentRequest() request: Request
  ): Promise<UserResponse> {
    // return await this.identityService.forwardRequest(request)
    const result = await this.identityService.forwardRequest(request)
    if (result && result.user && result.user.id) {
      const officeUser = await OfficeUser.findOne({
        where: {
          iamUserId: result.user.id
        }
      })
      console.log(`[identityRefreshToken] officeUser: `, officeUser)
      if (officeUser) {
        result.user.id = officeUser.id
        result.user.name = officeUser.fullname
        result.user.status = officeUser.status
      }
    }

    return result
  }

  @Mutation(() => User, { name: 'identityLogout', nullable: true })
  async logout(@CurrentRequest() request: Request): Promise<User> {
    return await this.identityService.forwardRequest(request)
  }

  @Mutation(() => UserResponse, { name: 'identityVerifyForgotPassword', nullable: true })
  async verifyForgotPassword(
    @Args('session', { nullable: false }) _sessionBase64: string,
    @Args('otp', { nullable: false }) _otp: number,
    @CurrentRequest() request: Request
  ): Promise<UserResponse> {
    // return await this.identityService.forwardRequest(request)
    const result = await this.identityService.forwardRequest(request)
    if (result && result.user && result.user.id) {
      const officeUser = await OfficeUser.findOne({
        where: {
          iamUserId: result.user.id
        }
      })
      console.log(`[identityRefreshToken] officeUser: `, officeUser)
      if (officeUser) {
        result.user.id = officeUser.id
        result.user.name = officeUser.fullname
        result.user.status = officeUser.status
      }
    }

    return result
  }

  @Mutation(() => UserResponse, { name: 'identitySetPassword', nullable: true })
  async setPassword(
    @Args('password', { nullable: false }) _newPassword: string,
    @CurrentRequest() request: Request
  ): Promise<UserResponse> {
    // return await this.identityService.forwardRequest(request)
    const result = await this.identityService.forwardRequest(request)
    if (result && result.user && result.user.id) {
      const officeUser = await OfficeUser.findOne({
        where: {
          iamUserId: result.user.id
        }
      })
      console.log(`[identityRefreshToken] officeUser: `, officeUser)
      if (officeUser) {
        result.user.id = officeUser.id
        result.user.name = officeUser.fullname
        result.user.status = officeUser.status
      }
    }

    return result
  }

  @Mutation(() => UserResponse, { name: 'identityChangePassword' })
  async changePassword(
    @Args('arguments') _args: UserPasswordArgs,
    @CurrentRequest() request: Request
  ): Promise<User> {
    // return await this.identityService.forwardRequest(request)
    const { data, error } = await this.iamClient.getPermission(RequestContext.currentToken(), [])

    if (error) {
      throw OfficeError.SysUserNotExisted
    }

    if (data.userInfo.user.type === UserType.SYSTEM_USER) {
      const check = await this.identityService.sysLogin(
        data.userInfo.user.email,
        _args.oldPassword,
        process.env.SERVICE_ID,
        process.env.OFFICE_ORGANIZATION_ID
      )


      if (check.errors) return check
    }

    const result = await this.identityService.forwardRequest(request)
    if (result && result.user && result.user.id) {
      const officeUser = await OfficeUser.findOne({
        where: {
          iamUserId: result.user.id
        }
      })
      console.log(`[identityRefreshToken] officeUser: `, officeUser)
      if (officeUser) {
        result.user.id = officeUser.id
        result.user.name = officeUser.fullname
        result.user.status = officeUser.status
      }
    }

    return result
  }

  // @Mutation(() => User, { name: 'identityUploadAvatar' })
  // async uploadAvatar(
  //   @Args({ name: 'avatar', type: () => GraphQLUpload }) file: FileUpload,
  //   @BearerAccessToken() token: string
  // ) {
  //   const storageFile = await this.storageService.uploadFile(
  //     file,
  //     token,
  //     FileCleanType.Never,
  //     'avatar',
  //     process.env.SRT_IAM_MICROSERVICE_DOMAIN_CODE
  //   )

  //   const { data, error } = await this.identityService.updateAvatar(
  //     token,
  //     storageFile.id
  //   )
  //   if (error) throw error

  //   return data
  // }

  @Mutation(() => NotificationSubscribeResponse, { name: 'iamNotificationSubscribe' })
  async notificationSubscribe(
    @Args('deviceToken', { nullable: false }) _deviceToken: string,
    @CurrentRequest() request: Request
  ) {
    return await this.identityService.forwardRequest(request)
  }
}
