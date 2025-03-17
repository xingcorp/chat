import { Field, InputType, Int } from "@nestjs/graphql"
import { ObjectStatus } from "../../../../models/entities/profile.info.block"
import { IsOrgChartIdExist } from "../../../core/middleware/validator"

@InputType()
export class QueryMeetingRoomsArgs {
    @Field(_type => String, { nullable: true })
    keyword: string

    @Field(_type => String, { nullable: true })
    @IsOrgChartIdExist()
    organizationId: string

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus

    @Field({ nullable: true })
    approvalFormId?: string

    @Field(_type => Int, { nullable: true, defaultValue: 0 })
    page?: number

    @Field(_type => Int, { nullable: true, defaultValue: 20 })
    size?: number
}

@InputType()
export class CreateMeetingRoomArgs {
    @Field(_type => String)
    name: string

    @Field(_type => String)
    @IsOrgChartIdExist()
    organizationId: string

    @Field(_type => Int)
    capacity: number

    @Field(_type => String)
    color: string

    @Field({ nullable: true })
    approvalFormId: string

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus
}

@InputType()
export class UpdateMeetingRoomArgs {
    @Field(_type => String)
    id: string

    @Field(_type => String)
    name: string

    @Field(_type => String)
    @IsOrgChartIdExist()
    organizationId: string

    @Field(_type => Int)
    capacity: number

    @Field(_type => String)
    color: string

    @Field({ nullable: true })
    approvalFormId: string

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus
}

@InputType()
export class DeleteMeetingRoomArgs {
    @Field(_type => String)
    id: string
}