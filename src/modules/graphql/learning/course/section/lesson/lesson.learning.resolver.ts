import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { LearnLesson } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { LearningLessonCreateInput, LearningLessonFilterInput, LearningLessonUpdateInput, LearningLessonUpsertInput } from './dto/lesson.learning.arg';
import { LessonLearningService } from './lesson.learning.service';
import { LearningLessonResponse } from './dto/lesson.learning.response';


@Resolver()
export class LessonLearningResolver {
    constructor(private readonly service: LessonLearningService) {}

    @Mutation(() => LearnLesson, {name: 'manageLearningLessonCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningLessonCreate(
        @Args('arguments', {nullable: false}) args: LearningLessonCreateInput,
    ): Promise<LearnLesson> {
        return this.service.create(args)
    }

    @Mutation(() => LearnLesson, {name: 'manageLearningLessonUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningLessonUpdate(
        @Args('arguments', {nullable: false}) args: LearningLessonUpdateInput,
    ): Promise<LearnLesson> {
        return this.service.update(args)
    }

    @Mutation(() => LearnLesson, {name: 'manageLearningLessonUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningLessonUpsert(
        @Args('arguments', {nullable: false}) args: LearningLessonUpsertInput,
    ): Promise<LearnLesson> {
        return this.service.upsert(args)
    }

    @Query(() => LearnLesson, {name: 'manageLearningLessonGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningLessonGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnLesson> {
        return this.service.get(id)
    }

    @Query(() => LearningLessonResponse, {name: 'manageLearningLessonList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageLearningLessonList(
        @Args('filter', {nullable: true}) filter: LearningLessonFilterInput,
    ): Promise<LearningLessonResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, {name: 'manageLearningLessonRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningLessonRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
