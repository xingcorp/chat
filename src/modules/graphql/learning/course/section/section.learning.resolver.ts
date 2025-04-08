import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { LearnSection } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { SectionLearningService } from "@modules/graphql/learning/course/section/section.learning.service";
import {
    LearningSectionCreateInput, LearningSectionFilterInput, LearningSectionReOrderLessonInput,
    LearningSectionUpdateInput, LearningSectionUpsertInput
} from "@modules/graphql/learning/course/section/dto/section.learning.arg";
import { LearningSectionResponse } from "@modules/graphql/learning/course/section/dto/section.learning.response";

@Resolver()
export class SectionLearningResolver {
    constructor(private readonly service: SectionLearningService) { }

    @Mutation(() => LearnSection, { name: 'manageLearningSectionCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSectionCreate(
        @Args('arguments', { nullable: false }) args: LearningSectionCreateInput,
    ): Promise<LearnSection> {
        return this.service.create(args)
    }

    @Mutation(() => LearnSection, { name: 'manageLearningSectionUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSectionUpdate(
        @Args('arguments', { nullable: false }) args: LearningSectionUpdateInput,
    ): Promise<LearnSection> {
        return this.service.update(args)
    }

    @Mutation(() => LearnSection, { name: 'manageLearningSectionUpsert', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSectionUpsert(
        @Args('arguments', { nullable: false }) args: LearningSectionUpsertInput,
    ): Promise<LearnSection> {
        return this.service.upsert(args)
    }

    @Mutation(() => LearnSection, { name: 'manageLearningSectionReOrderLesson', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSectionReOrderLesson(
        @Args('arguments', { nullable: false }) args: LearningSectionReOrderLessonInput,
    ): Promise<LearnSection> {
        return this.service.reOrderLesson(args)
    }

    @Query(() => LearnSection, { name: 'manageLearningSectionGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSectionGet(
        @Args('id', { nullable: false }) id: string,
    ): Promise<LearnSection> {
        return this.service.get(id)
    }

    @Query(() => LearningSectionResponse, { name: 'manageLearningSectionList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageLearningSectionList(
        @Args('filter', { nullable: true }) filter: LearningSectionFilterInput,
    ): Promise<LearningSectionResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, { name: 'manageLearningSectionRemove', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSectionRemove(
        @Args('id', { nullable: false }) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
