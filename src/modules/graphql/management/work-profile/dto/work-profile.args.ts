import {
    Field,
    Float,
    InputType,
    Int,
    ObjectType,
    OmitType,
    PartialType,
    PickType,
    registerEnumType
} from "@nestjs/graphql";
import { IsExistUserDbValidate } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { IsExistOrgChartDbValidate } from "@decorators/validation/db/org-chart/is-exist.org-chart.db.validate";
import { ValidateIf } from "class-validator";
import GraphQLJSON from "graphql-type-json";
import { IsExistTitleDbValidate } from "@decorators/validation/db/title/is-exist.title.db.validate";
import {
    IsExistWorkProfileDbValidate
} from "@decorators/validation/db/work-profile/is-exist.work-profile.db.validate";
import { Expose, Transform } from "class-transformer";
import {
    WorkProfileChangeType,
    WorkProfileChangeTypeExplain,
} from "@enum/work-profile/work-profile.enum";
import { OfficeUser, UserWorkProfile } from "@models/entities";
import { IsExistAttachmentsIamValidate } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { IsExistCodeUserDbValidate } from "@decorators/validation/db/user/is-exist-code.user.db.validate";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { IsInValidate } from "@decorators/validation/utils/is-in.validate";
import { LangVi } from "@utils/lang";
import { IsCodeExistOrgChartDbValidate } from "@decorators/validation/db/org-chart/is-code-exist.org-chart.db.validate";
import { IsCodeExistTitleDbValidate } from "@decorators/validation/db/title/is-code-exist.title.db.validate";
import { IsValidDateFormatValidate } from "@decorators/validation/utils/is-valid-date-format.validate";
import { enumTextGetVals } from "@utils/enum.utils";
import { IsNotExistCodeUserDbValidate } from "@decorators/validation/db/user/is-not-exist-code.user.db.validate";
import { IsUniqueCodeUserDbValidate } from "@decorators/validation/db/user/is-unique-code.user.db.validate";
import {
    IsUniqueActiveDateWorkProfileDbValidate
} from "@decorators/validation/db/work-profile/is-unique.active-date.work-profile.db.validate";
import { datetimeGetDateFromFormat, getTimeLocal } from "@utils/datetime.utils";
import { DatePeriod } from "@common/args.common";
import {
    IsValidMetadataWorkProfileDbValidate
} from "@decorators/validation/db/work-profile/is-valid-metadata.work-profile.db.validate";

registerEnumType(WorkProfileChangeType, {name: 'WorkProfileChangeType'})

@InputType()
export class WorkProfileCreateInput {
    user?: OfficeUser

    @Field(_type => String, {nullable: false})
    @ValidateIf(o => o.userId)
    @IsExistUserDbValidate()
    userId: string

    @Field(_type => WorkProfileChangeType, {nullable: false, description: 'Hình thức thay đổi'})
    type: WorkProfileChangeType

    @Field(_type => String, {nullable: true, description: 'Lý do thay đổi'})
    reason: string

    @Expose()
    @Transform(({obj}) => {
        return {id: obj.userId ?? obj.user?.id}
    })
    IsUniqueActiveDateWorkProfileDbValidate_userQuery?: object = null

    @Field(_type => Float, {nullable: false, description: 'Ngày hiệu lực'})
    @ValidateIf(o => o.userId || o.user)
    @IsUniqueActiveDateWorkProfileDbValidate()
    activeDate: number

    @Field(_type => Float, {nullable: true, description: 'Ngày het han'})
    endDate: number

    @Field(_type => Boolean, {nullable: false, description: 'Có quyết định'})
    isDecided: boolean

    @Field(_type => String, {nullable: true, description: 'Số quyết định'})
    @ValidateIf(o => o.isDecided)
    @IsDefinedValidate()
    decidedNumber: string

    @Field(_type => Float, {nullable: true, description: 'Ngày quyết định'})
    @ValidateIf(o => o.isDecided)
    @IsDefinedValidate()
    decidedDate: number

    @Field(_type => String, {nullable: true, description: 'Mã nhân viên'})
    @ValidateIf(o => o.userId || o.user)
    @IsNotExistCodeUserDbValidate()
    userCode: string

    @Field(_type => String, {nullable: true, description: 'Phòng ban'})
    @ValidateIf(o => o.departmentId)
    @IsExistOrgChartDbValidate()
    departmentId: string

    @Field(_type => String, {nullable: true, description: 'Chức danh'})
    @ValidateIf(o => o.titleId)
    @IsExistTitleDbValidate()
    titleId: string

    @Field(_type => String, {nullable: true, description: 'Ngạch bậc'})
    major: string

    @Field(_type => String, {nullable: true, description: 'Quản lý trực tiếp'})
    @ValidateIf(o => o.leaderId)
    @IsExistUserDbValidate({
        message: 'OfficeLeaderUserNotExisted'
    })
    leaderId: string

    @Field(_type => GraphQLJSON, {defaultValue: null})
    @Transform(({value}) => value ?? {})
    // @IsValidMetadataWorkProfileDbValidate()
    metadata: JSON

    @Field(_type => String, {nullable: true, description: 'Ghi chú'})
    note: string

    @Field(() => [String], {nullable: true})
    @ValidateIf(o => o.attachmentIds)
    @IsExistAttachmentsIamValidate()
    attachmentIds: string[]
}

@InputType()
export class WorkProfileUpdateInput extends PartialType(OmitType(WorkProfileCreateInput, ['userId'])) {
    @Field(_type => String, {nullable: false})
    @IsExistWorkProfileDbValidate()
    id: string

    @Field(_type => String, {nullable: true, description: 'Mã nhân viên'})
    @ValidateIf(o => o.id && o.userCode)
    @IsNotExistCodeUserDbValidate({
        key: 'id',
        query: async (id: string) => (await UserWorkProfile.findOne({
            relations: ['user'],
            where: {
                id
            }
        }))?.user?.id
    })
    userCode: string

    @Expose()
    @Transform(({obj}) => obj.id)
    IsUniqueActiveDateWorkProfileDbValidate_updateId?: string = null

    @Expose()
    @Transform(({obj}) => {
        if (obj.id) return {workProfiles: {id: obj.id}}

        return null
    })
    IsUniqueActiveDateWorkProfileDbValidate_userQuery?: object = null

    @Field(_type => Float, {nullable: false, description: 'Ngày hiệu lực'})
    @ValidateIf(o => o.activeDate)
    @IsUniqueActiveDateWorkProfileDbValidate()
    activeDate: number
}

@InputType()
export class ManagementWorkProfileFilter {
    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number

    @Field({nullable: true})
    @ValidateIf(o => o.userId)
    @IsExistUserDbValidate()
    userId: string

    @Field({ nullable: true })
    keyword: string

    @Field({ nullable: true })
    type: string

    @Field({ nullable: true })
    orgId: string

    @Field(_type => DatePeriod, { nullable: true })
    activeDate: DatePeriod
}

@InputType()
export class OfficeWorkProfileFilter {
    @Field(() => Int, {nullable: true})
    page: number

    @Field(() => Int, {nullable: true})
    size: number
}

const TypeTextData = enumTextGetVals(WorkProfileChangeTypeExplain)

@InputType()
@ObjectType()
export class WorkProfileBulkUpsertInput extends PickType(WorkProfileCreateInput, ['reason', 'major', 'metadata', 'note']) {
    errorMessage?: string

    @Field(_type => String, {nullable: true})
    @IsExistWorkProfileDbValidate()
    id: string

    @Field(_type => String, {nullable: false, description: 'Hình thức thay đổi'})
    @IsInValidate(TypeTextData, {
        message: `FieldMustIn::Hình thức::${TypeTextData.join(',')}`
    })
    typeText: string

    @Field(_type => String, {nullable: true, description: 'Nhân viên'})
    @ValidateIf(o => o.userCodeUpdate)
    @IsExistCodeUserDbValidate()
    userCodeUpdate: string

    @Expose()
    @Transform(({obj}) => obj.id)
    IsUniqueActiveDateWorkProfileDbValidate_updateId?: string = null

    @Expose()
    @Transform(({obj}) => {
        if (obj.userCodeUpdate) return {code: obj.userCodeUpdate}
        if (obj.id) return {workProfiles: {id: obj.id}}

        return null
    })
    IsUniqueActiveDateWorkProfileDbValidate_userQuery?: object = null

    @Expose()
    @Transform(({obj}) => {
        const date = datetimeGetDateFromFormat('DD/MM/yyyy', obj.activeDate)
        return date ? getTimeLocal(date) : null
    })
    IsUniqueActiveDateWorkProfileDbValidate_dateNumber?: number = null

    @Field(_type => String, {nullable: false, description: 'Ngày hiệu lực'})
    @ValidateIf(o => o.activeDate)
    @IsValidDateFormatValidate('DD/MM/yyyy', {
        message: 'WrongFormatField::Ngày hiệu lực'
    })
    @ValidateIf(o => o.userCodeUpdate || o.id)
    @IsUniqueActiveDateWorkProfileDbValidate()
    activeDate: string

    @Field(_type => String, {nullable: false, description: 'Ngày hết hạn'})
    @ValidateIf(o => o.endDate)
    @IsValidDateFormatValidate('DD/MM/yyyy', {
        message: 'WrongFormatField::Ngày hết hạn'
    })
    endDate: string

    @Field(_type => String, {nullable: true, defaultValue: LangVi.NO, description: 'Có quyết định'})
    @IsInValidate([LangVi.YES, LangVi.NO], {
        message: 'WorkProfileInfoTypeError'
    })
    decided: string

    @Field(_type => String, {nullable: true, description: 'Số quyết định'})
    @ValidateIf(o => o.decided === LangVi.YES)
    @IsDefinedValidate()
    decidedNumber: string

    @Field(_type => String, {nullable: true, description: 'Ngày quyết định'})
    @ValidateIf(o => o.decided === LangVi.YES)
    @IsDefinedValidate()
    @IsValidDateFormatValidate('DD/MM/yyyy', {
        message: 'WrongFormatField::Ngày quyết định'
    })
    decidedDate: string

    @Field(_type => String, {nullable: true, description: 'Mã nhân viên'})
    @ValidateIf(o => (o.userCodeUpdate && o.userCodeUpdate !== o.userCode) || (o.id && o.userCode))
    @IsUniqueCodeUserDbValidate({
        key: 'id',
        query: async (id: string) => (await UserWorkProfile.findOne({
            relations: ['user'],
            where: {
                id
            }
        }))?.user?.id
    })
    userCode: string

    @Field(_type => String, {nullable: true, description: 'Phòng ban'})
    @ValidateIf(o => o.department)
    @IsCodeExistOrgChartDbValidate()
    department: string

    @Field(_type => String, {nullable: true, description: 'Chức danh'})
    @ValidateIf(o => o.title)
    @IsCodeExistTitleDbValidate()
    title: string

    @Field(_type => String, {nullable: true, description: 'Quản lý trực tiếp'})
    @ValidateIf(o => o.leader)
    @IsExistCodeUserDbValidate({
        message: 'OfficeLeaderUserNotExisted'
    })
    leader: string
}

