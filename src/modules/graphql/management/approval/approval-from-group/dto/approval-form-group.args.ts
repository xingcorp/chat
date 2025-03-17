import { Field, Float, InputType, Int, OmitType, PartialType } from "@nestjs/graphql";
import {
    IsNameNotExistApprovalFormGroupDbValidate
} from "@decorators/validation/db/approval/form/group/is-name-not-exist.approval-form-group.db.validate";
import { ApprovalFormGroup, OfficeFilter } from "@models/entities";
import { Expose, Transform } from "class-transformer";
import {
    IsExistApprovalFormGroupDbValidate
} from "@decorators/validation/db/approval/form/group/is-exist.approval-form-group.db.validate";

@InputType()
export class ApprovalFormGroupCreateInput {
    @Field(_type => String, {nullable: false})
    @IsNameNotExistApprovalFormGroupDbValidate()
    name: string
}


@InputType()
export class ApprovalFormGroupCreateUpdateInput extends ApprovalFormGroupCreateInput {
    @Field(_type => String, { nullable: true })
    @IsExistApprovalFormGroupDbValidate()
    formGroupId: string

    formGroup?: ApprovalFormGroup

    @Expose()
    @Transform(({obj}) => obj.formGroupId)
    IsNameNotExistApprovalFormGroupDbValidate_formGroupId?: string = null
}

@InputType()
export class ApprovalFormGroupFilter {
    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number

    @Field({nullable: true})
    keyword: string
}