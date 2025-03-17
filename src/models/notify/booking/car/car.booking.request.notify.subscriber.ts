import { forwardRef, Inject, Injectable } from "@nestjs/common";
import { Connection, EntitySubscriberInterface, ObjectLiteral, UpdateEvent } from "typeorm";
import { CarBookingRequest, RequestStatus } from "@models/entities/car.booking.request";
import { InjectConnection, InjectRepository } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { CarRepo, OfficeUserRepo } from "@repositories/index";

@Injectable()
// @EventSubscriber()
export class CarBookingRequestNotifySubscriber implements EntitySubscriberInterface<CarBookingRequest> {
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
        return CarBookingRequest
    }

    private async bookCarApproval() {
        if (this.newVal.status === this.oldVal.status) return null

        this.entity.car = await this.carRepo.getById(this.entity.carId)

        switch (this.newVal.status) {
            case RequestStatus.Approved:
                this.notifyType = NotifyType.BookCarApproval
                this.notifyTitle = NotifyMessageTitle.BookCarApproval()
                this.notifyContent = NotifyMessageContent.BookCarApproval(this.entity)
                this.metadata = {bookingId: this.entity.id}
                this.receiverIds = await this.officeUserRepo.getAllUserIdsAllWayByIds([this.entity.car?.driverId, this.entity?.createdBy])
                await this.pushNotifyToRelationUser()
                return
        }
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
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<CarBookingRequest>) {
        try {
            this.entity = event.entity
            this.newVal = event.entity
            this.oldVal = event.databaseEntity

            /*check notify when user approval*/
            await this.bookCarApproval()
        } catch (e) {
            console.log('Called after CarBookingRequest updated error: ', e)
        }
    }
}