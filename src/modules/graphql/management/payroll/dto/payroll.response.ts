import { Field, ObjectType} from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { OfficePayroll } from "@models/entities";

@ObjectType()
export class PayrollBulkResponse {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: true })
    code?: string

    @Field(_type => String, { nullable: true })
    name?: string

    @Field(_type => String, { nullable: true })
    status?: string

    @Field(_type => String, { nullable: true })
    errorMessage: string
}

@ObjectType()
export class PayrollBulkUpsertResponse {
    @Field(_type => [PayrollBulkResponse], { nullable: true })
    records?: PayrollBulkResponse[]
}

@ObjectType()
export class PayrollBlockBulkResponse {
    @Field(_type => String, { nullable: true })
    id: string

    @Field(_type => String, { nullable: true })
    code?: string

    @Field(_type => String, { nullable: true })
    name?: string

    @Field(_type => String, { nullable: true })
    status?: string

    @Field(_type => String, { nullable: true })
    payrollCode?: string

    @Field(_type => String, { nullable: true })
    errorMessage: string
}

@ObjectType()
export class PayrollBlockBulkUpsertResponse {
    @Field(_type => [PayrollBlockBulkResponse], { nullable: true })
    records?: PayrollBlockBulkResponse[]
}

@ObjectType({ implements: PagingData })
export class PayrollListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [OfficePayroll], { nullable: true })
    payrolls?: OfficePayroll[]
}