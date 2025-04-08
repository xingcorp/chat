import { Args, Query, Resolver } from '@nestjs/graphql';
import { ProjectLearningService } from "@modules/graphql/learning/project/project.learning.service";
import { LearnProject } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { LearningProjectResponse } from "@modules/graphql/learning/project/dto/project.learning.response";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { LearningProjectFilterInput } from "@modules/graphql/learning/project/dto/project.learning.arg";

@Resolver()
export class OfficeProjectLearningResolver {
    constructor(private readonly service: ProjectLearningService) {
    }

    @Query(() => LearnProject, { name: 'officeLearningProjectGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningProjectGet(
        @Args('id', { nullable: false }) id: string,
    ): Promise<LearnProject> {
        return this.service.get(id)
    }

    @Query(() => LearningProjectResponse, { name: 'officeLearningProjectList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeLearningProjectList(
        @Args('filter', { nullable: true }) filter: LearningProjectFilterInput,
    ): Promise<LearningProjectResponse> {
        return this.service.list(filter)
    }
}
