import { Field, ObjectType } from "@nestjs/graphql"
import { PagingData } from "src/models/base/paging.response"
import { OfficeOrgChart } from "src/models/entities"

@ObjectType({ implements: PagingData })
export class OrgChartResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [OfficeOrgChart], { nullable: true })
    orgCharts?: OfficeOrgChart[]
}

@ObjectType({ implements: PagingData })
export class BulkUpsertOrgChartResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [UpsertOrgChartResponse], { nullable: true })
    records?: UpsertOrgChartResponse[]
}

@ObjectType()
export class UpsertOrgChartResponse {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: true })
    code: string

    @Field(_type => String, { nullable: true })
    name: string

    @Field(_type => String, { nullable: true })
    parentCode: string

    @Field(_type => String, { nullable: true })
    errorMessage: string
}