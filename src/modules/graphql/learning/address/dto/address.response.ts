import { PagingData } from "@models/base/paging.response"
import { LearnAddress } from "@models/entities/learning/address.learn"
import { Field, ObjectType } from "@nestjs/graphql"

@ObjectType({ implements: PagingData })
export class LearningAddressResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [LearnAddress], { nullable: true })
    records?: LearnAddress[]
}