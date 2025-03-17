import { Args, Mutation, Resolver } from '@nestjs/graphql';
import { SetMetadata, UseInterceptors } from "@nestjs/common";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { FixedDataOrgChartUserAllAndWithChildInterceptor } from "@interceptors/org-chart.interceptor";
import { ErrorInterceptor } from "@interceptors/error.interceptor";
import { ScheduleBookingService } from "@modules/graphql/booking/schedule.booking.service";
import {
    BookingScheduleNotifyInput,
    BookingScheduleRemoveInput,
    BookingScheduleUpdateInput
} from "@modules/graphql/booking/dto/schedule.booking.args";
import { MeetingRoomSchedule } from "@models/entities";
import { NotificationCampaign } from "@models/entities/notification.campaign";

@Resolver()
export class ScheduleBookingResolver {

    constructor(
        private readonly scheduleBookingService: ScheduleBookingService,
    ) {
    }

    @Mutation(() => MeetingRoomSchedule, { name: 'managementBookingScheduleUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementBookingScheduleUpdate(
        @Args('arguments', { nullable: false }) args: BookingScheduleUpdateInput,
    ) {
        return this.scheduleBookingService.adminBookingScheduleUpdate(args)
    }

    @Mutation(() => String, { name: 'managementBookingScheduleRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementBookingScheduleRemove(
        @Args('arguments', { nullable: false }) args: BookingScheduleRemoveInput,
    ) {
        return this.scheduleBookingService.adminBookingScheduleRemove(args)
    }

    @Mutation(() => NotificationCampaign, { name: 'managementBookingScheduleNotify' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async managementBookingScheduleNotify(
        @Args('arguments', { nullable: false }) args: BookingScheduleNotifyInput,
    ) {
        return this.scheduleBookingService.adminBookingScheduleNotify(args)
    }

    /*Office*/

    @Mutation(() => MeetingRoomSchedule, { name: 'officeBookingScheduleUpdate' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeBookingScheduleUpdate(
        @Args('arguments', { nullable: false }) args: BookingScheduleUpdateInput,
    ) {
        return this.scheduleBookingService.userBookingScheduleUpdate(args)
    }

    @Mutation(() => String, { name: 'officeBookingMeetingRoomScheduleRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeBookingMeetingRoomScheduleRemove(
        @Args('arguments', { nullable: false }) args: BookingScheduleRemoveInput,
    ) {
        return this.scheduleBookingService.userBookingScheduleRemove(args)
    }

    @Mutation(() => NotificationCampaign, { name: 'officeBookingScheduleNotify' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async officeBookingScheduleNotify(
        @Args('arguments', { nullable: false }) args: BookingScheduleNotifyInput,
    ) {
        return this.scheduleBookingService.officeBookingScheduleNotify(args)
    }
}
