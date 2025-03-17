import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { UserWorkProfile } from "@models/entities";
import { WorkProfileBulkUpsertInput } from "@modules/graphql/management/work-profile/dto/work-profile.args";
import GraphQLJSON from "graphql-type-json";
import { WorkProfileAction } from "@enum/work-profile/work-profile.enum";

@ObjectType()
export class WorkProfileInfoType {
    @Field(_type => String, {nullable: true})
    key: string

    @Field(_type => WorkProfileAction, {nullable: true})
    type: WorkProfileAction

    @Field(_type => String, {nullable: true})
    title: string
}

@ObjectType({ implements: PagingData })
export class WorkProfileListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [UserWorkProfile], { nullable: true })
    records?: UserWorkProfile[]
}

@ObjectType()
export class WorkProfileBulkUpsertRecordResponse extends WorkProfileBulkUpsertInput {
    @Field({nullable: true})
    errorMessage: string

    @Field(_type => GraphQLJSON, { nullable: true })
    metadata: JSON
}

@ObjectType({ implements: PagingData })
export class WorkProfileBulkUpsertResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [WorkProfileBulkUpsertRecordResponse], { nullable: true })
    records?: WorkProfileBulkUpsertRecordResponse[]
}
