import { Field, InputType, Int } from "@nestjs/graphql";
import { LearnSkill } from "@models/entities";
import { Expose, Transform } from "class-transformer";
import {
    IsNameNotExistSkillLearningDbValidate
} from "@decorators/validation/db/learning/skill/is-name-not-exist.skill.learning.db.validate";
import {
    IsExistSkillLearningDbValidate
} from "@decorators/validation/db/learning/skill/is-exist.skill.learning.db.validate";
import { ValidateIf } from "class-validator";
import { DefaultFilterInput } from "@common/args.common";

@InputType()
export class LearningSkillCreateInput {
    @Field(_type => String, {nullable: false})
    @IsNameNotExistSkillLearningDbValidate()
    name: string
}

@InputType()
export class LearningSkillUpdateInput extends LearningSkillCreateInput {
    @Field(_type => String, { nullable: true })
    @IsExistSkillLearningDbValidate()
    skillId: string

    skill?: LearnSkill

    @Expose()
    @Transform(({obj}) => obj.skillId)
    IsNameNotExistSkillLearningDbValidate_skillId?: string = null
}

@InputType()
export class LearningSkillUpsertInput extends LearningSkillUpdateInput {
    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.skillId)
    @IsExistSkillLearningDbValidate()
    skillId: string
}

@InputType()
export class LearningSkillFilterInput extends DefaultFilterInput {}