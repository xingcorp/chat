import { ObjectType, Field, Int } from "@nestjs/graphql"
import { PolicyAction } from "../../objects/policy.action"

@ObjectType()
export class PolicyActionResponse {
    @Field(() => Int, { defaultValue: 0 })
    total: number

    @Field(() => Int, { defaultValue: 0 })
    count: number

    @Field(() => [PolicyAction], { nullable: true })
    actions?: PolicyAction[]
}
