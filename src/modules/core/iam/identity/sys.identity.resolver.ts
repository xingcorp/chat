import { forwardRef, Inject } from '@nestjs/common'
import { Args, Mutation, Resolver } from '@nestjs/graphql'
import { CurrentRequest } from '../../middleware/decorator/request.decorator'
import { CmsUserLoginArgs } from './identity.arg'
import { UserResponse } from './identity.response'
import { IdentityService } from './identity.service'

@Resolver()
export class SysIdentityResolver {
  constructor(
    @Inject(forwardRef(() => IdentityService))
    private readonly identityService: IdentityService
  ) {}

  // //Login for system user
  // @Mutation(() => UserResponse, { name: "identitySysLogin" })
  // async identitySysLogin(
  //     @Args("credential", { nullable: false }) _credential: SysUserLoginArgs,
  //     @CurrentRequest() request: Request
  // ): Promise<UserResponse> {
  //     return await this.identityService.forwardRequest(request)
  // }

  // @Mutation(() => User, { name: "identitySysLogout", nullable: true })
  // async sysLogout(
  //     @CurrentRequest() request: Request
  // ): Promise<User | null> {
  //     return await this.identityService.forwardRequest(request)
  // }

  //Login for system user
  @Mutation(() => UserResponse, { name: "identitySysLogin" })
  async identitySysLogin(
      @Args("credential", { nullable: false }) credential: CmsUserLoginArgs,
      @CurrentRequest() request: Request
  ): Promise<UserResponse> {
      // return this.identityService.forwardRequest(request)
      return this.identityService.sysLogin(
          credential.email,
          credential.password,
          process.env.SERVICE_ID,
          process.env.OFFICE_ORGANIZATION_ID
      )
  }
}
