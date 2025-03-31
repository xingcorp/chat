import { Field, Float, InputType } from '@nestjs/graphql'

@InputType()
export class UserLoginArgs {
  @Field({ nullable: false })
  phone: string

  @Field({ nullable: false })
  password: string

  @Field({ nullable: true })
  name: string

  @Field({ nullable: true })
  model: string

  @Field({ nullable: true })
  identifierForVendor: string
}

@InputType()
export class IdentityOrgDeviceArgs {
  @Field({ nullable: true })
  name: string

  @Field({ nullable: true })
  model: string

  @Field({ nullable: true })
  identifierForVendor: string

  @Field(() => String, { nullable: true })
  versionOS: string

}

@InputType()
export class SysUserLoginArgs {
  @Field({ nullable: false })
  email: string

  @Field({ nullable: false })
  password: string

  @Field({ nullable: false })
  organizationId: string
}

@InputType()
export class CmsUserLoginArgs {
  @Field({ nullable: false })
  email: string

  @Field({ nullable: false })
  password: string
}

@InputType()
export class UserRegisterArgs {
  @Field({ nullable: true })
  name: string

  @Field({ nullable: false })
  phone: string

  @Field({ nullable: false })
  password: string
}

@InputType()
export class RegisterBusinessRoleArgs {
  @Field({ nullable: true })
  fullname: string

  @Field({ nullable: true })
  code: string

  @Field({ nullable: true })
  secondPhone: string

  @Field({ nullable: true })
  identityCardNo: string

  @Field({ nullable: true })
  email: string

  @Field({ nullable: true })
  carrierId: string

  @Field({ nullable: true })
  bankId: string

  @Field({ nullable: true })
  bankAccountNumber: string

  @Field({ nullable: true })
  bankAccountHolder: string

  @Field(() => String, { nullable: true })
  bankCardNumber: string

  @Field(() => String, { nullable: true })
  bankBranch: string

  @Field(() => Float, { nullable: true })
  dateOfBirth: number

  @Field(() => String, { nullable: true })
  addressZoneId: string

  @Field(() => String, { nullable: true })
  address: string
}

@InputType()
export class UserPasswordArgs {
  @Field({ nullable: true })
  oldPassword: string

  @Field({ nullable: false })
  newPassword: string
}

@InputType()
export class UserInfoArgs {
  @Field({ nullable: true })
  fullname: string

  @Field({ nullable: true })
  code: string

  @Field(() => [String], { nullable: true })
  phones: string[]

  @Field(() => String, { nullable: true })
  email: string

  @Field(() => String, { nullable: true })
  address: string

  @Field(() => String, { nullable: true })
  addressZoneId: string

  @Field(() => String, { nullable: true })
  carrierId: string

  @Field(() => String, { nullable: true })
  bankId: string

  @Field(() => String, { nullable: true })
  bankAccountNumber: string

  @Field(() => String, { nullable: true })
  bankAccountHolder: string

  @Field(() => String, { nullable: true })
  bankCardNumber: string

  @Field(() => String, { nullable: true })
  bankBranch: string
}
