import { forwardRef, Inject, SetMetadata, UseInterceptors } from "@nestjs/common";
import { Args, Mutation, Query, Resolver } from "@nestjs/graphql";
import { OfficeError } from "../../../../common/office.error";
import { ServiceActions, ServiceKeys, UserType } from "src/modules/core/middleware/guard/service.action";
import { ApprovalForm, MeetingRoom } from "../../../../models/entities";
import { CreateMeetingRoomArgs, DeleteMeetingRoomArgs, QueryMeetingRoomsArgs, UpdateMeetingRoomArgs } from "./meeting.room.args";
import { MeetingRoomsResponse } from "./meeting.room.response";
import { OfficeUserType, RequesterId } from "../../../core/middleware/decorator/user.decorator";
import { ObjectStatus } from "../../../../models/entities/profile.info.block";
import {MeetingRoomService} from "./meeting-room.service";
import { Not } from "typeorm";
import {
    FixedDataOrgChartUserWithParentAndChildInterceptor
} from "@interceptors/org-chart.interceptor";

@Resolver()
export class MeetingRoomResolver {
    constructor(
        @Inject(forwardRef(() => MeetingRoomService))
        private readonly meetingRoomService: MeetingRoomService
    ) { }

    @Query(() => MeetingRoomsResponse, { name: 'officeMeetingRoomGetList' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER, UserType.NORMAL_USER])
    @UseInterceptors(FixedDataOrgChartUserWithParentAndChildInterceptor)
    async getMeetingRooms(
        @Args('arguments', { nullable: false }) filter: QueryMeetingRoomsArgs,
        @OfficeUserType() userType: string,
        @RequesterId() requesterId: string,
    ): Promise<MeetingRoomsResponse> {
        const [rooms, total] =
            userType === UserType.NORMAL_USER.toString()
                ? await this.meetingRoomService.getAppMeetingRooms(filter, requesterId)
                : await this.meetingRoomService.getAdminMeetingRooms(filter, requesterId);

        return {
            total,
            count: rooms.length,
            meetingRooms: rooms
        }
    }

    @Mutation(() => MeetingRoom, { name: 'officeCreateMeetingRoom' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async createMeetingRoom(
        @Args('arguments', { nullable: false }) args: CreateMeetingRoomArgs,
        @RequesterId() requesterId: string,
    ): Promise<MeetingRoom> {
        if (args.approvalFormId) {
            const approvalForm = await ApprovalForm.findOne({ where: { id: args.approvalFormId } })
            if (!approvalForm) throw OfficeError.ApprovalFormNotFound
        }

        const checkName = await MeetingRoom.findOneBy({name: args.name.trim()})
        if (checkName) {
            throw OfficeError.MeetingRoomExistedName
        }

        return MeetingRoom.create({ ...args, createdById: requesterId, updatedBy: requesterId }).save()
    }

    @Mutation(() => MeetingRoom, { name: 'officeUpdateMeetingRoom' })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async updateMeetingRoom(
        @Args('arguments', { nullable: false }) args: UpdateMeetingRoomArgs,
        @RequesterId() requesterId: string,
    ): Promise<MeetingRoom> {
        const isRoomExist = await MeetingRoom.findOne({ where: { id: args.id } })
        if (!isRoomExist) {
            throw OfficeError.MeetingRoomNotFound
        }

        const checkName = await MeetingRoom.findOneBy({
            name: args.name.trim(),
            id: Not(isRoomExist.id)
        })
        if (checkName) {
            throw OfficeError.MeetingRoomExistedName
        }

        isRoomExist.name = args.name
        isRoomExist.organizationId = args.organizationId
        isRoomExist.capacity = args.capacity
        isRoomExist.color = args.color
        isRoomExist.status = args.status

        if (args.approvalFormId && args.approvalFormId !== isRoomExist.approvalFormId) {
            const approvalForm = await ApprovalForm.findOne({ where: { id: args.approvalFormId } })
            if (!approvalForm) throw OfficeError.ApprovalFormNotFound

            isRoomExist.approvalFormId = approvalForm.id

            //yêu cầu đặt phòng chưa phê duyệt -> chuyển sang luồng phê duyệt mới
        }
        isRoomExist.updatedBy = requesterId

        // isRoomExist.save()
        return isRoomExist.save()
    }

    @Mutation(() => MeetingRoom, { name: 'officeDeleteMeetingRoom', nullable: true })
    @SetMetadata(ServiceKeys.Action, [ServiceActions.Authenticated])
    @SetMetadata(ServiceKeys.UserType, [UserType.SYSTEM_USER])
    async deleteMeetingRoom(
        @Args('arguments', { nullable: false }) args: DeleteMeetingRoomArgs,
        @RequesterId() requesterId: string,
    ): Promise<MeetingRoom> {
        const isRoomExist = await MeetingRoom.findOne({ where: { id: args.id } })
        if (!isRoomExist) {
            throw OfficeError.MeetingRoomNotFound
        }
        isRoomExist.status = ObjectStatus.Inactive
        await isRoomExist.save()
        const deleteResult = await MeetingRoom.softRemove(isRoomExist)
        return deleteResult
    }
}