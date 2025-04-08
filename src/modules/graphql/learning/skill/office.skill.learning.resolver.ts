import { Args, Query, Resolver } from '@nestjs/graphql';
import { SkillLearningService } from "@modules/graphql/learning/skill/skill.learning.service";
import { LearnSkill } from "@models/entities";
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FixedDataOrgChartUserAllAndWChildInterceptor } from "@interceptors/org-chart.interceptor";
import { LearningSkillResponse } from "@modules/graphql/learning/skill/dto/skill.learning.response";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { LearningSkillFilterInput } from "@modules/graphql/learning/skill/dto/skill.learning.arg";

@Resolver()
export class OfficeSkillLearningResolver {
    constructor(private readonly service: SkillLearningService) {}

    @Query(() => LearnSkill, {name: 'officeLearningSkillGet', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    async officeLearningSkillGet(
        @Args('id', {nullable: false}) id: string,
    ): Promise<LearnSkill> {
        return this.service.get(id)
    }

    @Query(() => LearningSkillResponse, {name: 'officeLearningSkillList', nullable: true})
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeLearningSkillList(
        @Args('filter', {nullable: true}) filter: LearningSkillFilterInput,
    ): Promise<LearningSkillResponse> {
        return this.service.list(filter)
    }

}
