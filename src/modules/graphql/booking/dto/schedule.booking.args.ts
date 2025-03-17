import { Field, Float, InputType, OmitType, PartialType } from "@nestjs/graphql"
import {
    MeetingRoomSchedule
} from "@models/entities/meeting.room.schedule"
import {
    IsExistAndCanModifyScheduleMeetingDbValidate
} from "@decorators/validation/db/meeting/schedule/is-exist-and-can-modify.schedule.meeting.db.validate";
import { BookMeetingRoomArgs } from "@modules/graphql/booking/dto/booking.args";
import {
    IsValidTimeScheduleMeetingDbValidate
} from "@decorators/validation/db/meeting/schedule/is-valid-time.schedule.meeting.db.validate";
import { NotificationCampaignDifferentArgs } from "@core/iam/notification/notification.args";
import {
    IsExistScheduleMeetingDbValidate
} from "@decorators/validation/db/meeting/schedule/is-exist.schedule.meeting.db.validate";

@InputType()
export class BookingScheduleUpdateInput extends OmitType(
    BookMeetingRoomArgs,
    ['repeatConfig', 'repeatedDays', 'repeatedEndAt']
){
    @Field(_type => String)
    @IsExistAndCanModifyScheduleMeetingDbValidate()
    @IsValidTimeScheduleMeetingDbValidate()
    scheduleId: string

    schedule?: MeetingRoomSchedule
}

@InputType()
export class BookingScheduleRemoveInput {
    @Field(_type => String)
    @IsExistAndCanModifyScheduleMeetingDbValidate()
    scheduleId: string

    schedule?: MeetingRoomSchedule

    @Field(_type => String, { nullable: true })
    description: string
}

@InputType()
export class BookingScheduleNotifyInput extends NotificationCampaignDifferentArgs {
    @Field(_type => String)
    @IsExistScheduleMeetingDbValidate()
    scheduleId: string

    schedule?: MeetingRoomSchedule
}