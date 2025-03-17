import { Parent, ResolveField, Resolver } from "@nestjs/graphql";
import {
    LearnSkill,
} from "@models/entities";
import { SkillLearningRepo } from "@models/repositories";

@Resolver(_of => LearnSkill)
export class LearnSkillResolver {
    constructor(
        private skillLearningRepo: SkillLearningRepo,
    ) {
    }

    @ResolveField('parent', _return => LearnSkill, { nullable: true })
    async parentOrg(
        @Parent() root: LearnSkill
    ) {
        if (root.parentId !== 'root') {
            return this.skillLearningRepo.findOne({
                where: {
                    id: root.parentId
                }
            })
        }

        return null
    }
}