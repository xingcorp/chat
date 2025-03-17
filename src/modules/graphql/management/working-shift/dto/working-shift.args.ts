import { Field, Float, InputType, registerEnumType } from "@nestjs/graphql";
import { ArrayMinSize, IsNotEmpty, Max, Min, ValidateIf } from "class-validator";
import { DayOfTheWeek } from "@utils/enum.utils";
import { OutOfTime, WorkShiftOutOfTimePunishment } from "@models/entities/working-shifts/working-shift.out-of-time";
import { OverTime } from "@models/entities/working-shifts/working-shift.over-time";
import { IsBetween } from "@decorators/validation/utils/is-between.validate";
import { Expose } from "class-transformer";

registerEnumType(DayOfTheWeek, {name: 'DayOfTheWeek'})
registerEnumType(OutOfTime, {name: 'OutOfTime'})
registerEnumType(WorkShiftOutOfTimePunishment, {name: 'WorkShiftOutOfTimePunishment'})
registerEnumType(OverTime, {name: 'OverTime'})

@InputType()
export class WorkingShiftOutOfTimeInput {
    @Field(_type => OutOfTime, { nullable: true })
    type: OutOfTime

    @Field(_type => Float, { nullable: true })
    from: number

    @Field(_type => Float, { nullable: true })
    to: number

    @Field(_type => WorkShiftOutOfTimePunishment, { nullable: true })
    punishmentType: WorkShiftOutOfTimePunishment

    @Field(_type => Float, { nullable: true })
    @Min(0, {
        message: 'ShiftValueFromZeroToOne'
    })
    @Max(1, {
        message: 'ShiftValueFromZeroToOne'
    })
    punishmentValue: number
}

@InputType()
export class WorkingShiftOverTimeInput {
    @Field(_type => OverTime, { nullable: true })
    type: OverTime

    @Field(_type => Float, { nullable: true })
    minTime: number

    @Field(_type => Float, { nullable: true })
    maxTime: number

    @Field(_type => Float, { nullable: true })
    startTime: number

    @Field(_type => Boolean, { nullable: true })
    isStartAfterEndShift: boolean

    // @Expose()
    // @ValidateIf()
    // checkValidateStartTime: any
}

@InputType()
export class WorkingShiftInput {
    @Field({ nullable: false })
    @IsNotEmpty()
    name: string

    // TODO: hide if auto generate
    @Field({ nullable: false })
    @IsNotEmpty()
    code: string

    @Field(_type => Float, { nullable: false })
    @IsNotEmpty()
    startDate: number

    @Field(_type => Float, { nullable: false })
    @IsNotEmpty()
    endDate: number

    @Field(_type => [DayOfTheWeek], { nullable: false })
    @IsNotEmpty()
    @ArrayMinSize(1, {
        message: 'ShiftAtLeastADay'
    })
    dayActive: DayOfTheWeek[]

    @Field(_type => Float, { nullable: false })
    @IsNotEmpty()
    checkInTime: number

    @Field(_type => Float, { nullable: false })
    @IsNotEmpty()
    checkOutTime: number

    @Field({ nullable: false })
    @IsNotEmpty()
    active: boolean

    @Field(_type => Float, { nullable: true })
    @ValidateIf(o => o.lunchStartTime)
    @IsBetween('checkInTime', 'checkOutTime', {
        message: 'ShiftLunchShoutBetweenWorkDay'
    })
    lunchStartTime: number

    @Field(_type => Float, { nullable: true })
    @ValidateIf(o => o.lunchEndTime)
    @IsBetween('checkInTime', 'checkOutTime', {
        message: 'ShiftLunchShoutBetweenWorkDay'
    })
    lunchEndTime: number

    @Field(_type => Float, { nullable: true, defaultValue: 0 })
    @Min(0, {
        message: 'ShiftValueFromZeroToOne'
    })
    @Max(1, {
        message: 'ShiftValueFromZeroToOne'
    })
    noCheckInTimePunishment: number

    @Field(_type => Float, { nullable: true, defaultValue: 0 })
    @Min(0, {
        message: 'ShiftValueFromZeroToOne'
    })
    @Max(1, {
        message: 'ShiftValueFromZeroToOne'
    })
    noCheckOutTimePunishment: number

    @Field(_type => [WorkingShiftOutOfTimeInput], { nullable: true })
    outOfTime: WorkingShiftOutOfTimeInput[]

    @Field(_type => [WorkingShiftOverTimeInput], { nullable: true })
    overTime: WorkingShiftOverTimeInput[]
}