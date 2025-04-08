import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { LearnSection } from "@models/entities";

@ObjectType({ implements: PagingData })
export class LearningSectionResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [LearnSection], { nullable: true })
    records?: LearnSection[]
}