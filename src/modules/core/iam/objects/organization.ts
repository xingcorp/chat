import { Field, ObjectType } from '@nestjs/graphql'
import { Column } from 'typeorm'
import { Address } from './address'
import { User } from './user'

export enum OrganizationType {
  Group = 'Group',
  Company = 'Company',
  Distributor = 'Distributor',
  Shop = 'Shop',
  Invidiual = 'Invidiual',
  Unknow = 'Unknow'
}

@ObjectType()
export class Organization {
  @Field(() => String)
  id: string

  @Field(() => String, { nullable: true })
  type: OrganizationType

  @Field(() => String, { nullable: true })
  code: string

  @Field(() => String, { nullable: true })
  pdaCode: string

  @Field(() => String, { nullable: true })
  name: string

  @Field(() => String, { nullable: true })
  distributorChanel: string

  @Field(() => String, { nullable: true })
  salesOffice: string

  @Field(() => String, { nullable: true })
  phone: string

  @Field(() => String, { nullable: true })
  region: string

  @Field(() => String, { nullable: true })
  regionCode: string

  @Field(() => String, { nullable: true })
  area: string

  @Field(() => Address, { nullable: true })
  address: Address

  @Field(() => User, { nullable: true })
  owner: User
}
