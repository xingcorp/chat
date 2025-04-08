import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { AdminService } from "@modules/graphql/management/admin/admin.service";
import { OfficeSysUser } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { UserLoginArgs } from "@core/iam/identity/identity.arg";
import { RequestContext } from "@common/context/request.context";

@Resolver()
export class AdminResolver {

    constructor(private readonly adminService: AdminService) {
    }

    @Mutation(() => OfficeSysUser, {name: 'manageAdminLinkWithUser', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageAdminLinkWithUser(
        @Args('credential', { nullable: false }) credential: UserLoginArgs
    ): Promise<OfficeSysUser> {
        return this.adminService.linkWithUser(credential)
    }

    @Mutation(() => OfficeSysUser, {name: 'manageAdminUnlinkUser', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async manageAdminUnlinkUser(): Promise<OfficeSysUser> {
        return this.adminService.unlinkUser()
    }

    @Query(() => OfficeSysUser, {name: 'manageAdminInfoGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async manageAdminInfoGet(): Promise<OfficeSysUser> {
        return RequestContext.currentAdmin()
    }
}
