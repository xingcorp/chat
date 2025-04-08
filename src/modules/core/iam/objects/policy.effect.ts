import { Field, Float, ObjectType } from '@nestjs/graphql'

@ObjectType()
export class PolicyEffect {
    @Field(() => String)
    id: string

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
