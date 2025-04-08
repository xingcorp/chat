import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { UserPaycheckService } from "@modules/graphql/management/user-paycheck/user-paycheck.service";
import { OfficeLogs, OfficeUserPaycheck } from "@models/entities";
import { ParseArrayPipe, SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { IsSystemOfficeAdmin, OfficeRequesterId, RequesterId } from "@core/middleware/decorator/user.decorator";
import {
    UserPaycheckBulkUpsertInput, UserPaycheckCommentCreate,
    UserPaycheckCreateInput, UserPaycheckListFilter,
    UserPaycheckUpdateInput
} from "@modules/graphql/management/user-paycheck/dto/user-paycheck.args";
import {
    UserPaycheckBulkUpsertResponse,
    UserPaycheckListResponse
} from "@modules/graphql/management/user-paycheck/dto/user-paycheck.response";
import { BearerAccessToken } from "@core/middleware/decorator/request.decorator";
import { FixedDataOrgChartUserWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { ListDataIdsOfOrg, ListUsersOfOrg } from "@core/middleware/decorator/org-chart.decorator";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { ValidateDataTypeBulkUpsertInterceptor } from "@interceptors/validate-data-type.interceptor";

@Resolver()
export class UserPaycheckResolver {
    constructor(private readonly userPaycheckService: UserPaycheckService) {
    }

    @Mutation(() => OfficeUserPaycheck, { name: 'managementUserPaycheckCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    async managementUserPaycheckCreate(
        @Args('arguments', { nullable: false }) args: UserPaycheckCreateInput,
        @RequesterId() requesterId: string,
        @BearerAccessToken() token: string,
    ): Promise<OfficeUserPaycheck> {
        return this.userPaycheckService.create(requesterId, args, token)
    }

    @Mutation(() => OfficeUserPaycheck, { name: 'managementUserPaycheckUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    async managementUserPaycheckUpdate(
        @Args('arguments', { nullable: false }) args: UserPaycheckUpdateInput,
        @RequesterId() requesterId: string,
        @BearerAccessToken() token: string,
    ): Promise<OfficeUserPaycheck> {
        return this.userPaycheckService.update(requesterId, args, token)
    }

    @Mutation(() => UserPaycheckBulkUpsertResponse, { name: 'managementUserPaycheckBulkUpsert', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ValidateDataTypeBulkUpsertInterceptor)
    async managementUserPaycheckBulkUpsert(
        @Args(
            'userPaychecks',
            {type: () => [UserPaycheckBulkUpsertInput]},
            new ParseArrayPipe({items: UserPaycheckBulkUpsertInput})
        ) args: UserPaycheckBulkUpsertInput[],
        @RequesterId() requesterId: string,
        @BearerAccessToken() token: string,
    ): Promise<UserPaycheckBulkUpsertResponse> {
        return this.userPaycheckService.bulkUpsert(requesterId, args, token)
    }

    @Query(() => OfficeUserPaycheck, { name: 'managementUserPaycheckGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async managementUserPaycheckGet(
        @Args('id', { nullable: false }) id: string,
        @ListUsersOfOrg('ids') userIds: any,
        @IsSystemOfficeAdmin() iSupperAdmin: boolean,
    ): Promise<OfficeUserPaycheck> {
        userIds = iSupperAdmin ? [] : userIds
        return this.userPaycheckService.getPaycheckOfUser(id, userIds)
    }

    @Query(() => UserPaycheckListResponse, { name: 'managementUserPaycheckList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async managementUserPaycheckList(
        @Args('filter', { nullable: true, defaultValue: { page: 1 }})  args: UserPaycheckListFilter,
        @RequesterId() requesterId: string,
        @ListUsersOfOrg('ids') userIds: any,
        @ListDataIdsOfOrg('listUsersOfOrgCustom') userIdsPicked: any,
        @IsSystemOfficeAdmin() iSupperAdmin: boolean,
    ): Promise<UserPaycheckListResponse> {

        userIds = iSupperAdmin ? [] : userIds

        const orgData = {
            userIds,
            userIdsPicked
        }

        return this.userPaycheckService.getListFilters(requesterId, args, orgData)
    }

    @Query(() => OfficeUserPaycheck, { name: 'officeUserPaycheckGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async officeUserPaycheckGet(
        @Args('id', { nullable: false }) id: string,
        @OfficeRequesterId() requesterId: string,
    ): Promise<OfficeUserPaycheck> {
        return this.userPaycheckService.officeGet(requesterId, id)
    }

    @Query(() => UserPaycheckListResponse, { name: 'officeUserPaycheckList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    async officeUserPaycheckList(
        @Args('filters', { nullable: false }) args: UserPaycheckListFilter,
        @OfficeRequesterId() requesterId: string,
    ): Promise<UserPaycheckListResponse> {
        return this.userPaycheckService.officeGetListFilters(requesterId, args)
    }

    @Mutation(() => OfficeUserPaycheck, { name: 'userPaycheckCommentCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async userPaycheckCommentCreate(
        @Args('arguments', { nullable: false }) args: UserPaycheckCommentCreate,
    ): Promise<OfficeUserPaycheck> {
        return this.userPaycheckService.commentCreate(args)
    }
}
