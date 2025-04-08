import { Field, Int, ObjectType } from "@nestjs/graphql";
import { PagingData } from "@models/base/paging.response";
import { OfficeFilter, OfficeTask } from "@models/entities";
import { TaskStatus } from "@enum/task/task.enum";

@ObjectType()
export class OfficeTaskStatisticResponse {
    @Field(_type => TaskStatus, { nullable: true })
    status?: TaskStatus

    @Field(_type => Int, { nullable: true })
    count?: number
}

@ObjectType({ implements: PagingData })
export class OfficeTaskListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [OfficeTask], { nullable: true })
    records?: OfficeTask[]

    @Field(_type => [OfficeTaskStatisticResponse], { nullable: true })
    statistics?: OfficeTaskStatisticResponse[]
}

@ObjectType({ implements: PagingData })
export class TaskFilterListResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [OfficeFilter], { nullable: true })
    records?: OfficeFilter[]
}