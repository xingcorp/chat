import { Field, Float, ObjectType } from '@nestjs/graphql'
import { PolicyEffect } from './policy.effect'
import { PolicyService } from './policy.service'

@ObjectType()
export class PolicyAction {
    @Field(() => String)
    id: string

    @Field(() => PolicyService, { nullable: true })
    service: PolicyService

    @Field(() => PolicyEffect, { nullable: true })
    effect: PolicyEffect

    @Field(() => String, { nullable: true })
    name: string

    @Field(() => String, { nullable: true })
    code: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => PolicyAction, { nullable: true })
    parent: PolicyAction

    @Field(() => [PolicyAction], { nullable: true })
    children: PolicyAction[]

    @Field(() => Float, { nullable: true })
    createdAt: Date

    @Field(() => Float, { nullable: true })
    updatedAt: Date
}
