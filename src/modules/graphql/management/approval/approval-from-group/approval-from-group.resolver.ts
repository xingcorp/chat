import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { ApprovalFormGroup } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import {
    ApprovalFromGroupService
} from "@modules/graphql/management/approval/approval-from-group/approval-from-group.service";
import {
    ApprovalFormGroupCreateInput,
    ApprovalFormGroupCreateUpdateInput,
    ApprovalFormGroupFilter
} from "@modules/graphql/management/approval/approval-from-group/dto/approval-form-group.args";
import {
    ApprovalFormGroupResponse
} from "@modules/graphql/management/approval/approval-from-group/dto/approval-form-group.response";

@Resolver()
export class ApprovalFromGroupResolver {
    constructor(private readonly fromGroupService: ApprovalFromGroupService) {
    }

    @Mutation(() => ApprovalFormGroup, {name: 'managerApprovalFormGroupCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerApprovalFormGroupCreate(
        @Args('arguments', {nullable: false}) args: ApprovalFormGroupCreateInput,
    ): Promise<ApprovalFormGroup> {
        return this.fromGroupService.create(args)
    }

    @Mutation(() => ApprovalFormGroup, {name: 'managerApprovalFormGroupUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerApprovalFormGroupUpdate(
        @Args('arguments', {nullable: false}) args: ApprovalFormGroupCreateUpdateInput,
    ): Promise<ApprovalFormGroup> {
        return this.fromGroupService.update(args)
    }

    @Query(() => ApprovalFormGroup, {name: 'managerApprovalFormGroupGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerApprovalFormGroupGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<ApprovalFormGroup> {
        return this.fromGroupService.get(id)
    }

    @Query(() => ApprovalFormGroupResponse, {name: 'managerApprovalFormGroupList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managerApprovalFormGroupList(
        @Args('filter', {nullable: true}) filter: ApprovalFormGroupFilter,
    ): Promise<ApprovalFormGroupResponse> {
        return this.fromGroupService.list(filter)
    }

    @Query(() => ApprovalFormGroupResponse, {name: 'officeApprovalFormGroupList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeApprovalFormGroupList(
        @Args('filter', {nullable: true}) filter: ApprovalFormGroupFilter,
    ): Promise<ApprovalFormGroupResponse> {
        return this.fromGroupService.list(filter)
    }

    @Mutation(() => String, {name: 'managerApprovalFormGroupRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async managerApprovalFormGroupRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.fromGroupService.remove(id)
    }
}
