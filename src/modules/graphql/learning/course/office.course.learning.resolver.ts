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
export class OfficeCourseLearningResolver {
    constructor(private readonly service: CourseLearningService) {}

    @Mutation(() => LearnCourse, {name: 'officeLearningCourseCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningCourseCreate(
        @Args('arguments', {nullable: false}) args: LearningCourseCreateInput,
    ): Promise<LearnCourse> {
        return this.service.create(args)
    }

    @Mutation(() => LearnCourse, {name: 'officeLearningCourseUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningCourseUpdate(
        @Args('arguments', {nullable: false}) args: LearningCourseUpdateInput,
    ): Promise<LearnCourse> {
        return this.service.update(args)
    }

    @Mutation(() => LearnCourse, {name: 'officeLearningCourseUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningCourseUpsert(
        @Args('arguments', {nullable: false}) args: LearningCourseUpsertInput,
    ): Promise<LearnCourse> {
        return this.service.upsert(args)
    }

    @Mutation(() => LearnCourse, {name: 'officeLearningCourseReOrderSection', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningCourseReOrderSection(
        @Args('arguments', {nullable: false}) args: LearningCourseReOrderSectionInput,
    ): Promise<LearnCourse> {
        return this.service.reOrderSection(args)
    }

    @Query(() => LearnCourse, {name: 'officeLearningCourseGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningCourseGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnCourse> {
        return this.service.get(id)
    }

    @Query(() => LearningCourseResponse, {name: 'officeLearningCourseList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeLearningCourseList(
        @Args('filter', {nullable: true}) filter: LearningCourseFilterInput,
    ): Promise<LearningCourseResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, {name: 'officeLearningCourseRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningCourseRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
