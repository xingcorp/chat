import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";

@ObjectType()
export class IdentifyCardPlaceResponse {
    @Field(_type => String, {nullable: true})
    title: string

    @Field(_type => String, {nullable: true})
    value: string
}

@ObjectType({ implements: PagingData })
export class IdentifyCardPlaceListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [IdentifyCardPlaceResponse], { nullable: true })
    records?: IdentifyCardPlaceResponse[]
}