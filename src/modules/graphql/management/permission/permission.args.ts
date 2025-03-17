import { ObjectStatus } from '@models/entities/profile.info.block'
import { InputType, Field, Int } from '@nestjs/graphql'
import { IsNotEmpty, IsUUID } from 'class-validator'

@InputType()
export class PermissionBusinessRoleFilter {
    @Field(() => Int, { nullable: true, defaultValue: 0 })
    page?: number

    @Field(() => Int, { nullable: true, defaultValue: 100 })
    size?: number

    @Field(() => String, { nullable: true })
    keyword: string
}

@InputType()
export class PermissionUpdateArgs {
    @Field(() => String, { nullable: false })
    businessRoleId: string

    @Field(() => [String], { nullable: false })
    actionIds: string[]
}

@InputType()
export class BusinessRoleUpdateArgs {
    @Field(() => String, { nullable: false })
    businessRoleId: string

    @Field(() => String, { nullable: true })
    name: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => [String], { nullable: false })
    actionIds: string[]
}

@InputType()
export class BusinessRoleCreateArgs {
    @Field(() => String, { nullable: false })
    name: string

    // @Field(() => String, { nullable: false })
    // code: string

    @Field(() => String, { nullable: true })
    description: string

    @Field(() => [String], { nullable: false })
    actionIds: string[]
}

@InputType()
export class AddSysUserArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    fullname: string

    @Field({ nullable: true })
    code: string

    @Field({ nullable: false })
    email: string

    @Field({ nullable: false })
    businessRoleId: string

    @Field(() => [String], { nullable: false })
    orgChartIds: string[]
}

@InputType()
export class EditSysUserArgs {
    @Field(() => String, { nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field({ nullable: true })
    fullname: string

    @Field({ nullable: true })
    code: string

    @Field({ nullable: true })
    businessRoleId: string

    @Field(() => [String], { nullable: true })
    orgChartIds: string[]

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus
}

@InputType()
export class SysUserFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field(_type => ObjectStatus, { nullable: true })
    status?: ObjectStatus

    @Field({ nullable: true })
    orgChartId?: string
}