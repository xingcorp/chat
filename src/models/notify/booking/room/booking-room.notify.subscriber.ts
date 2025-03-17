import { forwardRef, Inject, Injectable } from "@nestjs/common";
import {
    Connection,
    EntitySubscriberInterface,
    InsertEvent,
    ObjectLiteral,
    SoftRemoveEvent,
    UpdateEvent
} from "typeorm";
import { BookingMeetingRoom, OfficeTask } from "@models/entities";
import { InjectConnection } from "@nestjs/typeorm";
import { NotificationService } from "@core/iam/notification/notification.service";
import { NotificationCampaignRepo } from "@repositories/index";
import { NotifyMessageContent, NotifyMessageTitle, NotifyType } from "@common/notify.message";
import { RequestStatus } from "@models/entities/car.booking.request";
import { NotificationScheduleType } from "@models/entities/notification.campaign";
import { RequestContext } from "@common/context/request.context";

enum CaseType {
    Create = 'Create',
    Update = 'Update',
    Delete = 'Delete',
}

@Injectable()
// @EventSubscriber()
export class BookingRoomNotifySubscriber implements EntitySubscriberInterface<BookingMeetingRoom> {
    private entity: ObjectLiteral;
    private newVal: ObjectLiteral;
    private oldVal: BookingMeetingRoom;
    private notifyType: string;
    private notifyTitle: any;
    private notifyContent: string;
    private receiverIds: any;
    private metadata: any;

    constructor(
        @InjectConnection() readonly connection: Connection,
        @Inject(forwardRef(() => NotificationService))
        private readonly notificationService: NotificationService,
        private readonly notificationCampaignRepo: NotificationCampaignRepo,
    ) {
        connection.subscribers.push(this);
    }

    /**
     * Indicates that this subscriber only listen to OfficeUser events.
     */
    listenTo() {
        return BookingMeetingRoom
    }

    private async notifySysBookRoom(entity: BookingMeetingRoom | ObjectLiteral, content: string, type: CaseType) {
        if (type === CaseType.Delete && entity.status !== RequestStatus.Approved && !entity.bookedById) return null

        const fullReceiverIds = [entity.hostId, ...entity.participantIds, entity.bookedById].filter(i => i)

        return this.notificationService.destinationPush(
            null,
            NotifyType[`BookingRoom${type}`],
            NotifyMessageTitle[`BookingRoom${type}`](),
            content,
            '',
            JSON.stringify({bookingId: entity.id}),
            entity.status === RequestStatus.Approved ? fullReceiverIds : [entity.bookedById],
            null,
            process.env.OFFICE_ORGANIZATION_ID
        )
    }

    private async bookRoomNotify() {
        if (RequestContext.isSysUser() && this.newVal.status !== this.oldVal.status) return

        const bookRoomNotify = await this.notificationCampaignRepo.getBookingRoomById(this.entity.id)

        if (bookRoomNotify && !this.entity.cancelDescription) {
            await this.notifySysBookRoom(this.entity, bookRoomNotify.content, CaseType.Update)
        }
    }

    /**
     * Called after entity insertion.
     */
    async afterInsert(event: InsertEvent<BookingMeetingRoom>) {
        try {
            const entity = event.entity
            this.entity = event.entity

            const bookRoomNotify = await this.notificationCampaignRepo.getBookingRoomById(entity.id)

            if (bookRoomNotify && bookRoomNotify.type !== NotificationScheduleType.Now) {
                await this.notifySysBookRoom(entity, bookRoomNotify.content, CaseType.Create)
            }

        } catch (e) {
            console.log('Called after BookingMeetingRoom insertion error: ', e)
        }
    }

    /**
     * Called after entity update.
     */
    async afterUpdate(event: UpdateEvent<BookingMeetingRoom>) {
        try {
            this.entity = event.entity
            this.newVal = event.entity
            this.oldVal = event.databaseEntity

            /*check notify when admin update*/
            await this.bookRoomNotify()

            /*check notify when user approval*/
            await this.bookRoomApproval()
        } catch (e) {
            console.log('Called after BookingMeetingRoom updated error: ', e)
        }
    }

    /**
     * Called after entity removal.
     */
    /*async afterSoftRemove(event: SoftRemoveEvent<BookingMeetingRoom>) {
        try {
            const entity = event.entity

            await this.notifySysBookRoom(entity, entity.cancelDescription, CaseType.Delete)
        } catch (e) {
            console.log('Called after BookingMeetingRoom soft remove error: ', e)
        }
    }*/

    private async bookRoomApproval() {
        if (this.newVal.status === this.oldVal.status) return null
        
        switch (this.newVal.status) {
            case RequestStatus.Approved:
                this.notifyType = NotifyType.BookingRoomApproval
                this.notifyTitle = NotifyMessageTitle.BookingRoomApproval()
                this.notifyContent = NotifyMessageContent.BookingRoomApproval(this.newVal)
                this.metadata = {bookingId: this.entity.id}
                this.receiverIds = [this.entity.hostId, ...this.entity.participantIds, this.entity.bookedById].filter(i => i)
                await this.pushNotifyHaveMeetingToRelationUser()
                return
        }
    }

    private async pushNotifyHaveMeetingToRelationUser() {
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

    private async bookRoomApprovalAfterInsert() {
        switch (this.entity?.status) {
            case RequestStatus.Approved:
                this.notifyType = NotifyType.BookingRoomApproval
                this.notifyTitle = NotifyMessageTitle.BookingRoomApproval()
                this.notifyContent = NotifyMessageContent.BookingRoomApproval(this.newVal)
                this.metadata = {bookingId: this.entity.id}
                this.receiverIds = [this.entity?.hostId, ...this.entity?.participantIds, this.entity?.bookedById].filter(i => i)
                await this.pushNotifyHaveMeetingToRelationUser()
                return
        }
    }
}