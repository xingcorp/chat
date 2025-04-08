import { Parent, ResolveField, Resolver } from "@nestjs/graphql"
import { NotificationCampaign } from "@models/entities/notification.campaign";
import { NotificationCampaignKind } from "@enum/campaign/campaign.enum";
import { MeetingRoomSchedule, OfficeTask, OfficeUser } from "@models/entities";
import { InjectRepository } from "@nestjs/typeorm";
import { BookingMeetingRoomRepo, MeetingRoomScheduleRepo, OfficeTaskRepo } from "@models/repositories";
import { forwardRef, Inject } from "@nestjs/common";
import { RedisService } from "@core/common/redis.service";
import { CACHE_KEY } from "@common/cache-key.common";

@Resolver(_of => MeetingRoomSchedule)
export class BookingRoomScheduleFieldResolver {
    constructor(
        @InjectRepository(MeetingRoomScheduleRepo)
        private readonly scheduleRepo: MeetingRoomScheduleRepo,
        @InjectRepository(BookingMeetingRoomRepo)
        private readonly bookingMeetingRoomRepo: BookingMeetingRoomRepo,
        @Inject(forwardRef(() => RedisService))
        private readonly redisService: RedisService,
    ) { }

    @ResolveField('notify', _return => NotificationCampaign, { nullable: true })
    async notify(
        @Parent() root: MeetingRoomSchedule
    ) {
        return NotificationCampaign.findOne({
            where: {
                notifyTypeId: root.id,
                notifyType: NotificationCampaignKind.Book_Room_Schedule
            }
        })
    }

    @ResolveField('host', _return => OfficeUser, { nullable: true })
    async host(
        @Parent() root: MeetingRoomSchedule
    ) {
        const redisKey = CACHE_KEY.MEETING_SCHEDULE.RESOLVER_FIELD.HOST(root.id)

        const cached = await this.redisService.get(redisKey)
        if (cached) {
            const resCached = JSON.parse(cached)
            return resCached ?? null
        }

        const _this = await this.scheduleRepo.getBy({ id: root.id }, ['host'])

        await this.redisService.setWithTtl(redisKey, JSON.stringify(_this.host), 30 * 24 * 60 * 60)

        return _this.host
    }

    @ResolveField('participants', _return => [OfficeUser], { nullable: true })
    async participants(
        @Parent() root: MeetingRoomSchedule
    ) {
        const redisKey = CACHE_KEY.MEETING_SCHEDULE.RESOLVER_FIELD.PARTICIPANTS(root.id)

        const cached = await this.redisService.get(redisKey)
        if (cached) {
            const resCached = JSON.parse(cached)
            return resCached ?? null
        }

        const _this = await this.scheduleRepo.getBy({ id: root.id }, ['participants'])

        let participants = _this.participants

        if (!participants) {
            const booking = await this.bookingMeetingRoomRepo.getBy({ id: _this.bookingId }, ['participants'])

            participants = booking.participants
        }

        await this.redisService.setWithTtl(redisKey, JSON.stringify(participants), 30 * 24 * 60 * 60)

        return participants
    }
}