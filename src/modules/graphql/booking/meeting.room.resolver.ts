import { Inject, SetMetadata, forwardRef, UseInterceptors } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { ServiceActions, ServiceKeys, UserType } from "@core/middleware/guard/service.action";
import { RequesterId } from "@core/middleware/decorator/user.decorator";
import {
    BookMeetingRoomArgs, DeleteBookingMeetingRoomArgs,
    NotificationBookingMeetingRoomArgs,
    QueryBookingMeetingRoomArgs,
    UpdateBookingMeetingRoomArgs
} from "./dto/booking.args";
import { BookingService } from "./booking.service";
import { BookMeetingRoomsResponse, MeetingDetailResponse, MeetingsResponse } from "./dto/booking.response";
import {MeetingRoomSchedule} from "@models/entities";
import { ApprovalService } from "../approval/approval.service";
import { BearerAccessToken } from "src/modules/core/middleware/decorator/request.decorator";
import {
    FixedDataOrgChartUserAllAndWithChildInterceptor,
    FixedDataOrgChartUserAllInterceptor
} from "@interceptors/org-chart.interceptor";
import { In } from "typeorm";
import { ListDataOfOrg } from "@core/middleware/decorator/org-chart.decorator";
import { RequestContext } from "@common/context/request.context";
import { NotificationCampaign } from "@models/entities/notification.campaign";
import { ErrorInterceptor } from "@interceptors/error.interceptor";


@Resolver()
export class BookingMeetingRoomResolver {
    constructor(
        private readonly bookingService: BookingService,

        @Inject(forwardRef(() => ApprovalService))
        private readonly approvalService: ApprovalService
    ) { }

    @Query(_return => MeetingsResponse, { name: "officeGetMeetingSchedule" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async getAllMeeting(
        @Args("arguments") filter: QueryBookingMeetingRoomArgs,
    ): Promise<MeetingsResponse> {
        return this.bookingService.getAllMeeting(filter);
    }

    @Query(_return => MeetingDetailResponse, { name: "officeGetMeetingDetail" })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async getMeetingDetail(
        @Args("id") id: string,
        @ListDataOfOrg('listOrgIdOnly') listOrgIdOnly: string[],
        @ListDataOfOrg('listOrgIdAll') listOrgIdAll: string[],
    ): Promise<MeetingDetailResponse> {
        let query = MeetingRoomSchedule.createQueryBuilder('meeting')
            .leftJoinAndSelect('meeting.booking', 'booking')
            .leftJoinAndSelect('booking.participants', 'participants')
            .leftJoinAndSelect('booking.bookedBy', 'bookedBy')
            .leftJoinAndSelect('booking.host', 'host')
            .leftJoinAndSelect('meeting.meetingRoom', 'meetingRoom')
            .where({
                id,
                booking: {
                    organizationId: In(RequestContext.isNormalUser() ? listOrgIdAll : listOrgIdOnly) //ok
                }
            })

        const meeting = await query.getOne()

        return { meeting }
    }

    @Mutation(() => BookMeetingRoomsResponse, { name: 'officeBookMeetingRoom' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER, UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async bookMeetingRoom(
        @Args('arguments', { nullable: false }) args: BookMeetingRoomArgs,
    ): Promise<BookMeetingRoomsResponse> {
        return this.bookingService.bookMeetingRoom(args)
    }

    /*legacy*/
    @Mutation(() => BookMeetingRoomsResponse, { name: 'officeBookMeetingRoomLegacy' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER, UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async bookMeetingRoomLegacy(
        @Args('arguments', { nullable: false }) args: BookMeetingRoomArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ): Promise<BookMeetingRoomsResponse> {
        return this.bookingService.bookMeetingRoomLegacy({token, requesterId}, args)
    }

    @Mutation(() => BookMeetingRoomsResponse, { name: 'officeUpdateBookingMeetingRoom' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER, UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllAndWithChildInterceptor)
    @UseInterceptors(ErrorInterceptor)
    async updateBookingMeetingRoom(
        @Args('arguments', { nullable: false }) args: UpdateBookingMeetingRoomArgs,
        @BearerAccessToken() token: string,
        @RequesterId() requesterId: string,
    ) {
        return this.bookingService.updateBookingMeetingRoom(args)
    }

    @Mutation(() => String, { name: 'managementDeleteBookingMeetingRoom' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async managementDeleteBookingMeetingRoom(
        @Args('arguments', { nullable: false }) args: DeleteBookingMeetingRoomArgs,
    ) {
        return this.bookingService.adminBookingRemove(args)
    }

    @Mutation(() => String, { name: 'officeBookingMeetingRoomRemove' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async officeBookingMeetingRoomRemove(
        @Args('arguments', { nullable: false }) args: DeleteBookingMeetingRoomArgs,
    ) {
        return this.bookingService.userBookingRemove(args)
    }

    @Mutation(() => NotificationCampaign, { name: 'managementUpdateNotifyBookingMeetingRoom' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    @UseInterceptors(FixedDataOrgChartUserAllInterceptor)
    async managementUpdateNotifyBookingMeetingRoom(
        @Args('arguments', { nullable: false }) args: NotificationBookingMeetingRoomArgs,
    ) {
        return this.bookingService.notifyBookingUpdate(args)
    }
}