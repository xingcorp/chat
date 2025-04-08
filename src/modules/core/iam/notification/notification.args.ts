import {  NotificationCampaignStatus, NotificationObjectType, NotificationScheduleType } from "@models/entities/notification.campaign"
import { Field, Float, InputType, Int, PartialType } from "@nestjs/graphql"
import { IsNotEmpty, IsUUID, ValidateIf } from "class-validator"
import { NotificationCampaignKind } from "@enum/campaign/campaign.enum";
import { IsExistUserDbValidate } from "@decorators/validation/db/user/is-exist.user.db.validate";
import { IsDefinedValidate } from "@decorators/validation/utils/is-defined.validate";
import { Transform } from "class-transformer";
import { CustomIntOrAIntScalar } from "@helpers/scalar/graphql/int-or-array-of-int.graphql.scalar";
import { DayOfWeek } from "@common/constant.common";

@InputType()
export class NotificationCampaignArgs {
    @Field(_type => String, { nullable: false })
    title: string

    @Field(_type => String, { nullable: false })
    content: string

    @Field(() => [String], { nullable: true })
    imageIds: string[]

    @Field(() => [String], { nullable: true })
    attachFileIds: string[]

    @Field(_type => NotificationObjectType, { nullable: true })
    objectType: NotificationObjectType

    //Personal
    @Field(() => [String], { nullable: true })
    /*@ValidateIf(o => o.objectType === NotificationObjectType.Personal && !o.userId)
    @IsDefinedValidate({
        message: 'CampaignPersonalRequireReceiver'
    })*/
    phones: string[]

    //Personal
    @Field(() => [String], { nullable: true })
    @ValidateIf(o => o.userIds?.length)
    @IsExistUserDbValidate({
        message: 'CampaignUserGetNotifyNotExist'
    })
    userIds: string[]

    //Department
    @Field(() => [String], { nullable: true })
    @ValidateIf(o => !o.userIds || (Array.isArray(o.userIds) && !o.userIds.length))
    @IsDefinedValidate({
        message: 'CampaignNeedReceiver'
    })
    departmentIds: string[]

    //Department
    @Field(() => [String], { nullable: true })
    titleIds: string[]

    @Field(_type => NotificationScheduleType, { nullable: false, defaultValue: NotificationScheduleType.Now })
    type: NotificationScheduleType

    //Daily/Weekly/Monthly
    @Field(() => CustomIntOrAIntScalar, { nullable: true })
    @Transform(({value}) => Array.isArray(value) ? value : [value])
    startTimeInMinutes: number[]

    @Field(() => Float, { nullable: true, defaultValue: 7 })
    timeZone: number

    @Field(() => [DayOfWeek], { nullable: true })
    weekDays: DayOfWeek[]

    @Field(() => [Int], { nullable: true })
    monthDays: number[]

    @Field(_type => Float, { nullable: true })
    startAt: Date

    @Field(_type => Float, { nullable: true })
    endAt: Date
    
    @Field(_type => NotificationCampaignStatus, { nullable: false, defaultValue: NotificationCampaignStatus.Inactive })
    status: NotificationCampaignStatus
}

@InputType()
export class NotificationCampaignDifferentArgs extends PartialType(NotificationCampaignArgs) {
    notifyType: NotificationCampaignKind

    // @Field(_type => String, { nullable: true })
    notifyTypeId: string
}

@InputType()
export class NotificationUpdateCampaignArgs {
    @Field({ nullable: false })
    @IsNotEmpty()
    @IsUUID()
    id: string

    @Field(_type => NotificationCampaignStatus, { nullable: false })
    status: NotificationCampaignStatus
}

@InputType()
export class NotificationCampaignFilter {
    @Field({ nullable: true, defaultValue: 0})
    page?: number

    @Field({ nullable: true, defaultValue: 20})
    size?: number

    @Field(_type => String, { nullable: true })
    keyword?: string

    @Field({ nullable: true })
    fromDate?: number

    @Field({ nullable: true })
    toDate?: number

    @Field(_type => NotificationCampaignStatus, { nullable: true })
    status?: NotificationCampaignStatus

    @Field(_type => NotificationScheduleType, { nullable: true })
    type?: NotificationScheduleType
}

@InputType()
export class AppNotificationUpdateAllArgs {
    @Field(() => Boolean, { nullable: false, defaultValue: true })
    isRead: boolean
}