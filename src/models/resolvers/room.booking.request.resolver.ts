import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import {
    BookingMeetingRoom,
    CloneByDate,
    MeetingRoom,
    OfficeApproval,
    OfficeOrgChart,
    OfficeSysUser,
    OfficeUser
} from "../entities"
import {
    EquimentsForMettingRoom,
    LogisticsForMettingRoom,
    MeetingRoomSchedule
} from "../entities/meeting.room.schedule"
import { NotificationCampaign } from "@models/entities/notification.campaign";
import { NotificationCampaignKind } from "@enum/campaign/campaign.enum";
import { In } from "typeorm";
import { getDataAdminToImpersonationUser } from "@helpers/data.helper";
import { CloneDateTypeEnum } from "@enum/clone/date.clone.enum";

@Resolver(_of => BookingMeetingRoom)
export class BookingMeetingRoomFieldResolver {
    constructor() { }

    @ResolveField('bookingApproval', _return => OfficeApproval, { nullable: true })
    async bookingApproval(
        @Parent() root: BookingMeetingRoom
    ) {
        if (root.approvalId) {
            return OfficeApproval.findOne({
                where: {
                    id: root.approvalId
                }
            })
        }

        return null
    }

    @ResolveField('room', _return => MeetingRoom, { nullable: true })
    async room(
        @Parent() root: BookingMeetingRoom
    ) {
        if (root.meetingRoomId) {
            return MeetingRoom.findOne({
                where: {
                    id: root.meetingRoomId
                }
            })
        }

        return null
    }

    @ResolveField('requester', _return => OfficeUser, { nullable: true })
    async requester(
        @Parent() root: BookingMeetingRoom
    ) {
        if (root.bookedById) {
            return OfficeUser.findOne({
                where: {
                    id: root.bookedById
                }
            })
        }

        return null
    }

    @ResolveField('host', _return => OfficeUser, { nullable: true })
    async host(
        @Parent() root: BookingMeetingRoom
    ) {
        if (!root.host && root.hostId) {
            return OfficeUser.findOne({
                where: {
                    id: root.hostId
                }
            })
        }

        return null
    }

    @ResolveField('equiments', _return => [EquimentsForMettingRoom], { nullable: true })
    async equiments(
        @Parent() root: BookingMeetingRoom
    ) {
        const schedule = await MeetingRoomSchedule.findOne({
            where: {
                bookingId: root.id
            }
        })

        return schedule?.equiments
    }

    @ResolveField('logistics', _return => [LogisticsForMettingRoom], { nullable: true })
    async logistics(
        @Parent() root: BookingMeetingRoom
    ) {
        const schedule = await MeetingRoomSchedule.findOne({
            where: {
                bookingId: root.id
            }
        })

        return schedule?.logistics
    }

    @ResolveField('notify', _return => NotificationCampaign, { nullable: true })
    async notify(
        @Parent() root: BookingMeetingRoom
    ) {
        return NotificationCampaign.findOne({
            where: {
                notifyTypeId: root.id,
                notifyType: NotificationCampaignKind.Book_Room
            }
        })
    }

    @ResolveField('bookedBy', _return => OfficeUser, { nullable: true })
    async bookedBy(
        @Parent() root: BookingMeetingRoom
    ) {
        if (root.bookedById) return root.bookedBy

        const admin = await OfficeSysUser.findOneBy({
            id: In([root.createdById, root.updatedById])
        })

        if (!admin) return null

        return {
            ...getDataAdminToImpersonationUser(admin)
        } as OfficeUser
    }

    @ResolveField('orgChart', _return => OfficeOrgChart, { nullable: true })
    async orgChart(
        @Parent() root: BookingMeetingRoom
    ) {
        return OfficeOrgChart.findOneBy({id: root.organizationId})
    }

    @ResolveField('repeatConfig', _return => CloneByDate, {nullable: true})
    async repeatConfig(
        @Parent() root: BookingMeetingRoom
    ) {
        return CloneByDate.findOneBy({
            relationType: CloneDateTypeEnum.BookingMeetingRoom,
            relationId: root.id
        })
    }
}