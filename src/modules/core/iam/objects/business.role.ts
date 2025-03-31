import { Field, ObjectType } from '@nestjs/graphql'
import { Address } from './address'
import { BankAccount } from './bank.account'
import { Organization } from './organization'
import { Permission } from './permission'
import { Policy } from './policy'

export enum BusinessRoleStatus {
  Pending = 'Pending',
  Approved = 'Approved',
  Rejected = 'Rejected',
  Suspended = 'Suspended'
}

@ObjectType()
export class BusinessRole {
  @Field(() => String, { nullable: true })
  id: string

  @Field(() => String, { nullable: true })
  type: string

  @Field(() => String, { nullable: true })
  code: string

  @Field(() => String, { nullable: true })
  name: string

  @Field(() => String, { nullable: true })
  description: string

  @Field(() => Organization, { nullable: true })
  organization: Organization

  @Field(() => BankAccount, { nullable: true })
  bankAccount: BankAccount

  @Field(() => Organization, { nullable: true })
  businessOrganization: Organization

  @Field(() => Address, { nullable: true })
  address: Address

  @Field(() => String, { nullable: true })
  agreementUrl: string

  @Field(() => String, { nullable: true })
  contentUrl: string

  @Field(() => String, { nullable: false })
  status: string

  @Field(() => [Permission], { nullable: true })
  permissions: Permission[]

  @Field(() => [Policy], { nullable: true })
  policies: Policy[]
}
