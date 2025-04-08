import { Inject, SetMetadata, forwardRef, UseInterceptors } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { NotificationCampaignArgs, NotificationCampaignFilter, NotificationUpdateCampaignArgs } from "./notification.args";
import { NotificationCampaign } from "@models/entities/notification.campaign";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { RequesterId } from "@core/middleware/decorator/user.decorator";
import { OfficeError } from "@common/office.error";
import { NotificationCampaignResponse } from "./notification.response";
import { NotificationService } from "./notification.service";
import { StorageService } from "@core/storage/storage.service";
import { BearerAccessToken } from "@core/middleware/decorator/request.decorator";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { FixedDataOrgChartUserAllAndWithChildInterceptor } from "@interceptors/org-chart.interceptor";

@Resolver()
export class NotificationResolver {
    constructor(
        @Inject(forwardRef(() => StorageService))
        private readonly storageService: StorageService,

        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService
    ) { }

    @Mutation(() => NotificationCampaign, { name: 'officeCreateNotificationCampaign' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(ErrorInterceptor)
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    async createNotificationCampaign(
        @Args('arguments', { nullable: false }) args: NotificationCampaignArgs,
        @RequesterId() requesterId: string,
        @BearerAccessToken() token: string,
    ): Promise<NotificationCampaign> {
        return this.notificationService.createNotificationCampaign({requesterId, token}, args)
    }

    @Query(_return => NotificationCampaignResponse, { name: "officeGetNotificationCampaignList" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async officeGetNotificationCampaignList(
        @Args("filter", { nullable: true }) filter: NotificationCampaignFilter
    ): Promise<NotificationCampaignResponse> {
        const [list, count] = await this.notificationService.notificationCampaignList(filter)

        return {
            total: count,
            count: list.length,
            campaigns: list
        }
    }

    @Mutation(() => NotificationCampaign, { name: 'officeUpdateNotificationCampaign' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async updateNotificationCampaign(
        @Args('arguments', { nullable: false }) args: NotificationUpdateCampaignArgs,
        @RequesterId() requesterId: string,
    ): Promise<NotificationCampaign> {
        const campaign = await NotificationCampaign.findOne({
            where: {
                id: args.id
            }
        })

        if (!campaign) throw OfficeError.NotificationCampaignNotFound

        campaign.status = args.status
        campaign.updatedBy = requesterId

        if (Array.isArray(campaign.startTimeInMinutes)) delete campaign.startTimeInMinutes
        if (campaign.startTimeIn) campaign.startTimeIn = Array.isArray(campaign.startTimeIn) ? campaign.startTimeIn : [campaign.startTimeIn]

        return campaign.save()
    }
}