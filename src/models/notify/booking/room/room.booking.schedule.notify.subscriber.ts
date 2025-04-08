import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, ObjectLiteral, SoftRemoveEvent, UpdateEvent } from "typeorm";
import { CarBookingRequest, RequestStatus } from "@models/entities/car.booking.request";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { CarRepo, MeetingRoomScheduleRepo, OfficeUserRepo } from "@repositories/index";
import { CarBookingSchedule } from "@models/entities/car.booking.schedule";
import { MeetingRoomSchedule } from "@models/entities";

@Injectable()
// @EventSubscriber()
export class RoomBookingScheduleNotifySubscriber implements EntitySubscriberInterface<MeetingRoomSchedule> {
    private entity: ObjectLiteral;
    private newVal: ObjectLiteral;
    private oldVal: any;
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        @InjectRepository(MeetingRoomScheduleRepo)
        private readonly scheduleRepo: MeetingRoomScheduleRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return MeetingRoomSchedule
    }

    private async pushNotifyToRelationUser() {
        return this.notificationService.destinationPush(
            null,
            this.notifyType,
            this.notifyTitle,
            this.notifyContent,
            '',
            JSON.stringify(this.metadata),
            this.receiverIds,
            null,
            process.env.OFFICE_ORGANIZATION_ID
        )
    }

    /**
     * Called after entity removal.
     */
    async afterSoftRemove(event: SoftRemoveEvent<MeetingRoomSchedule>) {
        try {
            this.entity = event.entity
            const schedule = await this.scheduleRepo.findOne({
                relations: ['host', 'participants', 'booking'],
                where: {
                    id: this.entity.id,
                }
            })

            this.notifyType = NotifyType.BookingRoomDelete
            this.notifyTitle = NotifyMessageTitle.BookingRoomDelete()
            this.notifyContent = this.entity.cancelDescription
            this.metadata = {scheduleId: this.entity.id, bookingId: schedule.booking.id}
            this.receiverIds = await this.officeUserRepo.getAllUserIdsAllWayByIds([schedule.host.id, ...(schedule.participants.length ? schedule.participants.map(i => i.id) : [])])
            await this.pushNotifyToRelationUser()

        } catch (e) {
            console.log('afterSoftRemove MeetingRoomSchedule error: ', e)
        }
    }
}