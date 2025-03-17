import { Field, Float, InputType, Int, OmitType } from "@nestjs/graphql"
import { IsNotEmpty, IsUUID, ValidateIf } from "class-validator"
import { ObjectStatus } from "src/models/entities/profile.info.block"
import GraphQLJSON from 'graphql-type-json'
import { ScheduleType } from "@models/entities/user.schedule"
import { DatePeriod } from "@common/args.common";
import { LangVi } from "@utils/lang";
import { Transform } from "class-transformer";
import { transformDDMMYYYFullCharacter } from "@utils/datetime.utils";
import { IsExistAttachmentsIamValidate } from "@decorators/validation/iam/is-exist-attachments.iam.validate";
import { IsInValidate } from "@decorators/validation/utils/is-in.validate";
import * as IdentifyCardPlaceData from '@modules/graphql/master-data/data/identify-card-place.json'
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { IsNotExistCodeUserDbValidate } from "@decorators/validation/db/user/is-not-exist-code.user.db.validate";
import { IsCodeExistOrgChartDbValidate } from "@decorators/validation/db/org-chart/is-code-exist.org-chart.db.validate";
import { IsCodeExistTitleDbValidate } from "@decorators/validation/db/title/is-code-exist.title.db.validate";
import { IsExistCodeUserDbValidate } from "@decorators/validation/db/user/is-exist-code.user.db.validate";

const IdCardIssuedPlaceData = Object.values(IdentifyCardPlaceData).map(i => i.name)

@InputType()
export class EmployeeDepartmentArgs {
    @Field({ nullable: true })
    companyId: string

    @Field({ nullable: true })
    @IsNotEmpty()
    @IsUUID()
    departmentId: string

    @Field({ nullable: true })
    titleId: string
}

@InputType()
export class AddEmployeeArgs {
    @Field({ nullable: false })
    @IsDefinedValidate()
    fullname: string

    @Field({ nullable: true })
    @ValidateIf(o => o.code)
    @IsNotExistCodeUserDbValidate()
    code: string

    @Field({ nullable: true })
    // @IsNotEmpty()
    hrCode: string

    @Field({ nullable: true })
    major: string

    // @Field(() => Boolean, { nullable: false, defaultValue: false })
    // resigned: boolean

    // @Field(_type => Float, { nullable: true })
    // lastWorkingOn: number

    // @Field(_type => String, { nullable: true })
    // resignationType: string

    // @Field(_type => String, { nullable: true })
    // resignationReason: string

    // @Field(_type => String, { nullable: true })
    // resignationDetailReason: string

    // @Field()
    // companyId: string

    @Field({ nullable: false })
    @IsDefinedValidate()
    // @IsPhoneNumber("VN")
    phone: string

    @Field({ nullable: true })
    email: string

    @Field({ nullable: true })
    personalEmail: string

    @Field(_type => String, { nullable: true })
    identityCard: string

    @Field(_type => Float, { nullable: true })
    idCardIssuedOn: number

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.idCardIssuedPlace)
    @IsInValidate(IdCardIssuedPlaceData, {
        message: `FieldMustIn::Nơi cấp::${IdCardIssuedPlaceData.join(',')}`
    })
    idCardIssuedPlace: string

    @Field(_type => String, { nullable: true })
    socialInsuranceCode: string

    @Field(_type => String, { nullable: true })
    taxCode: string

    @Field(_type => String, { nullable: true })
    relativePhone: string

    @Field({ nullable: true })
    address: string

    @Field({ nullable: true })
    addressZoneId: string

    @Field({ nullable: true })
    tempAddress: string

    @Field({ nullable: true })
    tempAddressZoneId: string

    @Field(_type => [EmployeeDepartmentArgs], { nullable: true })
    departments: EmployeeDepartmentArgs[]

    @Field({ nullable: true })
    note: string

    @Field(_type => ObjectStatus, { nullable: true, defaultValue: ObjectStatus.Active })
    status: ObjectStatus

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    attachFileIds: string[]

    @Field({ nullable: true })
    bankId: string

    @Field({ nullable: true })
    bankBranch: string

    @Field({ nullable: true })
    accountHolder: string

    @Field({ nullable: true })
    accountNumber: string

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    data: JSON

    @Field(_type => Float, { nullable: true })
    onboardingOn: number

    @Field(_type => Float, { nullable: true })
    leaveOn: number

    @Field(_type => Float, { nullable: true })
    officalWorkingOn: number

    @Field(_type => Float, { nullable: true })
    dateOfBirth: number

    @Field({ nullable: true })
    leaderId: string
}

@InputType()
export class EditEmployeeArgs {
    @Field({ nullable: false })
    @IsDefinedValidate()
    @IsUUID()
    id: string

    @Field({ nullable: true })
    fullname: string

    @Field({ nullable: true })
    code: string

    @Field({ nullable: true })
    hrCode: string

    @Field({ nullable: true })
    major: string

    @Field(() => Boolean, { nullable: true })
    resigned: boolean | undefined

    @Field(_type => Float, { nullable: true })
    lastWorkingOn: number

    @Field(_type => String, { nullable: true })
    resignationType: string

    @Field(_type => String, { nullable: true })
    resignationReason: string

    @Field(_type => String, { nullable: true })
    resignationDetailReason: string

    @Field()
    companyId: string

    @Field({ nullable: true })
    email: string

    @Field({ nullable: true })
    personalEmail: string

    @Field(_type => String, { nullable: true })
    identityCard: string

    @Field(_type => Float, { nullable: true })
    idCardIssuedOn: number

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.idCardIssuedPlace)
    @IsInValidate(IdCardIssuedPlaceData, {
        message: `FieldMustIn::Nơi cấp::${IdCardIssuedPlaceData.join(',')}`
    })
    idCardIssuedPlace: string

    @Field(_type => String, { nullable: true })
    socialInsuranceCode: string

    @Field(_type => String, { nullable: true })
    taxCode: string

    @Field(_type => String, { nullable: true })
    relativePhone: string

    @Field({ nullable: true })
    address: string

    @Field({ nullable: true })
    addressZoneId: string

    @Field({ nullable: true })
    tempAddress: string

    @Field({ nullable: true })
    tempAddressZoneId: string

    @Field(_type => [EmployeeDepartmentArgs], { nullable: true })
    departments: EmployeeDepartmentArgs[]

    @Field({ nullable: true })
    note: string

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    attachFileIds: string[]

    @Field({ nullable: true })
    bankId: string

    @Field({ nullable: true })
    bankBranch: string

    @Field({ nullable: true })
    accountHolder: string

    @Field({ nullable: true })
    accountNumber: string

    @Field(() => GraphQLJSON, { nullable: true })
    data: JSON

    @Field(_type => Float, { nullable: true })
    onboardingOn: number

    @Field(_type => Float, { nullable: true })
    leaveOn: number

    @Field(_type => Float, { nullable: true })
    officalWorkingOn: number

    @Field(_type => Float, { nullable: true })
    dateOfBirth: number

    @Field({ nullable: true })
    leaderId: string

    @Field({ nullable: true })
    phoneNumber: string
}

@InputType()
export class UpsertEmployeeArgs {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    fullname: string

    @Field(_type => String, { nullable: true })
    phone: string

    @Field(_type => String, { nullable: true })
    departments: string

    @Field(_type => String, { nullable: true })
    email: string

    @Field(_type => String, { nullable: true })
    address: string

    @Field(_type => String, { nullable: true })
    province: string

    @Field(_type => String, { nullable: true })
    district: string

    @Field(_type => String, { nullable: true })
    ward: string

    @Field(_type => String, { nullable: true })
    bankName: string

    @Field(_type => String, { nullable: true })
    bankBranch: string

    @Field(_type => String, { nullable: true })
    accountHolder: string

    @Field(_type => String, { nullable: true })
    accountNumber: string

    @Field(_type => String, { nullable: true })
    status: string
}

@InputType()
export class ImportEmployeeArgs {
    errorMessage?: string

    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.code)
    @IsNotExistCodeUserDbValidate()
    code: string

    @Field(_type => String, { nullable: true })
    fullname: string

    @Field(_type => String, { nullable: true })
    phone: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.title)
    @IsCodeExistTitleDbValidate()
    title: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.department)
    @IsCodeExistOrgChartDbValidate()
    department: string

    @Field(_type => String, { nullable: true })
    email: string

    @Field(_type => String, { nullable: true })
    personalEmail: string

    @Field(_type => String, { nullable: true })
    address: string

    @Field(_type => String, { nullable: true })
    province: string

    @Field(_type => String, { nullable: true })
    district: string

    @Field(_type => String, { nullable: true })
    ward: string

    @Field(_type => String, { nullable: true })
    identityCard: string

    @Field(_type => String, { nullable: true })
    @Transform(({value}) => transformDDMMYYYFullCharacter(value))
    idCardIssuedOn: string

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => o.idCardIssuedPlace)
    @IsInValidate(IdCardIssuedPlaceData, {
        message: `FieldMustIn::Nơi cấp::${IdCardIssuedPlaceData.join(',')}`
    })
    idCardIssuedPlace: string

    @Field(_type => String, { nullable: true })
    @Transform(({value}) => transformDDMMYYYFullCharacter(value))
    birthday: string

    @Field(_type => String, { nullable: true })
    hrCode: string

    @Field(_type => String, { nullable: true })
    major: string

    @Field(_type => String, { nullable: true })
    @Transform(({value}) => transformDDMMYYYFullCharacter(value))
    onboardingOn: string

    @Field(_type => String, { nullable: true })
    @Transform(({value}) => transformDDMMYYYFullCharacter(value))
    officalWorkingOn: string

    @Field(_type => String, { nullable: true, defaultValue: LangVi.NO })
    resigned: string

    @Field(_type => String, { nullable: true })
    resignationType: string

    @Field(_type => String, { nullable: true })
    resignationReason: string

    @Field(_type => String, { nullable: true })
    resignationDetailReason: string

    @Field(_type => String, { nullable: true })
    @Transform(({value}) => transformDDMMYYYFullCharacter(value))
    lastWorkingOn: string

    @Field(_type => String, { nullable: true })
    @Transform(({value}) => transformDDMMYYYFullCharacter(value))
    leaveOn: string

    @Field(_type => String, { nullable: true })
    taxCode: string

    @Field(_type => String, { nullable: true })
    socialInsuranceCode: string

    @Field(_type => String, { nullable: true })
    relativePhone: string

    @Field(_type => String, { nullable: true })
    bankName: string

    @Field(_type => String, { nullable: true })
    bankBranch: string

    @Field(_type => String, { nullable: true })
    accountHolder: string

    @Field(_type => String, { nullable: true })
    accountNumber: string

    @Field(_type => String, { nullable: true })
    status: string

    @Field(_type => String, { nullable: true })
    leaderCode: string

    @Field(() => GraphQLJSON, { nullable: true })
    data: JSON
}

@InputType()
export class EmployeeBulkCreateImport extends OmitType(
    ImportEmployeeArgs,
    ['id', 'resigned', 'resignationReason', 'resignationType', 'resignationDetailReason', 'lastWorkingOn', 'leaveOn', 'data']
){
}

@InputType()
export class UpsertEmployeeDataArgs {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(() => GraphQLJSON, { nullable: true })
    data: JSON
}

@InputType()
export class QueryScheduleArgs {
    @Field(_type => Float)
    startAt: number

    @Field(_type => Float)
    endAt: number

    @Field(_type => ScheduleType, { defaultValue: ScheduleType.Meeting })
    type: ScheduleType
}

@InputType()
export class EmployeeReportFilterArgs {
    @Field(_type => String, { nullable: true })
    l1Id: string

    @Field(_type => String, { nullable: true })
    l2Id: string

    @Field(_type => String, { nullable: true })
    l3Id: string

    @Field(_type => String, { nullable: true })
    l4Id: string

    @Field(_type => String, { nullable: true })
    l5Id: string

    @Field(_type => String, { nullable: true })
    l6Id: string

    @Field(_type => String, { nullable: true })
    lCurrentId: string

    @Field(_type => String, { nullable: true })
    titleId: string

    @Field(_type => String, { nullable: true })
    major: string

    @Field(_type => DatePeriod, { nullable: true })
    onboardingOn: DatePeriod

    @Field(_type => DatePeriod, { nullable: true })
    leaveOn: DatePeriod

    @Field(_type => Int, { nullable: true })
    seniority: number

    @Field(_type => String, { nullable: true })
    resignationType: string

    @Field(_type => String, { nullable: true })
    resignationReason: string

    @Field(_type => DatePeriod, { nullable: true })
    lastWorkingOn: DatePeriod
}

@InputType()
export class EmployeeReportFilterListArgs extends EmployeeReportFilterArgs {
    @Field({ nullable: true, defaultValue: 0 })
    page: number

    @Field({ nullable: true, defaultValue: 20 })
    size: number

    @Field({ nullable: true, defaultValue: false })
    resigned: boolean
}

@InputType()
export class OfficeUserFilter extends EmployeeReportFilterListArgs {
    @Field({ nullable: true })
    keyword?: string

    @Field(_type => ObjectStatus, { nullable: true })
    status?: ObjectStatus

    @Field(_type => [String], { nullable: true })
    departmentIds?: string[]
}

@InputType()
export class AnalysisNumberOfUserUsedAppFilter {
    @Field(_type => Float, { nullable: true })
    latestLoginTime?: number

    @Field(_type => String, { nullable: true })
    orgChardId?: string
}

@InputType()
export class OfficeEmployeeAvatarUpdateInput {
    @Field()
    @IsExistAttachmentsIamValidate()
    imageId: string
}