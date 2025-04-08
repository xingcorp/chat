import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { LearnSkill } from "@models/entities";

@ObjectType({ implements: PagingData })
export class LearningSkillResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [LearnSkill], { nullable: true })
    records?: LearnSkill[]
}