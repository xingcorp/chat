import { Field, Float, InputType, Int, ObjectType, PartialType, registerEnumType } from "@nestjs/graphql"
import { IsOrgChartIdExist } from "@core/middleware/validator"
import { RepeatedDay } from "@models/entities/booking/booking.meeting.room"
import { BookingCarProgress } from "@models/entities/booking/booking.car"
import GraphQLJSON from "graphql-type-json"
import {
    EquimentsForMettingRoom,
    LogisticsForMettingRoom,
    MeetingRoomSchedule
} from "@models/entities/meeting.room.schedule"
import { NotificationCampaignDifferentArgs } from "@core/iam/notification/notification.args";
import { RequestStatus } from "@models/entities/car.booking.request";
import { IsFutureFromNow } from "@decorators/validation/utils/is-future-from-now.validate";
import { IsGreaterThan } from "@decorators/validation/utils/is-greater-than.validate";
import { ValidateIf, ValidateNested } from "class-validator";
import { CloneDatePeriodEnum } from "@enum/clone/date.clone.enum";
import { IsExistRoomDbValidate } from "@decorators/validation/db/room/room/is-exist.room.db.validate";
import { MeetingRoom, OfficeUser } from "@models/entities";
import { IsExistUserDbValidate } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { Type } from "class-transformer";
import { IsExistAndGetUserDbValidate } from "@decorators/validation/db/user/is-exist-and-get.user.db.validate";
import { DayOfWeek } from "@common/constant.common"

@InputType()
export class BookMeetingRoomRepeatConfigInput {
    @Field(_type => CloneDatePeriodEnum, { nullable: true })
    periodType: CloneDatePeriodEnum

    @Field(() => Float, { nullable: true, defaultValue: 7 })
    timeZone: number

    @Field(() => [DayOfWeek], { nullable: true })
    weekDays: DayOfWeek[]

    @Field(() => [Int], { nullable: true })
    monthDays: number[]

    @Field(_type => Float, { nullable: true })
    startAt: number

    @Field(_type => Float, { nullable: true })
    @ValidateIf(o => o.periodType && o.periodType !== CloneDatePeriodEnum.Now)
    @IsDefinedValidate({
        message: 'CloneConfigByDateNeedEndOfSchedule'
    })
    endAt: number
}

@InputType()
export class BookMeetingRoomArgs {
    @Field(_type => String)
    @IsExistRoomDbValidate()
    meetingRoomId: string

    meetingRoom?: MeetingRoom

    @Field(_type => Float)
    @IsFutureFromNow({
        message: 'BookingRoomNotInThePast'
    })
    startAt: number

    @Field(_type => Float)
    @IsGreaterThan('startAt', {
        message: 'WrongEndDatePeriod'
    })
    endAt: number

    @Field(_type => String, { nullable: true })
    @ValidateIf(o => !o.organizationId)
    @IsOrgChartIdExist()
    organizationId: string

    @Field(_type => String)
    meetingContent: string

    @Field(_type => String)
    @IsExistAndGetUserDbValidate({
        message: 'BookingRoomHostNotFound'
    })
    hostId: string

    host?: OfficeUser

    @Field(_type => Int)
    quantity: number

    @Field(_type => [String], { nullable: true })
    @IsExistAndGetUserDbValidate({
        message: 'BookingRoomParticipantNotFound'
    })
    participantIds: string[]

    participants?: OfficeUser[]

    @Field(_type => String, { nullable: true })
    note: string

    /*legacy*/
    @Field(_type => Float, { nullable: true, description: 'legacy' })
    repeatedEndAt: number

    /*legacy*/
    @Field(_type => [RepeatedDay], { nullable: true, description: 'legacy' })
    repeatedDays: RepeatedDay[]

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    formFieldData: JSON

    @Field(_type => [EquimentsForMettingRoom], { defaultValue: [] })
    equiments: EquimentsForMettingRoom[]

    @Field(_type => [LogisticsForMettingRoom], { defaultValue: [] })
    logistics: LogisticsForMettingRoom[]

    @Field(_type => NotificationCampaignDifferentArgs, { nullable: true })
    notify: NotificationCampaignDifferentArgs

    @Field(() => [String], { nullable: true })
    subscriberIds: string[]

    @Field(_type => BookMeetingRoomRepeatConfigInput, { nullable: true})
    @Type(() => BookMeetingRoomRepeatConfigInput)
    @ValidateNested({each: true})
    repeatConfig: BookMeetingRoomRepeatConfigInput
}

@InputType()
export class UpdateBookingMeetingRoomArgs {
    @Field(_type => String)
    bookingId: string

    @Field(_type => String, {nullable: true})
    scheduleId: string

    @Field(_type => String)
    meetingRoomId: string

    @Field(_type => Float)
    startAt: number

    @Field(_type => Float)
    @IsGreaterThan('startAt', {
        message: 'WrongEndDatePeriod'
    })
    endAt: number

    @Field(_type => String)
    @IsOrgChartIdExist()
    organizationId: string

    @Field(_type => String)
    meetingContent: string

    @Field(_type => String)
    hostId: string

    @Field(_type => Int)
    quantity: number

    @Field(_type => [String], { nullable: true })
    participantIds: string[]

    @Field(_type => String, { nullable: true })
    note: string

    /*legacy*/
    @Field(_type => Float, { nullable: true, description: 'legacy' })
    repeatedEndAt: number

    /*legacy*/
    @Field(_type => [RepeatedDay], { nullable: true, description: 'legacy' })
    repeatedDays: RepeatedDay[]

    @Field(_type => [EquimentsForMettingRoom], { defaultValue: [] })
    equiments: EquimentsForMettingRoom[]

    @Field(_type => [LogisticsForMettingRoom], { defaultValue: [] })
    logistics: LogisticsForMettingRoom[]

    @Field(_type => NotificationCampaignDifferentArgs, { nullable: true })
    notify: NotificationCampaignDifferentArgs

    @Field(_type => BookMeetingRoomRepeatConfigInput, { nullable: true})
    repeatConfig: BookMeetingRoomRepeatConfigInput
}

@InputType()
export class DeleteBookingMeetingRoomArgs {
    @Field(_type => String)
    id: string

    @Field(_type => String, { nullable: true })
    description: string
}


@InputType()
export class NotificationBookingMeetingRoomArgs extends NotificationCampaignDifferentArgs {
    @Field(_type => String)
    bookingId: string
}

export enum CaseQueryMeeting {
    All,
    OnlyMe
}
registerEnumType(CaseQueryMeeting, { name: 'CaseQueryMeeting' })
registerEnumType(RequestStatus, { name: 'RequestStatus' })

@InputType()
export class QueryBookingMeetingRoomArgs {
    @Field(_type => Float)
    startAt: number

    @Field(_type => Float)
    endAt: number

    @Field(_type => CaseQueryMeeting)
    case: CaseQueryMeeting

    @Field(_type => [String], { defaultValue: [] })
    meetingRoomIds: string[]

    @Field(_type => Boolean, { defaultValue: false })
    isAllRoom: boolean

    @Field(_type => String, { nullable: true })
    orgChartId: string

    @Field(_type => RequestStatus, { nullable: true })
    bookingStatus: RequestStatus
}

@InputType()
export class BookCarArgs {
    @Field(_type => String)
    carType: string

    @Field(_type => Float)
    startAt: Date

    @Field(_type => Float)
    endAt: Date

    @Field(_type => String, { nullable: true })
    note: string

    @Field(_type => String)
    pickupAddress: string

    @Field(_type => String)
    destinationAddress: string

    @Field(_type => String)
    leaderId: string
}

@InputType()
export class ResponseBookingCarArgs {
    @Field(_type => String)
    bookingId: string

    @Field(_type => String, { nullable: true })
    note: string

    @Field(_type => Boolean)
    isApprove: boolean
}

@InputType()
export class BookingCarFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page: number

    @Field({ nullable: true, defaultValue: 20 })
    size: number

    @Field({ nullable: true })
    keyword: string

    @Field({ nullable: true })
    progress: BookingCarProgress
}
