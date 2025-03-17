import { Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, ObjectLiteral, UpdateEvent } from "typeorm";
import { MeetingRoomSchedule } from "@models/entities";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { OfficeTaskLogRepo, OfficeTaskRepo } from "@models/repositories";
import { TaskLogService } from "@modules/graphql/task/task-log/task-log.service";
import { SubscriberHelpers } from "@helpers/subscribers/subscriber.helpers";
import { RedisService } from "@core/common/redis.service";
import { CACHE_KEY } from "@common/cache-key.common";

@Injectable()
// @EventSubscriber()
export class ScheduleMeetingSubscriber implements EntitySubscriberInterface<MeetingRoomSchedule> {
    private entity: ObjectLiteral;
    private eventUpdate: UpdateEvent<MeetingRoomSchedule>;

    constructor(
        @InjectConnection() readonly connection: Connection,
        private readonly redisService: RedisService,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to CloneByDate events.
     */
    listenTo() {
        return MeetingRoomSchedule
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<MeetingRoomSchedule>) {
        try {
            this.eventUpdate = event
            this.entity = event.entity

            await this.checkToRemoveCache()

        } catch (e) {
            console.log('afterUpdate ScheduleMeetingSubscriber error:', e)
        }
    }

    private async checkToRemoveCache() {
        if (SubscriberHelpers.isChangeField(this.eventUpdate, 'host')) {
            await this.redisService.delete(CACHE_KEY.MEETING_SCHEDULE.RESOLVER_FIELD.HOST(this.entity.id))
        }

        if (SubscriberHelpers.isChangeField(this.eventUpdate, 'participants')) {
            await this.redisService.delete(CACHE_KEY.MEETING_SCHEDULE.RESOLVER_FIELD.PARTICIPANTS(this.entity.id))
        }
    }
}