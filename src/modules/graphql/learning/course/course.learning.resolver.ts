import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { CourseLearningService } from "@modules/graphql/learning/course/course.learning.service";
import { LearnCourse } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import {
    LearningCourseCreateInput, LearningCourseFilterInput, LearningCourseReOrderSectionInput,
    LearningCourseUpdateInput, LearningCourseUpsertInput
} from "@modules/graphql/learning/course/dto/course.learning.arg";
import { LearningCourseResponse } from "@modules/graphql/learning/course/dto/course.learning.response";

@Resolver()
export class CourseLearningResolver {
    constructor(private readonly service: CourseLearningService) {}

    @Mutation(() => LearnCourse, {name: 'manageLearningCourseCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCourseCreate(
        @Args('arguments', {nullable: false}) args: LearningCourseCreateInput,
    ): Promise<LearnCourse> {
        return this.service.create(args)
    }

    @Mutation(() => LearnCourse, {name: 'manageLearningCourseUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCourseUpdate(
        @Args('arguments', {nullable: false}) args: LearningCourseUpdateInput,
    ): Promise<LearnCourse> {
        return this.service.update(args)
    }

    @Mutation(() => LearnCourse, {name: 'manageLearningCourseUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCourseUpsert(
        @Args('arguments', {nullable: false}) args: LearningCourseUpsertInput,
    ): Promise<LearnCourse> {
        return this.service.upsert(args)
    }

    @Mutation(() => LearnCourse, {name: 'manageLearningCourseReOrderSection', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCourseReOrderSection(
        @Args('arguments', {nullable: false}) args: LearningCourseReOrderSectionInput,
    ): Promise<LearnCourse> {
        return this.service.reOrderSection(args)
    }

    @Query(() => LearnCourse, {name: 'manageLearningCourseGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCourseGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnCourse> {
        return this.service.get(id)
    }

    @Query(() => LearningCourseResponse, {name: 'manageLearningCourseList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageLearningCourseList(
        @Args('filter', {nullable: true}) filter: LearningCourseFilterInput,
    ): Promise<LearningCourseResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, {name: 'manageLearningCourseRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningCourseRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
