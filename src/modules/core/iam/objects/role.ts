import { Field, ObjectType } from '@nestjs/graphql'
import { Permission } from './permission'
import { Policy } from './policy'

@ObjectType()
export class Role {
  @Field(() => String, { nullable: true })
  id: string

  @Field(() => String, { nullable: true })
  name: string

  @Field(() => Boolean, { nullable: true })
  readonly: boolean

  @Field(() => String, { nullable: true })
  description: string

  @Field(() => [Permission], { nullable: true })
  permissions: Permission[]

  @Field(() => [Policy], { nullable: true })
  policies: Policy[]
}
