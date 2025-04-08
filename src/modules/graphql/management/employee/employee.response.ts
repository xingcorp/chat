import { Field, Int, ObjectType, OmitType } from "@nestjs/graphql"
import GraphQLJSON from "graphql-type-json"
import { PagingData } from "src/models/base/paging.response"
import { OfficeUser, UserSchedule } from "src/models/entities"

@ObjectType({ implements: PagingData })
export class OfficeUserResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [OfficeUser], { nullable: true })
    officeUsers?: OfficeUser[]
}

@ObjectType({ implements: PagingData })
export class BulkUpsertEmployeeResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [UpsertEmployeeResponse], { nullable: true })
    records?: UpsertEmployeeResponse[]
}

@ObjectType()
export class UpsertEmployeeResponse {
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

    @Field(_type => String, { nullable: true })
    errorMessage: string
}

@ObjectType({ implements: PagingData })
export class BulkImportEmployeeResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [ImportEmployeeResponse], { nullable: true })
    records?: ImportEmployeeResponse[]
}

@ObjectType()
export class ImportEmployeeResponse {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    fullname: string

    @Field(_type => String, { nullable: true })
    phone: string

    @Field(_type => String, { nullable: true })
    title: string

    @Field(_type => String, { nullable: true })
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
    idCardIssuedOn: string

    @Field(_type => String, { nullable: true })
    idCardIssuedPlace: string

    @Field(_type => String, { nullable: true })
    birthday: string

    @Field(_type => String, { nullable: true })
    hrCode: string

    @Field(_type => String, { nullable: true })
    major: string

    @Field(_type => String, { nullable: true })
    onboardingOn: string

    @Field(_type => String, { nullable: true })
    officalWorkingOn: string

    @Field(_type => String, { nullable: true })
    resigned: string

    @Field(_type => String, { nullable: true })
    resignationType: string

    @Field(_type => String, { nullable: true })
    resignationReason: string

    @Field(_type => String, { nullable: true })
    resignationDetailReason: string

    @Field(_type => String, { nullable: true })
    lastWorkingOn: string

    @Field(_type => String, { nullable: true })
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
    errorMessage: string

    @Field(_type => GraphQLJSON, { nullable: true })
    data: JSON
}

@ObjectType({ implements: PagingData })
export class EmployeeBulkCreateResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [ImportBulkCreateResponse], { nullable: true })
    records?: ImportBulkCreateResponse[]
}

@ObjectType()
export class ImportBulkCreateResponse extends OmitType(
    ImportEmployeeResponse,
    ['id', 'resigned', 'resignationReason', 'resignationType', 'resignationDetailReason', 'lastWorkingOn', 'leaveOn', 'data']
){
}

@ObjectType({ implements: PagingData })
export class BulkUpsertEmployeeDataResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [UpsertEmployeeDataResponse], { nullable: true })
    records?: UpsertEmployeeDataResponse[]
}

@ObjectType()
export class UpsertEmployeeDataResponse {
    @Field(_type => String, { nullable: true })
    code: string

    @Field(() => GraphQLJSON, { nullable: true })
    data: JSON

    @Field(_type => String, { nullable: true })
    errorMessage: string
}

@ObjectType({ implements: PagingData })
export class SchedulesResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [UserSchedule], { nullable: true })
    schedules?: UserSchedule[]
}


@ObjectType()
export class AnalysisNumberOfUserUsedAppResponse {
    @Field(_type => Int, { defaultValue: 0 })
    total: number

    @Field(_type => [OfficeUser], { nullable: true })
    records?: OfficeUser[]
}

@ObjectType()
export class ImportUserFieldsGetResponse {
    @Field(_type => [String], { nullable: true })
    fields?: String[]
}