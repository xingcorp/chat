import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import GraphQLJSON from "graphql-type-json";

@ObjectType({ implements: PagingData })
export class OfficeChatMessageSearchResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [GraphQLJSON], { nullable: true })
    records?: any[]
}

@ObjectType()
export class OfficeChatLinkPreviewResponse {
    @Field(_type => Boolean, { nullable: true })
    success: boolean

    @Field(_type => GraphQLJSON, { nullable: true })
    data?: any
}