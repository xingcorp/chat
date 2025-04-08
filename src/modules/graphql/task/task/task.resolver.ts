import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { TaskService } from "@modules/graphql/task/task/task.service";
import { OfficeFilter, OfficeOrgChart, OfficeTask } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import {  OfficeRequesterId } from "@core/middleware/decorator/user.decorator";
import {
    TaskCreateInput, TaskFilterCreateInput, TaskFilterList, TaskFilterUpdateInput,
    TaskListFilter, TaskReportConfigList,
    TaskStatusUpdateInput,
    TaskUpdateInput
} from "@modules/graphql/task/task/dto/task.args";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import {
    FixedDataOrgChartUserAllAndWChildInterceptor,
    FixedDataOrgChartUserWChildInterceptor
} from "@interceptors/org-chart.interceptor";
import { ListDataOfOrg } from "@core/middleware/decorator/org-chart.decorator";
import { OfficeTaskListResponse, TaskFilterListResponse } from "@modules/graphql/task/task/dto/task.response";
import { BearerAccessToken } from "@core/middleware/decorator/request.decorator";

@Resolver()
export class TaskResolver {
    constructor(private readonly taskService: TaskService) {
    }

    @Mutation(() => OfficeTask, { name: 'officeTaskCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskCreate(
        @Args('arguments', { nullable: false }) args: TaskCreateInput,
        @OfficeRequesterId() userId: string,
        @ListDataOfOrg('rootOrg') rootOrg: OfficeOrgChart,
        @BearerAccessToken() token: string,
    ): Promise<OfficeTask> {
        return this.taskService.create({userId, rootOrg, token}, args)
    }

    @Mutation(() => OfficeTask, { name: 'officeTaskUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskUpdate(
        @Args('arguments', { nullable: false }) args: TaskUpdateInput,
        @OfficeRequesterId() userId: string,
        @ListDataOfOrg('rootOrg') rootOrg: OfficeOrgChart,
        @BearerAccessToken() token: string,
    ): Promise<OfficeTask> {
        return this.taskService.update({userId, rootOrg, token}, args)
    }

    @Mutation(() => OfficeTask, { name: 'officeTaskStatusUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskStatusUpdate(
        @Args('arguments', { nullable: false }) args: TaskStatusUpdateInput,
    ): Promise<OfficeTask> {
        return this.taskService.statusUpdate(args)
    }

    @Query(() => OfficeTaskListResponse, { name: 'officeTaskList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskList(
        @Args('filter', { nullable: true, defaultValue: { page: 1 }}) args: TaskListFilter,
        @OfficeRequesterId() userId: string,
        @ListDataOfOrg('rootOrg') rootOrg: OfficeOrgChart,
    ): Promise<OfficeTaskListResponse> {
        return this.taskService.list({userId, rootOrg}, args)
    }

    @Query(() => OfficeTask, { name: 'officeTaskGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskGet(
        @Args('id', { nullable: false }) id: string,
        @OfficeRequesterId() userId: string,
        @ListDataOfOrg('rootOrg') rootOrg: OfficeOrgChart,
    ): Promise<OfficeTask> {
        return this.taskService.get({userId, rootOrg}, id)
    }

    @Query(() => OfficeTaskListResponse, { name: 'officeTaskReportConfigList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskReportConfigList(
        @Args('filter', { nullable: true }) args: TaskReportConfigList,
    ): Promise<OfficeTaskListResponse> {
        return this.taskService.reportConfigList(args)
    }

    @Mutation(() => OfficeFilter, { name: 'officeTaskFilterCreate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeTaskFilterCreate(
        @Args("args", { nullable: true }) args: TaskFilterCreateInput,
    ) : Promise<OfficeFilter> {
        return this.taskService.taskFilterCreate(args)
    }

    @Mutation(() => OfficeFilter, { name: 'officeTaskFilterUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeTaskFilterUpdate(
        @Args("args", { nullable: true }) args: TaskFilterUpdateInput,
    ) : Promise<OfficeFilter> {
        return this.taskService.taskFilterUpdate(args)
    }

    @Mutation(() => OfficeFilter, { name: 'officeTaskFilterRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeTaskFilterRemove(
        @Args("id", { nullable: true }) id: string,
    ) : Promise<OfficeFilter> {
        return this.taskService.taskFilterRemove(id)
    }

    @Query(() => OfficeFilter, { name: "officeTaskFilterGet"})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeTaskFilterGet(
        @Args("id", { nullable: true }) id: string,
    ) : Promise<OfficeFilter> {
        return this.taskService.taskFilterGet(id)
    }

    @Query(() => TaskFilterListResponse, { name: "officeTaskFilterList"})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeTaskFilterList(
        @Args("filter", { nullable: true }) filter: TaskFilterList,
    ) : Promise<TaskFilterListResponse> {
        return this.taskService.taskFilterList(filter)
    }
}
