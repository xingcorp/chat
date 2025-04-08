import { Field, InputType, OmitType } from "@nestjs/graphql";
import { OfficeBookingCarArgs } from "@modules/graphql/management/car/dto/car.args";
import { CarBookingSchedule } from "@models/entities/car.booking.schedule";
import {
    IsExistAndCanModifyScheduleCarDbValidate
} from "@decorators/validation/db/car/schedule/is-exist-and-can-modify.schedule.car.db.validate";
import {
    IsValidTimeScheduleCarDbValidate
} from "@decorators/validation/db/car/schedule/is-valid-time.schedule.car.db.validate";

@InputType()
export class CarBookingScheduleUpdateInput extends OmitType(
    OfficeBookingCarArgs,
    ['repeatConfig']
){
    @Field(_type => String)
    @IsExistAndCanModifyScheduleCarDbValidate()
    @IsValidTimeScheduleCarDbValidate()
    scheduleId: string

    schedule?: CarBookingSchedule
}

@InputType()
export class CarBookingScheduleRemoveInput {
    @Field(_type => String)
    @IsExistAndCanModifyScheduleCarDbValidate()
    scheduleId: string

    schedule?: CarBookingSchedule

    @Field(_type => String, { nullable: true })
    description: string
}