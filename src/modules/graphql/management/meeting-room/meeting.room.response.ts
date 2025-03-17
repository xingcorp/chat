import { Field, ObjectType } from "@nestjs/graphql"
import { PagingData } from "src/models/base/paging.response"
import { MeetingRoom } from "../../../../models/entities"

@ObjectType({ implements: PagingData })
export class MeetingRoomsResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [MeetingRoom], { nullable: true })
    meetingRooms: MeetingRoom[]
}