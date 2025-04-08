import { Field, Float, ObjectType } from '@nestjs/graphql'
import { User } from './user'

@ObjectType()
export class Address {
  @Field(() => String, { nullable: true })
  id: string

  @Field(() => Float, { nullable: true })
  createdAt: Date

  @Field(() => Float, { nullable: true })
  updatedAt: Date

  @Field(() => String, { nullable: true })
  ownerId: string

  @Field(() => User, { nullable: true })
  owner: User

  @Field(() => Float, { nullable: true })
  latitude: number

  @Field(() => Float, { nullable: true })
  longitude: number

  @Field(() => String, { nullable: true })
  country: string

  @Field(() => String, { nullable: true })
  province: string

  @Field(() => String, { nullable: true })
  district: string

  @Field(() => String, { nullable: true })
  ward: string

  @Field(() => String, { nullable: true })
  address: string

  @Field(() => String, { nullable: true })
  countryId: string

  @Field(() => String, { nullable: true })
  provinceId: string

  @Field(() => String, { nullable: true })
  districtId: string

  @Field(() => String, { nullable: true })
  wardId: string
}
