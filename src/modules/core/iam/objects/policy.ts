import { Field, Float, ObjectType } from '@nestjs/graphql'
import { PolicyAction } from './policy.action'
import { PolicyEffect } from './policy.effect'
import { PolicyService } from './policy.service'

@ObjectType()
export class Policy {
    @Field(() => String)
    id: string

    @Field(() => PolicyService, { nullable: true })
    service: PolicyService

    @Field(() => PolicyEffect, { nullable: true })
    effect: PolicyEffect

    @Field(() => [PolicyAction], { nullable: true })
    actions: PolicyAction[]

    @Field(() => String, { nullable: true })
    condition: string

    @Field(() => Float, { nullable: true })
    createdAt: Date

    @Field(() => Float, { nullable: true })
    updatedAt: Date
}
