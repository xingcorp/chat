import { Field, Float, InputType, Int } from "@nestjs/graphql"
import { IsNotEmpty, IsUUID, ValidateIf, ValidateNested } from "class-validator"
import GraphQLJSON from "graphql-type-json"
import { ObjectStatus } from "@models/entities/profile.info.block"
import { IsFutureFromNow } from "@decorators/validation/utils/is-future-from-now.validate";
import { IsGreaterThanOrEqual } from "@decorators/validation/utils/is-greater-than-or-equal.validate";
import { IsExistCarDbValidate } from "@decorators/validation/db/car/car/is-exist.car.db.validate";
import { Car } from "@models/entities/car";
import { Type } from "class-transformer";
import { CloneDatePeriodEnum } from "@enum/clone/date.clone.enum";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { NotificationCampaignDifferentArgs } from "@core/iam/notification/notification.args";
import { DayOfWeek } from "@common/constant.common";

@InputType()
export class OfficeCarArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    model: string

    @Field({ nullable: true })
    orgChartId: string

    @Field(_type => Int, { nullable: false })
    capacity: number

    @Field(_type => String, { nullable: false })
    plateNumber: string

    @Field(_type => String, { nullable: false })
    @IsNotEmpty()
    @IsUUID()
    driverId: string

    @Field({ nullable: true })
    color: string

    @Field({ nullable: true })
    approvalFormId: string

    @Field(_type => ObjectStatus, { nullable: false, defaultValue: ObjectStatus.Active })
    status: ObjectStatus
}

@InputType()
export class EditOfficeCarArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field(_type => String, { nullable: true })
    model: string

    @Field(_type => String, { nullable: true })
    orgChartId: string

    @Field(_type => Int, { nullable: true })
    capacity: number

    @Field(_type => String, { nullable: true })
    plateNumber: string

    @Field(_type => String, { nullable: true })
    driverId: string

    @Field(_type => String, { nullable: true })
    approvalFormId: string

    @Field(_type => String, { nullable: true })
    color: string

    @Field(_type => ObjectStatus, { nullable: true })
    status: ObjectStatus
}

@InputType()
export class OfficeCarFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field(_type => ObjectStatus, { nullable: true })
    status?: ObjectStatus

    @Field({ nullable: true })
    model?: string

    @Field({ nullable: true })
    orgChartId?: string

    @Field({ nullable: true })
    approvalFormId?: string

    @Field({ nullable: true })
    driverId?: string
}

@InputType()
export class CarBookingScheduleFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field(_type => [String], { nullable: true })
    carIds?: string[]

    @Field(() => Boolean, { nullable: false, defaultValue: false })
    owner: boolean

    @Field({ nullable: true })
    fromDate?: number

    @Field({ nullable: true })
    toDate?: number
}

@InputType()
export class OfficeActiveCarFilter {
    @Field({ nullable: true, defaultValue: 0 })
    page?: number

    @Field({ nullable: true, defaultValue: 20 })
    size?: number

    @Field({ nullable: true })
    keyword?: string

    @Field({ nullable: true })
    companyId?: string
}

@InputType()
export class BookCarRepeatConfigInput {
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
export class OfficeBookingCarArgs {
    @Field({ nullable: false })
    @IsExistCarDbValidate()
    carId: string

    car?: Car

    @Field(_type => Float, { nullable: false })
    @IsFutureFromNow({
        message: 'BookingCarNotInThePast'
    })
    startAt: number

    @Field(_type => Float, { nullable: false })
    @IsGreaterThanOrEqual('startAt', {
        message: 'WrongEndDatePeriod'
    })
    endAt: number

    @Field(_type => String, { nullable: false })
    fromAddress: string

    @Field(_type => String, { nullable: false })
    toAddress: string

    @Field({ nullable: true })
    note: string

    @Field(() => GraphQLJSON, { nullable: true, defaultValue: null })
    formFieldData: JSON

    @Field(() => [String], { nullable: true })
    subscriberIds: string[]

    @Field(_type => NotificationCampaignDifferentArgs, { nullable: true })
    notify: NotificationCampaignDifferentArgs

    @Field(_type => BookCarRepeatConfigInput, { nullable: true})
    @Type(() => BookCarRepeatConfigInput)
    @ValidateNested({each: true})
    repeatConfig: BookCarRepeatConfigInput
}