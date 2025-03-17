import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { ProjectLearningService } from "@modules/graphql/learning/project/project.learning.service";
import { LearnProject } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import {
    LearningProjectCreateInput, LearningProjectFilterInput,
    LearningProjectUpdateInput, LearningProjectUpsertInput
} from "@modules/graphql/learning/project/dto/project.learning.arg";
import { LearningProjectResponse } from './dto/project.learning.response';

@Resolver()
export class ProjectLearningResolver {
    constructor(private readonly service: ProjectLearningService) {
    }

    @Mutation(() => LearnProject, { name: 'manageLearningProjectCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningProjectCreate(
        @Args('arguments', { nullable: false }) args: LearningProjectCreateInput,
    ): Promise<LearnProject> {
        return this.service.create(args)
    }

    @Mutation(() => LearnProject, { name: 'manageLearningProjectUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningProjectUpdate(
        @Args('arguments', { nullable: false }) args: LearningProjectUpdateInput,
    ): Promise<LearnProject> {
        return this.service.update(args)
    }

    @Mutation(() => LearnProject, {name: 'manageLearningProjectUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningProjectUpsert(
        @Args('arguments', {nullable: false}) args: LearningProjectUpsertInput,
    ): Promise<LearnProject> {
        return this.service.upsert(args)
    }

    @Query(() => LearnProject, { name: 'manageLearningProjectGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningProjectGet(
        @Args('id', { nullable: false }) id: string,
    ): Promise<LearnProject> {
        return this.service.get(id)
    }

    @Query(() => LearningProjectResponse, { name: 'manageLearningProjectList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageLearningProjectList(
        @Args('filter', { nullable: true }) filter: LearningProjectFilterInput,
    ): Promise<LearningProjectResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, { name: 'manageLearningProjectRemove', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningProjectRemove(
        @Args('id', { nullable: false }) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
