import { Injectable } from '@nestjs/common';
import { RequestContext } from "@common/context/request.context";
import { BookingService } from "@modules/graphql/booking/booking.service";
import { MeetingRoomScheduleRepo, NotificationCampaignRepo, OfficeUserRepo, UserScheduleRepo } from "@models/repositories";
import {
    BookingScheduleNotifyInput,
    BookingScheduleRemoveInput,
    BookingScheduleUpdateInput
} from "@modules/graphql/booking/dto/schedule.booking.args";
import { LearnCourse, MeetingRoomSchedule, UserSchedule } from "@models/entities";
import { NotificationCampaignDifferentArgs } from "@core/iam/notification/notification.args";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { NotificationService } from "@core/iam/notification/notification.service";
import { CACHE_KEY } from "@common/cache-key.common";
import { RedisService } from "@core/common/redis.service";
import { arrayIsTheSame } from "@utils/array.utils";
import { combineDateAndTime, datetimeDateRoundToMinuteGet, getWeekDayNumber, TIMESTAMP } from "@utils/datetime.utils";
import { sleep } from "@utils/common.utils";
import { DayOfWeek } from '@common/constant.common';
import { ScheduleType, ScheduleTypeColor } from '@models/entities/user.schedule';

@Injectable()
export class ScheduleBookingService {

    constructor(
        private readonly bookingService: BookingService,
        private readonly notificationService: NotificationService,
        private readonly redisService: RedisService,
        private readonly meetingRoomScheduleRepo: MeetingRoomScheduleRepo,
        private readonly officeUserRepo: OfficeUserRepo,
        private readonly notificationCampaignRepo: NotificationCampaignRepo,
        private readonly scheduleRepo: MeetingRoomScheduleRepo,
    ) {
    }

    async adminBookingScheduleRemove(args: BookingScheduleRemoveInput) {
        return this.bookingScheduleRemove(args)
    }

    async userBookingScheduleRemove(args: BookingScheduleRemoveInput) {
        if (RequestContext.isNormalUser()) {
            await this.bookingService.checkNormalUserCanModifyBooking(args.schedule.booking)
        }

        return this.bookingScheduleRemove(args)
    }

    private async bookingScheduleRemove(args: BookingScheduleRemoveInput) {
        const schedule = args.schedule

        const listAllScheduleOfBooking = await this.meetingRoomScheduleRepo.getAllOfMeetingId(schedule.bookingId)

        if (listAllScheduleOfBooking.length === 1) {
            await this.bookingService.bookingRemove({
                id: schedule.bookingId,
                description: args.description
            }, schedule.booking)
        } else {
            const notifyBooking = await this.notificationCampaignRepo.getBookingRoomById(schedule.bookingId)
            schedule.cancelDescription = args.description ?? null
            await schedule.save()
            await schedule.softRemove()

            if (notifyBooking) await notifyBooking.softRemove()
        }

        return args.scheduleId
    }

    adminBookingScheduleUpdate(args: BookingScheduleUpdateInput) {
        return this.bookingScheduleUpdate(args)
    }

    async userBookingScheduleUpdate(args: BookingScheduleUpdateInput) {
        if (RequestContext.isNormalUser()) {
            await this.bookingService.checkNormalUserCanModifyBooking(args.schedule.booking)
        }

        return this.bookingScheduleUpdate(args)
    }

    private async bookingScheduleUpdate(args: BookingScheduleUpdateInput) {
        const schedule = args.schedule

        await this.checkToRemoveCache(schedule, args)

        schedule.startAt = new Date(args.startAt) ?? schedule.startAt
        schedule.endAt = new Date(args.endAt) ?? schedule.endAt
        schedule.equiments = args.equiments ?? schedule.equiments
        schedule.logistics = args.logistics ?? schedule.logistics
        schedule.meetingRoom = args.meetingRoom ?? schedule.meetingRoom
        schedule.meetingContent = args.meetingContent ?? schedule.meetingContent
        schedule.host = args.host ?? schedule.host
        schedule.quantity = args.quantity ?? schedule.quantity
        schedule.note = args.note ?? schedule.note

        if (!!args.participantIds && Array.isArray(args.participantIds) && args.participantIds.length) {
            schedule.participants = args.participants
        } else {
            schedule.participants = null
        }

        await schedule.save()
        await schedule.reload()

        if (args.notify) {
            await this.bookingScheduleNotifyUpsert(args.notify, schedule)
        }

        return schedule
    }

    private async bookingScheduleNotifyUpsert(args: NotificationCampaignDifferentArgs, schedule: MeetingRoomSchedule) {
        const booking = schedule.booking
        args.phones = await this.officeUserRepo.listPhoneById([booking.hostId, ...booking.participantIds, booking.bookedById])
        args.userIds = await this.officeUserRepo.listFieldById([booking.hostId, ...booking.participantIds, booking.bookedById], 'id')
        args.notifyTypeId = schedule.id
        args.title = args.title ?? NotifyMessageTitle.BookingRoomUpdate()

        return this.notificationService.upsertNotificationBookingRoomSchedule(args)
    }

    adminBookingScheduleNotify(args: BookingScheduleNotifyInput) {
        return this.bookingScheduleNotifyUpsert(args, args.schedule)
    }

    officeBookingScheduleNotify(args: BookingScheduleNotifyInput) {
        return this.bookingScheduleNotifyUpsert(args, args.schedule)
    }

    private async checkToRemoveCache(schedule: MeetingRoomSchedule, args: BookingScheduleUpdateInput) {
        if (!Array.isArray(args.participants) || !Array.isArray(schedule.participants) || !arrayIsTheSame(args.participants, schedule.participants)) {
            await this.redisService.delete(CACHE_KEY.MEETING_SCHEDULE.RESOLVER_FIELD.PARTICIPANTS(schedule.id))
        }
    }

    async remindMeeting() {
        const now = new Date()

        await this.remindMeetingAtTime(datetimeDateRoundToMinuteGet(now).getTime() + TIMESTAMP["1H"])
    }

    async remindMeetingAtTime(timestamp: number) {
        const date = new Date(timestamp)
        const schedules = await this.scheduleRepo.getAllStartAt(date)

        console.log('SCHEDULE_MEETING_REMIND schedules', schedules)

        for (const schedule of schedules) {
            this.notifyRemind(schedule)
            await sleep(500)
        }
    }

    private async notifyRemind(schedule: MeetingRoomSchedule) {
        return this.notificationService.systemDestinationPush(
            NotifyType.BookingRoomApproval,
            NotifyMessageTitle.BookingRoomApproval(),
            NotifyMessageContent.BookingRoomApproval(schedule),
            '',
            JSON.stringify({ scheduleId: schedule.id, bookingId: schedule.booking.id }),
            await this.officeUserRepo.getAllUserIdsAllWayByIds([schedule.host.id, ...schedule.participants.map(i => i.id)]),
            null,
            process.env.OFFICE_ORGANIZATION_ID,
            schedule.host.id
        )
    }
}
