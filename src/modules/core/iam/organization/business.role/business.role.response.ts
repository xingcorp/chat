import { Field, Int, ObjectType } from '@nestjs/graphql'
import { BusinessRole } from '../../objects/business.role'
import { User } from '../../objects/user'

@ObjectType()
export class BusinessRoleResponse {
  @Field(() => Int, { defaultValue: 0 })
  total: number

  @Field(() => Int, { defaultValue: 0 })
  count: number

  @Field(() => [BusinessRole], { nullable: true })
  businessRoles?: BusinessRole[]
}

@ObjectType()
export class BusinessRoleUsers {
  @Field(() => Int, { defaultValue: 0 })
  total: number

  @Field(() => Int, { defaultValue: 0 })
  count: number

  @Field(() => [User], { nullable: true })
  users?: User[]
}
