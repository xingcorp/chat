import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { LearnLesson } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { LessonLearningService } from './lesson.learning.service';
import { LearningLessonCreateInput, LearningLessonFilterInput, LearningLessonUpdateInput, LearningLessonUpsertInput } from './dto/lesson.learning.arg';
import { LearningLessonResponse } from './dto/lesson.learning.response';


@Resolver()
export class OfficeLessonLearningResolver {
    constructor(private readonly service: LessonLearningService) {}

    @Mutation(() => LearnLesson, {name: 'officeLearningLessonCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningLessonCreate(
        @Args('arguments', {nullable: false}) args: LearningLessonCreateInput,
    ): Promise<LearnLesson> {
        return this.service.create(args)
    }

    @Mutation(() => LearnLesson, {name: 'officeLearningLessonUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningLessonUpdate(
        @Args('arguments', {nullable: false}) args: LearningLessonUpdateInput,
    ): Promise<LearnLesson> {
        return this.service.update(args)
    }

    @Mutation(() => LearnLesson, {name: 'officeLearningLessonUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningLessonUpsert(
        @Args('arguments', {nullable: false}) args: LearningLessonUpsertInput,
    ): Promise<LearnLesson> {
        return this.service.upsert(args)
    }

    @Query(() => LearnLesson, {name: 'officeLearningLessonGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningLessonGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnLesson> {
        return this.service.get(id)
    }

    @Query(() => LearningLessonResponse, {name: 'officeLearningLessonList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeLearningLessonList(
        @Args('filter', {nullable: true}) filter: LearningLessonFilterInput,
    ): Promise<LearningLessonResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, {name: 'officeLearningLessonRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningLessonRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
