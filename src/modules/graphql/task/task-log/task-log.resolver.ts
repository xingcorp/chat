import { Args, Mutation, Resolver } from '@nestjs/graphql';
import { OfficeTaskLog } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { OfficeRequesterId } from "@core/middleware/decorator/user.decorator";
import { ListDataOfOrg } from "@core/middleware/decorator/org-chart.decorator";
import { TaskService } from "@modules/graphql/task/task/task.service";
import { TaskLogService } from "@modules/graphql/task/task-log/task-log.service";
import { TaskCommentCreate, TaskCommentUpdate } from "@modules/graphql/task/task-log/dto/task-log.args";

@Resolver()
export class TaskLogResolver {

    constructor(
        private readonly taskLogService: TaskLogService,
    ) {
    }

    @Mutation(() => OfficeTaskLog, { name: 'officeTaskCommentCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskCommentCreate(
        @Args('arguments', { nullable: false }) args: TaskCommentCreate,
        @OfficeRequesterId() userId: string,
        @ListDataOfOrg('rootOrgId') rootOrgId: string,
    ): Promise<OfficeTaskLog> {
        return this.taskLogService.commentCreate({userId, rootOrgId}, args)
    }

    @Mutation(() => OfficeTaskLog, { name: 'officeTaskCommentUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserWChildInterceptor)
    async officeTaskCommentUpdate(
        @Args('arguments', { nullable: false }) args: TaskCommentUpdate,
        @OfficeRequesterId() userId: string,
    ): Promise<OfficeTaskLog> {
        return this.taskLogService.commentUpdate(userId, args)
    }
}
