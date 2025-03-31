import { ObjectType, Field, Int, Float } from '@nestjs/graphql'
import { AddressZone } from '../../objects/address.zone'

@ObjectType()
export class AddressZoneResponse {
  @Field(() => Int, { defaultValue: 0 })
  total: number

  @Field(() => Int, { defaultValue: 0 })
  count: number

  @Field(() => [AddressZone], { nullable: true })
  zones?: AddressZone[]
}

@ObjectType()
export class LocationResponse {
  @Field(_type => Float, { nullable: true })
  longitude: number

  @Field(_type => Float, { nullable: true })
  latitude: number
}

@ObjectType()
export class AddressResponse {
  @Field(_type => String, { nullable: true })
  fullAddress: string

  @Field(_type => String, { nullable: true })
  address: string

  @Field(_type => String, { nullable: true })
  province: string

  @Field(_type => String, { nullable: true })
  district: string

  @Field(_type => String, { nullable: true })
  ward: string

  @Field(_type => AddressZone, { nullable: true })
  addressZone: AddressZone
}