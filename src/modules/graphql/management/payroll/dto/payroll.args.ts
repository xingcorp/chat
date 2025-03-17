import { Field, InputType, OmitType, PartialType, PickType, registerEnumType } from "@nestjs/graphql";
import { IsNotEmpty, IsUUID } from "class-validator";
import { InfoBlockArgs } from "@modules/graphql/profile/profile.args";
import { ObjectStatus } from "@models/entities/profile.info.block";
import { DataType } from "@models/entities/profile.info.field";
import { CommonListFilterPaginate } from "@modules/graphql/common/common.args";

registerEnumType(ObjectStatus, {name: 'ObjectStatus'})

@InputType()
export class PayrollCreateInput {
    // @Field(_type => String, { nullable: true })
    // code: string

    @Field(_type => String, { nullable: false })
    name: string

    @Field(_type => ObjectStatus, { nullable: false })
    status: ObjectStatus

    @Field(_type => [String], { nullable: false })
    orgChartIds: string[]
}

@InputType()
export class PayrollUpdateInput extends PartialType(PayrollCreateInput) {
    @Field(_type => String, { nullable: false })
    id: string
}

@InputType()
export class PayrollBulkUpsertInput extends PartialType(OmitType(PayrollCreateInput, ['status'])) {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true, defaultValue: ObjectStatus.Active })
    status: string
}

@InputType()
export class PayrollFieldArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

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
export class PayrollBlockArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field({ nullable: true })
    note: string

    @Field(_type => ObjectStatus, { nullable: true, defaultValue: ObjectStatus.Active })
    status: ObjectStatus

    @Field(() => [PayrollFieldArgs], { nullable: true })
    fields: PayrollFieldArgs[]
}

@InputType()
export class PayrollCreateWithBlockInput {
    // @Field(_type => String, { nullable: true })
    // code: string

    @Field(_type => String, { nullable: false })
    @IsNotEmpty()
    name: string

    @Field(_type => ObjectStatus, { nullable: false })
    status: ObjectStatus

    @Field(() => [PayrollBlockArgs], { nullable: true })
    blocks: PayrollBlockArgs[]
}

@InputType()
export class PayrollBlockCreateInput {
    @Field({ nullable: false })
    name: string

    // @Field({ nullable: true })
    // code: string

    @Field({ nullable: true })
    note: string

    @Field(_type => ObjectStatus, { nullable: true, defaultValue: ObjectStatus.Active })
    status: ObjectStatus

    @Field({ nullable: false })
    @IsNotEmpty()
    payrollId: string
}

@InputType()
export class PayrollBlockUpdateInput extends PartialType(PayrollBlockCreateInput) {
    @Field({ nullable: false })
    @IsNotEmpty()
    id: string
}

@InputType()
export class PayrollBlockBulkUpsertInput extends PartialType(OmitType(PickType(PayrollBlockCreateInput, ['name']), ['status'])) {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true, defaultValue: ObjectStatus.Active })
    status: string

    @Field(_type => String, { nullable: true })
    payrollCode: string
}

@InputType()
export class PayrollBlockFieldCreateInput {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    blockId: string

    @Field(_type => DataType, { nullable: true, defaultValue: DataType.Text })
    dataType: DataType

    // @Field({ nullable: true })
    // code: string

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
export class PayrollBlockFieldUpdateInput extends PartialType(PayrollBlockFieldCreateInput) {
    @Field({ nullable: false })
    id: string
}


@InputType()
export class PayrollListFilter extends CommonListFilterPaginate {
    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    userId?: string
}
