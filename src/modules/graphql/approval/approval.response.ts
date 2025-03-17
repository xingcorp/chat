import { Field, Int, ObjectType } from "@nestjs/graphql"
import { PagingData } from "src/models/base/paging.response"
import { ApprovalForm, OfficeApproval, OfficeFilter } from "src/models/entities"
import { ApprovalFilter } from "@modules/graphql/approval/approval.args";
import GraphQLJSON from "graphql-type-json";
import { NotificationCampaign } from "@models/entities/notification.campaign";

@ObjectType({ implements: PagingData })
export class ApprovalFormResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [ApprovalForm], { nullable: true })
    approvalForms?: ApprovalForm[]
}

@ObjectType({ implements: PagingData })
export class ApprovalResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [OfficeApproval], { nullable: true })
    approvals?: OfficeApproval[]
}

@ObjectType()
export class ApprovalFilterResponse  {
    @Field({ nullable: true })
    name: string

    @Field({ nullable: true })
    order: number

    @Field(() => ApprovalFilter,{ nullable: true })
    filter: ApprovalFilter
}

@ObjectType()
export class ApprovalMenuCategoryItemResponse  {
    @Field({ nullable: true })
    id?: string

    @Field({ nullable: true })
    type?: string

    @Field(() => [OfficeFilter], { nullable: true })
    list: OfficeFilter[]
}

@ObjectType()
export class ApprovalMenuCategoryResponse  {
    @Field(() => [ApprovalMenuCategoryItemResponse], { nullable: true })
    forms: ApprovalMenuCategoryItemResponse[]

    @Field(() => [ApprovalMenuCategoryItemResponse], { nullable: true })
    departments: ApprovalMenuCategoryItemResponse[]

    @Field(() => [ApprovalMenuCategoryItemResponse], { nullable: true })
    creators: ApprovalMenuCategoryItemResponse[]

    @Field(() => [ApprovalMenuCategoryItemResponse], { nullable: true })
    approvals: ApprovalMenuCategoryItemResponse[]

    @Field(() => [ApprovalMenuCategoryItemResponse], { nullable: true })
    statuses: ApprovalMenuCategoryItemResponse[]
}

@ObjectType()
export class ApprovalMenuCountResponse  {
    @Field(() => Int, { nullable: true })
    waiting: number

    @Field(() => Int, { nullable: true })
    approved: number

    @Field(() => Int, { nullable: true })
    notify: number

    @Field(() => Int, { nullable: true })
    submitted: number

    @Field(() => Int, { nullable: true })
    draft: number
}

@ObjectType()
export class ApprovalMenuResponse  {
    @Field(() => ApprovalMenuCountResponse,{ nullable: true })
    count: ApprovalMenuCountResponse

/*
    @Field(() => ApprovalMenuCategoryResponse,{ nullable: true })
    category: ApprovalMenuCategoryResponse
*/

    /*@Field(() => [OfficeFilter],{ nullable: true })
    categoryFilter: OfficeFilter[]*/
}

@ObjectType({ implements: PagingData })
export class ApprovalFilterListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [OfficeFilter], { nullable: true })
    records?: OfficeFilter[]
}