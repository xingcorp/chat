import { Field, Int, ObjectType } from "@nestjs/graphql"
import { BookingMeetingRoom, MeetingRoomSchedule } from "@models/entities"
import { BookingCar } from "@models/entities/booking/booking.car"
import { PagingData } from "@models/base/paging.response"

@ObjectType()
export class BookMeetingRoomsResponse {
    @Field(_type => BookingMeetingRoom, { nullable: true })
    booking: BookingMeetingRoom
}

@ObjectType()
export class MeetingDetailResponse {
    @Field(_type => MeetingRoomSchedule, { nullable: true })
    meeting: MeetingRoomSchedule
}

@ObjectType()
export class MeetingsResponse {
    @Field(_type => Int)
    total: number

    @Field(_type => [MeetingRoomSchedule], { nullable: true })
    meetings: MeetingRoomSchedule[]
}

@ObjectType()
export class BookingCarResponse {
    @Field(_type => BookingCar, { nullable: true })
    booking: BookingCar
}

@ObjectType({ implements: PagingData })
export class BookingsCarResponse implements PagingData {
    total: number
    count: number

    @Field(_type => [BookingCar], { nullable: true })
    bookings: BookingCar[]
}