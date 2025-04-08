import { Field, InputType, registerEnumType } from "@nestjs/graphql"
import { IsNotEmpty, IsUUID } from "class-validator"
import { ActiveStatus, GetOrgChartType } from "@common/enum.common";
import { ObjectStatus } from "@models/entities/profile.info.block";
import {
    IsCodeExistedOrgChartDbValidate
} from "@decorators/validation/db/org-chart/is-code-existed.org-chart.db.validate";

registerEnumType(GetOrgChartType, {name: 'GetOrgChartType'})

@InputType()
export class OrgChartArgs {
    @Field({ nullable: false })
    // @IsNotEmpty()
    name: string

    @Field({ nullable: true })
    parentId: string

    @Field({ nullable: true })
    note: string

    @Field({ nullable: true })
    approverId: string

    @Field(_type => ObjectStatus, { nullable: true, defaultValue: ObjectStatus.Active })
    status: ObjectStatus

    @Field(_type => String, { nullable: true })
    @IsCodeExistedOrgChartDbValidate()
    code: string
}

@InputType()
export class EditOrgChartArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field({ nullable: true })
    name: string

    @Field({ nullable: true })
    parentId: string

    @Field({ nullable: true })
    note: string

    @Field({ nullable: true })
    approverId: string

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus
}

@InputType()
export class UpsertOrgChartArgs {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    parentCode: string
}


@InputType()
export class SysOrgChartFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    adminId?: string

    @Field({ nullable: true, defaultValue: true })
    haveNoManager?: boolean

    @Field(_type => GetOrgChartType, { nullable: true, defaultValue: GetOrgChartType.Only })
    orgType?: GetOrgChartType
}

@InputType()
export class OrgChartFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    adminId?: string

    @Field({ nullable: true, defaultValue: false })
    haveNoManager?: boolean

    @Field(_type => GetOrgChartType, { nullable: true, defaultValue: GetOrgChartType.Only })
    orgType?: GetOrgChartType
}

@InputType()
export class OrgChartFullListFilter {
    @Field({ nullable: true })
    page?: number

    @Field({ nullable: true })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    rootId?: string

    @Field(() => [ActiveStatus], { nullable: true })
    statuses?: ActiveStatus[]
}

@InputType()
export class UserOrgChartFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true, defaultValue: true })
    onlyActive?: boolean

    @Field({ nullable: true, defaultValue: true })
    notResigned?: boolean
}

@InputType()
export class UserSysOrgChartFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true, defaultValue: true })
    onlyActive?: boolean

    @Field({ nullable: true, defaultValue: true })
    notResigned?: boolean

    @Field(_type => GetOrgChartType, { nullable: true, defaultValue: GetOrgChartType.Only })
    orgType?: GetOrgChartType
}
