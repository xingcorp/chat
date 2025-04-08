import { forwardRef, Inject, Injectable } from '@nestjs/common'
import { CRMError } from 'src/common/crm.error'
import { GraphQLClient } from '../../common/graphql.client'
import { IdentitySchema, IdentitySysSchema } from './identity.shema'
import { OfficeOrgChart, OfficeUser, UserDepartment } from "@models/entities";
import { OfficeError } from "@common/office.error";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { IdentityOrgDeviceArgs, UserLoginArgs } from "@core/iam/identity/identity.arg";
import { OrganizationDevice } from '@models/entities/organization.device'
import { In, IsNull } from 'typeorm'
import { OrganizationDeviceStatus } from '@enum/device/device.enum'
import { RequestContext } from "@common/context/request.context";

@Injectable()
export class IdentityService extends GraphQLClient {
  constructor(
  ) {
    super(process.env.SRT_IAM_MICROSERVICE_DOMAIN)
  }

  public async challengeWithPhone(
    phone: string,
    serviceId: string,
    organizationId: string,
    email?: string
  ) {
    return await this.sendMutationThrowError(null, IdentitySchema.PHONE_CHALLENGE, {
      phone: phone,
      email: email,
      serviceId: serviceId,
      organizationId: organizationId
    })
  }

  public async register(
    name: string,
    phone: string,
    password: string,
    serviceId: string,
    orgId: string
  ) {
    return await this.sendMutationThrowError(null, IdentitySchema.IDENTITY_REGISTER, {
      name: name,
      phone: phone,
      password: password,
      serviceId: serviceId,
      organizationId: orgId
    })
  }

  public async login(
    phone: string,
    password: string,
    serviceId: string,
    orgId: string
  ) {
    const result = await this.sendMutationThrowError(null, IdentitySchema.PHONE_LOGIN, {
      phone: phone,
      password: password,
      serviceId: serviceId,
      organizationId: orgId
    })

    // if (result.user && result.user.id) {
    //   const crmUser = await this.userService.findByIamId(result.user.id)
    //   if (crmUser && crmUser.status !== UserStatus.Active) {
    //     throw CRMError.CrmUserInactive
    //   }
    // }

    return result
  }

  public async sysLogin(
    email: string,
    password: string,
    serviceId: string,
    orgId: string
  ) {
    return await this.sendMutationThrowError(null, IdentitySysSchema.SYS_LOGIN, {
      email: email,
      password: password,
      serviceId: serviceId,
      organizationId: orgId
    })
  }

  public async sysProfile(
    token: string
  ) {
    return await this.sendQueryThrowError(token, IdentitySysSchema.SYS_PROFILE, null)
  }

  public async userProfile(
    token: string,
    requestId: string
  ) {
    return await this.sendQueryThrowError(token, IdentitySysSchema.USER_PROFILE_WITH_REQUEST_ID, { requestId: requestId })
  }

  public async subscribedUser(
    token: string,
    userId: string
  ) {
    return await this.sendQueryThrowError(token, IdentitySchema.FIND_SUBSCRIBED_USER, {
      userId: userId
    })
  }

  public async userFindById(bearerToken, userId: string) {
    return this.sendMutation(bearerToken, IdentitySchema.FIND_USER_BY_ID, {
      userId: userId
    })
  }

  public async updateAvatar(bearerToken: string, fileId: string) {
    return this.sendMutation(bearerToken, IdentitySchema.UPDATE_AVATAR, { fileId: fileId })
  }

  public async sysUserCreate(
    token: string,
    fullname: string,
    email: string,
    password: string,
    phone: string,
    phones: string[],
    addressZoneId: string,
    address: string
  ) {
    return await this.sendMutation(
      token,
      IdentitySysSchema.SYS_USER_CREATE,
      {
        arguments: {
          fullname: fullname,
          email: email,
          password: password,
          phone: phone,
          phones: phones,
          addressZoneId: addressZoneId,
          address: address
        }
      }
    )
  }

  public async sysUserUpdate(
    token: string,
    iamUserId: string,
    fullname: string,
    phone: string,
    phones: string[],
    addressZoneId: string,
    address: string
  ) {
    return await this.sendMutation(
      token,
      IdentitySysSchema.SYS_USER_UPDATE,
      {
        arguments: {
          userId: iamUserId,
          fullname: fullname,
          phone: phone,
          phones: phones,
          addressZoneId: addressZoneId,
          address: address
        }
      }
    )
  }

  public async sysUserFindById(bearerToken, userId: string) {
    return this.sendMutation(
      bearerToken,
      IdentitySchema.FIND_USER_BY_ID,
      { userId: userId }
    )
  }

  public async sysChangePassword(
    bearerToken: string,
    oldPassword: string,
    newPassword: string
  ) {
    return this.sendMutationThrowError(
      bearerToken,
      IdentitySysSchema.SYS_CHANGE_PASSWORD,
      {
        arguments: {
          oldPassword: oldPassword,
          newPassword: newPassword
        }
      }
    )
  }

  public async sysLogout(bearerToken: string) {
    return this.sendMutationThrowError(
      bearerToken,
      IdentitySysSchema.SYS_LOGOUT
    )
  }

  public async sysRefreshToken(bearerToken: string, refreshToken: string) {
    return this.sendMutationThrowError(
      bearerToken,
      IdentitySysSchema.SYS_REFRESH_TOKEN,
      { token: refreshToken }
    )
  }

  public async sysSetPassword(bearerToken: string, userId: string, password: string) {
    return this.sendMutationThrowError(
      bearerToken,
      IdentitySysSchema.SYS_SET_PASSWORD,
      {
        arguments: {
          userId: userId,
          password: password
        }
      }
    )
  }

  public async userCreate(
    token: string,
    fullname: string,
    email: string,
    phone: string
  ) {
    return await this.sendMutation(
      token,
      IdentitySysSchema.USER_CREATE,
      {
        arguments: {
          fullname: fullname,
          email: email,
          phone: phone,
          serviceId: process.env.SERVICE_ID,
          organizationId: process.env.OFFICE_ORGANIZATION_ID
        }
      }
    )
  }

  public async getBankDetail(id: string) {
    return await this.sendQueryThrowError(
      null,
      IdentitySysSchema.FIND_BANK_BY_ID,
      {
        id: id
      }
    )
  }

  public async getBankDetailByName(name: string) {
    return await this.sendQuery(
      null,
      IdentitySysSchema.FIND_BANK_BY_NAME,
      {
        name: name
      }
    )
  }

    async officeLogin(credential: UserLoginArgs) {
        const officeUser = await OfficeUser.findOne({
            where: {
                phone: credential.phone
            }
        })
        if (!officeUser) throw OfficeError.AccountNotExisted
        if (officeUser.status === ObjectStatus.Inactive) throw OfficeError.InactivedAccount
        const result = await this.login(
            credential.phone,
            credential.password,
            process.env.SERVICE_ID,
            process.env.OFFICE_ORGANIZATION_ID
        )

        // if (credential.identifierForVendor) {
        //   await this.identityService.registerOrganizationDevice(credential.name , credential.model , credential.identifierForVendor , officeUser.id)
        //   const approvedDevice = await OrganizationDevice.findOne({
        //     where: {
        //       user: {id:officeUser.id},
        //       identifierForVendor: credential.identifierForVendor,
        //       status: OrganizationDeviceStatus.APPROVED
        //     }
        //   });

        //   if (!approvedDevice) {
        //     throw OfficeError.DeviceNotApprovedThisAccount
        //   }
        // }

        if (result && result.user) {
            result.user.id = officeUser.id
            result.user.name = officeUser.fullname
            result.user.status = officeUser.status

            officeUser.lastLoginAt = new Date()
            await officeUser.save()
        }

        return result
    }

    public async deleteSessionTokenUserInActive(userId: string) {
        return this.sendMutationWithSecret(IdentitySysSchema.REMOVE_USER_TOKEN_BY_SECRET, {
            arguments: {
                userId,
                serviceId: process.env.SERVICE_ID,
                organizationId: process.env.OFFICE_ORGANIZATION_ID
            }
        })
    }

    async getAdminEnvToken() {
        const admin = await this.sysLogin(
            process.env.ADMIN_EMAIL,
            process.env.ADMIN_PASS,
            process.env.SERVICE_ID,
            process.env.OFFICE_ORGANIZATION_ID
        )

        return `Bearer ${admin?.accessToken}`
    }

  public async checkOrgOxi(userId: string): Promise<boolean> {
    const userDepartments = await UserDepartment.find({
      where: {
        userId: userId
      }
    })

    let rootIds = []
    const departments = await OfficeOrgChart.find({
      where: {
        id: In(userDepartments.map(ud => ud.departmentId))
      }
    })
    for (const dept of departments) {
      const root = dept.path.split("/")[1]
      if (!rootIds.includes(root)) rootIds.push(root)
    }
    if (rootIds.includes(process.env.OXII_ORG_ID)) {
      return true
    } else {
      return false
    }
  }

}
