import { Field, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { ApprovalFormGroup } from "@models/entities";

@ObjectType({ implements: PagingData })
export class ApprovalFormGroupResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [ApprovalFormGroup], { nullable: true })
    records?: ApprovalFormGroup[]
}