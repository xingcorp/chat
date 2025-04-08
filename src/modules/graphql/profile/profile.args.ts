import { Field, InputType } from "@nestjs/graphql"
import { IsNotEmpty, IsUUID } from "class-validator"
import { ObjectStatus } from "src/models/entities/profile.info.block"
import { DataType } from "src/models/entities/profile.info.field"

@InputType()
export class InfoBlockArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field({ nullable: true })
    note: string

    @Field(_type => ObjectStatus, { nullable: true, defaultValue: ObjectStatus.Active })
    status: ObjectStatus
}

@InputType()
export class OfficeTitleArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field({ nullable: true })
    note: string
}

@InputType()
export class OfficeTitleFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string
}

@InputType()
export class EditOfficeTitleArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field({ nullable: true })
    name: string

    @Field({ nullable: true })
    note: string
}

@InputType()
export class EditInfoBlockArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field({ nullable: true })
    name: string

    @Field({ nullable: true })
    note: string

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus

    @Field({ nullable: true })
    order: number
}

@InputType()
export class UpsertBlockArgs {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    status: string
}

@InputType()
export class UpsertFieldArgs {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    blockCode: string

    @Field(_type => String, { nullable: true })
    dataType: string

    @Field(_type => String, { nullable: true })
    note: string

    @Field(_type => String, { nullable: true })
    required: string

    @Field(_type => String, { nullable: true })
    optionItems: string

    @Field(_type => String, { nullable: true })
    status: string
}

@InputType()
export class UpsertTitleArgs {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string
}

@InputType()
export class InfoFieldArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    blockId: string

    @Field(_type => DataType, { nullable: true, defaultValue: DataType.Text })
    dataType: DataType

    @Field({ nullable: true })
    note: string

    @Field(() => Boolean, { nullable: true, defaultValue: false })
    required: boolean

    @Field(_type => ObjectStatus, { nullable: true, defaultValue: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => [String], { nullable: true })
    optionItems: string[]
}

@InputType()
export class EditInfoFieldArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field({ nullable: true })
    name: string

    @Field(_type => DataType, { nullable: true })
    dataType: DataType

    // @Field({ nullable: true })
    // fieldLength: string

    @Field({ nullable: true })
    note: string

    @Field(() => Boolean, { nullable: true })
    required: boolean

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus

    // @Field(() => Boolean, { nullable: true })
    // displayInBrief: boolean

    @Field({ nullable: true })
    order: number

    @Field(_type => [String], { nullable: true })
    optionItems: string[]
}