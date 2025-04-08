import { Field, Float, InputType, Int, PartialType } from "@nestjs/graphql";
import GraphQLJSON from "graphql-type-json";
import { CommonListFilterPaginate } from "@modules/graphql/common/common.args";
import { DatePeriod } from "@common/args.common";
import { IsDefined, IsInt, Max, Min, ValidateIf } from "class-validator";
import { Type } from "class-transformer";
import { PaycheckStatus } from "@enum/payroll/paycheck.enum";
import { OfficeFeatureLogAttachmentType } from "@enum/logs/logs.enum";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";

@InputType()
export class UserPaycheckCreateInput {
    @Field(_type => String, { nullable: false })
    payrollId: string

    @Field(_type => String, { nullable: false })
    userId: string

    @Field(_type => String, { nullable: false })
    name: string

    @Field(_type => Int, { nullable: false })
    @Min(1, {
        message: 'WrongDataInput'
    })
    @Max(12, {
        message: 'WrongDataInput'
    })
    month: number

    @Field(_type => Int, { nullable: false })
    @Min(2000, {
        message: 'WrongDataInput'
    })
    year: number

    @Field(_type => Float, { nullable: false })
    @Type(() => Number)
    @IsInt({
        message: 'WrongDataInput'
    })
    @Min(0,{
        message: 'WrongDataInput'
    })
    wage: number

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    metadata: JSON
}

@InputType()
export class UserPaycheckUpdateInput extends PartialType(UserPaycheckCreateInput) {
    @Field(_type => String, { nullable: false })
    id: string

    @Field(_type => PaycheckStatus, { nullable: true })
    status: PaycheckStatus
}

@InputType()
export class UserPaycheckBulkUpsertInput {
    errorMessage?: string

    @Field(_type => String, { nullable: true })
    code?: string

    @Field(_type => String, { nullable: true })
    @IsDefinedValidate()
    userCode?: string

    @Field(_type => String, { nullable: true })
    @IsDefinedValidate()
    payrollCode?: string

    @Field(_type => String, { nullable: true })
    @IsDefinedValidate()
    name?: string

    @Field(_type => Int, { nullable: true })
    @IsDefinedValidate()
    month?: number

    @Field(_type => Int, { nullable: true })
    @IsDefinedValidate()
    year?: number

    @Field(_type => Float, { nullable: true })
    @Type(() => Number)
    @IsDefinedValidate()
    wage?: number

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    metadata?: JSON
}

@InputType()
export class UserPaycheckListFilter extends CommonListFilterPaginate {
    @Field({ nullable: true })
    keyword?: string

    @Field(_type => Int, { nullable: true })
    month?: number

    @Field(_type => Int, { nullable: true })
    year?: number

    @Field(_type => String, { nullable: true })
    payrollId?: string

    @Field(_type => String, { nullable: true })
    paycheckId?: string

    @Field(_type => DatePeriod, { nullable: true })
    createdDate?: DatePeriod

    @Field(_type => [String], { nullable: true })
    orgChartIds?: string[]

    @Field(_type => [PaycheckStatus], { nullable: true })
    statuses?: PaycheckStatus[]
}

@InputType()
export class UserPaycheckCommentCreate {
    @Field(_type => String, { nullable: false })
    paycheckId: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => !o.attachmentIds && !o.imageIds)
    @IsDefined({
        message: 'LogCommentRequiredData'
    })
    comment: string

    @Field(() => [String], { nullable: true })
    attachmentIds: string[]

    @Field(() => [String], { nullable: true })
    imageIds: string[]
}
