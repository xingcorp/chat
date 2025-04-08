import { Field, Float, ObjectType } from '@nestjs/graphql'

@ObjectType()
export class PolicyService {
    @Field(() => String)
    id: string

    @Field(() => PolicyService, { nullable: true })
    parent: PolicyService

    @Field(() => String, { nullable: true })
    name: string

    @Field(() => String, { nullable: true })
    code: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => Float, { nullable: true })
    createdAt: Date

    @Field(() => Float, { nullable: true })
    updatedAt: Date
}
