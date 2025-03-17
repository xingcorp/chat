import { Field, Float, Int, ObjectType } from "@nestjs/graphql";
import GraphQLJSON from "graphql-type-json";
import { PagingData } from "@models/base/paging.response";
import { OfficeUserPaycheck } from "@models/entities";

@ObjectType()
export class UserPaycheckBulkResponse {
    @Field(_type => String, { nullable: true })
    id?: string

    @Field(_type => String, { nullable: true })
    code?: string

    @Field(_type => String, { nullable: true })
    name?: string

    @Field(_type => Int, { nullable: true })
    month?: number

    @Field(_type => Int, { nullable: true })
    year?: number

    @Field(_type => Float, { nullable: true })
    wage?: number

    @Field(_type => String, { nullable: true })
    userCode?: string

    @Field(_type => String, { nullable: true })
    payrollCode?: string

    @Field(() => GraphQLJSON, { nullable: true })
    metadata?: JSON

    @Field(_type => String, { nullable: true })
    errorMessage: string
}

@ObjectType()
export class UserPaycheckBulkUpsertResponse {
    @Field(_type => [UserPaycheckBulkResponse], { nullable: true })
    records?: UserPaycheckBulkResponse[]
}

@ObjectType({ implements: PagingData })
export class UserPaycheckListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [OfficeUserPaycheck], { nullable: true })
    userPaychecks?: OfficeUserPaycheck[]
}