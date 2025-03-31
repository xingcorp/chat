import { Field, Float, Int, ObjectType } from '@nestjs/graphql'
import { Bank } from '../objects/bank'
import { BusinessRole } from '../objects/business.role'
import { Carrier } from '../objects/carrier'
import { User } from '../objects/user'

@ObjectType()
export class UserResponse {
  @Field({ nullable: true })
  accessToken?: string

  @Field({ nullable: true })
  refreshToken?: string

  @Field({ nullable: true })
  loggedInTime?: number

  @Field(() => User, { nullable: true, defaultValue: null })
  user?: User

  @Field(() => [BusinessRole], { nullable: true, defaultValue: null })
  avaiableBusinessRoles?: BusinessRole[]
}

@ObjectType()
export class BankResponse {
  @Field(() => Int, { defaultValue: 0 })
  total: number

  @Field(() => Int, { defaultValue: 0 })
  count: number

  @Field(() => [Bank], { nullable: true })
  banks?: Bank[]
}

@ObjectType()
export class CarrierResponse {
  @Field(() => Int, { defaultValue: 0 })
  total: number

  @Field(() => Int, { defaultValue: 0 })
  count: number

  @Field(() => [Carrier], { nullable: true })
  carriers?: Carrier[]
}

@ObjectType()
export class OtpResponse {
  @Field(() => String, { nullable: false })
  target: string

  @Field(() => String, { nullable: false })
  session: string

  @Field(() => String, { nullable: false })
  organization: string
}

@ObjectType()
export class NotificationSubscribeResponse {
  @Field(() => String, { nullable: false })
  userId: string

  @Field(() => String, { nullable: false })
  deviceToken: string

  @Field(() => Float, { nullable: false })
  updatedAt: Date
}
