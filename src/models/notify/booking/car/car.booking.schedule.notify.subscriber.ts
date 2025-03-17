import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, ObjectLiteral, SoftRemoveEvent, UpdateEvent } from "typeorm";
import { CarBookingRequest, RequestStatus } from "@models/entities/car.booking.request";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { CarRepo, OfficeUserRepo } from "@repositories/index";
import { CarBookingSchedule } from "@models/entities/car.booking.schedule";

@Injectable()
// @EventSubscriber()
export class CarBookingScheduleNotifySubscriber implements EntitySubscriberInterface<CarBookingSchedule> {
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
        @InjectRepository(CarRepo)
        private readonly carRepo: CarRepo,
        @InjectRepository(OfficeUserRepo)
        private readonly officeUserRepo: OfficeUserRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return CarBookingSchedule
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
    async afterSoftRemove(event: SoftRemoveEvent<CarBookingSchedule>) {
        try {
            this.entity = event.entity

            this.notifyType = NotifyType.Car.Booking.Remove
            this.notifyTitle = NotifyMessageTitle.Car.Booking.Remove
            this.notifyContent = this.entity.cancelDescription
            this.metadata = {scheduleId: this.entity.id}
            this.receiverIds = await this.officeUserRepo.getAllUserIdsAllWayByIds([this.entity?.createdBy])
            await this.pushNotifyToRelationUser()

        } catch (e) {
            console.log('afterSoftRemove CarBookingSchedule: ', e)
        }
    }
}