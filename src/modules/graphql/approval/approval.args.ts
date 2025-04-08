import { Field, Float, InputType, ObjectType, OmitType, PartialType, registerEnumType } from "@nestjs/graphql"
import { IsDefined, IsNotEmpty, IsNotIn, IsUUID, ValidateIf, ValidateNested } from "class-validator"
import GraphQLJSON from "graphql-type-json"
import { ApprovalOwnerStatus, ApprovalSource, ApprovalStatus, OfficeApproval } from "src/models/entities/approval"
import { ApprovalAction, ActionUnit, ApprovalType } from "src/models/entities/approval.form"
import { ApprovalProcessAction } from "src/models/entities/approval.step"
import { ObjectStatus } from "src/models/entities/profile.info.block"
import { DataType } from "src/models/entities/profile.info.field"
import { GrantType } from "@utils/enum.utils";
import { IsExistUserDbValidate } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { DatePeriod } from "@common/args.common";
import { ApprovalForwardItem, ApprovalSubmitTypeEnum, YourActionEnum } from "@enum/approval/approval/approval.enum";
import {
    IsCanUpdateApprovalDbValidate
} from "@decorators/validation/db/approval/approval/is-can-update.approval.db.validate";
import {
    IsValidSubscriberListApprovalDbValidate
} from "@decorators/validation/db/approval/approval/is-valid-subscriber-list.approval.db.validate";
import {
    IsNameNotExistUserApprovalFilterDbValidate
} from "@decorators/validation/db/filter/user-approval/is-name-not-exist.user-approval.filter.db.validate";
import { Expose, Transform, Type } from "class-transformer";
import { ApprovalFormGroup, OfficeFilter, OfficeUser } from "@models/entities";
import {
    IsCanUpdateUserApprovalFilterDbValidate
} from "@decorators/validation/db/filter/user-approval/is-can-update.user-approval.filter.db.validate";
import {
    IsExistApprovalFormGroupDbValidate
} from "@decorators/validation/db/approval/form/group/is-exist.approval-form-group.db.validate";
import { IsExistApprovalDbValidate } from "@decorators/validation/db/approval/approval/is-exist.approval.db.validate";
import { IsExistAndGetUserDbValidate } from "@decorators/validation/db/user/is-exist-and-get.user.db.validate";

registerEnumType(GrantType, { name: 'GrantType' })
registerEnumType(ApprovalSubmitTypeEnum, { name: 'ApprovalSubmitTypeEnum' })
registerEnumType(YourActionEnum, { name: 'YourActionEnum' })
registerEnumType(ApprovalForwardItem, { name: 'ApprovalForwardItem' })

@InputType()
export class ApprovalFormArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field({ nullable: true })
    note: string

    @Field(_type => ObjectStatus, { nullable: true, defaultValue: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => ApprovalType, { nullable: true })
    type: ApprovalType

    @Field({ nullable: true })
    typeId: string

    @Field(_type => [String], { nullable: true, defaultValue: [] })
    @ValidateIf(o => !o.userIds)
    @IsDefinedValidate({
        message: 'ApprovalNeedUsed'
    })
    departmentIds: string[]

    @Field(_type => [String], { nullable: true, defaultValue: [] })
    @ValidateIf(o => o.userIds)
    @IsExistUserDbValidate()
    userIds: string[]

    @Field(() => [ApprovalFormFieldArgs], { nullable: true })
    fields: ApprovalFormFieldArgs[]

    @Field(() => [ApprovalFormStepArgs], { nullable: true })
    steps: ApprovalFormStepArgs[]

    @Field(_type => [String], { nullable: false, defaultValue: [] })
    subscriber: string[]

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.formGroupIds)
    @IsExistApprovalFormGroupDbValidate()
    formGroupIds: string[]

    formGroups?: ApprovalFormGroup[] = []
}

@InputType()
export class EditApprovalFormArgs {
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
    typeId: string

    @Field(_type => [String], { nullable: true })
    departmentIds: string[]

    @Field(_type => [String], { nullable: true })
    @ValidateIf(o => o.userIds)
    @IsExistUserDbValidate()
    userIds: string[]

    @Field(() => [ApprovalFormFieldArgs], { nullable: true })
    fields: ApprovalFormFieldArgs[]

    @Field(() => [ApprovalFormStepArgs], { nullable: true })
    steps: ApprovalFormStepArgs[]

    @Field(_type => [String], { nullable: true })
    subscriber: string[]

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.formGroupIds)
    @IsExistApprovalFormGroupDbValidate()
    formGroupIds: string[]

    formGroups?: ApprovalFormGroup[] = []
}

@InputType()
export class ApprovalTableColumnArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field(() => Boolean, { nullable: true, defaultValue: false })
    required: boolean
}

@InputType()
export class ApprovalFormFieldArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field(_type => DataType, { nullable: true, defaultValue: DataType.Text })
    dataType: DataType

    @Field(() => Boolean, { nullable: true, defaultValue: false })
    required: boolean

    @Field({ nullable: true })
    hintText: string //TEXT

    @Field(() => Boolean, { nullable: true, defaultValue: true })
    timeInPast: boolean //DATE

    @Field(_type => [String], { nullable: true })
    optionItems: string[] //LIST

    @Field(() => Boolean, { nullable: true, defaultValue: false })
    multiSelect: boolean //LIST

    @Field(_type => [ApprovalTableColumnArgs], { nullable: true })
    columns: ApprovalTableColumnArgs[] //TABLE
}

@InputType()
export class ApprovalFormStepApproverArgs {
    // @Field(_type => String, { nullable: false })
    // @IsUUID()
    // @IsNotEmpty()
    // approveBy: string

    @Field(_type => [String], { nullable: false, defaultValue: [] })
    approveBy: string[]

    @Field({ nullable: true, defaultValue: 0 })
    level: number

    @Field({ nullable: true })
    departmentId: string

    @Field(_type => ActionUnit, { nullable: false })
    unit: ActionUnit
}

@InputType()
export class ApprovalFormStepArgs {
    @Field(_type => ApprovalAction, { nullable: false })
    action: ApprovalAction

    @Field(_type => [String], { nullable: false, defaultValue: [] })
    consentBy: string[]

    @Field(() => ApprovalFormStepApproverArgs, { nullable: true })
    approver: ApprovalFormStepApproverArgs
}

@InputType()
export class ApprovalFormFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field(_type => ObjectStatus, { nullable: true })
    status?: ObjectStatus

    @Field(_type => ApprovalType, { nullable: true })
    type?: ApprovalType

    @Field(_type => [String], { nullable: true })
    orgChartIds?: string[]
}

@InputType()
export class ApprovalStepArgs {
    @Field(_type => ApprovalAction, { nullable: false })
    action: ApprovalAction

    @Field(_type => [String], { nullable: false, defaultValue: [] })
    consentBy: string[]

    // @Field({ nullable: true })
    // approverId: string

    @Field(_type => [String], { nullable: false, defaultValue: [] })
    approveBy: string[]
}

@InputType()
export class ApprovalStepUpdateInput extends ApprovalStepArgs {
    @Field(_type => Number, { nullable: true })
    actionAt: number
}

@InputType()
export class ApprovalFieldArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    @Field(_type => DataType, { nullable: true, defaultValue: DataType.Text })
    dataType: DataType

    @Field(() => Boolean, { nullable: true, defaultValue: false })
    required: boolean

    @Field({ nullable: true })
    hintText: string //TEXT

    @Field(() => Boolean, { nullable: true, defaultValue: true })
    timeInPast: boolean //DATE

    @Field(_type => [String], { nullable: true })
    optionItems: string[] //LIST

    @Field(() => Boolean, { nullable: true, defaultValue: false })
    multiSelect: boolean //LIST

    @Field(_type => String, { nullable: true })
    textValue: string

    @Field(_type => Float, { nullable: true })
    dateValue: Date

    @Field(() => [String], { nullable: true })
    listValues: string[]
}

@InputType()
export class ApprovalStructureArgs {
    // @Field({ nullable: false })
    // @IsNotEmpty()
    // name: string

    @Field(() => [ApprovalFieldArgs], { nullable: true })
    fields: ApprovalFieldArgs[]

    @Field(() => [ApprovalStepArgs], { nullable: true })
    steps: ApprovalStepArgs[]

    @Field(_type => [String], { nullable: false, defaultValue: [] })
    subscriber: string[]
}

@InputType()
export class ApprovalForwardUserDataInput {
    @Field(_type => String,{ nullable: true })
    @IsExistAndGetUserDbValidate()
    userId: string

    user?: OfficeUser

    @Field(_type => [ApprovalForwardItem], { nullable: true })
    showItems: ApprovalForwardItem[]

    @Field({ nullable: true })
    note: string
}

@InputType()
export class ApprovalForwardDataInput {
    @Field({ nullable: true })
    @IsExistApprovalDbValidate()
    originApprovalId: string

    originApproval?: OfficeApproval

    @Field(() => [ApprovalForwardUserDataInput], { nullable: true })
    @IsDefinedValidate({
        message: 'ApprovalForwardRequiredUser'
    })
    @Type(() => ApprovalForwardUserDataInput)
    @ValidateNested({each: true})
    forwardUserData?: ApprovalForwardUserDataInput[]

    @Field({ nullable: true })
    note: string
}

@InputType()
export class ApprovalArgs {
    @Field(_type => ApprovalSource, { nullable: false })
    source: ApprovalSource

    @Field({ nullable: true })
    name: string

    @Field({ nullable: true })
    note: string

    @Field({ nullable: true }) //Template
    formId: string

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    formFieldData: JSON

    @Field(() => ApprovalStructureArgs, { nullable: true }) //Blank
    structure: ApprovalStructureArgs

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    attachmentIds: string[]

    @Field(() => [String], { nullable: true })
    subscriberIds: string[]

    @Field(_type => String, { nullable: true })
    draftId?: string

    @Field(_type => ApprovalSubmitTypeEnum, { nullable: true, defaultValue: ApprovalSubmitTypeEnum.Submit })
    submitType: ApprovalSubmitTypeEnum

    @Field(() => ApprovalForwardDataInput, { nullable: true })
    @ValidateIf(o => o.submitType === ApprovalSubmitTypeEnum.Forward)
    @Type(() => ApprovalForwardDataInput)
    @ValidateNested({each: true})
    forwardData?: ApprovalForwardDataInput

    @Field({ nullable: true, defaultValue: true })
    isPublic?: boolean

    type?: ApprovalType
    relationId?: string
}

@InputType()
export class ApprovalUpdateInput extends ApprovalArgs {
    @Field(_type => String, { nullable: false })
    @IsCanUpdateApprovalDbValidate()
    approvalId: string

    approval?: OfficeApproval
}

@InputType()
export class ApprovalSubscriberUpdateInput {
    @Field(_type => String, { nullable: false })
    // @IsCanAddSubscriberApprovalDbValidate()
    @IsValidSubscriberListApprovalDbValidate('subscriberIds')
    approvalId: string

    approval?: OfficeApproval

    @Field(() => [String], { nullable: true })
    // @IsExistUserDbValidate()
    subscriberIds: string[]
}

@InputType()
export class ApprovalApproveStepUpdateInput {
    @Field(_type => String, { nullable: false })
    @IsExistApprovalDbValidate()
    approvalId: string

    approval?: OfficeApproval

    @Field(() => [ApprovalStepArgs], { nullable: true })
    newSteps: ApprovalStepArgs[]

    @Field({ nullable: true })
    note: string
}

@InputType()
export class ShoppingRequestArgs {
    @Field({ nullable: true })
    name: string

    @Field(_type => Float, { nullable: true })
    expectedCost: number

    @Field({ nullable: true })
    note: string

    @Field({ nullable: false }) //Template
    formId: string

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    formFieldData: JSON

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    attachmentIds: string[]

    @Field(() => [String], { nullable: true })
    subscriberIds: string[]

    @Field(_type => ApprovalSubmitTypeEnum, { nullable: true, defaultValue: ApprovalSubmitTypeEnum.Submit })
    submitType: ApprovalSubmitTypeEnum
}

@InputType()
export class ApprovalActionArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field(_type => ApprovalProcessAction, { nullable: false })
    @IsNotIn([ApprovalProcessAction.Submit])
    action: ApprovalProcessAction

    @Field({ nullable: true })
    comment: string

    @Field({ nullable: true })
    grantStepId: string

    @Field({ nullable: true })
    grantTo: string

    @Field(() => GrantType, { nullable: true })
    grantToType: GrantType

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    attachmentIds: string[]

    @Field(() => [String], { nullable: true })
    approvalRowIds: string[]
}

@InputType()
export class ApprovalFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field(_type => ApprovalOwnerStatus, { nullable: true })
    status: ApprovalOwnerStatus

    @Field(_type => ApprovalType, { nullable: true })
    type?: ApprovalType

    @Field(_type => [ApprovalStatus], { nullable: true })
    statuses?: ApprovalStatus[]

    @Field(_type => [String], { nullable: true })
    formIds?: string[]

    @Field({ nullable: true })
    createdFrom?: number

    @Field({ nullable: true })
    createdTo?: number

    @Field({ nullable: true })
    keyword?: string

    @Field(_type => DatePeriod, { nullable: true })
    doneAt: DatePeriod

    @Field(_type => [String], { nullable: true })
    departmentIds?: string[]

    @Field(_type => [String], { nullable: true })
    creatorIds?: string[]

    @Field(_type => [String], { nullable: true })
    approvalIds?: string[]

    @Field(_type => [YourActionEnum], { nullable: true, defaultValue: [] })
    yourAction?: YourActionEnum[]
}

@InputType()
export class ApprovalFilterSave extends PartialType(OmitType(ApprovalFilter, ['size', 'page', 'status'])){
}

@InputType()
export class ApprovalFilterCreateInput {
    @Field({ nullable: true })
    @IsNameNotExistUserApprovalFilterDbValidate()
    name: string

    /*@Field({ nullable: true })
    order: number*/

    @Field(() => ApprovalFilterSave,{ nullable: true })
    filter: ApprovalFilterSave
}


@InputType()
export class ApprovalFilterUpdateInput extends ApprovalFilterCreateInput {
    @Field(_type => String, { nullable: true })
    @IsCanUpdateUserApprovalFilterDbValidate()
    approvalFilterId: string

    approvalFilter?: OfficeFilter

    @Expose()
    @Transform(({obj}) => obj.approvalFilterId)
    IsNameNotExistUserApprovalFilterDbValidate_filterId?: string = null
}

@InputType()
export class ApprovalCommentCreate {
    @Field(_type => String, { nullable: false })
    approvalId: string

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

@InputType()
export class ApprovalFilterListFilter {
    @Field({ nullable: true })
    page?: number

    @Field({ nullable: true })
    size?: number

    @Field({ nullable: true })
    keyword?: string
}