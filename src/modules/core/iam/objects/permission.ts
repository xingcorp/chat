import { Field, ObjectType } from '@nestjs/graphql'
import { Policy } from './policy'

@ObjectType()
export class Permission {
    @Field(() => String, { nullable: true })
    name: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => [Policy], { nullable: true })
    policies: Policy[]
}
