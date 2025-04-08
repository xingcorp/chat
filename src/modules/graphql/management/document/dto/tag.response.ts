import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { TagDocument } from "@models/entities";

@ObjectType({ implements: PagingData })
export class DocumentTagResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [TagDocument], { nullable: true })
    records?: TagDocument[]
}