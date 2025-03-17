import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { CategoryWiki } from "@models/entities";

@ObjectType({ implements: PagingData })
export class CategoryWikiResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [CategoryWiki], { nullable: true })
    records?: CategoryWiki[]
}