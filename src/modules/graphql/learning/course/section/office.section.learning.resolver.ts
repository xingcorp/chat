import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { SectionLearningService } from "@modules/graphql/learning/course/section/section.learning.service";
import { LearnSection } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import {
    LearningSectionCreateInput, LearningSectionFilterInput, LearningSectionReOrderLessonInput,
    LearningSectionUpdateInput, LearningSectionUpsertInput
} from "@modules/graphql/learning/course/section/dto/section.learning.arg";
import { LearningSectionResponse } from "@modules/graphql/learning/course/section/dto/section.learning.response";

@Resolver()
export class OfficeSectionLearningResolver {
    constructor(private readonly service: SectionLearningService) { }

    @Mutation(() => LearnSection, { name: 'officeLearningSectionCreate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningSectionCreate(
        @Args('arguments', { nullable: false }) args: LearningSectionCreateInput,
    ): Promise<LearnSection> {
        return this.service.create(args)
    }

    @Mutation(() => LearnSection, { name: 'officeLearningSectionUpdate', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningSectionUpdate(
        @Args('arguments', { nullable: false }) args: LearningSectionUpdateInput,
    ): Promise<LearnSection> {
        return this.service.update(args)
    }

    @Mutation(() => LearnSection, { name: 'officeLearningSectionUpsert', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningSectionUpsert(
        @Args('arguments', { nullable: false }) args: LearningSectionUpsertInput,
    ): Promise<LearnSection> {
        return this.service.upsert(args)
    }

    @Mutation(() => LearnSection, { name: 'officeLearningSectionReOrderLesson', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningSectionReOrderLesson(
        @Args('arguments', { nullable: false }) args: LearningSectionReOrderLessonInput,
    ): Promise<LearnSection> {
        return this.service.reOrderLesson(args)
    }

    @Query(() => LearnSection, { name: 'officeLearningSectionGet', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningSectionGet(
        @Args('id', { nullable: false }) id: string,
    ): Promise<LearnSection> {
        return this.service.get(id)
    }

    @Query(() => LearningSectionResponse, { name: 'officeLearningSectionList', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeLearningSectionList(
        @Args('filter', { nullable: true }) filter: LearningSectionFilterInput,
    ): Promise<LearningSectionResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, { name: 'officeLearningSectionRemove', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningSectionRemove(
        @Args('id', { nullable: false }) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
