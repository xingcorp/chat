import { Field, Float, Int, ObjectType } from '@nestjs/graphql'
import { BankAccount } from './bank.account'
import { BusinessRole } from './business.role'
import { Carrier } from './carrier'
import { File } from '../../storage/objects/file'
import { Address } from './address'
import { Configuration } from './configuration'
import { OrganizationDevice } from '@models/entities/organization.device'

@ObjectType()
export class User {
  @Field(() => String)
  id: string

  @Field(() => String, { nullable: true })
  extendId: string

  @Field(() => String, { nullable: true })
  phone: string

  @Field(() => [String], { nullable: true })
  phones: string[]

  @Field(() => String, { nullable: true })
  email: string

  @Field(() => String, { nullable: true })
  username: string

  @Field(() => String, { nullable: true })
  name: string

  @Field(() => String, { nullable: true })
  fullname: string

  @Field(() => Float, { nullable: true })
  dateOfBirth: Date

  @Field(() => File, { nullable: true })
  avatar: File

  @Field(() => Address, { nullable: true })
  address: Address

  @Field(() => [Carrier], { nullable: true })
  carriers: Carrier[]

  @Field(() => [BankAccount], { nullable: true })
  bankAccounts: BankAccount[]

  @Field(_type => BankAccount, { nullable: true })
  bankAccount: BankAccount

  @Field(() => [BusinessRole], { nullable: true })
  businessRoles: BusinessRole[]

  @Field(() => BusinessRole, { nullable: true })
  sessionBusinessRole: BusinessRole

  @Field(() => [BusinessRole], { nullable: true })
  sessionMultiBusinessRoles: BusinessRole[]

  @Field(() => Int, { nullable: true })
  unreadNotificationCount: number

  @Field(() => Configuration, { nullable: true })
  configuration: Configuration

  @Field(() => Float, { nullable: true })
  createdAt: Date

  @Field(() => Float, { nullable: true })
  updatedAt: Date

  @Field(() => File, { nullable: true })
  frontIdCard: File

  @Field(() => File, { nullable: true })
  backIdCard: File

  @Field(() => [File], { nullable: true })
  images: File[]

  @Field(() => Float, { nullable: true })
  desiredDistance: number

  @Field(_type => Boolean, { nullable: false })
  profileVerified: boolean

  @Field(() => String, { nullable: true })
  taxNumber: string

  @Field(() => String, { nullable: true })
  requestId: string

  @Field(_type => Boolean, { nullable: true })
  isCheckDeviceValidated: boolean

  @Field(() => [OrganizationDevice], { nullable: true })
  organizationDevices?: OrganizationDevice[]
}
