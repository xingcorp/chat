import { PagingData } from "@models/base/paging.response"
import { NotificationCampaign } from "@models/entities/notification.campaign"
import { OfficeSysUser } from "@models/entities/system.user"
import { Field, Int, ObjectType } from "@nestjs/graphql"
import { Notification } from '../objects/notification'

@ObjectType({ implements: PagingData })
export class NotificationCampaignResponse implements PagingData {
    total: number
    count: number
    
    @Field(_type => [NotificationCampaign], { nullable: true })
    campaigns?: NotificationCampaign[]
}

@ObjectType()
export class AppNotificationResponse {
    @Field(() => Int, { defaultValue: 0 })
    total: number

    @Field(() => Int, { defaultValue: 0 })
    count: number

    @Field(() => [Notification], { nullable: true })
    notifications?: Notification[]
}