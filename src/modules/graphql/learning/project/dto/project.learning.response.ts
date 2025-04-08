import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { LearnProject } from "@models/entities";

@ObjectType({ implements: PagingData })
export class LearningProjectResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [LearnProject], { nullable: true })
    records?: LearnProject[]
}