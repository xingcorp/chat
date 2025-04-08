import { Field, Int, InterfaceType } from "@nestjs/graphql";

@InterfaceType()
export abstract class PagingData {
    @Field(_type => Int, { defaultValue: 0 })
    total: number

    @Field(_type => Int, { defaultValue: 0 })
    count: number
}