import { Args, Mutation, Query, Resolver } from '@nestjs/graphql';
import { SkillLearningService } from "@modules/graphql/learning/skill/skill.learning.service";
import { LearnSkill } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import {
    LearningSkillCreateInput, LearningSkillFilterInput,
    LearningSkillUpdateInput, LearningSkillUpsertInput
} from "@modules/graphql/learning/skill/dto/skill.learning.arg";
import { LearningSkillResponse } from "@modules/graphql/learning/skill/dto/skill.learning.response";

@Resolver()
export class SkillLearningResolver {
    constructor(private readonly service: SkillLearningService) {}

    @Mutation(() => LearnSkill, {name: 'manageLearningSkillCreate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSkillCreate(
        @Args('arguments', {nullable: false}) args: LearningSkillCreateInput,
    ): Promise<LearnSkill> {
        return this.service.create(args)
    }

    @Mutation(() => LearnSkill, {name: 'manageLearningSkillUpdate', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSkillUpdate(
        @Args('arguments', {nullable: false}) args: LearningSkillUpdateInput,
    ): Promise<LearnSkill> {
        return this.service.update(args)
    }

    @Mutation(() => LearnSkill, {name: 'manageLearningSkillUpsert', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSkillUpsert(
        @Args('arguments', {nullable: false}) args: LearningSkillUpsertInput,
    ): Promise<LearnSkill> {
        return this.service.upsert(args)
    }

    @Query(() => LearnSkill, {name: 'manageLearningSkillGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSkillGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnSkill> {
        return this.service.get(id)
    }

    @Query(() => LearningSkillResponse, {name: 'manageLearningSkillList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async manageLearningSkillList(
        @Args('filter', {nullable: true}) filter: LearningSkillFilterInput,
    ): Promise<LearningSkillResponse> {
        return this.service.list(filter)
    }

    @Mutation(() => String, {name: 'manageLearningSkillRemove', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async manageLearningSkillRemove(
        @Args('id', {nullable: false}) id: string,
    ): Promise<string> {
        return this.service.remove(id)
    }
}
