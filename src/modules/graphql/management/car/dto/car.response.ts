import { Field, ObjectType } from "@nestjs/graphql"
import { PagingData } from "@models/base/paging.response"
import { Car } from "@models/entities/car"
import { CarBookingSchedule } from "@models/entities/car.booking.schedule"

@ObjectType({ implements: PagingData })
export class CarResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [Car], { nullable: true })
    cars?: Car[]
}

@ObjectType({ implements: PagingData })
export class CarBookingScheduleResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [CarBookingSchedule], { nullable: true })
    schedules?: CarBookingSchedule[]
}