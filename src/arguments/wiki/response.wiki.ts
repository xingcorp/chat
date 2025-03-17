import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { DocumentWiki } from "@models/entities";

@ObjectType({ implements: PagingData })
export class DocumentWikiListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [DocumentWiki], { nullable: true })
    records?: DocumentWiki[]
}