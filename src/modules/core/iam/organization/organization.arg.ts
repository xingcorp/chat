import { InputType, Field, Float, Int } from '@nestjs/graphql'
import { OrganizationType } from '../objects/organization'

@InputType()
export class CreateOrganizationArgs {
  @Field(() => String, { nullable: false })
  type: OrganizationType

  @Field(() => String, { nullable: false })
  parentId: string

  @Field(() => String, { nullable: false })
  phone: string

  @Field(() => String, { nullable: false })
  code: string

  @Field(() => String, { nullable: false })
  name: string

  @Field(() => String, { nullable: true })
  distributorChanel?: string

  @Field(() => String, { nullable: true })
  salesOffice?: string

  @Field(() => String, { nullable: false })
  address?: string

  @Field(() => Float, { nullable: true, defaultValue: 0 })
  latitude?: number

  @Field(() => Float, { nullable: true, defaultValue: 0 })
  longtitude?: number

  @Field(() => String, { nullable: true })
  pdaCode?: string

  @Field(() => String, { nullable: true })
  region?: string

  @Field(() => String, { nullable: true })
  area?: string

  @Field(() => String, { nullable: true })
  countryId?: string

  @Field(() => String, { nullable: true })
  provinceId?: string

  @Field(() => String, { nullable: true })
  districtId?: string

  @Field(() => String, { nullable: true })
  wardId?: string

  @Field(() => String, { nullable: false })
  regionCode?: string
}

@InputType()
export class OrganizationFilter {
  @Field(() => Int, { nullable: true, defaultValue: 0 })
  page: number

  @Field(() => Int, { nullable: true, defaultValue: 100 })
  size: number

  @Field(() => String, { nullable: true })
  keyword: string

  parentId?: string;

  type?: string;
}